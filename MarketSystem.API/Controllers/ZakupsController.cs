using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ZakupsController : ControllerBase
{
    private readonly IZakupService _zakupService;

    public ZakupsController(IZakupService zakupService)
    {
        _zakupService = zakupService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ZakupDto>> GetZakup(Guid id)
    {
        var zakup = await _zakupService.GetZakupByIdAsync(id);
        if (zakup is null)
            return NotFound();

        return Ok(zakup);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<ZakupDto>>> GetAllZakups()
    {
        var zakups = await _zakupService.GetAllZakupsAsync();
        return Ok(zakups);
    }

    [HttpGet("by-date")]
    public async Task<ActionResult<IEnumerable<ZakupDto>>> GetZakupsByDateRange([FromQuery] DateTime start, [FromQuery] DateTime end)
    {
        var zakups = await _zakupService.GetZakupsByDateRangeAsync(start, end);
        return Ok(zakups);
    }

    [HttpPost]
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
}
