using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class DebtService : IDebtService
{
    private readonly IAppDbContext _context;
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarket;
    private readonly IAuditLogService _auditLog;
    private readonly ILogger<DebtService> _logger;

    public DebtService(
        IAppDbContext context,
        IUnitOfWork unitOfWork,
        ICurrentMarketService currentMarket,
        IAuditLogService auditLog,
        ILogger<DebtService> logger)
    {
        _context = context;
        _unitOfWork = unitOfWork;
        _currentMarket = currentMarket;
        _auditLog = auditLog;
        _logger = logger;
    }

    public async Task<IEnumerable<DebtDto>> GetByCustomerAsync(Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarket.GetCurrentMarketId();

        var debts = await _context.Debts
            .AsNoTracking()
            .Include(d => d.Sale)
                .ThenInclude(s => s!.SaleItems)
                    .ThenInclude(si => si.Product)
            .Include(d => d.Customer)
            .Where(d => d.CustomerId == customerId && d.Status == DebtStatus.Open && d.MarketId == marketId)
            .OrderByDescending(d => d.CreatedAt)
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        return debts.Select(MapToDto).ToList();
    }

    public async Task<decimal> GetCustomerTotalAsync(Guid customerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarket.GetCurrentMarketId();

        // Aggregate in the DB so we never materialise the full row set just to sum.
        return await _context.Debts
            .Where(d => d.CustomerId == customerId && d.Status == DebtStatus.Open && d.MarketId == marketId)
            .SumAsync(d => (decimal?)d.RemainingDebt, cancellationToken) ?? 0m;
    }

    public async Task<IEnumerable<DebtDto>> ListAsync(DebtStatus? status, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarket.GetCurrentMarketId();

        var query = _context.Debts
            .AsNoTracking()
            .Include(d => d.Sale)
                .ThenInclude(s => s!.SaleItems)
                    .ThenInclude(si => si.Product)
            .Include(d => d.Customer)
            .Where(d => d.MarketId == marketId);

        if (status.HasValue)
            query = query.Where(d => d.Status == status.Value);

        var debts = await query
            .OrderByDescending(d => d.CreatedAt)
            .AsSplitQuery()
            .ToListAsync(cancellationToken);

        return debts.Select(MapToDto).ToList();
    }

    public async Task<PayDebtResultDto> PayAsync(Guid debtId, PayDebtDto request, Guid actorUserId, CancellationToken cancellationToken = default)
    {
        if (request.Amount <= 0)
            throw new InvalidOperationException("To'lov miqdori 0 dan katta bo'lishi kerak.");

        var marketId = _currentMarket.GetCurrentMarketId();

        var strategy = _context.Database.CreateExecutionStrategy();
        return await strategy.ExecuteAsync(async () =>
        {
            await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                // SELECT … FOR UPDATE so a parallel /api/Debts/{id}/pay request
                // blocks until we commit. Without this, two concurrent payments
                // would both see RemainingDebt = 100, both subtract, both add
                // their full amount into the cash register — the customer ends
                // up paying twice for the same debt and the till is over.
                var debt = await _context.Debts
                    .FromSqlInterpolated($"SELECT * FROM \"Debts\" WHERE \"Id\" = {debtId} FOR UPDATE")
                    .FirstOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Qarz topilmadi.");

                if (debt.MarketId != marketId)
                    throw new KeyNotFoundException("Qarz topilmadi.");
                if (debt.Status != DebtStatus.Open)
                    throw new InvalidOperationException("Bu qarz allaqachon yopilgan.");

                // The sale row needs to move with the debt so we lock that too.
                var sale = await _context.Sales
                    .FromSqlInterpolated($"SELECT *, xmin FROM \"Sales\" WHERE \"Id\" = {debt.SaleId} FOR UPDATE")
                    .FirstOrDefaultAsync(cancellationToken)
                    ?? throw new KeyNotFoundException("Savdo topilmadi.");
                if (sale.MarketId != marketId)
                    throw new KeyNotFoundException("Savdo topilmadi.");

                if (request.Amount > debt.RemainingDebt)
                    throw new InvalidOperationException(
                        $"To'lov miqdori ({request.Amount}) qoldiq qarzdan ({debt.RemainingDebt}) katta.");

                // Map client's "CARD" alias to the canonical Terminal enum.
                var paymentTypeStr = string.Equals(request.PaymentType, "CARD", StringComparison.OrdinalIgnoreCase)
                    ? "Terminal" : request.PaymentType;

                if (!Enum.TryParse<PaymentType>(paymentTypeStr, ignoreCase: true, out var paymentType))
                    throw new InvalidOperationException($"Noto'g'ri to'lov turi: {request.PaymentType}");

                var payment = new Payment
                {
                    Id = Guid.NewGuid(),
                    SaleId = debt.SaleId,
                    PaymentType = paymentType,
                    Amount = request.Amount,
                    MarketId = marketId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.Payments.Add(payment);

                if (paymentType == PaymentType.Cash)
                {
                    var register = await _context.CashRegisters
                        .FirstOrDefaultAsync(cr => cr.MarketId == marketId, cancellationToken);
                    if (register == null)
                    {
                        // Defence in depth: AuthService and the migration both seed
                        // a register per market, but if someone deleted it manually
                        // we recreate rather than 500.
                        register = new CashRegister
                        {
                            Id = Guid.NewGuid(),
                            MarketId = marketId,
                            CurrentBalance = 0m,
                            LastUpdated = DateTime.UtcNow
                        };
                        _context.CashRegisters.Add(register);
                    }
                    register.CurrentBalance += request.Amount;
                    register.LastUpdated = DateTime.UtcNow;
                }

                debt.RemainingDebt -= request.Amount;
                if (debt.RemainingDebt <= 0)
                {
                    debt.RemainingDebt = 0;
                    debt.Status = DebtStatus.Closed;
                    sale.Status = SaleStatus.Closed;
                }
                sale.PaidAmount += request.Amount;

                await _context.SaveChangesAsync(cancellationToken);
                await tx.CommitAsync(cancellationToken);

                await _auditLog.LogPaymentActionAsync(payment.Id, actorUserId, cancellationToken);
                _logger.LogInformation(
                    "Debt payment recorded: DebtId={DebtId} Amount={Amount} Remaining={Remaining} ByUser={UserId}",
                    debtId, request.Amount, debt.RemainingDebt, actorUserId);

                return new PayDebtResultDto(
                    debt.RemainingDebt,
                    request.Amount,
                    debt.Status.ToString());
            }
            catch (Exception)
            {
                await tx.RollbackAsync(cancellationToken);
                throw;
            }
        });
    }

    private static DebtDto MapToDto(Debt debt)
    {
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
                si.Product?.GetUnitName() ?? "dona",
                si.Comment,
                si.IsExternal
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
    }
}
