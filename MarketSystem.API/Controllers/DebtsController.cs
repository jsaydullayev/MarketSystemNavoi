using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore; // ✅ For Include extension method
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data; // ✅ For AppDbContext

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class DebtsController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAuditLogService _auditLogService;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly AppDbContext _context;

    public DebtsController(IUnitOfWork unitOfWork, IAuditLogService auditLogService, ICurrentMarketService currentMarketService, AppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _auditLogService = auditLogService;
        _currentMarketService = currentMarketService;
        _context = context;
    }

    /// <summary>
    /// Get all open debts for a customer
    /// </summary>
    [HttpGet("{customerId}")]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetCustomerDebts(Guid customerId)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ✅ OPTIMIZED: Single query with eager loading
        var debts = await _unitOfWork.Debts.GetQueryable()
            .Include(d => d.Sale)
                .ThenInclude(s => s.SaleItems)
                    .ThenInclude(si => si.Product)
            .Include(d => d.Customer)
            .Where(d => d.CustomerId == customerId && d.Status == DebtStatus.Open && d.MarketId == marketId)
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync(CancellationToken.None);

        var result = debts.Select(debt => {
            // Map sale items to DTOs
            List<SaleItemDto>? saleItems = null;
            if (debt.Sale?.SaleItems != null)
            {
                saleItems = debt.Sale.SaleItems.Select(si => new SaleItemDto(
                    si.Id.ToString(),
                    si.SaleId.ToString(),
                    si.ProductId,
                    si.Product?.Name ?? "Noma'lum mahsulot",
                    si.Quantity,
                    si.CostPrice,
                    si.SalePrice,
                    si.TotalPrice,
                    si.Profit,
                    "dona", // TODO: Get from product
                    si.Comment
                )).ToList();
            }

            return new DebtDto(
                debt.Id,
                debt.SaleId,
                debt.CustomerId,
                debt.Customer?.FullName,
                debt.TotalDebt,
                debt.RemainingDebt,
                debt.Status.ToString(),
                debt.Sale?.CreatedAt ?? DateTime.MinValue,
                saleItems
            );
        }).ToList();

        return Ok(result);
    }

    /// <summary>
    /// Get total debt amount for a customer
    /// </summary>
    [HttpGet("~/api/Debts/customer/{customerId}/total")]
    public async Task<ActionResult<decimal>> GetCustomerTotalDebt(Guid customerId)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var debts = await _unitOfWork.Debts.FindAsync(
            d => d.CustomerId == customerId && d.Status == DebtStatus.Open && d.MarketId == marketId,
            CancellationToken.None);

        var totalDebt = debts.Sum(d => d.RemainingDebt);
        return Ok(totalDebt);
    }

    /// <summary>
    /// Make a payment towards a debt
    /// </summary>
    [HttpPost("~/api/Debts/{debtId}/pay")]
    public async Task<IActionResult> PayDebt(Guid debtId, [FromBody] PayDebtDto request)
    {
        var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        // ✅ FIX: Use execution strategy to wrap transaction operations
        // This is required because NpgsqlRetryingExecutionStrategy doesn't support user-initiated transactions
        var strategy = _context.Database.CreateExecutionStrategy();

        return await strategy.ExecuteAsync<IActionResult>(async () =>
        {
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

                var paymentTypeStr = request.PaymentType;
                if (string.Equals(paymentTypeStr, "CARD", StringComparison.OrdinalIgnoreCase))
                {
                    paymentTypeStr = "Terminal";
                }

                // Create payment record
                var marketId = _currentMarketService.GetCurrentMarketId();
                var payment = new Payment
                {
                    Id = Guid.NewGuid(),
                    SaleId = debt.SaleId,
                    PaymentType = Enum.Parse<PaymentType>(paymentTypeStr, true),
                    Amount = request.Amount,
                    MarketId = marketId,
                    CreatedAt = DateTime.UtcNow
                };
                await _unitOfWork.Payments.AddAsync(payment);

                // ✅ NEW: Update cash register balance for cash payments
                if (payment.PaymentType == PaymentType.Cash)
                {
                    var cashRegister = await _context.CashRegisters
                        .OrderByDescending(cr => cr.LastUpdated)
                        .FirstOrDefaultAsync(CancellationToken.None);

                    if (cashRegister != null)
                    {
                        cashRegister.CurrentBalance += request.Amount;
                        cashRegister.LastUpdated = DateTime.UtcNow;
                        _context.CashRegisters.Update(cashRegister);
                    }
                }

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
        });
    }

    /// <summary>
    /// Get all debts (admin/owner only)
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<IEnumerable<DebtDto>>> GetAllDebts(
        [FromQuery] DebtStatus? status = null)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // ✅ OPTIMIZED: Use eager loading to avoid N+1 queries
        var debtsQuery = status.HasValue
            ? _unitOfWork.Debts.GetQueryable()
                .Include(d => d.Sale)
                    .ThenInclude(s => s.SaleItems)
                        .ThenInclude(si => si.Product)
                .Include(d => d.Customer)
                .Where(d => d.Status == status.Value && d.MarketId == marketId)
            : _unitOfWork.Debts.GetQueryable()
                .Include(d => d.Sale)
                    .ThenInclude(s => s.SaleItems)
                        .ThenInclude(si => si.Product)
                .Include(d => d.Customer)
                .Where(d => d.MarketId == marketId);

        var debts = await debtsQuery
            .OrderByDescending(d => d.CreatedAt)
            .ToListAsync(CancellationToken.None);

        var result = debts.Select(debt => {
            // Map sale items to DTOs
            List<SaleItemDto>? saleItems = null;
            if (debt.Sale?.SaleItems != null)
            {
                saleItems = debt.Sale.SaleItems.Select(si => new SaleItemDto(
                    si.Id.ToString(),
                    si.SaleId.ToString(),
                    si.ProductId,
                    si.Product?.Name ?? "Noma'lum mahsulot",
                    si.Quantity,
                    si.CostPrice,
                    si.SalePrice,
                    si.TotalPrice,
                    si.Profit,
                    "dona", // TODO: Get from product
                    si.Comment
                )).ToList();
            }

            return new DebtDto(
                debt.Id,
                debt.SaleId,
                debt.CustomerId,
                debt.Customer?.FullName,
                debt.TotalDebt,
                debt.RemainingDebt,
                debt.Status.ToString(),
                debt.Sale?.CreatedAt ?? DateTime.MinValue,
                saleItems
            );
        }).ToList();

        return Ok(result);
    }
}
