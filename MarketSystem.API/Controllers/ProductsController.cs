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

    [HttpGet("export")]
    public async Task<IActionResult> ExportProductsToExcel(CancellationToken ct = default)
    {
        var products = await _productService.GetAllProductsAsync();

        var exportData = products.Select(p => new
        {
            ID = p.Id.ToString(),
            Nomi = p.Name,
            Kategoriya = p.CategoryName ?? "",
            Xarid_narxi = p.CostPrice,
            Sotuv_narxi = p.SalePrice,
            Minimal_narx = p.MinSalePrice,
            Miqdor = p.Quantity,
            Minimal_chegara = p.MinThreshold,
            Vaqtinchalik = p.IsTemporary ? "Ha" : "Yo'q"
        });

        var fileContent = _excelService.GenerateExcel(exportData, "Mahsulotlar");

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"Mahsulotlar_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
        );
    }

}
