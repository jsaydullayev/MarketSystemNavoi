/// Dependency Injection Setup
/// Centralized service locator using get_it
library;

import 'package:get_it/get_it.dart';

// Handlers
import '../handlers/navigation_handler.dart';

// Providers
import '../providers/auth_provider.dart';

// HTTP Service
import '../../data/services/http_service.dart';

// Services
import '../../data/services/auth_service.dart';
import '../../data/services/customer_service.dart';
import '../../data/services/sales_service.dart';
import '../../data/services/zakup_service.dart';

// Sales Feature - Clean Architecture
import '../../features/sales/domain/repositories/sale_repository_interface.dart';
import '../../features/sales/data/repositories/sale_repository_impl.dart';
import '../../features/sales/data/datasources/sale_remote_data_source.dart';
import '../../features/sales/domain/usecases/get_sales_usecase.dart';
import '../../features/sales/domain/usecases/get_sale_detail_usecase.dart';
import '../../features/sales/domain/usecases/get_my_draft_sales_usecase.dart';
import '../../features/sales/domain/usecases/create_sale_usecase.dart';
import '../../features/sales/domain/usecases/add_sale_item_usecase.dart';
import '../../features/sales/domain/usecases/add_payment_usecase.dart';
import '../../features/sales/domain/usecases/cancel_sale_usecase.dart';
import '../../features/sales/domain/usecases/delete_sale_usecase.dart';
import '../../features/sales/domain/usecases/return_sale_item_usecase.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';

// Customers Feature - Clean Architecture
import '../../features/customers/domain/repositories/customer_repository_interface.dart';
import '../../features/customers/data/repositories/customer_repository_impl.dart';
import '../../features/customers/data/datasources/customer_remote_data_source.dart';
import '../../features/customers/domain/usecases/get_customers_usecase.dart';
import '../../features/customers/domain/usecases/get_customer_by_phone_usecase.dart';
import '../../features/customers/domain/usecases/create_customer_usecase.dart';
import '../../features/customers/domain/usecases/update_customer_usecase.dart';
import '../../features/customers/domain/usecases/delete_customer_usecase.dart';
import '../../features/customers/domain/usecases/get_customer_debts_usecase.dart';
import '../../features/customers/presentation/bloc/customers_bloc.dart';

// Zakup Feature - Clean Architecture
import '../../features/zakup/domain/repositories/zakup_repository_interface.dart';
import '../../features/zakup/data/repositories/zakup_repository_impl.dart';
import '../../features/zakup/data/datasources/zakup_remote_data_source.dart';
import '../../features/zakup/domain/usecases/get_zakups_usecase.dart';
import '../../features/zakup/domain/usecases/get_zakups_by_date_range_usecase.dart';
import '../../features/zakup/domain/usecases/create_zakup_usecase.dart';
import '../../features/zakup/presentation/bloc/zakup_bloc.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Dependency Injection setup
/// Call this in main.dart before runApp
Future<void> setupDependencyInjection() async {
  await _initCore();
  _initServices();
  _initAuthFeature();
  _initSalesFeature();
  _initCustomersFeature();
  _initZakupFeature();
}

/// Initialize core services
Future<void> _initCore() async {
  // Navigation handler is stateless, just register the type. The legacy
  // AuthHandler / NetworkHandler / StorageHandler trio that used to live
  // here was dead code — the Dio-based AuthRepository they backed had no
  // screen consumer, and tokens have moved to TokenStorage (secure
  // storage) so SharedPreferences-based handlers are no longer needed.
  sl.registerLazySingleton(() => NavigationHandler());
}

/// Initialize services
void _initServices() {
  // HttpService - shared singleton
  sl.registerLazySingleton<HttpService>(() => HttpService());

  // Auth Service - uses shared HttpService
  sl.registerFactory<AuthService>(() {
    final httpService = sl<HttpService>();
    final authService = AuthService(httpService: httpService);
    // AuthService'ni HttpService ga bog'lash (401 handler uchun)
    httpService.setAuthService(authService);
    return authService;
  });

  // Auth Provider - needs AuthService (register after AuthService)
  sl.registerLazySingleton<AuthProvider>(
    () => AuthProvider(authService: sl<AuthService>()),
  );

  // Customer Service - needs AuthProvider + shared HttpService
  sl.registerFactory<CustomerService>(
    () => CustomerService(authProvider: sl(), httpService: sl()),
  );

  // Sales Service - needs AuthProvider (HttpService is wired from AuthProvider)
  sl.registerFactory<SalesService>(() => SalesService(authProvider: sl()));

  // Zakup Service - needs AuthProvider + shared HttpService
  sl.registerFactory<ZakupService>(
    () => ZakupService(authProvider: sl(), httpService: sl()),
  );
}

/// Initialize Sales Feature (Clean Architecture)
void _initSalesFeature() {
  // Repository
  sl.registerFactory<SaleRepositoryInterface>(
    () => SaleRepositoryImpl(
      remoteDataSource: SaleRemoteDataSource(salesService: sl()),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetSalesUseCase(sl()));
  sl.registerLazySingleton(() => GetSaleDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetMyDraftSalesUseCase(sl()));
  sl.registerLazySingleton(() => CreateSaleUseCase(sl()));
  sl.registerLazySingleton(() => AddSaleItemUseCase(sl()));
  sl.registerLazySingleton(() => AddPaymentUseCase(sl()));
  sl.registerLazySingleton(() => CancelSaleUseCase(sl()));
  sl.registerLazySingleton(() => DeleteSaleUseCase(sl()));
  sl.registerLazySingleton(() => ReturnSaleItemUseCase(sl()));

  // BLoC
  sl.registerFactory<SalesBloc>(
    () => SalesBloc(
      getSalesUseCase: sl(),
      getSaleDetailUseCase: sl(),
      getMyDraftSalesUseCase: sl(),
      createSaleUseCase: sl(),
      addSaleItemUseCase: sl(),
      addPaymentUseCase: sl(),
      cancelSaleUseCase: sl(),
      deleteSaleUseCase: sl(),
      returnSaleItemUseCase: sl(),
    ),
  );
}

/// Initialize Customers Feature (Clean Architecture)
void _initCustomersFeature() {
  // Repository
  sl.registerFactory<CustomerRepositoryInterface>(
    () => CustomerRepositoryImpl(
      remoteDataSource: CustomerRemoteDataSource(customerService: sl()),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetCustomersUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerByPhoneUseCase(sl()));
  sl.registerLazySingleton(() => CreateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCustomerUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomerUseCase(sl()));
  sl.registerLazySingleton(() => GetCustomerDebtsUseCase(sl()));

  // BLoC
  sl.registerFactory<CustomersBloc>(
    () => CustomersBloc(
      getCustomersUseCase: sl(),
      getCustomerByPhoneUseCase: sl(),
      createCustomerUseCase: sl(),
      updateCustomerUseCase: sl(),
      deleteCustomerUseCase: sl(),
      getCustomerDebtsUseCase: sl(),
    ),
  );
}

/// Initialize Zakup Feature (Clean Architecture)
void _initZakupFeature() {
  // Repository
  sl.registerFactory<ZakupRepositoryInterface>(
    () => ZakupRepositoryImpl(
      remoteDataSource: ZakupRemoteDataSource(zakupService: sl()),
    ),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetZakupsUseCase(sl()));
  sl.registerLazySingleton(() => GetZakupsByDateRangeUseCase(sl()));
  sl.registerLazySingleton(() => CreateZakupUseCase(sl()));

  // BLoC
  sl.registerFactory<ZakupBloc>(
    () => ZakupBloc(
      getZakupsUseCase: sl(),
      getZakupsByDateRangeUseCase: sl(),
      createZakupUseCase: sl(),
    ),
  );
}

/// Reset all registered services (for testing)
Future<void> resetDependencyInjection() async {
  await sl.reset();
}

void _initAuthFeature() {
  // The Clean-Architecture-style AuthRepository scaffold lived here but
  // never had a screen consumer (login/register/welcome all talk to
  // AuthService directly through AuthProvider). Removed alongside the
  // Dio NetworkHandler stack — see the same commit's deletions in
  // core/handlers and features/auth/data + features/auth/domain.
}
