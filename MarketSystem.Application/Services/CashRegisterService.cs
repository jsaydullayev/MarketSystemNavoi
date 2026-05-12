using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class CashRegisterService : ICashRegisterService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CashRegisterService> _logger;
    private readonly AppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ITashkentClock _clock;

    public CashRegisterService(IUnitOfWork unitOfWork, ILogger<CashRegisterService> logger, AppDbContext context, ICurrentMarketService currentMarketService, ITashkentClock clock)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _context = context;
        _currentMarketService = currentMarketService;
        _clock = clock;
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

            return await _unitOfWork.ExecuteInTransactionAsync(async () =>
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

                if (request.WithdrawType == "cash")
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
                        WithdrawType = "cash"
                    };

                    _context.CashWithdrawals.Add(withdrawal);

                    cashRegister.CurrentBalance -= request.Amount;
                    cashRegister.LastUpdated = DateTime.UtcNow;
                    cashRegister.LastWithdrawalId = withdrawal.Id;

                    await _context.SaveChangesAsync(cancellationToken);
                    _logger.LogInformation("Cash withdrawn. Amount: {Amount}", request.Amount);
                }
                else if (request.WithdrawType == "click")
                {
                    var withdrawal = new CashWithdrawal
                    {
                        Id = Guid.NewGuid(),
                        Amount = request.Amount,
                        Comment = request.Comment,
                        WithdrawalDate = DateTime.UtcNow,
                        UserId = userId,
                        WithdrawType = "click"
                    };

                    _context.CashWithdrawals.Add(withdrawal);

                    cashRegister.LastUpdated = DateTime.UtcNow;
                    cashRegister.LastWithdrawalId = withdrawal.Id;

                    await _context.SaveChangesAsync(cancellationToken);
                    _logger.LogInformation("Click withdrawal recorded. Amount: {Amount}", request.Amount);
                }
                else
                {
                    _logger.LogWarning("Invalid withdraw type: {Type}", request.WithdrawType);
                    return false;
                }

                return true;
            }, cancellationToken);
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
            var cashRegister = await GetOrCreateRegisterAsync(marketId, cancellationToken);

            cashRegister.CurrentBalance += amount;
            cashRegister.LastUpdated = DateTime.UtcNow;
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Cash added. Amount: {Amount}, MarketId: {MarketId}", amount, marketId);
            return true;
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

            decimal cashPaid = 0;
            decimal cardPaid = 0;
            decimal clickPaid = 0;

            foreach (var sale in todaySales)
            {
                foreach (var payment in sale.Payments)
                {
                    if (payment.PaymentType == Domain.Enums.PaymentType.Cash)
                    {
                        cashPaid += payment.Amount;
                    }
                    else if (payment.PaymentType == Domain.Enums.PaymentType.Terminal ||
                             payment.PaymentType == Domain.Enums.PaymentType.Transfer)
                    {
                        cardPaid += payment.Amount;
                    }
                    else if (payment.PaymentType == Domain.Enums.PaymentType.Click)
                    {
                        clickPaid += payment.Amount;
                    }
                }
            }

            return new TodaySalesSummaryDto
            {
                TotalSales = todaySales.Count,
                TotalAmount = todaySales.Sum(s => s.TotalAmount),
                TotalPaid = todaySales.Sum(s => s.PaidAmount),
                DebtAmount = todaySales.Sum(s => s.TotalAmount > s.PaidAmount ? s.TotalAmount - s.PaidAmount : 0),
                CashPaid = cashPaid,
                CardPaid = cardPaid,
                ClickPaid = clickPaid,
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
