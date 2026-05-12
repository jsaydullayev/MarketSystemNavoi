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

    private bool TryGetCallerId(out Guid id)
    {
        var raw = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return Guid.TryParse(raw, out id);
    }
}
