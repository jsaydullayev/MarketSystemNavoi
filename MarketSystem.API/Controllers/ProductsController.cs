using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using MarketSystem.API.Helpers;
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
        catch (InvalidOperationException ex)
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
        catch (InvalidOperationException ex)
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

    [HttpGet]
    public async Task<IActionResult> ExportProductsToExcel()
    {
        var products = await _productService.GetAllProductsAsync();

        var headers = new[] { "ID", "Nomi", "Kategoriya", "Xarid narxi", "Sotuv narxi", "Min. narx", "Miqdor", "Min. chegara", "Vaqtinchalik" };

        var csv = CsvHelper.GenerateCsv(
            products,
            headers,
            p => new[]
            {
                p.Id.ToString(),
                p.Name,
                p.CategoryName ?? "",
                p.CostPrice.ToString("F2"),
                p.SalePrice.ToString("F2"),
                p.MinSalePrice.ToString("F2"),
                p.Quantity.ToString(),
                p.MinThreshold.ToString(),
                p.IsTemporary ? "Ha" : "Yo'q"
            }
        );

        var content = CsvHelper.GenerateExcelCsv(csv);

        return File(
            content,
            "text/csv",
            $"mahsulotlar_{DateTime.Now:yyyyMMdd_HHmmss}.csv"
        );
    }
}
