using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IAuthService
{
    Task<AuthResponse?> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse?> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse?> RefreshTokenAsync(RefreshTokenRequest request, CancellationToken cancellationToken = default);
    Task<bool> LogoutAsync(string refreshToken, Guid callerUserId, CancellationToken cancellationToken = default);
}
