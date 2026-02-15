using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using System.Security.Claims;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
public class MarketsController : ControllerBase
{
    private readonly IMarketService _marketService;
    private readonly ILogger<MarketsController> _logger;
    private readonly ICurrentMarketService _currentMarketService;

    public MarketsController(IMarketService marketService, ILogger<MarketsController> logger, ICurrentMarketService currentMarketService)
    {
        _marketService = marketService;
        _logger = logger;
        _currentMarketService = currentMarketService;
    }

    // SuperAdmin only - Create market with new Owner user
    [HttpPost]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> CreateMarket([FromBody] CreateMarketRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var result = await _marketService.CreateMarketAsync(request, cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // Owner only - Register market for themselves (updates their existing account)
    [HttpPost]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<IActionResult> RegisterMarket([FromBody] RegisterMarketRequest request, CancellationToken cancellationToken)
    {
        try
        {
            // Get current Owner user ID
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (!Guid.TryParse(userIdStr, out var ownerId))
                return Unauthorized();

            var result = await _marketService.RegisterMarketForOwnerAsync(request, ownerId, cancellationToken);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    // Owner only - Get their own market details
    [HttpGet]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<IActionResult> GetMyMarket(CancellationToken cancellationToken)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
            if (!marketId.HasValue)
                return NotFound(new { message = "Sizga tegishli market topilmadi" });

            var market = await _marketService.GetMarketByIdAsync(marketId.Value, cancellationToken);
            if (market is null)
                return NotFound(new { message = "Market topilmadi" });

            return Ok(market);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting market for owner");
            return StatusCode(500, new { message = "Xatolik yuz berdi" });
        }
    }

    // Owner only - Update their own market details
    [HttpPut]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<IActionResult> UpdateMyMarket([FromBody] UpdateMyMarketRequest request, CancellationToken cancellationToken)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
            if (!marketId.HasValue)
                return NotFound(new { message = "Sizga tegishli market topilmadi" });

            var result = await _marketService.UpdateMarketAsync(marketId.Value, request.Name, request.Description, cancellationToken);
            if (!result)
                return NotFound(new { message = "Market topilmadi" });

            return Ok(new { message = "Market ma'lumotlari muvaffaqiyatli yangilandi" });
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error updating market for owner");
            return StatusCode(500, new { message = "Xatolik yuz berdi" });
        }
    }

    [HttpGet]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> GetAllMarkets(CancellationToken cancellationToken)
    {
        var markets = await _marketService.GetAllMarketsAsync(cancellationToken);
        return Ok(markets);
    }

    [HttpGet("{id}")]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> GetMarketById(int id, CancellationToken cancellationToken)
    {
        var market = await _marketService.GetMarketByIdAsync(id, cancellationToken);
        if (market is null) return NotFound();
        return Ok(market);
    }

    [HttpPut("{id}")]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> UpdateMarket(int id, [FromBody] UpdateMarketRequest request, CancellationToken cancellationToken)
    {
        var result = await _marketService.UpdateMarketAsync(id, request.Name, request.Description, cancellationToken);
        if (!result) return NotFound();
        return Ok(new { message = "Market updated successfully" });
    }

    [HttpDelete("{id}")]
    [Authorize(Roles = "SuperAdmin")]
    public async Task<IActionResult> DeleteMarket(int id, CancellationToken cancellationToken)
    {
        var result = await _marketService.DeleteMarketAsync(id, cancellationToken);
        if (!result) return NotFound();
        return Ok(new { message = "Market deleted successfully" });
    }
}

public record UpdateMarketRequest(
    string Name,
    string? Description
);
