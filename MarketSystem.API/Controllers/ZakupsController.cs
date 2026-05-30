using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.RateLimiting;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using System.Security.Claims;
using MarketSystem.Domain.Enums;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class ZakupsController : ControllerBase
{
    private readonly IZakupService _zakupService;
    private readonly IExcelService _excelService;
    private readonly ITashkentClock _clock;

    public ZakupsController(IZakupService zakupService, IExcelService excelService, ITashkentClock clock)
    {
        _zakupService = zakupService;
        _excelService = excelService;
        _clock = clock;
    }

    private bool IsSeller()
    {
        var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
        return roleClaim == Role.Seller.ToString();
    }

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.ZakupAccess)]
    public async Task<IActionResult> GetZakup(Guid id)
    {
        var zakup = await _zakupService.GetZakupByIdAsync(id);
        if (zakup is null)
            return NotFound();

        // Return ZakupSellerDto for Sellers (without cost price)
        if (IsSeller())
        {
            var sellerDto = new ZakupSellerDto(
                zakup.Id,
                zakup.ProductId,
                zakup.ProductName,
                zakup.Quantity,
                zakup.CreatedAt,
                zakup.CreatedBy
            );
            return Ok(sellerDto);
        }

        return Ok(zakup);
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.ZakupAccess)]
    public async Task<IActionResult> GetAllZakups()
    {
        var zakups = await _zakupService.GetAllZakupsAsync();

        if (IsSeller())
        {
            var sellerDtos = zakups.Select(z => new ZakupSellerDto(
                z.Id, z.ProductId, z.ProductName, z.Quantity, z.CreatedAt, z.CreatedBy));
            return Ok(sellerDtos);
        }

        return Ok(zakups);
    }

    [HttpGet]
    [RequirePermission(PermissionKeys.ZakupAccess)]
    public async Task<IActionResult> GetZakupsPaged(
        [FromQuery] int page = 1,
        [FromQuery] int size = 50)
    {
        var result = await _zakupService.GetAllZakupsPagedAsync(page, size);

        if (IsSeller())
        {
            var sellerItems = result.Items.Select(z => new ZakupSellerDto(
                z.Id, z.ProductId, z.ProductName, z.Quantity, z.CreatedAt, z.CreatedBy)).ToList();
            return Ok(new { items = sellerItems, result.Page, result.Size, result.Total, result.TotalPages });
        }

        return Ok(result);
    }

    [HttpGet("by-date")]
    [RequirePermission(PermissionKeys.ZakupAccess)]
    public async Task<IActionResult> GetZakupsByDateRange([FromQuery] DateTime start, [FromQuery] DateTime end)
    {
        var zakups = await _zakupService.GetZakupsByDateRangeAsync(start, end);

        // Return ZakupSellerDto for Sellers (without cost price)
        if (IsSeller())
        {
            var sellerDtos = zakups.Select(z => new ZakupSellerDto(
                z.Id,
                z.ProductId,
                z.ProductName,
                z.Quantity,
                z.CreatedAt,
                z.CreatedBy
            ));
            return Ok(sellerDtos);
        }

        return Ok(zakups);
    }

    [HttpPost]
    [RequirePermission(PermissionKeys.ZakupCreate)]
    public async Task<ActionResult<ZakupDto>> CreateZakup([FromBody] CreateZakupDto request)
    {
        var adminIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(adminIdStr) || !Guid.TryParse(adminIdStr, out var adminId))
            return Unauthorized();

        try
        {
            var zakup = await _zakupService.CreateZakupAsync(request, adminId);
            return CreatedAtAction(nameof(GetZakup), new { id = zakup.Id }, zakup);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpGet("export")]
    [EnableRateLimiting("export")]
    [RequirePermission(PermissionKeys.ZakupAccess)]
    public async Task<IActionResult> ExportZakupsToExcel()
    {
        var zakups = await _zakupService.GetAllZakupsAsync();

        // Hide cost prices for Sellers - use consistent structure
        var exportData = zakups.Select(z => new
        {
            ID = z.Id.ToString(),
            Mahsulot = z.ProductName,
            Sana = z.CreatedAt.ToString("yyyy-MM-dd HH:mm"),
            Xodim = z.CreatedBy,
            Miqdor = z.Quantity,
            Xarid_narxi = IsSeller() ? "-" : z.CostPrice.ToString(),
            Jami_summa = IsSeller() ? "-" : (z.Quantity * z.CostPrice).ToString()
        });

        var fileContent = _excelService.GenerateExcel(exportData, "Xaridlar");

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"Xaridlar_{_clock.NowLocal:yyyyMMdd_HHmmss}.xlsx"
        );
    }
}
