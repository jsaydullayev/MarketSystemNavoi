using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "AllRoles")]
public class DebtsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;

    public DebtsController(IUnitOfWork unitOfWork, IAuditLogService auditLogService)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
    }

    /// <summary>
    /// Get all open debts for a customer
    /// </summary>
    [HttpGet("customer/{customerId}")]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetCustomerDebts(Guid customerId)
    {
        var debts = await _unitOfWork.Debts.FindAsync(
            d => d.CustomerId == customerId && d.Status == DebtStatus.Open,
            CancellationToken.None);

        var result = new List<DebtDto>();
        foreach (var debt in debts)
        {
            var sale = await _unitOfWork.Sales.GetByIdAsync(debt.SaleId);
            result.Add(new DebtDto(
                debt.Id,
                debt.SaleId,
                debt.CustomerId,
                debt.TotalDebt,
                debt.RemainingDebt,
                debt.Status.ToString(),
                sale?.CreatedAt ?? DateTime.MinValue
            ));
        }

        return Ok(result);
    }

    /// <summary>
    /// Get total debt amount for a customer
    /// </summary>
    [HttpGet("customer/{customerId}/total")]
    public async Task<ActionResult<decimal>> GetCustomerTotalDebt(Guid customerId)
    {
        var debts = await _unitOfWork.Debts.FindAsync(
            d => d.CustomerId == customerId && d.Status == DebtStatus.Open,
            CancellationToken.None);

        var totalDebt = debts.Sum(d => d.RemainingDebt);
        return Ok(totalDebt);
    }

    /// <summary>
    /// Make a payment towards a debt
    /// </summary>
    [HttpPost("{debtId}/pay")]
    public async Task<IActionResult> PayDebt(Guid debtId, [FromBody] PayDebtDto request)
    {
        var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        await _unitOfWork.BeginTransactionAsync(CancellationToken.None);

        try
        {
            var debt = await _unitOfWork.Debts.GetByIdAsync(debtId);
            if (debt is null || debt.Status != DebtStatus.Open)
                return NotFound("Debt not found or already closed");

            var sale = await _unitOfWork.Sales.GetByIdAsync(debt.SaleId);
            if (sale is null)
                return NotFound("Sale not found");

            // Validate payment amount
            if (request.Amount <= 0)
                return BadRequest("Payment amount must be positive");

            if (request.Amount > debt.RemainingDebt)
                return BadRequest($"Payment amount ({request.Amount}) exceeds remaining debt ({debt.RemainingDebt})");

            // Create payment record
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = debt.SaleId,
                PaymentType = Enum.Parse<PaymentType>(request.PaymentType, true),
                Amount = request.Amount,
                CreatedAt = DateTime.UtcNow
            };
            await _unitOfWork.Payments.AddAsync(payment);

            // Update debt
            debt.RemainingDebt -= request.Amount;
            if (debt.RemainingDebt <= 0)
            {
                debt.RemainingDebt = 0;
                debt.Status = DebtStatus.Closed;
                sale.Status = SaleStatus.Closed;
            }

            // Update sale
            sale.PaidAmount += request.Amount;
            _unitOfWork.Sales.Update(sale);
            _unitOfWork.Debts.Update(debt);

            await _unitOfWork.SaveChangesAsync(CancellationToken.None);
            await _unitOfWork.CommitTransactionAsync();

            // Audit log
            await _auditLogService.LogPaymentActionAsync(payment.Id, userId, CancellationToken.None);

            return Ok(new
            {
                message = "Payment successful",
                remainingDebt = debt.RemainingDebt,
                paymentAmount = request.Amount,
                debtStatus = debt.Status.ToString()
            });
        }
        catch (Exception ex)
        {
            await _unitOfWork.RollbackTransactionAsync();
            return BadRequest($"Payment failed: {ex.Message}");
        }
    }

    /// <summary>
    /// Get all debts (admin/owner only)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetAllDebts(
        [FromQuery] DebtStatus? status = null)
    {
        var debts = status.HasValue
            ? await _unitOfWork.Debts.FindAsync(d => d.Status == status.Value, CancellationToken.None)
            : await _unitOfWork.Debts.GetAllAsync(CancellationToken.None);

        var result = new List<DebtDto>();
        foreach (var debt in debts)
        {
            var sale = await _unitOfWork.Sales.GetByIdAsync(debt.SaleId);
            result.Add(new DebtDto(
                debt.Id,
                debt.SaleId,
                debt.CustomerId,
                debt.TotalDebt,
                debt.RemainingDebt,
                debt.Status.ToString(),
                sale?.CreatedAt ?? DateTime.MinValue
            ));
        }

        return Ok(result);
    }
}
