using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Settings;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace MarketSystem.Application.Services;

public class JwtService(IConfiguration configuration, ILogger<JwtService> logger) : IJwtService
{
    private readonly JwtSetting _jwtSetting = configuration.GetSection("Jwt")
        .Get<JwtSetting>()!;

    public TokenDto GenerateToken(User user, bool populateExp)
    {
        var key = Encoding.UTF8.GetBytes(_jwtSetting.Key);
        var credentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>()
        {
            new (ClaimTypes.NameIdentifier, user.Id.ToString()),
            new (ClaimTypes.Name, user.Username),
            new (ClaimTypes.Role, user.Role.ToString()!)
        };

        // MarketId null bo'lsa claim qo'shmaslik (Owner uchun market hali yaratilmagan bo'lishi mumkin)
        if (user.MarketId.HasValue)
        {
            claims.Add(new Claim("MarketId", user.MarketId.Value.ToString()));
        }

        claims.Add(new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()));

        var security = new JwtSecurityToken(
            issuer: _jwtSetting.Issuer,
            audience: _jwtSetting.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_jwtSetting.AccessTokenExpireMinutes),
            signingCredentials: credentials
        );

        var accessToken = new JwtSecurityTokenHandler().WriteToken(security);
        return new TokenDto(AccessToken: accessToken, RefreshToken: string.Empty);
    }

    public (string Jti, DateTime ExpiresAtUtc)? GetJtiAndExpiry(string token)
    {
        // We parse but DON'T verify the signature here — the caller is using
        // this to revoke a token they already validated through the JwtBearer
        // middleware. ReadJwtToken does no cryptographic work.
        try
        {
            var handler = new JwtSecurityTokenHandler();
            if (!handler.CanReadToken(token)) return null;
            var jwt = handler.ReadJwtToken(token);
            var jti = jwt.Claims.FirstOrDefault(c => c.Type == JwtRegisteredClaimNames.Jti)?.Value;
            if (string.IsNullOrEmpty(jti)) return null;
            return (jti, jwt.ValidTo == DateTime.MinValue
                ? DateTime.UtcNow.AddMinutes(_jwtSetting.AccessTokenExpireMinutes)
                : jwt.ValidTo);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "GetJtiAndExpiry: failed to read token claims.");
            return null;
        }
    }

    public Tuple<bool, string?> ValidateAndGetUser(string token)
    {
        var key = Encoding.UTF8.GetBytes(_jwtSetting.Key);
        var options = new TokenValidationParameters()
        {
            ValidIssuer = _jwtSetting.Issuer,
            ValidateIssuer = true,
            ValidAudience = _jwtSetting.Audience,
            ValidateAudience = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuerSigningKey = true,
            // Refresh flow needs to read claims from an expired access token.
            // Lifetime is enforced by the refresh-token's own ExpiresAt check.
            ValidateLifetime = false
        };

        try
        {
            var tokenHandler = new JwtSecurityTokenHandler();
            var principal = tokenHandler.ValidateToken(token, options, out var securityToken);
            var jwtSecurityToken = securityToken as JwtSecurityToken;

            if (jwtSecurityToken is null || !jwtSecurityToken.Header.Alg.Equals("HS256",
                StringComparison.InvariantCultureIgnoreCase))
                return new(false, null);

            var name = principal.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(name))
            {
                return new(false, null);
            }
            return new(true, name);
        }
        catch (Exception ex)
        {
            logger.LogDebug(ex, "ValidateAndGetUser: token validation failed (malformed or expired).");
            return new(false, null);
        }
    }
}
