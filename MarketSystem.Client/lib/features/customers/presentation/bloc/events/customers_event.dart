/// Customers Events
/// Customers BLoC uchun hodisalar

import 'package:equatable/equatable.dart';

/// Customers Event base class
abstract class CustomersEvent extends Equatable {
  const CustomersEvent();

  @override
  List<Object?> get props => [];
}

/// Get all customers event
class GetCustomersEvent extends CustomersEvent {
  const GetCustomersEvent();
}

/// Get customer by phone event
class GetCustomerByPhoneEvent extends CustomersEvent {
  final String phone;

  const GetCustomerByPhoneEvent(this.phone);

  @override
  List<Object?> get props => [phone];
}

/// Create customer event
class CreateCustomerEvent extends CustomersEvent {
  final String phone;
  final String? fullName;
  final String? comment;
  final double? initialDebt;

  const CreateCustomerEvent({
    required this.phone,
    this.fullName,
    this.comment,
    this.initialDebt,
  });

  @override
  List<Object?> get props => [phone, fullName, comment, initialDebt];
}

/// Update customer event
class UpdateCustomerEvent extends CustomersEvent {
  final String phone;
  final String? fullName;

  const UpdateCustomerEvent({
    required this.phone,
    this.fullName,
  });

  @override
  List<Object?> get props => [phone, fullName];
}

/// Delete customer event
class DeleteCustomerEvent extends CustomersEvent {
  final String id;

  const DeleteCustomerEvent(this.id);

  @override
  List<Object?> get props => [id];
}

/// Get customer debts event
class GetCustomerDebtsEvent extends CustomersEvent {
  final String customerId;

  const GetCustomerDebtsEvent(this.customerId);

  @override
  List<Object?> get props => [customerId];
}
