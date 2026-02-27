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
            }
        }
        await _next(context);
    }
}
