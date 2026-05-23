import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'zakup_entity.g.dart';

/// Zakup Entity - xarid obyekti
@JsonSerializable()
class ZakupEntity extends Equatable {
  final String id;
  final String productId;
  @JsonKey(defaultValue: '')
  final String productName;
  @FlexibleDoubleConverter()
  final double quantity;
  @FlexibleDoubleConverter()
  final double costPrice;
  @IsoDateTimeConverter()
  final DateTime createdAt;
  @JsonKey(defaultValue: "Noma'lum")
  final String createdBy;

  const ZakupEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.costPrice,
    required this.createdAt,
    required this.createdBy,
  });

  factory ZakupEntity.fromJson(Map<String, dynamic> json) =>
      _$ZakupEntityFromJson(json);

  Map<String, dynamic> toJson() => _$ZakupEntityToJson(this);

  String getFormattedCostPrice() => costPrice.toStringAsFixed(2);

  @override
  List<Object?> get props =>
      [id, productId, productName, quantity, costPrice, createdAt, createdBy];
}
