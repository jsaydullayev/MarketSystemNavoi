using ClosedXML.Excel;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Extensions;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Application.Interfaces;
using System.Linq.Expressions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

/// <summary>
/// M5 — ReportService is intentionally <c>partial</c> so future PRs can lift
/// its three natural sub-modules into separate files without renaming the
/// type or touching every call-site:
///   • <c>ReportService.Pdf.cs</c> — the static PDF renderers and the
///     <c>PdfTheme</c> palette (~700 lines, pure rendering, already
///     unit-tested in isolation via PdfExportTests).
///   • <c>ReportService.Dashboard.cs</c> — GetWeeklySeriesAsync,
///     GetTopProductsAsync, GetStaffPerformanceAsync, GetMyPerformanceAsync.
///   • <c>ReportService.cs</c> (this file) — the report-data fetchers
///     (daily, period, comprehensive, profit summary, cash balance).
/// The split is deferred — a 2200-line file move is high-touch and the
/// current organisation is workable. The partial declaration unblocks
/// incremental moves whenever someone has a quiet PR.
/// </summary>
public partial class ReportService : IReportService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ILogger<ReportService> _logger;
    private readonly ITashkentClock _clock;
    private readonly IAppDbContext _context;

    // License setup lives in the STATIC constructor so it runs before any
    // Excel/PDF is produced — including via the static PDF renderers
    // (RenderInvoicePdf / RenderSalesListPdf), which may be reached without an
    // instance ever being created (e.g. from tests).
    static ReportService()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public ReportService(
        IUnitOfWork unitOfWork,
        ICurrentMarketService currentMarketService,
        ILogger<ReportService> logger,
        ITashkentClock clock,
        IAppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _currentMarketService = currentMarketService;
        _logger = logger;
        _clock = clock;
        _context = context;
    }

    public async Task<DailyReportDto> GetDailyReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt < end && z.MarketId == marketId,
            cancellationToken);

        return CalculateReport(sales, zakups, start, end, userRole);
    }

    public async Task<DailySaleItemsResponseDto> GetDailySaleItemsAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        // ✅ Batch fetch all ordinary products to avoid N+1 query (faqat oddiy mahsulotlar uchun)
        var ordinaryProductIds = sales
            .SelectMany(s => s.SaleItems)
            .Where(si => !si.IsExternal && si.ProductId.HasValue)
            // The Where above already guarantees HasValue; the null-forgiving
            // `!` just tells the compiler what the filter cannot express.
            .Select(si => si.ProductId!.Value)
            .Distinct()
            .ToList();

        var products = new Dictionary<Guid, Product>();
        if (ordinaryProductIds.Any())
        {
            var productList = await _unitOfWork.Products.FindAsync(
                p => ordinaryProductIds.Contains(p.Id) && p.MarketId == marketId,
                cancellationToken);
            foreach (var p in productList)
            {
                products[p.Id] = p;
            }
        }

        bool includeProfit = userRole == Role.Owner.ToString();

        var allItems = new List<DailySaleItemDto>();

        _logger.LogInformation("[GetDailySaleItems] Processing {Count} sales for {Date}", sales.Count(), start.ToString("yyyy-MM-dd"));

        foreach (var sale in sales)
        {
            foreach (var item in sale.SaleItems)
            {
                // ✅ ISEXTERNAL SHARTI - Product name va CostPrice
                string productName;
                decimal costPrice;
                string unit = "";

                if (!item.IsExternal)
                {
                    // Oddiy mahsulot. A non-external item should always carry
                    // a ProductId, but the column is nullable — guard so a
                    // bad row is skipped instead of throwing.
                    if (!item.ProductId.HasValue ||
                        !products.TryGetValue(item.ProductId.Value, out var product))
                        continue;

                    productName = product.Name;
                    costPrice = item.CostPrice;
                    unit = product.GetUnitName();
                }
                else
                {
                    // Tashqi mahsulot
                    productName = item.ExternalProductName ?? "Tashqi mahsulot";
                    costPrice = item.ExternalCostPrice;
                    // Unit bo'sh qoldiriladi
                }
                var quantity = item.Quantity;

                if (quantity % 1 != 0)
                {
                    _logger.LogInformation("Double quantity: {ProductName} - {Quantity} ta (Sale: {SaleId})", productName, quantity, sale.Id);
                }

                var salePrice = item.SalePrice;
                var totalCost = costPrice * quantity;
                var totalRevenue = salePrice * quantity;
                decimal? profit = includeProfit ? totalRevenue - totalCost : null;

                allItems.Add(new DailySaleItemDto(
                    productName,
                    quantity,
                    costPrice,
                    salePrice,
                    totalCost,
                    totalRevenue,
                    profit
                ));
            }
        }

        var sortedItems = allItems.OrderByDescending(i => i.Quantity).ToList();

        return new DailySaleItemsResponseDto(
            start,
            sortedItems
        );
    }

    public async Task<PeriodReportDto> GetPeriodReportAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Use < instead of <= to include the entire end day (up to 23:59:59.999)
        var endDateTime = request.EndDate.AddDays(1);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt < endDateTime && s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt < endDateTime && z.MarketId == marketId,
            cancellationToken);

        var report = CalculateReport(sales, zakups, request.StartDate, request.EndDate, userRole);

        decimal averageSale = report.TotalTransactions > 0
            ? report.TotalSales / report.TotalTransactions
            : 0;

        return new PeriodReportDto(
            request.StartDate,
            request.EndDate,
            report.TotalSales,
            report.TotalPaidSales,
            report.TotalDebtSales,
            report.TotalZakup,
            report.Profit,
            report.NetIncome,
            report.TotalTransactions,
            averageSale,
            report.PaymentBreakdown
        );
    }

    public async Task<ComprehensiveReportDto> GetComprehensiveReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        // Get daily sales with SaleItems and Payments
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        // Get zakups
        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt < end && z.MarketId == marketId,
            cancellationToken);

        // P6 — Projection o'rniga to'liq entity yuklash:
        // 10K tovar × ~20 ustun + Category navigation = ~100MB memory.
        // Select projection faqat kerakli 7 ustunni oladi → ~15MB.
        var productProjections = await _context.Products
            .AsNoTracking()
            .Where(p => p.MarketId == marketId)
            .Select(p => new
            {
                p.Id,
                p.Name,
                p.Quantity,
                p.MinThreshold,
                p.CostPrice,
                p.SalePrice,
                p.MinSalePrice,
                p.Unit,
                CategoryName = p.Category != null ? p.Category.Name : (string?)null,
            })
            .ToListAsync(cancellationToken);

        // Calculate daily report
        var dailyReport = CalculateReport(sales, zakups, start, end);

        // Calculate seller reports - ONLY FOR OWNER
        var sellerReports = new List<SellerReportDto>();

        // Only Owner can see seller reports
        if (userRole == Role.Owner.ToString())
        {
            // Get all users for seller reports (filtered by market)
            var users = await _unitOfWork.Users.FindAsync(
                u => u.MarketId == marketId,
                cancellationToken);

            foreach (var user in users.Where(u => u.Role == Role.Seller || u.Role == Role.Admin || u.Role == Role.Owner))
            {
                var userSales = sales.Where(s => s.SellerId == user.Id).ToList();
                if (userSales.Any())
                {
                    decimal totalSales = userSales.Sum(s => s.TotalAmount);
                    decimal totalProfit = 0;

                    foreach (var sale in userSales)
                    {
                        foreach (var item in sale.SaleItems)
                        {
                            // ✅ ISEXTERNAL SHARTI - Effective cost price
                            decimal costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                            var itemCost = costPrice * item.Quantity;
                            var itemRevenue = item.SalePrice * item.Quantity;
                            totalProfit += itemRevenue - itemCost;
                        }
                    }

                    sellerReports.Add(new SellerReportDto(
                        user.Id,
                        user.FullName,
                        totalSales,
                        totalProfit,
                        userSales.Count
                    ));
                }
            }
        }

        // Calculate inventory report
        var inventoryReport = new List<InventoryReportDto>();
        decimal totalInventoryCost = 0;
        decimal totalInventorySaleValue = 0;

        // Determine if profit should be included (Owner only)
        bool includeProfit = userRole == Role.Owner.ToString();

        // Calculate inventory statistics
        int productCount = productProjections.Count;
        int lowStockCount = productProjections.Count(p => p.Quantity <= p.MinThreshold && p.Quantity > 0);
        int outOfStockCount = productProjections.Count(p => p.Quantity <= 0);

        foreach (var product in productProjections)
        {
            var totalCostValue = product.Quantity * product.CostPrice;
            var totalSaleValue = product.Quantity * product.SalePrice;
            decimal? potentialProfit = includeProfit ? totalSaleValue - totalCostValue : null;

            totalInventoryCost += totalCostValue;
            totalInventorySaleValue += totalSaleValue;

            var unitName = product.Unit switch
            {
                UnitType.Kilogram => "kg",
                UnitType.Meter    => "m",
                _                 => "dona",
            };

            inventoryReport.Add(new InventoryReportDto(
                product.Id,
                product.Name,
                product.Quantity,
                product.CostPrice,
                product.SalePrice,
                product.MinSalePrice,
                totalCostValue,
                totalSaleValue,
                potentialProfit,
                product.CategoryName,
                unitName
            ));
        }

        return new ComprehensiveReportDto(
            date,
            dailyReport,
            sellerReports,
            inventoryReport,
            totalInventoryCost,
            totalInventorySaleValue,
            productCount,
            totalInventoryCost,
            lowStockCount,
            outOfStockCount
        );
    }

    private static DailyReportDto CalculateReport(
        IEnumerable<Sale> sales,
        IEnumerable<Zakup> zakups,
        DateTime start,
        DateTime end,
        string? userRole = null)
    {
        // ⭐ PROFESSIONAL VARIANT - Separate Paid and Debt sales
        decimal totalPaidSales = 0;      // To'langan savdolar
        decimal totalDebtSales = 0;      // Qarzga sotilgan
        decimal totalAllSales = 0;       // Jami savdo (paid + debt)
        decimal totalCost = 0;           // Cost of goods sold
        decimal totalProfit = 0;         // Actual profit from sales
        int totalTransactions = sales.Count();

        // Determine if profit should be included (Owner only)
        bool includeProfit = userRole == Role.Owner.ToString();

        // Calculate payment breakdown - separate positive and negative payments
        var paymentBreakdown = new Dictionary<string, decimal>();
        var paymentCounts = new Dictionary<string, int>();
        decimal totalRefunds = 0;  // Qaytarilgan summa

        // Calculate from sales and their items
        foreach (var sale in sales)
        {
            // IMPORTANT: Use sale.PaidAmount directly instead of summing payments
            // This ensures credit applications (which don't create payment records)
            // are not incorrectly counted in reports
            var paidAmount = sale.PaidAmount;
            var debtAmount = sale.TotalAmount - paidAmount;

            // Add to appropriate categories
            totalPaidSales += paidAmount;
            totalDebtSales += debtAmount;
            totalAllSales += sale.TotalAmount;

            // Calculate cost and profit from ALL sale items (both paid and debt)
            foreach (var item in sale.SaleItems)
            {
                // ✅ ISEXTERNAL SHARTI - EFFECTIVE COST PRICE
                decimal costPrice = item.IsExternal
                    ? item.ExternalCostPrice
                    : item.CostPrice;

                var itemCost = costPrice * item.Quantity;
                var itemRevenue = item.SalePrice * item.Quantity;
                var itemProfit = itemRevenue - itemCost;

                totalCost += itemCost;
                if (includeProfit)
                {
                    totalProfit += itemProfit;
                }
            }

            // Accumulate payment breakdown from payments
            foreach (var payment in sale.Payments)
            {
                if (payment.Amount < 0)
                {
                    // Negative payment = refund/return
                    totalRefunds += Math.Abs(payment.Amount);
                }
                else
                {
                    // Positive payment = actual payment
                    var paymentType = payment.PaymentType.ToString();
                    if (!paymentBreakdown.ContainsKey(paymentType))
                    {
                        paymentBreakdown[paymentType] = 0;
                        paymentCounts[paymentType] = 0;
                    }
                    paymentBreakdown[paymentType] += payment.Amount;
                    paymentCounts[paymentType]++;
                }
            }
        }

        decimal totalZakup = zakups.Sum(z => z.Quantity * z.CostPrice);

        // Net income = Profit - Operating expenses (currently 0)
        decimal? netIncome = includeProfit ? totalProfit : null;
        decimal? profit = includeProfit ? totalProfit : null;

        // Convert to list of DTOs
        var paymentBreakdownList = paymentBreakdown
            .Select(kvp => new PaymentBreakdownDto(
                kvp.Key,
                kvp.Value,
                paymentCounts[kvp.Key]
            ))
            .ToList();

        // Add "Qarz" to payment breakdown if there is any debt sales
        if (totalDebtSales > 0)
        {
            paymentBreakdownList.Add(new PaymentBreakdownDto(
                "Qarz",
                totalDebtSales,
                0  // Count doesn't apply to debt
            ));
        }

        // Add "Qaytarilgan" to payment breakdown if there are any refunds
        if (totalRefunds > 0)
        {
            paymentBreakdownList.Add(new PaymentBreakdownDto(
                "Qaytarilgan",
                -totalRefunds,  // Show as negative to indicate deduction
                0  // Count doesn't apply to refunds
            ));
        }

        return new DailyReportDto(
            start,
            totalAllSales,
            totalPaidSales,
            totalDebtSales,
            totalZakup,
            profit,
            netIncome,
            totalTransactions,
            paymentBreakdownList
        );
    }

    public async Task<ProfitSummaryDto> GetProfitSummaryAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var todayLocal = _clock.TodayLocal;

        // Today (Tashkent calendar day -> UTC range)
        var (todayStart, todayEnd) = GetUtcDateRange(todayLocal);

        // Week = rolling 7-day window (last 7 days including today), anchored to
        // Tashkent local midnight. Rolling-7d matches user intuition
        // ("shu hafta = oxirgi 7 kun") and avoids the Sunday/Monday reset that
        // an ISO-week anchor causes.
        var weekStart = ToUtcDate(todayLocal.AddDays(-6));
        var monthStart = ToUtcDate(new DateTime(todayLocal.Year, todayLocal.Month, 1));

        // P2 — the previous version loaded every Sale + SaleItem for today,
        // week, month, AND all-time into memory (the all-time fetch is
        // O(history) — fatal once a market has a year of data) just to sum
        // profit. Replace with one DB-side aggregation that emits a single
        // SQL statement with four conditional SUMs.
        //
        // EF translates the CASE WHEN into PG's FILTER clause. Profit per
        // item = (SalePrice − effectiveCost) × Quantity, where effectiveCost
        // is ExternalCostPrice for tashqi mahsulot and CostPrice for normal
        // products. allTime always passes the date filter (constant true).
        var summary = await _context.SaleItems
            .AsNoTracking()
            .Where(si => si.Sale.MarketId == marketId
                      && si.Sale.Status != SaleStatus.Cancelled
                      && si.Sale.Status != SaleStatus.Draft)
            .GroupBy(_ => 1)
            .Select(g => new
            {
                Today = g.Sum(si =>
                    si.Sale.CreatedAt >= todayStart && si.Sale.CreatedAt < todayEnd
                        ? ((si.IsExternal ? si.SalePrice - si.ExternalCostPrice
                                          : si.SalePrice - si.CostPrice) * si.Quantity)
                        : 0m),
                Week = g.Sum(si =>
                    si.Sale.CreatedAt >= weekStart
                        ? ((si.IsExternal ? si.SalePrice - si.ExternalCostPrice
                                          : si.SalePrice - si.CostPrice) * si.Quantity)
                        : 0m),
                Month = g.Sum(si =>
                    si.Sale.CreatedAt >= monthStart
                        ? ((si.IsExternal ? si.SalePrice - si.ExternalCostPrice
                                          : si.SalePrice - si.CostPrice) * si.Quantity)
                        : 0m),
                All = g.Sum(si =>
                    (si.IsExternal ? si.SalePrice - si.ExternalCostPrice
                                   : si.SalePrice - si.CostPrice) * si.Quantity),
            })
            .FirstOrDefaultAsync(cancellationToken);

        return new ProfitSummaryDto(
            summary?.Today ?? 0m,
            summary?.Week ?? 0m,
            summary?.Month ?? 0m,
            summary?.All ?? 0m);
    }

    public async Task<CashBalanceDto> GetCashBalanceAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // "Today" anchored to Tashkent calendar day (00:00–24:00 local), not UTC.
        var (todayStart, todayEnd) = GetUtcDateRange(_clock.TodayLocal);

        // Get all payments for today
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= todayStart && s.CreatedAt < todayEnd &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "Payments");

        decimal cashInRegister = 0;
        decimal cardPayments = 0;
        decimal totalRefunds = 0;

        foreach (var sale in sales)
        {
            foreach (var payment in sale.Payments)
            {
                if (payment.Amount < 0)
                {
                    // Negative payment = refund, subtract from the appropriate balance
                    if (payment.PaymentType == PaymentType.Cash)
                    {
                        cashInRegister += payment.Amount;  // This will subtract since payment.Amount is negative
                    }
                    else if (payment.PaymentType == PaymentType.Terminal)
                    {
                        cardPayments += payment.Amount;  // This will subtract
                    }
                    totalRefunds += Math.Abs(payment.Amount);
                }
                else
                {
                    // Positive payment = actual payment
                    if (payment.PaymentType == PaymentType.Cash)
                    {
                        cashInRegister += payment.Amount;
                    }
                    else if (payment.PaymentType == PaymentType.Terminal)
                    {
                        cardPayments += payment.Amount;
                    }
                }
            }
        }

        return new CashBalanceDto(
            cashInRegister,
            cardPayments,
            cashInRegister + cardPayments
        );
    }

    public async Task<DashboardSummaryDto> GetOwnerDashboardSummaryAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var now = DateTime.UtcNow;
        var overdueCutoff = now.AddDays(-14);

        // These five COUNT/SUM queries replace what the client used to do by
        // downloading GetAllCustomers + GetAllProducts + GetAllDebts in full
        // and folding them on the UI isolate. Definitions are kept identical to
        // that client logic so the dashboard numbers don't shift:
        //   - customerCount: non-deleted customers (== GetAllCustomers().length)
        //   - lowStockCount: Quantity <= MinThreshold (== Product.IsLowStock;
        //     intentionally NOT filtering IsDeleted, matching GetAllProducts)
        //   - pending debts: RemainingDebt > 0
        //   - overdue: past DueDate, or (no DueDate) created > 14 days ago
        var customerCount = await _context.Customers
            .AsNoTracking()
            .CountAsync(c => c.MarketId == marketId && !c.IsDeleted, cancellationToken);

        var lowStockCount = await _context.Products
            .AsNoTracking()
            .CountAsync(p => p.MarketId == marketId && p.Quantity <= p.MinThreshold, cancellationToken);

        var pending = _context.Debts
            .AsNoTracking()
            .Where(d => d.MarketId == marketId && d.RemainingDebt > 0);

        var pendingDebtsCount = await pending.CountAsync(cancellationToken);
        var pendingDebtsTotal =
            await pending.SumAsync(d => (decimal?)d.RemainingDebt, cancellationToken) ?? 0m;
        var overdueDebtsCount = await pending.CountAsync(
            d => (d.DueDate != null && d.DueDate < now) ||
                 (d.DueDate == null && d.CreatedAt < overdueCutoff),
            cancellationToken);

        return new DashboardSummaryDto(
            customerCount,
            lowStockCount,
            pendingDebtsCount,
            pendingDebtsTotal,
            overdueDebtsCount);
    }

    public async Task<DailySalesListDto> GetDailySalesListAsync(
        DateTime date,
        string? userRole = null,
        Guid? userId = null,
        DateTime? endDate = null,
        CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        // Single day when endDate is null; otherwise the inclusive [date,
        // endDate] Tashkent-day range — start of the first day, end of the last.
        var (start, _) = GetUtcDateRange(date);
        var (_, end) = GetUtcDateRange(endDate ?? date);

        Expression<Func<Sale, bool>> salesQuery = s => s.CreatedAt >= start && s.CreatedAt < end &&
                              s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                              s.MarketId == marketId &&
                              (userRole != Role.Seller.ToString() || s.SellerId == userId);

        var sales = await _unitOfWork.Sales.FindAsync(
            salesQuery,
            cancellationToken,
            includeProperties: "SaleItems,Payments,Seller,Customer");

        var salesListItems = new List<DailySalesListItemDto>();

        decimal totalPaidSales = 0;
        decimal totalDebtSales = 0;
        decimal totalAllSales = 0;

        bool includeProfit = userRole == Role.Owner.ToString();

        foreach (var sale in sales)
        {
            var paidAmount = sale.PaidAmount;
            var debtAmount = sale.TotalAmount - paidAmount;

            totalPaidSales += paidAmount;
            totalDebtSales += debtAmount;
            totalAllSales += sale.TotalAmount;

            decimal? profit = null;
            if (includeProfit)
            {
                profit = 0;
                var paidRatio = sale.TotalAmount > 0 ? paidAmount / sale.TotalAmount : 0;

                foreach (var item in sale.SaleItems)
                {
                    // ✅ ISEXTERNAL SHARTI - Effective cost price
                    decimal costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                    var itemCost = costPrice * item.Quantity;
                    var itemRevenue = item.SalePrice * item.Quantity;
                    var itemProfit = itemRevenue - itemCost;

                    profit += itemProfit * paidRatio;
                }
            }

            // Check if this sale has any refund (negative) payments
            var hasRefunds = sale.Payments.Any(p => p.Amount < 0);

            // Determine payment type - if there are refunds, show as "Qaytarilgan"
            // Otherwise show the primary payment type
            string paymentType;
            if (hasRefunds)
            {
                paymentType = "Qaytarilgan";
            }
            else
            {
                var primaryPayment = sale.Payments.FirstOrDefault(p => p.Amount > 0);
                var paymentTypeRaw = primaryPayment?.PaymentType.ToString() ?? "Cash";
                paymentType = paymentTypeRaw.ToLowerInvariant();
            }

            salesListItems.Add(new DailySalesListItemDto(
                sale.Id,
                sale.CreatedAt,
                sale.Seller?.FullName ?? "Unknown",
                sale.TotalAmount,
                paymentType,
                sale.Status.ToString(),
                profit,
                sale.Customer?.FullName
            ));
        }

        decimal? summaryProfit = null;
        if (includeProfit && salesListItems.Any())
        {
            summaryProfit = salesListItems.Sum(s => s.Profit ?? 0);
        }

        return new DailySalesListDto(
            start,
            salesListItems,
            totalAllSales,     
            totalPaidSales,    
            totalDebtSales,    
            salesListItems.Count,
            summaryProfit
        );
    }

    private static decimal CalculateProfitFromSales(IEnumerable<Sale> sales)
    {
        decimal profit = 0;

        foreach (var sale in sales)
        {
            foreach (var item in sale.SaleItems)
            {
                // ✅ ISEXTERNAL SHARTI - Effective cost price
                var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                var itemCost = costPrice * item.Quantity;
                var itemRevenue = item.SalePrice * item.Quantity;
                profit += itemRevenue - itemCost;
            }
        }

        return profit;
    }

    public async Task<MonthlyCategorySalesResponseDto> GetMonthlyCategorySalesAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var start = new DateTime(date.Year, date.Month, 1, 0, 0, 0, DateTimeKind.Utc);
        var end = start.AddMonths(1);

        var categories = await _unitOfWork.ProductCategories.FindAsync(
            c => c.MarketId == marketId && c.IsActive && !c.IsDeleted,
            cancellationToken);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId,
            cancellationToken);
        var productDict = products.ToDictionary(p => p.Id);

        bool includeProfit = userRole == Role.Owner.ToString();
        var categorySales = new Dictionary<int, CategorySalesDto>();

        foreach (var category in categories)
        {
            categorySales[category.Id] = new CategorySalesDto(category.Id, category.Name, 0, 0, includeProfit ? 0 : null);
        }

        int otherCategoryId = -1;
        categorySales[otherCategoryId] = new CategorySalesDto(otherCategoryId, "Boshqa", 0, 0, includeProfit ? 0 : null);

        decimal totalSalesOverall = 0;
        decimal totalProfitOverall = 0;

        foreach (var sale in sales)
        {
            foreach (var item in sale.SaleItems)
            {
                // ✅ ISEXTERNAL SHARTI - Product va CostPrice olish
                Product? product = null;
                int catId = otherCategoryId;

                if (!item.IsExternal && item.ProductId.HasValue)
                {
                    product = productDict.GetValueOrDefault(item.ProductId.Value);
                    catId = product?.CategoryId ?? otherCategoryId;
                }

                // Get or create category sales
                if (!categorySales.TryGetValue(catId, out var currentCat))
                {
                    catId = otherCategoryId;
                    currentCat = categorySales[catId];
                }

                decimal itemSales = item.Quantity * item.SalePrice;
                // ✅ Effective cost price
                var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                decimal itemProfit = (item.SalePrice - costPrice) * item.Quantity;

                decimal? newTotalProfit = includeProfit ? (currentCat.TotalProfit ?? 0) + itemProfit : null;

                categorySales[catId] = new CategorySalesDto(
                    currentCat.CategoryId,
                    currentCat.CategoryName,
                    currentCat.TotalSales + itemSales,
                    currentCat.TotalQuantity + item.Quantity,
                    newTotalProfit
                );

                totalSalesOverall += itemSales;
                if (includeProfit)
                {
                    totalProfitOverall += itemProfit;
                }
            }
        }

        if (categorySales[otherCategoryId].TotalSales == 0)
        {
            categorySales.Remove(otherCategoryId);
        }

        return new MonthlyCategorySalesResponseDto(
            date,
            categorySales.Values.ToList(),
            totalSalesOverall,
            includeProfit ? totalProfitOverall : null
        );
    }

    public async Task<List<SaleWithItemsDto>> GetSalesWithItemsAsync(
        DateTime startDate,
        DateTime endDate,
        string? userRole = null,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var start = ToUtcDate(startDate);
        var end = ToUtcDate(endDate.AddDays(1));

        // Use IAppDbContext for complex query with proper includes
        // This is done via the unit of work's context if accessible
        // For now, use the repository and get products in batch
        Expression<Func<Sale, bool>> salesQuery = s => s.CreatedAt >= start && s.CreatedAt < end &&
                              s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                              s.MarketId == marketId &&
                              (userRole != Role.Seller.ToString() || s.SellerId == userId);

        var sales = await _unitOfWork.Sales.FindAsync(
            salesQuery,
            cancellationToken,
            includeProperties: "SaleItems,Payments,Seller,Customer");

        // Get all products in batch (N+1 solution)
        var allProductIds = sales.SelectMany(s => s.SaleItems).Select(si => si.ProductId).Distinct().ToList();
        var products = new Dictionary<Guid, string>();
        if (allProductIds.Any())
        {
            var productList = await _unitOfWork.Products.FindAsync(
                p => allProductIds.Contains(p.Id) && p.MarketId == marketId,
                cancellationToken);
            foreach (var p in productList)
            {
                products[p.Id] = p.Name;
            }
        }

        bool includeProfit = userRole == Role.Owner.ToString();
        var salesWithItems = new List<SaleWithItemsDto>();

        foreach (var sale in sales)
        {
            // Get primary payment type (first non-refund payment, or first payment)
            var primaryPayment = sale.Payments.FirstOrDefault(p => p.Amount > 0);
            var hasRefunds = sale.Payments.Any(p => p.Amount < 0);

            string? paymentType;
            if (hasRefunds)
            {
                paymentType = "Qaytarilgan";
            }
            else
            {
                paymentType = primaryPayment?.PaymentType.ToString().ToLowerInvariant() ?? "cash";
            }

            // Calculate profit if owner
            decimal? profit = null;
            if (includeProfit)
            {
                profit = 0;
                var paidRatio = sale.TotalAmount > 0 ? sale.PaidAmount / sale.TotalAmount : 0;

                foreach (var item in sale.SaleItems)
                {
                    // ✅ ISEXTERNAL SHARTI - Effective cost price
                    var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                    var itemCost = costPrice * item.Quantity;
                    var itemRevenue = item.SalePrice * item.Quantity;
                    var itemProfit = itemRevenue - itemCost;

                    profit += itemProfit * paidRatio;
                }
            }

            // Create sale items DTOs with product names from dictionary
            var items = sale.SaleItems.Select(item => {
                // ✅ ISEXTERNAL SHARTI - Product name olish
                string productName;
                if (!item.IsExternal)
                {
                    productName = item.ProductId.HasValue && products.TryGetValue(item.ProductId.Value, out var name) ? name : "Unknown";
                }
                else
                {
                    productName = item.ExternalProductName ?? "Tashqi mahsulot";
                }
                // ✅ Effective cost price
                var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                return new SaleItemExportDto(
                    item.ProductId?.ToString() ?? "",
                    productName,
                    item.Quantity,
                    costPrice,
                    item.SalePrice,
                    item.SalePrice * item.Quantity,
                    includeProfit ? (item.SalePrice - costPrice) * item.Quantity : null,
                    item.Comment
                );
            }).ToList();

            salesWithItems.Add(new SaleWithItemsDto(
                sale.Id,
                sale.CreatedAt,
                sale.Seller?.FullName ?? "Unknown",
                sale.Customer?.FullName,
                sale.TotalAmount,
                sale.PaidAmount,
                paymentType,
                sale.Status.ToString(),
                profit,
                items
            ));
        }

        return salesWithItems;
    }

    public async Task<byte[]> ExportSalesListToPdfAsync(DateTime? startDate, DateTime? endDate, string? userRole = null, string lang = "uz", CancellationToken cancellationToken = default)
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get all sales if no date range specified
        var start = startDate.HasValue ? ToUtcDate(startDate.Value) : DateTime.MinValue;
        var end = endDate.HasValue ? ToUtcDate(endDate.Value.AddDays(1)) : DateTime.UtcNow.AddDays(1);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                 s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments,Seller,Customer");

        // Get all products for the sale items
        var allProductIds = sales.SelectMany(s => s.SaleItems).Select(si => si.ProductId).Distinct().ToList();
        var products = new Dictionary<Guid, string>();
        if (allProductIds.Any())
        {
            var productList = await _unitOfWork.Products.FindAsync(
                p => allProductIds.Contains(p.Id) && p.MarketId == marketId,
                cancellationToken);
            foreach (var p in productList)
            {
                products[p.Id] = p.Name;
            }
        }

        // Owner role check - null or non-owner means no profit visibility.
        // Cost price is visible to Owner AND Admin (data.costPrice), but never
        // to a Seller — so the Xarid column is masked for Sellers.
        bool includeProfit = !string.IsNullOrEmpty(userRole) && userRole == Role.Owner.ToString();
        bool includeCost = userRole is "Owner" or "Admin";
        decimal totalSales = 0;
        decimal totalProfit = 0;

        var reportItems = new List<SalesReportItem>();
        int itemNumber = 1;

        // Sort sales by date descending
        var sortedSales = sales.OrderByDescending(s => s.CreatedAt).ToList();

        foreach (var sale in sortedSales)
        {
            // Calculate paid ratio for debt sales (only count profit for paid portion)
            decimal paidRatio = sale.TotalAmount > 0
                ? sale.PaidAmount / sale.TotalAmount
                : 1;

            foreach (var item in sale.SaleItems)
            {
                // ✅ ISEXTERNAL SHARTI - Product name olish
                string productName;
                decimal costPrice;

                if (!item.IsExternal)
                {
                    productName = item.ProductId.HasValue && products.TryGetValue(item.ProductId.Value, out var name) ? name : "Unknown";
                    costPrice = item.CostPrice;
                }
                else
                {
                    productName = item.ExternalProductName ?? "Tashqi mahsulot";
                    costPrice = item.ExternalCostPrice;
                }

                // Full item profit
                decimal fullItemProfit = (item.SalePrice - costPrice) * item.Quantity;
                // Adjusted profit based on paid ratio (consistent with Excel export)
                decimal adjustedProfit = fullItemProfit * paidRatio;

                totalSales += item.TotalPrice;
                if (includeProfit)
                {
                    totalProfit += adjustedProfit;
                }

                reportItems.Add(new SalesReportItem(
                    itemNumber++,
                    sale.CreatedAt,
                    sale.Customer?.FullName ?? L("Mijoz yo'q", "Без клиента"),
                    sale.Seller?.FullName ?? L("Noma'lum", "Неизвестно"),
                    productName,
                    item.Quantity,
                    costPrice,  // ✅ Effective cost price (ExternalCostPrice for external products)
                    item.SalePrice,
                    item.TotalPrice,
                    includeProfit ? adjustedProfit : null,
                    sale.Status.ToString()
                ));
            }
        }

        
        try
        {
            _logger.LogInformation($"[ExportSalesListToPdfAsync] Starting PDF generation for {reportItems.Count} items");
            return RenderSalesListPdf(reportItems, startDate, endDate, includeProfit, includeCost, totalSales, totalProfit, _clock.NowLocal, lang);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Sales list PDF generation failed: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Renders the sales-list report as a branded A4 *landscape* PDF (minimalist design).
    /// No zebra striping, hairline borders, colored text status, KPI summary strip.
    /// Pure rendering — unit-testable.
    /// </summary>
    internal static byte[] RenderSalesListPdf(
        IReadOnlyList<SalesReportItem> items,
        DateTime? startDate,
        DateTime? endDate,
        bool includeProfit,
        bool includeCost,
        decimal totalSales,
        decimal totalProfit,
        DateTime generatedAtLocal,
        string lang = "uz")
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var period = startDate.HasValue && endDate.HasValue
            ? $"{startDate.Value:dd.MM.yyyy} — {endDate.Value:dd.MM.yyyy}"
            : L("Barcha vaqt", "За всё время");

        int count = items.Count;
        decimal avg = count > 0 ? totalSales / count : 0;

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4.Landscape());
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(9).FontColor(PdfTheme.Ink));

                // ── Header: oq fon, brand belgisi, ink chiziq ──
                page.Header().PaddingHorizontal(28).PaddingTop(22).PaddingBottom(14)
                    .BorderBottom(2).BorderColor(PdfTheme.Ink).Row(row =>
                {
                    row.AutoItem().Element(c => BrandMark(c, "B"));
                    row.RelativeItem().PaddingLeft(13).Column(col =>
                    {
                        col.Item().Text(L("Sotuvlar hisoboti", "Отчёт о продажах"))
                            .FontSize(18).Bold().FontColor(PdfTheme.Ink);
                        col.Item().PaddingTop(2).Text(period)
                            .FontSize(10).FontColor(PdfTheme.Muted);
                    });
                    row.ConstantItem(190).AlignRight().AlignBottom()
                        .Text($"{L("Yaratilgan: ", "Создан: ")}{generatedAtLocal:dd.MM.yyyy HH:mm}")
                        .FontSize(9).FontColor(PdfTheme.Muted);
                });

                page.Content().PaddingHorizontal(28).PaddingTop(16).Column(column =>
                {
                    // ── KPI xulosa strip ──
                    column.Item().PaddingBottom(18).Row(row =>
                    {
                        SummaryKpi(row, L("Jami savdo", "Общая выручка"),
                            $"{totalSales:N0}", L("so'm", "сум"), PdfTheme.Ink, first: true);
                        if (includeProfit)
                            SummaryKpi(row, L("Sof foyda", "Чистая прибыль"),
                                $"{totalProfit:N0}", L("so'm", "сум"),
                                totalProfit >= 0 ? PdfTheme.Success : PdfTheme.Danger,
                                first: false, labelAccent: true);
                        SummaryKpi(row, L("Cheklar soni", "Кол-во чеков"),
                            $"{count:N0}", "", PdfTheme.Ink, first: false);
                        SummaryKpi(row, L("O'rtacha chek", "Средний чек"),
                            $"{avg:N0}", L("so'm", "сум"), PdfTheme.Ink, first: false);
                    });

                    if (count == 0)
                    {
                        column.Item().AlignCenter().PaddingTop(50)
                            .Text(L("Tanlangan davr uchun ma'lumot topilmadi", "Нет данных за выбранный период"))
                            .FontSize(11).FontColor(PdfTheme.Muted);
                        return;
                    }

                    // ── Jadval ──
                    column.Item().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.ConstantColumn(26);   // #
                            columns.ConstantColumn(82);   // Sana
                            columns.RelativeColumn(2);    // Mijoz
                            columns.RelativeColumn(2);    // Sotuvchi
                            columns.RelativeColumn(2.4f); // Mahsulot
                            columns.ConstantColumn(55);   // Miqdor
                            if (includeCost) columns.ConstantColumn(72); // Xarid
                            columns.ConstantColumn(72);   // Narx
                            columns.ConstantColumn(90);   // Jami
                            if (includeProfit) columns.ConstantColumn(78); // Foyda
                            columns.ConstantColumn(96);   // Holat
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(SalesHeadCell).Text("#");
                            header.Cell().Element(SalesHeadCell).Text(L("SANA", "ДАТА"));
                            header.Cell().Element(SalesHeadCell).Text(L("MIJOZ", "КЛИЕНТ"));
                            header.Cell().Element(SalesHeadCell).Text(L("SOTUVCHI", "ПРОДАВЕЦ"));
                            header.Cell().Element(SalesHeadCell).Text(L("MAHSULOT", "ТОВАР"));
                            header.Cell().Element(SalesHeadCell).AlignRight().Text(L("MIQDOR", "КОЛ-ВО"));
                            if (includeCost)
                                header.Cell().Element(SalesHeadCell).AlignRight().Text(L("XARID", "ЗАКУП"));
                            header.Cell().Element(SalesHeadCell).AlignRight().Text(L("NARX", "ЦЕНА"));
                            header.Cell().Element(SalesHeadCell).AlignRight().Text(L("JAMI", "СУММА"));
                            if (includeProfit)
                                header.Cell().Element(SalesHeadCell).AlignRight().Text(L("FOYDA", "ПРИБЫЛЬ"));
                            header.Cell().Element(SalesHeadCell).Text(L("HOLAT", "СТАТУС"));
                        });

                        foreach (var item in items)
                        {
                            var (statusLabel, statusColor) = SaleStatusInfo(item.Status, isRu);

                            table.Cell().Element(SalesBodyCell).Text($"{item.Number}")
                                .FontColor(PdfTheme.Faint).SemiBold();
                            table.Cell().Element(SalesBodyCell).Text(item.Date.ToString("dd.MM.yy HH:mm"))
                                .FontColor(PdfTheme.Muted);
                            table.Cell().Element(SalesBodyCell).Text(item.CustomerName).SemiBold();
                            table.Cell().Element(SalesBodyCell).Text(item.SellerName).FontColor(PdfTheme.Muted);
                            table.Cell().Element(SalesBodyCell).Text(item.ProductName);
                            table.Cell().Element(SalesBodyCell).AlignRight().Text($"{item.Quantity:N2}");
                            if (includeCost)
                                table.Cell().Element(SalesBodyCell).AlignRight().Text($"{item.CostPrice:N0}")
                                    .FontColor(PdfTheme.Muted);
                            table.Cell().Element(SalesBodyCell).AlignRight().Text($"{item.SalePrice:N0}")
                                .FontColor(PdfTheme.Muted);
                            table.Cell().Element(SalesBodyCell).AlignRight().Text($"{item.TotalPrice:N0}").Bold();
                            if (includeProfit)
                                table.Cell().Element(SalesBodyCell).AlignRight()
                                    .Text($"{item.Profit ?? 0:N0}").SemiBold()
                                    .FontColor((item.Profit ?? 0) >= 0 ? PdfTheme.Success : PdfTheme.Danger);

                            // ── STATUS: rangli qalin matn (fon/to'rtburchaksiz) ──
                            table.Cell().Element(SalesBodyCell)
                                .Text(statusLabel).FontSize(9).Bold().FontColor(statusColor);
                        }
                    });
                });

                // ── Footer ──
                page.Footer().BorderTop(1).BorderColor(PdfTheme.Line)
                    .PaddingHorizontal(28).PaddingVertical(9).Row(row =>
                {
                    row.RelativeItem().AlignMiddle().Text(t =>
                    {
                        t.Span("Strotech").FontSize(8).Bold().FontColor(PdfTheme.BrandDark);
                        t.Span(L(" tomonidan yaratildi  ·  strotech.uz", " · strotech.uz"))
                            .FontSize(8).FontColor(PdfTheme.Muted);
                    });
                    row.RelativeItem().AlignRight().AlignMiddle().Text(t =>
                    {
                        t.Span(L("Jami savdo:  ", "Общая сумма:  ")).FontSize(9).SemiBold().FontColor(PdfTheme.Muted);
                        t.Span($"{totalSales:N0}{L(" so'm", " сум")}").FontSize(10).Bold().FontColor(PdfTheme.Ink);
                        if (includeProfit)
                        {
                            t.Span(L("      Jami foyda:  ", "      Итого прибыль:  ")).FontSize(9).SemiBold().FontColor(PdfTheme.Muted);
                            t.Span($"{totalProfit:N0}{L(" so'm", " сум")}").FontSize(10).Bold()
                                .FontColor(totalProfit >= 0 ? PdfTheme.Success : PdfTheme.Danger);
                        }
                    });
                });
            });
        }).GeneratePdf();
    }

    // ── Brand belgisi (apelsin kvadrat + oq bosh harf) ──
    private static void BrandMark(IContainer c, string initial)
        => c.Width(38).Height(38).Background(PdfTheme.Brand)
            .AlignCenter().AlignMiddle()
            .Text(initial).FontSize(18).Bold().FontColor(PdfTheme.White);

    // ── KPI xulosa kartasi (chiziq bilan ajratilgan, qutisiz) ──
    private static void SummaryKpi(QuestPDF.Fluent.RowDescriptor row,
        string label, string value, string suffix, string accent, bool first, bool labelAccent = false)
    {
        row.RelativeItem().Element(e =>
        {
            var box = first
                ? e.PaddingRight(20)
                : e.BorderLeft(1).BorderColor(PdfTheme.Line).PaddingLeft(20).PaddingRight(20);
            box.Column(col =>
            {
                col.Item().Text(label.ToUpperInvariant())
                    .FontSize(8).Bold().FontColor(labelAccent ? accent : PdfTheme.Muted).LetterSpacing(0.05f);
                col.Item().PaddingTop(6).Text(t =>
                {
                    t.Span(value).FontSize(18).Bold().FontColor(accent);
                    if (!string.IsNullOrEmpty(suffix))
                        t.Span($" {suffix}").FontSize(10).FontColor(PdfTheme.Faint);
                });
            });
        });
    }

    // ── Sales-list rendering helpers ──
    private static IContainer SalesHeadCell(IContainer c)
        => c.PaddingBottom(9).PaddingHorizontal(6)
            .BorderBottom(1.5f).BorderColor(PdfTheme.Line)
            .DefaultTextStyle(x => x.FontSize(8).Bold().FontColor(PdfTheme.Muted).LetterSpacing(0.06f));

    // Fonsiz, faqat hairline, kengroq.
    private static IContainer SalesBodyCell(IContainer c)
        => c.BorderBottom(1).BorderColor(PdfTheme.Line)
            .PaddingVertical(7).PaddingHorizontal(6).AlignMiddle();

    public async Task<byte[]> ExportDailyReportToPdfAsync(DateTime date, string? userRole = null, string lang = "uz", CancellationToken cancellationToken = default)
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var report = await GetDailyReportAsync(date, userRole, cancellationToken);
        var kpis = new List<(string Label, string Value, string Accent)>
        {
            (L("Jami savdo", "Общая выручка"),   $"{report.TotalSales:N0}{L(" so'm", " сум")}",     PdfTheme.Ink),
            (L("To'langan", "Оплачено"),         $"{report.TotalPaidSales:N0}{L(" so'm", " сум")}", PdfTheme.Success),
            (L("Qarz", "Долг"),                  $"{report.TotalDebtSales:N0}{L(" so'm", " сум")}", PdfTheme.Danger),
            (L("Cheklar soni", "Кол-во чеков"),  $"{report.TotalTransactions:N0}",   PdfTheme.Ink),
            (L("Zakup", "Закуп"),                $"{report.TotalZakup:N0}{L(" so'm", " сум")}",     PdfTheme.Muted),
        };
        if (report.Profit.HasValue)
            kpis.Add((L("Sof foyda", "Чистая прибыль"), $"{report.Profit.Value:N0}{L(" so'm", " сум")}",
                report.Profit.Value >= 0 ? PdfTheme.Success : PdfTheme.Danger));

        return RenderSummaryReportPdf(L("KUNLIK HISOBOT", "ДНЕВНОЙ ОТЧЁТ"), date.ToString("dd.MM.yyyy"),
            kpis, report.PaymentBreakdown, _clock.NowLocal, lang);
    }

    public async Task<byte[]> ExportPeriodReportToPdfAsync(PeriodReportRequest request, string? userRole = null, string lang = "uz", CancellationToken cancellationToken = default)
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var report = await GetPeriodReportAsync(request, userRole, cancellationToken);
        var kpis = new List<(string Label, string Value, string Accent)>
        {
            (L("Jami savdo", "Общая выручка"),   $"{report.TotalSales:N0}{L(" so'm", " сум")}",     PdfTheme.Ink),
            (L("To'langan", "Оплачено"),         $"{report.TotalPaidSales:N0}{L(" so'm", " сум")}", PdfTheme.Success),
            (L("Qarz", "Долг"),                  $"{report.TotalDebtSales:N0}{L(" so'm", " сум")}", PdfTheme.Danger),
            (L("Cheklar soni", "Кол-во чеков"),  $"{report.TotalTransactions:N0}",   PdfTheme.Ink),
            (L("O'rtacha chek", "Средний чек"),  $"{report.AverageSale:N0}{L(" so'm", " сум")}",    PdfTheme.Ink),
            (L("Zakup", "Закуп"),                $"{report.TotalZakup:N0}{L(" so'm", " сум")}",     PdfTheme.Muted),
        };
        if (report.Profit.HasValue)
            kpis.Add((L("Sof foyda", "Чистая прибыль"), $"{report.Profit.Value:N0}{L(" so'm", " сум")}",
                report.Profit.Value >= 0 ? PdfTheme.Success : PdfTheme.Danger));

        var period = $"{request.StartDate:dd.MM.yyyy} — {request.EndDate:dd.MM.yyyy}";
        return RenderSummaryReportPdf(L("DAVRIY HISOBOT", "ОТЧЁТ ЗА ПЕРИОД"), period, kpis, report.PaymentBreakdown, _clock.NowLocal, lang);
    }

    public async Task<byte[]> ExportComprehensiveReportToPdfAsync(DateTime date, string? userRole = null, string lang = "uz", CancellationToken cancellationToken = default)
    {
        var report = await GetComprehensiveReportAsync(date, userRole, cancellationToken);
        return RenderComprehensiveReportPdf(report, date.ToString("dd.MM.yyyy"), _clock.NowLocal, lang);
    }

    /// <summary>
    /// Renders a daily/period summary report — KPI cards + payment breakdown.
    /// Pure rendering (no I/O); unit-testable via PdfExportTests.
    /// </summary>
    internal static byte[] RenderSummaryReportPdf(
        string title, string period,
        IReadOnlyList<(string Label, string Value, string Accent)> kpis,
        IReadOnlyList<PaymentBreakdownDto> payments,
        DateTime generatedAtLocal,
        string lang = "uz")
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(10).FontColor(PdfTheme.Ink));

                page.Header().Element(h => ReportHeaderBand(h, title, period, isRu, generatedAtLocal));

                page.Content().PaddingHorizontal(32).PaddingTop(22).Column(column =>
                {
                    column.Spacing(20);

                    foreach (var chunk in kpis.Chunk(3))
                    {
                        column.Item().Row(row =>
                        {
                            row.Spacing(12);
                            foreach (var k in chunk) KpiCard(row, k.Label, k.Value, k.Accent);
                            for (int p = chunk.Length; p < 3; p++) row.RelativeItem();
                        });
                    }

                    if (payments.Count > 0)
                        column.Item().Column(sec =>
                        {
                            sec.Item().PaddingBottom(6).Text(L("TO'LOV TURLARI", "ТИПЫ ОПЛАТЫ"))
                                .FontSize(11).Bold().FontColor(PdfTheme.BrandDark);
                            sec.Item().Element(e => PaymentBreakdownTable(e, payments, isRu));
                        });
                });

                page.Footer().Element(f => ReportFooterBand(f, isRu));
            });
        }).GeneratePdf();
    }

    /// <summary>
    /// Renders the comprehensive report — daily summary KPIs, per-seller table
    /// and an inventory overview. Pure rendering; unit-testable.
    /// </summary>
    internal static byte[] RenderComprehensiveReportPdf(ComprehensiveReportDto report, string dateLabel, DateTime generatedAtLocal, string lang = "uz")
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var d = report.DailyReport;

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(9.5f).FontColor(PdfTheme.Ink));

                page.Header().Element(h => ReportHeaderBand(h, L("TO'LIQ HISOBOT", "ПОЛНЫЙ ОТЧЁТ"), dateLabel, isRu, generatedAtLocal));

                page.Content().PaddingHorizontal(32).PaddingTop(20).Column(column =>
                {
                    column.Spacing(18);

                    // Daily summary KPIs
                    column.Item().Row(row =>
                    {
                        row.Spacing(12);
                        KpiCard(row, L("Jami savdo", "Общая выручка"), $"{d.TotalSales:N0}{L(" so'm", " сум")}", PdfTheme.Ink);
                        KpiCard(row, L("To'langan", "Оплачено"), $"{d.TotalPaidSales:N0}{L(" so'm", " сум")}", PdfTheme.Success);
                        KpiCard(row, L("Qarz", "Долг"), $"{d.TotalDebtSales:N0}{L(" so'm", " сум")}", PdfTheme.Danger);
                        if (d.Profit.HasValue)
                            KpiCard(row, L("Sof foyda", "Чистая прибыль"), $"{d.Profit.Value:N0}{L(" so'm", " сум")}",
                                d.Profit.Value >= 0 ? PdfTheme.Success : PdfTheme.Danger);
                    });

                    // Seller breakdown
                    column.Item().Column(sec =>
                    {
                        sec.Item().PaddingBottom(6).Text(L("SOTUVCHILAR", "ПРОДАВЦЫ"))
                            .FontSize(11).Bold().FontColor(PdfTheme.BrandDark);
                        sec.Item().Table(table =>
                        {
                            table.ColumnsDefinition(columns =>
                            {
                                columns.RelativeColumn(3);
                                columns.ConstantColumn(120);
                                columns.ConstantColumn(80);
                                columns.ConstantColumn(120);
                            });
                            table.Header(header =>
                            {
                                header.Cell().Element(SalesHeadCell).Text(L("SOTUVCHI", "ПРОДАВЕЦ"));
                                header.Cell().Element(SalesHeadCell).AlignRight().Text(L("SAVDO", "ПРОДАЖИ"));
                                header.Cell().Element(SalesHeadCell).AlignRight().Text(L("CHEKLAR", "ЧЕКИ"));
                                header.Cell().Element(SalesHeadCell).AlignRight().Text(L("FOYDA", "ПРИБЫЛЬ"));
                            });
                            int i = 0;
                            foreach (var s in report.SellerReports)
                            {
                                var bg = i++ % 2 == 0 ? PdfTheme.White : PdfTheme.Zebra;
                                table.Cell().Element(c => SalesBodyCell(c)).Text(s.SellerName);
                                table.Cell().Element(c => SalesBodyCell(c)).AlignRight().Text($"{s.TotalSales:N0}");
                                table.Cell().Element(c => SalesBodyCell(c)).AlignRight().Text($"{s.TransactionCount:N0}");
                                table.Cell().Element(c => SalesBodyCell(c)).AlignRight()
                                    .Text(s.TotalProfit.HasValue ? $"{s.TotalProfit.Value:N0}" : "—");
                            }
                        });
                    });

                    // Inventory overview
                    column.Item().Column(sec =>
                    {
                        sec.Item().PaddingBottom(6).Text(L("SKLAD HOLATI", "СОСТОЯНИЕ СКЛАДА"))
                            .FontSize(11).Bold().FontColor(PdfTheme.BrandDark);
                        sec.Item().Row(row =>
                        {
                            row.Spacing(12);
                            KpiCard(row, L("Mahsulotlar", "Товары"), $"{report.ProductCount:N0}", PdfTheme.Ink);
                            KpiCard(row, L("Jami qiymat", "Общая стоимость"), $"{report.TotalInventoryValue:N0}{L(" so'm", " сум")}", PdfTheme.Ink);
                            KpiCard(row, L("Kam qolgan", "Заканчивается"), $"{report.LowStockCount:N0}", PdfTheme.BrandDark);
                            KpiCard(row, L("Tugagan", "Закончились"), $"{report.OutOfStockCount:N0}", PdfTheme.Danger);
                        });
                    });
                });

                page.Footer().Element(f => ReportFooterBand(f, isRu));
            });
        }).GeneratePdf();
    }

    // ── Report rendering helpers ──
    private static void ReportHeaderBand(IContainer header, string title, string subtitle, bool isRu, DateTime generatedAtLocal)
    {
        header.Background(PdfTheme.Brand).PaddingVertical(16).PaddingHorizontal(32).Row(row =>
        {
            row.RelativeItem().Column(col =>
            {
                col.Item().Text(title).FontSize(18).Bold().FontColor(PdfTheme.White);
                col.Item().PaddingTop(2).Text(subtitle).FontSize(10).FontColor(PdfTheme.BrandTint);
            });
            row.ConstantItem(170).AlignRight().AlignBottom()
                .Text($"{(isRu ? "Создан: " : "Yaratilgan: ")}{generatedAtLocal:dd.MM.yyyy HH:mm}")
                .FontSize(8).FontColor(PdfTheme.BrandTint);
        });
    }

    private static void ReportFooterBand(IContainer footer, bool isRu)
    {
        footer.BorderTop(1).BorderColor(PdfTheme.Line)
            .PaddingHorizontal(32).PaddingVertical(8).Row(row =>
        {
            row.RelativeItem().AlignMiddle()
                .Text(isRu
                    ? "Создано в Strotech  ·  strotech.uz"
                    : "Strotech tomonidan yaratildi  ·  strotech.uz")
                .FontSize(8).FontColor(PdfTheme.Muted);
            row.RelativeItem().AlignRight().AlignMiddle().Text(x =>
            {
                x.DefaultTextStyle(s => s.FontSize(8).FontColor(PdfTheme.Muted));
                x.Span(isRu ? "Стр. " : "Sahifa ");
                x.CurrentPageNumber();
                x.Span(" / ");
                x.TotalPages();
            });
        });
    }

    private static void KpiCard(QuestPDF.Fluent.RowDescriptor row, string label, string value, string accent)
    {
        row.RelativeItem().Border(1).BorderColor(PdfTheme.Line).Background(PdfTheme.White)
            .Padding(12).Column(col =>
        {
            col.Item().Text(label.ToUpperInvariant()).FontSize(7.5f).Bold().FontColor(PdfTheme.Muted);
            col.Item().PaddingTop(5).Text(value).FontSize(13).Bold().FontColor(accent);
        });
    }

    private static void PaymentBreakdownTable(IContainer container, IReadOnlyList<PaymentBreakdownDto> payments, bool isRu)
    {
        container.Table(table =>
        {
            table.ColumnsDefinition(columns =>
            {
                columns.RelativeColumn(3);
                columns.ConstantColumn(90);
                columns.ConstantColumn(150);
            });
            table.Header(header =>
            {
                header.Cell().Element(SalesHeadCell).Text(isRu ? "ТИП" : "TUR");
                header.Cell().Element(SalesHeadCell).AlignRight().Text(isRu ? "КОЛ-ВО" : "SONI");
                header.Cell().Element(SalesHeadCell).AlignRight().Text(isRu ? "СУММА" : "SUMMA");
            });
            int i = 0;
            foreach (var p in payments)
            {
                var bg = i++ % 2 == 0 ? PdfTheme.White : PdfTheme.Zebra;
                table.Cell().Element(c => SalesBodyCell(c)).Text(PaymentLabel(p.PaymentType, isRu));
                table.Cell().Element(c => SalesBodyCell(c)).AlignRight().Text($"{p.Count:N0}");
                table.Cell().Element(c => SalesBodyCell(c)).AlignRight().Text($"{p.Amount:N0}{(isRu ? " сум" : " so'm")}");
            }
        });
    }

    private static string PaymentLabel(string type, bool isRu) => type switch
    {
        "Cash" => isRu ? "Наличные" : "Naqd",
        "Transfer" => isRu ? "Перевод / Счёт" : "O'tkazma / Hisob",
        "Qaytarilgan" or "Refund" => isRu ? "Возврат" : "Qaytarilgan",
        _ => type, // Terminal / Click — already fine
    };

    public async Task<byte[]> GenerateInvoicePdfAsync(Guid saleId, string? userRole = null, string lang = "uz", CancellationToken cancellationToken = default)
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var marketId = _currentMarketService.GetCurrentMarketId();

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.Id == saleId && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments,Seller,Customer,Market");

        var sale = sales.FirstOrDefault();
        if (sale == null)
            throw new KeyNotFoundException($"Sale with ID {saleId} not found.");

        if (sale.Market == null)
            throw new InvalidOperationException($"Market data is missing for sale {saleId}.");

        var market = sale.Market;
        var seller = sale.Seller;

        // If seller was soft-deleted, fetch their name directly from database (ignoring soft-delete filter)
        string sellerName = L("Noma'lum sotuvchi", "Продавец не указан");
        if (seller != null)
        {
            sellerName = seller.FullName;
        }
        else
        {
            // Try to get seller name from database even if deleted
            var deletedSeller = await _unitOfWork.Users.GetByIdIncludingDeletedAsync(sale.SellerId, cancellationToken);
            if (deletedSeller != null)
            {
                sellerName = deletedSeller.FullName;
            }
        }

        var customer = sale.Customer;

        // If customer was soft-deleted, fetch their name from database (ignoring soft-delete filter)
        string noCustomer = L("Mijoz ko'rsatilmagan", "Без клиента");
        string customerName = noCustomer;
        if (customer != null)
        {
            customerName = customer.FullName ?? noCustomer;
        }
        else if (sale.CustomerId.HasValue)
        {
            // Try to get customer name from database even if deleted
            var deletedCustomer = await _unitOfWork.Customers.GetByIdIncludingDeletedAsync(sale.CustomerId.Value, cancellationToken);
            if (deletedCustomer != null)
            {
                customerName = deletedCustomer.FullName ?? noCustomer;
            }
        }

        // ✅ Get all ordinary products for the sale items (faqat oddiy mahsulotlar uchun)
        var ordinaryProductIds = sale.SaleItems
            .Where(si => !si.IsExternal && si.ProductId.HasValue)
            .Select(si => si.ProductId!.Value)
            .Distinct()
            .ToList();

        var products = new Dictionary<Guid, Product>();
        if (ordinaryProductIds.Any())
        {
            var productList = await _unitOfWork.Products.FindAsync(
                p => ordinaryProductIds.Contains(p.Id) && p.MarketId == marketId,
                cancellationToken);
            foreach (var p in productList)
            {
                products[p.Id] = p;
            }
        }
        var productDict = products;

        // Determine payment type
        var primaryPayment = sale.Payments.FirstOrDefault(p => p.Amount > 0);
        var paymentTypeEnum = primaryPayment?.PaymentType ?? PaymentType.Cash;
        string paymentTypeUz = isRu
            ? paymentTypeEnum switch
            {
                PaymentType.Cash => "Наличные",
                PaymentType.Transfer => "Перевод / Счёт",
                _ => paymentTypeEnum.ToString(), // Terminal / Click — already fine
            }
            : paymentTypeEnum.ToUzbek();

        // Create invoice data
        var invoiceItems = new List<InvoiceItemData>();
        foreach (var item in sale.SaleItems)
        {
            // ✅ ISEXTERNAL SHARTI - Product name olish
            string productName;
            if (!item.IsExternal)
            {
                // Oddiy mahsulot - ProductId nullable uchun null check
                if (!item.ProductId.HasValue)
                    productName = "Unknown";
                else
                {
                    var product = productDict.GetValueOrDefault(item.ProductId.Value);
                    productName = product?.Name ?? L("Noma'lum mahsulot", "Неизвестный товар");
                }
            }
            else
            {
                // Tashqi mahsulot
                productName = item.ExternalProductName ?? L("Noma'lum mahsulot", "Неизвестный товар");
            }
            invoiceItems.Add(new InvoiceItemData(
                productName,
                item.Quantity,
                item.SalePrice,
                item.SalePrice * item.Quantity,
                item.Comment,
                item.IsExternal
            ));
        }

        var invoiceData = new InvoiceData(
            market.Name,
            market.Description ?? "",
            sellerName,
            customerName,
            sale.Id,
            sale.CreatedAt,
            paymentTypeUz,
            invoiceItems,
            sale.TotalAmount,
            sale.PaidAmount,
            sale.TotalAmount - sale.PaidAmount,
            sale.Status.ToString() // raw enum — RenderInvoicePdf localises it
        );

        try
        {
            return RenderInvoicePdf(invoiceData, lang);
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"PDF generation failed for sale {saleId}: {ex.Message}", ex);
        }
    }

    /// <summary>
    /// Renders a sale invoice as a branded A4 PDF (minimalist design).
    /// No colored background, only hairline borders and colored text.
    /// Pure rendering — no I/O — so it can be unit-tested with sample data.
    /// </summary>
    internal static byte[] RenderInvoicePdf(InvoiceData data, string lang = "uz")
    {
        bool isRu = lang.Equals("ru", StringComparison.OrdinalIgnoreCase);
        string L(string uz, string ru) => isRu ? ru : uz;

        var (statusLabel, statusColor) = SaleStatusInfo(data.Status, isRu);
        var shortId = data.InvoiceNumber.ToString("N")[..6].ToUpperInvariant();
        var displayNumber = $"INV-{data.Date:yyMMdd}-{shortId}";
        var initial = string.IsNullOrWhiteSpace(data.MarketName)
            ? "M" : data.MarketName.Trim()[..1].ToUpperInvariant();

        return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(0);
                page.DefaultTextStyle(x => x.FontSize(10).FontColor(PdfTheme.Ink));

                // ── Header: oq fon, brand belgisi, apelsin "FAKTURA" ──
                page.Header().PaddingHorizontal(32).PaddingTop(26).PaddingBottom(16)
                    .BorderBottom(2).BorderColor(PdfTheme.Ink).Row(row =>
                {
                    row.AutoItem().Element(c => BrandMark(c, initial));
                    row.RelativeItem().PaddingLeft(14).Column(col =>
                    {
                        col.Item().Text(data.MarketName).FontSize(21).Bold().FontColor(PdfTheme.Ink);
                        if (!string.IsNullOrWhiteSpace(data.MarketDescription))
                            col.Item().PaddingTop(2).Text(data.MarketDescription)
                                .FontSize(10).FontColor(PdfTheme.Muted);
                    });
                    row.ConstantItem(160).Column(col =>
                    {
                        col.Item().AlignRight().Text(L("FAKTURA", "СЧЁТ-ФАКТУРА"))
                            .FontSize(24).Bold().FontColor(PdfTheme.Brand).LetterSpacing(0.04f);
                        col.Item().AlignRight().PaddingTop(3).Text(displayNumber)
                            .FontSize(10).SemiBold().FontColor(PdfTheme.Muted);
                    });
                });

                page.Content().PaddingHorizontal(32).PaddingTop(22).Column(column =>
                {
                    column.Spacing(0);

                    // ── Meta: toza maydonlar + status rangli matn ──
                    column.Item().PaddingBottom(20).Row(row =>
                    {
                        InvoiceMetaField(row, L("Sana", "Дата"), data.Date.ToString("dd.MM.yyyy · HH:mm"), first: true);
                        InvoiceMetaField(row, L("Mijoz", "Клиент"), data.CustomerName, first: false);
                        InvoiceMetaField(row, L("Sotuvchi", "Продавец"), data.SellerName, first: false);
                        InvoiceMetaField(row, L("To'lov", "Оплата"), data.PaymentType, first: false);
                        // Status – rangli matn (fonsiz)
                        row.ConstantItem(120).Element(e => e
                            .BorderLeft(1).BorderColor(PdfTheme.Line).PaddingLeft(18).Column(col =>
                        {
                            col.Item().Text(L("HOLAT", "СТАТУС"))
                                .FontSize(8).Bold().FontColor(PdfTheme.Muted).LetterSpacing(0.08f);
                            col.Item().PaddingTop(5).Text(statusLabel)
                                .FontSize(13).Bold().FontColor(statusColor);
                        }));
                    });

                    // ── Mahsulotlar jadvali ──
                    column.Item().Table(table =>
                    {
                        table.ColumnsDefinition(columns =>
                        {
                            columns.ConstantColumn(34);   // #
                            columns.RelativeColumn(4);    // Mahsulot
                            columns.RelativeColumn(1.4f); // Miqdor
                            columns.RelativeColumn(2);    // Narx
                            columns.RelativeColumn(2.2f); // Jami
                        });

                        table.Header(header =>
                        {
                            header.Cell().Element(InvoiceHeadCell).Text("#");
                            header.Cell().Element(InvoiceHeadCell).Text(L("MAHSULOT", "ТОВАР"));
                            header.Cell().Element(InvoiceHeadCell).AlignRight().Text(L("MIQDOR", "КОЛ-ВО"));
                            header.Cell().Element(InvoiceHeadCell).AlignRight().Text(L("NARX", "ЦЕНА"));
                            header.Cell().Element(InvoiceHeadCell).AlignRight().Text(L("JAMI", "СУММА"));
                        });

                        int i = 0;
                        foreach (var item in data.Items)
                        {
                            i++;
                            table.Cell().Element(InvoiceBodyCell).Text($"{i}").FontColor(PdfTheme.Faint).SemiBold();
                            table.Cell().Element(InvoiceBodyCell).Text(t =>
                            {
                                t.Span(item.ProductName).SemiBold();
                                // "tashqi" – apelsin uppercase matn (teg/fonsiz)
                                if (item.IsExternal)
                                    t.Span(L("   TASHQI", "   ВНЕШНИЙ")).FontSize(8).Bold()
                                        .FontColor(PdfTheme.BrandDark).LetterSpacing(0.05f);
                            });
                            table.Cell().Element(InvoiceBodyCell).AlignRight().Text($"{item.Quantity:N2}").FontColor(PdfTheme.Muted);
                            table.Cell().Element(InvoiceBodyCell).AlignRight().Text($"{item.Price:N0}").FontColor(PdfTheme.Muted);
                            table.Cell().Element(InvoiceBodyCell).AlignRight().Text($"{item.Total:N0}").Bold();

                            if (!string.IsNullOrWhiteSpace(item.Comment))
                                table.Cell().ColumnSpan(5).Element(InvoiceBodyCell)
                                    .Text($"{L("Izoh", "Примечание")}: {item.Comment}")
                                    .FontSize(8.5f).Italic().FontColor(PdfTheme.Muted);
                        }
                    });

                    // ── Summalar bloki ──
                    column.Item().PaddingTop(22).AlignRight().Width(290).Column(col =>
                    {
                        InvoiceTotalRow(col, L("Oraliq summa", "Промежуточная"), $"{data.TotalAmount:N0}{L(" so'm", " сум")}");
                        col.Item().PaddingTop(4).BorderTop(2).BorderColor(PdfTheme.Ink).PaddingTop(10).Row(r =>
                        {
                            r.RelativeItem().Text(L("Jami summa", "Общая сумма")).FontSize(13).Bold().FontColor(PdfTheme.Ink);
                            r.AutoItem().Text(t =>
                            {
                                t.Span($"{data.TotalAmount:N0}").FontSize(19).Bold().FontColor(PdfTheme.Ink);
                                t.Span(L(" so'm", " сум")).FontSize(11).FontColor(PdfTheme.Faint);
                            });
                        });
                        InvoiceTotalRow(col, L("To'langan", "Оплачено"), $"{data.PaidAmount:N0}{L(" so'm", " сум")}");

                        // ── Qarzdorlik: qizil qalin matn (blok/fonsiz) ──
                        if (data.RemainingAmount > 0)
                            col.Item().PaddingTop(7).Row(r =>
                            {
                                r.RelativeItem().Text(L("Qarzdorlik", "Задолженность"))
                                    .FontSize(12).Bold().FontColor(PdfTheme.Danger);
                                r.AutoItem().Text($"{data.RemainingAmount:N0}{L(" so'm", " сум")}")
                                    .FontSize(14).Bold().FontColor(PdfTheme.Danger);
                            });
                    });

                    column.Item().PaddingTop(24).AlignCenter()
                        .Text(L("Xaridingiz uchun rahmat!", "Спасибо за покупку!"))
                        .FontSize(12).Bold().FontColor(PdfTheme.BrandDark);
                });

                // ── Footer ──
                page.Footer().BorderTop(1).BorderColor(PdfTheme.Line)
                    .PaddingHorizontal(32).PaddingVertical(9).Row(row =>
                {
                    row.RelativeItem().AlignMiddle().Text(t =>
                    {
                        t.Span("Strotech").FontSize(8).Bold().FontColor(PdfTheme.BrandDark);
                        t.Span(L(" tomonidan yaratildi  ·  strotech.uz", " · strotech.uz"))
                            .FontSize(8).FontColor(PdfTheme.Muted);
                    });
                    row.RelativeItem().AlignRight().AlignMiddle().Text(x =>
                    {
                        x.DefaultTextStyle(s => s.FontSize(8).FontColor(PdfTheme.Muted));
                        x.Span(L("Sahifa ", "Стр. ")); x.CurrentPageNumber(); x.Span(" / "); x.TotalPages();
                    });
                });
            });
        }).GeneratePdf();
    }

    // ── Invoice helper'lari ──
    // Meta maydoni: RowDescriptor, chiziq bilan ajratilgan (qutisiz).
    private static void InvoiceMetaField(QuestPDF.Fluent.RowDescriptor row,
        string label, string value, bool first)
    {
        row.RelativeItem().Element(e =>
        {
            var box = first
                ? e.PaddingRight(18)
                : e.BorderLeft(1).BorderColor(PdfTheme.Line).PaddingLeft(18).PaddingRight(18);
            box.Column(col =>
            {
                col.Item().Text(label.ToUpperInvariant())
                    .FontSize(8).Bold().FontColor(PdfTheme.Muted).LetterSpacing(0.06f);
                col.Item().PaddingTop(5).Text(value).FontSize(12).SemiBold().FontColor(PdfTheme.Ink);
            });
        });
    }

    private static void InvoiceTotalRow(QuestPDF.Fluent.ColumnDescriptor col, string label, string value,
        bool bold = false, string color = "#0F172A")
    {
        col.Item().PaddingVertical(4).Row(row =>
        {
            var l = row.RelativeItem().Text(label).FontSize(12).FontColor(PdfTheme.Muted);
            if (bold) l.SemiBold();
            var v = row.AutoItem().Text(value).FontSize(12.5f).SemiBold().FontColor(color);
            if (bold) v.Bold();
        });
    }

    // Muted uppercase + pastki hairline.
    private static IContainer InvoiceHeadCell(IContainer c)
        => c.PaddingBottom(10).PaddingHorizontal(8)
            .BorderBottom(1.5f).BorderColor(PdfTheme.Line)
            .DefaultTextStyle(x => x.FontSize(9).Bold().FontColor(PdfTheme.Muted).LetterSpacing(0.06f));

    // Fonsiz hairline.
    private static IContainer InvoiceBodyCell(IContainer c)
        => c.BorderBottom(1).BorderColor(PdfTheme.Line)
            .PaddingVertical(8).PaddingHorizontal(8).AlignMiddle();

    // Invoice data classes — `internal` so the PDF renderers (and their tests)
    // can construct them; see InternalsVisibleTo in the .csproj.
    internal record InvoiceData(
        string MarketName,
        string MarketDescription,
        string SellerName,
        string CustomerName,
        Guid InvoiceNumber,
        DateTime Date,
        string PaymentType,
        List<InvoiceItemData> Items,
        decimal TotalAmount,
        decimal PaidAmount,
        decimal RemainingAmount,
        string Status
    );

    internal record InvoiceItemData(
        string ProductName,
        decimal Quantity,
        decimal Price,
        decimal Total,
        string? Comment,
        bool IsExternal
    );

    internal record SalesReportItem(
        int Number,
        DateTime Date,
        string CustomerName,
        string SellerName,
        string ProductName,
        decimal Quantity,
        decimal CostPrice,
        decimal SalePrice,
        decimal TotalPrice,
        decimal? Profit,
        string Status
    );

    // ── Strotech PDF design system ──────────────────────────────────────
    // Single source of truth for every PDF's colours. Mirrors the Flutter
    // app's design tokens (AppTokens) so printed documents match the UI.
    internal static class PdfTheme
    {
        public const string Brand = "#FF6B00";       // primary accent (orange)
        public const string BrandDark = "#E55400";   // headings / emphasis
        public const string BrandLight = "#FFF4EB";  // tinted section background
        public const string BrandTint = "#FFE9D6";   // on-brand subtle text
        public const string Ink = "#0F172A";         // primary text
        public const string Muted = "#64748B";       // secondary text
        public const string Faint = "#94A3B8";       // index / tertiary text
        public const string Line = "#E2E8F0";        // dividers / borders
        public const string Zebra = "#F8FAFC";       // alternate table row
        public const string White = "#FFFFFF";
        public const string Success = "#16A34A";     // paid / profit
        public const string Danger = "#DC2626";      // debt / loss
        public const string InfoBlue = "#2563EB";    // closed
    }

    /// <summary>Localised label + status colour for a sale status — accepts
    /// both the raw enum name ("Paid") and an already-localised label.</summary>
    private static (string Label, string Color) SaleStatusInfo(string status, bool isRu) => status switch
    {
        "Paid" or "To'langan" => (isRu ? "Оплачено" : "To'langan", PdfTheme.Success),
        "Debt" or "Qarz" => (isRu ? "Долг" : "Qarz", PdfTheme.Danger),
        "Closed" or "Qarz yopilgan" => (isRu ? "Долг закрыт" : "Qarz yopilgan", PdfTheme.InfoBlue),
        "Cancelled" or "Bekor qilingan" => (isRu ? "Отменено" : "Bekor qilingan", PdfTheme.Danger),
        "Draft" => (isRu ? "Черновик" : "Qoralama", PdfTheme.Muted),
        _ => (status, PdfTheme.Muted),
    };

    private static IContainer HeaderStyle(IContainer container)
    {
        return container
            .Border(1)
            .BorderColor(Colors.Grey.Lighten2)
            .Padding(4)
            .Background(Colors.Grey.Lighten4)
            .AlignCenter()
            .AlignMiddle();
    }

    private static IContainer RowStyle(IContainer container)
    {
        return container
            .Border(1)
            .BorderColor(Colors.Grey.Lighten2)
            .Padding(3)
            .AlignMiddle();
    }

    // Used by report PDFs/Excel for human-readable date labels — anchored to Tashkent.
    private DateTime ToUtcDate(DateTime date) => _clock.LocalDayToUtcRange(date).UtcStart;

    /// <summary>
    /// Convert a Tashkent-local calendar date to the UTC half-open range covering that day.
    /// Tashkent is GMT+5: a "2026-05-12 daily report" must include sales from
    /// 2026-05-11 19:00 UTC to 2026-05-12 19:00 UTC.
    /// </summary>
    private (DateTime Start, DateTime End) GetUtcDateRange(DateTime date) =>
        _clock.LocalDayToUtcRange(date);

    // ═══════════════════════════════════════════════════════════════════
    // Dashboard aggregations (added 2026-05-18) — back the new design's
    // ChartCard, TopSellersCard, and Reports → Staff page. Pure aggregations
    // over existing Sales/SaleItems/Users; no new domain entities.
    // ═══════════════════════════════════════════════════════════════════

    /// <summary>
    /// Last <paramref name="days"/> Tashkent calendar days, ending today, with
    /// revenue + profit + check count per day. Fills gaps with zero-points so
    /// the frontend can plot a continuous chart without gap-handling code.
    /// Profit is suppressed (returned as 0) for non-Owner callers.
    /// When <paramref name="compare"/> is true, also returns the total revenue
    /// for the equally-sized window immediately preceding [current window],
    /// so the dashboard can show a week-over-week delta without a second
    /// round-trip.
    /// </summary>
    public async Task<WeeklySeriesDto> GetWeeklySeriesAsync(
        int days, bool compare = false, string? userRole = null, CancellationToken cancellationToken = default)
    {
        // Clamp to [1, 30] — frontend asks for 7 by default; 30 is a hard cap
        // so a misbehaving client can't trigger a month-long full table scan.
        if (days < 1) days = 1;
        if (days > 30) days = 30;

        var marketId = _currentMarketService.GetCurrentMarketId();
        var todayLocal = _clock.TodayLocal;
        var rangeStartLocal = todayLocal.AddDays(-(days - 1));
        var rangeStartUtc = ToUtcDate(rangeStartLocal);
        var (_, rangeEndUtc) = GetUtcDateRange(todayLocal);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= rangeStartUtc && s.CreatedAt < rangeEndUtc &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                 s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var includeProfit = userRole == Role.Owner.ToString();
        var byDay = new Dictionary<DateTime, (decimal revenue, decimal profit, int count)>(days);

        foreach (var sale in sales)
        {
            // Bucket sales into the Tashkent calendar day they belong to.
            // CreatedAt is UTC; offset back to local before flooring to date.
            var localDay = _clock.ToLocal(sale.CreatedAt).Date;

            var current = byDay.TryGetValue(localDay, out var existing)
                ? existing
                : (revenue: 0m, profit: 0m, count: 0);
            decimal saleProfit = 0;
            if (includeProfit)
            {
                foreach (var item in sale.SaleItems)
                {
                    var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                    saleProfit += (item.SalePrice - costPrice) * item.Quantity;
                }
            }
            byDay[localDay] = (
                current.revenue + sale.TotalAmount,
                current.profit + saleProfit,
                current.count + 1);
        }

        var points = new List<DailyPoint>(days);
        decimal currentTotal = 0;
        for (var i = 0; i < days; i++)
        {
            var localDay = rangeStartLocal.AddDays(i).Date;
            var utcStart = ToUtcDate(localDay);
            var bucket = byDay.TryGetValue(localDay, out var v) ? v : (0m, 0m, 0);
            points.Add(new DailyPoint(utcStart, bucket.Item1, bucket.Item2, bucket.Item3));
            currentTotal += bucket.Item1;
        }

        // Optional second pass for the previous equally-sized window so the
        // frontend's ChartCard footer can render "↑/↓ X% vs last week".
        // We deliberately query a separate batch (rather than widening the
        // first one to 2× the range) to keep memory bounded when days=30.
        decimal? previousTotal = null;
        if (compare)
        {
            var prevStartLocal = rangeStartLocal.AddDays(-days);
            var prevStartUtc = ToUtcDate(prevStartLocal);
            var prevEndUtc = rangeStartUtc;

            var prevSales = await _unitOfWork.Sales.FindAsync(
                s => s.CreatedAt >= prevStartUtc && s.CreatedAt < prevEndUtc &&
                     s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                     s.MarketId == marketId,
                cancellationToken);

            previousTotal = prevSales.Sum(s => s.TotalAmount);
        }

        return new WeeklySeriesDto(points, currentTotal, previousTotal);
    }

    /// <summary>
    /// Top-N products in the selected period, ranked by quantity / revenue /
    /// profit. Tenant-scoped; profit hidden for non-Owner callers.
    /// </summary>
    public async Task<TopProductsDto> GetTopProductsAsync(
        string period, string sortBy, int limit,
        string? userRole = null, CancellationToken cancellationToken = default)
    {
        if (limit < 1) limit = 1;
        if (limit > 50) limit = 50;

        var marketId = _currentMarketService.GetCurrentMarketId();
        var (rangeStartUtc, rangeEndUtc) = ResolvePeriodRange(period);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= rangeStartUtc && s.CreatedAt < rangeEndUtc &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                 s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        // Fallback: if `today` returned nothing (typical for fresh shops at
        // 9 AM, or shops with no sales yet today), widen to the rolling-week
        // window so the dashboard isn't a blank box. We mutate `period` so the
        // returned DTO advertises the actual range used.
        var effectivePeriod = period;
        if ((period?.ToLowerInvariant() == "today") && !sales.Any())
        {
            (rangeStartUtc, rangeEndUtc) = ResolvePeriodRange("week");
            effectivePeriod = "week";
            sales = await _unitOfWork.Sales.FindAsync(
                s => s.CreatedAt >= rangeStartUtc && s.CreatedAt < rangeEndUtc &&
                     s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                     s.MarketId == marketId,
                cancellationToken,
                includeProperties: "SaleItems");
        }

        var includeProfit = userRole == Role.Owner.ToString();

        // Group line items by ProductId; track distinct sellers per product.
        var byProduct = new Dictionary<Guid, (decimal qty, decimal revenue, decimal profit, HashSet<Guid> sellers)>();
        foreach (var sale in sales)
        {
            foreach (var item in sale.SaleItems)
            {
                // Skip external one-off products — they don't have a stable
                // ProductId across sales, so "top external one-off" would
                // be meaningless noise in the ranking. ProductId is also
                // guaranteed non-null after this gate.
                if (item.IsExternal || item.ProductId == null) continue;

                var key = item.ProductId.Value;
                if (!byProduct.TryGetValue(key, out var agg))
                {
                    agg = (0m, 0m, 0m, new HashSet<Guid>());
                }
                agg.qty += item.Quantity;
                agg.revenue += item.SalePrice * item.Quantity;
                if (includeProfit)
                {
                    var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                    agg.profit += (item.SalePrice - costPrice) * item.Quantity;
                }
                agg.sellers.Add(sale.SellerId);
                byProduct[key] = agg;
            }
        }

        // Resolve category names in one batch — saves N round-trips when the
        // ranking spans many distinct categories.
        var productIds = byProduct.Keys.ToList();
        var products = await _unitOfWork.Products.FindAsync(
            p => productIds.Contains(p.Id) && p.MarketId == marketId,
            cancellationToken,
            includeProperties: "Category");
        var productCategory = products.ToDictionary(
            p => p.Id,
            p => p.Category?.Name ?? string.Empty);
        var productName = products.ToDictionary(p => p.Id, p => p.Name);

        // Sort by the requested key; ties broken by quantity desc.
        var sortKey = sortBy?.ToLowerInvariant() ?? "quantity";
        IEnumerable<KeyValuePair<Guid, (decimal qty, decimal revenue, decimal profit, HashSet<Guid> sellers)>> ordered = sortKey switch
        {
            "revenue" => byProduct.OrderByDescending(p => p.Value.revenue).ThenByDescending(p => p.Value.qty),
            "profit" => byProduct.OrderByDescending(p => p.Value.profit).ThenByDescending(p => p.Value.qty),
            _ => byProduct.OrderByDescending(p => p.Value.qty).ThenByDescending(p => p.Value.revenue),
        };

        var rows = new List<TopProductRow>();
        var rank = 1;
        foreach (var (id, agg) in ordered.Take(limit))
        {
            rows.Add(new TopProductRow(
                Rank: rank++,
                ProductId: id.ToString(),
                Name: productName.TryGetValue(id, out var n) ? n : string.Empty,
                Category: productCategory.TryGetValue(id, out var c) ? c : string.Empty,
                Sellers: agg.sellers.Count,
                Quantity: agg.qty,
                Revenue: agg.revenue,
                Profit: includeProfit ? agg.profit : null));
        }

        // Echo the *resolved* period, not the requested one — that way when
        // today→week fallback kicked in above the UI knows to re-label the
        // panel as "Bu hafta" instead of misleadingly "Bugun".
        return new TopProductsDto(effectivePeriod ?? "month", sortKey, rows);
    }

    /// <summary>
    /// Per-staff sales metrics for the period. Includes staff with zero sales
    /// so the page can show the whole team (otherwise a quiet seller would
    /// silently disappear from the leaderboard). Shift counts come from the
    /// Shift entity — sessions opened inside the period count; the
    /// <c>IsActiveShift</c> flag also catches sessions that opened earlier
    /// and are still open right now.
    /// </summary>
    public async Task<StaffPerformanceDto> GetStaffPerformanceAsync(
        string period, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (rangeStartUtc, rangeEndUtc) = ResolvePeriodRange(period);

        var users = await _unitOfWork.Users.FindAsync(
            u => u.MarketId == marketId &&
                 (u.Role == Role.Seller || u.Role == Role.Admin || u.Role == Role.Owner),
            cancellationToken);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= rangeStartUtc && s.CreatedAt < rangeEndUtc &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                 s.MarketId == marketId,
            cancellationToken);

        var bySeller = sales
            .GroupBy(s => s.SellerId)
            .ToDictionary(g => g.Key, g => (count: g.Count(), revenue: g.Sum(s => s.TotalAmount)));

        // Pull the shifts in one round-trip and bucket them by user. The
        // predicate keeps it cheap: "either opened in this period, or still
        // open right now". A seller who clocked in last week and never
        // closed shows IsActiveShift=true even if ShiftCount stays 0 for
        // the current week.
        var shifts = (await _unitOfWork.Shifts.FindAsync(
            sh => sh.MarketId == marketId &&
                  ((sh.OpenedAt >= rangeStartUtc && sh.OpenedAt < rangeEndUtc)
                   || sh.ClosedAt == null),
            cancellationToken)).ToList();

        var shiftCountByUser = shifts
            .Where(sh => sh.OpenedAt >= rangeStartUtc && sh.OpenedAt < rangeEndUtc)
            .GroupBy(sh => sh.UserId)
            .ToDictionary(g => g.Key, g => g.Count());

        var activeShiftUsers = shifts
            .Where(sh => sh.ClosedAt == null)
            .Select(sh => sh.UserId)
            .ToHashSet();

        var rows = new List<StaffRow>();
        foreach (var u in users)
        {
            var stats = bySeller.TryGetValue(u.Id, out var v) ? v : (0, 0m);
            rows.Add(new StaffRow(
                Rank: 0, // assigned after sort
                UserId: u.Id.ToString(),
                FullName: u.FullName,
                Role: u.Role.ToString(),
                SaleCount: stats.Item1,
                Revenue: stats.Item2,
                AverageCheck: stats.Item1 == 0 ? 0m : stats.Item2 / stats.Item1,
                ShiftCount: shiftCountByUser.TryGetValue(u.Id, out var sc) ? sc : 0,
                IsActiveShift: activeShiftUsers.Contains(u.Id)
            ));
        }

        // Sort by Revenue desc, then FullName asc for stable ordering of zero-sales staff.
        var sorted = rows
            .OrderByDescending(r => r.Revenue)
            .ThenBy(r => r.FullName, StringComparer.OrdinalIgnoreCase)
            .Select((r, i) => r with { Rank = i + 1 })
            .ToList();

        return new StaffPerformanceDto(period ?? "week", sorted);
    }

    /// <summary>
    /// One seller's own metrics. Same shape as a single <see cref="StaffRow"/>
    /// but scoped to a single user, plus a derived "first sale today" timestamp
    /// for the Seller dashboard's shift-duration card.
    /// </summary>
    public async Task<MyPerformanceDto> GetMyPerformanceAsync(
        Guid userId, string period, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (rangeStartUtc, rangeEndUtc) = ResolvePeriodRange(period);

        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        var fullName = user?.FullName ?? string.Empty;

        // Only this seller's non-draft, non-cancelled sales in the period.
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= rangeStartUtc && s.CreatedAt < rangeEndUtc &&
                 s.SellerId == userId &&
                 s.Status != SaleStatus.Cancelled && s.Status != SaleStatus.Draft &&
                 s.MarketId == marketId,
            cancellationToken);

        var salesList = sales.ToList();
        var saleCount = salesList.Count;
        var revenue = salesList.Sum(s => s.TotalAmount);
        var averageCheck = saleCount == 0 ? 0m : revenue / saleCount;

        DateTime? firstSaleAt = saleCount == 0
            ? null
            : salesList.Min(s => s.CreatedAt);

        // Real shift tracking: sum the worked minutes of every Shift the seller
        // opened within the period (open shifts count up to "now"). Falls back
        // to the "minutes since first sale" heuristic when the seller has no
        // recorded shifts yet — so the dashboard never regresses to 0.
        var shifts = await _unitOfWork.Shifts.FindAsync(
            s => s.UserId == userId && s.MarketId == marketId &&
                 s.OpenedAt >= rangeStartUtc && s.OpenedAt < rangeEndUtc,
            cancellationToken);
        var shiftList = shifts.ToList();

        int shiftMinutes;
        if (shiftList.Count > 0)
        {
            shiftMinutes = shiftList.Sum(s =>
            {
                var minutes = ((s.ClosedAt ?? DateTime.UtcNow) - s.OpenedAt).TotalMinutes;
                return minutes > 0 ? (int)minutes : 0;
            });
        }
        else if (firstSaleAt is { } first)
        {
            var elapsed = DateTime.UtcNow - first;
            // Clamp to non-negative — clock-skew between server and DB can
            // produce small negatives that would render as "-3 min".
            shiftMinutes = elapsed.TotalMinutes > 0 ? (int)elapsed.TotalMinutes : 0;
        }
        else
        {
            shiftMinutes = 0;
        }

        return new MyPerformanceDto(
            Period: period ?? "today",
            UserId: userId.ToString(),
            FullName: fullName,
            SaleCount: saleCount,
            Revenue: revenue,
            AverageCheck: averageCheck,
            FirstSaleAtUtc: firstSaleAt,
            ShiftDurationMinutes: shiftMinutes);
    }

    /// <summary>
    /// Map a string period token to a Tashkent-anchored UTC date range.
    /// Defaults to "month" on any unrecognised value so callers don't see
    /// errors from typos — the response still echoes the resolved period.
    /// </summary>
    private (DateTime StartUtc, DateTime EndUtc) ResolvePeriodRange(string? period)
    {
        var todayLocal = _clock.TodayLocal;
        var (todayStart, todayEnd) = GetUtcDateRange(todayLocal);

        return (period?.ToLowerInvariant()) switch
        {
            "today" => (todayStart, todayEnd),
            "week" => (ToUtcDate(todayLocal.AddDays(-6)), todayEnd),
            "year" => (ToUtcDate(new DateTime(todayLocal.Year, 1, 1)), todayEnd),
            _ => (ToUtcDate(new DateTime(todayLocal.Year, todayLocal.Month, 1)), todayEnd), // month (default)
        };
    }
}