using MarketSystem.Application.DTOs;

namespace MarketSystem.Domain.Interfaces;

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

    // PDF export methods (temporarily disabled - being updated)
    Task<byte[]> ExportDailyReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportPeriodReportToPdfAsync(PeriodReportRequest request, string? userRole = null, CancellationToken cancellationToken = default);
    Task<byte[]> ExportComprehensiveReportToPdfAsync(DateTime date, string? userRole = null, CancellationToken cancellationToken = default);
}
