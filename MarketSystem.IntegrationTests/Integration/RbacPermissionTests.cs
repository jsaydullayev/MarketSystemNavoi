using MarketSystem.Domain.Constants;
using MarketSystem.Domain.Entities;
using MarketSystem.Domain.Enums;
using FluentAssertions;
using Xunit;

namespace MarketSystem.IntegrationTests.Integration;

/// <summary>
/// Verifies the Owner RBAC permission model — specifically that the role
/// defaults reproduce the system's pre-RBAC hard-coded authorization, so the
/// 42-endpoint policy migration grants/revokes nothing by accident.
///
/// The invariants asserted here mirror the old role policies:
///   • AllRoles endpoints  → permission is in the Seller default
///   • AdminOrOwner-only   → permission is NOT in the Seller default
///   • OwnerOnly           → permission is NOT in the Admin default
/// </summary>
public class RbacPermissionTests
{
    private static User UserWith(Role role, params string[] permissions)
        => new()
        {
            Id = Guid.NewGuid(),
            FullName = "Test",
            Username = "test",
            Role = role,
            Permissions = permissions.ToList(),
        };

    // ---- Owner / SuperAdmin always bypass ------------------------------

    [Theory]
    [InlineData(Role.Owner)]
    [InlineData(Role.SuperAdmin)]
    public void OwnerAndSuperAdmin_HaveEveryPermission(Role role)
    {
        var user = UserWith(role);

        foreach (var key in PermissionKeys.All)
            user.HasPermission(key).Should().BeTrue($"{role} must never be gated by {key}");

        user.GetEffectivePermissions().Should().BeEquivalentTo(PermissionKeys.All);
    }

    // ---- Admin default = old "AdminOrOwner" reach ----------------------

    [Fact]
    public void AdminDefault_HasEverythingExceptOwnerOnlyFinancials()
    {
        var admin = UserWith(Role.Admin); // empty set → role default

        // Owner-only report metrics — Admin was blocked by the OwnerOnly policy.
        admin.HasPermission(PermissionKeys.DataProfit).Should().BeFalse();
        admin.HasPermission(PermissionKeys.DataCashBalance).Should().BeFalse();

        // Everything else was reachable by Admin via AdminOrOwner / AllRoles.
        foreach (var key in PermissionKeys.All)
        {
            if (key is PermissionKeys.DataProfit or PermissionKeys.DataCashBalance)
                continue;
            admin.HasPermission(key).Should().BeTrue($"Admin default must include {key}");
        }
    }

    // ---- Seller default = old "AllRoles" reach -------------------------

    [Fact]
    public void SellerDefault_GrantsExactlyTheAllRolesEndpoints()
    {
        var seller = UserWith(Role.Seller); // empty set → role default

        // Granted: view + create-sale + customer create/edit + debt pay + open exports.
        string[] granted =
        {
            PermissionKeys.DashboardAccess,
            PermissionKeys.ProductsAccess, PermissionKeys.ProductsExport,
            PermissionKeys.CategoriesAccess,
            PermissionKeys.SalesAccess, PermissionKeys.SalesCreate, PermissionKeys.SalesExport,
            PermissionKeys.CustomersAccess, PermissionKeys.CustomersManage, PermissionKeys.CustomersExport,
            PermissionKeys.ZakupAccess,
            PermissionKeys.ReportsExport,
            PermissionKeys.UsersAccess,
            PermissionKeys.DebtsAccess, PermissionKeys.DebtsManage,
            PermissionKeys.DataAllSalesView,
        };
        foreach (var key in granted)
            seller.HasPermission(key).Should().BeTrue($"Seller default must include {key}");
    }

    [Fact]
    public void SellerDefault_DeniesEveryManagementAndDestructiveAction()
    {
        var seller = UserWith(Role.Seller);

        // Denied: was AdminOrOwner / OwnerOnly — Seller got a 403 before RBAC too.
        string[] denied =
        {
            PermissionKeys.ProductsCreate, PermissionKeys.ProductsEdit, PermissionKeys.ProductsDelete,
            PermissionKeys.CategoriesManage,
            PermissionKeys.SalesEdit, PermissionKeys.SalesDelete,
            PermissionKeys.CustomersDelete,
            PermissionKeys.ZakupCreate,
            PermissionKeys.CashRegisterAccess, PermissionKeys.CashRegisterManage,
            PermissionKeys.ReportsAccess,
            PermissionKeys.UsersManage, PermissionKeys.UsersShift,
            PermissionKeys.DataCostPrice, PermissionKeys.DataProfit, PermissionKeys.DataCashBalance,
        };
        foreach (var key in denied)
            seller.HasPermission(key).Should().BeFalse($"Seller default must NOT include {key}");
    }

    // ---- Explicit set overrides the role default -----------------------

    [Fact]
    public void ExplicitPermissionSet_OverridesTheRoleDefault()
    {
        // An Owner grants this Seller exactly one capability.
        var seller = UserWith(Role.Seller, PermissionKeys.ProductsAccess);

        seller.HasPermission(PermissionKeys.ProductsAccess).Should().BeTrue();
        // Anything outside the explicit set is now denied — even sales.create,
        // which the role default would have granted.
        seller.HasPermission(PermissionKeys.SalesCreate).Should().BeFalse();
        seller.GetEffectivePermissions().Should().ContainSingle()
            .Which.Should().Be(PermissionKeys.ProductsAccess);
    }

    [Fact]
    public void EmptyPermissionSet_FallsBackToRoleDefault()
    {
        var seller = UserWith(Role.Seller);

        seller.GetEffectivePermissions()
            .Should().BeEquivalentTo(PermissionDefaults.ForRole(Role.Seller));
    }

    // ---- Catalogue integrity -------------------------------------------

    [Fact]
    public void PermissionCatalogue_HasNoDuplicates()
        => PermissionKeys.All.Should().OnlyHaveUniqueItems();

    [Theory]
    [InlineData("products.create", true)]
    [InlineData("customers.delete", true)]
    [InlineData("data.profit", true)]
    [InlineData("products.destroy", false)]
    [InlineData("", false)]
    public void IsValid_RecognisesOnlyCataloguedKeys(string key, bool expected)
        => PermissionKeys.IsValid(key).Should().Be(expected);
}
