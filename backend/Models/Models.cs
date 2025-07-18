using System.ComponentModel.DataAnnotations;

namespace PerryChick.Api.Models;

public class User
{
	public int Id { get; set; }

	/// <summary>
	/// Keycloak user ID (sub claim from JWT token)
	/// This is the primary identifier that links to Keycloak
	/// </summary>
	[Required]
	[StringLength(255)]
	public string KeycloakId { get; set; } = string.Empty;

	[Required]
	[StringLength(100)]
	public string Username { get; set; } = string.Empty;

	[Required]
	[EmailAddress]
	[StringLength(255)]
	public string Email { get; set; } = string.Empty;

	/// <summary>
	/// Application-specific user data not stored in Keycloak
	/// </summary>
	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public DateTime? LastLoginAt { get; set; }

	public bool IsActive { get; set; } = true;

	/// <summary>
	/// Application-specific preferences
	/// </summary>
	public string? Preferences { get; set; } // JSON string for user preferences

	/// <summary>
	/// Shopping carts associated with this user
	/// </summary>
	public List<ShoppingCart> ShoppingCarts { get; set; } = new List<ShoppingCart>();
}

public class StoreItem
{
	public int Id { get; set; }

	[Required]
	[StringLength(100)]
	public string Name { get; set; } = string.Empty;

	[Required]
	[StringLength(500)]
	public string Description { get; set; } = string.Empty;

	public decimal Price { get; set; }

	public int Stock { get; set; }

	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public bool IsActive { get; set; } = true;
}

public class ShoppingCart
{
	public int Id { get; set; }

	public int UserId { get; set; }

	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public bool IsActive { get; set; } = true;

	/// <summary>
	/// Navigation property to the User who owns this cart
	/// </summary>
	public User User { get; set; } = new User();

	public List<ShoppingCartItem> Items { get; set; } = new List<ShoppingCartItem>();
}

public class ShoppingCartItem
{
	public int Id { get; set; }

	public int ShoppingCartId { get; set; }

	public int StoreItemId { get; set; }

	public int Quantity { get; set; } = 1;

	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public bool IsActive { get; set; } = true;

	public StoreItem StoreItem { get; set; } = new StoreItem();
}
