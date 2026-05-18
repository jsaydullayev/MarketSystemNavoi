using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IReportService
{
    Task<DailyReportDto> GetDailyReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
    Task<DailySaleItemsResponseDto> GetDailySaleItemsAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
    Task<PeriodReportDto> GetPeriodReportAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportToExcelAsync(PeriodReportRequest request, CancellationToken cancellationToken = default);
    Task<ComprehensiveReportDto> GetComprehensiveReportAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportComprehensiveToExcelAsync(DateTime date, CancellationToken cancellationToken = default);

    // New methods for role-based access control
    Task<ProfitSummaryDto> GetProfitSummaryAsync(CancellationToken cancellationToken = default);
    Task<CashBalanceDto> GetCashBalanceAsync(CancellationToken cancellationToken = default);
    Task<DailySalesListDto> GetDailySalesListAsync(DateTime date, string? userRole = null, Guid? userId = null, CancellationToken cancellationToken = default);
    Task<MonthlyCategorySalesResponseDto> GetMonthlyCategorySalesAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);

    // Detailed sales with items for export
    Task<List<SaleWithItemsDto>> GetSalesWithItemsAsync(DateTime startDate, DateTime endDate, string? userRole = null, Guid? userId = null, CancellationToken cancellationToken = default);

    // PDF export methods (temporarily disabled - being updated)
    Task<byte[]> ExportDailyReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportPeriodReportToPdfAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportComprehensiveReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);

    // Invoice generation
    Task<byte[]> GenerateInvoicePdfAsync(Guid saleId, string? userRole = null, CancellationToken cancellationToken = default);

    // Sales list export to PDF
    Task<byte[]> ExportSalesListToPdfAsync(DateTime? startDate, DateTime? endDate, string? userRole = null, CancellationToken cancellationToken = default);

    // Dashboard aggregations — added 2026-05-18 to back the new design's
    // ChartCard (weekly bar series), TopSellersCard (ranking), and the
    // Users / Reports → Staff page. All three are read-only aggregations
    // over existing tables; no new domain entities required.
    Task<WeeklySeriesDto> GetWeeklySeriesAsync(int days, bool compare = false, string? userRole = null, CancellationToken cancellationToken = default);
    Task<TopProductsDto> GetTopProductsAsync(string period, string sortBy, int limit, string? userRole = null, CancellationToken cancellationToken = default);
    Task<StaffPerformanceDto> GetStaffPerformanceAsync(string period, CancellationToken cancellationToken = default);
}
