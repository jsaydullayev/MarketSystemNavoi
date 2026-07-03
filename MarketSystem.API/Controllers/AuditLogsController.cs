using System.Security.Claims;
using MarketSystem.API.Authorization;
using MarketSystem.Application.DTOs;
using MarketSystem.Application.Interfaces;
using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace MarketSystem.API.Controllers;

/// <summary>
/// Read-only API for the audit log (Plan 07 Bosqich 2). Owner / SuperAdmin
/// pass the permission gate automatically; an Admin may be granted
/// <see cref="PermissionKeys.DataAuditLog"/> by the Owner via the
/// permission-matrix screen.
///
/// Tenant scoping: every non-SuperAdmin caller is force-pinned to their own
/// market here in the controller, regardless of any <c>marketId</c> query
/// param — that's safer than relying on the service to remember the rule.
/// </summary>
[ApiController]
[Route("api/audit-logs")]
[Authorize]
public class AuditLogsController : ControllerBase
{
    private readonly IAuditLogQueryService _queryService;
    private readonly ICurrentMarketService _currentMarketService;

    public AuditLogsController(
        IAuditLogQueryService queryService,
        ICurrentMarketService currentMarketService)
    {
        _queryService = queryService;
        _currentMarketService = currentMarketService;
    }

    /// <summary>
    /// Paged audit-log lookup. All filter params are optional. The
    /// <paramref name="marketId"/> query param is only honoured for SuperAdmin —
    /// other callers are scoped to their own market.
    /// </summary>
    [HttpGet]
    [RequirePermission(PermissionKeys.DataAuditLog)]
    public async Task<ActionResult<PagedResult<AuditLogDto>>> Query(
        [FromQuery] string? entityType,
        [FromQuery] string? action,
        [FromQuery] Guid? userId,
        [FromQuery] int? marketId,
        [FromQuery] DateTime? from,
        [FromQuery] DateTime? to,
        [FromQuery] int page = 1,
        [FromQuery] int size = 50,
        CancellationToken ct = default)
    {
        var role = User.FindFirst(ClaimTypes.Role)?.Value;
        var isSuperAdmin = string.Equals(role, nameof(Role.SuperAdmin), StringComparison.Ordinal);

        // Owner / Admin / Seller are pinned to their tenant. SuperAdmin may
        // pass marketId (specific market) or omit it (all markets).
        var effectiveMarketId = isSuperAdmin
            ? marketId
            : _currentMarketService.TryGetCurrentMarketId();

        var filter = new AuditLogFilter(
            EntityType: entityType,
            Action: action,
            UserId: userId,
            MarketId: effectiveMarketId,
            FromUtc: from,
            ToUtc: to,
            Page: page,
            Size: size);

        return Ok(await _queryService.QueryAsync(filter, allowCrossMarket: isSuperAdmin, ct));
    }

    /// <summary>
    /// Suspicious-activity detection (Plan 07 Bosqich 3): groups recent
    /// audit events by the configured rules (failed-login burst, bulk
    /// delete) and returns whichever groups currently trip the threshold.
    /// Tenant scoping mirrors <see cref="Query"/> — SuperAdmin sees every
    /// market, everyone else is pinned to their own.
    /// </summary>
    [HttpGet("suspicious")]
    [RequirePermission(PermissionKeys.DataAuditLog)]
    public async Task<ActionResult<SuspiciousActivityReport>> GetSuspicious(
        [FromQuery] int? marketId,
        CancellationToken ct = default)
    {
        var role = User.FindFirst(ClaimTypes.Role)?.Value;
        var isSuperAdmin = string.Equals(role, nameof(Role.SuperAdmin), StringComparison.Ordinal);

        var effectiveMarketId = isSuperAdmin
            ? marketId
            : _currentMarketService.TryGetCurrentMarketId();

        return Ok(await _queryService.GetSuspiciousAsync(effectiveMarketId, allowCrossMarket: isSuperAdmin, ct));
    }
}
