using MarketSystem.Application.DTOs;

namespace MarketSystem.Domain.Interfaces;

public interface IReportService
{
    Task<DailyReportDto> GetDailyReportAsync(DateTime date, CancellationToken cancellationToken = default);
    Task<PeriodReportDto> GetPeriodReportAsync(PeriodReportRequest request, CancellationToken cancellationToken = default);
    Task<byte[]> ExportToExcelAsync(PeriodReportRequest request, CancellationToken cancellationToken = default);
}
