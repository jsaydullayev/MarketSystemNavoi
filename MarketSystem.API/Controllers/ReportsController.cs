using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using OfficeOpenXml;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
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
    [HttpGet("daily")]
    public async Task<ActionResult<DailyReportDto>> GetDailyReport([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Service handles UTC conversion internally via GetUtcDateRange
        var report = await _reportService.GetDailyReportAsync(date, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Get daily sale items - detailed list of products sold on specific date
    /// </summary>
    [HttpGet("daily-items")]
    public async Task<ActionResult<DailySaleItemsResponseDto>> GetDailySaleItems([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Use the service's GetUtcDateRange for proper UTC conversion
        var saleItems = await _reportService.GetDailySaleItemsAsync(date, userRole);
        return Ok(saleItems);
    }

    /// <summary>
    /// Get sales report for a period
    /// </summary>
    [HttpGet("period")]
    public async Task<ActionResult<PeriodReportDto>> GetPeriodReport(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        if (start > end)
            return BadRequest("Start date cannot be after end date");

        // Convert to UTC - treat the input dates as UTC
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var report = await _reportService.GetPeriodReportAsync(request, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Export sales report to Excel
    /// </summary>
    [HttpGet("period/export")]
    public async Task<IActionResult> ExportToExcel(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

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
    [HttpGet("comprehensive")]
    public async Task<ActionResult<ComprehensiveReportDto>> GetComprehensiveReport([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Service handles UTC conversion internally via GetUtcDateRange
        var report = await _reportService.GetComprehensiveReportAsync(date, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Export comprehensive report to Excel
    /// </summary>
    [HttpGet("comprehensive/export")]
    public async Task<IActionResult> ExportComprehensiveToExcel([FromQuery] DateTime date)
    {
        // Service handles UTC conversion internally via GetUtcDateRange
        var excelBytes = await _reportService.ExportComprehensiveToExcelAsync(date);

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
    [HttpGet("profit-summary")]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<ProfitSummaryDto>> GetProfitSummary()
    {
        var summary = await _reportService.GetProfitSummaryAsync();
        return Ok(summary);
    }

    /// <summary>
    /// Get cash balance - Owner only
    /// </summary>
    [HttpGet("cash-balance")]
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
    [HttpGet("daily-sales-list")]
    [Authorize(Policy = "AllRoles")]
    public async Task<ActionResult<DailySalesListDto>> GetDailySalesList([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

        // Service handles UTC conversion internally via GetUtcDateRange
        var salesList = await _reportService.GetDailySalesListAsync(date, userRole, userId);
        return Ok(salesList);
    }

    /// <summary>
    /// Export all sales to Excel with detailed formatting
    /// </summary>
    [HttpGet("sales/export")]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportSalesToExcel(
        [FromQuery] DateTime? startDate = null,
        [FromQuery] DateTime? endDate = null,
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("=== EXPORT SALES TO EXCEL START ===");
            _logger.LogInformation("StartDate: {StartDate}, EndDate: {EndDate}",
                startDate, endDate);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

            DateTime queryStartDate = startDate ?? DateTime.UtcNow.AddDays(-30);
            DateTime queryEndDate = endDate ?? DateTime.UtcNow;

            var utcStart = DateTime.SpecifyKind(queryStartDate.Date, DateTimeKind.Utc);
            var utcEnd = DateTime.SpecifyKind(queryEndDate.Date, DateTimeKind.Utc);

            _logger.LogInformation("Fetching sales list for period: {Start} to {End}", utcStart, utcEnd);
            var salesList = await _reportService.GetDailySalesListAsync(utcStart, userRole, userId);
            _logger.LogInformation("Got {Count} sales from service", salesList.Sales.Count);

            // Filter by date range if specified
            var filteredSales = salesList.Sales
                .Where(s => s.CreatedAt >= utcStart && s.CreatedAt < utcEnd.AddDays(1))
                .ToList();
            _logger.LogInformation("Filtered to {Count} sales within date range", filteredSales.Count);

            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            using (var package = new ExcelPackage())
            {
                // ============================================
                // SHEET 1: KUNLIK UMUMIY HISOBOT (Summary)
                // ============================================
                var summarySheet = package.Workbook.Worksheets.Add("Kunlik Hisobot");

                // Report title
                summarySheet.Cells[1, 1].Value = "SOTUVLAR HISOBOTI";
                summarySheet.Cells[1, 1, 1, 6].Merge = true;
                summarySheet.Cells[1, 1].Style.Font.Bold = true;
                summarySheet.Cells[1, 1].Style.Font.Size = 16;
                summarySheet.Cells[1, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                // Report period
                summarySheet.Cells[2, 1].Value = $"Sana: {queryStartDate:yyyy-MM-dd} - {queryEndDate:yyyy-MM-dd}";
                summarySheet.Cells[2, 1, 2, 6].Merge = true;
                summarySheet.Cells[2, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                // Summary calculations
                decimal totalSales = salesList.TotalSales;
                decimal totalPaid = salesList.TotalPaidSales;
                decimal totalDebt = salesList.TotalDebtSales;
                decimal totalProfit = salesList.SummaryProfit ?? 0;

                // Calculate payment breakdown
                decimal cashPayments = 0;
                decimal terminalPayments = 0;
                decimal clickPayments = 0;
                decimal transferPayments = 0;
                decimal refunds = 0;

                foreach (var sale in filteredSales)
                {
                    // Use payment type from the sale
                    switch (sale.PaymentType?.ToLower())
                    {
                        case "cash":
                            cashPayments += sale.TotalAmount;
                            break;
                        case "terminal":
                            terminalPayments += sale.TotalAmount;
                            break;
                        case "click":
                            clickPayments += sale.TotalAmount;
                            break;
                        case "transfer":
                            transferPayments += sale.TotalAmount;
                            break;
                        case "qaytarilgan":
                        case "refund":
                            refunds += Math.Abs(sale.TotalAmount);
                            break;
                    }
                }

                // Summary table
                int row = 4;
                summarySheet.Cells[row, 1].Value = "KO'RSATGICH";
                summarySheet.Cells[row, 2].Value = "SUMMA (so'm)";
                summarySheet.Cells[row, 1, row, 2].Style.Font.Bold = true;
                summarySheet.Cells[row, 1, row, 2].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                summarySheet.Cells[row, 1, row, 2].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                summarySheet.Cells[row, 1, row, 2].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                row++;
                summarySheet.Cells[row, 1].Value = "Jami savdo (Total)";
                summarySheet.Cells[row, 2].Value = totalSales;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "To'langan (Naqd)";
                summarySheet.Cells[row, 2].Value = totalPaid;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Qarz (Debt)";
                summarySheet.Cells[row, 2].Value = totalDebt;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Vozvrat (Qaytarilgan)";
                summarySheet.Cells[row, 2].Value = -refunds;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                summarySheet.Cells[row, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);

                row += 2;
                summarySheet.Cells[row, 1].Value = "TO'LOV TURLARI BO'YICHA";
                summarySheet.Cells[row, 1, row, 2].Merge = true;
                summarySheet.Cells[row, 1].Style.Font.Bold = true;
                summarySheet.Cells[row, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                row++;
                summarySheet.Cells[row, 1].Value = "Naqd (Cash)";
                summarySheet.Cells[row, 2].Value = cashPayments;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Terminal";
                summarySheet.Cells[row, 2].Value = terminalPayments;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Click";
                summarySheet.Cells[row, 2].Value = clickPayments;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Transfer / Hisob";
                summarySheet.Cells[row, 2].Value = transferPayments;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                if (userRole == "Owner")
                {
                    row += 2;
                    summarySheet.Cells[row, 1].Value = "FOYDA (Profit)";
                    summarySheet.Cells[row, 1, row, 2].Merge = true;
                    summarySheet.Cells[row, 1].Style.Font.Bold = true;
                    summarySheet.Cells[row, 1].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    summarySheet.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);

                    row++;
                    summarySheet.Cells[row, 1].Value = "Jami foyda";
                    summarySheet.Cells[row, 2].Value = totalProfit;
                    summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                    summarySheet.Cells[row, 2].Style.Font.Bold = true;
                }

                row++;
                summarySheet.Cells[row, 1].Value = "Tranzaksiyalar soni";
                summarySheet.Cells[row, 2].Value = filteredSales.Count;
                summarySheet.Cells[row, 2].Style.Font.Bold = true;

                summarySheet.Cells[summarySheet.Dimension.Address].AutoFitColumns();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                // ============================================
                // SHEET 2: BATAFSIL SOTUVLAR RO'YXATI
                // ============================================
                var detailsSheet = package.Workbook.Worksheets.Add("Batafsil Sotuvlar");

                // Headers
                detailsSheet.Cells[1, 1].Value = "№";
                detailsSheet.Cells[1, 2].Value = "Sana";
                detailsSheet.Cells[1, 3].Value = "Savdo ID";
                detailsSheet.Cells[1, 4].Value = "Sotuvchi";
                detailsSheet.Cells[1, 5].Value = "Mijoz";
                detailsSheet.Cells[1, 6].Value = "Jami summa";
                detailsSheet.Cells[1, 7].Value = "To'lov turi";
                detailsSheet.Cells[1, 8].Value = "Holat";
                detailsSheet.Cells[1, 9].Value = "Foyda";

                // Header styling
                using (var range = detailsSheet.Cells[1, 1, 1, 9])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                    range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                }

                // Data rows
                int detailRow = 2;
                decimal detailTotal = 0;
                decimal detailProfit = 0;

                foreach (var sale in filteredSales)
                {
                    detailsSheet.Cells[detailRow, 1].Value = detailRow - 1;
                    detailsSheet.Cells[detailRow, 2].Value = sale.CreatedAt.ToString("dd.MM.yyyy HH:mm");
                    detailsSheet.Cells[detailRow, 3].Value = sale.Id.ToString();
                    detailsSheet.Cells[detailRow, 4].Value = sale.SellerName ?? "";
                    detailsSheet.Cells[detailRow, 5].Value = sale.CustomerName ?? "Mijoz yo'q";
                    detailsSheet.Cells[detailRow, 6].Value = sale.TotalAmount;
                    detailsSheet.Cells[detailRow, 6].Style.Numberformat.Format = "#,##0.00";
                    detailsSheet.Cells[detailRow, 7].Value = GetPaymentTypeText(sale.PaymentType);
                    detailsSheet.Cells[detailRow, 8].Value = GetStatusText(sale.Status);

                    if (userRole == "Owner" && sale.Profit.HasValue)
                    {
                        detailsSheet.Cells[detailRow, 9].Value = sale.Profit.Value;
                        detailsSheet.Cells[detailRow, 9].Style.Numberformat.Format = "#,##0.00";
                        detailProfit += sale.Profit.Value;
                    }
                    else if (userRole == "Owner")
                    {
                        detailsSheet.Cells[detailRow, 9].Value = 0;
                    }

                    // Status coloring
                    var statusCell = detailsSheet.Cells[detailRow, 8];
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
                        case "closed":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.DarkBlue);
                            break;
                    }

                    // Payment type coloring
                    var paymentCell = detailsSheet.Cells[detailRow, 7];
                    if (sale.PaymentType?.ToLower() == "qaytarilgan" || sale.PaymentType?.ToLower() == "refund")
                    {
                        paymentCell.Style.Font.Color.SetColor(System.Drawing.Color.Red);
                        paymentCell.Style.Font.Bold = true;
                    }

                    detailTotal += sale.TotalAmount;
                    detailRow++;
                }

                // Footer
                detailsSheet.Cells[detailRow, 1].Value = "JAMI:";
                detailsSheet.Cells[detailRow, 1, detailRow, 5].Merge = true;
                detailsSheet.Cells[detailRow, 1].Style.Font.Bold = true;
                detailsSheet.Cells[detailRow, 6].Value = detailTotal;
                detailsSheet.Cells[detailRow, 6].Style.Numberformat.Format = "#,##0.00";
                detailsSheet.Cells[detailRow, 6].Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    detailsSheet.Cells[detailRow, 9].Value = detailProfit;
                    detailsSheet.Cells[detailRow, 9].Style.Numberformat.Format = "#,##0.00";
                    detailsSheet.Cells[detailRow, 9].Style.Font.Bold = true;
                }

                detailsSheet.Cells[detailsSheet.Dimension.Address].AutoFitColumns();
                detailsSheet.Column(1).Width = 6;
                detailsSheet.Column(2).Width = 18;
                detailsSheet.Column(3).Width = 40;
                detailsSheet.Column(4).Width = 20;
                detailsSheet.Column(5).Width = 20;
                detailsSheet.Column(6).Width = 15;
                detailsSheet.Column(7).Width = 15;
                detailsSheet.Column(8).Width = 15;
                detailsSheet.Column(9).Width = 15;

                // Borders
                using (var range = detailsSheet.Cells[1, 1, detailRow, 9])
                {
                    range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                }

                // Auto filter
                detailsSheet.Cells[1, 1, 1, 9].AutoFilter = true;

                // ============================================
                // SHEET 3: MAHSULOTLAR BO'YICHA BATAFSIL (Products Detail)
                // ============================================
                try
                {
                    _logger.LogInformation("Fetching sales with items for product detail sheet...");
                    var salesWithItems = await _reportService.GetSalesWithItemsAsync(
                        utcStart, utcEnd, userRole, userId, cancellationToken);
                    _logger.LogInformation("Found {Count} sales with items", salesWithItems.Count);

                    var itemsSheet = package.Workbook.Worksheets.Add("Mahsulotlar Batafsil");

                    // Determine column count based on user role
                    int colCount = userRole == "Owner" ? 9 : 8;

                    // Headers
                    itemsSheet.Cells[1, 1].Value = "№";
                    itemsSheet.Cells[1, 2].Value = "Sana";
                    itemsSheet.Cells[1, 3].Value = "Savdo ID";
                    itemsSheet.Cells[1, 4].Value = "Mijoz";
                    itemsSheet.Cells[1, 5].Value = "Mahsulot nomi";
                    itemsSheet.Cells[1, 6].Value = "Miqdor";
                    itemsSheet.Cells[1, 7].Value = "Sotuv narxi";
                    itemsSheet.Cells[1, 8].Value = "Jami summa";

                    if (userRole == "Owner")
                    {
                        itemsSheet.Cells[1, 9].Value = "Foyda";
                    }

                    // Header styling
                    using (var range = itemsSheet.Cells[1, 1, 1, colCount])
                    {
                        range.Style.Font.Bold = true;
                        range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                        range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);
                        range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                    }

                    // Data rows
                    int itemRow = 2;
                    decimal itemsTotal = 0;
                    decimal itemsProfit = 0;

                    foreach (var sale in salesWithItems)
                    {
                        foreach (var item in sale.Items)
                        {
                            itemsSheet.Cells[itemRow, 1].Value = itemRow - 1;
                            itemsSheet.Cells[itemRow, 2].Value = sale.CreatedAt.ToString("dd.MM.yyyy HH:mm");
                            itemsSheet.Cells[itemRow, 3].Value = sale.Id.ToString();
                            itemsSheet.Cells[itemRow, 4].Value = sale.CustomerName ?? "Mijoz yo'q";
                            itemsSheet.Cells[itemRow, 5].Value = item.ProductName;
                            itemsSheet.Cells[itemRow, 6].Value = item.Quantity;
                            itemsSheet.Cells[itemRow, 6].Style.Numberformat.Format = "#,##0.000";
                            itemsSheet.Cells[itemRow, 7].Value = item.SalePrice;
                            itemsSheet.Cells[itemRow, 7].Style.Numberformat.Format = "#,##0.00";
                            itemsSheet.Cells[itemRow, 8].Value = item.TotalAmount;
                            itemsSheet.Cells[itemRow, 8].Style.Numberformat.Format = "#,##0.00";

                            if (userRole == "Owner" && item.Profit.HasValue)
                            {
                                itemsSheet.Cells[itemRow, 9].Value = item.Profit.Value;
                                itemsSheet.Cells[itemRow, 9].Style.Numberformat.Format = "#,##0.00";
                                itemsProfit += item.Profit.Value;
                            }

                            itemsTotal += item.TotalAmount;
                            itemRow++;
                        }
                    }

                    // Footer
                    itemsSheet.Cells[itemRow, 1].Value = "JAMI:";
                    itemsSheet.Cells[itemRow, 1, itemRow, 7].Merge = true;
                    itemsSheet.Cells[itemRow, 1].Style.Font.Bold = true;
                    itemsSheet.Cells[itemRow, 8].Value = itemsTotal;
                    itemsSheet.Cells[itemRow, 8].Style.Numberformat.Format = "#,##0.00";
                    itemsSheet.Cells[itemRow, 8].Style.Font.Bold = true;

                    if (userRole == "Owner")
                    {
                        itemsSheet.Cells[itemRow, 9].Value = itemsProfit;
                        itemsSheet.Cells[itemRow, 9].Style.Numberformat.Format = "#,##0.00";
                        itemsSheet.Cells[itemRow, 9].Style.Font.Bold = true;
                    }

                    itemsSheet.Cells[itemsSheet.Dimension.Address].AutoFitColumns();
                    itemsSheet.Column(1).Width = 6;
                    itemsSheet.Column(2).Width = 18;
                    itemsSheet.Column(3).Width = 40;
                    itemsSheet.Column(4).Width = 20;
                    itemsSheet.Column(5).Width = 40;
                    itemsSheet.Column(6).Width = 12;
                    itemsSheet.Column(7).Width = 12;
                    itemsSheet.Column(8).Width = 15;
                    if (userRole == "Owner") itemsSheet.Column(9).Width = 15;

                    // Borders
                    using (var range = itemsSheet.Cells[1, 1, itemRow, colCount])
                    {
                        range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    }

                    // Auto filter
                    itemsSheet.Cells[1, 1, 1, colCount].AutoFilter = true;

                    itemsSheet.Cells[itemsSheet.Dimension.Address].AutoFitColumns();
                    itemsSheet.Column(1).Width = 6;
                    itemsSheet.Column(2).Width = 18;
                    itemsSheet.Column(3).Width = 40;
                    itemsSheet.Column(4).Width = 20;
                    itemsSheet.Column(5).Width = 40;
                    itemsSheet.Column(6).Width = 12;
                    itemsSheet.Column(7).Width = 12;
                    itemsSheet.Column(8).Width = 15;
                    if (userRole == "Owner") itemsSheet.Column(9).Width = 15;

                    // Borders
                    using (var range = itemsSheet.Cells[1, 1, itemRow, colCount])
                    {
                        range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                        range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    }

                    _logger.LogInformation("Successfully created product detail sheet with {RowCount} rows", itemRow - 1);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error creating product detail sheet, skipping this sheet");
                    // Continue without this sheet - summary and details sheets are sufficient
                }

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

    private string GetPaymentTypeText(string? paymentType)
    {
        return paymentType?.ToLower() switch
        {
            "cash" => "Naqd",
            "terminal" => "Terminal",
            "click" => "Click",
            "transfer" => "Transfer / Hisob",
            "qaytarilgan" => "QAYTARILGAN",
            "refund" => "QAYTARILGAN",
            _ => paymentType ?? ""
        };
    }

    private string GetStatusText(string? status)
    {
        return status switch
        {
            "Draft" => "Qoralama",
            "Paid" => "To'langan",
            "Debt" => "Qarzli",
            "Closed" => "Yopilgan",
            "Cancelled" => "Bekor qilingan",
            _ => status ?? ""
        };
    }


    [HttpGet("comprehensive-report/export")]
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

            DateTime reportDate = date ?? DateTime.UtcNow;
            var utcDate = DateTime.SpecifyKind(reportDate.Date, DateTimeKind.Utc);

            var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
            var dailyReport = await _reportService.GetDailyReportAsync(utcDate, userRole, cancellationToken);

            ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
            using (var package = new ExcelPackage())
            {
             var summarySheet = package.Workbook.Worksheets.Add("Kunlik Hisobot");

                // Report title
                summarySheet.Cells[1, 1].Value = "KUNLIK HISOBOT";
                summarySheet.Cells[1, 1, 1, 3].Merge = true;
                summarySheet.Cells[1, 1].Style.Font.Bold = true;
                summarySheet.Cells[1, 1].Style.Font.Size = 16;
                summarySheet.Cells[1, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                // Report date
                summarySheet.Cells[2, 1].Value = $"Sana: {reportDate:dd.MM.yyyy}";
                summarySheet.Cells[2, 1, 2, 3].Merge = true;
                summarySheet.Cells[2, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                // Summary statistics
                int row = 4;
                summarySheet.Cells[row, 1].Value = "KO'RSATGICH";
                summarySheet.Cells[row, 2].Value = "QIYMATI";
                summarySheet.Cells[row, 1, row, 2].Style.Font.Bold = true;
                summarySheet.Cells[row, 1, row, 2].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                summarySheet.Cells[row, 1, row, 2].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);

                row++;
                summarySheet.Cells[row, 1].Value = "Sotuvlar soni";
                summarySheet.Cells[row, 2].Value = salesList.Sales.Count;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0";

                row++;
                summarySheet.Cells[row, 1].Value = "Jami savdo (Total)";
                summarySheet.Cells[row, 2].Value = dailyReport.TotalSales;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "To'langan (Paid)";
                summarySheet.Cells[row, 2].Value = dailyReport.TotalPaidSales;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                row++;
                summarySheet.Cells[row, 1].Value = "Qarz (Debt)";
                summarySheet.Cells[row, 2].Value = dailyReport.TotalDebtSales;
                summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                // Payment breakdown from the daily report
                if (dailyReport.PaymentBreakdown != null && dailyReport.PaymentBreakdown.Any())
                {
                    row += 2;
                    summarySheet.Cells[row, 1].Value = "TO'LOV TURLARI";
                    summarySheet.Cells[row, 1, row, 2].Merge = true;
                    summarySheet.Cells[row, 1].Style.Font.Bold = true;
                    summarySheet.Cells[row, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                    foreach (var payment in dailyReport.PaymentBreakdown)
                    {
                        row++;
                        summarySheet.Cells[row, 1].Value = GetPaymentTypeText(payment.PaymentType);
                        summarySheet.Cells[row, 2].Value = payment.Amount;
                        summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";

                        // Color refunds in red
                        if (payment.PaymentType?.ToLower() == "qaytarilgan")
                        {
                            summarySheet.Cells[row, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                        }
                    }
                }

                if (userRole == "Owner" && dailyReport.Profit.HasValue)
                {
                    row += 2;
                    summarySheet.Cells[row, 1].Value = "FOYDA (Profit)";
                    summarySheet.Cells[row, 1, row, 2].Merge = true;
                    summarySheet.Cells[row, 1].Style.Font.Bold = true;
                    summarySheet.Cells[row, 1].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    summarySheet.Cells[row, 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);

                    row++;
                    summarySheet.Cells[row, 1].Value = "Jami foyda";
                    summarySheet.Cells[row, 2].Value = dailyReport.Profit.Value;
                    summarySheet.Cells[row, 2].Style.Numberformat.Format = "#,##0.00";
                    summarySheet.Cells[row, 2].Style.Font.Bold = true;
                }

                summarySheet.Cells[summarySheet.Dimension.Address].AutoFitColumns();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                  var salesSheet = package.Workbook.Worksheets.Add("Sotuvlar Ro'yxati");

                salesSheet.Cells[1, 1].Value = "№";
                salesSheet.Cells[1, 2].Value = "Sana";
                salesSheet.Cells[1, 3].Value = "Savdo ID";
                salesSheet.Cells[1, 4].Value = "Sotuvchi";
                salesSheet.Cells[1, 5].Value = "Mijoz";
                salesSheet.Cells[1, 6].Value = "Summa";
                salesSheet.Cells[1, 7].Value = "To'lov turi";
                salesSheet.Cells[1, 8].Value = "Holat";
                if (userRole == "Owner")
                {
                    salesSheet.Cells[1, 9].Value = "Foyda";
                }

                // Header styling
                int headerCols = userRole == "Owner" ? 9 : 8;
                using (var range = salesSheet.Cells[1, 1, 1, headerCols])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
                    range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                }

                // Data rows
                int salesRow = 2;
                decimal sheetTotal = 0;
                decimal sheetProfit = 0;

                foreach (var sale in salesList.Sales)
                {
                    salesSheet.Cells[salesRow, 1].Value = salesRow - 1;
                    salesSheet.Cells[salesRow, 2].Value = sale.CreatedAt.ToString("dd.MM.yyyy HH:mm");
                    salesSheet.Cells[salesRow, 3].Value = sale.Id.ToString();
                    salesSheet.Cells[salesRow, 4].Value = sale.SellerName ?? "";
                    salesSheet.Cells[salesRow, 5].Value = sale.CustomerName ?? "Mijoz yo'q";
                    salesSheet.Cells[salesRow, 6].Value = sale.TotalAmount;
                    salesSheet.Cells[salesRow, 6].Style.Numberformat.Format = "#,##0.00";
                    salesSheet.Cells[salesRow, 7].Value = GetPaymentTypeText(sale.PaymentType);
                    salesSheet.Cells[salesRow, 8].Value = GetStatusText(sale.Status ?? "");

                    if (userRole == "Owner")
                    {
                        salesSheet.Cells[salesRow, 9].Value = sale.Profit ?? 0;
                        salesSheet.Cells[salesRow, 9].Style.Numberformat.Format = "#,##0.00";
                        sheetProfit += sale.Profit ?? 0;
                    }

                    var statusCell = salesSheet.Cells[salesRow, 8];
                    switch (sale.Status?.ToLower())
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
                        case "closed":
                            statusCell.Style.Font.Color.SetColor(System.Drawing.Color.DarkBlue);
                            break;
                    }

                    // Payment type coloring for refunds
                    var paymentCell = salesSheet.Cells[salesRow, 7];
                    if (sale.PaymentType?.ToLower() == "qaytarilgan" || sale.PaymentType?.ToLower() == "refund")
                    {
                        paymentCell.Style.Font.Color.SetColor(System.Drawing.Color.Red);
                        paymentCell.Style.Font.Bold = true;
                    }

                    sheetTotal += sale.TotalAmount;
                    salesRow++;
                }

                salesSheet.Cells[salesRow, 1].Value = "JAMI:";
                salesSheet.Cells[salesRow, 1, salesRow, 5].Merge = true;
                salesSheet.Cells[salesRow, 1].Style.Font.Bold = true;
                salesSheet.Cells[salesRow, 6].Value = sheetTotal;
                salesSheet.Cells[salesRow, 6].Style.Numberformat.Format = "#,##0.00";
                salesSheet.Cells[salesRow, 6].Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    salesSheet.Cells[salesRow, 9].Value = sheetProfit;
                    salesSheet.Cells[salesRow, 9].Style.Numberformat.Format = "#,##0.00";
                    salesSheet.Cells[salesRow, 9].Style.Font.Bold = true;
                }

                salesSheet.Cells[salesSheet.Dimension.Address].AutoFitColumns();
                salesSheet.Column(1).Width = 6;
                salesSheet.Column(2).Width = 18;
                salesSheet.Column(3).Width = 40;
                salesSheet.Column(4).Width = 20;
                salesSheet.Column(5).Width = 20;
                salesSheet.Column(6).Width = 15;
                salesSheet.Column(7).Width = 15;
                salesSheet.Column(8).Width = 15;
                if (userRole == "Owner") salesSheet.Column(9).Width = 15;

                using (var range = salesSheet.Cells[1, 1, salesRow, headerCols])
                {
                    range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                }
                salesSheet.Cells[1, 1, 1, headerCols].AutoFilter = true;

                var productsSheet = package.Workbook.Worksheets.Add("Mahsulotlar Bo'yicha");
                productsSheet.Cells[1, 1].Value = "MAHSULOTLAR BO'YICHA HISOBOT";
                productsSheet.Cells[1, 1, 1, 5].Merge = true;
                productsSheet.Cells[1, 1].Style.Font.Bold = true;
                productsSheet.Cells[1, 1].Style.Font.Size = 14;
                productsSheet.Cells[1, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                productsSheet.Cells[2, 1].Value = $"Sana: {reportDate:dd.MM.yyyy}";
                productsSheet.Cells[2, 1, 2, 5].Merge = true;
                productsSheet.Cells[2, 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                productsSheet.Cells[4, 1].Value = "№";
                productsSheet.Cells[4, 2].Value = "Mahsulot nomi";
                productsSheet.Cells[4, 3].Value = "Miqdor";
                productsSheet.Cells[4, 4].Value = "Sotuv narxi";
                productsSheet.Cells[4, 5].Value = "Jami summa";

                using (var range = productsSheet.Cells[4, 1, 4, 5])
                {
                    range.Style.Font.Bold = true;
                    range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                    range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);
                    range.Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                }

                var dailySaleItems = await _reportService.GetDailySaleItemsAsync(utcDate, userRole, cancellationToken);
                int prodRow = 5;
                decimal prodTotal = 0;

                foreach (var item in dailySaleItems.SaleItems)
                {
                    productsSheet.Cells[prodRow, 1].Value = prodRow - 4;
                    productsSheet.Cells[prodRow, 2].Value = item.ProductName;
                    productsSheet.Cells[prodRow, 3].Value = item.Quantity;
                    productsSheet.Cells[prodRow, 3].Style.Numberformat.Format = "#,##0.000";
                    productsSheet.Cells[prodRow, 4].Value = item.SalePrice;
                    productsSheet.Cells[prodRow, 4].Style.Numberformat.Format = "#,##0.00";
                    productsSheet.Cells[prodRow, 5].Value = item.TotalRevenue;
                    productsSheet.Cells[prodRow, 5].Style.Numberformat.Format = "#,##0.00";

                    prodTotal += item.TotalRevenue;
                    prodRow++;
                }

                productsSheet.Cells[prodRow, 1].Value = "JAMI:";
                productsSheet.Cells[prodRow, 1, prodRow, 4].Merge = true;
                productsSheet.Cells[prodRow, 1].Style.Font.Bold = true;
                productsSheet.Cells[prodRow, 5].Value = prodTotal;
                productsSheet.Cells[prodRow, 5].Style.Numberformat.Format = "#,##0.00";
                productsSheet.Cells[prodRow, 5].Style.Font.Bold = true;

                productsSheet.Cells[productsSheet.Dimension.Address].AutoFitColumns();
                productsSheet.Column(1).Width = 6;
                productsSheet.Column(2).Width = 40;
                productsSheet.Column(3).Width = 12;
                productsSheet.Column(4).Width = 15;
                productsSheet.Column(5).Width = 15;

                using (var range = productsSheet.Cells[4, 1, prodRow, 5])
                {
                    range.Style.Border.Top.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Bottom.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Left.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                    range.Style.Border.Right.Style = OfficeOpenXml.Style.ExcelBorderStyle.Thin;
                }

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

    [HttpGet("monthly-category-sales")]
    [Authorize(Policy = "AllRoles")]
    public async Task<ActionResult<MonthlyCategorySalesResponseDto>> GetMonthlyCategorySales([FromQuery] DateTime date, CancellationToken cancellationToken = default)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Service handles UTC conversion internally
        var report = await _reportService.GetMonthlyCategorySalesAsync(date, userRole, cancellationToken);
        return Ok(report);
    }

    [HttpGet("daily/export-pdf")]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportDailyReportToPdf([FromQuery] DateTime date)
    {
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var pdfBytes = await _reportService.ExportDailyReportToPdfAsync(utcDate, userRole);

        return File(
            pdfBytes,
            "application/pdf",
            $"daily_report_{date:yyyyMMdd}.pdf"
        );
    }

    [HttpGet("period/export-pdf")]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportPeriodReportToPdf(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

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

    [HttpGet("comprehensive/export-pdf")]
    [Authorize(Policy = "AllRoles")]
    public async Task<IActionResult> ExportComprehensiveReportToPdf([FromQuery] DateTime date)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var pdfBytes = await _reportService.ExportComprehensiveReportToPdfAsync(utcDate, userRole);

        return File(
            pdfBytes,
            "application/pdf",
            $"comprehensive_report_{date:yyyyMMdd}.pdf"
        );
    }
}