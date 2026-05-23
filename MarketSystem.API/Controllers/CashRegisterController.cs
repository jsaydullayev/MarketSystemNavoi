using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class CashRegisterController : ControllerBase
{
    private readonly ICashRegisterService _cashRegisterService;

    public CashRegisterController(ICashRegisterService cashRegisterService)
    {
        _cashRegisterService = cashRegisterService;
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.CashRegisterAccess)]
    public async Task<ActionResult<CashRegisterDto>> GetCashRegister(CancellationToken cancellationToken)
    {
        var result = await _cashRegisterService.GetCashRegisterAsync(cancellationToken);
        if (result == null)
            return NotFound(new { message = "Cash register not found" });

        return Ok(result);
    }

    [HttpGet("today-sales")]
    [RequirePermission(PermissionKeys.CashRegisterAccess)]
    public async Task<ActionResult<TodaySalesSummaryDto>> GetTodaySales(CancellationToken cancellationToken)
    {
        var result = await _cashRegisterService.GetTodaySalesSummaryAsync(cancellationToken);
        if (result == null)
            return NotFound(new { message = "Today's sales summary not found" });

        return Ok(result);
    }

    [HttpPost("withdraw")]
    [RequirePermission(PermissionKeys.CashRegisterManage)]
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
    [RequirePermission(PermissionKeys.CashRegisterManage)]
    public async Task<IActionResult> AddCash([FromBody] AddCashRequest request, CancellationToken cancellationToken)
    {
        // Y3 — capture the JWT identity so the deposit audit row attributes
        // the actor, same as WithdrawCash above.
        var userIdClaim = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !Guid.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized(new { message = "Invalid user" });
        }

        var success = await _cashRegisterService.AddCashAsync(request.Amount, userId, cancellationToken);
        if (!success)
            return BadRequest(new { message = "Failed to add cash" });

        return Ok(new { message = "Cash added successfully" });
    }
}
