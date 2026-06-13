using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IProductService
{
    Task<ProductDto?> GetProductByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetAllProductsAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<ProductDto>> GetAllProductsPagedAsync(int page, int size, CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(CancellationToken cancellationToken = default);
    Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default);
    Task<ProductDto?> UpdateProductAsync(UpdateProductDto request, CancellationToken cancellationToken = default);
    Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> UpdateStockAsync(Guid id, decimal quantityChange, CancellationToken cancellationToken = default);

    /// <summary>
    /// Mahsulotga rasm biriktiradi (yoki mavjudini almashtiradi). Baytlar
    /// allaqachon validatsiyadan o'tgan deb hisoblanadi. Mahsulot topilmasa
    /// (yoki boshqa tenantniki) null qaytaradi.
    /// </summary>
    Task<ProductDto?> SetProductImageAsync(Guid productId, byte[] bytes, string extension, CancellationToken cancellationToken = default);

    /// <summary>Mahsulot rasmini o'chiradi (ImageUrl=null + fayl). Topilmasa null.</summary>
    Task<ProductDto?> RemoveProductImageAsync(Guid productId, CancellationToken cancellationToken = default);
}
