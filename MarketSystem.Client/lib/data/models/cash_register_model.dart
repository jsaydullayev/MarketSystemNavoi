import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'cash_register_model.g.dart';

@JsonSerializable()
class CashRegisterModel {
  final String id;
  @FlexibleDoubleConverter()
  final double currentBalance;
  @IsoDateTimeConverter()
  final DateTime lastUpdated;
  @JsonKey(defaultValue: [])
  final List<CashWithdrawalModel> withdrawals;

  CashRegisterModel({
    required this.id,
    required this.currentBalance,
    required this.lastUpdated,
    required this.withdrawals,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) =>
      _$CashRegisterModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashRegisterModelToJson(this);
}

@JsonSerializable()
class CashWithdrawalModel {
  final String id;
  @FlexibleDoubleConverter()
  final double amount;
  final String comment;
  @IsoDateTimeConverter()
  final DateTime withdrawalDate;
  final String? userName;

  CashWithdrawalModel({
    required this.id,
    required this.amount,
    required this.comment,
    required this.withdrawalDate,
    this.userName,
  });

  factory CashWithdrawalModel.fromJson(Map<String, dynamic> json) =>
      _$CashWithdrawalModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashWithdrawalModelToJson(this);
}

@JsonSerializable()
class TodaySalesSummaryModel {
  final int totalSales;
  @FlexibleDoubleConverter()
  final double totalAmount;
  @FlexibleDoubleConverter()
  final double totalPaid;
  @FlexibleDoubleConverter()
  final double cashPaid;
  @FlexibleDoubleConverter()
  final double cardPaid;
  @FlexibleDoubleConverter()
  final double clickPaid;
  @FlexibleDoubleConverter()
  final double debtAmount;
  @IsoDateTimeConverter()
  final DateTime date;

  TodaySalesSummaryModel({
    required this.totalSales,
    required this.totalAmount,
    required this.totalPaid,
    required this.cashPaid,
    required this.cardPaid,
    required this.clickPaid,
    required this.debtAmount,
    required this.date,
  });

  factory TodaySalesSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$TodaySalesSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$TodaySalesSummaryModelToJson(this);
}
