/// Owner RBAC — client-side permission keys.
///
/// These MUST stay in sync with the backend catalogue
/// (`MarketSystem.Domain/Constants/PermissionKeys.cs`). The backend is the
/// real gate — these keys only drive what the UI shows/hides so a user is
/// not offered an action the server would 403.
class Permissions {
  Permissions._();

  static const dashboardAccess = 'dashboard.access';
  static const notificationsAccess = 'notifications.access';

  static const productsAccess = 'products.access';
  static const productsCreate = 'products.create';
  static const productsEdit = 'products.edit';
  static const productsDelete = 'products.delete';
  static const productsExport = 'products.export';
  static const productsImport = 'products.import';

  static const categoriesAccess = 'categories.access';
  static const categoriesManage = 'categories.manage';

  static const salesAccess = 'sales.access';
  static const salesCreate = 'sales.create';
  static const salesEdit = 'sales.edit';
  static const salesDelete = 'sales.delete';
  static const salesExport = 'sales.export';
  static const salesInvoice = 'sales.invoice';

  static const customersAccess = 'customers.access';
  static const customersManage = 'customers.manage';
  static const customersDelete = 'customers.delete';
  static const customersExport = 'customers.export';

  static const zakupAccess = 'zakup.access';
  static const zakupCreate = 'zakup.create';

  static const cashRegisterAccess = 'cashregister.access';
  static const cashRegisterManage = 'cashregister.manage';

  static const reportsAccess = 'reports.access';
  static const reportsExport = 'reports.export';

  static const usersAccess = 'users.access';
  static const usersManage = 'users.manage';
  static const usersShift = 'users.shift';

  static const debtsAccess = 'debts.access';
  static const debtsManage = 'debts.manage';
  static const debtsDueDate = 'debts.dueDate';

  static const dataCostPrice = 'data.costPrice';
  static const dataProfit = 'data.profit';
  static const dataCashBalance = 'data.cashBalance';
  static const dataAllSalesView = 'data.allSalesView';
  // Audit-log viewing — Owner / SuperAdmin always have it (handler bypass);
  // Owner may grant it to a trusted Admin via the permission-matrix screen.
  static const dataAuditLog = 'data.auditLog';
}
