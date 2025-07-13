using Microsoft.EntityFrameworkCore;
using PerryChick.Api.Models;

namespace PerryChick.Api.Data;

public class AppDbContext : DbContext
{
	public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
	{
	}

	public DbSet<User> Users { get; set; }
	public DbSet<Chick> Chicks { get; set; }

	protected override void OnModelCreating(ModelBuilder modelBuilder)
	{
		base.OnModelCreating(modelBuilder);

		// Configure User entity
		modelBuilder.Entity<User>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.HasIndex(e => e.Email).IsUnique();
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
		});

		// Configure Chick entity
		modelBuilder.Entity<Chick>(entity =>
		{
			entity.HasKey(e => e.Id);
			entity.Property(e => e.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
			entity.Property(e => e.Weight).HasPrecision(5, 2);

			// Configure relationship
			entity.HasOne(c => c.User)
				  .WithMany()
				  .HasForeignKey(c => c.UserId)
				  .OnDelete(DeleteBehavior.Cascade);
		});

		// Seed data
		modelBuilder.Entity<User>().HasData(
			new User
			{
				Id = 1,
				Name = "Demo User",
				Email = "demo@perrychick.com",
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			}
		);

		modelBuilder.Entity<Chick>().HasData(
			new Chick
			{
				Id = 1,
				Name = "Perry",
				Breed = "Rhode Island Red",
				HatchDate = DateTime.UtcNow.AddDays(-30),
				Color = "Red",
				Weight = 0.5m,
				UserId = 1,
				CreatedAt = DateTime.UtcNow,
				IsActive = true
			}
		);
	}
}
