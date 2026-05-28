namespace MarketSystem.Domain.Constants;

/// <summary>
/// Canonical catalogue of fine-grained permission keys used by the Owner
/// RBAC system. A non-Owner user's effective permission set is a subset of
/// <see cref="All"/>.
///
/// Owner and SuperAdmin are NEVER gated by permissions — they always have
/// full access. Permissions only ever constrain Admin and Seller users.
/// </summary>
public static class PermissionKeys
{
    public const string DashboardAccess = "dashboard.access";

    public const string ProductsAccess = "products.access";
    public const string ProductsCreate = "products.create";
    public const string ProductsEdit = "products.edit";
    public const string ProductsDelete = "products.delete";
    public const string ProductsExport = "products.export";
    public const string ProductsImport = "products.import";

    public const string CategoriesAccess = "categories.access";
    public const string CategoriesManage = "categories.manage";

    public const string SalesAccess = "sales.access";
    public const string SalesCreate = "sales.create";
    public const string SalesEdit = "sales.edit";
    public const string SalesDelete = "sales.delete";
    public const string SalesExport = "sales.export";

    public const string CustomersAccess = "customers.access";
    public const string CustomersManage = "customers.manage";
    public const string CustomersDelete = "customers.delete";
    public const string CustomersExport = "customers.export";

    public const string ZakupAccess = "zakup.access";
    public const string ZakupCreate = "zakup.create";

    public const string CashRegisterAccess = "cashregister.access";
    public const string CashRegisterManage = "cashregister.manage";

    public const string ReportsAccess = "reports.access";
    public const string ReportsExport = "reports.export";

    public const string UsersAccess = "users.access";
    public const string UsersManage = "users.manage";
    public const string UsersShift = "users.shift";

    public const string DebtsAccess = "debts.access";
    public const string DebtsManage = "debts.manage";

    // Sensitive data fields — gate whether the user may see the value at all.
    public const string DataCostPrice = "data.costPrice";
    public const string DataProfit = "data.profit";
    public const string DataCashBalance = "data.cashBalance";
    public const string DataAllSalesView = "data.allSalesView";
    // Audit-log viewing — Owner/SuperAdmin always have it (handler bypass);
    // Owner can grant it to a trusted Admin via the permission-matrix screen.
    public const string DataAuditLog = "data.auditLog";

    /// <summary>Every permission key, in catalogue order. Used for validation
    /// and to render the Owner permission-matrix screen.</summary>
    public static readonly IReadOnlyList<string> All = new[]
    {
        DashboardAccess,
        ProductsAccess, ProductsCreate, ProductsEdit, ProductsDelete, ProductsExport, ProductsImport,
        CategoriesAccess, CategoriesManage,
        SalesAccess, SalesCreate, SalesEdit, SalesDelete, SalesExport,
        CustomersAccess, CustomersManage, CustomersDelete, CustomersExport,
        ZakupAccess, ZakupCreate,
        CashRegisterAccess, CashRegisterManage,
        ReportsAccess, ReportsExport,
        UsersAccess, UsersManage, UsersShift,
        DebtsAccess, DebtsManage,
        DataCostPrice, DataProfit, DataCashBalance, DataAllSalesView, DataAuditLog,
    };

    /// <summary>True when <paramref name="key"/> is a recognised permission
    /// key — guards the PUT /permissions endpoint against typos / injection.</summary>
    public static bool IsValid(string key) => All.Contains(key);
}
