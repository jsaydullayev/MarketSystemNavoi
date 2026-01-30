using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Interfaces;

public interface ISaleRepository : IRepository<Sale>
{
    Task<Sale?> GetWithItemsAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task<Sale?> GetWithDetailsAsync(Guid saleId, CancellationToken cancellationToken = default);
    Task<IEnumerable<Sale>> GetDraftSalesByBranchAsync(Guid branchId, CancellationToken cancellationToken = default);
    Task<IEnumerable<Sale>> GetSalesByBranchAsync(Guid branchId, DateTime startDate, DateTime endDate, CancellationToken cancellationToken = default);
}
