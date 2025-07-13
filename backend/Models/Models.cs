using System.ComponentModel.DataAnnotations;

namespace PerryChick.Api.Models;

public class User
{
	public int Id { get; set; }

	[Required]
	[StringLength(100)]
	public string Name { get; set; } = string.Empty;

	[Required]
	[EmailAddress]
	[StringLength(255)]
	public string Email { get; set; } = string.Empty;

	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public bool IsActive { get; set; } = true;
}

public class Chick
{
	public int Id { get; set; }

	[Required]
	[StringLength(100)]
	public string Name { get; set; } = string.Empty;

	[StringLength(50)]
	public string Breed { get; set; } = string.Empty;

	public DateTime HatchDate { get; set; }

	public string Color { get; set; } = string.Empty;

	public decimal Weight { get; set; }

	public int UserId { get; set; }
	public User User { get; set; } = null!;

	public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

	public DateTime? UpdatedAt { get; set; }

	public bool IsActive { get; set; } = true;
}
