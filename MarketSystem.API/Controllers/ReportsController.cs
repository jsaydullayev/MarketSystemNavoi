using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;

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
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var report = await _reportService.GetDailyReportAsync(utcDate, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Get daily sale items - detailed list of products sold on specific date
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<DailySaleItemsResponseDto>> GetDailySaleItems([FromQuery] DateTime date)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var saleItems = await _reportService.GetDailySaleItemsAsync(utcDate, userRole);
        return Ok(saleItems);
    }

    /// <summary>
    /// Get sales report for a period
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<PeriodReportDto>> GetPeriodReport(
        [FromQuery] DateTime start,
        [FromQuery] DateTime end)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        if (start > end)
            return BadRequest("Start date cannot be after end date");

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var report = await _reportService.GetPeriodReportAsync(request, userRole);
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

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcStart = DateTime.SpecifyKind(start.Date, DateTimeKind.Utc);
        var utcEnd = DateTime.SpecifyKind(end.Date, DateTimeKind.Utc);

        var request = new PeriodReportRequest(utcStart, utcEnd);
        var excelBytes = await _reportService.ExportToExcelAsync(request);

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
    [HttpGet]
    public async Task<ActionResult<ComprehensiveReportDto>> GetComprehensiveReport([FromQuery] DateTime date)
    {
        // Get user role from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;

        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var report = await _reportService.GetComprehensiveReportAsync(utcDate, userRole);
        return Ok(report);
    }

    /// <summary>
    /// Export comprehensive report to Excel
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> ExportComprehensiveToExcel([FromQuery] DateTime date)
    {
        // Convert to UTC to prevent PostgreSQL DateTime Kind error
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var excelBytes = await _reportService.ExportComprehensiveToExcelAsync(utcDate);

        return File(
            excelBytes,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"comprehensive_report_{date:yyyyMMdd}.xlsx"
        );
    }

    // New endpoints for role-based access control

    /// <summary>
    /// Get profit summary - Owner only
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<ProfitSummaryDto>> GetProfitSummary()
    {
        var summary = await _reportService.GetProfitSummaryAsync();
        return Ok(summary);
    }

    /// <summary>
    /// Get cash balance - Owner only
    /// </summary>
    [HttpGet]
    [Authorize(Policy = "OwnerOnly")]
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
    [HttpGet]
    [Authorize(Policy = "AllRoles")]
    public async Task<ActionResult<DailySalesListDto>> GetDailySalesList([FromQuery] DateTime date)
    {
        // Get user role and ID from JWT token
        var userRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var userIdString = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Guid? userId = Guid.TryParse(userIdString, out var parsedId) ? parsedId : null;

        // FIX: The date from query parameter is in local time (browser sends "2026-02-19")
        // We need to convert it to UTC date range.
        // Example: User in UTC+5 creates sale at 10:00 local time -> stored as 05:00 UTC
        // When user queries "2026-02-19", they want to see that sale.
        // The query date "2026-02-19 00:00:00" (local) = "2026-02-18 19:00:00" (UTC)
        // So we should query from that UTC time to +24 hours.

        // Actually, let's use a simpler approach:
        // The date parameter comes as unspecified kind DateTime from the query string.
        // ASP.NET binds "2026-02-19" as DateTime with Kind = Unspecified.
        // We treat it as UTC for the query.
        var utcDate = DateTime.SpecifyKind(date.Date, DateTimeKind.Utc);
        var salesList = await _reportService.GetDailySalesListAsync(utcDate, userRole, userId);
        return Ok(salesList);
    }
}
