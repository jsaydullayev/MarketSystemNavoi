/// Sales Events
/// Sales BLoC uchun hodisalar

import 'package:equatable/equatable.dart';

/// Sales Event base class
abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

/// Get all sales event
class GetSalesEvent extends SalesEvent {
  const GetSalesEvent();
}

/// Get my draft sales event
class GetMyDraftSalesEvent extends SalesEvent {
  const GetMyDraftSalesEvent();
}

/// Create sale event
class CreateSaleEvent extends SalesEvent {
  final String? customerId;

  const CreateSaleEvent({this.customerId});

  @override
  List<Object?> get props => [customerId];
}

/// Add sale item event
class AddSaleItemEvent extends SalesEvent {
  final String saleId;
  final String productId;
  final int quantity;
  final double salePrice;
  final double minSalePrice;
  final String? comment;

  const AddSaleItemEvent({
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.salePrice,
    required this.minSalePrice,
    this.comment,
  });

  @override
  List<Object?> get props => [saleId, productId, quantity, salePrice, minSalePrice, comment];
}

/// Add payment event
class AddPaymentEvent extends SalesEvent {
  final String saleId;
  final String paymentType;
  final double amount;

  const AddPaymentEvent({
    required this.saleId,
    required this.paymentType,
    required this.amount,
  });

  @override
  List<Object?> get props => [saleId, paymentType, amount];
}

/// Cancel sale event
class CancelSaleEvent extends SalesEvent {
  final String saleId;
  final String adminId;

  const CancelSaleEvent({
    required this.saleId,
    required this.adminId,
  });

  @override
  List<Object?> get props => [saleId, adminId];
}

/// Get sale detail event
class GetSaleDetailEvent extends SalesEvent {
  final String saleId;

  const GetSaleDetailEvent(this.saleId);

  @override
  List<Object?> get props => [saleId];
}

/// Return sale item event
class ReturnSaleItemEvent extends SalesEvent {
  final String saleId;
  final String saleItemId;
  final double quantity;
  final String? comment;

  const ReturnSaleItemEvent({
    required this.saleId,
    required this.saleItemId,
    required this.quantity,
    this.comment,
  });

  @override
  List<Object?> get props => [saleId, saleItemId, quantity, comment];
}

