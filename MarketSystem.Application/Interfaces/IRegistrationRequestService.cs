using MarketSystem.Application.DTOs;
using MarketSystem.Domain.Enums;

namespace MarketSystem.Application.Interfaces;

public interface IRegistrationRequestService
{
    /// <summary>
    /// Public sign-up — anonymous submission. Returns the new request Id.
    /// Throws InvalidOperationException if the same phone already has a pending request.
    /// </summary>
    Task<Guid> SubmitAsync(SubmitRegistrationRequestDto dto, CancellationToken cancellationToken = default);

    /// <summary>SuperAdmin list. If <paramref name="status"/> is null, returns all statuses.</summary>
    Task<IEnumerable<RegistrationRequestDto>> ListAsync(RegistrationRequestStatus? status, CancellationToken cancellationToken = default);

    /// <summary>Active Owner users across all markets — SuperAdmin only.</summary>
    Task<IEnumerable<OwnerSummaryDto>> ListOwnersAsync(CancellationToken cancellationToken = default);

    /// <summary>
    /// Approve a request — atomically creates a new Owner user, a new dedicated
    /// Market, and a CashRegister scoped to that market. Returns credentials info
    /// so the SuperAdmin can hand them to the owner.
    /// </summary>
    Task<ApproveRegistrationResultDto> ApproveAsync(Guid requestId, ApproveRegistrationRequestDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>Reject a request with a reason. Idempotent on a request already rejected.</summary>
    Task<bool> RejectAsync(Guid requestId, string reason, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Real-time uniqueness check for the approve form. Any combination of fields
    /// may be supplied; each comes back as <c>true</c> (free), <c>false</c> (taken),
    /// or <c>null</c> (not asked). When a market name is supplied without a
    /// subdomain, returns a generated suggestion so the UI can preview it.
    /// </summary>
    Task<CheckAvailabilityResultDto> CheckAvailabilityAsync(
        string? username,
        string? marketName,
        string? subdomain,
        CancellationToken cancellationToken = default);

    /// <summary>Full owner detail (Owner + Market + live stats). Returns null if the user is not an Owner or has been deleted.</summary>
    Task<OwnerDetailDto?> GetOwnerDetailAsync(Guid userId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Manual create — same shape as <see cref="ApproveAsync"/> but without a backing
    /// registration request. Used when the SuperAdmin onboards a tenant out-of-band.
    /// </summary>
    Task<ApproveRegistrationResultDto> CreateOwnerAsync(CreateOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>Update mutable Owner+Market fields. Username and password are not editable here.</summary>
    Task<OwnerDetailDto> UpdateOwnerAsync(Guid userId, UpdateOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Soft-delete an Owner and deactivate their Market. Historical data
    /// (sales, products, debts) is preserved for audit; the market simply
    /// becomes unreachable. Returns false if the user is not found.
    /// </summary>
    Task<bool> DeleteOwnerAsync(Guid userId, DeleteOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>
    /// Administratively block a market (non-payment, ToS violation, etc.).
    /// Login and tenant-resolution will reject the entire market until
    /// <see cref="UnblockMarketAsync"/> is called. Idempotent: blocking an
    /// already-blocked market updates the reason and timestamp.
    /// </summary>
    Task<MarketBlockStatusDto> BlockMarketAsync(int marketId, BlockMarketDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);

    /// <summary>Restore a previously blocked market. Idempotent on already-unblocked markets.</summary>
    Task<MarketBlockStatusDto> UnblockMarketAsync(int marketId, Guid superAdminUserId, CancellationToken cancellationToken = default);
}
