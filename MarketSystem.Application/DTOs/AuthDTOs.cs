namespace MarketSystem.Application.DTOs;

public record LoginRequest(string Username, string Password);
public record AuthResponse(Guid UserId, string Username, string FullName, string Role, string Token);
public record RefreshTokenRequest(string Token);
