using MarketSystem.Domain.Entities;

namespace MarketSystem.Domain.Interfaces;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<User?> GetActiveUserAsync(Guid id, CancellationToken cancellationToken = default);
}
