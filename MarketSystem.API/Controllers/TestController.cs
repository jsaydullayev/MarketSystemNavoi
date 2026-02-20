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

    [HttpGet("categories")]
    [AllowAnonymous]
    public async Task<IActionResult> TestCategories()
    {
        try
        {
            var allCategories = await _unitOfWork.ProductCategories.GetAllAsync();
            var market4Categories = await _unitOfWork.ProductCategories.FindAsync(c => c.MarketId == 4);

            return Ok(new
            {
                totalCategories = allCategories.Count(),
                market4CategoriesCount = market4Categories.Count(),
                categories = market4Categories.Select(c => new
                {
                    id = c.Id,
                    name = c.Name,
                    marketId = c.MarketId,
                    isActive = c.IsActive,
                    isDeleted = c.IsDeleted
                })
            });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message, stackTrace = ex.StackTrace });
        }
    }

    [HttpPost("seed-category")]
    [AllowAnonymous]
    public async Task<IActionResult> SeedTestCategory()
    {
        try
        {
            var category = new MarketSystem.Domain.Entities.ProductCategory
            {
                Name = "Yog'och mahsulotlar",
                Description = "Taxta, DSP, reka va boshqalar",
                MarketId = 4,
                IsActive = true,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };

            await _unitOfWork.ProductCategories.AddAsync(category);
            await _unitOfWork.SaveChangesAsync();

            return Ok(new { message = "Test category created", id = category.Id, name = category.Name });
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message, stackTrace = ex.StackTrace });
        }
    }
}
