using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class ProductService : IProductService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IAppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IProductImageStorage _imageStorage;

    public ProductService(IUnitOfWork unitOfWork, IAppDbContext context, ICurrentMarketService currentMarketService, IProductImageStorage imageStorage)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
        _imageStorage = imageStorage;
    }

    public async Task<ProductDto?> GetProductByIdAsync(Guid id, bool canViewCost = true, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // P3 — pure read-then-map path. Don't pay the change-tracker cost
        // (snapshot of every loaded property + reverse navigation fix-up)
        // on a single-entity lookup that only serves a DTO.
        var product = await _context.Products
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id && p.MarketId == marketId, cancellationToken);

        if (product is null)
            return null;

        return MapToDto(product, canViewCost);
    }

    public async Task<IEnumerable<ProductDto>> GetAllProductsAsync(bool canViewCost = true, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // P3 — list-then-map path; same reasoning as GetProductByIdAsync.
        // Hard cap at 5000 to prevent OOM on large markets; callers needing
        // unbounded access should use GetAllProductsPagedAsync instead.
        var products = await _context.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.MarketId == marketId)
            .Take(5000)
            .ToListAsync(cancellationToken);

        return products.Select(p => MapToDto(p, canViewCost));
    }

    public async Task<PagedResult<ProductDto>> GetAllProductsPagedAsync(int page, int size, bool canViewCost = true, CancellationToken cancellationToken = default)
    {
        page = Math.Max(1, page);
        size = Math.Clamp(size, 1, 200);

        var marketId = _currentMarketService.GetCurrentMarketId();

        var query = _context.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.MarketId == marketId);

        var total = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(p => p.Name)
            .Skip((page - 1) * size)
            .Take(size)
            .ToListAsync(cancellationToken);

        return PagedResult<ProductDto>.From(items.Select(p => MapToDto(p, canViewCost)).ToList(), page, size, total);
    }

    public async Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(bool canViewCost = true, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // P3 — dashboard widget; reads only.
        var products = await _context.Products
            .AsNoTracking()
            .Include(p => p.Category)
            .Where(p => p.MarketId == marketId && p.Quantity <= p.MinThreshold)
            .ToListAsync(cancellationToken);

        return products.Select(p => MapToDto(p, canViewCost));
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.TryGetCurrentMarketId();

        if (!marketId.HasValue)
        {
            throw new UnauthorizedAccessException("Siz hali market yaratmagansiz. Iltimos, avval market yaratiling.");
        }

        var unitValue = request.Unit == 0 ? 1 : request.Unit;
        if (!Enum.IsDefined(typeof(UnitType), unitValue))
        {
            throw new ArgumentException("Noto'g'ri o'lchov birligi tanlandi!");
        }

        // Per-market product name uniqueness — surface a friendly error before
        // EF lets Postgres reject the insert with a raw 23505. The DB index is
        // partial on `IsDeleted = false` so a re-created product after delete works.
        var nameTaken = await _unitOfWork.Products.AnyAsync(
            p => p.MarketId == marketId.Value && p.Name == request.Name && !p.IsDeleted,
            cancellationToken);
        if (nameTaken)
            throw new InvalidOperationException($"'{request.Name}' nomli mahsulot allaqachon mavjud.");

        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            IsTemporary = request.IsTemporary,
            CreatedBySellerId = sellerId,
            CostPrice = 0, // Zakup orqali belgilanadi
            SalePrice = request.SalePrice,
            MinSalePrice = request.MinSalePrice,
            // Boshlang'ich qoldiq: do'konda bor, lekin zakupsiz tovarlar uchun
            // foydalanuvchi kiritgan miqdor. Keyingi qoldiq o'zgarishlari zakup
            // orqali davom etadi.
            Quantity = request.Quantity,
            MinThreshold = request.MinThreshold,
            Unit = (UnitType)unitValue,  // ✅ NEW: Unit type
            MarketId = marketId.Value,  // Multi-tenancy
            CategoryId = request.CategoryId  // Category
        };

        await _unitOfWork.Products.AddAsync(product, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(product);
    }

    public async Task<ProductDto?> UpdateProductAsync(UpdateProductDto request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == request.Id && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return null;

        var unitValue = request.Unit == 0 ? 1 : request.Unit;
        if (!Enum.IsDefined(typeof(UnitType), unitValue))
        {
            throw new ArgumentException("Noto'g'ri o'lchov birligi tanlandi!");
        }

        product.Name = request.Name;
        product.IsTemporary = request.IsTemporary;
        // CostPrice va Quantity faqat Zakup orqali yangilanadi
        product.SalePrice = request.SalePrice;
        product.MinSalePrice = request.MinSalePrice;
        product.MinThreshold = request.MinThreshold;
        product.Unit = (UnitType)unitValue;  // ✅ NEW: Update unit
        product.CategoryId = request.CategoryId;  // Category

        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(product);
    }

    public async Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == id && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return false;

        _unitOfWork.Products.Delete(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UpdateStockAsync(Guid id, decimal quantityChange, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == id && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return false;

        // Check if new quantity would be negative
        var newQuantity = product.Quantity + quantityChange;
        if (newQuantity < 0)
            throw new InvalidOperationException($"Insufficient stock. Current: {product.Quantity} {product.GetUnitName()}, Requested change: {quantityChange}");

        product.Quantity = newQuantity;
        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<ProductDto?> SetProductImageAsync(Guid productId, byte[] bytes, string extension, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Tenant filtri — boshqa marketning mahsulotini topib bo'lmaydi.
        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == productId && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return null;

        // Eski rasmni o'chiramiz (yetim fayl qolmasin). Best-effort.
        var oldImageUrl = product.ImageUrl;

        var newUrl = await _imageStorage.SaveAsync(marketId, product.Id, bytes, extension, cancellationToken);
        product.ImageUrl = newUrl;
        product.UpdatedAt = DateTime.UtcNow;

        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        // DB muvaffaqiyatli yangilangandan keyingina eski faylni o'chiramiz —
        // saqlash muvaffaqiyatsiz bo'lsa, eski rasm hamon ko'rsatiladi.
        if (!string.IsNullOrEmpty(oldImageUrl) && oldImageUrl != newUrl)
            await _imageStorage.DeleteAsync(oldImageUrl, cancellationToken);

        return MapToDto(product);
    }

    public async Task<ProductDto?> RemoveProductImageAsync(Guid productId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == productId && p.MarketId == marketId,
            cancellationToken);
        var product = products.FirstOrDefault();

        if (product is null)
            return null;

        var oldImageUrl = product.ImageUrl;
        product.ImageUrl = null;
        product.UpdatedAt = DateTime.UtcNow;

        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        if (!string.IsNullOrEmpty(oldImageUrl))
            await _imageStorage.DeleteAsync(oldImageUrl, cancellationToken);

        return MapToDto(product);
    }

    // canViewCost masks the confidential cost price for callers without
    // data.costPrice visibility (Sellers). The JSON read endpoints used to
    // return CostPrice unconditionally — leaking the shop's margin to every
    // Seller — while the Excel export already masked it. 0 == hidden; the
    // Flutter client gates the field on the same permission so a Seller never
    // sees the value either way.
    private static ProductDto MapToDto(Product product, bool canViewCost = true)
    {
        return new ProductDto(
            product.Id,
            product.Name,
            canViewCost ? product.CostPrice : 0m,
            product.SalePrice,
            product.MinSalePrice,
            product.Quantity,
            product.MinThreshold,
            (int)product.Unit,  // Cast enum to int
            product.GetUnitName(),  // Unit name (dona/kg/m)
            product.CategoryId,
            product.Category?.Name,
            product.IsTemporary,
            product.IsInStock(1),  // Simplified check
            product.IsLowStock,
            product.ImageUrl
        );
    }
}
