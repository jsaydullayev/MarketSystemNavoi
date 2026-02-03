using System.Text.Json;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class AuditLogService : IAuditLogService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ILogger<AuditLogService> _logger;

    public AuditLogService(IUnitOfWork unitOfWork, ILogger<AuditLogService> logger)
    {
        _unitOfWork = unitOfWork;
        _logger = logger;
    }

    public async Task LogActionAsync(
        string entityType,
        Guid entityId,
        string action,
        Guid userId,
        object? payload = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            var auditLog = new AuditLog
            {
                Id = Guid.NewGuid(),
                EntityType = entityType,
                EntityId = entityId,
                Action = action,
                UserId = userId,
                Payload = payload != null ? JsonSerializer.Serialize(payload) : string.Empty,
                CreatedAt = DateTime.UtcNow
            };

            await _unitOfWork.AuditLogs.AddAsync(auditLog, cancellationToken);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Audit log created: {EntityType} {EntityId} - {Action} by User {UserId}",
                entityType, entityId, action, userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to create audit log for {EntityType} {EntityId}",
                entityType, entityId);
        }
    }

    public async Task LogSaleActionAsync(Guid saleId, string action, Guid userId, CancellationToken cancellationToken = default)
    {
        var sale = await _unitOfWork.Sales.GetByIdAsync(saleId, cancellationToken);
        if (sale != null)
        {
            await LogActionAsync("Sale", saleId, action, userId, new
            {
                SaleId = saleId,
                SellerId = sale.SellerId,
                CustomerId = sale.CustomerId,
                Status = sale.Status.ToString(),
                TotalAmount = sale.TotalAmount,
                PaidAmount = sale.PaidAmount
            }, cancellationToken);
        }
    }

    public async Task LogPaymentActionAsync(Guid paymentId, Guid userId, CancellationToken cancellationToken = default)
    {
        var payment = await _unitOfWork.Payments.GetByIdAsync(paymentId, cancellationToken);
        if (payment != null)
        {
            await LogActionAsync("Payment", paymentId, "Create", userId, new
            {
                PaymentId = paymentId,
                SaleId = payment.SaleId,
                PaymentType = payment.PaymentType.ToString(),
                Amount = payment.Amount
            }, cancellationToken);
        }
    }

    public async Task LogZakupActionAsync(Guid zakupId, Guid userId, CancellationToken cancellationToken = default)
    {
        var zakup = await _unitOfWork.Zakups.GetByIdAsync(zakupId, cancellationToken);
        if (zakup != null)
        {
            await LogActionAsync("Zakup", zakupId, "Create", userId, new
            {
                ZakupId = zakupId,
                ProductId = zakup.ProductId,
                Quantity = zakup.Quantity,
                CostPrice = zakup.CostPrice
            }, cancellationToken);
        }
    }

    public async Task LogDebtActionAsync(Guid debtId, string action, Guid userId, CancellationToken cancellationToken = default)
    {
        var debt = await _unitOfWork.Debts.GetByIdAsync(debtId, cancellationToken);
        if (debt != null)
        {
            await LogActionAsync("Debt", debtId, action, userId, new
            {
                DebtId = debtId,
                SaleId = debt.SaleId,
                CustomerId = debt.CustomerId,
                TotalDebt = debt.TotalDebt,
                RemainingDebt = debt.RemainingDebt,
                Status = debt.Status.ToString()
            }, cancellationToken);
        }
    }
}
