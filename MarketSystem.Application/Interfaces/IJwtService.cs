using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;

namespace MarketSystem.Application.Interfaces;

public interface IJwtService
{
    TokenDto GenerateToken(User user, bool populateExp);
    Tuple<bool, string?> ValidateAndGetUser(string token);

    /// <summary>
    /// Extracts the <c>jti</c> claim and original expiry from an access token.
    /// Used by Logout / RefreshToken so we can revoke the exact token that's
    /// currently in the user's hands. Returns null on a malformed token.
    /// </summary>
    (string Jti, DateTime ExpiresAtUtc)? GetJtiAndExpiry(string token);
}