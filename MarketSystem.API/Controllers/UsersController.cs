using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using System.Text.Json;
using Serilog;

namespace MarketSystem.API.Controllers;
//new code
[ApiController]
[Route("api/[controller]/[action]")]
[Authorize(Policy = "AllRoles")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ICurrentMarketService _currentMarketService;

    public UsersController(IUserService userService, ICurrentMarketService currentMarketService)
    {
        _userService = userService;
        _currentMarketService = currentMarketService;
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<UserDto>> GetUser(Guid id)
    {
        var user = await _userService.GetUserByIdAsync(id);
        if (user is null)
            return NotFound();

        return Ok(user);
    }

    [HttpGet]
    public async Task<ActionResult<UserDto>> MyProfile()
    {
        var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        var user = await _userService.GetUserByIdAsync(userId);
        if (user is null)
            return NotFound();

        return Ok(user);
    }

    [HttpGet]
    public async Task<ActionResult<IEnumerable<UserDto>>> GetAllUsers()
    {
        var users = await _userService.GetAllUsersAsync();

        // Get current user's role and market ID
        var currentRole = User.FindFirst(ClaimTypes.Role)?.Value;
        var currentMarketId = _currentMarketService.TryGetCurrentMarketId();

        // SuperAdmin sees all users, others see only their market's users
        if (currentRole != "SuperAdmin" && currentMarketId.HasValue)
        {
            users = users.Where(u => u.MarketId == currentMarketId.Value);
        }

        if (users is null)
        {
            return BadRequest("Foydalanuvchilar topilmadi");
        }

        return Ok(users);
    }

    [HttpPost]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserDto request)
    {
        try
        {
            var user = await _userService.CreateUserAsync(request);
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<ActionResult<UserDto>> UpdateUser(Guid id, [FromBody] UpdateUserDto request)
    {
        if (id != request.Id)
            return BadRequest("ID mismatch");

        try
        {
            var user = await _userService.UpdateUserAsync(request);
            if (user is null)
                return NotFound();

            return Ok(user);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut]
    public async Task<ActionResult<UserDto>> UpdateMyProfile([FromBody] UpdateProfileDto request)
    {
        var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        try
        {
            var user = await _userService.UpdateProfileAsync(userId, request);
            if (user is null)
                return NotFound();

            return Ok(user);
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut]
    public async Task<ActionResult<UserDto>> UpdateProfileImage()
    {
        Log.Information("=== UPDATE PROFILE IMAGE START ===");
        Log.Information("Request Content-Type: {ContentType}", Request.ContentType);
        Log.Information("HasFormContentType: {HasFormContentType}", Request.HasFormContentType);
        // `Request.Form` throws InvalidOperationException on a non-multipart
        // request (e.g. when the client sends a JSON base64 body). Gate the
        // log on HasFormContentType so the endpoint doesn't 500 on its own
        // diagnostic line before any business logic runs.
        if (Request.HasFormContentType)
        {
            Log.Information("Files count: {FilesCount}", Request.Form.Files.Count);
        }

        var userIdStr = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        Log.Information("User ID from token: {UserId}", userIdStr);

        if (!Guid.TryParse(userIdStr, out var userId))
            return Unauthorized();

        try
        {
            UpdateProfileImageDto request;

            // Check if request contains file upload (multipart/form-data)
            if (Request.HasFormContentType && Request.Form != null && Request.Form.Files.Count > 0)
            {
                // Handle file upload
                var image = Request.Form.Files[0];

                if (image == null || image.Length == 0)
                    return BadRequest("Rasm fayli tanlanmadi.");

                // Check file size (max 5MB)
                if (image.Length > 5 * 1024 * 1024)
                {
                    return BadRequest("Rasm hajmi juda katta. Maksimum rasm hajmi 5MB.");
                }

                // Read into memory so we can inspect magic bytes BEFORE trusting the file.
                using var memoryStream = new MemoryStream();
                await image.CopyToAsync(memoryStream);
                var imageBytes = memoryStream.ToArray();

                // Magic-byte sniff — a renamed `payload.exe.png` would pass the extension
                // check but fail here. We trust the file's actual bytes, not its name.
                var kind = MarketSystem.API.Validation.ImageContentValidator.Detect(imageBytes);
                if (kind == MarketSystem.API.Validation.ImageKind.Unknown)
                {
                    return BadRequest("Fayl tasvir emas yoki qo'llab-quvvatlanmaydigan formatda (JPEG/PNG/GIF/WebP qabul qilinadi).");
                }

                var base64Image = Convert.ToBase64String(imageBytes);
                var mimeType = MarketSystem.API.Validation.ImageContentValidator.ToMimeType(kind);

                request = new UpdateProfileImageDto(
                    ProfileImage: $"data:{mimeType};base64,{base64Image}"
                );
            }
            else
            {
                // Handle JSON body
                var options = new JsonSerializerOptions
                {
                    PropertyNameCaseInsensitive = true
                };

                request = await Request.ReadFromJsonAsync<UpdateProfileImageDto>(options);

                if (request == null)
                    return BadRequest("So'rov noto'g'ri formatda.");
            }

            var user = await _userService.UpdateProfileImageAsync(userId, request);
            if (user is null)
                return NotFound();

            return Ok(user);
        }
        catch (UnauthorizedAccessException ex)
        {
            Log.Error(ex, "Unauthorized access while updating profile image for user: {UserId}", userId);
            return Unauthorized(ex.Message);
        }
        catch (InvalidOperationException ex)
        {
            Log.Error(ex, "Invalid operation while updating profile image for user: {UserId}", userId);
            return BadRequest(ex.Message);
        }
        catch (Exception ex)
        {
            Log.Error(ex, "Error updating profile image for user: {UserId}", userId);
            return BadRequest($"Rasmni yangilashda xatolik: {ex.Message}");
        }
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        var result = await _userService.DeleteUserAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    [HttpPost("{id}/deactivate")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        var result = await _userService.DeactivateUserAsync(id);
        if (!result)
            return NotFound();

        return Ok(new { message = "User deactivated" });
    }

    [HttpPost("{id}/activate")]
    [Authorize(Policy = "AdminOrOwner")]
    public async Task<IActionResult> ActivateUser(Guid id)
    {
        var result = await _userService.ActivateUserAsync(id);
        if (!result)
            return NotFound();

        return Ok(new { message = "User activated" });
    }
}
