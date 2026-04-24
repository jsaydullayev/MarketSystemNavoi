using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using MarketSystem.Domain.Enums;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class ZakupsController : ControllerBase
{
    private readonly IZakupService _zakupService;

    public ZakupsController(IZakupService zakupService)
    {
        _zakupService = zakupService;
    }

    private bool IsSeller()
    {
        var roleClaim = User.FindFirst(ClaimTypes.Role)?.Value;
        return roleClaim == Role.Seller.ToString();
    }

    [HttpGet("{id}")]
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
    public async Task<IActionResult> GetAllZakups()
    {
        var zakups = await _zakupService.GetAllZakupsAsync();

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

    [HttpGet("by-date")]
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
    [Authorize(Policy = "AdminOrOwner")]
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
    public async Task<IActionResult> ExportZakupsToExcel([FromServices] MarketSystem.Application.Interfaces.IExcelService excelService)
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
            Xarid_narxi = IsSeller() ? null : z.CostPrice,
            Jami_summa = IsSeller() ? null : z.Quantity * z.CostPrice
        });

        var fileContent = excelService.GenerateExcel(exportData, "Xaridlar");

        return File(
            fileContent,
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            $"Xaridlar_{DateTime.Now:yyyyMMdd_HHmmss}.xlsx"
        );
    }
}
