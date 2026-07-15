using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

public interface IZakupService
{
    // ── Single-line (legacy / quick re-stock) ────────────────────────────────
    Task<ZakupDto?> GetZakupByIdAsync(Guid id, CancellationToken cancellationToken = default);
    Task<IEnumerable<ZakupDto>> GetAllZakupsAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<ZakupDto>> GetAllZakupsPagedAsync(int page, int size, CancellationToken cancellationToken = default);
    Task<IEnumerable<ZakupDto>> GetZakupsByDateRangeAsync(DateTime start, DateTime end, CancellationToken cancellationToken = default);
    Task<ZakupDto> CreateZakupAsync(CreateZakupDto request, Guid adminId, CancellationToken cancellationToken = default);
    Task<bool> DeleteZakupAsync(Guid id, Guid deletedByUserId, CancellationToken cancellationToken = default);

    // ── Goods-receipt (multi-item + supplier + payment) ──────────────────────
    Task<ZakupReceiptDto> CreateZakupReceiptAsync(CreateZakupReceiptDto request, Guid adminId, CancellationToken cancellationToken = default);
    Task<IEnumerable<ZakupReceiptDto>> GetAllZakupReceiptsAsync(CancellationToken cancellationToken = default);
    Task<PagedResult<ZakupReceiptDto>> GetAllZakupReceiptsPagedAsync(int page, int size, CancellationToken cancellationToken = default);
    Task<ZakupReceiptDto?> GetZakupReceiptByIdAsync(Guid receiptId, CancellationToken cancellationToken = default);
    Task<bool> DeleteZakupReceiptAsync(Guid receiptId, Guid deletedByUserId, CancellationToken cancellationToken = default);
    Task<ZakupReceiptDto?> RegisterSupplierPaymentAsync(Guid receiptId, decimal amount, Guid userId, CancellationToken cancellationToken = default);
}
