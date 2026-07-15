namespace MarketSystem.Domain.Constants;

/// <summary>
/// Canonical <c>AuditLog.EntityType</c> values — kept here so producers and
/// (future) the audit-query layer agree on exact strings.
/// </summary>
public static class AuditEntityTypes
{
    public const string Sale = "Sale";
    public const string Payment = "Payment";
    public const string Zakup = "Zakup";
    public const string ZakupReceipt = "ZakupReceipt";
    public const string Supplier = "Supplier";
    public const string Debt = "Debt";
    public const string Auth = "Auth";
    public const string User = "User";
    public const string Permission = "Permission";
    public const string Market = "Market";
    public const string CashRegister = "CashRegister";
    public const string Shift = "Shift";
    public const string RegistrationRequest = "RegistrationRequest";
    public const string Product = "Product";
    // Server-side fault captured by the global exception handler (5xx). Surfaces
    // in the security journal's "Suspicious" tab so the Owner/developer can read
    // the status code + message and fix it.
    public const string Error = "Error";
}

/// <summary>Canonical <c>AuditLog.Action</c> values.</summary>
public static class AuditActions
{
    public const string Create = "Create";
    public const string Update = "Update";
    public const string Delete = "Delete";
    public const string Cancel = "Cancel";
    public const string Login = "Login";
    public const string LoginFailed = "LoginFailed";
    public const string Logout = "Logout";
    public const string Activate = "Activate";
    public const string Deactivate = "Deactivate";
    public const string PermissionChange = "PermissionChange";
    public const string Block = "Block";
    public const string Unblock = "Unblock";
    public const string Withdraw = "Withdraw";
    public const string Deposit = "Deposit";
    public const string Open = "Open";
    public const string Close = "Close";

    // Y1 — distinguish password-change from a generic User Update so the
    // security journal can isolate credential events for review.
    public const string PasswordChange = "PasswordChange";
    public const string ShiftChange = "ShiftChange";
    public const string ProfileImageUpdate = "ProfileImageUpdate";
    public const string ProductImageUpdate = "ProductImageUpdate";

    // Owner hand-corrected a product's on-hand stock outside the zakup/sales
    // flow (e.g. after a physical inventory count). Fraud-sensitive, so it gets
    // its own action rather than a generic Update for the security journal.
    public const string StockAdjust = "StockAdjust";

    // A server-side fault (5xx) recorded by the global exception handler.
    public const string Error = "Error";
}
