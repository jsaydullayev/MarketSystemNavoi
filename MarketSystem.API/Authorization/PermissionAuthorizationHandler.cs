using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;

namespace MarketSystem.API.Authorization;

/// <summary>
/// Evaluates a <see cref="PermissionRequirement"/> against the current user.
///
/// Owner and SuperAdmin are never gated — they pass every permission check.
/// For Admin and Seller the requirement is satisfied only when the access
/// token carries a matching <c>perm</c> claim (the user's effective
/// permission set is embedded at login by JwtService).
/// </summary>
public sealed class PermissionAuthorizationHandler : AuthorizationHandler<PermissionRequirement>
{
    /// <summary>Claim type used to carry each granted permission key in the JWT.</summary>
    public const string PermissionClaimType = "perm";

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionRequirement requirement)
    {
        var role = context.User.FindFirst(ClaimTypes.Role)?.Value;

        // Owner / SuperAdmin bypass — they always have full access.
        if (role is "Owner" or "SuperAdmin")
        {
            context.Succeed(requirement);
            return Task.CompletedTask;
        }

        var granted = context.User
            .FindAll(PermissionClaimType)
            .Any(c => string.Equals(c.Value, requirement.Permission, StringComparison.Ordinal));

        if (granted)
            context.Succeed(requirement);

        // Otherwise leave the requirement unsatisfied → 403 Forbidden.
        return Task.CompletedTask;
    }
}
