using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "AdminOrOwner")]
public class CashRegisterController : ControllerBase
{
    private readonly ICashRegisterService _cashRegisterService;

    public CashRegisterController(ICashRegisterService cashRegisterService)
    {
        _cashRegisterService = cashRegisterService;
    }

    [HttpGet]
    public async Task<ActionResult<CashRegisterDto>> GetCashRegister(CancellationToken cancellationToken)
    {
        var result = await _cashRegisterService.GetCashRegisterAsync(cancellationToken);
        if (result == null)
            return BadRequest(new { message = "Failed to get cash register" });

        return Ok(result);
    }

    [HttpGet("today-sales")]
    public async Task<ActionResult<TodaySalesSummaryDto>> GetTodaySales(CancellationToken cancellationToken)
    {
        var result = await _cashRegisterService.GetTodaySalesSummaryAsync(cancellationToken);
        if (result == null)
            return BadRequest(new { message = "Failed to get today's sales" });

        return Ok(result);
    }

    [HttpPost("withdraw")]
    public async Task<IActionResult> WithdrawCash([FromBody] WithdrawCashRequest request, CancellationToken cancellationToken)
    {
        // User ID ni JWT dan olamiz
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized(new { message = "Invalid user" });
        }

        var success = await _cashRegisterService.WithdrawCashAsync(request, userId, cancellationToken);
        if (!success)
            return BadRequest(new { message = "Failed to withdraw cash. Check balance or amount." });

        return Ok(new { message = "Cash withdrawn successfully" });
    }

    [HttpPost("add")]
    public async Task<IActionResult> AddCash([FromQuery] decimal amount, CancellationToken cancellationToken)
    {
        var success = await _cashRegisterService.AddCashAsync(amount, cancellationToken);
        if (!success)
            return BadRequest(new { message = "Failed to add cash" });

        return Ok(new { message = "Cash added successfully" });
    }
}
