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

  // Features
  static const String products = '/products';
  static const String productsForm = '/products-form';
  static const String sales = '/sales';
  static const String salesForm = '/sales-form';
  static const String dailySales = '/daily-sales';
  static const String customers = '/customers';
  static const String customersForm = '/customers-form';
  static const String zakup = '/zakup';
  static const String zakupForm = '/zakup-form';
  static const String reports = '/reports';
  static const String debts = '/debts';
  static const String users = '/users';
  static const String usersForm = '/users-form';
  static const String adminProducts = '/admin-products';
  static const String adminProductsForm = '/admin-products-form';
  static const String profile = '/profile';

  // Sub-routes
  static const String productDetail = '/products/:id';
  static const String customerDetail = '/customers/:id';
  static const String saleDetail = '/sales/:id';
  static const String userDetail = '/users/:id';
}

/// Route arguments keys
class RouteArguments {
  static const String productId = 'product_id';
  static const String customerId = 'customer_id';
  static const String saleId = 'sale_id';
  static const String userId = 'user_id';
  static const String ZakupId = 'zakup_id';
}
