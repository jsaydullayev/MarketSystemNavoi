using System.Security.Claims;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Enums;
using MarketSystem.API.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class DebtsController : ControllerBase
{
    private readonly IDebtService _debts;
    private readonly IReportService _reports;
    private readonly ITashkentClock _clock;

    public DebtsController(IDebtService debts, IReportService reports, ITashkentClock clock)
    {
        _debts = debts;
        _reports = reports;
        _clock = clock;
    }

    /// <summary>Open debts for one customer.</summary>
    [HttpGet("{customerId}")]
    [RequirePermission(PermissionKeys.DebtsAccess)]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetCustomerDebts(Guid customerId, CancellationToken ct)
        => Ok(await _debts.GetByCustomerAsync(customerId, ct));

    /// <summary>Total open debt for one customer.</summary>
    [HttpGet("~/api/Debts/customer/{customerId}/total")]
    [RequirePermission(PermissionKeys.DebtsAccess)]
    public async Task<ActionResult<decimal>> GetCustomerTotalDebt(Guid customerId, CancellationToken ct)
        => Ok(await _debts.GetCustomerTotalAsync(customerId, ct));

    /// <summary>
    /// Bitta qarzdorning yig'ma ko'rsatkichlari: jami qoldiq qarz, oxirgi
    /// (hozirgi) olingan qarz summasi va oxirgi to'lov. Mijoz bir necha marta
    /// qarz olgan bo'lsa ham bitta javobda umumlashtiriladi.
    /// </summary>
    [HttpGet("~/api/Debts/customer/{customerId}/summary")]
    [RequirePermission(PermissionKeys.DebtsAccess)]
    public async Task<ActionResult<CustomerDebtSummaryDto>> GetCustomerDebtSummary(Guid customerId, CancellationToken ct)
    {
        var summary = await _debts.GetCustomerSummaryAsync(customerId, ct);
        return summary is null ? NotFound(new { message = "Mijoz topilmadi." }) : Ok(summary);
    }

    /// <summary>
    /// Qarzdor bo'yicha PDF hisobot — ekrandagi uchta ko'rsatkich + qarzlar va
    /// to'lovlar tarixi.
    /// </summary>
    [HttpGet("~/api/Debts/customer/{customerId}/export-pdf")]
    [RequirePermission(PermissionKeys.DebtsAccess)]
    public async Task<IActionResult> ExportCustomerDebtPdf(
        Guid customerId,
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        try
        {
            var pdfBytes = await _reports.ExportCustomerDebtPdfAsync(customerId, lang, ct);
            var fileName = $"Qarzdor_{customerId}_{_clock.NowLocal:yyyyMMdd_HHmmss}.pdf";
            return File(pdfBytes, "application/pdf", fileName);
        }
        catch (KeyNotFoundException ex) { return NotFound(new { message = ex.Message }); }
    }

    /// <summary>Make a payment against an open debt.</summary>
    [HttpPost("~/api/Debts/{debtId}/pay")]
    [RequirePermission(PermissionKeys.DebtsManage)]
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

    /// <summary>Update a debt's payment due date. Requires debts.dueDate.</summary>
    [HttpPut("~/api/Debts/{debtId}/due-date")]
    [RequirePermission(PermissionKeys.DebtsDueDate)]
    public async Task<ActionResult<DebtDto>> UpdateDueDate(Guid debtId, [FromBody] UpdateDebtDueDateDto request, CancellationToken ct)
    {
        var updated = await _debts.UpdateDueDateAsync(debtId, request.DueDate, ct);
        return updated is null ? NotFound(new { message = "Qarz topilmadi." }) : Ok(updated);
    }

    /// <summary>All debts in this market (optionally filtered by status).</summary>
    [HttpGet]
    [RequirePermission(PermissionKeys.DebtsAccess)]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetAllDebts(
        [FromQuery] DebtStatus? status,
        CancellationToken ct)
        => Ok(await _debts.ListAsync(status, ct));
}
