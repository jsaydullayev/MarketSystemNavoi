using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.API.Authorization;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Interfaces;
using System.Security.Claims;
using System.Text.Json;
using Serilog;

namespace MarketSystem.API.Controllers;
//new code
[ApiController]
[Route("api/[controller]/[action]")]
[Authorize]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;
    private readonly ICurrentMarketService _currentMarketService;
    private readonly IAuditLogService _auditLogService;

    public UsersController(
        IUserService userService,
        ICurrentMarketService currentMarketService,
        IAuditLogService auditLogService)
    {
        _userService = userService;
        _currentMarketService = currentMarketService;
        _auditLogService = auditLogService;
    }

    /// <summary>The authenticated caller's user id, taken from the JWT — recorded
    /// as the actor on audit entries. Guid.Empty if the claim is somehow absent.</summary>
    private Guid CurrentUserId() =>
        Guid.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : Guid.Empty;

    [HttpGet("{id}")]
    [RequirePermission(PermissionKeys.UsersAccess)]
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
    [RequirePermission(PermissionKeys.UsersAccess)]
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
    [RequirePermission(PermissionKeys.UsersManage)]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] CreateUserDto request)
    {
        try
        {
            var user = await _userService.CreateUserAsync(request);
            await _auditLogService.LogActionAsync(
                AuditEntityTypes.User, user.Id, AuditActions.Create, CurrentUserId(),
                new { user.Username, user.Role, user.FullName });
            return CreatedAtAction(nameof(GetUser), new { id = user.Id }, user);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ex.Message);
        }
    }

    [HttpPut("{id}")]
    [RequirePermission(PermissionKeys.UsersManage)]
    public async Task<ActionResult<UserDto>> UpdateUser(Guid id, [FromBody] UpdateUserDto request)
    {
        if (id != request.Id)
            return BadRequest("ID mismatch");

        try
        {
            var user = await _userService.UpdateUserAsync(request);
            if (user is null)
                return NotFound();

            await _auditLogService.LogActionAsync(
                AuditEntityTypes.User, user.Id, AuditActions.Update, CurrentUserId(),
                new { user.Username, user.Role, user.IsActive });

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
            // Nullable: the JSON branch assigns from ReadFromJsonAsync which
            // returns T?. Both branches below guarantee a non-null value
            // before it's used (form branch via `new`, JSON branch via the
            // explicit null check), so the later usage stays safe.
            UpdateProfileImageDto? request;

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
    [RequirePermission(PermissionKeys.UsersManage)]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        var result = await _userService.DeleteUserAsync(id);
        if (!result)
            return NotFound();

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.User, id, AuditActions.Delete, CurrentUserId());

        return NoContent();
    }

    [HttpPost("{id}/deactivate")]
    [RequirePermission(PermissionKeys.UsersManage)]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        var result = await _userService.DeactivateUserAsync(id);
        if (!result)
            return NotFound();

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.User, id, AuditActions.Deactivate, CurrentUserId());

        return Ok(new { message = "User deactivated" });
    }

    [HttpPost("{id}/activate")]
    [RequirePermission(PermissionKeys.UsersManage)]
    public async Task<IActionResult> ActivateUser(Guid id)
    {
        var result = await _userService.ActivateUserAsync(id);
        if (!result)
            return NotFound();

        await _auditLogService.LogActionAsync(
            AuditEntityTypes.User, id, AuditActions.Activate, CurrentUserId());

        return Ok(new { message = "User activated" });
    }

    /// <summary>
    /// Set a seller's work shift — "Active", "Blocked" or "Scheduled" (with a
    /// [startUtc, endUtc] window). Admin/Owner only.
    /// </summary>
    [HttpPut("{id}/shift")]
    [RequirePermission(PermissionKeys.UsersShift)]
    public async Task<ActionResult<UserDto>> UpdateShift(Guid id, [FromBody] UpdateShiftDto request)
    {
        try
        {
            var user = await _userService.UpdateShiftAsync(id, request);
            if (user is null)
                return NotFound();

            return Ok(user);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }

    /// <summary>
    /// Owner RBAC — read a user's permission configuration (effective set,
    /// role defaults and the full catalogue). Owner-only, scoped to the
    /// caller's own market.
    /// </summary>
    [HttpGet("{id}")]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<UserPermissionsDto>> GetUserPermissions(Guid id)
    {
        var permissions = await _userService.GetUserPermissionsAsync(id);
        if (permissions is null)
            return NotFound();

        return Ok(permissions);
    }

    /// <summary>
    /// Owner RBAC — overwrite a user's explicit permission set. Send an empty
    /// list to reset the user to its role default. Owner/SuperAdmin cannot be
    /// edited. The change takes effect on the user's next login/token refresh.
    /// </summary>
    [HttpPut("{id}")]
    [Authorize(Policy = "OwnerOnly")]
    public async Task<ActionResult<UserPermissionsDto>> UpdateUserPermissions(Guid id, [FromBody] UpdatePermissionsDto request)
    {
        try
        {
            // Snapshot the effective set BEFORE the change so the audit record
            // shows exactly what was granted/revoked, not merely the final state.
            var before = await _userService.GetUserPermissionsAsync(id);

            var permissions = await _userService.UpdateUserPermissionsAsync(id, request);
            if (permissions is null)
                return NotFound();

            await _auditLogService.LogActionAsync(
                AuditEntityTypes.Permission, id, AuditActions.PermissionChange, CurrentUserId(),
                new
                {
                    targetUserId = id,
                    before = before?.EffectivePermissions,
                    after = permissions.EffectivePermissions,
                    isCustomized = permissions.IsCustomized
                });

            return Ok(permissions);
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(new { message = ex.Message });
        }
    }
}
