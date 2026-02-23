using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class ProductService : IProductService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppDbContext _context;
    private readonly ICurrentMarketService _currentMarketService;

    public ProductService(IUnitOfWork unitOfWork, AppDbContext context, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
    }

    public async Task<ProductDto?> GetProductByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.Id == id && p.MarketId == marketId,
            cancellationToken);

        var product = products.FirstOrDefault();

        if (product is null)
            return null;

        return MapToDto(product);
    }

    public async Task<IEnumerable<ProductDto>> GetAllProductsAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId,
            cancellationToken,
            includeProperties: "Category");  // ✅ Include Category

        return products.Select(MapToDto);
    }

    public async Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId && p.Quantity <= p.MinThreshold,
            cancellationToken,
            includeProperties: "Category");  // ✅ Include Category

        return products.Select(MapToDto);
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.TryGetCurrentMarketId();

        if (!marketId.HasValue)
        {
            throw new UnauthorizedAccessException("Siz hali market yaratmagansiz. Iltimos, avval market yaratiling.");
        }

        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            IsTemporary = request.IsTemporary,
            CreatedBySellerId = sellerId,
            CostPrice = 0, // Zakup orqali belgilanadi
            SalePrice = request.SalePrice,
            MinSalePrice = request.MinSalePrice,
            Quantity = 0, // Zakup orqali belgilanadi
            MinThreshold = request.MinThreshold,
            Unit = (UnitType)request.Unit,  // ✅ NEW: Unit type
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

        product.Name = request.Name;
        // CostPrice va Quantity faqat Zakup orqali yangilanadi
        product.SalePrice = request.SalePrice;
        product.MinSalePrice = request.MinSalePrice;
        product.MinThreshold = request.MinThreshold;
        product.Unit = (UnitType)request.Unit;  // ✅ NEW: Update unit
        product.CategoryId = request.CategoryId;  // Category

        _context.Entry(product).State = EntityState.Modified;
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
        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static ProductDto MapToDto(Product product)
    {
        return new ProductDto(
            product.Id,
            product.Name,
            product.CostPrice,
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
            product.IsLowStock
        );
    }
}
