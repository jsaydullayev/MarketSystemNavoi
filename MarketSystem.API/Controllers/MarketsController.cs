using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Roles = "SuperAdmin")]  // Faqat SuperAdmin market yaratishi mumkin
public class MarketsController : ControllerBase
{
    private readonly IMarketService _marketService;
    private readonly ILogger<MarketsController> _logger;

    public MarketsController(IMarketService marketService, ILogger<MarketsController> logger)
    {
        _marketService = marketService;
        _logger = logger;
    }

    [HttpPost]
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

    [HttpGet]
    public async Task<IActionResult> GetAllMarkets(CancellationToken cancellationToken)
    {
        var markets = await _marketService.GetAllMarketsAsync(cancellationToken);
        return Ok(markets);
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetMarketById(int id, CancellationToken cancellationToken)
    {
        var market = await _marketService.GetMarketByIdAsync(id, cancellationToken);
        if (market is null) return NotFound();
        return Ok(market);
    }

    [HttpPut("{id}")]
    public async Task<IActionResult> UpdateMarket(int id, [FromBody] UpdateMarketRequest request, CancellationToken cancellationToken)
    {
        var result = await _marketService.UpdateMarketAsync(id, request.Name, request.Description, cancellationToken);
        if (!result) return NotFound();
        return Ok(new { message = "Market updated successfully" });
    }

    [HttpDelete("{id}")]
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
