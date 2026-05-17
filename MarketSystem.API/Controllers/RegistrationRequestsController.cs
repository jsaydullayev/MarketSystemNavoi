using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.Extensions.Logging;

namespace MarketSystem.API.Controllers;

/// <summary>
/// Public sign-up entry point. Only one POST — there is intentionally no
/// GET / PUT / DELETE, so the queue stays private and we can't accidentally
/// leak phone numbers or pending state. Reviewing and approving requests
/// lives under <see cref="SuperAdminController"/>.
/// </summary>
[ApiController]
[Route("api/[controller]")]
public class RegistrationRequestsController : ControllerBase
{
    private readonly IRegistrationRequestService _service;
    private readonly ILogger<RegistrationRequestsController> _logger;

    public RegistrationRequestsController(
        IRegistrationRequestService service,
        ILogger<RegistrationRequestsController> logger)
    {
        _service = service;
        _logger = logger;
    }

    /// <summary>
    /// Anonymous sign-up — visitor submits FullName + Phone. To avoid leaking
    /// whether a given phone is already in the queue or in an unsupported format,
    /// we return the SAME 200 OK response in every case (validation failures
    /// included), and write the actual reason to the server log. The only
    /// front-facing 4xx is a 429 from the rate limiter.
    /// </summary>
    [HttpPost]
    [AllowAnonymous]
    [EnableRateLimiting("registration-submit")]
    public async Task<IActionResult> Submit([FromBody] SubmitRegistrationRequestDto request, CancellationToken ct)
    {
        const string genericMessage = "Adminga yubordik. Admin tez orada javob beradi.";
        try
        {
            await _service.SubmitAsync(request, ct);
            return Ok(new { message = genericMessage });
        }
        catch (InvalidOperationException ex)
        {
            // Surface validation hints back to the user ONLY for clearly user-facing
            // formatting errors. Anything else (duplicate phone, suspicious shape)
            // gets the generic message so a bad actor can't enumerate the queue.
            var userFacing = ex.Message != "DUPLICATE_PENDING"
                && (ex.Message.Contains("kiriting") || ex.Message.Contains("format"));
            _logger.LogInformation("Registration submit handled with reason: {Reason}", ex.Message);
            return userFacing
                ? BadRequest(new { message = ex.Message })
                : Ok(new { message = genericMessage });
        }
    }
}