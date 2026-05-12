using System.Security.Claims;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class DebtsController : ControllerBase
{
    private readonly IDebtService _debts;

    public DebtsController(IDebtService debts)
    {
        _debts = debts;
    }

    /// <summary>Open debts for one customer.</summary>
    [HttpGet("{customerId}")]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetCustomerDebts(Guid customerId, CancellationToken ct)
        => Ok(await _debts.GetByCustomerAsync(customerId, ct));

    /// <summary>Total open debt for one customer.</summary>
    [HttpGet("~/api/Debts/customer/{customerId}/total")]
    public async Task<ActionResult<decimal>> GetCustomerTotalDebt(Guid customerId, CancellationToken ct)
        => Ok(await _debts.GetCustomerTotalAsync(customerId, ct));

    /// <summary>Make a payment against an open debt.</summary>
    [HttpPost("~/api/Debts/{debtId}/pay")]
    public async Task<IActionResult> PayDebt(Guid debtId, [FromBody] PayDebtDto request, CancellationToken ct)
    {
        if (!Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var userId))
            return Unauthorized();

        try
        {
            var result = await _debts.PayAsync(debtId, request, userId, ct);
            return Ok(new
            {
                message = "Payment successful",
                remainingDebt = result.RemainingDebt,
                paymentAmount = result.PaymentAmount,
                debtStatus = result.DebtStatus
            });
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    /// <summary>All debts in this market (optionally filtered by status).</summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetAllDebts(
        [FromQuery] DebtStatus? status,
        CancellationToken ct)
        => Ok(await _debts.ListAsync(status, ct));
}
