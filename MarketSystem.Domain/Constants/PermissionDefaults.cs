using MarketSystem.Domain.Enums;

namespace MarketSystem.Domain.Constants;

/// <summary>
/// Default permission sets per role.
///
/// These sets are chosen to reproduce the system's *current* hard-coded
/// authorization behaviour exactly, so that turning on RBAC does not silently
/// grant or revoke anything:
///
///   • Admin  — passes the old "AdminOrOwner" policy: full operational access
///              except the two Owner-exclusive financial report metrics.
///   • Seller — passes only the old "AllRoles" policy: view + own-sale create,
///              no management/destructive actions, no cost/profit visibility.
///
/// A new user is seeded with the set for its role. An existing user whose
/// explicit set is still empty falls back to these (see User.HasPermission),
/// so the migration needs no data step. Owner/SuperAdmin are never gated.
/// </summary>
public static class PermissionDefaults
{
    /// <summary>Admin = everything except the Owner-only financial views
    /// (profit summary, cash-balance report) — mirrors the old OwnerOnly gate.</summary>
    public static readonly IReadOnlyList<string> Admin = PermissionKeys.All
        .Where(k => k != PermissionKeys.DataProfit && k != PermissionKeys.DataCashBalance)
        .ToArray();

    /// <summary>Seller = view access + create-sale + customer create/edit +
    /// debt payment + the exports that were open to all roles. No product /
    /// category / user management, no customer delete, no cost/profit, no
    /// cash register. Note: no <c>reports.access</c> — the Reports controller
    /// was AdminOrOwner, so a Seller could only ever reach its export and
    /// daily-list endpoints (gated below by reports.export / sales.access).</summary>
    public static readonly IReadOnlyList<string> Seller = new[]
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

    /// <summary>Default effective set for a freshly created user of
    /// <paramref name="role"/>. Owner/SuperAdmin get the full catalogue
    /// (they are not gated, but a complete set keeps the data consistent).</summary>
    public static IReadOnlyList<string> ForRole(Role role) => role switch
    {
        Role.Admin => Admin,
        Role.Seller => Seller,
        _ => PermissionKeys.All,
    };
}
