import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'customer_entity.g.dart';

/// Customer Entity - mijoz obyekti
@JsonSerializable()
class CustomerEntity extends Equatable {
  final String id;
  final String phone;
  final String? fullName;
  final String? comment;
  @FlexibleDoubleConverter()
  final double totalDebt;
  @IsoDateTimeConverter()
  final DateTime createdAt;
  @NullableIsoDateTimeConverter()
  final DateTime? updatedAt;

  const CustomerEntity({
    required this.id,
    required this.phone,
    this.fullName,
    this.comment,
    this.totalDebt = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory CustomerEntity.fromJson(Map<String, dynamic> json) =>
      _$CustomerEntityFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerEntityToJson(this);

  /// Telefon raqamini formatlash
  String getFormattedPhone() {
    if (phone.length == 12 && phone.startsWith('998')) {
      return '+${phone.substring(0, 3)} (${phone.substring(3, 5)}) ${phone.substring(5, 8)}-${phone.substring(8)}';
    }
    return phone;
  }

  /// To'liq ismini qaytarish (ism yoki telefon)
  String getDisplayName() {
    return fullName?.isNotEmpty == true ? fullName! : getFormattedPhone();
  }

  @override
  List<Object?> get props => [
    id,
    phone,
    fullName,
    comment,
    totalDebt,
    createdAt,
    updatedAt,
  ];
}
