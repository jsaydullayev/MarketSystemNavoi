using System.Net;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;
using MarketSystem.Infrastructure.Data;

namespace MarketSystem.API.Middleware;

/// <summary>
/// Har bir request uchun marketni aniqlaydi (subdomain yoki JWT token orqali)
/// </summary>
public class TenantResolutionMiddleware
{
    private readonly RequestDelegate _next;

    public TenantResolutionMiddleware(RequestDelegate next)
    {
        _next = next;
    }

    public async Task InvokeAsync(HttpContext context, AppDbContext dbContext)
    {
        // 1. Agar user logged in bo'lsa, JWT tokenidan MarketId olish
        var marketIdClaim = context.User?.FindFirst("MarketId")?.Value;
        if (!string.IsNullOrEmpty(marketIdClaim) && int.TryParse(marketIdClaim, out var tokenMarketId))
        {
            context.Items["MarketId"] = tokenMarketId;
            await _next(context);
            return;
        }

        // 2. Subdomain orqali aniqlash (market1.example.com)
        var host = context.Request.Host.Host;
        if (!host.Equals("localhost", StringComparison.OrdinalIgnoreCase) &&
            host.Contains('.'))
        {
            var subdomain = host.Split('.')[0];
            var market = await dbContext.Markets
                .FirstOrDefaultAsync(m => m.Subdomain == subdomain);

            if (market != null)
            {
                context.Items["MarketId"] = market.Id;
            }
        }

        await _next(context);
    }
}
