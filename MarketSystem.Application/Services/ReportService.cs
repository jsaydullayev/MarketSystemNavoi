using OfficeOpenXml;
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
using Microsoft.Extensions.Logging;

namespace MarketSystem.Application.Services;

public class ReportService : IReportService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly ILogger<ReportService> _logger;

    public ReportService(IUnitOfWork unitOfWork, ICurrentMarketService currentMarketService, ILogger<ReportService> logger)
    {
        _unitOfWork = unitOfWork;
        _currentMarketService = currentMarketService;
        _logger = logger;
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<DailyReportDto> GetDailyReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
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
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        // ✅ Batch fetch all ordinary products to avoid N+1 query (faqat oddiy mahsulotlar uchun)
        var ordinaryProductIds = sales
            .SelectMany(s => s.SaleItems)
            .Where(si => !si.IsExternal && si.ProductId.HasValue)
            .Select(si => si.ProductId.Value)
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
                    // Oddiy mahsulot
                    if (!products.TryGetValue(item.ProductId.Value, out var product))
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
            s => s.CreatedAt >= request.StartDate && s.CreatedAt < endDateTime && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
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

    public async Task<byte[]> ExportToExcelAsync(PeriodReportRequest request, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Use < instead of <= to include the entire end day (up to 23:59:59.999)
        var endDateTime = request.EndDate.AddDays(1);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt < endDateTime && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt < endDateTime && z.MarketId == marketId,
            cancellationToken);

        using var package = new ExcelPackage();
        var worksheet = package.Workbook.Worksheets.Add("Report");

        worksheet.Cells[1, 1].Value = "Date";
        worksheet.Cells[1, 2].Value = "Type";
        worksheet.Cells[1, 3].Value = "Product";
        worksheet.Cells[1, 4].Value = "Quantity";
        worksheet.Cells[1, 5].Value = "Amount";
        worksheet.Cells[1, 6].Value = "Cost";
        worksheet.Cells[1, 7].Value = "Profit";

        using (var range = worksheet.Cells[1, 1, 1, 7])
        {
            range.Style.Font.Bold = true;
            range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
            range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
        }

        int row = 2;
        foreach (var sale in sales)
        {
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == sale.Id, cancellationToken);

            foreach (var item in saleItems)
            {
                // ✅ ISEXTERNAL SHARTI - Product name va CostPrice
                string productName;
                Product? product = null;

                if (!item.IsExternal)
                {
                    // Oddiy mahsulot - Product ni olish
                    product = await _unitOfWork.Products.GetByIdAsync(item.ProductId.Value, cancellationToken);
                    productName = product?.Name ?? "Unknown";
                }
                else
                {
                    // Tashqi mahsulot - ExternalProductName ishlatish
                    productName = item.ExternalProductName ?? "Tashqi mahsulot";
                }

                worksheet.Cells[row, 1].Value = sale.CreatedAt.ToString("yyyy-MM-dd");
                worksheet.Cells[row, 2].Value = "Sale";
                worksheet.Cells[row, 3].Value = productName;
                worksheet.Cells[row, 4].Value = item.Quantity;
                worksheet.Cells[row, 5].Value = item.SalePrice * item.Quantity;
                // ✅ ISEXTERNAL SHARTI - Effective cost price
                var costPrice = item.IsExternal ? item.ExternalCostPrice : item.CostPrice;
                worksheet.Cells[row, 6].Value = costPrice * item.Quantity;
                worksheet.Cells[row, 7].Value = item.Profit;
                row++;
            }
        }


        foreach (var zakup in zakups)
        {
            var product = await _unitOfWork.Products.GetByIdAsync(zakup.ProductId, cancellationToken);

            worksheet.Cells[row, 1].Value = zakup.CreatedAt.ToString("yyyy-MM-dd");
            worksheet.Cells[row, 2].Value = "Zakup";
            worksheet.Cells[row, 3].Value = product?.Name ?? "Unknown";
            worksheet.Cells[row, 4].Value = zakup.Quantity;
            worksheet.Cells[row, 5].Value = zakup.Quantity * zakup.CostPrice;
            worksheet.Cells[row, 6].Value = zakup.Quantity * zakup.CostPrice;
            worksheet.Cells[row, 7].Value = 0;
            row++;
        }
        
        worksheet.Cells.AutoFitColumns();

        return await package.GetAsByteArrayAsync();
    }

    public async Task<ComprehensiveReportDto> GetComprehensiveReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        // Get daily sales with SaleItems and Payments
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        // Get zakups
        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt < end && z.MarketId == marketId,
            cancellationToken);

        // Get all products for inventory report (filtered by market) with Category
        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId,
            cancellationToken,
            includeProperties: "Category");

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
                        totalProfit,  // Already filtered since this is only called when userRole == "Owner"
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
        bool includeProfit = userRole == "Owner";

        // Calculate inventory statistics
        int productCount = products.Count();
        int lowStockCount = products.Count(p => p.Quantity < 10 && p.Quantity > 0);
        int outOfStockCount = products.Count(p => p.Quantity <= 0);

        foreach (var product in products)
        {
            var totalCostValue = product.Quantity * product.CostPrice;
            var totalSaleValue = product.Quantity * product.SalePrice;
            decimal? potentialProfit = includeProfit ? totalSaleValue - totalCostValue : null;

            totalInventoryCost += totalCostValue;
            totalInventorySaleValue += totalSaleValue;

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
                product.Category?.Name,
                product.GetUnitName()
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

    public async Task<byte[]> ExportComprehensiveToExcelAsync(DateTime date, CancellationToken cancellationToken = default)
    {
        // Export to Excel is Owner-only feature, so pass "Owner" role
        var report = await GetComprehensiveReportAsync(date, "Owner", cancellationToken);

        using var package = new ExcelPackage();

        // 1. Summary Sheet
        var summarySheet = package.Workbook.Worksheets.Add("Summary");
        summarySheet.Cells[1, 1].Value = "Hisobot sanasi:";
        summarySheet.Cells[1, 2].Value = date.ToString("yyyy-MM-dd");
        summarySheet.Cells[2, 1].Value = "Jami savdo:";
        summarySheet.Cells[2, 2].Value = report.DailyReport.TotalSales;
        summarySheet.Cells[3, 1].Value = "Jami foyda:";
        summarySheet.Cells[3, 2].Value = report.DailyReport.Profit;
        summarySheet.Cells[4, 1].Value = "Jami tranzaksiyalar:";
        summarySheet.Cells[4, 2].Value = report.DailyReport.TotalTransactions;
        summarySheet.Cells[5, 1].Value = "Skladdagi tovarlar qiymati (xarid narxi):";
        summarySheet.Cells[5, 2].Value = report.TotalInventoryCost;
        summarySheet.Cells[6, 1].Value = "Skladdagi tovarlar qiymati (sotuv narxi):";
        summarySheet.Cells[6, 2].Value = report.TotalInventorySaleValue;

        using (var range = summarySheet.Cells[1, 1, 6, 2])
        {
            range.Style.Font.Bold = true;
        }

        // 2. Seller Reports Sheet
        var sellerSheet = package.Workbook.Worksheets.Add("Sotuvchilar");
        sellerSheet.Cells[1, 1].Value = "Sotuvchi";
        sellerSheet.Cells[1, 2].Value = "Jami savdo";
        sellerSheet.Cells[1, 3].Value = "Foyda";
        sellerSheet.Cells[1, 4].Value = "Tranzaksiyalar soni";

        using (var headerRange = sellerSheet.Cells[1, 1, 1, 4])
        {
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightBlue);
        }

        int row = 2;
        foreach (var seller in report.SellerReports)
        {
            sellerSheet.Cells[row, 1].Value = seller.SellerName;
            sellerSheet.Cells[row, 2].Value = seller.TotalSales;
            sellerSheet.Cells[row, 3].Value = seller.TotalProfit;
            sellerSheet.Cells[row, 4].Value = seller.TransactionCount;
            row++;
        }

        sellerSheet.Cells.AutoFitColumns();

        // 3. Inventory Sheet
        var inventorySheet = package.Workbook.Worksheets.Add("Sklad");
        inventorySheet.Cells[1, 1].Value = "Mahsulot";
        inventorySheet.Cells[1, 2].Value = "Miqdor";
        inventorySheet.Cells[1, 3].Value = "Xarid narxi";
        inventorySheet.Cells[1, 4].Value = "Sotuv narxi";
        inventorySheet.Cells[1, 5].Value = "Minimal narx";
        inventorySheet.Cells[1, 6].Value = "Jami xarid qiymati";
        inventorySheet.Cells[1, 7].Value = "Jami sotuv qiymati";
        inventorySheet.Cells[1, 8].Value = "Potensial foyda";

        using (var headerRange = inventorySheet.Cells[1, 1, 1, 8])
        {
            headerRange.Style.Font.Bold = true;
            headerRange.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
            headerRange.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGreen);
        }

        row = 2;
        foreach (var item in report.InventoryReport)
        {
            inventorySheet.Cells[row, 1].Value = item.ProductName;
            inventorySheet.Cells[row, 2].Value = item.Quantity;
            inventorySheet.Cells[row, 3].Value = item.CostPrice;
            inventorySheet.Cells[row, 4].Value = item.SalePrice;
            inventorySheet.Cells[row, 5].Value = item.MinSalePrice;
            inventorySheet.Cells[row, 6].Value = item.TotalCostValue;
            inventorySheet.Cells[row, 7].Value = item.TotalSaleValue;
            inventorySheet.Cells[row, 8].Value = item.PotentialProfit;
            row++;
        }

        inventorySheet.Cells.AutoFitColumns();

        return await package.GetAsByteArrayAsync();
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
        bool includeProfit = userRole == "Owner";

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
        var now = DateTime.UtcNow;

        // Today
        var (todayStart, todayEnd) = GetUtcDateRange(now);

        // Week
        var weekStart = ToUtcDate(now.Date.AddDays(-(int)now.DayOfWeek));

        // Month
        var monthStart = ToUtcDate(new DateTime(now.Year, now.Month, 1));

        var todaySales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= todayStart && s.CreatedAt < todayEnd &&
                 s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var weekSales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= weekStart && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var monthSales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= monthStart && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var allSales = await _unitOfWork.Sales.FindAsync(
            s => s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        return new ProfitSummaryDto(
            CalculateProfitFromSales(todaySales),
            CalculateProfitFromSales(weekSales),
            CalculateProfitFromSales(monthSales),
            CalculateProfitFromSales(allSales)
        );
    }

    public async Task<CashBalanceDto> GetCashBalanceAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var now = DateTime.UtcNow;

        // Get today's date range in current market's timezone
        var (todayStart, todayEnd) = GetUtcDateRange(now);

        // Get all payments for today
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= todayStart && s.CreatedAt < todayEnd &&
                 s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
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

    public async Task<DailySalesListDto> GetDailySalesListAsync(
        DateTime date,
        string? userRole = null,
        Guid? userId = null,
        CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var (start, end) = GetUtcDateRange(date);

        Expression<Func<Sale, bool>> salesQuery = s => s.CreatedAt >= start && s.CreatedAt < end &&
                              s.Status != SaleStatus.Cancelled &&
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

        bool includeProfit = userRole == "Owner";

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
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId,
            cancellationToken);
        var productDict = products.ToDictionary(p => p.Id);

        bool includeProfit = userRole == "Owner";
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

        // Use AppDbContext for complex query with proper includes
        // This is done via the unit of work's context if accessible
        // For now, use the repository and get products in batch
        Expression<Func<Sale, bool>> salesQuery = s => s.CreatedAt >= start && s.CreatedAt < end &&
                              s.Status != SaleStatus.Cancelled &&
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

        bool includeProfit = userRole == "Owner";
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

    public async Task<byte[]> ExportSalesListToPdfAsync(DateTime? startDate, DateTime? endDate, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Get all sales if no date range specified
        var start = startDate.HasValue ? ToUtcDate(startDate.Value) : DateTime.MinValue;
        var end = endDate.HasValue ? ToUtcDate(endDate.Value.AddDays(1)) : DateTime.UtcNow.AddDays(1);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end &&
                 s.Status != SaleStatus.Cancelled &&
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

        // Owner role check - null or non-owner means no profit visibility
        bool includeProfit = !string.IsNullOrEmpty(userRole) && userRole == Role.Owner.ToString();
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
                    sale.Customer?.FullName ?? "Mijoz yo'q",
                    sale.Seller?.FullName ?? "Noma'lum",
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

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(1, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(9));

                    // Header
                    page.Header().Element(header =>
                    {
                        header.Column(column =>
                        {
                            column.Item().Row(row =>
                            {
                                row.RelativeItem().Column(col =>
                                {
                                    col.Item().Text("SOTUVLAR HISOBOTI").FontSize(16).Bold();
                                    col.Item().Text(
                                        startDate.HasValue && endDate.HasValue
                                            ? $"{startDate.Value:dd.MM.yyyy} - {endDate.Value:dd.MM.yyyy}"
                                            : "Barcha vaqt")
                                        .FontSize(10).Light();
                                });
                            });
                            column.Item().PaddingVertical(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                        });
                    });

                    // Content - Table
                    page.Content().Element(content =>
                    {
                        content.Table(table =>
                        {
                            // Define columns - always include profit column for consistency
                            // It will be hidden if includeProfit is false
                            table.ColumnsDefinition(columns =>
                            {
                                columns.ConstantColumn(25);  // #
                                columns.ConstantColumn(70); // Date
                                columns.RelativeColumn(2);  // Customer
                                columns.RelativeColumn(2);  // Seller
                                columns.RelativeColumn(2);  // Product
                                columns.ConstantColumn(50); // Quantity
                                columns.ConstantColumn(60); // Cost
                                columns.ConstantColumn(60); // Price
                                columns.ConstantColumn(70); // Total
                                columns.ConstantColumn(60); // Profit (always defined, conditionally shown)
                                columns.ConstantColumn(50); // Status
                            });

                            // Table Header
                            table.Header(header =>
                            {
                                header.Cell().Element(HeaderStyle).Text("#").SemiBold();
                                header.Cell().Element(HeaderStyle).Text("Sana").SemiBold();
                                header.Cell().Element(HeaderStyle).Text("Mijoz").SemiBold();
                                header.Cell().Element(HeaderStyle).Text("Sotuvchi").SemiBold();
                                header.Cell().Element(HeaderStyle).Text("Mahsulot").SemiBold();
                                header.Cell().Element(HeaderStyle).AlignRight().Text("Miqdor").SemiBold();
                                header.Cell().Element(HeaderStyle).AlignRight().Text("Xarid").SemiBold();
                                header.Cell().Element(HeaderStyle).AlignRight().Text("Narx").SemiBold();
                                header.Cell().Element(HeaderStyle).AlignRight().Text("Jami").SemiBold();
                                header.Cell().Element(HeaderStyle).AlignRight().Text("Foyda").SemiBold();
                                header.Cell().Element(HeaderStyle).Text("Holat").SemiBold();
                            });

                            // Table Rows
                            foreach (var item in reportItems)
                            {
                                table.Cell().Element(RowStyle).Text($"{item.Number}");
                                table.Cell().Element(RowStyle).Text(item.Date.ToString("dd.MM HH:mm"));
                                table.Cell().Element(RowStyle).Text(item.CustomerName);
                                table.Cell().Element(RowStyle).Text(item.SellerName);
                                table.Cell().Element(RowStyle).Text(item.ProductName);
                                table.Cell().Element(RowStyle).AlignRight().Text($"{item.Quantity:N2}");
                                table.Cell().Element(RowStyle).AlignRight().Text($"{item.CostPrice:N0}");
                                table.Cell().Element(RowStyle).AlignRight().Text($"{item.SalePrice:N0}");
                                table.Cell().Element(RowStyle).AlignRight().Text($"{item.TotalPrice:N0}").Bold();
                                if (includeProfit && item.Profit.HasValue)
                                {
                                    table.Cell().Element(RowStyle).AlignRight().Text($"{item.Profit.Value:N0}")
                                        .FontColor(item.Profit.Value >= 0 ? Colors.Green.Darken2 : Colors.Red.Darken2);
                                }
                                else
                                {
                                    table.Cell().Element(RowStyle).AlignRight().Text("-");
                                }
                                table.Cell().Element(RowStyle).Text(item.Status);
                            }
                        });
                    });

                    // Footer with totals
                    page.Footer().Element(footer =>
                    {
                        footer.PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                        footer.PaddingTop(5).Row(row =>
                        {
                            row.RelativeItem();
                            row.ConstantItem(150).Text("Jami savdo:").SemiBold();
                            row.ConstantItem(100).Text($"{totalSales:N0} so'm").Bold();
                            if (includeProfit)
                            {
                                row.ConstantItem(100).Text("Jami foyda:").SemiBold();
                                row.ConstantItem(100).Text($"{totalProfit:N0} so'm")
                                    .Bold()
                                    .FontColor(totalProfit >= 0 ? Colors.Green.Darken2 : Colors.Red.Darken2);
                            }
                        });
                        footer.PaddingTop(5).AlignCenter().Text(x =>
                        {
                            x.Span("Sahifa ");
                            x.CurrentPageNumber();
                        });
                    });
                });
            }).GeneratePdf();
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"Sales list PDF generation failed: {ex.Message}", ex);
        }
    }

    public Task<byte[]> ExportDailyReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException("PDF export functionality is currently being updated. Please use Excel export instead.");
    }

    public Task<byte[]> ExportPeriodReportToPdfAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException("PDF export functionality is currently being updated. Please use Excel export instead.");
    }

    public Task<byte[]> ExportComprehensiveReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        throw new NotImplementedException("PDF export functionality is currently being updated. Please use Excel export instead.");
    }

    public async Task<byte[]> GenerateInvoicePdfAsync(Guid saleId, string? userRole = null, CancellationToken cancellationToken = default)
    {
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
        string sellerName = "Noma'lum sotuvchi";
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
        string customerName = "Mijoz ko'rsatilmagan";
        if (customer != null)
        {
            customerName = customer.FullName ?? "Mijoz ko'rsatilmagan";
        }
        else if (sale.CustomerId.HasValue)
        {
            // Try to get customer name from database even if deleted
            var deletedCustomer = await _unitOfWork.Customers.GetByIdIncludingDeletedAsync(sale.CustomerId.Value, cancellationToken);
            if (deletedCustomer != null)
            {
                customerName = deletedCustomer.FullName ?? "Mijoz ko'rsatilmagan";
            }
        }

        // ✅ Get all ordinary products for the sale items (faqat oddiy mahsulotlar uchun)
        var ordinaryProductIds = sale.SaleItems
            .Where(si => !si.IsExternal && si.ProductId.HasValue)
            .Select(si => si.ProductId.Value)
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
        string paymentTypeUz = paymentTypeEnum.ToUzbek();

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
                    productName = product?.Name ?? "Noma'lum mahsulot";
                }
            }
            else
            {
                // Tashqi mahsulot
                productName = item.ExternalProductName ?? "Noma'lum mahsulot";
            }
            invoiceItems.Add(new InvoiceItemData(
                productName,
                item.Quantity,
                item.SalePrice,
                item.SalePrice * item.Quantity,
                item.Comment
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
            sale.TotalAmount - sale.PaidAmount
        );

        // Generate PDF using QuestPDF
        try
        {
            return Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(2, Unit.Centimetre);
                page.DefaultTextStyle(x => x.FontSize(10));

                // Header
                page.Header().Element(header =>
                {
                    header.Column(column =>
                    {
                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Column(col =>
                            {
                                col.Item().Text(invoiceData.MarketName).FontSize(18).Bold();
                                col.Item().Text(invoiceData.MarketDescription).FontSize(10).Light();
                            });
                            row.ConstantItem(100).AlignRight().Text("FAKTURA").FontSize(12).Bold();
                        });
                        column.Item().PaddingVertical(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                    });
                });

                // Content
                page.Content().Element(content =>
                {
                    content.Column(column =>
                    {
                        // Invoice details
                        column.Spacing(10);

                        column.Item().Row(row =>
                        {
                            row.RelativeItem().Column(col =>
                            {
                                col.Item().Text("Faktura №:").SemiBold();
                                col.Item().Text(invoiceData.InvoiceNumber.ToString());
                                col.Item().Text("Sana:").SemiBold();
                                col.Item().Text(invoiceData.Date.ToString("dd.MM.yyyy HH:mm"));
                            });

                            row.RelativeItem().Column(col =>
                            {
                                col.Item().Text("Sotuvchi:").SemiBold();
                                col.Item().Text(invoiceData.SellerName);
                                col.Item().Text("Mijoz:").SemiBold();
                                col.Item().Text(invoiceData.CustomerName);
                            });
                        });

                        column.Item().PaddingVertical(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);

                        // Items table
                        column.Item().Element(e =>
                        {
                            e.Table(table =>
                            {
                                table.ColumnsDefinition(columns =>
                                {
                                    columns.ConstantColumn(30);
                                    columns.RelativeColumn(3);
                                    columns.ConstantColumn(60);
                                    columns.ConstantColumn(80);
                                    columns.RelativeColumn(2);
                                });

                                table.Header(header =>
                                {
                                    header.Cell().Element(CellStyle).Text("#");
                                    header.Cell().Element(CellStyle).Text("Mahsulot").SemiBold();
                                    header.Cell().Element(CellStyle).AlignRight().Text("Miqdor");
                                    header.Cell().Element(CellStyle).AlignRight().Text("Narx");
                                    header.Cell().Element(CellStyle).AlignRight().Text("Jami").SemiBold();
                                });

                                int index = 1;
                                foreach (var item in invoiceData.Items)
                                {
                                    table.Cell().Element(CellStyle).Text($"{index++}");
                                    table.Cell().Element(CellStyle).Text(item.ProductName);
                                    table.Cell().Element(CellStyle).AlignRight().Text($"{item.Quantity:N2}");
                                    table.Cell().Element(CellStyle).AlignRight().Text($"{item.Price:N2} so'm");
                                    table.Cell().Element(CellStyle).AlignRight().Text($"{item.Total:N2} so'm");

                                    if (!string.IsNullOrEmpty(item.Comment))
                                    {
                                        table.Cell().ColumnSpan(5).Element(CommentStyle).Text($"Izoh: {item.Comment}").FontSize(8);
                                    }
                                }
                            });
                        });

                        column.Item().PaddingVertical(10).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);

                        // Totals
                        column.Item().AlignRight().Element(e =>
                        {
                            e.Table(table =>
                            {
                                table.ColumnsDefinition(columns =>
                                {
                                    columns.RelativeColumn(2);
                                    columns.ConstantColumn(100);
                                });

                                table.Cell().Element(TotalCellStyle).Text("To'lov turi:");
                                table.Cell().Element(TotalCellStyle).AlignRight().Text(invoiceData.PaymentType).SemiBold();

                                table.Cell().Element(TotalCellStyle).Text("Jami summa:").Bold();
                                table.Cell().Element(TotalCellStyle).AlignRight().Text($"{invoiceData.TotalAmount:N2} so'm").Bold();

                                table.Cell().Element(TotalCellStyle).Text("To'langan:");
                                table.Cell().Element(TotalCellStyle).AlignRight().Text($"{invoiceData.PaidAmount:N2} so'm");

                                if (invoiceData.RemainingAmount > 0)
                                {
                                    table.Cell().Element(TotalCellStyle).Text("Qarzdorlik:").Bold().FontColor(Colors.Red.Medium);
                                    table.Cell().Element(TotalCellStyle).AlignRight().Text($"{invoiceData.RemainingAmount:N2} so'm").Bold().FontColor(Colors.Red.Medium);
                                }
                            });
                        });
                    });
                });

                // Footer
                page.Footer().AlignCenter().Text(x =>
                {
                    x.Span("Sahifa ");
                    x.CurrentPageNumber();
                });
            });
        }).GeneratePdf();
        }
        catch (Exception ex)
        {
            throw new InvalidOperationException($"PDF generation failed for sale {saleId}: {ex.Message}", ex);
        }
    }

    private static IContainer CellStyle(IContainer container)
    {
        return container
            .Border(1)
            .BorderColor(Colors.Grey.Lighten2)
            .Padding(5)
            .AlignCenter()
            .AlignMiddle();
    }

    private static IContainer CommentStyle(IContainer container)
    {
        return container
            .Border(1)
            .BorderColor(Colors.Grey.Lighten2)
            .PaddingLeft(35)
            .AlignLeft()
            .AlignMiddle();
    }

    private static IContainer TotalCellStyle(IContainer container)
    {
        return container
            .Padding(3)
            .AlignRight();
    }

    // Invoice data classes
    private record InvoiceData(
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
        decimal RemainingAmount
    );

    private record InvoiceItemData(
        string ProductName,
        decimal Quantity,
        decimal Price,
        decimal Total,
        string? Comment
    );

    private record SalesReportItem(
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

    private static DateTime ToUtcDate(DateTime date)
    {
        return DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
    }

    private static (DateTime Start, DateTime End) GetUtcDateRange(DateTime date)
    {
        var start = ToUtcDate(date);
        var end = ToUtcDate(date.AddDays(1));
        return (start, end);
    }
}