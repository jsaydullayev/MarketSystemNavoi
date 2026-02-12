/// Customers States
/// Customers BLoC uchun holatlar

import 'package:equatable/equatable.dart';
import '../../../domain/entities/customer_entity.dart';

/// Customers State base class
abstract class CustomersState extends Equatable {
  const CustomersState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

/// Loading state
class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

/// Customers loaded state
class CustomersLoaded extends CustomersState {
  final List<CustomerEntity> customers;

  const CustomersLoaded(this.customers);

  @override
  List<Object?> get props => [customers];
}

/// Customer found state
class CustomerFound extends CustomersState {
  final CustomerEntity customer;

  const CustomerFound(this.customer);

  @override
  List<Object?> get props => [customer];
}

/// Customer not found state
class CustomerNotFound extends CustomersState {
  const CustomerNotFound();
}

/// Customer created state
class CustomerCreated extends CustomersState {
  final CustomerEntity customer;

  const CustomerCreated(this.customer);

  @override
  List<Object?> get props => [customer];
}

/// Customer updated state
class CustomerUpdated extends CustomersState {
  final CustomerEntity customer;

  const CustomerUpdated(this.customer);

  @override
  List<Object?> get props => [customer];
}

/// Customer deleted state
class CustomerDeleted extends CustomersState {
  const CustomerDeleted();
}

/// Error state
class CustomersError extends CustomersState {
  final String message;

  const CustomersError(this.message);

  @override
  List<Object?> get props => [message];
}
