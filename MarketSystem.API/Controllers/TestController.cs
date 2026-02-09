using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]/[action]")]
public class TestController : ControllerBase
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IJwtService _jwtService;

    public TestController(IUnitOfWork unitOfWork, IJwtService jwtService)
    {
        _unitOfWork = unitOfWork;
        _jwtService = jwtService;
    }

    [HttpGet("users")]
    [AllowAnonymous]
    public async Task<IActionResult> GetUsers()
    {
        try
        {
            var users = await _unitOfWork.Users.GetAllAsync();
            return Ok(new { count = users.Count(), users = users.Select(u => new { u.Id, u.Username, u.Role, u.IsActive }) });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("create-user")]
    [AllowAnonymous]
    public async Task<ActionResult<AuthResponse>> CreateUser([FromBody] LoginRequest request)
    {
        try
        {
            var user = new MarketSystem.Domain.Entities.User
            {
                Id = Guid.NewGuid(),
                FullName = "Test User",
                Username = request.Username,
                PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
                Role = MarketSystem.Domain.Enums.Role.Owner,
                IsActive = true
            };

            await _unitOfWork.Users.AddAsync(user);
            await _unitOfWork.SaveChangesAsync();

            var token = _jwtService.GenerateToken(user, true);

            return Ok(new AuthResponse(
                user.Id,
                user.Username,
                user.FullName,
                user.Role.ToString(),
                user.Language.ToString().ToLowerInvariant(),
                token.AccessToken,
                string.Empty, // Test endpoint - no refresh token
                DateTime.UtcNow.AddDays(7)
            ));
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("protected")]
    [Authorize]
    public IActionResult GetProtected()
    {
        var userId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        var username = User.FindFirst(System.Security.Claims.ClaimTypes.Name)?.Value;
        var role = User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;

        return Ok(new
        {
            message = "You are authenticated!",
            userId,
            username,
            role
        });
    }
}
