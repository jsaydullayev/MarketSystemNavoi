namespace MarketSystem.Application.DTOs;

public record CreateProductRequest(string Name);
public record CreateZakupRequest(Guid ProductId, decimal Quantity, decimal CostPrice);
public record ProductResponse(Guid Id, string Name, bool IsTemporary);
