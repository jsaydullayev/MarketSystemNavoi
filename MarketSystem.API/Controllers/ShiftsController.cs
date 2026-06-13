using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.API.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using System.Security.Claims;

namespace MarketSystem.API.Controllers;

/// <summary>
/// Seller work-shift sessions. Self-service — every authenticated user opens,
/// closes and views only their OWN shift (the user id comes from the JWT), so
/// these endpoints are gated by plain [Authorize], not a permission.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ShiftsController : ControllerBase
{
    private readonly IShiftService _shiftService;

    public ShiftsController(IShiftService shiftService) => _shiftService = shiftService;

    private Guid? CurrentUserId()
        => Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : null;

    /// <summary>The caller's currently open shift; 204 No Content when none.</summary>
    [HttpGet("current")]
    public async Task<ActionResult<ShiftDto>> GetCurrent(CancellationToken ct = default)
    {
        if (CurrentUserId() is not { } userId) return Unauthorized();
        var shift = await _shiftService.GetCurrentShiftAsync(userId, ct);
        return shift is null ? NoContent() : Ok(shift);
    }

    /// <summary>Opens the caller's work shift (idempotent).</summary>
    [HttpPost("open")]
    public async Task<ActionResult<ShiftDto>> Open(CancellationToken ct = default)
    {
        if (CurrentUserId() is not { } userId) return Unauthorized();
        return Ok(await _shiftService.OpenShiftAsync(userId, ct));
    }

    /// <summary>Closes the caller's open work shift.</summary>
    [HttpPost("close")]
    public async Task<ActionResult<ShiftDto>> Close(CancellationToken ct = default)
    {
        if (CurrentUserId() is not { } userId) return Unauthorized();
        try
        {
            return Ok(await _shiftService.CloseShiftAsync(userId, ct));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>A specific user's worked-shift sessions (most recent first).
    /// Owner/Admin only — gated by users.shift — so an Owner can review how
    /// long a seller actually worked. Market-scoped inside the service.</summary>
    [HttpGet("user/{userId:guid}")]
    [RequirePermission(PermissionKeys.UsersShift)]
    public async Task<ActionResult<IReadOnlyList<ShiftDto>>> GetUserShifts(
        Guid userId, CancellationToken ct = default)
        => Ok(await _shiftService.GetUserShiftsAsync(userId, 30, ct));
}
