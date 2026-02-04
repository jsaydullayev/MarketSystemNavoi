using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using MarketSystem.Domain.Interfaces;
using MarketSystem.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

namespace MarketSystem.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly AppDbContext _context;

    public UserService(IUnitOfWork unitOfWork, AppDbContext context)
    {
        _unitOfWork = unitOfWork;
        _context = context;
    }

    public async Task<UserDto?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken);
        if (user is null)
            return null;

        return MapToDto(user);
    }

    public async Task<UserDto?> GetUserByUsernameAsync(string username, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByUsernameAsync(username, cancellationToken);
        if (user is null)
            return null;

        return MapToDto(user);
    }

    public async Task<IEnumerable<UserDto>> GetAllUsersAsync(CancellationToken cancellationToken = default)
    {
        var users = await _unitOfWork.Users.GetAllAsync(cancellationToken);
        return users.Select(MapToDto);
    }

    public async Task<UserDto> CreateUserAsync(CreateUserDto request, CancellationToken cancellationToken = default)
    {
        // Check if username already exists
        if (await _unitOfWork.Users.AnyAsync(u => u.Username == request.Username, cancellationToken))
            throw new InvalidOperationException($"Username '{request.Username}' already exists");

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = request.FullName,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = Enum.Parse<Role>(request.Role, true),
            IsActive = true
        };

        await _unitOfWork.Users.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateUserAsync(UpdateUserDto request, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(request.Id, cancellationToken);
        if (user is null)
            return null;

        user.FullName = request.FullName;
        user.Role = Enum.Parse<Role>(request.Role, true);
        user.IsActive = request.IsActive;

        // Update password only if provided
        if (!string.IsNullOrWhiteSpace(request.Password))
        {
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
        }

        _context.Entry(user).State = EntityState.Modified;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<bool> DeleteUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken);
        if (user is null)
            return false;

        _unitOfWork.Users.Delete(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> DeactivateUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken);
        if (user is null)
            return false;

        user.IsActive = false;
        _context.Entry(user).State = EntityState.Modified;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    public async Task<bool> ActivateUserAsync(Guid id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken);
        if (user is null)
            return false;

        user.IsActive = true;
        _context.Entry(user).State = EntityState.Modified;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);
        return true;
    }

    private static UserDto MapToDto(User user)
    {
        return new UserDto(
            user.Id,
            user.FullName,
            user.Username,
            user.Role.ToString(),
            user.IsActive
        );
    }
}
