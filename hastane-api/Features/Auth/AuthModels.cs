namespace Ozi.Features.Auth;

public record LoginRequest(string Username, string Password);

public record UserDto(string Username, string DisplayName, string Role);

public record LoginResponse(string Token, DateTime ExpiresAt, UserDto User);
