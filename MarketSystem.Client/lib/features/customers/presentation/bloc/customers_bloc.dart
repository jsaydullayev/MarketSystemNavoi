/// Customers BLoC
/// Customers state management

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/create_customer_usecase.dart';
import '../../domain/usecases/delete_customer_usecase.dart';
import '../../domain/usecases/get_customer_by_phone_usecase.dart';
import '../../domain/usecases/get_customers_usecase.dart';
import '../../domain/usecases/update_customer_usecase.dart';
import '../../domain/usecases/get_customer_debts_usecase.dart';
import 'events/customers_event.dart';
import 'states/customers_state.dart';

/// Customers BLoC
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final GetCustomersUseCase getCustomersUseCase;
  final GetCustomerByPhoneUseCase getCustomerByPhoneUseCase;
  final CreateCustomerUseCase createCustomerUseCase;
  final UpdateCustomerUseCase updateCustomerUseCase;
  final DeleteCustomerUseCase deleteCustomerUseCase;
  final GetCustomerDebtsUseCase getCustomerDebtsUseCase;

  CustomersBloc({
    required this.getCustomersUseCase,
    required this.getCustomerByPhoneUseCase,
    required this.createCustomerUseCase,
    required this.updateCustomerUseCase,
    required this.deleteCustomerUseCase,
    required this.getCustomerDebtsUseCase,
  }) : super(const CustomersInitial()) {
    on<GetCustomersEvent>(_onGetCustomers);
    on<GetCustomerByPhoneEvent>(_onGetCustomerByPhone);
    on<CreateCustomerEvent>(_onCreateCustomer);
    on<UpdateCustomerEvent>(_onUpdateCustomer);
    on<DeleteCustomerEvent>(_onDeleteCustomer);
    on<GetCustomerDebtsEvent>(_onGetCustomerDebts);
  }

  /// Get all customers
  Future<void> _onGetCustomers(
    GetCustomersEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await getCustomersUseCase();

    if (result.isSuccess && result.data != null) {
      emit(CustomersLoaded(result.data!));
    } else {
      emit(CustomersError(result.error ?? 'Mijozlarni yuklashda xatolik'));
    }
  }

  /// Get customer by phone
  Future<void> _onGetCustomerByPhone(
    GetCustomerByPhoneEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await getCustomerByPhoneUseCase(event.phone);

    if (result.isSuccess) {
      if (result.data != null) {
        emit(CustomerFound(result.data!));
      } else {
        emit(const CustomerNotFound());
      }
    } else {
      emit(CustomersError(result.error ?? 'Mijozni qidirishda xatolik'));
    }
  }

  /// Create customer
  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await createCustomerUseCase(
      phone: event.phone,
      fullName: event.fullName,
      comment: event.comment,
      initialDebt: event.initialDebt,
    );

    if (result.isSuccess && result.data != null) {
      emit(CustomerCreated(result.data!));
    } else {
      emit(CustomersError(result.error ?? 'Mijoz yaratishda xatolik'));
    }
  }

  /// Update customer
  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await updateCustomerUseCase(
      phone: event.phone,
      fullName: event.fullName,
    );

    if (result.isSuccess && result.data != null) {
      emit(CustomerUpdated(result.data!));
    } else {
      emit(CustomersError(result.error ?? 'Mijoz ma\'lumotlarini yangilashda xatolik'));
    }
  }

  /// Delete customer
  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await deleteCustomerUseCase(event.id);

    if (result.isSuccess) {
      emit(const CustomerDeleted());
    } else {
      emit(CustomersError(result.error ?? 'Mijozni o\'chirishda xatolik'));
    }
  }

  /// Get customer debts
  Future<void> _onGetCustomerDebts(
    GetCustomerDebtsEvent event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomerDebtsLoading());
    final result = await getCustomerDebtsUseCase(event.customerId);

    if (result.isSuccess && result.data != null) {
      emit(CustomerDebtsLoaded(result.data!));
    } else {
      emit(CustomersError(result.error ?? 'Mijoz qarzlarini yuklashda xatolik'));
    }
  }
}
