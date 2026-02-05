using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
    {
        _logger.LogInformation("=== LOGIN REQUEST ===");
        _logger.LogInformation("Username: {Username}", request.Username);
        _logger.LogInformation("Password length: {Length}", request.Password?.Length ?? 0);
        _logger.LogInformation("====================");

        var result = await _authService.LoginAsync(request);

        if (result is null)
        {
            _logger.LogWarning("Login FAILED for user: {Username}", request.Username);
            return Unauthorized("Invalid credentials");
        }

        _logger.LogInformation("Login SUCCESS for user: {Username}", result.Username);
        return Ok(result);
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
    {
        try
        {
            var result = await _authService.RegisterAsync(request);
            return Ok(result);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var result = await _authService.RefreshTokenAsync(request);

        if (result is null)
            return Unauthorized("Invalid token");

        return Ok(result);
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Logout([FromBody] RefreshTokenRequest request)
    {
        var result = await _authService.LogoutAsync(request.RefreshToken);

        if (!result)
            return BadRequest("Invalid token");

        return Ok(new { message = "Logged out successfully" });
    }
}
