using System.Net;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.API.Middleware;

/// <summary>
/// </summary>
public class TenantResolutionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<TenantResolutionMiddleware> _logger;

    public TenantResolutionMiddleware(RequestDelegate next, ILogger<TenantResolutionMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, AppDbContext dbContext)
    {
        // Skip tenant resolution for public endpoints
        var path = context.Request.Path.Value ?? "";
        var skipPaths = new[] { "/api/Auth/Login", "/api/Auth/Register", "/api/Auth/RefreshToken", "/api/Auth/Logout", "/health", "/swagger", "/privacy", "/hubs" };

        if (skipPaths.Any(p => path.StartsWith(p, StringComparison.OrdinalIgnoreCase)))
        {
            await _next(context);
            return;
        }

        // If the user is not authenticated, let the normal auth pipeline handle it
        // (returns 401 from [Authorize] for protected endpoints, or proceeds for [AllowAnonymous]).
        // Otherwise we mask the real auth failure with our "Market topilmadi" message.
        if (context.User?.Identity?.IsAuthenticated != true)
        {
            await _next(context);
            return;
        }

        // Avval JWT token'dan MarketId claim ni olamiz (birinchi prioritet)
        var marketIdClaim = context.User?.FindFirst("MarketId")?.Value;

        _logger.LogInformation("TenantResolution: User={User}, MarketIdClaim={MarketIdClaim}",
            context.User?.Identity?.Name, marketIdClaim);

        if (!string.IsNullOrEmpty(marketIdClaim) && int.TryParse(marketIdClaim, out var tokenMarketId))
        {
            context.Items["MarketId"] = tokenMarketId;
            _logger.LogInformation("MarketId set from token: {MarketId}", tokenMarketId);
            await _next(context);
            return;
        }

        // Agar token'da MarketId bo'lmasa, subdomain bo'yicha qidiramiz (ikkinchi prioritet)
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

        // MarketId topilmadi - 401 Unauthorized qaytarish
        _logger.LogWarning("MarketId not found for user {User}, path {Path}",
            context.User?.Identity?.Name, context.Request.Path);

        context.Response.StatusCode = (int)HttpStatusCode.Unauthorized;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new
        {
            error = "Unauthorized",
            message = "Market topilmadi. Iltimos, tizimga qaytadan kiring yoki administrator bilan bog'laning."
        });
    }
}
