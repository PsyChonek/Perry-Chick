using System.Security.Claims;
using System.Text.Json;

namespace PerryChick.Api.Services;

public class UserContext : IUserContext
{
	private readonly IHttpContextAccessor _httpContextAccessor;

	public UserContext(IHttpContextAccessor httpContextAccessor)
	{
		_httpContextAccessor = httpContextAccessor;
	}

	public int? UserId
	{
		get
		{
			var userIdClaim = _httpContextAccessor.HttpContext?.User?.FindFirst("sub")
						   ?? _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.NameIdentifier);

			if (userIdClaim != null && int.TryParse(userIdClaim.Value, out var userId))
			{
				return userId;
			}
			return null;
		}
	}

	public string? Email => _httpContextAccessor.HttpContext?.User?.FindFirst("email")?.Value
						 ?? _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.Email)?.Value;

	public string? Username => _httpContextAccessor.HttpContext?.User?.FindFirst("preferred_username")?.Value
							?? _httpContextAccessor.HttpContext?.User?.FindFirst("name")?.Value
							?? _httpContextAccessor.HttpContext?.User?.FindFirst(ClaimTypes.Name)?.Value;

	public bool IsAuthenticated => _httpContextAccessor.HttpContext?.User?.Identity?.IsAuthenticated ?? false;

	public IEnumerable<string> Roles
	{
		get
		{
			var user = _httpContextAccessor.HttpContext?.User;
			if (user == null) return Enumerable.Empty<string>();

			// First try to get roles from realm_access claim (Keycloak format)
			var realmAccessClaim = user.FindFirst("realm_access")?.Value;
			if (!string.IsNullOrEmpty(realmAccessClaim))
			{
				try
				{
					var realmAccess = JsonSerializer.Deserialize<JsonElement>(realmAccessClaim);
					if (realmAccess.TryGetProperty("roles", out var rolesElement) && rolesElement.ValueKind == JsonValueKind.Array)
					{
						return rolesElement.EnumerateArray().Select(role => role.GetString()).Where(r => !string.IsNullOrEmpty(r))!;
					}
				}
				catch (JsonException)
				{
					// If JSON parsing fails, fall back to other methods
				}
			}

			// Fallback to standard role claims
			return user.FindAll("realm_access.roles")?.Select(c => c.Value)
				   ?? user.FindAll(ClaimTypes.Role)?.Select(c => c.Value)
				   ?? Enumerable.Empty<string>();
		}
	}

	public bool HasRole(string role)
	{
		return Roles.Contains(role, StringComparer.OrdinalIgnoreCase);
	}
}
