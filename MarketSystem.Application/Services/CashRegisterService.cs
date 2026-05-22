using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class CashRegisterService : ICashRegisterService
{
    private const string WithdrawTypeCash = "cash";
    private const string WithdrawTypeClick = "click";

    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CashRegisterService> _logger;
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ITashkentClock _clock;
    private readonly IAuditLogService _auditLogService;

    public CashRegisterService(IUnitOfWork unitOfWork, ILogger<CashRegisterService> logger, IAppDbContext context, ICurrentMarketService currentMarketService, ITashkentClock clock, IAuditLogService auditLogService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _context = context;
        _currentMarketService = currentMarketService;
        _clock = clock;
        _auditLogService = auditLogService;
    }

    private async Task<CashRegister> GetOrCreateRegisterAsync(int marketId, CancellationToken cancellationToken)
    {
        var register = await _context.CashRegisters
            .Include(x => x.LastWithdrawal)
            .FirstOrDefaultAsync(x => x.MarketId == marketId, cancellationToken);

        if (register != null) return register;

        register = new CashRegister
        {
            Id = Guid.NewGuid(),
            MarketId = marketId,
            CurrentBalance = 0,
            LastUpdated = DateTime.UtcNow
        };
        _context.CashRegisters.Add(register);
        try
        {
            await _context.SaveChangesAsync(cancellationToken);
            return register;
        }
        catch (DbUpdateException)
        {
            // Another concurrent request just inserted the per-market register.
            // Drop the local entity from the change tracker and re-read.
            _context.Entry(register).State = EntityState.Detached;
            var existing = await _context.CashRegisters
                .Include(x => x.LastWithdrawal)
                .FirstOrDefaultAsync(x => x.MarketId == marketId, cancellationToken);
            if (existing == null) throw;
            return existing;
        }
    }

    public async Task<CashRegisterDto?> GetCashRegisterAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
            var cashRegister = await GetOrCreateRegisterAsync(marketId, cancellationToken);

            var withdrawals = await _context.CashWithdrawals
                .Include(x => x.User)
                .Where(x => x.User == null || x.User.MarketId == marketId)
                .OrderByDescending(x => x.WithdrawalDate)
                .Take(50)
                .ToListAsync(cancellationToken);

            return new CashRegisterDto
            {
                Id = cashRegister.Id,
                CurrentBalance = cashRegister.CurrentBalance,
                LastUpdated = cashRegister.LastUpdated,
                Withdrawals = withdrawals.Select(w => new CashWithdrawalDto
                {
                    Id = w.Id,
                    Amount = w.Amount,
                    Comment = w.Comment,
                    WithdrawalDate = w.WithdrawalDate,
                    UserName = w.User?.FullName ?? "Unknown"
                }).ToList()
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting cash register");
            return null;
        }
    }

    public async Task<bool> WithdrawCashAsync(WithdrawCashRequest request, Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
            CashWithdrawal? recorded = null;

            var ok = await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var cashRegister = await _context.CashRegisters
                    .FirstOrDefaultAsync(x => x.MarketId == marketId, cancellationToken);

                if (cashRegister == null)
                {
                    _logger.LogWarning("Cash register not found for market {MarketId}", marketId);
                    return false;
                }

                if (request.Amount <= 0)
                {
                    _logger.LogWarning("Invalid withdrawal amount: {Amount}", request.Amount);
                    return false;
                }

                _logger.LogInformation("WithdrawCashAsync called. Type: {Type}, Amount: {Amount}, MarketId: {MarketId}",
                    request.WithdrawType, request.Amount, marketId);

                if (request.WithdrawType == WithdrawTypeCash)
                {
                    if (cashRegister.CurrentBalance < request.Amount)
                    {
                        _logger.LogWarning("Insufficient funds. Balance: {Balance}, Requested: {Amount}",
                            cashRegister.CurrentBalance, request.Amount);
                        return false;
                    }

                    var withdrawal = new CashWithdrawal
                    {
                        Id = Guid.NewGuid(),
                        Amount = request.Amount,
                        Comment = request.Comment,
                        WithdrawalDate = DateTime.UtcNow,
                        UserId = userId,
                        WithdrawType = WithdrawTypeCash
                    };

                    _context.CashWithdrawals.Add(withdrawal);

                    cashRegister.CurrentBalance -= request.Amount;
                    cashRegister.LastUpdated = DateTime.UtcNow;
                    cashRegister.LastWithdrawalId = withdrawal.Id;

                    await _context.SaveChangesAsync(cancellationToken);
                    recorded = withdrawal;
                    _logger.LogInformation("Cash withdrawn. Amount: {Amount}", request.Amount);
                }
                else if (request.WithdrawType == WithdrawTypeClick)
                {
                    var withdrawal = new CashWithdrawal
                    {
                        Id = Guid.NewGuid(),
                        Amount = request.Amount,
                        Comment = request.Comment,
                        WithdrawalDate = DateTime.UtcNow,
                        UserId = userId,
                        WithdrawType = WithdrawTypeClick
                    };

                    _context.CashWithdrawals.Add(withdrawal);

                    cashRegister.LastUpdated = DateTime.UtcNow;
                    cashRegister.LastWithdrawalId = withdrawal.Id;

                    await _context.SaveChangesAsync(cancellationToken);
                    recorded = withdrawal;
                    _logger.LogInformation("Click withdrawal recorded. Amount: {Amount}", request.Amount);
                }
                else
                {
                    _logger.LogWarning("Invalid withdraw type: {Type}", request.WithdrawType);
                    return false;
                }

                return true;
            }, cancellationToken);

            // Audit AFTER the transaction commits. LogActionAsync swallows its
            // own errors, but running it outside the transaction also guarantees
            // a failed audit write can never roll back a completed withdrawal.
            if (ok && recorded is not null)
            {
                await _auditLogService.LogActionAsync(
                    AuditEntityTypes.CashRegister, recorded.Id, AuditActions.Withdraw, userId,
                    new { recorded.Amount, recorded.WithdrawType, recorded.Comment }, cancellationToken);
            }

            return ok;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error withdrawing cash");
            return false;
        }
    }

    public async Task<bool> AddCashAsync(decimal amount, CancellationToken cancellationToken = default)
    {
        try
        {
            if (amount <= 0)
            {
                _logger.LogWarning("Invalid deposit amount: {Amount}", amount);
                return false;
            }

            var marketId = _currentMarketService.GetCurrentMarketId();

            // Mirror WithdrawCashAsync — wrap the read/modify/save in a
            // transaction so two concurrent deposits can't both read the
            // same balance, both add their amounts, and clobber each other.
            // The EnableRetryOnFailure on the DbContext also handles transient
            // failures, but only when the work is inside a transaction.
            return await _unitOfWork.ExecuteInTransactionAsync(async () =>
            {
                var cashRegister = await GetOrCreateRegisterAsync(marketId, cancellationToken);
                cashRegister.CurrentBalance += amount;
                cashRegister.LastUpdated = DateTime.UtcNow;
                await _context.SaveChangesAsync(cancellationToken);

                _logger.LogInformation("Cash added. Amount: {Amount}, MarketId: {MarketId}", amount, marketId);
                return true;
            }, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding cash");
            return false;
        }
    }

    public async Task<TodaySalesSummaryDto?> GetTodaySalesSummaryAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();
            // Tashkent business day, expressed as a UTC half-open range.
            var todayLocal = _clock.TodayLocal;
            var (todayUtcStart, todayUtcEnd) = _clock.LocalDayToUtcRange(todayLocal);

            var todaySales = await _context.Sales
                .Where(s => s.CreatedAt >= todayUtcStart && s.CreatedAt < todayUtcEnd && s.MarketId == marketId)
                .Include(s => s.Payments)
                .ToListAsync(cancellationToken);

            var allPayments = todaySales.SelectMany(s => s.Payments).ToList();

            return new TodaySalesSummaryDto
            {
                TotalSales = todaySales.Count,
                TotalAmount = todaySales.Sum(s => s.TotalAmount),
                TotalPaid = todaySales.Sum(s => s.PaidAmount),
                DebtAmount = todaySales.Sum(s => s.TotalAmount > s.PaidAmount ? s.TotalAmount - s.PaidAmount : 0),
                CashPaid = allPayments
                    .Where(p => p.PaymentType == Domain.Enums.PaymentType.Cash)
                    .Sum(p => p.Amount),
                CardPaid = allPayments
                    .Where(p => p.PaymentType == Domain.Enums.PaymentType.Terminal ||
                                p.PaymentType == Domain.Enums.PaymentType.Transfer)
                    .Sum(p => p.Amount),
                ClickPaid = allPayments
                    .Where(p => p.PaymentType == Domain.Enums.PaymentType.Click)
                    .Sum(p => p.Amount),
                Date = todayLocal
            };
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting today's sales summary");
            return null;
        }
    }
}
