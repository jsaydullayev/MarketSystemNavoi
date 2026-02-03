using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Common;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;

namespace MarketSystem.Application.Services;

public class JwtService(IConfiguration configuration) : IJwtService
{

    private readonly JwtSetting _jwtSetting = configuration.GetSection("Jwt")
        .Get<JwtSetting>()!;

    public TokenDto GenerateToken(User user, bool populateExp)
    {
        var key = Encoding.UTF32.GetBytes(_jwtSetting.Key);
        var credentials = new SigningCredentials(new SymmetricSecurityKey(key), SecurityAlgorithms.HmacSha256);
        var claims = new List<Claim>()
        {
            new (ClaimTypes.NameIdentifier, user.Id.ToString()),
            new (ClaimTypes.Name, user.Username),
            new (ClaimTypes.Role, user.Role.ToString()!)
        };

        var security = new JwtSecurityToken(
            issuer: _jwtSetting.Issuer,
            audience: _jwtSetting.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: credentials
        );

        var accessToken = new JwtSecurityTokenHandler().WriteToken(security);
        return new TokenDto(AccessToken: accessToken, RefreshToken: string.Empty);
    }

    public Tuple<bool, string?> ValidateAndGetUser(string token)
    {
        var key = Encoding.UTF32.GetBytes(_jwtSetting.Key);
        var options = new TokenValidationParameters()
        {
            ValidIssuer = _jwtSetting.Issuer,
            ValidateIssuer = true,
            ValidAudience = _jwtSetting.Audience,
            ValidateAudience = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuerSigningKey = true,
            ValidateLifetime = true
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var principal = tokenHandler.ValidateToken(token, options, out var securityToken);
        var jwtSecurityToken = securityToken as JwtSecurityToken;

        if (jwtSecurityToken is null || !jwtSecurityToken.Header.Alg.Equals(SecurityAlgorithms.HmacSha256,
            StringComparison.InvariantCultureIgnoreCase))
            return new(false, null);

        var name = principal.Claims.FirstOrDefault(c => c.Type == ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(name))
        {
            return new(false, null);
        }
        return new(true, name);
    }
}
