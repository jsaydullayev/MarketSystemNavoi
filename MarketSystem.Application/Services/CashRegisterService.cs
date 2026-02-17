using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace MarketSystem.Application.Services;

public class CashRegisterService : ICashRegisterService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<CashRegisterService> _logger;
    private readonly AppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;

    public CashRegisterService(IUnitOfWork unitOfWork, ILogger<CashRegisterService> logger, AppDbContext context, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
        _context = context;
        _currentMarketService = currentMarketService;
    }

    public async Task<CashRegisterDto?> GetCashRegisterAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            var marketId = _currentMarketService.GetCurrentMarketId();

            var cashRegister = await _context.CashRegisters
                .Include(x => x.LastWithdrawal)
                .FirstOrDefaultAsync(cancellationToken);

            // Agar cash register yo'q bo'lsa, yaratamiz
            if (cashRegister == null)
            {
                cashRegister = new CashRegister
                {
                    Id = Guid.NewGuid(),
                    CurrentBalance = 0,
                    LastUpdated = DateTime.UtcNow
                };
                _context.CashRegisters.Add(cashRegister);
                await _context.SaveChangesAsync(cancellationToken);
            }

            // Filter withdrawals by market (through User.MarketId)
            var withdrawals = await _context.CashWithdrawals
                .Include(x => x.User)
                .Where(x => x.User != null && x.User.MarketId == marketId)
                .OrderByDescending(x => x.WithdrawalDate)
                .Take(50)
                .ToListAsync(cancellationToken);

            var cashRegisterDto = new CashRegisterDto
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

            return cashRegisterDto;
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
            using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            var cashRegister = await _context.CashRegisters
                .FirstOrDefaultAsync(cancellationToken);

            if (cashRegister == null)
            {
                _logger.LogWarning("Cash register not found");
                return false;
            }

            if (request.Amount <= 0)
            {
                _logger.LogWarning("Invalid withdrawal amount: {Amount}", request.Amount);
                return false;
            }

            _logger.LogInformation("WithdrawCashAsync called. Type: {Type}, Amount: {Amount}",
                request.WithdrawType, request.Amount);

            // Agar 'cash' bo'lsa, kassadan pul olinadi
            if (request.WithdrawType == "cash")
            {
                if (cashRegister.CurrentBalance < request.Amount)
                {
                    _logger.LogWarning("Insufficient funds in cash register. Balance: {Balance}, Requested: {Amount}",
                        cashRegister.CurrentBalance, request.Amount);
                    return false;
                }

                // Withdrawal yaratish
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

                // Balansni kamaytirish
                cashRegister.CurrentBalance -= request.Amount;
                cashRegister.LastUpdated = DateTime.UtcNow;
                cashRegister.LastWithdrawalId = withdrawal.Id;

                await _context.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                _logger.LogInformation("Cash withdrawn successfully. Type: cash, Amount: {Amount}", request.Amount);
            }
            // Agar 'click' bo'lsa, tarixga yozib qo'ydi, balansga ta'sir qilmaydi
            else if (request.WithdrawType == "click")
            {
                // Withdrawal yaratish (faqat tarix uchun, balansga ta'sir qilmaydi)
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

                // Faqat yangilash
                cashRegister.LastUpdated = DateTime.UtcNow;
                cashRegister.LastWithdrawalId = withdrawal.Id;

                await _context.SaveChangesAsync(cancellationToken);
                await transaction.CommitAsync(cancellationToken);

                _logger.LogInformation("Click withdrawal recorded. Type: click, Amount: {Amount}", request.Amount);
            }
            else
            {
                _logger.LogWarning("Invalid withdraw type: {Type}", request.WithdrawType);
                return false;
            }

            return true;
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

            var cashRegister = await _context.CashRegisters
                .FirstOrDefaultAsync(cancellationToken);

            if (cashRegister == null)
            {
                cashRegister = new CashRegister
                {
                    Id = Guid.NewGuid(),
                    CurrentBalance = amount,
                    LastUpdated = DateTime.UtcNow
                };
                _context.CashRegisters.Add(cashRegister);
            }
            else
            {
                cashRegister.CurrentBalance += amount;
                cashRegister.LastUpdated = DateTime.UtcNow;
            }

            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Cash added successfully. Amount: {Amount}", amount);
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
            var today = DateTime.UtcNow.Date;

            // Bugungi savdolarni olish (filtered by market)
            var todaySales = await _context.Sales
                .Where(s => s.CreatedAt.Date == today && s.MarketId == marketId)
                .Include(s => s.Payments)
                .ToListAsync(cancellationToken);

            // To'lovlar bo'yicha hisoblash
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

            var summary = new TodaySalesSummaryDto
            {
                TotalSales = todaySales.Count,
                TotalAmount = todaySales.Sum(s => s.TotalAmount),
                TotalPaid = todaySales.Sum(s => s.PaidAmount),
                CashPaid = cashPaid,
                CardPaid = cardPaid,
                ClickPaid = clickPaid,
                Date = today
            };

            return summary;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting today's sales summary");
            return null;
        }
    }
}
//new code