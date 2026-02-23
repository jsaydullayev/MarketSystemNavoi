using MarketSystem.Application.DTOs;

namespace MarketSystem.Domain.Interfaces;

public interface IProductService
{
    Task<ProductDto?> GetProductByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetAllProductsAsync(CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(CancellationToken cancellationToken = default);
    Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default);
    Task<ProductDto?> UpdateProductAsync(UpdateProductDto request, CancellationToken cancellationToken = default);
    Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> UpdateStockAsync(Guid id, decimal quantityChange, CancellationToken cancellationToken = default);
}
