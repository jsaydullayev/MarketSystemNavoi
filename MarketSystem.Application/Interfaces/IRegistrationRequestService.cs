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
    /// Create an Owner + Market + CashRegister directly, without a pre-existing
    /// registration request. Used by SuperAdmin when onboarding an owner who
    /// signed up out-of-band (e.g. by phone or in person).
    /// </summary>
    Task<ApproveRegistrationResultDto> CreateOwnerAsync(CreateOwnerDto dto, Guid superAdminUserId, CancellationToken cancellationToken = default);
}
