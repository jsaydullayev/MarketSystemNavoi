using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Common;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;

namespace MarketSystem.Application.Services;

public class JwtService(IConfiguration configuration) : IJwtService
{

    private readonly JwtSetting _jwtSetting = configuration.GetSection("JwtSettings")
        .Get<JwtSetting>()!;

    public TokenDto GenerateToken(User user, bool populateExp)
    {
        /*
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(
            _configuration["Jwt:Key"] ?? throw new InvalidOperationException("JWT Key not configured")));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expires = DateTime.UtcNow.AddDays(Convert.ToDouble(
            _configuration["Jwt:ExpireDays"] ?? "7"));

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(ClaimTypes.Name, user.Username),
            new(ClaimTypes.GivenName, user.FullName),
            new(ClaimTypes.Role, user.Role.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: expires,
            signingCredentials: credentials
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
        */

        var key = Encoding.UTF32.GetBytes(_jwtSetting.Key);
        var signingKey = new SigningCredentials(new SymmetricSecurityKey(key), "H256");
        var claims = new List<Claim>()
        {
            new (ClaimTypes.NameIdentifier, user.Id.ToString()),
            new (ClaimTypes.Name, user.Username),
            new (ClaimTypes.Role, user.Role.ToString()!)
        };

        var security = new JwtSecurityToken(issuer: _jwtSetting.Issuer,
            audience: _jwtSetting.Audience,
            claims: claims,
            expires: DateTime.Now.AddMinutes(2)
            );

        var accessToken = new JwtSecurityTokenHandler().WriteToken(security);
        if (populateExp)
        {
            var refreshToken = GenerateRefreshToken();
            user.RefreshToken = refreshToken;
            user.RefreshTokenExpireTime = DateTime.Now.AddDays(7);
        }
        return new TokenDto(AccessToken: accessToken, RefreshToken: user.RefreshToken!);
    }

    private string GenerateRefreshToken()
    {
        var randomNumber = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);

        return Convert.ToBase64String(randomNumber);
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
