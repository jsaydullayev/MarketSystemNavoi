using MediatR;
using Microsoft.Extensions.Logging;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Commands;

public record CancelSaleCommand(Guid SaleId, Guid AdminId) : IRequest;

public class CancelSaleCommandHandler : IRequestHandler<CancelSaleCommand>
{
    private readonly AppDbContext _context;
    private readonly ILogger<CancelSaleCommandHandler> _logger;

    public CancelSaleCommandHandler(AppDbContext context, ILogger<CancelSaleCommandHandler> logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task Handle(CancelSaleCommand command, CancellationToken cancellationToken)
    {
        _logger.LogInformation("Admin {AdminId} attempting to cancel sale {SaleId}", command.AdminId, command.SaleId);

        try
        {
            using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);

            // Validate admin
            var admin = await _context.Users
                .FirstOrDefaultAsync(u => u.Id == command.AdminId && u.IsActive, cancellationToken)
                ?? throw new Exception($"Admin with ID {command.AdminId} not found or inactive");

            var sale = await _context.Sales
                .Include(s => s.SaleItems)
                .Include(s => s.Debt)
                .Include(s => s.Payments)
                .FirstOrDefaultAsync(s => s.Id == command.SaleId, cancellationToken)
                ?? throw new Exception($"Sale with ID {command.SaleId} not found");

            var previousStatus = sale.Status;

            if (sale.Status == SaleStatus.Cancelled)
            {
                _logger.LogWarning("Attempt to cancel already cancelled sale {SaleId}", command.SaleId);
                throw new Exception("Sale already cancelled");
            }

            // Update sale status
            sale.Status = SaleStatus.Cancelled;
            _logger.LogInformation("Sale {SaleId} status changed from {PreviousStatus} to Cancelled",
                command.SaleId, previousStatus);

            // Close debt if exists
            if (sale.Debt != null)
            {
                var previousDebt = sale.Debt.RemainingDebt;
                sale.Debt.Status = DebtStatus.Closed;
                sale.Debt.RemainingDebt = 0;
                _logger.LogInformation("Closed debt for sale {SaleId}. Previous debt: {Debt}",
                    command.SaleId, previousDebt);
            }

            await _context.SaveChangesAsync(cancellationToken);
            await transaction.CommitAsync(cancellationToken);

            _logger.LogInformation("Sale {SaleId} successfully cancelled by Admin {AdminId}",
                command.SaleId, command.AdminId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error cancelling sale {SaleId}: {Message}", command.SaleId, ex.Message);
            throw;
        }
    }
}
