using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IProductCategoryService
{
    Task<IEnumerable<ProductCategoryDto>> GetAllCategoriesAsync(CancellationToken cancellationToken = default);
    Task<ProductCategoryDto?> GetCategoryByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<ProductCategoryDto> CreateCategoryAsync(CreateProductCategoryRequest request, CancellationToken cancellationToken = default);
    Task<ProductCategoryDto?> UpdateCategoryAsync(UpdateProductCategoryRequest request, CancellationToken cancellationToken = default);
    Task<bool> DeleteCategoryAsync(int id, CancellationToken cancellationToken = default);
}
