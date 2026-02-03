using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Interfaces;

namespace MarketSystem.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Policy = "AllRoles")]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
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
    public async Task<ActionResult<IEnumerable<UserDto>>> GetAllUsers()
    {
        var users = await _userService.GetAllUsersAsync();
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

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteUser(Guid id)
    {
        var result = await _userService.DeleteUserAsync(id);
        if (!result)
            return NotFound();

        return NoContent();
    }

    [HttpPost("{id}/deactivate")]
    public async Task<IActionResult> DeactivateUser(Guid id)
    {
        var result = await _userService.DeactivateUserAsync(id);
        if (!result)
            return NotFound();

        return Ok(new { message = "User deactivated" });
    }

    [HttpPost("{id}/activate")]
    public async Task<IActionResult> ActivateUser(Guid id)
    {
        var result = await _userService.ActivateUserAsync(id);
        if (!result)
            return NotFound();

        return Ok(new { message = "User activated" });
    }
}
