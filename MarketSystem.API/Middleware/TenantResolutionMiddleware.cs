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
        // Skip tenant resolution for endpoints that don't operate on a single
        // tenant. The SuperAdmin console (`/api/_sa/...`) is cross-tenant by
        // design — its JWT has no MarketId claim — and public-facing endpoints
        // (auth, registration submission, health, hubs auth handshake) run
        // without a tenant context too.
        var path = context.Request.Path.Value ?? "";
        var skipPaths = new[]
        {
            "/api/Auth/Login",
            "/api/Auth/Register",
            "/api/Auth/RefreshToken",
            "/api/Auth/Logout",
            "/api/_sa/",                    // SuperAdmin console — cross-tenant
            "/api/RegistrationRequests",    // Public submission — anonymous
            "/health",
            "/swagger",
            "/privacy",
            "/hubs",
        };

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
            // Real-time block enforcement: even after a token is issued,
            // SuperAdmin's "block market" action must take effect immediately.
            // A single cheap PK lookup per request (partial index covers the
            // hot path of unblocked markets — index returns no rows so the
            // EXISTS check is sub-millisecond).
            var block = await dbContext.Markets
                .AsNoTracking()
                .Where(m => m.Id == tokenMarketId && m.IsBlocked)
                .Select(m => new { m.BlockedAt, m.BlockedReason })
                .FirstOrDefaultAsync();
            if (block != null)
            {
                _logger.LogWarning(
                    "Request rejected — market {MarketId} is blocked. User={User} Path={Path}",
                    tokenMarketId, context.User?.Identity?.Name, context.Request.Path);

                // 423 Locked is the canonical status for "resource exists but
                // is intentionally inaccessible". Body shape is the same as
                // any other API error so the Flutter client's global error
                // mapper can pick out `code` and route to a block screen.
                context.Response.StatusCode = 423;
                context.Response.ContentType = "application/json";
                await context.Response.WriteAsJsonAsync(new
                {
                    code = "MARKET_BLOCKED",
                    message = "Do'kon administrator tomonidan bloklangan. Iltimos, administrator bilan bog'laning.",
                    reason = block.BlockedReason,
                    blockedAt = block.BlockedAt,
                    statusCode = 423
                });
                return;
            }

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
                .AsNoTracking()
                .FirstOrDefaultAsync(m => m.Subdomain == subdomain);

            if (market != null)
            {
                // Same block enforcement as the JWT path — without this, a
                // blocked market could still be reached via its subdomain URL.
                if (market.IsBlocked)
                {
                    _logger.LogWarning(
                        "Request rejected — market {MarketId} (subdomain {Subdomain}) is blocked. Path={Path}",
                        market.Id, subdomain, context.Request.Path);
                    context.Response.StatusCode = 423;
                    context.Response.ContentType = "application/json";
                    await context.Response.WriteAsJsonAsync(new
                    {
                        code = "MARKET_BLOCKED",
                        message = "Do'kon administrator tomonidan bloklangan. Iltimos, administrator bilan bog'laning.",
                        reason = market.BlockedReason,
                        blockedAt = market.BlockedAt,
                        statusCode = 423
                    });
                    return;
                }

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
