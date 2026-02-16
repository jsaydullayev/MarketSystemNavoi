using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Services;

public class PaymentService : IPaymentService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<PaymentService> _logger;

    public PaymentService(IUnitOfWork unitOfWork, ILogger<PaymentService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task<Payment> AddPaymentAsync(
        Guid saleId,
        PaymentType paymentType,
        decimal amount,
        int marketId,
        CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("Adding payment: SaleId={SaleId}, Type={Type}, Amount={Amount}, MarketId={MarketId}",
            saleId, paymentType, amount, marketId);

        var payment = new Payment
        {
            Id = Guid.NewGuid(),
            SaleId = saleId,
            PaymentType = paymentType,
            Amount = amount,
            MarketId = marketId  // Multi-tenancy - MarketId from parameter
        };

        await _unitOfWork.Payments.AddAsync(payment, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Payment added: PaymentId={PaymentId}", payment.Id);
        return payment;
    }

    public Task UpdateSaleStatusAsync(Sale sale, CancellationToken cancellationToken = default)
    {
        var totalPaid = sale.PaidAmount;
        var previousStatus = sale.Status;

        if (totalPaid >= sale.TotalAmount)
        {
            sale.Status = SaleStatus.Paid;
            _logger.LogInformation("Sale {SaleId} fully paid. Status changed from {Previous} to Paid",
                sale.Id, previousStatus);
        }
        else if (totalPaid > 0)
        {
            sale.Status = SaleStatus.Debt;
            _logger.LogInformation("Sale {SaleId} partially paid. Status changed from {Previous} to Debt. Remaining: {Remaining}",
                sale.Id, previousStatus, sale.TotalAmount - totalPaid);
        }

        return Task.CompletedTask;
    }

    public async Task<Debt?> CreateOrUpdateDebtAsync(Sale sale, CancellationToken cancellationToken = default)
    {
        var totalPaid = sale.PaidAmount;

        // Check if debt should exist
        if (totalPaid >= sale.TotalAmount)
        {
            // No debt needed - close existing if any
            if (sale.Debt != null)
            {
                sale.Debt.RemainingDebt = 0;
                sale.Debt.Status = DebtStatus.Closed;
                await _unitOfWork.SaveChangesAsync(cancellationToken);
            }
            return null;
        }

        // Create or update debt
        if (sale.Debt == null)
        {
            if (sale.CustomerId == null)
            {
                throw new Exception("Customer required for debt sales");
            }

            var remainingDebt = sale.TotalAmount - totalPaid;

            var debt = new Debt
            {
                Id = Guid.NewGuid(),
                SaleId = sale.Id,
                CustomerId = sale.CustomerId.Value,
                TotalDebt = remainingDebt,
                RemainingDebt = remainingDebt,
                Status = DebtStatus.Open,
                MarketId = sale.MarketId  // Multi-tenancy - inherit from Sale
            };

            await _unitOfWork.Debts.AddAsync(debt, cancellationToken);
            sale.Debt = debt;

            _logger.LogInformation("Created debt for sale {SaleId}: {DebtAmount}", sale.Id, remainingDebt);
        }
        else
        {
            var newRemainingDebt = sale.TotalAmount - totalPaid;
            _logger.LogInformation("Updating debt for sale {SaleId}: Previous={Previous}, New={New}",
                sale.Id, sale.Debt.RemainingDebt, newRemainingDebt);
            sale.Debt.RemainingDebt = newRemainingDebt;
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return sale.Debt;
    }

    public async Task CloseDebtAsync(Guid saleId, CancellationToken cancellationToken = default)
    {
        var sale = await _unitOfWork.Sales.GetWithDetailsAsync(saleId, cancellationToken);

        if (sale?.Debt == null)
        {
            return;
        }

        _logger.LogInformation("Closing debt for sale {SaleId}. Previous debt: {Debt}",
            saleId, sale.Debt.RemainingDebt);

        sale.Debt.RemainingDebt = 0;
        sale.Debt.Status = DebtStatus.Closed;

        await _unitOfWork.SaveChangesAsync(cancellationToken);
    }
}
