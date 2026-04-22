using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Constants;
using MarketSystem.Domain.Interfaces;
using MarketSystem.API.Helpers;
using MarketSystem.Infrastructure.Data;
using System.Security.Claims;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class ProductsController : ControllerBase
{
    private readonly IProductService _productService;

    public ProductsController(IProductService productService)
    {
        _productService = productService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ProductDto>> GetProduct(Guid id)
    {
        var product = await _productService.GetProductByIdAsync(id);
        if (product is null)
            return NotFound();

        return Ok(product);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetAllProducts()
    {
        var products = await _productService.GetAllProductsAsync();
        return Ok(products);
    }

    [HttpGet("low-stock")]
    public async Task<ActionResult<IEnumerable<ProductDto>>> GetLowStockProducts()
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
    public async Task<ActionResult<ProductDto>> CreateProduct([FromBody] CreateProductDto request)
    {
        var sellerId = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var sellerGuid = string.IsNullOrEmpty(sellerId) ? (Guid?)null : Guid.Parse(sellerId);

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
    public async Task<ActionResult<ProductDto>> UpdateProduct(Guid id, [FromBody] UpdateProductDto request)
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
    public async Task<IActionResult> DeleteProduct(Guid id)
    {
        var result = await _productService.DeleteProductAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    [HttpGet("export")]
    public async Task<IActionResult> ExportProductsToExcel([FromServices] MarketSystem.Application.Interfaces.IExcelService excelService)
    {
        var products = await _productService.GetAllProductsAsync();

        // Forma dagi ma'lumotlarni sodda va tushunarli qilish uchun yangi ro'yxat shakllantiramiz
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

        var fileContent = excelService.GenerateExcel(exportData, "Mahsulotlar");

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"Mahsulotlar_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
        );
    }

    /// <summary>
    /// Debug endpoint - tekshirish uchun
    /// </summary>
    [HttpGet("debug")]
    public async Task<IActionResult> DebugProducts([FromServices] AppDbContext dbContext)
    {
        var marketId = User.FindFirst("MarketId")?.Value;
        Console.WriteLine($"[DEBUG] User's MarketId: {marketId}");

        // Direct database query using raw SQL
        var rawProducts = await dbContext.Products
            .Where(p => p.MarketId == int.Parse(marketId ?? "0"))
            .Select(p => new
            {
                p.Id,
                p.Name,
                p.Quantity,
                p.Unit,
                p.CostPrice,
                p.SalePrice
            })
            .Take(5)
            .ToListAsync();

        Console.WriteLine($"[DEBUG] Raw SQL query result count: {rawProducts.Count}");

        foreach (var p in rawProducts)
        {
            Console.WriteLine($"[DEBUG] Product: {p.Name}, Quantity: {p.Quantity}, Unit: {p.Unit}");
        }

        // Get products via service (regular flow)
        var serviceProducts = await _productService.GetAllProductsAsync();

        return Ok(new
        {
            marketId,
            rawQueryCount = rawProducts.Count,
            rawProducts,
            serviceQueryCount = serviceProducts.Count(),
            serviceProducts = serviceProducts.Take(5).Select(p => new
            {
                id = p.Id,
                name = p.Name,
                quantity = p.Quantity,
                unit = p.Unit,
                unitName = p.UnitName
            })
        });
    }

}
