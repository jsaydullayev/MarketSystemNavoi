using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using System.Security.Claims;
using Microsoft.Extensions.Logging;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class SalesController : ControllerBase
{
    private readonly ISaleService _saleService;
    private readonly ILogger<SalesController> _logger;
    private readonly IReportService _reportService;
    private readonly IExcelService _excelService;

    public SalesController(ISaleService saleService, ILogger<SalesController> logger, IReportService reportService, IExcelService excelService)
    {
        _saleService = saleService;
        _logger = logger;
        _reportService = reportService;
        _excelService = excelService;
    }

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<SaleDto>> GetSale(Guid id, CancellationToken ct = default)
    {
        var sale = await _saleService.GetSaleByIdAsync(id);
        if (sale is null)
            return NotFound();

        return Ok(sale);
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<PagedResult<SaleDto>>> GetAllSales(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        CancellationToken ct = default)
    {
        // Returns a paged envelope: { items, page, size, total, totalPages }.
        // Defaults: page=1, size=50. Max size: 200 (clamped server-side).
        var result = await _saleService.GetSalesPagedAsync(page, size);
        return Ok(result);
    }

    [HttpGet("by-date")]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetSalesByDateRange([FromQuery] DateTime start, [FromQuery] DateTime end, CancellationToken ct = default)
    {
        if (start > end)
            return BadRequest(new { message = "Start date must be before end date" });

        var sales = await _saleService.GetSalesByDateRangeAsync(start, end);
        return Ok(sales);
    }

    [HttpGet("my-drafts")]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetMyDraftSales(CancellationToken ct = default)
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        var sales = await _saleService.GetDraftSalesBySellerAsync(sellerId);
        return Ok(sales);
    }

    [HttpGet("my-unfinished")]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<IEnumerable<SaleDto>>> GetMyUnfinishedSales(CancellationToken ct = default)
    {
        var sellerIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(sellerIdStr) || !Guid.TryParse(sellerIdStr, out var sellerId))
            return Unauthorized();

        var sales = await _saleService.GetUnfinishedSalesBySellerAsync(sellerId);
        return Ok(sales);
    }

    [HttpPost]
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<SaleDto>> CreateSale([FromBody] CreateSaleDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<SaleDto>> UpdateSaleCustomer(Guid saleId, [FromBody] UpdateSaleCustomerDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<SaleItemDto>> AddSaleItem(Guid saleId, [FromBody] AddSaleItemDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<SaleItemDto>> RemoveSaleItem(Guid saleId, [FromBody] RemoveSaleItemDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<PaymentDto>> AddPayment(Guid saleId, [FromBody] AddPaymentDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesDelete)]
    public async Task<ActionResult<SaleDto>> DeleteSale(Guid saleId, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesDelete)]
    public async Task<ActionResult<SaleDto>> CancelSale(Guid saleId, [FromBody] CancelSaleDto request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesEdit)]
    public async Task<ActionResult<SaleDto>> MarkSaleAsDebt(Guid saleId, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesEdit)]
    public async Task<ActionResult<SaleItemDto>> UpdateSaleItemPrice([FromBody] UpdateSaleItemPriceDto request, CancellationToken ct = default)
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

            if (!Guid.TryParse(request.SaleItemId, out var saleItemId))
                return BadRequest("Noto'g'ri saleItemId formati.");
            var updatedItem = await _saleService.UpdateSaleItemPriceAsync(saleItemId, request);

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
    [RequirePermission(PermissionKeys.SalesEdit)]
    public async Task<ActionResult<SaleItemDto?>> ReturnSaleItem(Guid saleId, [FromBody] ReturnSaleItemRequest? request, CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<IEnumerable<DebtorDto>>> GetDebtors(CancellationToken ct = default)
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
    [RequirePermission(PermissionKeys.SalesExport)]
    public async Task<IActionResult> ExportSalesToExcel(
        [FromQuery] string lang = "uz",
        CancellationToken ct = default)
    {
        try
        {
            var sales = await _saleService.GetAllSalesAsync();
            var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
            var orderedSales = sales.OrderByDescending(s => s.CreatedAt);
            var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
            var canSeeCost = role is "Owner" or "Admin";

            object exportData = isRu
                ? orderedSales.SelectMany(sale => sale.Items.Select(item => new
                {
                    Дата = sale.CreatedAt.ToString("yyyy-MM-dd HH:mm"),
                    Клиент = sale.CustomerName ?? "—",
                    Продавец = sale.SellerName,
                    Статус = sale.Status,
                    Товар = item.ProductName,
                    Количество = FormatDecimal(item.Quantity),
                    Ед_изм = item.Unit,
                    Цена_закупки = canSeeCost ? FormatDecimal(item.CostPrice) : "—",
                    Цена_продажи = FormatDecimal(item.SalePrice),
                    Сумма = FormatDecimal(item.TotalPrice),
                    Прибыль = canSeeCost ? FormatDecimal(item.Profit) : "—"
                })).Cast<object>()
                : orderedSales.SelectMany(sale => sale.Items.Select(item => new
                {
                    Sana = sale.CreatedAt.ToString("yyyy-MM-dd HH:mm"),
                    Mijoz = sale.CustomerName ?? "Mijoz yo'q",
                    Sotuvchi = sale.SellerName,
                    Holat = sale.Status,
                    Tovar_nomi = item.ProductName,
                    Miqdor = FormatDecimal(item.Quantity),
                    Birlik = item.Unit,
                    Harid_narxi = canSeeCost ? FormatDecimal(item.CostPrice) : "—",
                    Sotish_narxi = FormatDecimal(item.SalePrice),
                    Jami_summa = FormatDecimal(item.TotalPrice),
                    Foyda = canSeeCost ? FormatDecimal(item.Profit) : "—"
                })).Cast<object>();

            var sheetName = isRu ? "Продажи" : "Sotuvlar";
            var fileContent = _excelService.GenerateExcel((dynamic)exportData, sheetName);

            return File(
                fileContent,
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                $"{sheetName}_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting sales");
            return StatusCode(500, "Sotuvlarni eksport qilishda xatolik");
        }
    }

    [HttpGet("export-pdf")]
    [RequirePermission(PermissionKeys.SalesExport)]
    public async Task<IActionResult> ExportSalesToPdf([FromQuery] DateTime? startDate, [FromQuery] DateTime? endDate, [FromQuery] string lang = "uz", CancellationToken ct = default)
    {
        try
        {
            _logger.LogInformation("ExportSalesToPdf called - StartDate: {StartDate}, EndDate: {EndDate}",
                startDate, endDate);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            _logger.LogInformation("Exporting PDF for user role: {UserRole}", userRole ?? "Unknown");

            var pdfBytes = await _reportService.ExportSalesListToPdfAsync(startDate, endDate, userRole, lang);

            _logger.LogInformation("Sales PDF generated successfully");

            return File(
                pdfBytes,
                "application/pdf",
                $"Sotuvlar_{DateTime.Now:yyyyMMdd_HHmmss}.pdf"
            );
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Invalid operation during PDF export");
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting sales to PDF");
            return StatusCode(500, "Sotuvlarni PDF formatda eksport qilishda xatolik");
        }
    }

    /// <summary>
    /// Decimal sonni formatlash - butun sonlarda ".00" ni olib tashlaydi
    /// </summary>
    private static string FormatDecimal(decimal value)
    {
        return value.ToString("0.##");
    }

    [HttpPost("{saleId}/apply-credit")]
    [RequirePermission(PermissionKeys.SalesCreate)]
    public async Task<ActionResult<SaleDto>> ApplyCustomerCredit(Guid saleId, CancellationToken ct = default)
    {
        try
        {
            _logger.LogInformation("=== CONTROLLER: ApplyCustomerCredit called ===");
            _logger.LogInformation("Sale ID: {SaleId}", saleId);

            var sale = await _saleService.ApplyCustomerCreditAsync(saleId);
            if (sale is null)
                return NotFound();

            _logger.LogInformation("=== CONTROLLER: ApplyCustomerCredit SUCCESS ===");
            return Ok(sale);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogError(ex, "Error applying customer credit");
            return BadRequest(ex.Message);
        }
    }

    /// <summary>
    /// Generate and download PDF invoice for a sale
    /// </summary>
    [HttpGet("{id}/invoice")]
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<IActionResult> GetInvoice(Guid id, [FromQuery] string lang = "uz", CancellationToken ct = default)
    {
        try
        {
            _logger.LogInformation("GetInvoice called - Sale ID: {SaleId}", id);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var pdfBytes = await _reportService.GenerateInvoicePdfAsync(id, userRole, lang);

            var sale = await _saleService.GetSaleByIdAsync(id);
            var fileName = $"Faktura_{id}_{DateTime.Now:yyyyMMdd_HHmmss}.pdf";

            _logger.LogInformation("Invoice generated successfully for sale {SaleId}", id);

            return File(
                pdfBytes,
                "application/pdf",
                fileName
            );
        }
        catch (KeyNotFoundException ex)
        {
            _logger.LogWarning(ex, "Sale not found: {SaleId}", id);
            return NotFound(ex.Message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating invoice for sale {SaleId}", id);
            return StatusCode(500, "Faktura yaratishda xatolik yuz berdi");
        }
    }
}
