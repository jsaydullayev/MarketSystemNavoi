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
    private readonly ICurrentMarketService _currentMarketService;

    public UserService(IUnitOfWork unitOfWork, AppDbContext context, ICurrentMarketService currentMarketService)
    {
        _unitOfWork = unitOfWork;
        _context = context;
        _currentMarketService = currentMarketService;
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

        // Get current market ID from context
        var currentMarketId = _currentMarketService.GetCurrentMarketId();
        if (currentMarketId == null)
            throw new InvalidOperationException("Market topilmadi. Iltimos, qaytadan tizimga kiring.");

        var user = new User
        {
            Id = Guid.NewGuid(),
            FullName = request.FullName,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = Enum.Parse<Role>(request.Role, true),
            Language = Enum.TryParse<Language>(request.Language, ignoreCase: true, out var lang)
                ? lang
                : Language.Uzbek,
            IsActive = true,
            MarketId = currentMarketId.Value
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

    public async Task<UserDto?> UpdateProfileAsync(Guid userId, UpdateProfileDto request, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
            return null;

        // Update full name if provided
        if (!string.IsNullOrWhiteSpace(request.FullName))
        {
            user.FullName = request.FullName;
        }

        // Update password if both current and new password are provided
        if (!string.IsNullOrWhiteSpace(request.CurrentPassword) &&
            !string.IsNullOrWhiteSpace(request.NewPassword))
        {
            // Verify current password
            if (!BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
                throw new UnauthorizedAccessException("Current password is incorrect");

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        }

        _context.Entry(user).State = EntityState.Modified;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return MapToDto(user);
    }

    public async Task<UserDto?> UpdateProfileImageAsync(Guid userId, UpdateProfileImageDto request, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
            return null;

        // Validate base64 image size (approximately)
        if (!string.IsNullOrEmpty(request.ProfileImage))
        {
            // Remove data URL prefix if present
            var base64Data = request.ProfileImage;
            if (base64Data.StartsWith("data:image/"))
            {
                var commaIndex = base64Data.IndexOf(',');
                if (commaIndex > 0)
                {
                    base64Data = base64Data.Substring(commaIndex + 1);
                }
            }

            // Check base64 string length (10MB limit in base64 is approximately 13M characters)
            if (base64Data.Length > 13_000_000)
            {
                throw new ArgumentException("Rasm hajmi juda katta. Maksimum rasm hajmi 10MB.");
            }

            // Validate base64 format
            try
            {
                Convert.FromBase64String(base64Data);
            }
            catch (FormatException)
            {
                throw new ArgumentException("Rasm formati noto'g'ri.");
            }
        }

        user.ProfileImage = request.ProfileImage;

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
            user.ProfileImage,
            user.Role.ToString(),
            user.Language.ToString().ToLowerInvariant(),
            user.IsActive,
            user.MarketId
        );
    }
}
