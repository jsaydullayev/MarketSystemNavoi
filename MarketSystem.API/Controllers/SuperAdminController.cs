using System.Security.Claims;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;

namespace MarketSystem.API.Controllers;

/// <summary>
/// SuperAdmin-only console. The URL is gated by an opaque segment that the
/// operator configures via <c>SuperAdmin:ConsoleSegment</c> — see
/// <see cref="Middleware.SuperAdminPathGateMiddleware"/>. Requests to
/// <c>/api/_sa/...</c> with the wrong segment 404 BEFORE authentication runs,
/// so an unauthenticated scanner can't even tell the console exists.
///
/// The hidden URL is defence in depth — the primary access control is the
/// JWT <c>SuperAdmin</c> role check (<see cref="AuthorizeAttribute"/>).
/// </summary>
[ApiController]
[Route("api/_sa/{consoleSegment}")]
[Authorize(Roles = "SuperAdmin")]
[EnableRateLimiting("super-admin")]
public class SuperAdminController : ControllerBase
{
    private readonly IRegistrationRequestService _service;

    public SuperAdminController(IRegistrationRequestService service)
    {
        _service = service;
    }

    [HttpGet("requests")]
    public async Task<IActionResult> ListRequests(
        [FromQuery] RegistrationRequestStatus? status,
        CancellationToken ct)
        => Ok(await _service.ListAsync(status, ct));

    [HttpGet("owners")]
    public async Task<IActionResult> ListOwners(CancellationToken ct)
        => Ok(await _service.ListOwnersAsync(ct));

    /// <summary>
    /// Real-time uniqueness check for the approve form. Any of the three fields
    /// may be omitted; each comes back as true (free), false (taken), or null
    /// (not asked). When the caller supplies a username but no subdomain, the
    /// response includes a generated <c>suggestedSubdomain</c> for preview.
    /// </summary>
    [HttpGet("check-availability")]
    public async Task<IActionResult> CheckAvailability(
        [FromQuery] string? username,
        [FromQuery] string? marketName,
        [FromQuery] string? subdomain,
        CancellationToken ct)
        => Ok(await _service.CheckAvailabilityAsync(username, marketName, subdomain, ct));

    [HttpPost("requests/{id:guid}/approve")]
    public async Task<IActionResult> Approve(
        Guid id,
        [FromBody] ApproveRegistrationRequestDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            return Ok(await _service.ApproveAsync(id, body, superAdminId, ct));
        }
        catch (KeyNotFoundException) { return NotFound(new { message = "So'rov topilmadi." }); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPost("requests/{id:guid}/reject")]
    public async Task<IActionResult> Reject(
        Guid id,
        [FromBody] RejectRegistrationRequestDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            var ok = await _service.RejectAsync(id, body.Reason, superAdminId, ct);
            return ok ? Ok(new { message = "Rad etildi." }) : NotFound(new { message = "So'rov topilmadi." });
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    // ─── Owner CRUD ─────────────────────────────────────────────────────────

    /// <summary>Full owner profile (Owner + Market + live stats).</summary>
    [HttpGet("owners/{id:guid}")]
    public async Task<IActionResult> GetOwner(Guid id, CancellationToken ct)
    {
        var detail = await _service.GetOwnerDetailAsync(id, ct);
        return detail is null
            ? NotFound(new { message = "Owner topilmadi." })
            : Ok(detail);
    }

    /// <summary>Manual create — same shape as Approve, no backing request.</summary>
    [HttpPost("owners")]
    public async Task<IActionResult> CreateOwner(
        [FromBody] CreateOwnerDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            return Ok(await _service.CreateOwnerAsync(body, superAdminId, ct));
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    /// <summary>Update Owner+Market mutable fields. Username/password are not editable here.</summary>
    [HttpPut("owners/{id:guid}")]
    public async Task<IActionResult> UpdateOwner(
        Guid id,
        [FromBody] UpdateOwnerDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            return Ok(await _service.UpdateOwnerAsync(id, body, superAdminId, ct));
        }
        catch (KeyNotFoundException) { return NotFound(new { message = "Owner topilmadi." }); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    /// <summary>Soft-delete: Owner → IsDeleted, Market → IsActive=false. Historical data preserved.</summary>
    [HttpDelete("owners/{id:guid}")]
    public async Task<IActionResult> DeleteOwner(
        Guid id,
        [FromBody] DeleteOwnerDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            var ok = await _service.DeleteOwnerAsync(id, body, superAdminId, ct);
            return ok ? Ok(new { message = "Owner o'chirildi." }) : NotFound(new { message = "Owner topilmadi." });
        }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    // ─── Market block / unblock ─────────────────────────────────────────────

    /// <summary>
    /// Block a market — all login/tenant-resolution attempts return 423 until
    /// unblocked. Primary use: subscription non-payment. Reversible.
    /// </summary>
    [HttpPost("markets/{marketId:int}/block")]
    public async Task<IActionResult> BlockMarket(
        int marketId,
        [FromBody] BlockMarketDto body,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            return Ok(await _service.BlockMarketAsync(marketId, body, superAdminId, ct));
        }
        catch (KeyNotFoundException) { return NotFound(new { message = "Do'kon topilmadi." }); }
        catch (InvalidOperationException ex) { return BadRequest(new { message = ex.Message }); }
    }

    [HttpPost("markets/{marketId:int}/unblock")]
    public async Task<IActionResult> UnblockMarket(
        int marketId,
        CancellationToken ct)
    {
        if (!TryGetCallerId(out var superAdminId)) return Unauthorized();
        try
        {
            return Ok(await _service.UnblockMarketAsync(marketId, superAdminId, ct));
        }
        catch (KeyNotFoundException) { return NotFound(new { message = "Do'kon topilmadi." }); }
    }

    private bool TryGetCallerId(out Guid id)
    {
        var raw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(raw, out id);
    }
}
