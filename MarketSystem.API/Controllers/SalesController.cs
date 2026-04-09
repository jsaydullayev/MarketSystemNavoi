using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "AllRoles")]
public class SalesController : ControllerBase
{
    private readonly ISaleService _saleService;
    private readonly ILogger<SalesController> _logger;

    public SalesController(ISaleService saleService, ILogger<SalesController> logger)
    {
        _saleService = saleService;
        _logger = logger;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<SaleDto>> GetSale(Guid id)
    {
        var sale = await _saleService.GetSaleByIdAsync(id);
        if (sale is null)
            return NotFound();

        return Ok(sale);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetAllSales()
    {
        var sales = await _saleService.GetAllSalesAsync();
        return Ok(sales);
    }

    [HttpGet("by-date")]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetSalesByDateRange([FromQuery] DateTime start, [FromQuery] DateTime end)
    {
        var sales = await _saleService.GetSalesByDateRangeAsync(start, end);
        return Ok(sales);
    }

    [HttpGet("my-drafts")]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetMyDraftSales()
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        var sales = await _saleService.GetDraftSalesBySellerAsync(sellerId);
        return Ok(sales);
    }

    [HttpGet("my-unfinished")]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetMyUnfinishedSales()
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        var sales = await _saleService.GetUnfinishedSalesBySellerAsync(sellerId);
        return Ok(sales);
    }

    [HttpPost]
    public async Task<ActionResult<SaleDto>> CreateSale([FromBody] CreateSaleDto request)
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        try
        {
            var sale = await _saleService.CreateSaleAsync(request, sellerId);
            return CreatedAtAction(nameof(GetSale), new { id = sale.Id }, sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPatch("{saleId}/customer")]
    public async Task<ActionResult<SaleDto>> UpdateSaleCustomer(Guid saleId, [FromBody] UpdateSaleCustomerDto request)
    {
        try
        {
            var sale = await _saleService.UpdateSaleCustomerAsync(saleId, request);
            if (sale is null)
                return NotFound();

            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/items")]
    public async Task<ActionResult<SaleItemDto>> AddSaleItem(Guid saleId, [FromBody] AddSaleItemDto request)
    {
        try
        {
            var item = await _saleService.AddSaleItemAsync(saleId, request);
            if (item is null)
                return NotFound();

            return Ok(item);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/items/remove")]
    public async Task<ActionResult<SaleItemDto>> RemoveSaleItem(Guid saleId, [FromBody] RemoveSaleItemDto request)
    {
        _logger.LogInformation("RemoveSaleItem called - SaleId: {SaleId}, SaleItemId: {SaleItemId}, Quantity: {Quantity}",
            saleId, request.SaleItemId, request.Quantity);

        try
        {
            var item = await _saleService.RemoveSaleItemAsync(saleId, request);
            if (item is null)
                return NotFound();

            return Ok(item);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/payments")]
    public async Task<ActionResult<PaymentDto>> AddPayment(Guid saleId, [FromBody] AddPaymentDto request)
    {
        try
        {
            var payment = await _saleService.AddPaymentAsync(saleId, request);
            if (payment is null)
                return NotFound();

            return Ok(payment);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Savdoni o'chirish (faqat Draft va Paid statusdagi savdolar uchun)
    /// </summary>
    [HttpDelete("{saleId}")]
    public async Task<ActionResult<SaleDto>> DeleteSale(Guid saleId)
    {
        _logger.LogInformation("DeleteSale called - Sale ID: {SaleId}", saleId);

        try
        {
            var sale = await _saleService.DeleteSaleAsync(saleId);
            if (sale is null)
                return NotFound();

            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Failed to delete sale {SaleId}: {Message}", saleId, ex.Message);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error deleting sale {SaleId}", saleId);
            return StatusCode(500, "Savdoni o'chirishda xatolik yuz berdi");
        }
    }

    [HttpPost("{saleId}/cancel")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<SaleDto>> CancelSale(Guid saleId, [FromBody] CancelSaleDto request)
    {
        try
        {
            _logger.LogInformation("CancelSale called - Sale ID: {SaleId}, Admin ID: {AdminId}", saleId, request.AdminId);

            var sale = await _saleService.CancelSaleAsync(saleId, request.AdminId);
            if (sale is null)
                return NotFound();

            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost("{saleId}/mark-debt")]
    public async Task<ActionResult<SaleDto>> MarkSaleAsDebt(Guid saleId)
    {
        try
        {
            _logger.LogInformation("MarkSaleAsDebt called - Sale ID: {SaleId}", saleId);

            var sale = await _saleService.MarkSaleAsDebtAsync(saleId);
            if (sale is null)
                return NotFound();

            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Update sale item price - requires role-based permissions
    /// - Open debts: All roles can edit
    /// - Closed debts: Only Owner and Admin can edit
    /// </summary>
    [HttpPatch("items/price")]
    public async Task<ActionResult<SaleItemDto>> UpdateSaleItemPrice([FromBody] UpdateSaleItemPriceDto request)
    {
        try
        {
            var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
                return Unauthorized();

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            if (string.IsNullOrEmpty(userRole))
                return Unauthorized();

            _logger.LogInformation("UpdateSaleItemPrice called by {UserId} with role {Role}", userId, userRole);

            var updatedItem = await _saleService.UpdateSaleItemPriceAsync(request, userId, userRole);

            if (updatedItem == null)
                return NotFound();

            return Ok(updatedItem);
        }
        catch (UnauthorizedAccessException ex)
        {
            _logger.LogWarning(ex, "Unauthorized access to UpdateSaleItemPrice");
            return StatusCode(403, ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation in UpdateSaleItemPrice");
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in UpdateSaleItemPrice");
            return StatusCode(500, "Xatolik yuz berdi");
        }
    }

    [HttpPost("{saleId}/return-item")]
    public async Task<ActionResult<SaleItemDto?>> ReturnSaleItem(Guid saleId, [FromBody] ReturnSaleItemRequest? request)
    {
        try
        {
            if (request == null)
            {
                _logger.LogWarning("ReturnSaleItem called with null request body for SaleId: {SaleId}", saleId);
                return BadRequest("Request body cannot be null");
            }

            _logger.LogInformation("ReturnSaleItem called - SaleId: {SaleId}, SaleItemId: {SaleItemId}, Quantity: {Quantity}",
                saleId, request.SaleItemId, request.Quantity);

            var result = await _saleService.ReturnSaleItemAsync(saleId, request);

            // result null bo'lishi mumkin (full return bo'lganda), lekin bu muvaffaqiyatli amal
            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error in ReturnSaleItem");
            return StatusCode(500, "Tovarni qaytarishda xatolik");
        }
    }

    [HttpGet("debtors")]
    public async Task<ActionResult<IEnumerable<DebtorDto>>> GetDebtors()
    {
        try
        {
            var debtors = await _saleService.GetDebtorsAsync();
            return Ok(debtors);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error getting debtors");
            return StatusCode(500, "Qarzdorlarni olishda xatolik");
        }
    }

    [HttpGet("export")]
    public async Task<IActionResult> ExportSalesToExcel([FromServices] MarketSystem.Application.Interfaces.IExcelService excelService)
    {
        try
        {
            var sales = await _saleService.GetAllSalesAsync();

            // Har bir sotuvning har bir tovari uchun alohida qator
            var exportData = sales.SelectMany(sale => sale.Items.Select(item => new
            {
                Sana = sale.CreatedAt.ToString("yyyy-MM-dd HH:mm"),
                Mijoz = sale.CustomerName ?? "Mijoz yo'q",
                Sotuvchi = sale.SellerName,
                Holat = sale.Status,
                Tovar_nomi = item.ProductName,
                Miqdor = FormatDecimal(item.Quantity),
                Birlik = item.Unit,
                Harid_narxi = FormatDecimal(item.CostPrice),
                Sotish_narxi = FormatDecimal(item.SalePrice),
                Jami_summa = FormatDecimal(item.TotalPrice),
                Foyda = FormatDecimal(item.Profit)
            })).OrderByDescending(x => x.Sana);

            var fileContent = excelService.GenerateExcel(exportData, "Sotuvlar");

            return File(
                fileContent,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                $"Sotuvlar_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting sales");
            return StatusCode(500, "Sotuvlarni eksport qilishda xatolik");
        }
    }

    /// <summary>
    /// Decimal sonni formatlash - butun sonlarda ".00" ni olib tashlaydi
    /// </summary>
    private static string FormatDecimal(decimal value)
    {
        return value.ToString("0.##");
    }
}
