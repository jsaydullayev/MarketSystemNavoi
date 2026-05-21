using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;

namespace MarketSystem.API.Authorization;

/// <summary>
/// Dynamic authorization-policy provider. Policies whose name starts with
/// <c>perm:</c> are synthesised on the fly into a single
/// <see cref="PermissionRequirement"/> — this is what backs the
/// <see cref="RequirePermissionAttribute"/> without having to register a
/// named policy per permission key.
///
/// Every other policy name (the existing role policies — OwnerOnly,
/// AdminOrOwner, AllRoles, …) is delegated to the default provider unchanged.
/// </summary>
public sealed class PermissionPolicyProvider : IAuthorizationPolicyProvider
{
    public const string PolicyPrefix = "perm:";

    private readonly DefaultAuthorizationPolicyProvider _fallback;

    public PermissionPolicyProvider(IOptions<AuthorizationOptions> options)
        => _fallback = new DefaultAuthorizationPolicyProvider(options);

    public Task<AuthorizationPolicy> GetDefaultPolicyAsync() => _fallback.GetDefaultPolicyAsync();

    public Task<AuthorizationPolicy?> GetFallbackPolicyAsync() => _fallback.GetFallbackPolicyAsync();

    public Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (policyName.StartsWith(PolicyPrefix, StringComparison.OrdinalIgnoreCase))
        {
            var permission = policyName[PolicyPrefix.Length..];
            var policy = new AuthorizationPolicyBuilder()
                .RequireAuthenticatedUser()
                .AddRequirements(new PermissionRequirement(permission))
                .Build();
            return Task.FromResult<AuthorizationPolicy?>(policy);
        }

        return _fallback.GetPolicyAsync(policyName);
    }
}
