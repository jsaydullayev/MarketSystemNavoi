using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IUserService
{
    Task<UserDto?> GetUserByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<UserDto?> GetUserByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<IEnumerable<UserDto>> GetAllUsersAsync(CancellationToken cancellationToken = default);
    Task<UserDto> CreateUserAsync(CreateUserDto request, CancellationToken cancellationToken = default);
    Task<UserDto?> UpdateUserAsync(UpdateUserDto request, CancellationToken cancellationToken = default);
    Task<bool> DeleteUserAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> DeactivateUserAsync(Guid id, CancellationToken cancellationToken = default);
    Task<bool> ActivateUserAsync(Guid id, CancellationToken cancellationToken = default);
}
