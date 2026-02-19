using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AdminOrOwner")]
public class ProductCategoriesController : ControllerBase
{
    private readonly IProductCategoryService _categoryService;

    public ProductCategoriesController(IProductCategoryService categoryService)
    {
        _categoryService = categoryService;
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductCategoryDto>>> GetAllCategories(CancellationToken cancellationToken)
    {
        var categories = await _categoryService.GetAllCategoriesAsync(cancellationToken);
        return Ok(categories);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductCategoryDto>> GetCategoryById(int id, CancellationToken cancellationToken)
    {
        var category = await _categoryService.GetCategoryByIdAsync(id, cancellationToken);
        if (category is null)
            return NotFound();

        return Ok(category);
    }

    [HttpPost]
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
    public async Task<IActionResult> DeleteCategory(int id, CancellationToken cancellationToken)
    {
        var success = await _categoryService.DeleteCategoryAsync(id, cancellationToken);
        if (!success)
            return NotFound();

        return Ok(new { message = "Category muvaffaqiyatli o'chirildi" });
    }
}
