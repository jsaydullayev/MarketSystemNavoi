using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
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
    /// Pre-aggregated counters for the Owner dashboard (customer count,
    /// low-stock count, pending / overdue debts). Lets the client fetch a
    /// tiny JSON payload instead of downloading and folding three full
    /// catalogs on the UI isolate.
    /// </summary>
    [HttpGet("dashboard-summary")]
    [RequirePermission(PermissionKeys.ReportsAccess)]
    public async Task<ActionResult<DashboardSummaryDto>> GetDashboardSummary(
        CancellationToken cancellationToken)
    {
        var summary = await _reportService.GetOwnerDashboardSummaryAsync(cancellationToken);
        return Ok(summary);
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
    [EnableRateLimiting("export")]
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
                var fileName = (isRu ? "otchet_" : "hisobot_") + $"{TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, _tashkent):yyyyMMdd_HHmmss}.xlsx";

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
    /// Export the current warehouse (Ombor) inventory to Excel — mirrors the
    /// Reports → Ombor tab: a summary sheet (product count, incoming/sale
    /// valuation, potential profit, low/out-of-stock counts) plus the full
    /// per-product list (every product in the market, not date-bound).
    ///
    /// RBAC mirrors the rest of the report exports:
    ///   - cost columns (purchase price, total cost) → Owner + Admin only
    ///   - potential-profit columns → Owner only
    /// A Seller never sees cost or profit, so those columns are dropped
    /// entirely from their workbook rather than blanked.
    /// </summary>
    [HttpGet("inventory-report/export")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportInventoryReportToExcel(
        [FromQuery] DateTime? date = null,
        [FromQuery] string lang = "uz",
        CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Exporting warehouse (inventory) report to Excel. Date: {Date}", date);

            var isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);

            var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
            // Cost is visible to Owner AND Admin; profit only to Owner —
            // same masking the sales PDF/Excel exports apply.
            bool includeCost = userRole is "Owner" or "Admin";
            bool includeProfit = userRole == "Owner";

            DateTime reportDate = date ?? DateTime.UtcNow;
            var utcDate = DateTime.SpecifyKind(reportDate.Date, DateTimeKind.Utc);

            // The comprehensive report already computes the full inventory list
            // (current quantity × cost/sale prices) for the whole market.
            var report = await _reportService.GetComprehensiveReportAsync(utcDate, userRole, cancellationToken);
            var inventory = report.InventoryReport;

            using var workbook = new XLWorkbook();

            // ── Sheet 1: warehouse summary ──
            var summary = workbook.Worksheets.Add(isRu ? "Склад (сводка)" : "Ombor (xulosa)");

            summary.Cell(1, 1).Value = isRu ? "СКЛАД — СВОДКА" : "OMBOR — XULOSA";
            summary.Range(1, 1, 1, 2).Merge();
            summary.Cell(1, 1).Style.Font.Bold = true;
            summary.Cell(1, 1).Style.Font.FontSize = 16;
            summary.Cell(1, 1).Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            int r = 3;
            summary.Cell(r, 1).Value = isRu ? "ПОКАЗАТЕЛЬ" : "KO'RSATGICH";
            summary.Cell(r, 2).Value = isRu ? "ЗНАЧЕНИЕ" : "QIYMATI";
            summary.Range(r, 1, r, 2).Style.Font.Bold = true;
            summary.Range(r, 1, r, 2).Style.Fill.BackgroundColor = XLColor.LightBlue;

            r++;
            summary.Cell(r, 1).Value = isRu ? "Количество товаров" : "Mahsulotlar soni";
            summary.Cell(r, 2).Value = report.ProductCount;
            summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0";

            if (includeCost)
            {
                r++;
                summary.Cell(r, 1).Value = isRu ? "Приходная стоимость" : "Kelgan narxi";
                summary.Cell(r, 2).Value = report.TotalInventoryCost;
                summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0.00";
            }

            r++;
            summary.Cell(r, 1).Value = isRu ? "Стоимость продажи" : "Sotish narxi";
            summary.Cell(r, 2).Value = report.TotalInventorySaleValue;
            summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0.00";

            if (includeProfit)
            {
                r++;
                summary.Cell(r, 1).Value = isRu ? "Потенциальная прибыль" : "Potensial foyda";
                summary.Cell(r, 2).Value = report.TotalInventorySaleValue - report.TotalInventoryCost;
                summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0.00";
                summary.Cell(r, 2).Style.Font.Bold = true;
                summary.Cell(r, 2).Style.Font.FontColor = XLColor.Green;
            }

            r++;
            summary.Cell(r, 1).Value = isRu ? "Заканчивается" : "Kam qolgan";
            summary.Cell(r, 2).Value = report.LowStockCount;
            summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0";

            r++;
            summary.Cell(r, 1).Value = isRu ? "Закончились" : "Tugagan";
            summary.Cell(r, 2).Value = report.OutOfStockCount;
            summary.Cell(r, 2).Style.NumberFormat.Format = "#,##0";
            summary.Cell(r, 2).Style.Font.FontColor = report.OutOfStockCount > 0 ? XLColor.Red : XLColor.Black;

            summary.Column(1).Width = 28;
            summary.Column(2).Width = 22;

            // ── Sheet 2: per-product warehouse list ──
            var sheet = workbook.Worksheets.Add(isRu ? "Товары на складе" : "Ombordagi mahsulotlar");

            // Build column layout dynamically so masked columns leave no gaps.
            int c = 1;
            int colNo = c++;
            int colName = c++;
            int colCategory = c++;
            int colUnit = c++;
            int colStock = c++;
            int colPurchase = includeCost ? c++ : 0;
            int colSale = c++;
            int colMinSale = c++;
            int colTotalCost = includeCost ? c++ : 0;
            int colTotalValue = c++;
            int colProfit = includeProfit ? c++ : 0;
            int lastCol = c - 1;

            sheet.Cell(1, colNo).Value = "№";
            sheet.Cell(1, colName).Value = isRu ? "Название товара" : "Mahsulot nomi";
            sheet.Cell(1, colCategory).Value = isRu ? "Категория" : "Kategoriya";
            sheet.Cell(1, colUnit).Value = isRu ? "Ед." : "Birlik";
            sheet.Cell(1, colStock).Value = isRu ? "Остаток" : "Qoldiq";
            if (includeCost) sheet.Cell(1, colPurchase).Value = isRu ? "Цена закупки" : "Sotib olish narxi";
            sheet.Cell(1, colSale).Value = isRu ? "Цена продажи" : "Sotuv narxi";
            sheet.Cell(1, colMinSale).Value = isRu ? "Мин. цена" : "Min. narx";
            if (includeCost) sheet.Cell(1, colTotalCost).Value = isRu ? "Общий расход" : "Jami xarajat";
            sheet.Cell(1, colTotalValue).Value = isRu ? "Общая стоимость" : "Jami qiymat";
            if (includeProfit) sheet.Cell(1, colProfit).Value = isRu ? "Потенц. прибыль" : "Potensial foyda";

            var headerRange = sheet.Range(1, 1, 1, lastCol);
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.BackgroundColor = XLColor.LightGreen;
            headerRange.Style.Alignment.Horizontal = XLAlignmentHorizontalValues.Center;

            int row = 2;
            int idx = 1;
            foreach (var item in inventory)
            {
                sheet.Cell(row, colNo).Value = idx++;
                sheet.Cell(row, colName).Value = item.ProductName;
                sheet.Cell(row, colCategory).Value = item.Category ?? "";
                sheet.Cell(row, colUnit).Value = item.Unit ?? "";
                sheet.Cell(row, colStock).Value = item.Quantity;
                sheet.Cell(row, colStock).Style.NumberFormat.Format = "#,##0.###";

                if (includeCost)
                {
                    sheet.Cell(row, colPurchase).Value = item.CostPrice ?? 0;
                    sheet.Cell(row, colPurchase).Style.NumberFormat.Format = "#,##0.00";
                }

                sheet.Cell(row, colSale).Value = item.SalePrice;
                sheet.Cell(row, colSale).Style.NumberFormat.Format = "#,##0.00";
                sheet.Cell(row, colMinSale).Value = item.MinSalePrice;
                sheet.Cell(row, colMinSale).Style.NumberFormat.Format = "#,##0.00";

                if (includeCost)
                {
                    sheet.Cell(row, colTotalCost).Value = item.TotalCostValue;
                    sheet.Cell(row, colTotalCost).Style.NumberFormat.Format = "#,##0.00";
                }

                sheet.Cell(row, colTotalValue).Value = item.TotalSaleValue;
                sheet.Cell(row, colTotalValue).Style.NumberFormat.Format = "#,##0.00";

                if (includeProfit)
                {
                    sheet.Cell(row, colProfit).Value = item.PotentialProfit ?? 0;
                    sheet.Cell(row, colProfit).Style.NumberFormat.Format = "#,##0.00";
                }

                // Colour the stock cell like the UI chip: red when out, orange when low.
                var stockCell = sheet.Cell(row, colStock);
                if (item.Quantity <= 0)
                    stockCell.Style.Font.FontColor = XLColor.Red;
                else if (item.Quantity <= 10)
                    stockCell.Style.Font.FontColor = XLColor.Orange;
                else
                    stockCell.Style.Font.FontColor = XLColor.Green;

                row++;
            }

            // Totals row
            sheet.Cell(row, colNo).Value = isRu ? "ИТОГО:" : "JAMI:";
            sheet.Range(row, colNo, row, colStock).Merge();
            sheet.Cell(row, colNo).Style.Font.Bold = true;
            if (includeCost)
            {
                sheet.Cell(row, colTotalCost).Value = report.TotalInventoryCost;
                sheet.Cell(row, colTotalCost).Style.NumberFormat.Format = "#,##0.00";
                sheet.Cell(row, colTotalCost).Style.Font.Bold = true;
            }
            sheet.Cell(row, colTotalValue).Value = report.TotalInventorySaleValue;
            sheet.Cell(row, colTotalValue).Style.NumberFormat.Format = "#,##0.00";
            sheet.Cell(row, colTotalValue).Style.Font.Bold = true;
            if (includeProfit)
            {
                sheet.Cell(row, colProfit).Value = report.TotalInventorySaleValue - report.TotalInventoryCost;
                sheet.Cell(row, colProfit).Style.NumberFormat.Format = "#,##0.00";
                sheet.Cell(row, colProfit).Style.Font.Bold = true;
            }

            sheet.Columns().AdjustToContents();
            sheet.Column(colName).Width = 36;
            var borderRange = sheet.Range(1, 1, row, lastCol);
            borderRange.Style.Border.TopBorder = XLBorderStyleValues.Thin;
            borderRange.Style.Border.BottomBorder = XLBorderStyleValues.Thin;
            borderRange.Style.Border.LeftBorder = XLBorderStyleValues.Thin;
            borderRange.Style.Border.RightBorder = XLBorderStyleValues.Thin;
            sheet.Range(1, 1, 1, lastCol).SetAutoFilter();

            var stream = new MemoryStream();
            workbook.SaveAs(stream);
            stream.Position = 0;
            var contentType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
            var fileName = (isRu ? "sklad_" : "ombor_") +
                $"{TimeZoneInfo.ConvertTimeFromUtc(DateTime.UtcNow, _tashkent):yyyyMMdd_HHmmss}.xlsx";

            _logger.LogInformation("Successfully exported warehouse report to Excel ({Count} products)", inventory.Count);
            return File(stream, contentType, fileName);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error exporting warehouse report to Excel");
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
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportDailyReportToPdf([FromQuery] DateTime date, [FromQuery] string lang = "uz")
    {
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var pdfBytes = await _reportService.ExportDailyReportToPdfAsync(utcDate, userRole, lang);

        return File(
            pdfBytes,
            "application/pdf",
            $"daily_report_{date:yyyyMMdd}.pdf"
        );
    }

    [HttpGet("period/export-pdf")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportPeriodReportToPdf(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end,
        [FromQuery] string lang = "uz")
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var pdfBytes = await _reportService.ExportPeriodReportToPdfAsync(request, userRole, lang);

        return File(
            pdfBytes,
            "application/pdf",
            $"period_report_{start:yyyyMMdd}_{end:yyyyMMdd}.pdf"
        );
    }

    [HttpGet("comprehensive/export-pdf")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ReportsExport)]
    public async Task<IActionResult> ExportComprehensiveReportToPdf([FromQuery] DateTime date, [FromQuery] string lang = "uz")
    {
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var pdfBytes = await _reportService.ExportComprehensiveReportToPdfAsync(utcDate, userRole, lang);

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
    [EnableRateLimiting("export")]
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

}