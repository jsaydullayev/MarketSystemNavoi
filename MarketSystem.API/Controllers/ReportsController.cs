using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AdminOrOwner")]
public class ReportsController : ControllerBase
{
    private readonly IReportService _reportService;

    public ReportsController(IReportService reportService)
    {
        _reportService = reportService;
    }

    /// <summary>
    /// Get daily sales report
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<DailyReportDto>> GetDailyReport([FromQuery] DateTime date)
    {
        var report = await _reportService.GetDailyReportAsync(date);
        return Ok(report);
    }

    /// <summary>
    /// Get sales report for a period
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PeriodReportDto>> GetPeriodReport(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var request = new PeriodReportRequest(start, end);
        var report = await _reportService.GetPeriodReportAsync(request);
        return Ok(report);
    }

    /// <summary>
    /// Export sales report to Excel
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ExportToExcel(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        if (start > end)
            return BadRequest("Start date cannot be after end date");

        var request = new PeriodReportRequest(start, end);
        var excelBytes = await _reportService.ExportToExcelAsync(request);

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"report_{start:yyyyMMdd}_{end:yyyyMMdd}.xlsx"
        );
    }

    /// <summary>
    /// Get comprehensive report including seller stats and inventory
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<ComprehensiveReportDto>> GetComprehensiveReport([FromQuery] DateTime date)
    {
        var report = await _reportService.GetComprehensiveReportAsync(date);
        return Ok(report);
    }

    /// <summary>
    /// Export comprehensive report to Excel
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ExportComprehensiveToExcel([FromQuery] DateTime date)
    {
        var excelBytes = await _reportService.ExportComprehensiveToExcelAsync(date);

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"comprehensive_report_{date:yyyyMMdd}.xlsx"
        );
    }
}
