using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface ISaleService
{
    Task<Sale> CreateSaleAsync(Guid branchId, Guid sellerId, Guid? customerId, CancellationToken cancellationToken = default);
    Task<Sale?> GetSaleAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task AddItemAsync(Guid saleId, Guid productId, decimal quantity, decimal costPrice, decimal salePrice, string? comment, CancellationToken cancellationToken = default);
    Task<bool> CanAddItemAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task CancelSaleAsync(Guid saleId, CancellationToken cancellationToken = default);
}
