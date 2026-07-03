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
    /// Paged audit-log lookup. Defense-in-depth tenant scoping: unless
    /// <paramref name="allowCrossMarket"/> is true (SuperAdmin), the filter MUST
    /// carry a non-null <see cref="AuditLogFilter.MarketId"/> — a null market
    /// for a tenant caller throws rather than silently returning every tenant's
    /// audit trail. The controller still pins the market, but the boundary no
    /// longer trusts it blindly.
    /// </summary>
    Task<PagedResult<AuditLogDto>> QueryAsync(
        AuditLogFilter filter,
        bool allowCrossMarket = false,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Run the suspicious-activity detection rules (Plan 07 Bosqich 3) over
    /// the recent audit window. Unless <paramref name="allowCrossMarket"/> is
    /// true (SuperAdmin), <paramref name="marketId"/> MUST be non-null — a null
    /// market for a tenant caller throws (no cross-tenant leak).
    /// </summary>
    Task<SuspiciousActivityReport> GetSuspiciousAsync(
        int? marketId,
        bool allowCrossMarket = false,
        CancellationToken cancellationToken = default);
}
