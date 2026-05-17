using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IZakupService
{
    Task<ZakupDto?> GetZakupByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<ZakupDto>> GetAllZakupsAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<ZakupDto>> GetAllZakupsPagedAsync(int page, int size, CancellationToken cancellationToken = default);
    Task<IEnumerable<ZakupDto>> GetZakupsByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default);
    Task<ZakupDto> CreateZakupAsync(CreateZakupDto request, Guid adminId, CancellationToken cancellationToken = default);
}
