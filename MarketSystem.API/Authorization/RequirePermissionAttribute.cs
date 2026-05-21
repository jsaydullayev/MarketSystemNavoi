using Microsoft.AspNetCore.Authorization;

namespace MarketSystem.API.Authorization;

/// <summary>
/// Restricts an endpoint to users holding a specific permission key.
///
/// Usage: <c>[RequirePermission(PermissionKeys.ProductsCreate)]</c>.
///
/// Owner and SuperAdmin always pass (see <see cref="PermissionAuthorizationHandler"/>);
/// Admin and Seller must carry the matching permission. This is the RBAC
/// replacement for the old role policies (AdminOrOwner / AllRoles / …).
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method, AllowMultiple = true, Inherited = true)]
public sealed class RequirePermissionAttribute : AuthorizeAttribute
{
    public RequirePermissionAttribute(string permission)
        => Policy = PermissionPolicyProvider.PolicyPrefix + permission;
}
