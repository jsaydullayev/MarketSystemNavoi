using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Settings;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace MarketSystem.Application.Services;

public class JwtService : IJwtService
{
    private readonly JwtSetting _jwtSetting;
    private readonly ILogger<JwtService> logger;

    public JwtService(IConfiguration configuration, ILogger<JwtService> logger)
    {
        this.logger = logger;
        _jwtSetting = configuration.GetSection("Jwt").Get<JwtSetting>()
            ?? throw new InvalidOperationException(
                "JWT configuration section is missing. Set Jwt:Key, Jwt:Issuer, Jwt:Audience.");

        // S5 — every JWT operation (sign / verify) depends on Key being a
        // non-empty, sufficiently long secret. Program.cs does the same check
        // at startup, but Scoped services are re-resolved per request, so if
        // configuration was hot-reloaded to an empty Key we'd start signing
        // tokens with a zero-length HMAC key. Fail loudly here so we never
        // silently accept the fallback.
        if (string.IsNullOrWhiteSpace(_jwtSetting.Key) || _jwtSetting.Key.Length < 32)
            throw new InvalidOperationException(
                "Jwt:Key is missing or shorter than 32 characters. " +
                "JWT signing cannot proceed with a weak / empty key.");

        if (string.IsNullOrWhiteSpace(_jwtSetting.Issuer))
            throw new InvalidOperationException("Jwt:Issuer is missing.");
        if (string.IsNullOrWhiteSpace(_jwtSetting.Audience))
            throw new InvalidOperationException("Jwt:Audience is missing.");
    }

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

        // Owner RBAC — embed the effective permission set as "perm" claims so
        // [RequirePermission] can authorize without a DB round-trip. Owner and
        // SuperAdmin bypass permission checks entirely, so their (full) set is
        // not embedded — this keeps their tokens small.
        if (user.Role is not (Role.Owner or Role.SuperAdmin))
        {
            foreach (var permission in user.GetEffectivePermissions())
            {
                claims.Add(new Claim("perm", permission));
            }
        }

        claims.Add(new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()));

        // "iat" — token qachon berilgani (Unix soniya, RFC 7519 bo'yicha raqamli claim).
        // Busiz access token'ni User.TokensInvalidBeforeUtc bilan solishtirib bo'lmaydi:
        // parol o'zgargan / user o'chirilgan bo'lsa ham eski token to'liq TTL davomida
        // (30 daqiqagacha) ishlayverardi. OnTokenValidated (Program.cs) shu claim'ni
        // epoch bilan taqqoslab, eski tokenni darhol rad etadi.
        claims.Add(new Claim(
            JwtRegisteredClaimNames.Iat,
            DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(),
            ClaimValueTypes.Integer64));

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
