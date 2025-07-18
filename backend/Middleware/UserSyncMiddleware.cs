using PerryChick.Api.Data;
using PerryChick.Api.Models;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace PerryChick.Api.Middleware;

public class UserSyncMiddleware
{
	private readonly RequestDelegate _next;
	private readonly ILogger<UserSyncMiddleware> _logger;

	public UserSyncMiddleware(RequestDelegate next, ILogger<UserSyncMiddleware> logger)
	{
		_next = next;
		_logger = logger;
	}

	public async Task InvokeAsync(HttpContext context, AppDbContext dbContext)
	{
		if (context.User.Identity?.IsAuthenticated == true)
		{
			try
			{
				await SyncUserAsync(context, dbContext);
			}
			catch (Exception ex)
			{
				_logger.LogWarning(ex, "Failed to sync user from JWT token");
			}
		}

		await _next(context);
	}

	private async Task SyncUserAsync(HttpContext context, AppDbContext dbContext)
	{
		var userIdClaim = context.User.FindFirst("sub") ?? context.User.FindFirst(ClaimTypes.NameIdentifier);
		var emailClaim = context.User.FindFirst("email") ?? context.User.FindFirst(ClaimTypes.Email);
		var usernameClaim = context.User.FindFirst("preferred_username")
						  ?? context.User.FindFirst("name")
						  ?? context.User.FindFirst(ClaimTypes.Name);

		if (emailClaim?.Value == null) return;

		var email = emailClaim.Value;
		var username = usernameClaim?.Value ?? email.Split('@')[0];

		// Check if user exists in database
		var existingUser = await dbContext.Users.FirstOrDefaultAsync(u => u.Email == email);

		if (existingUser == null)
		{
			// Create new user from JWT claims
			var newUser = new User
			{
				Email = email,
				Username = username,
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			};

			dbContext.Users.Add(newUser);
			await dbContext.SaveChangesAsync();

			_logger.LogInformation("Created new user from JWT: {Email}", email);
		}
		else if (existingUser.Username != username)
		{
			// Update username if it has changed
			existingUser.Username = username;
			existingUser.UpdatedAt = DateTime.UtcNow;
			await dbContext.SaveChangesAsync();

			_logger.LogInformation("Updated username for user: {Email}", email);
		}
	}
}
