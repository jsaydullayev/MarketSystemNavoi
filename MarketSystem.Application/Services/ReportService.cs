using OfficeOpenXml;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Application.Interfaces;
using System.Linq.Expressions;

namespace MarketSystem.Application.Services;

public class ReportService : IReportService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly ICurrentMarketService _currentMarketService;

    public ReportService(IUnitOfWork unitOfWork, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _currentMarketService = currentMarketService;

        // Set EPPlus license context (EPPlus 7.x)
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
    }

    public async Task<DailyReportDto> GetDailyReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var start = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(date.Date.AddDays(1), DateTimeKind.Utc);

        // Include SaleItems and Payments for proper profit calculation
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
        var start = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(date.Date.AddDays(1), DateTimeKind.Utc);

        // Include SaleItems for detailed breakdown
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems");

        // Determine if profit should be included (Owner only)
        bool includeProfit = userRole == "Owner";

        // Group by product and aggregate
        var productGroups = new Dictionary<string, DailySaleItemDto>();

        foreach (var sale in sales)
        {
            foreach (var item in sale.SaleItems)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId, cancellationToken);
                if (product == null) continue;

                var productName = product.Name;
                var quantity = item.Quantity;
                var costPrice = item.CostPrice;
                var salePrice = item.SalePrice;
                var totalCost = costPrice * quantity;
                var totalRevenue = salePrice * quantity;
                decimal? profit = includeProfit ? totalRevenue - totalCost : null;

                if (productGroups.ContainsKey(productName))
                {
                    var existing = productGroups[productName];
                    productGroups[productName] = existing with
                    {
                        Quantity = existing.Quantity + quantity,
                        TotalCost = existing.TotalCost + totalCost,
                        TotalRevenue = existing.TotalRevenue + totalRevenue,
                        Profit = existing.Profit.HasValue && profit.HasValue
                            ? existing.Profit.Value + profit.Value
                            : null
                    };
                }
                else
                {
                    productGroups[productName] = new DailySaleItemDto(
                        productName,
                        quantity,
                        costPrice,
                        salePrice,
                        totalCost,
                        totalRevenue,
                        profit
                    );
                }
            }
        }

        return new DailySaleItemsResponseDto(
            start,
            productGroups.Values.ToList()
        );
    }

    public async Task<PeriodReportDto> GetPeriodReportAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();

        // Include SaleItems and Payments for proper profit calculation
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt <= request.EndDate && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt <= request.EndDate && z.MarketId == marketId,
            cancellationToken);

        var report = CalculateReport(sales, zakups, request.StartDate, request.EndDate, userRole);

        // Calculate average sale
        decimal averageSale = report.TotalTransactions > 0
            ? report.TotalSales / report.TotalTransactions
            : 0;

        return new PeriodReportDto(
            request.StartDate,
            request.EndDate,
            report.TotalSales,
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

        // Include SaleItems for proper data export
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt <= request.EndDate && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt <= request.EndDate && z.MarketId == marketId,
            cancellationToken);

        using var package = new ExcelPackage();
        var worksheet = package.Workbook.Worksheets.Add("Report");

        // Headers
        worksheet.Cells[1, 1].Value = "Date";
        worksheet.Cells[1, 2].Value = "Type";
        worksheet.Cells[1, 3].Value = "Product";
        worksheet.Cells[1, 4].Value = "Quantity";
        worksheet.Cells[1, 5].Value = "Amount";
        worksheet.Cells[1, 6].Value = "Cost";
        worksheet.Cells[1, 7].Value = "Profit";

        // Style headers
        using (var range = worksheet.Cells[1, 1, 1, 7])
        {
            range.Style.Font.Bold = true;
            range.Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
            range.Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.LightGray);
        }

        int row = 2;

        // Add sales data
        foreach (var sale in sales)
        {
            var saleItems = await _unitOfWork.SaleItems.FindAsync(si => si.SaleId == sale.Id, cancellationToken);

            foreach (var item in saleItems)
            {
                var product = await _unitOfWork.Products.GetByIdAsync(item.ProductId, cancellationToken);

                worksheet.Cells[row, 1].Value = sale.CreatedAt.ToString("yyyy-MM-dd");
                worksheet.Cells[row, 2].Value = "Sale";
                worksheet.Cells[row, 3].Value = product?.Name ?? "Unknown";
                worksheet.Cells[row, 4].Value = item.Quantity;
                worksheet.Cells[row, 5].Value = item.SalePrice * item.Quantity;
                worksheet.Cells[row, 6].Value = item.CostPrice * item.Quantity;
                worksheet.Cells[row, 7].Value = item.Profit;
                row++;
            }
        }

        // Add zakup data
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

        // AutoFit columns
        worksheet.Cells.AutoFitColumns();

        return await package.GetAsByteArrayAsync();
    }

    public async Task<ComprehensiveReportDto> GetComprehensiveReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var start = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(date.Date.AddDays(1), DateTimeKind.Utc);

        // Get daily sales with SaleItems and Payments
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "SaleItems,Payments");

        // Get zakups
        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt < end && z.MarketId == marketId,
            cancellationToken);

        // Get all products for inventory report (filtered by market)
        var products = await _unitOfWork.Products.FindAsync(
            p => p.MarketId == marketId,
            cancellationToken);

        // Calculate daily report
        var dailyReport = CalculateReport(sales, zakups, start, end);

        // Calculate seller reports - ONLY FOR OWNER
        var sellerReports = new List<SellerReportDto>();

        // Only Owner can see seller reports
        if (userRole == "Owner")
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
                            var itemCost = item.CostPrice * item.Quantity;
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
                potentialProfit
            ));
        }

        return new ComprehensiveReportDto(
            date,
            dailyReport,
            sellerReports,
            inventoryReport,
            totalInventoryCost,
            totalInventorySaleValue
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
        decimal totalSales = 0;
        decimal totalCost = 0;     // Cost of goods sold
        decimal totalProfit = 0;    // Actual profit from sales
        int totalTransactions = sales.Count();

        // Determine if profit should be included (Owner only)
        bool includeProfit = userRole == "Owner";

        // Calculate payment breakdown
        var paymentBreakdown = new Dictionary<string, decimal>();
        var paymentCounts = new Dictionary<string, int>();

        // Calculate from sales and their items
        foreach (var sale in sales)
        {
            totalSales += sale.TotalAmount;

            // Calculate cost and profit from each sale item
            foreach (var item in sale.SaleItems)
            {
                var itemCost = item.CostPrice * item.Quantity;
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

        return new DailyReportDto(
            start,
            totalSales,
            totalZakup,
            profit,
            netIncome,
            totalTransactions,
            paymentBreakdownList
        );
    }

    // New methods for role-based access control
    public async Task<ProfitSummaryDto> GetProfitSummaryAsync(CancellationToken cancellationToken = default)
    {
        var marketId = _currentMarketService.GetCurrentMarketId();
        var now = DateTime.UtcNow;

        // Today
        var todayStart = DateTime.SpecifyKind(now.Date, DateTimeKind.Utc);
        var todayEnd = DateTime.SpecifyKind(now.Date.AddDays(1), DateTimeKind.Utc);

        // Week
        var weekStart = DateTime.SpecifyKind(now.Date.AddDays(-(int)now.DayOfWeek), DateTimeKind.Utc);

        // Month
        var monthStart = DateTime.SpecifyKind(new DateTime(now.Year, now.Month, 1), DateTimeKind.Utc);

        // All time
        var allTimeStart = DateTime.SpecifyKind(DateTime.MinValue, DateTimeKind.Utc);

        var todaySales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= todayStart && s.CreatedAt < todayStart.AddDays(1) &&
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
        var todayStart = DateTime.SpecifyKind(now.Date, DateTimeKind.Utc);
        var todayEnd = DateTime.SpecifyKind(now.Date.AddDays(1), DateTimeKind.Utc);

        // Get all payments for today
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= todayStart && s.CreatedAt < todayEnd &&
                 s.Status != SaleStatus.Cancelled && s.MarketId == marketId,
            cancellationToken,
            includeProperties: "Payments");

        decimal cashInRegister = 0;
        decimal cardPayments = 0;

        foreach (var sale in sales)
        {
            foreach (var payment in sale.Payments)
            {
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
        var start = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var end = DateTime.SpecifyKind(date.Date.AddDays(1), DateTimeKind.Utc);

        // Build query with role-based filtering
        // If Seller, filter by their own sales only
        Expression<Func<Sale, bool>> salesQuery = s => s.CreatedAt >= start && s.CreatedAt < end &&
                              s.Status != SaleStatus.Cancelled &&
                              s.MarketId == marketId &&
                              (userRole != "Seller" || s.SellerId == userId);

        var sales = await _unitOfWork.Sales.FindAsync(
            salesQuery,
            cancellationToken,
            includeProperties: "SaleItems,Payments,Seller,Customer");

        var salesListItems = new List<DailySalesListItemDto>();
        decimal totalSales = 0;

        // Determine if profit should be included (Owner only)
        bool includeProfit = userRole == "Owner";

        foreach (var sale in sales)
        {
            totalSales += sale.TotalAmount;

            // Calculate profit for this sale
            decimal? profit = null;
            if (includeProfit)
            {
                profit = 0;
                foreach (var item in sale.SaleItems)
                {
                    var itemCost = item.CostPrice * item.Quantity;
                    var itemRevenue = item.SalePrice * item.Quantity;
                    profit += itemRevenue - itemCost;
                }
            }

            // Get primary payment type - convert to lowercase format
            var primaryPayment = sale.Payments.FirstOrDefault();
            var paymentTypeRaw = primaryPayment?.PaymentType.ToString() ?? "Cash";
            var paymentType = paymentTypeRaw.ToLowerInvariant();

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

        // Calculate summary profit for Owner only
        decimal? summaryProfit = null;
        if (includeProfit && salesListItems.Any())
        {
            summaryProfit = salesListItems.Sum(s => s.Profit ?? 0);
        }

        return new DailySalesListDto(
            start,
            salesListItems,
            totalSales,
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
                var itemCost = item.CostPrice * item.Quantity;
                var itemRevenue = item.SalePrice * item.Quantity;
                profit += itemRevenue - itemCost;
            }
        }

        return profit;
    }
}
