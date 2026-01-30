using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.DTOs;

public record CreateSaleRequest(Guid BranchId, Guid SellerId, Guid? CustomerId);
public record AddSaleItemRequest(Guid SaleId, Guid ProductId, decimal Quantity, decimal SalePrice, string? Comment);
public record AddPaymentRequest(Guid SaleId, PaymentType PaymentType, decimal Amount);
public record SaleItemResponse(Guid Id, Guid ProductId, string ProductName, decimal Quantity, decimal CostPrice, decimal SalePrice, decimal Profit, string? Comment);
public record PaymentResponse(Guid Id, PaymentType PaymentType, decimal Amount, DateTime CreatedAt);
public record SaleResponse(Guid Id, Guid BranchId, Guid SellerId, SaleStatus Status, decimal TotalAmount, decimal PaidAmount, decimal RemainingAmount, ICollection<SaleItemResponse> Items, ICollection<PaymentResponse> Payments);
