namespace PerryChick.Api.Services;

public interface IUserContext
{
	int? UserId { get; }
	string? Email { get; }
	string? Username { get; }
	bool IsAuthenticated { get; }
	IEnumerable<string> Roles { get; }
	bool HasRole(string role);
}
