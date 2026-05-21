using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Constants;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Helpers;
using System.Security.Claims;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;
    private readonly IExcelService _excelService;

    public ProductsController(IProductService productService, IExcelService excelService)
    {
        _productService = productService;
        _excelService = excelService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(Guid id, CancellationToken ct = default)
    {
        var product = await _productService.GetProductByIdAsync(id);
        if (product is null)
            return NotFound();

        return Ok(product);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAllProducts(CancellationToken ct = default)
    {
        var products = await _productService.GetAllProductsAsync();
        return Ok(products);
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<ProductDto>>> GetAllProductsPaged(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        CancellationToken ct = default)
    {
        var result = await _productService.GetAllProductsPagedAsync(page, size);
        return Ok(result);
    }

    [HttpGet("low-stock")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetLowStockProducts(CancellationToken ct = default)
    {
        var products = await _productService.GetLowStockProductsAsync();
        return Ok(products);
    }

    /// <summary>
    /// Barcha o'lchov birliklarini olish (dona, kg, m)
    /// </summary>
    [HttpGet("units")]
    [AllowAnonymous]
    public ActionResult<List<UnitInfo>> GetUnits()
    {
        return Ok(UnitConstants.AllUnits);
    }

    [HttpPost]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<ProductDto>> CreateProduct([FromBody] CreateProductDto request, CancellationToken ct = default)
    {
        var sellerId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var sellerGuid = !string.IsNullOrEmpty(sellerId) && Guid.TryParse(sellerId, out var parsed)
            ? parsed : (Guid?)null;

        try
        {
            var product = await _productService.CreateProductAsync(request, sellerGuid);
            return CreatedAtAction(nameof(GetProduct), new { id = product.Id }, product);
        }
        catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<ProductDto>> UpdateProduct(Guid id, [FromBody] UpdateProductDto request, CancellationToken ct = default)
    {
        if (id != request.Id)
            return BadRequest("ID mismatch");

        try
        {
            var product = await _productService.UpdateProductAsync(request);
            if (product is null)
                return NotFound();

            return Ok(product);
        }
        catch (Exception ex) when (ex is InvalidOperationException || ex is ArgumentException)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> DeleteProduct(Guid id, CancellationToken ct = default)
    {
        var result = await _productService.DeleteProductAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    /// <summary>
    /// Exports all products as an .xlsx workbook. Column headers (and the
    /// "Ha"/"Yo'q" boolean labels) come back in the caller's language —
    /// pass `lang=ru` for Russian, anything else (or omit) yields Uzbek.
    /// Returns every product the caller can see — same paging-disabled
    /// fetch used by the in-app list. No filtering server-side; the user
    /// can sort / filter in Excel if needed.
    /// </summary>
    [HttpGet("export")]
    public async Task<IActionResult> ExportProductsToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        var products = await _productService.GetAllProductsAsync();
        var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
        var canSeeCost = role is "Owner" or "Admin";

        // Anonymous types pick up the field names as Excel column headers.
        // We need two separate shapes for uz vs ru because anonymous-type
        // member names are compile-time fixed.
        object exportData = isRu
            ? products.Select(p => new
            {
                ID = p.Id.ToString(),
                Название = p.Name,
                Категория = p.CategoryName ?? "",
                Цена_закупки = canSeeCost ? p.CostPrice.ToString("G29") : "—",
                Цена_продажи = p.SalePrice,
                Минимальная_цена = p.MinSalePrice,
                Количество = p.Quantity,
                Минимальный_остаток = p.MinThreshold,
                Временный = p.IsTemporary ? "Да" : "Нет"
            }).Cast<object>()
            : products.Select(p => new
            {
                ID = p.Id.ToString(),
                Nomi = p.Name,
                Kategoriya = p.CategoryName ?? "",
                Xarid_narxi = canSeeCost ? p.CostPrice.ToString("G29") : "—",
                Sotuv_narxi = p.SalePrice,
                Minimal_narx = p.MinSalePrice,
                Miqdor = p.Quantity,
                Minimal_chegara = p.MinThreshold,
                Vaqtinchalik = p.IsTemporary ? "Ha" : "Yo'q"
            }).Cast<object>();

        var sheetName = isRu ? "Товары" : "Mahsulotlar";
        var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"{sheetName}_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
        );
    }

}
