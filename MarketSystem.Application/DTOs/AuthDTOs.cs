namespace MarketSystem.Application.DTOs;

public record LoginRequest(string Username, string Password);
public record RegisterRequest(string FullName, string Username, string Password, string Role);
public record RefreshTokenRequest(string AccessToken, string RefreshToken);
public record AuthResponse(Guid UserId, string Username, string FullName, string Role, string AccessToken, string RefreshToken, DateTime ExpiresAt);
