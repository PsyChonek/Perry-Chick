using Microsoft.EntityFrameworkCore;
using PerryChick.Api.Models;

namespace PerryChick.Api.Data;

public class AppDbContext : DbContext
{
	public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
	{
	}

	public DbSet<User> Users { get; set; }
	public DbSet<StoreItem> Chicks { get; set; }
	public DbSet<ShoppingCart> ShoppingCarts { get; set; }
	public DbSet<ShoppingCartItem> ShoppingCartItems { get; set; }

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		base.OnModelCreating(modelBuilder);

		// Configure User entity
		modelBuilder.Entity<User>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.HasIndex(e => e.Email).IsUnique();
			entity.HasIndex(e => e.KeycloakId).IsUnique(); // Unique index for Keycloak ID
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
		});

		// Configure Chick entity
		modelBuilder.Entity<StoreItem>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
		});

		// Configure ShoppingCart entity
		modelBuilder.Entity<ShoppingCart>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

			// Configure relationship with User
			entity.HasOne(sc => sc.User)
				  .WithMany(u => u.ShoppingCarts)
				  .HasForeignKey(sc => sc.UserId)
				  .OnDelete(DeleteBehavior.Cascade);
		});

		// Configure ShoppingCartItem entity
		modelBuilder.Entity<ShoppingCartItem>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");

			// Configure relationship with ShoppingCart
			entity.HasOne<ShoppingCart>()
				  .WithMany(sc => sc.Items)
				  .HasForeignKey(sci => sci.ShoppingCartId)
				  .OnDelete(DeleteBehavior.Cascade);

			// Configure relationship with StoreItem
			entity.HasOne(sci => sci.StoreItem)
				  .WithMany()
				  .HasForeignKey(sci => sci.StoreItemId)
				  .OnDelete(DeleteBehavior.Restrict);
		});

		// Seed data
		modelBuilder.Entity<User>().HasData(
			new User
			{
				Id = 1,
				Username = "Demo User",
				Email = "demo@perrystore.com",
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			}
		);

		modelBuilder.Entity<StoreItem>().HasData(
			new StoreItem
			{
				Id = 1,
				Name = "Perry",
				Description = "Classic premium item with excellent quality and reliability",
				Price = 25.99m,
				Stock = 5,
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			},
			new StoreItem
			{
				Id = 2,
				Name = "Popcorn",
				Description = "Light and fluffy snack item perfect for any occasion",
				Price = 8.99m,
				Stock = 15,
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			},
			new StoreItem
			{
				Id = 3,
				Name = "Bacon",
				Description = "Premium quality bacon strips with authentic smoky flavor",
				Price = 12.99m,
				Stock = 8,
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			}
		);
	}
}
