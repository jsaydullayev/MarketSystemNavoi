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

        // SuperAdmin is cross-tenant: their JWT has no MarketId claim by design
        // (they manage all markets, not one). Let the request pass through without
        // tenant resolution — the controllers they're allowed to call either use
        // the SuperAdmin console path (/api/_sa/) already skipped above, or are
        // user-scoped operations like /Users/MyProfile that work off the JWT claims alone.
        var roleClaim = context.User?.FindFirst(ClaimTypes.Role)?.Value;
        if (roleClaim == "SuperAdmin")
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

        // DIQQAT: bu yerda ilgari subdomain (Host header) bo'yicha fallback bor edi —
        // qayta qo'shmang. Host header'ni to'liq klient boshqaradi, va u orqali topilgan
        // market uchun foydalanuvchi a'zoligi (membership) hech qachon tekshirilmagan edi:
        // MarketId claim'i yo'q token bilan istalgan tenant ichida ishlash mumkin bo'lardi
        // (Owner esa barcha permission tekshiruvlarini chetlab o'tadi). Tenant faqat
        // imzolangan JWT `MarketId` claim'idan olinadi; claim bo'lmasa — quyidagi 403.

        // MarketId topilmadi — user authenticated lekin market ga ruxsat yo'q → 403
        _logger.LogWarning("MarketId not found for user {User}, path {Path}",
            context.User?.Identity?.Name, context.Request.Path);

        context.Response.StatusCode = StatusCodes.Status403Forbidden;
        context.Response.ContentType = "application/json";
        await context.Response.WriteAsJsonAsync(new
        {
            error = "Forbidden",
            message = "Market topilmadi. Iltimos, tizimga qaytadan kiring yoki administrator bilan bog'laning."
        });
    }
}
