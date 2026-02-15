using System.Security.Claims;
using MarketSystem.Application.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

/// <summary>
/// HttpContext'dan market IDni oladi (TenantResolutionMiddleware tomonidan qo'yilgan)
/// </summary>
public class CurrentMarketService : ICurrentMarketService
{
    private readonly IHttpContextAccessor _httpContextAccessor;
    private readonly ILogger<CurrentMarketService> _logger;

    public CurrentMarketService(IHttpContextAccessor httpContextAccessor, ILogger<CurrentMarketService> logger)
    {
        _httpContextAccessor = httpContextAccessor;
        _logger = logger;
    }

    public int GetCurrentMarketId()
    {
        var marketId = TryGetCurrentMarketId();

        if (marketId is null)
        {
            _logger.LogWarning("MarketId not found in HttpContext.Items");
            throw new UnauthorizedAccessException("Market topilmadi. Iltimos, tizimga kiring yoki administrator bilan bog'laning.");
        }

        return marketId.Value;
    }

    public int? TryGetCurrentMarketId()
    {
        var marketIdObj = _httpContextAccessor.HttpContext?.Items["MarketId"];

        if (marketIdObj is null)
        {
            _logger.LogDebug("MarketId is null in HttpContext.Items");
            return null;
        }

        if (marketIdObj is int marketId)
        {
            return marketId;
        }

        _logger.LogWarning("MarketId in HttpContext.Items is not an int: {Type}", marketIdObj.GetType());
        return null;
    }
}
