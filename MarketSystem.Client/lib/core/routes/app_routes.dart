/// App Routes
/// Centralized route name constants
library;

/// All app routes
class AppRoutes {
  // Splash/Welcome
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';

  // Main
  static const String dashboard = '/dashboard';

  // Hidden SuperAdmin console. Routed-to only after a successful SuperAdmin
  // login; intentionally NOT linked from any visible navigation. The backend
  // gates the actual API calls behind an opaque URL segment (see
  // SuperAdmin:ConsoleSegment), so even discovering this route name from a
  // build artefact isn't enough to reach the data — you also need a
  // SuperAdmin JWT and the matching segment.
  static const String superAdminConsole = '/superadmin-console';

  // Features
  static const String products = '/products';
  static const String sales = '/sales';
  static const String customers = '/customers';
  static const String zakup = '/zakup';
  static const String reports = '/reports';
  static const String debts = '/debts';
  static const String users = '/users';
  static const String adminProducts = '/admin-products';
  static const String profile = '/profile';
  static const String privacy = '/privacy';
  static const String cashRegister = '/cash-register';
  static const String notifications = '/notifications';
  // Owner / SuperAdmin (or Admin granted data.auditLog) — audit-log review.
  // Plan 07 Bosqich 4.
  static const String securityJournal = '/security-journal';
  // AUDIT-3 — dropped 7 orphan form-route constants (productsForm,
  // salesForm, customersForm, zakupForm, usersForm, adminProductsForm,
  // dailySales) and 4 sub-route patterns (productDetail, customerDetail,
  // saleDetail, userDetail). None had callers; route_generator.dart had
  // no handlers for them either. Form screens are opened via
  // MaterialPageRoute directly, so the named routes added nothing.
  // Also dropped the empty RouteArguments class — no consumer ever
  // read those keys.
}
