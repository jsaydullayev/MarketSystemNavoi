namespace MarketSystem.Application.DTOs;

public record CreateProductRequest(string Name);
public record CreateBranchProductRequest(Guid BranchId, Guid ProductId, decimal CostPrice, decimal SalePrice, decimal MinSalePrice, decimal Quantity, decimal MinThreshold);
public record CreateZakupRequest(Guid ProductId, Guid BranchId, decimal Quantity, decimal CostPrice);
public record ProductResponse(Guid Id, string Name, bool IsTemporary);
public record BranchProductResponse(Guid Id, Guid ProductId, string ProductName, decimal CostPrice, decimal SalePrice, decimal MinSalePrice, decimal Quantity, decimal MinThreshold, bool IsLowStock);
