using MarketSystem.Application.DTOs;

namespace MarketSystem.Application.Interfaces;

/// <summary>
/// Read-side counterpart to <see cref="MarketSystem.Domain.Interfaces.IAuditLogService"/>.
/// The query interface lives in the Application layer because its return shape
/// is a DTO (which Domain must not depend on), and it is consumed only by the
/// read controller — the audit-write call sites still depend on the slim
/// Domain interface.
/// </summary>
public interface IAuditLogQueryService
{
    /// <summary>
    /// Paged audit-log lookup. The controller enforces tenant scoping by
    /// pre-filling <see cref="AuditLogFilter.MarketId"/> for non-SuperAdmin
    /// callers; this method just applies whatever filter it receives.
    /// </summary>
    Task<PagedResult<AuditLogDto>> QueryAsync(
        AuditLogFilter filter,
        CancellationToken cancellationToken = default);
}
