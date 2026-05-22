using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using ClosedXML.Excel;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;
    private readonly ILogger<ReportsController> _logger;
    private readonly TimeZoneInfo _tashkent;

    public ReportsController(
        IReportService reportService,
        ILogger<ReportsController> logger,
        TimeZoneInfo tashkent)
    {
        _reportService = reportService;
        _logger = logger;
        _tashkent = tashkent;
    }

    /// <summary>
    /// Format a UTC timestamp as Tashkent local time for Excel display.
    /// Without this, all CreatedAt values rendered in the spreadsheet are
    /// 5 hours behind what the seller sees in the Flutter UI, which made
    /// late-evening sales appear to "fall on the previous day" in reports.
    /// </summary>
    private string FmtTashkent(DateTime utc) =>
        TimeZoneInfo.ConvertTimeFromUtc(
                DateTime.SpecifyKind(utc, DateTimeKind.Utc), _tashkent)
            .ToString("dd.MM.yyyy HH:mm");

    /// <summary>
    /// Get daily sales report
    /// </summary>
    [HttpGet("daily")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
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
    [RequirePermission(PermissionKeys.ReportsAccess)]
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
    [RequirePermission(PermissionKeys.ReportsAccess)]
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
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<IActionResult> ExportToExcel(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var excelBytes = await _reportService.ExportToExcelAsync(request, userRole);

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
    [RequirePermission(PermissionKeys.ReportsAccess)]
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
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<IActionResult> ExportComprehensiveToExcel(
        [FromQuery] DateTime date,
        [FromQuery] string lang = "uz")
    {
        var excelBytes = await _reportService.ExportComprehensiveToExcelAsync(date, lang);
        var fileName = lang.Equals("ru", StringComparison.OrdinalIgnoreCase)
            ? $"Otchet_{date:yyyyMMdd}.xlsx"
            : $"Hisobot_{date:yyyyMMdd}.xlsx";

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            fileName
        );
    }

    // New endpoints for role-based access control

    /// <summary>
    /// Get profit summary - Owner only
    /// </summary>
    [HttpGet("profit-summary")]
    [RequirePermission(PermissionKeys.DataProfit)]
    public async Task<ActionResult<ProfitSummaryDto>> GetProfitSummary()
    {
        var summary = await _reportService.GetProfitSummaryAsync();
        return Ok(summary);
    }

    /// <summary>
    /// Get last N days of revenue/profit/check counts as a time series.
    /// Backs the dashboard ChartCard. Defaults to 7 days; capped at 30 inside
    /// the service so a misbehaving client can't trigger a month-long scan.
    /// Profit values are zero unless the caller is Owner.
    /// </summary>
    [HttpGet("weekly-series")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<ActionResult<WeeklySeriesDto>> GetWeeklySeries(
        [FromQuery] int days = 7,
        [FromQuery] bool compare = false)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var series = await _reportService.GetWeeklySeriesAsync(days, compare, userRole);
        return Ok(series);
    }

    /// <summary>
    /// Get top-N products in the selected period, ranked by quantity, revenue,
    /// or profit. Backs the dashboard TopSellersCard and the Reports → Top
    /// page. Profit is hidden for non-Owner callers.
    /// </summary>
    [HttpGet("top-products")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<ActionResult<TopProductsDto>> GetTopProducts(
        [FromQuery] string period = "month",
        [FromQuery] string sortBy = "quantity",
        [FromQuery] int limit = 10)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var products = await _reportService.GetTopProductsAsync(period, sortBy, limit, userRole);
        return Ok(products);
    }

    /// <summary>
    /// Get per-staff sales metrics for the period. Backs the Users list page
    /// and the Reports → Staff page. Returns staff with zero sales too, so a
    /// quiet seller doesn't silently disappear from the team list.
    /// </summary>
    [HttpGet("staff-performance")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<ActionResult<StaffPerformanceDto>> GetStaffPerformance(
        [FromQuery] string period = "week")
    {
        var staff = await _reportService.GetStaffPerformanceAsync(period);
        return Ok(staff);
    }

    /// <summary>
    /// Get the current user's own sales metrics for the period (default: today).
    /// Backs the Seller dashboard's SellerStatsRow (sale count, revenue,
    /// shift duration). Open to all authenticated roles — each user only
    /// ever sees their own row.
    /// </summary>
    [HttpGet("my-performance")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<ActionResult<MyPerformanceDto>> GetMyPerformance(
        [FromQuery] string period = "today")
    {
        var userIdStr = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdStr) || !Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        var result = await _reportService.GetMyPerformanceAsync(userId, period);
        return Ok(result);
    }

    /// <summary>
    /// Get cash balance - Owner only
    /// </summary>
    [HttpGet("cash-balance")]
    [RequirePermission(PermissionKeys.DataCashBalance)]
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
    [RequirePermission(PermissionKeys.SalesAccess)]
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
    [RequirePermission(PermissionKeys.ReportsExport)]
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
            // Pass endDate so the service returns the whole [start, end] range —
            // previously this fetched only utcStart's single day, so a multi-day
            // export silently dropped every sale after day one.
            var salesList = await _reportService.GetDailySalesListAsync(
                utcStart, userRole, userId, endDate: utcEnd, cancellationToken);
            _logger.LogInformation("Got {Count} sales from service", salesList.Sales.Count);

            // The service already scoped the query to the range; this guard
            // just keeps the rest of the method working off an explicit list.
            var filteredSales = salesList.Sales.ToList();
            _logger.LogInformation("Filtered to {Count} sales within date range", filteredSales.Count);

            using (var workbook = new XLWorkbook())
            {
                // ============================================
                // SHEET 1: KUNLIK UMUMIY HISOBOT (Summary)
                // ============================================
                var summarySheet = workbook.Worksheets.Add("Kunlik Hisobot");

                // Report title
                summarySheet.Cell(1, 1).Value = "SOTUVLAR HISOBOTI";
                summarySheet.Range(1, 1, 1, 6).Merge();
                summarySheet.Cell(1, 1).Style.Font.Bold = true;
                summarySheet.Cell(1, 1).Style.Font.FontSize = 16;
                summarySheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Report period
                summarySheet.Cell(2, 1).Value = $"Sana: {queryStartDate:yyyy-MM-dd} - {queryEndDate:yyyy-MM-dd}";
                summarySheet.Range(2, 1, 2, 6).Merge();
                summarySheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

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
                summarySheet.Cell(row, 1).Value = "KO'RSATGICH";
                summarySheet.Cell(row, 2).Value = "SUMMA (so'm)";
                summarySheet.Range(row, 1, row, 2).Style.Font.Bold = true;
                summarySheet.Range(row, 1, row, 2).Style.Fill.BackgroundColor = XLColor.LightBlue;
                summarySheet.Range(row, 1, row, 2).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                row++;
                summarySheet.Cell(row, 1).Value = "Jami savdo (Total)";
                summarySheet.Cell(row, 2).Value = totalSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "To'langan (Naqd)";
                summarySheet.Cell(row, 2).Value = totalPaid;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Qarz (Debt)";
                summarySheet.Cell(row, 2).Value = totalDebt;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Vozvrat (Qaytarilgan)";
                summarySheet.Cell(row, 2).Value = -refunds;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";
                summarySheet.Cell(row, 2).Style.Font.FontColor = XLColor.Red;

                row += 2;
                summarySheet.Cell(row, 1).Value = "TO'LOV TURLARI BO'YICHA";
                summarySheet.Range(row, 1, row, 2).Merge();
                summarySheet.Cell(row, 1).Style.Font.Bold = true;
                summarySheet.Cell(row, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                row++;
                summarySheet.Cell(row, 1).Value = "Naqd (Cash)";
                summarySheet.Cell(row, 2).Value = cashPayments;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Terminal";
                summarySheet.Cell(row, 2).Value = terminalPayments;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Click";
                summarySheet.Cell(row, 2).Value = clickPayments;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Transfer / Hisob";
                summarySheet.Cell(row, 2).Value = transferPayments;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                if (userRole == "Owner")
                {
                    row += 2;
                    summarySheet.Cell(row, 1).Value = "FOYDA (Profit)";
                    summarySheet.Range(row, 1, row, 2).Merge();
                    summarySheet.Cell(row, 1).Style.Font.Bold = true;
                    summarySheet.Cell(row, 1).Style.Fill.BackgroundColor = XLColor.LightGreen;

                    row++;
                    summarySheet.Cell(row, 1).Value = "Jami foyda";
                    summarySheet.Cell(row, 2).Value = totalProfit;
                    summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";
                    summarySheet.Cell(row, 2).Style.Font.Bold = true;
                }

                row++;
                summarySheet.Cell(row, 1).Value = "Tranzaksiyalar soni";
                summarySheet.Cell(row, 2).Value = filteredSales.Count;
                summarySheet.Cell(row, 2).Style.Font.Bold = true;

                summarySheet.Columns().AdjustToContents();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                // ============================================
                // SHEET 2: BATAFSIL SOTUVLAR RO'YXATI
                // ============================================
                var detailsSheet = workbook.Worksheets.Add("Batafsil Sotuvlar");

                // Headers
                detailsSheet.Cell(1, 1).Value = "№";
                detailsSheet.Cell(1, 2).Value = "Sana";
                detailsSheet.Cell(1, 3).Value = "Savdo ID";
                detailsSheet.Cell(1, 4).Value = "Sotuvchi";
                detailsSheet.Cell(1, 5).Value = "Mijoz";
                detailsSheet.Cell(1, 6).Value = "Jami summa";
                detailsSheet.Cell(1, 7).Value = "To'lov turi";
                detailsSheet.Cell(1, 8).Value = "Holat";
                detailsSheet.Cell(1, 9).Value = "Foyda";

                // Header styling
                var detailsHeaderRange = detailsSheet.Range(1, 1, 1, 9);
                {
                    detailsHeaderRange.Style.Font.Bold = true;
                    detailsHeaderRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
                    detailsHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // Data rows
                int detailRow = 2;
                decimal detailTotal = 0;
                decimal detailProfit = 0;

                foreach (var sale in filteredSales)
                {
                    detailsSheet.Cell(detailRow, 1).Value = detailRow - 1;
                    detailsSheet.Cell(detailRow, 2).Value = FmtTashkent(sale.CreatedAt);
                    detailsSheet.Cell(detailRow, 3).Value = sale.Id.ToString();
                    detailsSheet.Cell(detailRow, 4).Value = sale.SellerName ?? "";
                    detailsSheet.Cell(detailRow, 5).Value = sale.CustomerName ?? "Mijoz yo'q";
                    detailsSheet.Cell(detailRow, 6).Value = sale.TotalAmount;
                    detailsSheet.Cell(detailRow, 6).Style.NumberFormat.Format = "#,##0.00";
                    detailsSheet.Cell(detailRow, 7).Value = GetPaymentTypeText(sale.PaymentType);
                    detailsSheet.Cell(detailRow, 8).Value = GetStatusText(sale.Status);

                    if (userRole == "Owner" && sale.Profit.HasValue)
                    {
                        detailsSheet.Cell(detailRow, 9).Value = sale.Profit.Value;
                        detailsSheet.Cell(detailRow, 9).Style.NumberFormat.Format = "#,##0.00";
                        detailProfit += sale.Profit.Value;
                    }
                    else if (userRole == "Owner")
                    {
                        detailsSheet.Cell(detailRow, 9).Value = 0;
                    }

                    // Status coloring
                    var statusCell = detailsSheet.Cell(detailRow, 8);
                    switch (sale.Status.ToLower())
                    {
                        case "paid":
                            statusCell.Style.Font.FontColor = XLColor.Green;
                            break;
                        case "debt":
                            statusCell.Style.Font.FontColor = XLColor.Red;
                            break;
                        case "cancelled":
                            statusCell.Style.Font.FontColor = XLColor.Gray;
                            break;
                        case "draft":
                            statusCell.Style.Font.FontColor = XLColor.Orange;
                            break;
                        case "closed":
                            statusCell.Style.Font.FontColor = XLColor.DarkBlue;
                            break;
                    }

                    // Payment type coloring
                    var paymentCell = detailsSheet.Cell(detailRow, 7);
                    if (sale.PaymentType?.ToLower() == "qaytarilgan" || sale.PaymentType?.ToLower() == "refund")
                    {
                        paymentCell.Style.Font.FontColor = XLColor.Red;
                        paymentCell.Style.Font.Bold = true;
                    }

                    detailTotal += sale.TotalAmount;
                    detailRow++;
                }

                // Footer
                detailsSheet.Cell(detailRow, 1).Value = "JAMI:";
                detailsSheet.Range(detailRow, 1, detailRow, 5).Merge();
                detailsSheet.Cell(detailRow, 1).Style.Font.Bold = true;
                detailsSheet.Cell(detailRow, 6).Value = detailTotal;
                detailsSheet.Cell(detailRow, 6).Style.NumberFormat.Format = "#,##0.00";
                detailsSheet.Cell(detailRow, 6).Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    detailsSheet.Cell(detailRow, 9).Value = detailProfit;
                    detailsSheet.Cell(detailRow, 9).Style.NumberFormat.Format = "#,##0.00";
                    detailsSheet.Cell(detailRow, 9).Style.Font.Bold = true;
                }

                detailsSheet.Columns().AdjustToContents();
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
                var detailsBorderRange = detailsSheet.Range(1, 1, detailRow, 9);
                {
                    detailsBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                    detailsBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                    detailsBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                    detailsBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                }

                // Auto filter
                detailsSheet.Range(1, 1, 1, 9).SetAutoFilter();

                // ============================================
                // SHEET 3: MAHSULOTLAR BO'YICHA BATAFSIL (Products Detail)
                // ============================================
                try
                {
                    _logger.LogInformation("Fetching sales with items for product detail sheet...");
                    var salesWithItems = await _reportService.GetSalesWithItemsAsync(
                        utcStart, utcEnd, userRole, userId, cancellationToken);
                    _logger.LogInformation("Found {Count} sales with items", salesWithItems.Count);

                    var itemsSheet = workbook.Worksheets.Add("Mahsulotlar Batafsil");

                    // Determine column count based on user role
                    int colCount = userRole == "Owner" ? 9 : 8;

                    // Headers
                    itemsSheet.Cell(1, 1).Value = "№";
                    itemsSheet.Cell(1, 2).Value = "Sana";
                    itemsSheet.Cell(1, 3).Value = "Savdo ID";
                    itemsSheet.Cell(1, 4).Value = "Mijoz";
                    itemsSheet.Cell(1, 5).Value = "Mahsulot nomi";
                    itemsSheet.Cell(1, 6).Value = "Miqdor";
                    itemsSheet.Cell(1, 7).Value = "Sotuv narxi";
                    itemsSheet.Cell(1, 8).Value = "Jami summa";

                    if (userRole == "Owner")
                    {
                        itemsSheet.Cell(1, 9).Value = "Foyda";
                    }

                    // Header styling
                    var itemsHeaderRange = itemsSheet.Range(1, 1, 1, colCount);
                    {
                        itemsHeaderRange.Style.Font.Bold = true;
                        itemsHeaderRange.Style.Fill.BackgroundColor = XLColor.LightGreen;
                        itemsHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                    }

                    // Data rows
                    int itemRow = 2;
                    decimal itemsTotal = 0;
                    decimal itemsProfit = 0;

                    foreach (var sale in salesWithItems)
                    {
                        foreach (var item in sale.Items)
                        {
                            itemsSheet.Cell(itemRow, 1).Value = itemRow - 1;
                            itemsSheet.Cell(itemRow, 2).Value = FmtTashkent(sale.CreatedAt);
                            itemsSheet.Cell(itemRow, 3).Value = sale.Id.ToString();
                            itemsSheet.Cell(itemRow, 4).Value = sale.CustomerName ?? "Mijoz yo'q";
                            itemsSheet.Cell(itemRow, 5).Value = item.ProductName;
                            itemsSheet.Cell(itemRow, 6).Value = item.Quantity;
                            itemsSheet.Cell(itemRow, 6).Style.NumberFormat.Format = "#,##0.000";
                            itemsSheet.Cell(itemRow, 7).Value = item.SalePrice;
                            itemsSheet.Cell(itemRow, 7).Style.NumberFormat.Format = "#,##0.00";
                            itemsSheet.Cell(itemRow, 8).Value = item.TotalAmount;
                            itemsSheet.Cell(itemRow, 8).Style.NumberFormat.Format = "#,##0.00";

                            if (userRole == "Owner" && item.Profit.HasValue)
                            {
                                itemsSheet.Cell(itemRow, 9).Value = item.Profit.Value;
                                itemsSheet.Cell(itemRow, 9).Style.NumberFormat.Format = "#,##0.00";
                                itemsProfit += item.Profit.Value;
                            }

                            itemsTotal += item.TotalAmount;
                            itemRow++;
                        }
                    }

                    // Footer
                    itemsSheet.Cell(itemRow, 1).Value = "JAMI:";
                    itemsSheet.Range(itemRow, 1, itemRow, 7).Merge();
                    itemsSheet.Cell(itemRow, 1).Style.Font.Bold = true;
                    itemsSheet.Cell(itemRow, 8).Value = itemsTotal;
                    itemsSheet.Cell(itemRow, 8).Style.NumberFormat.Format = "#,##0.00";
                    itemsSheet.Cell(itemRow, 8).Style.Font.Bold = true;

                    if (userRole == "Owner")
                    {
                        itemsSheet.Cell(itemRow, 9).Value = itemsProfit;
                        itemsSheet.Cell(itemRow, 9).Style.NumberFormat.Format = "#,##0.00";
                        itemsSheet.Cell(itemRow, 9).Style.Font.Bold = true;
                    }

                    itemsSheet.Columns().AdjustToContents();
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
                    var itemsBorderRange = itemsSheet.Range(1, 1, itemRow, colCount);
                    {
                        itemsBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                        itemsBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                        itemsBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                        itemsBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                    }

                    // Auto filter
                    itemsSheet.Range(1, 1, 1, colCount).SetAutoFilter();

                    _logger.LogInformation("Successfully created product detail sheet with {RowCount} rows", itemRow - 1);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error creating product detail sheet, skipping this sheet");
                    // Continue without this sheet - summary and details sheets are sufficient
                }

                var stream = new MemoryStream();
                workbook.SaveAs(stream);
                stream.Position = 0;
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

    private string GetPaymentTypeText(string? paymentType, bool isRu = false)
    {
        return paymentType?.ToLower() switch
        {
            "cash" => isRu ? "Наличные" : "Naqd",
            "terminal" => "Terminal",
            "click" => "Click",
            "transfer" => isRu ? "Перевод / Счёт" : "Transfer / Hisob",
            "qaytarilgan" => isRu ? "ВОЗВРАТ" : "QAYTARILGAN",
            "refund" => isRu ? "ВОЗВРАТ" : "QAYTARILGAN",
            _ => paymentType ?? ""
        };
    }

    private string GetStatusText(string? status, bool isRu = false)
    {
        return status switch
        {
            "Draft" => isRu ? "Черновик" : "Qoralama",
            "Paid" => isRu ? "Оплачено" : "To'langan",
            "Debt" => isRu ? "В долг" : "Qarzli",
            "Closed" => isRu ? "Закрыто" : "Yopilgan",
            "Cancelled" => isRu ? "Отменено" : "Bekor qilingan",
            _ => status ?? ""
        };
    }


    [HttpGet("comprehensive-report/export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportComprehensiveReportToExcel(
        [FromQuery] DateTime? date = null,
        [FromQuery] string lang = "uz",
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Exporting comprehensive report to Excel. Date: {Date}", date);

            var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

            DateTime reportDate = date ?? DateTime.UtcNow;
            var utcDate = DateTime.SpecifyKind(reportDate.Date, DateTimeKind.Utc);

            var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
            var dailyReport = await _reportService.GetDailyReportAsync(utcDate, userRole, cancellationToken);

            using (var workbook = new XLWorkbook())
            {
             var summarySheet = workbook.Worksheets.Add(isRu ? "Дневной отчёт" : "Kunlik Hisobot");

                // Report title
                summarySheet.Cell(1, 1).Value = isRu ? "ДНЕВНОЙ ОТЧЁТ" : "KUNLIK HISOBOT";
                summarySheet.Range(1, 1, 1, 3).Merge();
                summarySheet.Cell(1, 1).Style.Font.Bold = true;
                summarySheet.Cell(1, 1).Style.Font.FontSize = 16;
                summarySheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Report date
                summarySheet.Cell(2, 1).Value = (isRu ? "Дата: " : "Sana: ") + reportDate.ToString("dd.MM.yyyy");
                summarySheet.Range(2, 1, 2, 3).Merge();
                summarySheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Summary statistics
                int row = 4;
                summarySheet.Cell(row, 1).Value = isRu ? "ПОКАЗАТЕЛЬ" : "KO'RSATGICH";
                summarySheet.Cell(row, 2).Value = isRu ? "ЗНАЧЕНИЕ" : "QIYMATI";
                summarySheet.Range(row, 1, row, 2).Style.Font.Bold = true;
                summarySheet.Range(row, 1, row, 2).Style.Fill.BackgroundColor = XLColor.LightBlue;

                row++;
                summarySheet.Cell(row, 1).Value = isRu ? "Количество продаж" : "Sotuvlar soni";
                summarySheet.Cell(row, 2).Value = salesList.Sales.Count;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0";

                row++;
                summarySheet.Cell(row, 1).Value = isRu ? "Общая выручка (Total)" : "Jami savdo (Total)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = isRu ? "Оплачено (Paid)" : "To'langan (Paid)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalPaidSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = isRu ? "Долг (Debt)" : "Qarz (Debt)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalDebtSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                // Payment breakdown from the daily report
                if (dailyReport.PaymentBreakdown != null && dailyReport.PaymentBreakdown.Any())
                {
                    row += 2;
                    summarySheet.Cell(row, 1).Value = isRu ? "ТИПЫ ОПЛАТЫ" : "TO'LOV TURLARI";
                    summarySheet.Range(row, 1, row, 2).Merge();
                    summarySheet.Cell(row, 1).Style.Font.Bold = true;
                    summarySheet.Cell(row, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                    foreach (var payment in dailyReport.PaymentBreakdown)
                    {
                        row++;
                        summarySheet.Cell(row, 1).Value = GetPaymentTypeText(payment.PaymentType, isRu);
                        summarySheet.Cell(row, 2).Value = payment.Amount;
                        summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                        // Color refunds in red
                        if (payment.PaymentType?.ToLower() == "qaytarilgan")
                        {
                            summarySheet.Cell(row, 2).Style.Font.FontColor = XLColor.Red;
                        }
                    }
                }

                if (userRole == "Owner" && dailyReport.Profit.HasValue)
                {
                    row += 2;
                    summarySheet.Cell(row, 1).Value = isRu ? "ПРИБЫЛЬ (Profit)" : "FOYDA (Profit)";
                    summarySheet.Range(row, 1, row, 2).Merge();
                    summarySheet.Cell(row, 1).Style.Font.Bold = true;
                    summarySheet.Cell(row, 1).Style.Fill.BackgroundColor = XLColor.LightGreen;

                    row++;
                    summarySheet.Cell(row, 1).Value = isRu ? "Общая прибыль" : "Jami foyda";
                    summarySheet.Cell(row, 2).Value = dailyReport.Profit.Value;
                    summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";
                    summarySheet.Cell(row, 2).Style.Font.Bold = true;
                }

                summarySheet.Columns().AdjustToContents();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                  var salesSheet = workbook.Worksheets.Add(isRu ? "Список продаж" : "Sotuvlar Ro'yxati");

                salesSheet.Cell(1, 1).Value = "№";
                salesSheet.Cell(1, 2).Value = isRu ? "Дата" : "Sana";
                salesSheet.Cell(1, 3).Value = isRu ? "ID продажи" : "Savdo ID";
                salesSheet.Cell(1, 4).Value = isRu ? "Продавец" : "Sotuvchi";
                salesSheet.Cell(1, 5).Value = isRu ? "Клиент" : "Mijoz";
                salesSheet.Cell(1, 6).Value = isRu ? "Сумма" : "Summa";
                salesSheet.Cell(1, 7).Value = isRu ? "Тип оплаты" : "To'lov turi";
                salesSheet.Cell(1, 8).Value = isRu ? "Статус" : "Holat";
                if (userRole == "Owner")
                {
                    salesSheet.Cell(1, 9).Value = isRu ? "Прибыль" : "Foyda";
                }

                // Header styling
                int headerCols = userRole == "Owner" ? 9 : 8;
                var salesHeaderRange = salesSheet.Range(1, 1, 1, headerCols);
                {
                    salesHeaderRange.Style.Font.Bold = true;
                    salesHeaderRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
                    salesHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                // Data rows
                int salesRow = 2;
                decimal sheetTotal = 0;
                decimal sheetProfit = 0;

                foreach (var sale in salesList.Sales)
                {
                    salesSheet.Cell(salesRow, 1).Value = salesRow - 1;
                    salesSheet.Cell(salesRow, 2).Value = FmtTashkent(sale.CreatedAt);
                    salesSheet.Cell(salesRow, 3).Value = sale.Id.ToString();
                    salesSheet.Cell(salesRow, 4).Value = sale.SellerName ?? "";
                    salesSheet.Cell(salesRow, 5).Value = sale.CustomerName ?? (isRu ? "Без клиента" : "Mijoz yo'q");
                    salesSheet.Cell(salesRow, 6).Value = sale.TotalAmount;
                    salesSheet.Cell(salesRow, 6).Style.NumberFormat.Format = "#,##0.00";
                    salesSheet.Cell(salesRow, 7).Value = GetPaymentTypeText(sale.PaymentType, isRu);
                    salesSheet.Cell(salesRow, 8).Value = GetStatusText(sale.Status ?? "", isRu);

                    if (userRole == "Owner")
                    {
                        salesSheet.Cell(salesRow, 9).Value = sale.Profit ?? 0;
                        salesSheet.Cell(salesRow, 9).Style.NumberFormat.Format = "#,##0.00";
                        sheetProfit += sale.Profit ?? 0;
                    }

                    var statusCell = salesSheet.Cell(salesRow, 8);
                    switch (sale.Status?.ToLower())
                    {
                        case "paid":
                            statusCell.Style.Font.FontColor = XLColor.Green;
                            break;
                        case "debt":
                            statusCell.Style.Font.FontColor = XLColor.Red;
                            break;
                        case "cancelled":
                            statusCell.Style.Font.FontColor = XLColor.Gray;
                            break;
                        case "draft":
                            statusCell.Style.Font.FontColor = XLColor.Orange;
                            break;
                        case "closed":
                            statusCell.Style.Font.FontColor = XLColor.DarkBlue;
                            break;
                    }

                    // Payment type coloring for refunds
                    var paymentCell = salesSheet.Cell(salesRow, 7);
                    if (sale.PaymentType?.ToLower() == "qaytarilgan" || sale.PaymentType?.ToLower() == "refund")
                    {
                        paymentCell.Style.Font.FontColor = XLColor.Red;
                        paymentCell.Style.Font.Bold = true;
                    }

                    sheetTotal += sale.TotalAmount;
                    salesRow++;
                }

                salesSheet.Cell(salesRow, 1).Value = isRu ? "ИТОГО:" : "JAMI:";
                salesSheet.Range(salesRow, 1, salesRow, 5).Merge();
                salesSheet.Cell(salesRow, 1).Style.Font.Bold = true;
                salesSheet.Cell(salesRow, 6).Value = sheetTotal;
                salesSheet.Cell(salesRow, 6).Style.NumberFormat.Format = "#,##0.00";
                salesSheet.Cell(salesRow, 6).Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    salesSheet.Cell(salesRow, 9).Value = sheetProfit;
                    salesSheet.Cell(salesRow, 9).Style.NumberFormat.Format = "#,##0.00";
                    salesSheet.Cell(salesRow, 9).Style.Font.Bold = true;
                }

                salesSheet.Columns().AdjustToContents();
                salesSheet.Column(1).Width = 6;
                salesSheet.Column(2).Width = 18;
                salesSheet.Column(3).Width = 40;
                salesSheet.Column(4).Width = 20;
                salesSheet.Column(5).Width = 20;
                salesSheet.Column(6).Width = 15;
                salesSheet.Column(7).Width = 15;
                salesSheet.Column(8).Width = 15;
                if (userRole == "Owner") salesSheet.Column(9).Width = 15;

                var salesBorderRange = salesSheet.Range(1, 1, salesRow, headerCols);
                {
                    salesBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                }
                salesSheet.Range(1, 1, 1, headerCols).SetAutoFilter();

                var productsSheet = workbook.Worksheets.Add(isRu ? "По товарам" : "Mahsulotlar Bo'yicha");
                productsSheet.Cell(1, 1).Value = isRu ? "ОТЧЁТ ПО ТОВАРАМ" : "MAHSULOTLAR BO'YICHA HISOBOT";
                productsSheet.Range(1, 1, 1, 5).Merge();
                productsSheet.Cell(1, 1).Style.Font.Bold = true;
                productsSheet.Cell(1, 1).Style.Font.FontSize = 14;
                productsSheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                productsSheet.Cell(2, 1).Value = (isRu ? "Дата: " : "Sana: ") + reportDate.ToString("dd.MM.yyyy");
                productsSheet.Range(2, 1, 2, 5).Merge();
                productsSheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                productsSheet.Cell(4, 1).Value = "№";
                productsSheet.Cell(4, 2).Value = isRu ? "Название товара" : "Mahsulot nomi";
                productsSheet.Cell(4, 3).Value = isRu ? "Количество" : "Miqdor";
                productsSheet.Cell(4, 4).Value = isRu ? "Цена продажи" : "Sotuv narxi";
                productsSheet.Cell(4, 5).Value = isRu ? "Общая сумма" : "Jami summa";

                var productsHeaderRange = productsSheet.Range(4, 1, 4, 5);
                {
                    productsHeaderRange.Style.Font.Bold = true;
                    productsHeaderRange.Style.Fill.BackgroundColor = XLColor.LightGreen;
                    productsHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                var dailySaleItems = await _reportService.GetDailySaleItemsAsync(utcDate, userRole, cancellationToken);
                int prodRow = 5;
                decimal prodTotal = 0;

                foreach (var item in dailySaleItems.SaleItems)
                {
                    productsSheet.Cell(prodRow, 1).Value = prodRow - 4;
                    productsSheet.Cell(prodRow, 2).Value = item.ProductName;
                    productsSheet.Cell(prodRow, 3).Value = item.Quantity;
                    productsSheet.Cell(prodRow, 3).Style.NumberFormat.Format = "#,##0.000";
                    productsSheet.Cell(prodRow, 4).Value = item.SalePrice;
                    productsSheet.Cell(prodRow, 4).Style.NumberFormat.Format = "#,##0.00";
                    productsSheet.Cell(prodRow, 5).Value = item.TotalRevenue;
                    productsSheet.Cell(prodRow, 5).Style.NumberFormat.Format = "#,##0.00";

                    prodTotal += item.TotalRevenue;
                    prodRow++;
                }

                productsSheet.Cell(prodRow, 1).Value = isRu ? "ИТОГО:" : "JAMI:";
                productsSheet.Range(prodRow, 1, prodRow, 4).Merge();
                productsSheet.Cell(prodRow, 1).Style.Font.Bold = true;
                productsSheet.Cell(prodRow, 5).Value = prodTotal;
                productsSheet.Cell(prodRow, 5).Style.NumberFormat.Format = "#,##0.00";
                productsSheet.Cell(prodRow, 5).Style.Font.Bold = true;

                productsSheet.Columns().AdjustToContents();
                productsSheet.Column(1).Width = 6;
                productsSheet.Column(2).Width = 40;
                productsSheet.Column(3).Width = 12;
                productsSheet.Column(4).Width = 15;
                productsSheet.Column(5).Width = 15;

                var productsBorderRange = productsSheet.Range(4, 1, prodRow, 5);
                {
                    productsBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                }

                var stream = new MemoryStream();
                workbook.SaveAs(stream);
                stream.Position = 0;
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var fileName = (isRu ? "otchet_" : "hisobot_") + $"{DateTime.Now:yyyyMMdd_HHmmss}.xlsx";

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
    [RequirePermission(PermissionKeys.SalesAccess)]
    public async Task<ActionResult<MonthlyCategorySalesResponseDto>> GetMonthlyCategorySales([FromQuery] DateTime date, CancellationToken cancellationToken = default)
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Service handles UTC conversion internally
        var report = await _reportService.GetMonthlyCategorySalesAsync(date, userRole, cancellationToken);
        return Ok(report);
    }

    [HttpGet("daily/export-pdf")]
    [RequirePermission(PermissionKeys.ReportsExport)]
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
    [RequirePermission(PermissionKeys.ReportsExport)]
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
    [RequirePermission(PermissionKeys.ReportsExport)]
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

    /// <summary>
    /// Export daily report to Excel - kunlik hisobot, sotuvlar ro'yxati va mahsulotlar bo'yicha
    /// </summary>
    [HttpGet("daily/export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportDailyReportToExcel([FromQuery] DateTime date)
    {
        try
        {
            _logger.LogInformation("Exporting daily report to Excel. Date: {Date}", date);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

            var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

            var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
            var dailyReport = await _reportService.GetDailyReportAsync(utcDate, userRole);

            using (var workbook = new XLWorkbook())
            {
                // SHEET 1: Kunlik Hisobot
                var summarySheet = workbook.Worksheets.Add("Kunlik Hisobot");

                // Report title
                summarySheet.Cell(1, 1).Value = "KUNLIK HISOBOT";
                summarySheet.Range(1, 1, 1, 3).Merge();
                summarySheet.Cell(1, 1).Style.Font.Bold = true;
                summarySheet.Cell(1, 1).Style.Font.FontSize = 16;
                summarySheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Report date
                summarySheet.Cell(2, 1).Value = $"Sana: {date:dd.MM.yyyy}";
                summarySheet.Range(2, 1, 2, 3).Merge();
                summarySheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                // Summary statistics
                int row = 4;
                summarySheet.Cell(row, 1).Value = "KO'RSATGICH";
                summarySheet.Cell(row, 2).Value = "QIYMATI";
                summarySheet.Range(row, 1, row, 2).Style.Font.Bold = true;
                summarySheet.Range(row, 1, row, 2).Style.Fill.BackgroundColor = XLColor.LightBlue;

                row++;
                summarySheet.Cell(row, 1).Value = "Sotuvlar soni";
                summarySheet.Cell(row, 2).Value = salesList.Sales.Count;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0";

                row++;
                summarySheet.Cell(row, 1).Value = "Jami savdo (Total)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "To'langan (Paid)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalPaidSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                row++;
                summarySheet.Cell(row, 1).Value = "Qarz (Debt)";
                summarySheet.Cell(row, 2).Value = dailyReport.TotalDebtSales;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                // Payment breakdown
                if (dailyReport.PaymentBreakdown != null && dailyReport.PaymentBreakdown.Any())
                {
                    row += 2;
                    summarySheet.Cell(row, 1).Value = "TO'LOV TURLARI";
                    summarySheet.Range(row, 1, row, 2).Merge();
                    summarySheet.Cell(row, 1).Style.Font.Bold = true;
                    summarySheet.Cell(row, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                    foreach (var payment in dailyReport.PaymentBreakdown)
                    {
                        row++;
                        summarySheet.Cell(row, 1).Value = GetPaymentTypeText(payment.PaymentType);
                        summarySheet.Cell(row, 2).Value = payment.Amount;
                        summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";

                        if (payment.PaymentType?.ToLower() == "qaytarilgan")
                        {
                            summarySheet.Cell(row, 2).Style.Font.FontColor = XLColor.Red;
                        }
                    }
                }

                if (userRole == "Owner" && dailyReport.Profit.HasValue)
                {
                    row += 2;
                    summarySheet.Cell(row, 1).Value = "FOYDA (Profit)";
                    summarySheet.Range(row, 1, row, 2).Merge();
                    summarySheet.Cell(row, 1).Style.Font.Bold = true;
                    summarySheet.Cell(row, 1).Style.Fill.BackgroundColor = XLColor.LightGreen;

                    row++;
                    summarySheet.Cell(row, 1).Value = "Jami foyda";
                    summarySheet.Cell(row, 2).Value = dailyReport.Profit.Value;
                    summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";
                    summarySheet.Cell(row, 2).Style.Font.Bold = true;
                }

                summarySheet.Columns().AdjustToContents();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                // SHEET 2: Sotuvlar Ro'yxati
                var salesSheet = workbook.Worksheets.Add("Sotuvlar Ro'yxati");

                salesSheet.Cell(1, 1).Value = "№";
                salesSheet.Cell(1, 2).Value = "Sana";
                salesSheet.Cell(1, 3).Value = "Savdo ID";
                salesSheet.Cell(1, 4).Value = "Sotuvchi";
                salesSheet.Cell(1, 5).Value = "Mijoz";
                salesSheet.Cell(1, 6).Value = "Summa";
                salesSheet.Cell(1, 7).Value = "To'lov turi";
                salesSheet.Cell(1, 8).Value = "Holat";
                if (userRole == "Owner")
                {
                    salesSheet.Cell(1, 9).Value = "Foyda";
                }

                int headerCols = userRole == "Owner" ? 9 : 8;
                var salesHeaderRange = salesSheet.Range(1, 1, 1, headerCols);
                {
                    salesHeaderRange.Style.Font.Bold = true;
                    salesHeaderRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
                    salesHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                int salesRow = 2;
                decimal sheetTotal = 0;
                decimal sheetProfit = 0;

                foreach (var sale in salesList.Sales)
                {
                    salesSheet.Cell(salesRow, 1).Value = salesRow - 1;
                    salesSheet.Cell(salesRow, 2).Value = FmtTashkent(sale.CreatedAt);
                    salesSheet.Cell(salesRow, 3).Value = sale.Id.ToString();
                    salesSheet.Cell(salesRow, 4).Value = sale.SellerName ?? "";
                    salesSheet.Cell(salesRow, 5).Value = sale.CustomerName ?? "Mijoz yo'q";
                    salesSheet.Cell(salesRow, 6).Value = sale.TotalAmount;
                    salesSheet.Cell(salesRow, 6).Style.NumberFormat.Format = "#,##0.00";
                    salesSheet.Cell(salesRow, 7).Value = GetPaymentTypeText(sale.PaymentType);
                    salesSheet.Cell(salesRow, 8).Value = GetStatusText(sale.Status ?? "");

                    if (userRole == "Owner")
                    {
                        salesSheet.Cell(salesRow, 9).Value = sale.Profit ?? 0;
                        salesSheet.Cell(salesRow, 9).Style.NumberFormat.Format = "#,##0.00";
                        sheetProfit += sale.Profit ?? 0;
                    }

                    var statusCell = salesSheet.Cell(salesRow, 8);
                    switch (sale.Status?.ToLower())
                    {
                        case "paid":
                            statusCell.Style.Font.FontColor = XLColor.Green;
                            break;
                        case "debt":
                            statusCell.Style.Font.FontColor = XLColor.Red;
                            break;
                        case "cancelled":
                            statusCell.Style.Font.FontColor = XLColor.Gray;
                            break;
                        case "draft":
                            statusCell.Style.Font.FontColor = XLColor.Orange;
                            break;
                        case "closed":
                            statusCell.Style.Font.FontColor = XLColor.DarkBlue;
                            break;
                    }

                    sheetTotal += sale.TotalAmount;
                    salesRow++;
                }

                salesSheet.Cell(salesRow, 1).Value = "JAMI:";
                salesSheet.Range(salesRow, 1, salesRow, 5).Merge();
                salesSheet.Cell(salesRow, 1).Style.Font.Bold = true;
                salesSheet.Cell(salesRow, 6).Value = sheetTotal;
                salesSheet.Cell(salesRow, 6).Style.NumberFormat.Format = "#,##0.00";
                salesSheet.Cell(salesRow, 6).Style.Font.Bold = true;

                if (userRole == "Owner")
                {
                    salesSheet.Cell(salesRow, 9).Value = sheetProfit;
                    salesSheet.Cell(salesRow, 9).Style.NumberFormat.Format = "#,##0.00";
                    salesSheet.Cell(salesRow, 9).Style.Font.Bold = true;
                }

                salesSheet.Columns().AdjustToContents();
                salesSheet.Column(1).Width = 6;
                salesSheet.Column(2).Width = 18;
                salesSheet.Column(3).Width = 40;
                salesSheet.Column(4).Width = 20;
                salesSheet.Column(5).Width = 20;
                salesSheet.Column(6).Width = 15;
                salesSheet.Column(7).Width = 15;
                salesSheet.Column(8).Width = 15;
                if (userRole == "Owner") salesSheet.Column(9).Width = 15;

                var salesBorderRange = salesSheet.Range(1, 1, salesRow, headerCols);
                {
                    salesBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                    salesBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                }
                salesSheet.Range(1, 1, 1, headerCols).SetAutoFilter();

                // SHEET 3: Mahsulotlar Bo'yicha
                var productsSheet = workbook.Worksheets.Add("Mahsulotlar Bo'yicha");
                productsSheet.Cell(1, 1).Value = "MAHSULOTLAR BO'YICHA HISOBOT";
                productsSheet.Range(1, 1, 1, 5).Merge();
                productsSheet.Cell(1, 1).Style.Font.Bold = true;
                productsSheet.Cell(1, 1).Style.Font.FontSize = 14;
                productsSheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                productsSheet.Cell(2, 1).Value = $"Sana: {date:dd.MM.yyyy}";
                productsSheet.Range(2, 1, 2, 5).Merge();
                productsSheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                productsSheet.Cell(4, 1).Value = "№";
                productsSheet.Cell(4, 2).Value = "Mahsulot nomi";
                productsSheet.Cell(4, 3).Value = "Miqdor";
                productsSheet.Cell(4, 4).Value = "Sotuv narxi";
                productsSheet.Cell(4, 5).Value = "Jami summa";

                var productsHeaderRange = productsSheet.Range(4, 1, 4, 5);
                {
                    productsHeaderRange.Style.Font.Bold = true;
                    productsHeaderRange.Style.Fill.BackgroundColor = XLColor.LightGreen;
                    productsHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                }

                var dailySaleItems = await _reportService.GetDailySaleItemsAsync(utcDate, userRole);
                int prodRow = 5;
                decimal prodTotal = 0;

                foreach (var item in dailySaleItems.SaleItems)
                {
                    productsSheet.Cell(prodRow, 1).Value = prodRow - 4;
                    productsSheet.Cell(prodRow, 2).Value = item.ProductName;
                    productsSheet.Cell(prodRow, 3).Value = item.Quantity;
                    productsSheet.Cell(prodRow, 3).Style.NumberFormat.Format = "#,##0.000";
                    productsSheet.Cell(prodRow, 4).Value = item.SalePrice;
                    productsSheet.Cell(prodRow, 4).Style.NumberFormat.Format = "#,##0.00";
                    productsSheet.Cell(prodRow, 5).Value = item.TotalRevenue;
                    productsSheet.Cell(prodRow, 5).Style.NumberFormat.Format = "#,##0.00";

                    prodTotal += item.TotalRevenue;
                    prodRow++;
                }

                productsSheet.Cell(prodRow, 1).Value = "JAMI:";
                productsSheet.Range(prodRow, 1, prodRow, 4).Merge();
                productsSheet.Cell(prodRow, 1).Style.Font.Bold = true;
                productsSheet.Cell(prodRow, 5).Value = prodTotal;
                productsSheet.Cell(prodRow, 5).Style.NumberFormat.Format = "#,##0.00";
                productsSheet.Cell(prodRow, 5).Style.Font.Bold = true;

                productsSheet.Columns().AdjustToContents();
                productsSheet.Column(1).Width = 6;
                productsSheet.Column(2).Width = 40;
                productsSheet.Column(3).Width = 12;
                productsSheet.Column(4).Width = 15;
                productsSheet.Column(5).Width = 15;

                var productsBorderRange = productsSheet.Range(4, 1, prodRow, 5);
                {
                    productsBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                    productsBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                }

                var stream = new MemoryStream();
                workbook.SaveAs(stream);
                stream.Position = 0;
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var fileName = $"kunlik_hisobot_{date:yyyyMMdd}.xlsx";

                _logger.LogInformation("Successfully exported daily report to Excel");
                return File(stream, contentType, fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting daily report to Excel");
            return StatusCode(500, new { message = "Xatolik yuz berdi", error = ex.Message });
        }
    }

    /// <summary>
    /// Export inventory report to Excel - ombor hisoboti
    /// </summary>
    [HttpGet("inventory/export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportInventoryReportToExcel([FromQuery] DateTime date)
    {
        try
        {
            _logger.LogInformation("Exporting inventory report to Excel. Date: {Date}", date);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);

            var comprehensiveReport = await _reportService.GetComprehensiveReportAsync(utcDate, userRole);

            using (var workbook = new XLWorkbook())
            {
                // SHEET 1: Ombor xulosasi
                var summarySheet = workbook.Worksheets.Add("Ombor Xulosasi");

                summarySheet.Cell(1, 1).Value = "OMBOR HISOBOTI";
                summarySheet.Range(1, 1, 1, 3).Merge();
                summarySheet.Cell(1, 1).Style.Font.Bold = true;
                summarySheet.Cell(1, 1).Style.Font.FontSize = 16;
                summarySheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                summarySheet.Cell(2, 1).Value = $"Sana: {date:dd.MM.yyyy}";
                summarySheet.Range(2, 1, 2, 3).Merge();
                summarySheet.Cell(2, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                int row = 4;
                summarySheet.Cell(row, 1).Value = "KO'RSATGICH";
                summarySheet.Cell(row, 2).Value = "QIYMATI";
                summarySheet.Range(row, 1, row, 2).Style.Font.Bold = true;
                summarySheet.Range(row, 1, row, 2).Style.Fill.BackgroundColor = XLColor.LightGray;

                row++;
                summarySheet.Cell(row, 1).Value = "Mahsulotlar soni";
                summarySheet.Cell(row, 2).Value = comprehensiveReport.ProductCount;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0";

                row++;
                summarySheet.Cell(row, 1).Value = "Jami ombor qiymati";
                if (userRole == "Owner")
                {
                    summarySheet.Cell(row, 2).Value = comprehensiveReport.TotalInventoryValue;
                    summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0.00";
                }
                else
                {
                    summarySheet.Cell(row, 2).Value = "Noma'lum";
                }

                row++;
                summarySheet.Cell(row, 1).Value = "Kam qolgan mahsulotlar";
                summarySheet.Cell(row, 2).Value = comprehensiveReport.LowStockCount;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0";
                summarySheet.Cell(row, 2).Style.Font.FontColor = XLColor.Red;

                row++;
                summarySheet.Cell(row, 1).Value = "Tugagan mahsulotlar";
                summarySheet.Cell(row, 2).Value = comprehensiveReport.OutOfStockCount;
                summarySheet.Cell(row, 2).Style.NumberFormat.Format = "#,##0";
                summarySheet.Cell(row, 2).Style.Font.FontColor = XLColor.DarkRed;

                summarySheet.Columns().AdjustToContents();
                summarySheet.Column(1).Width = 30;
                summarySheet.Column(2).Width = 20;

                // SHEET 2: Mahsulotlar ro'yxati
                if (comprehensiveReport.InventoryReport != null && comprehensiveReport.InventoryReport.Any())
                {
                    var inventorySheet = workbook.Worksheets.Add("Mahsulotlar Ro'yxati");

                    inventorySheet.Cell(1, 1).Value = "№";
                    inventorySheet.Cell(1, 2).Value = "Mahsulot nomi";
                    inventorySheet.Cell(1, 3).Value = "Kategoriya";
                    inventorySheet.Cell(1, 4).Value = "Miqdor";
                    inventorySheet.Cell(1, 5).Value = "Birligi";
                    if (userRole == "Owner")
                    {
                        inventorySheet.Cell(1, 6).Value = "Olingan narxi";
                        inventorySheet.Cell(1, 7).Value = "Sotuv narxi";
                        inventorySheet.Cell(1, 8).Value = "Ombor qiymati";
                    }
                    else
                    {
                        inventorySheet.Cell(1, 6).Value = "Sotuv narxi";
                    }

                    int invHeaderCols = userRole == "Owner" ? 8 : 6;
                    var inventoryHeaderRange = inventorySheet.Range(1, 1, 1, invHeaderCols);
                    {
                        inventoryHeaderRange.Style.Font.Bold = true;
                        inventoryHeaderRange.Style.Fill.BackgroundColor = XLColor.LightBlue;
                        inventoryHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                    }

                    int invRow = 2;
                    int idx = 1;
                    decimal totalInvValue = 0;

                    foreach (var item in comprehensiveReport.InventoryReport)
                    {
                        inventorySheet.Cell(invRow, 1).Value = idx++;
                        inventorySheet.Cell(invRow, 2).Value = item.ProductName;
                        inventorySheet.Cell(invRow, 3).Value = item.Category ?? "";
                        inventorySheet.Cell(invRow, 4).Value = item.Quantity;
                        inventorySheet.Cell(invRow, 4).Style.NumberFormat.Format = "#,##0.000";
                        inventorySheet.Cell(invRow, 5).Value = item.Unit ?? "";

                        if (userRole == "Owner")
                        {
                            inventorySheet.Cell(invRow, 6).Value = item.CostPrice ?? 0;
                            inventorySheet.Cell(invRow, 6).Style.NumberFormat.Format = "#,##0.00";
                            inventorySheet.Cell(invRow, 7).Value = item.SalePrice;
                            inventorySheet.Cell(invRow, 7).Style.NumberFormat.Format = "#,##0.00";

                            decimal itemValue = (item.CostPrice ?? 0) * item.Quantity;
                            inventorySheet.Cell(invRow, 8).Value = itemValue;
                            inventorySheet.Cell(invRow, 8).Style.NumberFormat.Format = "#,##0.00";
                            totalInvValue += itemValue;
                        }
                        else
                        {
                            inventorySheet.Cell(invRow, 6).Value = item.SalePrice;
                            inventorySheet.Cell(invRow, 6).Style.NumberFormat.Format = "#,##0.00";
                        }

                        // Highlight low stock and out of stock
                        if (item.Quantity <= 0)
                        {
                            inventorySheet.Cell(invRow, 4).Style.Font.FontColor = XLColor.Red;
                            inventorySheet.Cell(invRow, 4).Style.Font.Bold = true;
                        }
                        else if (item.Quantity < 10)
                        {
                            inventorySheet.Cell(invRow, 4).Style.Font.FontColor = XLColor.Orange;
                        }

                        invRow++;
                    }

                    // Footer
                    inventorySheet.Cell(invRow, 1).Value = "JAMI:";
                    inventorySheet.Range(invRow, 1, invRow, 7).Merge();
                    inventorySheet.Cell(invRow, 1).Style.Font.Bold = true;

                    if (userRole == "Owner")
                    {
                        inventorySheet.Cell(invRow, 8).Value = totalInvValue;
                        inventorySheet.Cell(invRow, 8).Style.NumberFormat.Format = "#,##0.00";
                        inventorySheet.Cell(invRow, 8).Style.Font.Bold = true;
                    }

                    inventorySheet.Columns().AdjustToContents();
                    inventorySheet.Column(1).Width = 6;
                    inventorySheet.Column(2).Width = 40;
                    inventorySheet.Column(3).Width = 20;
                    inventorySheet.Column(4).Width = 12;
                    inventorySheet.Column(5).Width = 10;
                    if (userRole == "Owner")
                    {
                        inventorySheet.Column(6).Width = 15;
                        inventorySheet.Column(7).Width = 15;
                        inventorySheet.Column(8).Width = 18;
                    }
                    else
                    {
                        inventorySheet.Column(6).Width = 15;
                    }

                    var inventoryBorderRange = inventorySheet.Range(1, 1, invRow, invHeaderCols);
                    {
                        inventoryBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                        inventoryBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                        inventoryBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                        inventoryBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                    }
                    inventorySheet.Range(1, 1, 1, invHeaderCols).SetAutoFilter();
                }

                // SHEET 3: Kam qolgan mahsulotlar (agar mavjud bo'lsa)
                if (comprehensiveReport.InventoryReport != null && comprehensiveReport.InventoryReport.Any(i => i.Quantity < 10))
                {
                    var lowStockSheet = workbook.Worksheets.Add("Kam Qolgan Mahsulotlar");

                    lowStockSheet.Cell(1, 1).Value = "KAM QOLGAN VA TUGAGAN MAHSULOTLAR";
                    lowStockSheet.Range(1, 1, 1, 5).Merge();
                    lowStockSheet.Cell(1, 1).Style.Font.Bold = true;
                    lowStockSheet.Cell(1, 1).Style.Font.FontSize = 14;
                    lowStockSheet.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

                    lowStockSheet.Cell(3, 1).Value = "№";
                    lowStockSheet.Cell(3, 2).Value = "Mahsulot nomi";
                    lowStockSheet.Cell(3, 3).Value = "Kategoriya";
                    lowStockSheet.Cell(3, 4).Value = "Miqdor";
                    lowStockSheet.Cell(3, 5).Value = "Holati";

                    var lowStockHeaderRange = lowStockSheet.Range(3, 1, 3, 5);
                    {
                        lowStockHeaderRange.Style.Font.Bold = true;
                        lowStockHeaderRange.Style.Fill.BackgroundColor = XLColor.LightCoral;
                        lowStockHeaderRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;
                    }

                    int lowRow = 4;
                    int lowIdx = 1;

                    var lowStockItems = comprehensiveReport.InventoryReport.Where(i => i.Quantity < 10).OrderBy(i => i.Quantity).ToList();

                    foreach (var item in lowStockItems)
                    {
                        lowStockSheet.Cell(lowRow, 1).Value = lowIdx++;
                        lowStockSheet.Cell(lowRow, 2).Value = item.ProductName;
                        lowStockSheet.Cell(lowRow, 3).Value = item.Category ?? "";
                        lowStockSheet.Cell(lowRow, 4).Value = item.Quantity;
                        lowStockSheet.Cell(lowRow, 4).Style.NumberFormat.Format = "#,##0.000";

                        string status = item.Quantity <= 0 ? "TUGAGAN" : "KAM QOLGAN";
                        lowStockSheet.Cell(lowRow, 5).Value = status;

                        if (item.Quantity <= 0)
                        {
                            lowStockSheet.Cell(lowRow, 4).Style.Font.FontColor = XLColor.DarkRed;
                            lowStockSheet.Cell(lowRow, 4).Style.Font.Bold = true;
                            lowStockSheet.Cell(lowRow, 5).Style.Font.FontColor = XLColor.DarkRed;
                            lowStockSheet.Cell(lowRow, 5).Style.Font.Bold = true;
                        }
                        else
                        {
                            lowStockSheet.Cell(lowRow, 4).Style.Font.FontColor = XLColor.Orange;
                            lowStockSheet.Cell(lowRow, 5).Style.Font.FontColor = XLColor.Orange;
                        }

                        lowRow++;
                    }

                    lowStockSheet.Columns().AdjustToContents();
                    lowStockSheet.Column(1).Width = 6;
                    lowStockSheet.Column(2).Width = 40;
                    lowStockSheet.Column(3).Width = 20;
                    lowStockSheet.Column(4).Width = 12;
                    lowStockSheet.Column(5).Width = 15;

                    var lowStockBorderRange = lowStockSheet.Range(3, 1, lowRow - 1, 5);
                    {
                        lowStockBorderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
                        lowStockBorderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
                        lowStockBorderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
                        lowStockBorderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
                    }
                }

                var stream = new MemoryStream();
                workbook.SaveAs(stream);
                stream.Position = 0;
                var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
                var fileName = $"ombor_hisoboti_{date:yyyyMMdd}.xlsx";

                _logger.LogInformation("Successfully exported inventory report to Excel");
                return File(stream, contentType, fileName);
            }
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting inventory report to Excel");
            return StatusCode(500, new { message = "Xatolik yuz berdi", error = ex.Message });
        }
    }
}