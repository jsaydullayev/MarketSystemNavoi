using MediatR;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using OfficeOpenXml;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Queries;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "Admin,Owner")]
public class ReportsController : ControllerBase
{
    private readonly IMediator _mediator;

    public ReportsController(IMediator mediator)
    {
        _mediator = mediator;
        ExcelPackage.LicenseContext = LicenseContext.NonCommercial;
    }

    [HttpGet("sales")]
    public async Task<ActionResult<SalesReportResponse>> GetSalesReport(
        [FromQuery] Guid branchId,
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        var result = await _mediator.Send(new GetSalesReportQuery(branchId, startDate, endDate));
        return Ok(result);
    }

    [HttpGet("sales/export")]
    public async Task<FileResult> ExportSalesReport(
        [FromQuery] Guid branchId,
        [FromQuery] DateTime startDate,
        [FromQuery] DateTime endDate)
    {
        var result = await _mediator.Send(new GetSalesReportQuery(branchId, startDate, endDate));

        using var package = new ExcelPackage();
        var worksheet = package.Workbook.Worksheets.Add("Sales Report");

        worksheet.Cells[1, 1].Value = "Sales Report";
        worksheet.Cells[2, 1].Value = $"Branch: {branchId}";
        worksheet.Cells[3, 1].Value = $"Period: {startDate:yyyy-MM-dd} to {endDate:yyyy-MM-dd}";
        worksheet.Cells[5, 1].Value = "Total Sales";
        worksheet.Cells[5, 2].Value = result.TotalSales;
        worksheet.Cells[6, 1].Value = "Zakup Total";
        worksheet.Cells[6, 2].Value = result.ZakupTotal;
        worksheet.Cells[7, 1].Value = "Profit";
        worksheet.Cells[7, 2].Value = result.Profit;
        worksheet.Cells[8, 1].Value = "Net Profit";
        worksheet.Cells[8, 2].Value = result.NetProfit;

        var stream = new MemoryStream(package.GetAsByteArray());
        return File(stream, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "sales_report.xlsx");
    }
}
