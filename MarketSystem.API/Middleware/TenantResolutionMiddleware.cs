using System.Net;
using System.Security.Claims;
using MarketSystem.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.API.Middleware;

public class TenantResolutionMiddleware
{
    // Allocated once at startup — not per request.
    private static readonly string[] SkipPaths =
    [
        "/api/Auth/Login",
        "/api/Auth/Register",
        "/api/Auth/RefreshToken",
        "/api/Auth/Logout",
        "/api/_sa",              // SuperAdmin console — no MarketId claim
        "/api/RegistrationRequests", // public sign-up — anonymous
        "/health",
        "/swagger",
        "/privacy",
        "/hubs",
        "/seed"
    ];

    private readonly RequestDelegate _next;
    private readonly ILogger<TenantResolutionMiddleware> _logger;

    public TenantResolutionMiddleware(RequestDelegate next, ILogger<TenantResolutionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, IAppDbContext dbContext)
    {
        var path = context.Request.Path.Value ?? "";

        if (SkipPaths.Any(p => path.StartsWith(p, StringComparison.OrdinalIgnoreCase)))
        {
            await _next(context);
            return;
        }

        // If unauthenticated, let the normal auth pipeline return 401.
        // Resolving tenant here would mask the real auth failure.
        if (context.User?.Identity?.IsAuthenticated != true)
        {
            await _next(context);
            return;
        }

        // Priority 1: MarketId claim from JWT token
        var marketIdClaim = context.User.FindFirst("MarketId")?.Value;
        if (!string.IsNullOrEmpty(marketIdClaim) && int.TryParse(marketIdClaim, out var tokenMarketId))
        {
            context.Items["MarketId"] = tokenMarketId;
            _logger.LogInformation("MarketId set from token: {MarketId}", tokenMarketId);
            await _next(context);
            return;
        }

        // Priority 2: resolve market from subdomain
        var host = context.Request.Host.Host;
        if (!host.Equals("localhost", StringComparison.OrdinalIgnoreCase) &&
            host.Contains('.') &&
            !System.Net.IPAddress.TryParse(host, out _))
        {
            var subdomain = host.Split('.')[0];
            var market = await dbContext.Markets
                .FirstOrDefaultAsync(m => m.Subdomain == subdomain);

            if (market != null)
            {
                context.Items["MarketId"] = market.Id;
                _logger.LogInformation("MarketId set from subdomain: {Subdomain} -> {MarketId}", subdomain, market.Id);
                await _next(context);
                return;
            }
        }

        _logger.LogWarning("MarketId not resolved for user {User}, path {Path}",
            context.User.Identity?.Name, context.Request.Path);

        context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new
        {
            error = "Unauthorized",
            message = "Market topilmadi. Iltimos, tizimga qaytadan kiring yoki administrator bilan bog'laning."
        });
    }
}
