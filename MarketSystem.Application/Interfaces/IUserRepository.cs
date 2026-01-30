using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Interfaces;

public interface IUserRepository : IRepository<User>
{
    Task<User?> GetByUsernameAsync(string username, CancellationToken cancellationToken = default);
    Task<User?> GetByIdWithBranchAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<User>> GetByBranchAsync(Guid branchId, CancellationToken cancellationToken = default);
    Task<User?> GetActiveSellerAsync(Guid id, Guid branchId, CancellationToken cancellationToken = default);
}
