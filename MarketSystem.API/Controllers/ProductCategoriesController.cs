using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Helpers;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
public class ProductCategoriesController : ControllerBase
{
    private readonly IProductCategoryService _categoryService;

    public ProductCategoriesController(IProductCategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet]
    [Authorize] // All authenticated users can view categories
    public async Task<ActionResult<IEnumerable<ProductCategoryDto>>> GetAllCategories(CancellationToken cancellationToken)
    {
        // Debug logging
        var userRole = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        Console.WriteLine($"=== ProductCategories GetAllCategories ===");
        Console.WriteLine($"User Role: {userRole}");
        Console.WriteLine($"User ID: {userId}");
        Console.WriteLine($"IsAuthenticated: {User.Identity?.IsAuthenticated}");

        try
        {
            var categories = await _categoryService.GetAllCategoriesAsync(cancellationToken);

            Console.WriteLine($"Categories count: {categories.Count()}");

            foreach (var cat in categories)
            {
                Console.WriteLine($"  - ID: {cat.Id}, Name: {cat.Name}, Products: {cat.ProductCount}");
            }

            Console.WriteLine($"========================================");

            return Ok(categories);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"ERROR: {ex.Message}");
            Console.WriteLine($"STACK: {ex.StackTrace}");
            throw;
        }
    }

    [HttpGet("{id}")]
    [Authorize] // All authenticated users can view categories
    public async Task<ActionResult<ProductCategoryDto>> GetCategoryById(int id, CancellationToken cancellationToken)
    {
        var category = await _categoryService.GetCategoryByIdAsync(id, cancellationToken);
        if (category is null)
            return NotFound();

        return Ok(category);
    }

    [HttpPost]
    [Authorize(Policy = "AdminOrOwner")] // Only Admin and Owner can create categories
    public async Task<ActionResult<ProductCategoryDto>> CreateCategory(
        [FromBody] CreateProductCategoryRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var category = await _categoryService.CreateCategoryAsync(request, cancellationToken);
            return CreatedAtAction(nameof(GetCategoryById), new { id = category.Id }, category);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpPut]
    [Authorize(Policy = "AdminOrOwner")] // Only Admin and Owner can update categories
    public async Task<ActionResult<ProductCategoryDto>> UpdateCategory(
        [FromBody] UpdateProductCategoryRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            var category = await _categoryService.UpdateCategoryAsync(request, cancellationToken);
            if (category is null)
                return NotFound();

            return Ok(category);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOrOwner")] // Only Admin and Owner can delete categories
    public async Task<IActionResult> DeleteCategory(int id, CancellationToken cancellationToken)
    {
        var success = await _categoryService.DeleteCategoryAsync(id, cancellationToken);
        if (!success)
            return NotFound();

        return Ok(new { message = "Category muvaffaqiyatli o'chirildi" });
    }

    [HttpGet]
    [Authorize] // All authenticated users can export categories
    public async Task<IActionResult> ExportCategoriesToExcel(CancellationToken cancellationToken)
    {
        var categories = await _categoryService.GetAllCategoriesAsync(cancellationToken);

        var headers = new[] { "ID", "Nomi", "Ta'rifi", "Holati", "Mahsulotlar soni" };

        var csv = CsvHelper.GenerateCsv(
            categories,
            headers,
            cat => new[]
            {
                cat.Id.ToString(),
                cat.Name,
                cat.Description ?? "",
                cat.IsActive ? "Faol" : "Nofaol",
                cat.ProductCount.ToString()
            }
        );

        var content = CsvHelper.GenerateExcelCsv(csv);

        return File(
            content,
            "text/csv",
            $"kategoriyalar_{DateTime.Now:yyyyMMdd_HHmmss}.csv"
        );
    }
}
