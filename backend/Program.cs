using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Serilog;
using PerryChick.Api.Data;
using PerryChick.Api.Models;
using PerryChick.Api.Services;
using PerryChick.Api.Middleware;
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
		// Get CORS origins from environment variables with fallback
		var corsOrigins = Environment.GetEnvironmentVariable("CORS_ALLOWED_ORIGINS") ??
						 "http://localhost:3000,http://localhost:5173,http://localhost:8080";

		var allowedOrigins = corsOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries)
										.Select(origin => origin.Trim())
										.ToArray();

		// Get CORS methods from environment variables with fallback
		var corsMethods = Environment.GetEnvironmentVariable("CORS_ALLOWED_METHODS") ??
						 "GET,POST,PUT,DELETE,OPTIONS,PATCH";

		var allowedMethods = corsMethods.Split(',', StringSplitOptions.RemoveEmptyEntries)
									   .Select(method => method.Trim())
									   .ToArray();

		// Get CORS headers from environment variables with fallback
		var corsHeaders = Environment.GetEnvironmentVariable("CORS_ALLOWED_HEADERS") ??
						 "Origin,Accept,X-Requested-With,Content-Type,Access-Control-Request-Method,Access-Control-Request-Headers,Authorization";

		var allowedHeaders = corsHeaders.Split(',', StringSplitOptions.RemoveEmptyEntries)
									   .Select(header => header.Trim())
									   .ToArray();

		policy.WithOrigins(allowedOrigins)
			  .WithMethods(allowedMethods)
			  .WithHeaders(allowedHeaders)
			  .AllowCredentials();

		Log.Information("CORS configured with origins: {Origins}", string.Join(", ", allowedOrigins));
	});
});// Add JWT Authentication
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

// Add custom services for user context
builder.Services.AddScoped<IUserContext, UserContext>();
builder.Services.AddHttpContextAccessor();

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

// Add custom middleware for user synchronization
app.UseMiddleware<UserSyncMiddleware>();

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
	Message = "🏪 Perry Store API",
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

// Authentication info endpoint
app.MapGet("/api/auth/whoami", (IUserContext userContext) =>
{
	if (!userContext.IsAuthenticated)
		return Results.Unauthorized();

	return Results.Ok(new
	{
		UserId = userContext.UserId,
		Email = userContext.Email,
		Username = userContext.Username,
		IsAuthenticated = userContext.IsAuthenticated,
		Roles = userContext.Roles.ToArray()
	});
})
.WithName("WhoAmI")
.WithTags("Authentication")
.RequireAuthorization();

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

	user.Username = inputUser.Username;
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

// Store Item endpoints
app.MapGet("/api/items", async (AppDbContext db) =>
{
	return await db.Chicks.ToListAsync();
})
.WithName("GetStoreItems")
.WithTags("Store Items")
.RequireAuthorization();

app.MapGet("/api/items/{id}", async (int id, AppDbContext db) =>
{
	var item = await db.Chicks.FirstOrDefaultAsync(i => i.Id == id);
	return item is not null ? Results.Ok(item) : Results.NotFound();
})
.WithName("GetStoreItem")
.WithTags("Store Items")
.RequireAuthorization();

app.MapPost("/api/items", async (StoreItem item, AppDbContext db) =>
{
	item.CreatedAt = DateTime.UtcNow;
	db.Chicks.Add(item);
	await db.SaveChangesAsync();
	return Results.Created($"/api/items/{item.Id}", item);
})
.WithName("CreateStoreItem")
.WithTags("Store Items")
.RequireAuthorization();

app.MapPut("/api/items/{id}", async (int id, StoreItem inputItem, AppDbContext db) =>
{
	var item = await db.Chicks.FindAsync(id);
	if (item is null) return Results.NotFound();

	item.Name = inputItem.Name;
	item.Description = inputItem.Description;
	item.Price = inputItem.Price;
	item.Stock = inputItem.Stock;
	item.UpdatedAt = DateTime.UtcNow;

	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("UpdateStoreItem")
.WithTags("Store Items")
.RequireAuthorization();

app.MapDelete("/api/items/{id}", async (int id, AppDbContext db) =>
{
	var item = await db.Chicks.FindAsync(id);
	if (item is null) return Results.NotFound();

	db.Chicks.Remove(item);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("DeleteStoreItem")
.WithTags("Store Items")
.RequireAuthorization();

// Shopping Cart endpoints
app.MapGet("/api/cart", async (IUserContext userContext, AppDbContext db) =>
{
	if (!userContext.IsAuthenticated || !userContext.UserId.HasValue)
		return Results.Unauthorized();

	var userId = userContext.UserId.Value;
	var cart = await db.ShoppingCarts
		.Include(sc => sc.Items)
		.ThenInclude(sci => sci.StoreItem)
		.FirstOrDefaultAsync(sc => sc.UserId == userId && sc.IsActive);

	if (cart is null)
	{
		// Create a new cart if none exists
		cart = new ShoppingCart
		{
			UserId = userId,
			CreatedAt = DateTime.UtcNow
		};
		db.ShoppingCarts.Add(cart);
		await db.SaveChangesAsync();
	}

	return Results.Ok(cart);
})
.WithName("GetMyShoppingCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapGet("/api/cart/{userId}", async (int userId, AppDbContext db) =>
{
	var cart = await db.ShoppingCarts
		.Include(sc => sc.Items)
		.ThenInclude(sci => sci.StoreItem)
		.FirstOrDefaultAsync(sc => sc.UserId == userId && sc.IsActive);

	if (cart is null)
	{
		// Create a new cart if none exists
		cart = new ShoppingCart
		{
			UserId = userId,
			CreatedAt = DateTime.UtcNow
		};
		db.ShoppingCarts.Add(cart);
		await db.SaveChangesAsync();
	}

	return Results.Ok(cart);
})
.WithName("GetShoppingCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapPost("/api/cart/items", async (ShoppingCartItem cartItem, IUserContext userContext, AppDbContext db) =>
{
	if (!userContext.IsAuthenticated || !userContext.UserId.HasValue)
		return Results.Unauthorized();

	var userId = userContext.UserId.Value;

	// Get or create shopping cart for user
	var cart = await db.ShoppingCarts
		.FirstOrDefaultAsync(sc => sc.UserId == userId && sc.IsActive);

	if (cart is null)
	{
		cart = new ShoppingCart
		{
			UserId = userId,
			CreatedAt = DateTime.UtcNow
		};
		db.ShoppingCarts.Add(cart);
		await db.SaveChangesAsync();
	}

	// Check if item already exists in cart
	var existingItem = await db.ShoppingCartItems
		.FirstOrDefaultAsync(sci => sci.ShoppingCartId == cart.Id &&
									sci.StoreItemId == cartItem.StoreItemId &&
									sci.IsActive);

	if (existingItem != null)
	{
		// Update quantity if item already exists
		existingItem.Quantity += cartItem.Quantity;
		existingItem.UpdatedAt = DateTime.UtcNow;
	}
	else
	{
		// Add new item to cart
		cartItem.ShoppingCartId = cart.Id;
		cartItem.CreatedAt = DateTime.UtcNow;
		db.ShoppingCartItems.Add(cartItem);
	}

	await db.SaveChangesAsync();
	return Results.Created($"/api/cart/items/{cartItem.Id}", cartItem);
})
.WithName("AddItemToMyCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapPut("/api/cart/items/{itemId}", async (int itemId, ShoppingCartItem inputItem, AppDbContext db) =>
{
	var cartItem = await db.ShoppingCartItems.FindAsync(itemId);
	if (cartItem is null) return Results.NotFound();

	cartItem.Quantity = inputItem.Quantity;
	cartItem.UpdatedAt = DateTime.UtcNow;

	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("UpdateCartItem")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapDelete("/api/cart/items/{itemId}", async (int itemId, AppDbContext db) =>
{
	var cartItem = await db.ShoppingCartItems.FindAsync(itemId);
	if (cartItem is null) return Results.NotFound();

	db.ShoppingCartItems.Remove(cartItem);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("RemoveItemFromCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapDelete("/api/cart/clear", async (IUserContext userContext, AppDbContext db) =>
{
	if (!userContext.IsAuthenticated || !userContext.UserId.HasValue)
		return Results.Unauthorized();

	var userId = userContext.UserId.Value;
	var cart = await db.ShoppingCarts
		.Include(sc => sc.Items)
		.FirstOrDefaultAsync(sc => sc.UserId == userId && sc.IsActive);

	if (cart is null) return Results.NotFound();

	db.ShoppingCartItems.RemoveRange(cart.Items);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("ClearMyCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

app.MapDelete("/api/cart/{userId}/clear", async (int userId, AppDbContext db) =>
{
	var cart = await db.ShoppingCarts
		.Include(sc => sc.Items)
		.FirstOrDefaultAsync(sc => sc.UserId == userId && sc.IsActive);

	if (cart is null) return Results.NotFound();

	db.ShoppingCartItems.RemoveRange(cart.Items);
	await db.SaveChangesAsync();
	return Results.NoContent();
})
.WithName("ClearCart")
.WithTags("Shopping Cart")
.RequireAuthorization();

Log.Information("🚀 Starting Perry Chick API on {Environment}", app.Environment.EnvironmentName);

app.Run();
