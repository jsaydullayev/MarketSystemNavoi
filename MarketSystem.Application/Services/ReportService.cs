using OfficeOpenXml;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.Application.Services;

public class ReportService : IReportService
{
    private readonly IUnitOfWork _unitOfWork;

    public ReportService(IUnitOfWork unitOfWork)
    {
        _unitOfWork = unitOfWork;

        // Set EPPlus license context (EPPlus 7.x)
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
    }

    public async Task<DailyReportDto> GetDailyReportAsync(DateTime date, CancellationToken cancellationToken = default)
    {
        var start = date.Date;
        var end = date.Date.AddDays(1);

        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= start && s.CreatedAt < end && s.Status != SaleStatus.Cancelled,
            cancellationToken);

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= start && z.CreatedAt < end,
            cancellationToken);

        return CalculateReport(sales, zakups, start, end);
    }

    public async Task<PeriodReportDto> GetPeriodReportAsync(PeriodReportRequest request, CancellationToken cancellationToken = default)
    {
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt <= request.EndDate && s.Status != SaleStatus.Cancelled,
            cancellationToken);

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt <= request.EndDate,
            cancellationToken);

        var report = CalculateReport(sales, zakups, request.StartDate, request.EndDate);

        return new PeriodReportDto(
            request.StartDate,
            request.EndDate,
            report.TotalSales,
            report.TotalZakup,
            report.Profit,
            report.NetIncome,
            report.TotalTransactions
        );
    }

    public async Task<byte[]> ExportToExcelAsync(PeriodReportRequest request, CancellationToken cancellationToken = default)
    {
        var sales = await _unitOfWork.Sales.FindAsync(
            s => s.CreatedAt >= request.StartDate && s.CreatedAt <= request.EndDate && s.Status != SaleStatus.Cancelled,
            cancellationToken);

        var zakups = await _unitOfWork.Zakups.FindAsync(
            z => z.CreatedAt >= request.StartDate && z.CreatedAt <= request.EndDate,
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

    private static DailyReportDto CalculateReport(
        IEnumerable<Sale> sales,
        IEnumerable<Zakup> zakups,
        DateTime start,
        DateTime end)
    {
        decimal totalSales = 0;
        decimal totalCost = 0;     // Cost of goods sold
        decimal totalProfit = 0;    // Actual profit from sales
        int totalTransactions = sales.Count();

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
                totalProfit += itemProfit;
            }
        }

        decimal totalZakup = zakups.Sum(z => z.Quantity * z.CostPrice);

        // Net income = Profit - Operating expenses (currently 0)
        decimal netIncome = totalProfit;

        return new DailyReportDto(
            start,
            totalSales,
            totalZakup,
            totalProfit,
            netIncome,
            totalTransactions
        );
    }
}
