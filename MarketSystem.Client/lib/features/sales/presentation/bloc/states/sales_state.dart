/// Sales States
/// Sales BLoC uchun holatlar

import 'package:equatable/equatable.dart';
import '../../../domain/entities/sale_entity.dart';

/// Sales State base class
abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SalesInitial extends SalesState {
  const SalesInitial();
}

/// Loading state
class SalesLoading extends SalesState {
  const SalesLoading();
}

/// Sales loaded state
class SalesLoaded extends SalesState {
  final List<SaleEntity> sales;

  const SalesLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}

/// My draft sales loaded state
class MyDraftSalesLoaded extends SalesState {
  final List<SaleEntity> sales;

  const MyDraftSalesLoaded(this.sales);

  @override
  List<Object?> get props => [sales];
}

/// Sale created state
class SaleCreated extends SalesState {
  final SaleEntity sale;

  const SaleCreated(this.sale);

  @override
  List<Object?> get props => [sale];
}

/// Sale item added state
class SaleItemAdded extends SalesState {
  const SaleItemAdded();
}

/// Payment added state
class PaymentAdded extends SalesState {
  const PaymentAdded();
}

/// Sale cancelled state
class SaleCancelled extends SalesState {
  const SaleCancelled();
}

/// Error state
class SalesError extends SalesState {
  final String message;

  const SalesError(this.message);

  @override
  List<Object?> get props => [message];
}
