using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class ProductCategoriesController : ControllerBase
{
    private readonly IProductCategoryService _categoryService;
    private readonly IExcelService _excelService;
    private readonly ITashkentClock _clock;

    public ProductCategoriesController(IProductCategoryService categoryService, IExcelService excelService, ITashkentClock clock)
    {
        _categoryService = categoryService;
        _excelService = excelService;
        _clock = clock;
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.CategoriesAccess)]
    public async Task<ActionResult<IEnumerable<ProductCategoryDto>>> GetAllCategories(CancellationToken cancellationToken)
    {
        var categories = await _categoryService.GetAllCategoriesAsync(cancellationToken);
        return Ok(categories);
    }

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.CategoriesAccess)]
    public async Task<ActionResult<ProductCategoryDto>> GetCategoryById(int id, CancellationToken cancellationToken)
    {
        var category = await _categoryService.GetCategoryByIdAsync(id, cancellationToken);
        if (category is null)
            return NotFound();

        return Ok(category);
    }

    [HttpPost]
    [RequirePermission(PermissionKeys.CategoriesManage)]
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
    [RequirePermission(PermissionKeys.CategoriesManage)]
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
    [RequirePermission(PermissionKeys.CategoriesManage)]
    public async Task<IActionResult> DeleteCategory(int id, CancellationToken cancellationToken)
    {
        var success = await _categoryService.DeleteCategoryAsync(id, cancellationToken);
        if (!success)
            return NotFound();

        return Ok(new { message = "Category muvaffaqiyatli o'chirildi" });
    }

    /// <summary>
    /// Exports categories as a real .xlsx workbook (previously emitted CSV
    /// despite the "ToExcel" name). Column headers come back in the caller's
    /// language — pass `lang=ru` for Russian, anything else yields Uzbek.
    /// </summary>
    [HttpGet]
    [RequirePermission(PermissionKeys.CategoriesAccess)]
    public async Task<IActionResult> ExportCategoriesToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken cancellationToken = default)
    {
        var categories = await _categoryService.GetAllCategoriesAsync(cancellationToken);
        var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);

        // Anonymous-type member names become the Excel column headers, so we
        // need two shapes for uz vs ru.
        object exportData = isRu
            ? categories.Select(c => new
            {
                ID = c.Id.ToString(),
                Название = c.Name,
                Описание = c.Description ?? "",
                Значок = c.Icon ?? "",
                Статус = c.IsActive ? "Активна" : "Неактивна",
                Количество_товаров = c.ProductCount
            }).Cast<object>()
            : categories.Select(c => new
            {
                ID = c.Id.ToString(),
                Nomi = c.Name,
                Tavsifi = c.Description ?? "",
                Belgi = c.Icon ?? "",
                Holati = c.IsActive ? "Faol" : "Nofaol",
                Mahsulotlar_soni = c.ProductCount
            }).Cast<object>();

        var sheetName = isRu ? "Категории" : "Kategoriyalar";
        var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{sheetName}_{_clock.NowLocal:yyyyMMdd_HHmmss}.xlsx"
        );
    }
}
