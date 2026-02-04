using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class ProductService : IProductService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppDbContext _context;

    public ProductService(IUnitOfWork unitOfWork, AppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _context = context;
    }

    public async Task<ProductDto?> GetProductByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id, cancellationToken);
        if (product is null)
            return null;

        return MapToDto(product);
    }

    public async Task<IEnumerable<ProductDto>> GetAllProductsAsync(CancellationToken cancellationToken = default)
    {
        var products = await _unitOfWork.Products.GetAllAsync(cancellationToken);
        return products.Select(MapToDto);
    }

    public async Task<IEnumerable<ProductDto>> GetLowStockProductsAsync(CancellationToken cancellationToken = default)
    {
        var products = await _unitOfWork.Products.FindAsync(
            p => p.Quantity <= p.MinThreshold,
            cancellationToken);

        return products.Select(MapToDto);
    }

    public async Task<ProductDto> CreateProductAsync(CreateProductDto request, Guid? sellerId, CancellationToken cancellationToken = default)
    {
        var product = new Product
        {
            Id = Guid.NewGuid(),
            Name = request.Name,
            IsTemporary = request.IsTemporary,
            CreatedBySellerId = sellerId,
            CostPrice = request.CostPrice,
            SalePrice = request.SalePrice,
            MinSalePrice = request.MinSalePrice,
            Quantity = request.Quantity,
            MinThreshold = request.MinThreshold
        };

        await _unitOfWork.Products.AddAsync(product, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(product);
    }

    public async Task<ProductDto?> UpdateProductAsync(UpdateProductDto request, CancellationToken cancellationToken = default)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(request.Id, cancellationToken);
        if (product is null)
            return null;

        product.Name = request.Name;
        product.CostPrice = request.CostPrice;
        product.SalePrice = request.SalePrice;
        product.MinSalePrice = request.MinSalePrice;
        product.MinThreshold = request.MinThreshold;

        _context.Entry(product).State = EntityState.Modified;
        _unitOfWork.Products.Update(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(product);
    }

    public async Task<bool> DeleteProductAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id, cancellationToken);
        if (product is null)
            return false;

        _unitOfWork.Products.Delete(product);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> UpdateStockAsync(Guid id, int quantityChange, CancellationToken cancellationToken = default)
    {
        var product = await _unitOfWork.Products.GetByIdAsync(id, cancellationToken);
        if (product is null)
            return false;

        // Check if new quantity would be negative
        if (product.Quantity + quantityChange < 0)
            throw new InvalidOperationException($"Insufficient stock. Current: {product.Quantity}, Change: {quantityChange}");

        product.Quantity += quantityChange;
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
            product.IsTemporary,
            product.CostPrice,
            product.SalePrice,
            product.MinSalePrice,
            product.Quantity,
            product.MinThreshold
        );
    }
}
