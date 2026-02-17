using MediatR;
using Microsoft.Extensions.Logging;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record AddPaymentCommand(AddPaymentRequest Request) : IRequest<PaymentResponse>;

public class AddPaymentCommandHandler : IRequestHandler<AddPaymentCommand, PaymentResponse>
{
    private readonly AppDbContext _context;
    private readonly ILogger<AddPaymentCommandHandler> _logger;

    public AddPaymentCommandHandler(AppDbContext context, ILogger<AddPaymentCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<PaymentResponse> Handle(AddPaymentCommand command, CancellationToken cancellationToken)
    {
        var request = command.Request;

        _logger.LogInformation("Adding payment to sale {SaleId}: Type={Type}, Amount={Amount}",
            request.SaleId, request.PaymentType, request.Amount);

        try
        {
            using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            // Get sale with all related data
            var sale = await _context.Sales
                .Include(s => s.Payments)
                .Include(s => s.Debt)
                .Include(s => s.SaleItems)
                .FirstOrDefaultAsync(s => s.Id == request.SaleId, cancellationToken)
                ?? throw new Exception($"Sale with ID {request.SaleId} not found");

            if (sale.Status == SaleStatus.Cancelled)
            {
                _logger.LogWarning("Attempt to add payment to cancelled sale {SaleId}", request.SaleId);
                throw new Exception("Cannot add payment to cancelled sale");
            }

            if (sale.Status == SaleStatus.Closed)
            {
                _logger.LogWarning("Attempt to add payment to closed sale {SaleId}", request.SaleId);
                throw new Exception("Cannot add payment to closed sale");
            }

            var previousStatus = sale.Status;
            var payment = new Payment
            {
                Id = Guid.NewGuid(),
                SaleId = request.SaleId,
                PaymentType = request.PaymentType,
                Amount = request.Amount
            };

            _context.Payments.Add(payment);

            var totalPaid = sale.PaidAmount + request.Amount;
            sale.PaidAmount = totalPaid;

            // Determine sale status based on payment
            if (totalPaid >= sale.TotalAmount)
            {
                // Fully paid
                if (sale.Debt != null)
                {
                    _logger.LogInformation("Closing debt for sale {SaleId}. Previous debt: {Debt}",
                        request.SaleId, sale.Debt.RemainingDebt);
                    sale.Debt.RemainingDebt = 0;
                    sale.Debt.Status = DebtStatus.Closed;
                }

                sale.Status = SaleStatus.Closed; // To'liq to'langanda Closed status
                _logger.LogInformation("Sale {SaleId} fully paid. Status changed to Closed", request.SaleId);
            }
            else if (totalPaid > 0)
            {
                // Partial payment - create/update debt
                if (sale.Debt == null)
                {
                    if (sale.CustomerId == null)
                    {
                        _logger.LogError("Attempt to create debt without customer for sale {SaleId}", request.SaleId);
                        throw new Exception("Customer required for debt sales");
                    }

                    var remainingDebt = sale.TotalAmount - totalPaid;
                    sale.Debt = new Debt
                    {
                        Id = Guid.NewGuid(),
                        SaleId = sale.Id,
                        CustomerId = sale.CustomerId.Value,
                        TotalDebt = remainingDebt,
                        RemainingDebt = remainingDebt,
                        Status = DebtStatus.Open
                    };
                    _context.Debts.Add(sale.Debt);
                    _logger.LogInformation("Created new debt for sale {SaleId}: {DebtAmount}",
                        request.SaleId, remainingDebt);
                }
                else
                {
                    var newRemainingDebt = sale.TotalAmount - totalPaid;
                    _logger.LogInformation("Updating debt for sale {SaleId}: Previous={Previous}, New={New}",
                        request.SaleId, sale.Debt.RemainingDebt, newRemainingDebt);
                    sale.Debt.RemainingDebt = newRemainingDebt;
                }

                sale.Status = SaleStatus.Debt;
                _logger.LogInformation("Sale {SaleId} partially paid. Status changed to Debt. Remaining: {Remaining}",
                    request.SaleId, sale.TotalAmount - totalPaid);
            }

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            _logger.LogInformation("Payment added successfully to sale {SaleId}. Payment ID: {PaymentId}, Total Paid: {TotalPaid}, Status: {Status}",
                request.SaleId, payment.Id, totalPaid, sale.Status);

            return new PaymentResponse(payment.Id, payment.PaymentType, payment.Amount, payment.CreatedAt);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error adding payment to sale {SaleId}: {Message}", request.SaleId, ex.Message);
            throw;
        }
    }
}
