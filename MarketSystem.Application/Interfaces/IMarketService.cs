using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IMarketService
{
    Task<MarketDto?> CreateMarketAsync(CreateMarketRequest request, CancellationToken cancellationToken = default);
    Task<RegisterMarketResponse?> RegisterMarketForOwnerAsync(RegisterMarketRequest request, Guid ownerId, CancellationToken cancellationToken = default);
    Task<List<MarketDto>> GetAllMarketsAsync(CancellationToken cancellationToken = default);
    Task<MarketDto?> GetMarketByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<bool> UpdateMarketAsync(int id, string name, string? description, CancellationToken cancellationToken = default);
    Task<bool> DeleteMarketAsync(int id, CancellationToken cancellationToken = default);
}
