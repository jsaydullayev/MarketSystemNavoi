using MarketSystem.Application.Interfaces;
using MarketSystem.Application.Settings;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using System.Security.Claims;
using System.Text;

namespace MarketSystem.API.Extensions;

public static class AuthExtensions
{
    public static IServiceCollection AddJwtAuthentication(this IServiceCollection services, IConfiguration configuration, IWebHostEnvironment env)
    {
        services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
            .AddJwtBearer(options =>
            {
                var jwtParam = configuration.GetSection("Jwt").Get<JwtSetting>()!;
                var key = Encoding.UTF8.GetBytes(jwtParam.Key);
                options.TokenValidationParameters = new TokenValidationParameters
                {
                    ValidIssuer = jwtParam.Issuer,
                    ValidateIssuer = true,
                    ValidAudience = jwtParam.Audience,
                    ValidateAudience = true,
                    IssuerSigningKey = new SymmetricSecurityKey(key),
                    ValidateIssuerSigningKey = true,
                    ValidateLifetime = true,
                    ClockSkew = TimeSpan.FromMinutes(1),
                    RoleClaimType = ClaimTypes.Role,
                    NameClaimType = ClaimTypes.Name
                };

                options.RequireHttpsMetadata = !env.IsDevelopment();

                options.Events = new JwtBearerEvents
                {
                    OnMessageReceived = context =>
                    {
                        // Browser WebSocket clients can't set Authorization headers,
                        // so accept the token via ?token= ONLY on SignalR hub paths.
                        var path = context.HttpContext.Request.Path;
                        if (string.IsNullOrEmpty(context.Token) &&
                            path.StartsWithSegments("/hubs"))
                        {
                            var queryToken = context.Request.Query["token"].ToString();
                            if (!string.IsNullOrEmpty(queryToken))
                                context.Token = queryToken;
                        }
                        return Task.CompletedTask;
                    },
                    OnTokenValidated = context =>
                    {
                        // Reject access tokens whose jti has been revoked (logout,
                        // refresh rotation, suspicious-refresh defensive revoke).
                        var jti = context.Principal?.FindFirst(
                            System.IdentityModel.Tokens.Jwt.JwtRegisteredClaimNames.Jti)?.Value;
                        if (!string.IsNullOrEmpty(jti))
                        {
                            var store = context.HttpContext.RequestServices
                                .GetRequiredService<IRevokedTokenStore>();
                            if (store.IsRevoked(jti))
                                context.Fail("Token has been revoked.");
                        }
                        return Task.CompletedTask;
                    }
                };
            });

        return services;
    }

    public static IServiceCollection AddAuthorizationPolicies(this IServiceCollection services)
    {
        services.AddAuthorization(options =>
        {
            options.AddPolicy("OwnerOnly", policy => policy.RequireRole("Owner"));
            options.AddPolicy("AdminOrOwner", policy => policy.RequireRole("Owner", "Admin"));
            options.AddPolicy("OwnerOrSuperAdmin", policy => policy.RequireRole("Owner", "SuperAdmin"));
            options.AddPolicy("AllRoles", policy => policy.RequireRole("Owner", "Admin", "Seller", "SuperAdmin"));
        });

        return services;
    }
}
