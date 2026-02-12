/// Zakup Events
/// Zakup BLoC uchun hodisalar

import 'package:equatable/equatable.dart';

/// Zakup Event base class
abstract class ZakupEvent extends Equatable {
  const ZakupEvent();

  @override
  List<Object?> get props => [];
}

/// Get all zakups event
class GetZakupsEvent extends ZakupEvent {
  const GetZakupsEvent();
}

/// Get zakups by date range event
class GetZakupsByDateRangeEvent extends ZakupEvent {
  final DateTime start;
  final DateTime end;

  const GetZakupsByDateRangeEvent({
    required this.start,
    required this.end,
  });

  @override
  List<Object?> get props => [start, end];
}

/// Create zakup event
class CreateZakupEvent extends ZakupEvent {
  final String productId;
  final int quantity;
  final double costPrice;

  const CreateZakupEvent({
    required this.productId,
    required this.quantity,
    required this.costPrice,
  });

  @override
  List<Object?> get props => [productId, quantity, costPrice];
}
