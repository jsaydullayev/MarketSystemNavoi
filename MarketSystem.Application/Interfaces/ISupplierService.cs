using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface ISupplierService
{
    Task<SupplierDto?> GetSupplierByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<SupplierDto>> GetAllSuppliersAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<SupplierDto>> GetAllSuppliersPagedAsync(int page, int size, string? search = null, CancellationToken cancellationToken = default);
    Task<SupplierDto> CreateSupplierAsync(CreateSupplierDto request, CancellationToken cancellationToken = default);
    Task<SupplierDto?> UpdateSupplierAsync(UpdateSupplierDto request, CancellationToken cancellationToken = default);
    Task<bool> SoftDeleteSupplierAsync(Guid id, CancellationToken cancellationToken = default);
    Task<SupplierDeleteInfoDto> GetSupplierDeleteInfoAsync(Guid id, CancellationToken cancellationToken = default);
}
