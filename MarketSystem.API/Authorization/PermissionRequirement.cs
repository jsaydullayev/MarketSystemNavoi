using Microsoft.AspNetCore.Authorization;

namespace MarketSystem.API.Authorization;

/// <summary>
/// Authorization requirement carrying a single permission key
/// (e.g. <c>products.create</c>). Produced by <see cref="PermissionPolicyProvider"/>
/// for policies named <c>perm:&lt;key&gt;</c> and evaluated by
/// <see cref="PermissionAuthorizationHandler"/>.
/// </summary>
public sealed class PermissionRequirement : IAuthorizationRequirement
{
    public PermissionRequirement(string permission) => Permission = permission;

    public string Permission { get; }
}
