using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IProductService
{
    // canViewCost=false masks CostPrice (returns 0) for callers without
    // data.costPrice visibility — Sellers. Defaults to true so existing
    // internal/mutation call-sites and tests are unaffected; the read
    // controllers pass the role-derived value explicitly.
    Task<ProductDto?> GetProductByIdAsync(Guid id, bool canViewCost = true, CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetAllProductsAsync(bool canViewCost = true, CancellationToken cancellationToken = default);
    Task<PagedResult<ProductDto>> GetAllProductsPagedAsync(int page, int size, bool canViewCost = true, CancellationToken cancellationToken = default);
    Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(bool canViewCost = true, CancellationToken cancellationToken = default);
    Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default);

    // canEditStock=true lets the caller hand-correct on-hand Quantity via
    // request.Quantity (Owner/SuperAdmin only — the controller derives it from
    // the role). Defaults to false so existing call-sites and every non-Owner
    // request leave stock untouched; stock otherwise moves only through zakup/sales.
    // canEditCost=true lets the caller set CostPrice via request.CostPrice
    // (Owner/Admin — cost-viewers only). Defaults to false so cost-hidden callers
    // (whose GET masks CostPrice to 0) can't clobber the stored cost on edit.
    Task<ProductDto?> UpdateProductAsync(UpdateProductDto request, bool canEditStock = false, bool canEditCost = false, CancellationToken cancellationToken = default);
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
