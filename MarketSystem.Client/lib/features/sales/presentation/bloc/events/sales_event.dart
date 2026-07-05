// Sales Events
// Sales BLoC uchun hodisalar

import 'package:equatable/equatable.dart';

/// Sales Event base class
abstract class SalesEvent extends Equatable {
  const SalesEvent();

  @override
  List<Object?> get props => [];
}

/// Get all sales event (page=1 reset)
class GetSalesEvent extends SalesEvent {
  const GetSalesEvent();
}

/// Load next page of sales
class LoadMoreSalesEvent extends SalesEvent {
  const LoadMoreSalesEvent();
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
  final double quantity; // ✅ DECIMAL - 22.5 m, 15.5 kg bo'lishi mumkin
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
  List<Object?> get props => [
    saleId,
    productId,
    quantity,
    salePrice,
    minSalePrice,
    comment,
  ];
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

/// Cancel sale event. The acting admin is taken from the JWT on the server
/// — no adminId param here.
class CancelSaleEvent extends SalesEvent {
  final String saleId;

  const CancelSaleEvent({required this.saleId});

  @override
  List<Object?> get props => [saleId];
}

/// Delete sale event (Owner data-cleanup). The acting user is taken from the
/// JWT on the server — no actorId param here.
class DeleteSaleEvent extends SalesEvent {
  final String saleId;

  const DeleteSaleEvent({required this.saleId});

  @override
  List<Object?> get props => [saleId];
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
