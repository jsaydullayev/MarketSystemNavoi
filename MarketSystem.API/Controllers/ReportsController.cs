using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using OfficeOpenXml;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AdminOrOwner")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportsController> _logger;

    public ReportsController(IReportService reportService, ILogger<ReportsController> logger)
    {
        _reportService = reportService;
        _logger = logger;
    }

    /// <summary>
    /// Get daily sales report
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<DailyReportDto>> GetDailyReport([FromQuery] DateTime date)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var report = await _reportService.GetDailyReportAsync(utcDate, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Get daily sale items - detailed list of products sold on specific date
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<DailySaleItemsResponseDto>> GetDailySaleItems([FromQuery] DateTime date)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var saleItems = await _reportService.GetDailySaleItemsAsync(utcDate, userRole);
        return Ok(saleItems);
    }

    /// <summary>
    /// Get sales report for a period
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PeriodReportDto>> GetPeriodReport(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        if (start > end)
            return BadRequest("Start date cannot be after end date");

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var report = await _reportService.GetPeriodReportAsync(request, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Export sales report to Excel
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ExportToExcel(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var excelBytes = await _reportService.ExportToExcelAsync(request);

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"report_{start:yyyyMMdd}_{end:yyyyMMdd}.xlsx"
        );
    }

    /// <summary>
    /// Get comprehensive report including seller stats and inventory
    /// Seller reports are only visible to Owner role
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<ComprehensiveReportDto>> GetComprehensiveReport([FromQuery] DateTime date)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var report = await _reportService.GetComprehensiveReportAsync(utcDate, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Export comprehensive report to Excel
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ExportComprehensiveToExcel([FromQuery] DateTime date)
    {
        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var excelBytes = await _reportService.ExportComprehensiveToExcelAsync(utcDate);

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"comprehensive_report_{date:yyyyMMdd}.xlsx"
        );
    }

    // New endpoints for role-based access control

    /// <summary>
    /// Get profit summary - Owner only
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<ProfitSummaryDto>> GetProfitSummary()
    {
        var summary = await _reportService.GetProfitSummaryAsync();
        return Ok(summary);
    }

    /// <summary>
    /// Get cash balance - Owner only
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<CashBalanceDto>> GetCashBalance()
    {
        var balance = await _reportService.GetCashBalanceAsync();
        return Ok(balance);
    }

    /// <summary>
    /// Get daily sales list with role-based filtering
    /// - Owner: sees all sales with profit
    /// - Admin: sees all sales without profit
    /// - Seller: sees only their own sales without profit
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<ActionResult<DailySalesListDto>> GetDailySalesList([FromQuery] DateTime date)
    {
        // Get user role and ID from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

        // FIX: The date from query parameter is in local time (browser sends "2026-02-19")
        // We need to convert it to UTC date range.
        // Example: User in UTC+5 creates sale at 10:00 local time -> stored as 05:00 UTC
        // When user queries "2026-02-19", they want to see that sale.
        // The query date "2026-02-19 00:00:00" (local) = "2026-02-18 19:00:00" (UTC)
        // So we should query from that UTC time to +24 hours.

        // Actually, let's use a simpler approach:
        // The date parameter comes as unspecified kind DateTime from the query string.
        // ASP.NET binds "2026-02-19" as DateTime with Kind = Unspecified.
        // We treat it as UTC for the query.
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
        return Ok(salesList);
    }

    /// <summary>
    /// Export all sales to Excel with detailed formatting
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportSalesToExcel(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Exporting sales to Excel. StartDate: {StartDate}, EndDate: {EndDate}",
                startDate, endDate);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

            using (var package = new ExcelPackage())
            {
                var worksheet = package.Workbook.Worksheets.Add("Sotuvlar Hisoboti");

                // Headerlar
                worksheet.Cells[1, 1].Value = "ID";
                worksheet.Cells[1, 2].Value = "Sana";
                worksheet.Cells[1, 3].Value = "Sotuvchi";
                worksheet.Cells[1, 4].Value = "Mijoz";
                worksheet.Cells[1, 5].Value = "Jami summa";
                worksheet.Cells[1, 6].Value = "To'lov turi";
                worksheet.Cells[1, 7].Value = "Holat";
                worksheet.Cells[1, 8].Value = "Foyda";

                // Header styling
                using (var range = worksheet.Cells[1, 1, 1, 8])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                    range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                }

                // Ma'lumotlarni olish
                DateTime queryStartDate = startDate ?? DateTime.Today.AddDays(-30);
                DateTime queryEndDate = endDate ?? DateTime.Today;

                var utcStart = DateTime.SpecifyKind(queryStartDate.Date, DateTimeKind.Utc);
                var utcEnd = DateTime.SpecifyKind(queryEndDate.Date.AddDays(1).AddTicks(-1), DateTimeKind.Utc);

                var salesList = await _reportService.GetDailySalesListAsync(utcStart, userRole, userId);

                // Filter by date range if specified
                var filteredSales = salesList.Sales
                    .Where(s => s.CreatedAt >= utcStart && s.CreatedAt <= utcEnd)
                    .ToList();

                // Ma'lumotlarni yozish
                int row = 2;
                decimal totalAmount = 0;
                decimal totalProfit = 0;

                foreach (var sale in filteredSales)
                {
                    worksheet.Cells[row, 1].Value = sale.Id;
                    worksheet.Cells[row, 2].Value = sale.CreatedAt.ToString("yyyy-MM-dd HH:mm");
                    worksheet.Cells[row, 3].Value = sale.SellerName ?? "";
                    worksheet.Cells[row, 4].Value = sale.CustomerName ?? "";
                    worksheet.Cells[row, 5].Value = sale.TotalAmount;
                    worksheet.Cells[row, 6].Value = sale.PaymentType;
                    worksheet.Cells[row, 7].Value = GetStatusText(sale.Status);

                    // Foyda faqat Owner uchun
                    if (userRole == "Owner" && sale.Profit.HasValue)
                    {
                        worksheet.Cells[row, 8].Value = sale.Profit.Value;
                        totalProfit += sale.Profit.Value;
                    }
                    else if (userRole == "Owner")
                    {
                        worksheet.Cells[row, 8].Value = 0;
                    }

                    // Holat bo'yicha rang
                    var statusCell = worksheet.Cells[row, 7];
                    switch (sale.Status.ToLower())
                    {
                        case "paid":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.Green);
                            break;
                        case "debt":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.Red);
                            break;
                        case "cancelled":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.Gray);
                            break;
                        case "draft":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.Orange);
                            break;
                    }

                    totalAmount += sale.TotalAmount;

                    row++;
                }

                // Columnlarni avto-width
                worksheet.Cells[worksheet.Dimension.Address].AutoFitColumns();

                // Filter qo'shish
                worksheet.Cells[1, 1, 1, 8].AutoFilter = true;

                // Border qo'shish
                using (var range = worksheet.Cells[1, 1, row - 1, 8])
                {
                    range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                }

                // Footer qo'shish
                int footerRow = row + 1;
                worksheet.Cells[footerRow, 1].Value = "Jami:";
                worksheet.Cells[footerRow, 1].Style.Font.Bold = true;
                worksheet.Cells[footerRow, 5].Value = totalAmount;
                worksheet.Cells[footerRow, 5].Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    worksheet.Cells[footerRow, 8].Value = totalProfit;
                    worksheet.Cells[footerRow, 8].Style.Font.Bold = true;
                }

                // Faylni qaytarish
                var stream = new MemoryStream(package.GetAsByteArray());
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var fileName = $"sotuvlar_hisoboti_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";

                _logger.LogInformation("Successfully exported {Count} sales to Excel", filteredSales.Count);
                return File(stream, contentType, fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting sales to Excel");
            return StatusCode(500, new { message = "Xatolik yuz berdi", error = ex.Message });
        }
    }

    private string GetStatusText(string status)
    {
        return status switch
        {
            "Draft" => "Qoralama",
            "Paid" => "To'langan",
            "Debt" => "Qarzli",
            "Closed" => "Yopilgan",
            "Cancelled" => "Bekor qilingan",
            _ => status
        };
    }

    /// <summary>
    /// Export comprehensive report to Excel - includes sales, products, categories, customers
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportComprehensiveReportToExcel(
        [FromQuery] DateTime? date = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Exporting comprehensive report to Excel. Date: {Date}", date);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

            DateTime reportDate = date ?? DateTime.Today;
            var utcDate = DateTime.SpecifyKind(reportDate.Date, DateTimeKind.Utc);

            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            using (var package = new ExcelPackage())
            {
                // Sheet 1: Sales Summary
                var salesWorksheet = package.Workbook.Worksheets.Add("Sotuvlar");
                salesWorksheet.Cells[1, 1].Value = "Sana";
                salesWorksheet.Cells[1, 2].Value = "Sotuvlar soni";
                salesWorksheet.Cells[1, 3].Value = "Jami savdo";
                salesWorksheet.Cells[1, 4].Value = "Foyda (Owner only)";

                // Style sales header
                using (var range = salesWorksheet.Cells[1, 1, 1, 4])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                    range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                }

                // Get sales data
                var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
                int salesRow = 2;
                decimal totalSalesAmount = 0;
                decimal totalProfit = 0;

                foreach (var sale in salesList.Sales.Take(100)) // Last 100 sales
                {
                    salesWorksheet.Cells[salesRow, 1].Value = sale.CreatedAt.ToString("yyyy-MM-dd");
                    salesWorksheet.Cells[salesRow, 2].Value = 1;
                    salesWorksheet.Cells[salesRow, 3].Value = sale.TotalAmount;
                    if (userRole == "Owner" && sale.Profit.HasValue)
                    {
                        salesWorksheet.Cells[salesRow, 4].Value = sale.Profit.Value;
                        totalProfit += sale.Profit.Value;
                    }
                    totalSalesAmount += sale.TotalAmount;
                    salesRow++;
                }

                // Sales totals
                salesWorksheet.Cells[salesRow, 1].Value = "Jami:";
                salesWorksheet.Cells[salesRow, 1].Style.Font.Bold = true;
                salesWorksheet.Cells[salesRow, 3].Value = totalSalesAmount;
                salesWorksheet.Cells[salesRow, 3].Style.Font.Bold = true;
                if (userRole == "Owner")
                {
                    salesWorksheet.Cells[salesRow, 4].Value = totalProfit;
                    salesWorksheet.Cells[salesRow, 4].Style.Font.Bold = true;
                }

                salesWorksheet.Cells[salesWorksheet.Dimension.Address].AutoFitColumns();

                // Sheet 2: Summary Statistics
                var summaryWorksheet = package.Workbook.Worksheets.Add("Umumiy Hisobot");
                summaryWorksheet.Cells[1, 1].Value = "Hisobot sanasi:";
                summaryWorksheet.Cells[1, 2].Value = reportDate.ToString("yyyy-MM-dd");
                summaryWorksheet.Cells[1, 1].Style.Font.Bold = true;
                summaryWorksheet.Cells[1, 1].Style.Font.Size = 14;

                summaryWorksheet.Cells[3, 1].Value = "Sotuvlar soni:";
                summaryWorksheet.Cells[3, 2].Value = salesList.Sales.Count;
                summaryWorksheet.Cells[3, 2].Style.Font.Bold = true;

                summaryWorksheet.Cells[4, 1].Value = "Jami savdo:";
                summaryWorksheet.Cells[4, 2].Value = totalSalesAmount;
                summaryWorksheet.Cells[4, 2].Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    summaryWorksheet.Cells[5, 1].Value = "Jami foyda:";
                    summaryWorksheet.Cells[5, 2].Value = totalProfit;
                    summaryWorksheet.Cells[5, 2].Style.Font.Bold = true;
                    summaryWorksheet.Cells[5, 2].Style.Font.Color.SetColor(System.Drawing.Color.Green);
                }

                // Sheet 3: Top Products (if available)
                var productsWorksheet = package.Workbook.Worksheets.Add("Mahsulotlar");
                productsWorksheet.Cells[1, 1].Value = "Mahsulot ro'yxati";
                productsWorksheet.Cells[1, 1, 1, 1].Merge = true;
                productsWorksheet.Cells[1, 1].Style.Font.Bold = true;
                productsWorksheet.Cells[1, 1].Style.Font.Size = 14;
                productsWorksheet.Cells[1, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                productsWorksheet.Cells[3, 1].Value = "Note: Batafsil ma'lumot uchun Mahsulotlar bo'limiga o'ting";
                productsWorksheet.Cells[3, 1].Style.Font.Italic = true;
                productsWorksheet.Cells[3, 1].Style.Font.Color.SetColor(System.Drawing.Color.Gray);

                // Auto-fit all sheets
                foreach (var sheet in package.Workbook.Worksheets)
                {
                    sheet.Cells[sheet.Dimension.Address].AutoFitColumns();
                }

                // Return file
                var stream = new MemoryStream(package.GetAsByteArray());
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var fileName = $"hisobotlar_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";

                _logger.LogInformation("Successfully exported comprehensive report to Excel");
                return File(stream, contentType, fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting comprehensive report to Excel");
            return StatusCode(500, new { message = "Xatolik yuz berdi", error = ex.Message });
        }
    }

    /// <summary>
    /// Get monthly category sales report
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<ActionResult<MonthlyCategorySalesResponseDto>> GetMonthlyCategorySales([FromQuery] DateTime date, CancellationToken cancellationToken = default)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        
        var report = await _reportService.GetMonthlyCategorySalesAsync(utcDate, userRole, cancellationToken);
        return Ok(report);
    }

    /// <summary>
    /// Export daily report to PDF
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportDailyReportToPdf([FromQuery] DateTime date)
    {
        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var pdfBytes = await _reportService.ExportDailyReportToPdfAsync(utcDate, userRole);

        return File(
            pdfBytes,
            "application/pdf",
            $"daily_report_{date:yyyyMMdd}.pdf"
        );
    }

    /// <summary>
    /// Export period report to PDF
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportPeriodReportToPdf(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var pdfBytes = await _reportService.ExportPeriodReportToPdfAsync(request, userRole);

        return File(
            pdfBytes,
            "application/pdf",
            $"period_report_{start:yyyyMMdd}_{end:yyyyMMdd}.pdf"
        );
    }

    /// <summary>
    /// Export comprehensive report to PDF
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportComprehensiveReportToPdf([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var pdfBytes = await _reportService.ExportComprehensiveReportToPdfAsync(utcDate, userRole);

        return File(
            pdfBytes,
            "application/pdf",
            $"comprehensive_report_{date:yyyyMMdd}.pdf"
        );
    }
}

