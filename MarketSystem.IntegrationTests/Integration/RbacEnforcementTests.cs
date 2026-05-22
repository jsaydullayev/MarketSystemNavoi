using System.Reflection;
using System.Security.Claims;
using MarketSystem.API.Authorization;
using MarketSystem.API.Controllers;
using MarketSystem.Domain.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Routing;
using Microsoft.Extensions.Options;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies the RBAC *enforcement* layer that gates every HTTP request:
///   • PermissionAuthorizationHandler — who satisfies a permission requirement
///   • PermissionPolicyProvider       — perm:* policies are synthesised
///   • a reflection sweep proving every endpoint on the 9 RBAC controllers
///     is actually gated (catches a forgotten [RequirePermission]).
///
/// Together with RbacPermissionTests (the role-default model) this covers
/// "UI yashirsa ham endpoint 403 qaytaradi" without a full HTTP harness.
/// </summary>
public class RbacEnforcementTests
{
    // --- Handler: who satisfies a permission requirement ----------------

    private static async Task<bool> EvaluateAsync(
        string requiredKey, string role, params string[] grantedPerms)
    {
        var requirement = new PermissionRequirement(requiredKey);
        var claims = new List<Claim> { new(ClaimTypes.Role, role) };
        claims.AddRange(grantedPerms.Select(p =>
            new Claim(PermissionAuthorizationHandler.PermissionClaimType, p)));
        var user = new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
        var ctx = new AuthorizationHandlerContext(new[] { requirement }, user, null);

        await new PermissionAuthorizationHandler().HandleAsync(ctx);
        return ctx.HasSucceeded;
    }

    [Theory]
    [InlineData("Owner")]
    [InlineData("SuperAdmin")]
    public async Task Handler_OwnerAndSuperAdmin_PassWithNoPermClaims(string role)
        => (await EvaluateAsync(PermissionKeys.ProductsCreate, role))
            .Should().BeTrue($"{role} bypasses permission checks");

    [Fact]
    public async Task Handler_Admin_WithMatchingPermClaim_Passes()
        => (await EvaluateAsync(
                PermissionKeys.ProductsCreate, "Admin", PermissionKeys.ProductsCreate))
            .Should().BeTrue();

    [Fact]
    public async Task Handler_Admin_WithoutTheClaim_IsDenied()
        => (await EvaluateAsync(PermissionKeys.DataProfit, "Admin",
                PermissionKeys.ProductsCreate, PermissionKeys.SalesAccess))
            .Should().BeFalse("the Admin token carries no data.profit claim");

    [Fact]
    public async Task Handler_Seller_MissingDestructiveClaim_IsDenied()
        => (await EvaluateAsync(PermissionKeys.SalesDelete, "Seller",
                PermissionKeys.SalesAccess, PermissionKeys.SalesCreate))
            .Should().BeFalse("a default Seller cannot delete sales");

    [Fact]
    public async Task Handler_Seller_WithOwnerGrantedClaim_Passes()
        => (await EvaluateAsync(
                PermissionKeys.ProductsCreate, "Seller", PermissionKeys.ProductsCreate))
            .Should().BeTrue("an Owner grant adds the perm claim to the Seller token");

    // --- Policy provider: perm:* policies are synthesised ---------------

    [Fact]
    public async Task PolicyProvider_SynthesisesARequirementForPermPolicies()
    {
        var provider = new PermissionPolicyProvider(
            Options.Create(new AuthorizationOptions()));

        var policy = await provider.GetPolicyAsync(
            PermissionPolicyProvider.PolicyPrefix + PermissionKeys.SalesEdit);

        policy.Should().NotBeNull();
        policy!.Requirements.OfType<PermissionRequirement>()
            .Should().ContainSingle()
            .Which.Permission.Should().Be(PermissionKeys.SalesEdit);
    }

    // --- Coverage: no RBAC endpoint is left un-gated --------------------

    [Fact]
    public void EveryRbacControllerEndpoint_IsGatedOrExplicitlyExempt()
    {
        // Self-service endpoints — every authenticated user manages their own
        // profile, so they intentionally carry no [RequirePermission].
        var selfService = new HashSet<string>
        {
            "UsersController.MyProfile",
            "UsersController.UpdateMyProfile",
            "UsersController.UpdateProfileImage",
        };

        var controllers = new[]
        {
            typeof(ProductsController), typeof(SalesController),
            typeof(CustomersController), typeof(ProductCategoriesController),
            typeof(ZakupsController), typeof(UsersController),
            typeof(DebtsController), typeof(CashRegisterController),
            typeof(ReportsController),
        };

        var ungated = new List<string>();

        foreach (var controller in controllers)
        {
            var actions = controller
                .GetMethods(BindingFlags.Public | BindingFlags.Instance |
                            BindingFlags.DeclaredOnly)
                .Where(m => m.GetCustomAttributes<HttpMethodAttribute>(true).Any());

            foreach (var action in actions)
            {
                var id = $"{controller.Name}.{action.Name}";

                var gated =
                    action.GetCustomAttributes<RequirePermissionAttribute>(true).Any() ||
                    action.GetCustomAttributes<AllowAnonymousAttribute>(true).Any() ||
                    // catches [Authorize(Policy = "OwnerOnly")] on the permission
                    // management endpoints
                    action.GetCustomAttributes<AuthorizeAttribute>(true)
                        .Any(a => !string.IsNullOrEmpty(a.Policy)) ||
                    selfService.Contains(id);

                if (!gated) ungated.Add(id);
            }
        }

        ungated.Should().BeEmpty(
            "every RBAC controller endpoint must carry [RequirePermission], " +
            "[AllowAnonymous], a policy, or be a known self-service endpoint");
    }
}
