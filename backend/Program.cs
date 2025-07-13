using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Serilog;
using PerryChick.Api.Data;
using PerryChick.Api.Models;
using DotNetEnv;

// Load .env file from root directory
var rootDir = Directory.GetParent(Directory.GetCurrentDirectory())?.FullName;
if (rootDir != null)
{
	var envPath = Path.Combine(rootDir, ".env.local");
	if (File.Exists(envPath))
	{
		Env.Load(envPath);
	}
}

// Configure Serilog
Log.Logger = new LoggerConfiguration()
	.MinimumLevel.Information()
	.WriteTo.Console()
	.WriteTo.File("logs/perrychick-.txt", rollingInterval: RollingInterval.Day)
	.CreateLogger();

var builder = WebApplication.CreateBuilder(args);

// Use Serilog for logging
builder.Host.UseSerilog();

// Add services to the container
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
	c.SwaggerDoc("v1", new() { Title = "Perry Chick API", Version = "v1" });
});

// Add database context
builder.Services.AddDbContext<AppDbContext>(options =>
	options.UseNpgsql(Environment.GetEnvironmentVariable("DATABASE_URL")
					 ?? builder.Configuration.GetConnectionString("DefaultConnection")));

// Add CORS
builder.Services.AddCors(options =>
{
	options.AddPolicy("AllowFrontend", policy =>
	{
		policy.WithOrigins(Environment.GetEnvironmentVariable("FRONTEND_URL") ?? "http://localhost:3000")
			  .AllowAnyMethod()
			  .AllowAnyHeader()
			  .AllowCredentials();
	});
});

// Add JWT Authentication
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
	.AddJwtBearer(options =>
	{
		options.Authority = Environment.GetEnvironmentVariable("KEYCLOAK_URL");
		options.Audience = Environment.GetEnvironmentVariable("KEYCLOAK_CLIENT_ID");
		options.RequireHttpsMetadata = false; // Only for development

		options.TokenValidationParameters = new TokenValidationParameters
		{
			ValidateIssuer = true,
			ValidateAudience = true,
			ValidateLifetime = true,
			ValidateIssuerSigningKey = true,
			ClockSkew = TimeSpan.Zero
		};
	});

builder.Services.AddAuthorization();

var app = builder.Build();

// Configure the HTTP request pipeline
if (app.Environment.IsDevelopment())
{
	app.UseSwagger();
	app.UseSwaggerUI(c => c.SwaggerEndpoint("/swagger/v1/swagger.json", "Perry Chick API v1"));
}

app.UseCors("AllowFrontend");
app.UseAuthentication();
app.UseAuthorization();

// Ensure database is created (only if connection is available)
try
{
	using (var scope = app.Services.CreateScope())
	{
		var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
		context.Database.EnsureCreated();
	}
}
catch (Exception ex)
{
	Log.Warning("Database connection failed: {Message}. Continuing without database.", ex.Message);
}

// API Endpoints
app.MapGet("/", () => new
{
	Message = "🐣 Perry Chick API",
	Version = "1.0.0",
	Environment = app.Environment.EnvironmentName,
	Timestamp = DateTime.UtcNow
})
.WithName("GetRoot")
.WithTags("Health");

app.MapGet("/health", () => new
{
	Status = "Healthy",
	Timestamp = DateTime.UtcNow,
	Version = "1.0.0"
})
.WithName("HealthCheck")
.WithTags("Health");

// Configuration endpoint (development only)
app.MapGet("/config", () => new
{
	DatabaseUrl = Environment.GetEnvironmentVariable("DATABASE_URL") != null ? "✅ Loaded from .env" : "❌ Not found",
	FrontendUrl = Environment.GetEnvironmentVariable("FRONTEND_URL") ?? "❌ Not found",
	KeycloakUrl = Environment.GetEnvironmentVariable("KEYCLOAK_URL") ?? "❌ Not found",
	KeycloakClientId = Environment.GetEnvironmentVariable("KEYCLOAK_CLIENT_ID") ?? "❌ Not found"
})
.WithName("GetConfig")
.WithTags("Development");

// User endpoints
app.MapGet("/api/users", async (AppDbContext db) =>
{
	return await db.Users.ToListAsync();
})
.WithName("GetUsers")
.WithTags("Users")
.RequireAuthorization();

app.MapGet("/api/users/{id}", async (int id, AppDbContext db) =>
{
	var user = await db.Users.FindAsync(id);
	return user is not null ? Results.Ok(user) : Results.NotFound();
})
.WithName("GetUser")
.WithTags("Users")
.RequireAuthorization();

app.MapPost("/api/users", async (User user, AppDbContext db) =>
{
	user.CreatedAt = DateTime.UtcNow;
	db.Users.Add(user);
	await db.SaveChangesAsync();
	return Results.Created($"/api/users/{user.Id}", user);
})
.WithName("CreateUser")
.WithTags("Users");

app.MapPut("/api/users/{id}", async (int id, User inputUser, AppDbContext db) =>
{
	var user = await db.Users.FindAsync(id);
	if (user is null) return Results.NotFound();

	user.Name = inputUser.Name;
	user.Email = inputUser.Email;
	user.UpdatedAt = DateTime.UtcNow;

	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("UpdateUser")
.WithTags("Users")
.RequireAuthorization();

app.MapDelete("/api/users/{id}", async (int id, AppDbContext db) =>
{
	var user = await db.Users.FindAsync(id);
	if (user is null) return Results.NotFound();

	db.Users.Remove(user);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("DeleteUser")
.WithTags("Users")
.RequireAuthorization();

// Chick endpoints
app.MapGet("/api/chicks", async (AppDbContext db) =>
{
	return await db.Chicks.Include(c => c.User).ToListAsync();
})
.WithName("GetChicks")
.WithTags("Chicks")
.RequireAuthorization();

app.MapGet("/api/chicks/{id}", async (int id, AppDbContext db) =>
{
	var chick = await db.Chicks.Include(c => c.User).FirstOrDefaultAsync(c => c.Id == id);
	return chick is not null ? Results.Ok(chick) : Results.NotFound();
})
.WithName("GetChick")
.WithTags("Chicks")
.RequireAuthorization();

app.MapPost("/api/chicks", async (Chick chick, AppDbContext db) =>
{
	// Verify user exists
	var userExists = await db.Users.AnyAsync(u => u.Id == chick.UserId);
	if (!userExists) return Results.BadRequest("User not found");

	chick.CreatedAt = DateTime.UtcNow;
	db.Chicks.Add(chick);
	await db.SaveChangesAsync();
	return Results.Created($"/api/chicks/{chick.Id}", chick);
})
.WithName("CreateChick")
.WithTags("Chicks")
.RequireAuthorization();

app.MapPut("/api/chicks/{id}", async (int id, Chick inputChick, AppDbContext db) =>
{
	var chick = await db.Chicks.FindAsync(id);
	if (chick is null) return Results.NotFound();

	chick.Name = inputChick.Name;
	chick.Breed = inputChick.Breed;
	chick.Color = inputChick.Color;
	chick.Weight = inputChick.Weight;
	chick.UpdatedAt = DateTime.UtcNow;

	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("UpdateChick")
.WithTags("Chicks")
.RequireAuthorization();

app.MapDelete("/api/chicks/{id}", async (int id, AppDbContext db) =>
{
	var chick = await db.Chicks.FindAsync(id);
	if (chick is null) return Results.NotFound();

	db.Chicks.Remove(chick);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("DeleteChick")
.WithTags("Chicks")
.RequireAuthorization();

// Get chicks by user
app.MapGet("/api/users/{userId}/chicks", async (int userId, AppDbContext db) =>
{
	return await db.Chicks.Where(c => c.UserId == userId).ToListAsync();
})
.WithName("GetChicksByUser")
.WithTags("Chicks")
.RequireAuthorization();

Log.Information("🚀 Starting Perry Chick API on {Environment}", app.Environment.EnvironmentName);

app.Run();
