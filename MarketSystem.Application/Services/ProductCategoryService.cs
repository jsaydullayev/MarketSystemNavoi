using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class ProductCategoryService : IProductCategoryService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarketService;

    public ProductCategoryService(IUnitOfWork unitOfWork, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _currentMarketService = currentMarketService;
    }

    public async Task<IEnumerable<ProductCategoryDto>> GetAllCategoriesAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var categories = await _unitOfWork.ProductCategories
            .GetQueryable()
            .Include(c => c.Products)
            .Where(c => c.MarketId == marketId)
            .OrderBy(c => c.Name)
            .Select(c => new ProductCategoryDto(
                c.Id,
                c.Name,
                c.Description,
                c.IsActive,
                c.Products.Count(p => !p.IsDeleted)
            ))
            .ToListAsync(cancellationToken);

        return categories;
    }

    public async Task<ProductCategoryDto?> GetCategoryByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var category = await _unitOfWork.ProductCategories
            .GetQueryable()
            .Include(c => c.Products)
            .Where(c => c.Id == id && c.MarketId == marketId)
            .Select(c => new ProductCategoryDto(
                c.Id,
                c.Name,
                c.Description,
                c.IsActive,
                c.Products.Count(p => !p.IsDeleted)
            ))
            .FirstOrDefaultAsync(cancellationToken);

        return category;
    }

    public async Task<ProductCategoryDto> CreateCategoryAsync(CreateProductCategoryRequest request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var category = new ProductCategory
        {
            Name = request.Name,
            Description = request.Description,
            MarketId = marketId,
            IsActive = true
        };

        await _unitOfWork.ProductCategories.AddAsync(category, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new ProductCategoryDto(
            category.Id,
            category.Name,
            category.Description,
            category.IsActive,
            0
        );
    }

    public async Task<ProductCategoryDto?> UpdateCategoryAsync(UpdateProductCategoryRequest request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var category = await _unitOfWork.ProductCategories
            .GetQueryable()
            .Include(c => c.Products)
            .Where(c => c.Id == request.Id && c.MarketId == marketId)
            .FirstOrDefaultAsync(cancellationToken);

        if (category is null)
            return null;

        category.Name = request.Name;
        category.Description = request.Description;
        category.IsActive = request.IsActive;

        _unitOfWork.ProductCategories.Update(category);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return new ProductCategoryDto(
            category.Id,
            category.Name,
            category.Description,
            category.IsActive,
            category.Products.Count(p => !p.IsDeleted)
        );
    }

    public async Task<bool> DeleteCategoryAsync(int id, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        var category = await _unitOfWork.ProductCategories
            .GetQueryable()
            .Where(c => c.Id == id && c.MarketId == marketId)
            .FirstOrDefaultAsync(cancellationToken);

        if (category is null)
            return false;

        // ✅ Check if category has products
        var hasProducts = await _unitOfWork.Products
            .GetQueryable()
            .AnyAsync(p => p.CategoryId == id && !p.IsDeleted, cancellationToken);

        if (hasProducts)
        {
            throw new InvalidOperationException(
                "Kategoriyaga mahsulotlar bog'langan. Avval mahsulotlarni boshqa kategoriyaga o'tkazing yoki kategoriyani o'chirmang."
            );
        }

        // Soft delete
        category.IsDeleted = true;
        category.DeletedAt = DateTime.UtcNow;
        _unitOfWork.ProductCategories.Update(category);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return true;
    }
}
