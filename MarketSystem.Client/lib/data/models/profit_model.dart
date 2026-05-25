import 'package:json_annotation/json_annotation.dart';
import 'package:market_system_client/core/utils/json_converters.dart';

part 'profit_model.g.dart';

@JsonSerializable()
class ProfitSummaryModel {
  @FlexibleDoubleConverter()
  final double todayProfit;
  @FlexibleDoubleConverter()
  final double weekProfit;
  @FlexibleDoubleConverter()
  final double monthProfit;
  @FlexibleDoubleConverter()
  final double totalProfit;

  ProfitSummaryModel({
    required this.todayProfit,
    required this.weekProfit,
    required this.monthProfit,
    required this.totalProfit,
  });

  factory ProfitSummaryModel.fromJson(Map<String, dynamic> json) =>
      _$ProfitSummaryModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfitSummaryModelToJson(this);
}

@JsonSerializable()
class CashBalanceModel {
  @FlexibleDoubleConverter()
  final double cashInRegister;
  @FlexibleDoubleConverter()
  final double cardPayments;
  @FlexibleDoubleConverter()
  final double totalBalance;

  CashBalanceModel({
    required this.cashInRegister,
    required this.cardPayments,
    required this.totalBalance,
  });

  factory CashBalanceModel.fromJson(Map<String, dynamic> json) =>
      _$CashBalanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$CashBalanceModelToJson(this);
}

@JsonSerializable()
class DailySalesListItemModel {
  @JsonKey(defaultValue: '')
  final String id;
  @IsoDateTimeConverter()
  final DateTime createdAt;
  @JsonKey(defaultValue: 'Unknown')
  final String sellerName;
  @FlexibleDoubleConverter()
  final double totalAmount;
  @JsonKey(defaultValue: 'Cash')
  final String paymentType;
  @JsonKey(defaultValue: 'Draft')
  final String status;
  @FlexibleNullableDoubleConverter()
  final double? profit;
  final String? customerName;

  DailySalesListItemModel({
    required this.id,
    required this.createdAt,
    required this.sellerName,
    required this.totalAmount,
    required this.paymentType,
    required this.status,
    this.profit,
    this.customerName,
  });

  factory DailySalesListItemModel.fromJson(Map<String, dynamic> json) =>
      _$DailySalesListItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailySalesListItemModelToJson(this);
}

@JsonSerializable()
class DailySalesListModel {
  @IsoDateTimeConverter()
  final DateTime date;
  @JsonKey(defaultValue: [])
  final List<DailySalesListItemModel> sales;
  @FlexibleDoubleConverter()
  final double totalSales;
  @FlexibleDoubleConverter()
  final double totalPaidSales;
  @FlexibleDoubleConverter()
  final double totalDebtSales;
  @JsonKey(defaultValue: 0)
  final int totalTransactions;
  @FlexibleNullableDoubleConverter()
  final double? summaryProfit;

  DailySalesListModel({
    required this.date,
    required this.sales,
    required this.totalSales,
    required this.totalPaidSales,
    required this.totalDebtSales,
    required this.totalTransactions,
    this.summaryProfit,
  });

  factory DailySalesListModel.fromJson(Map<String, dynamic> json) =>
      _$DailySalesListModelFromJson(json);

  Map<String, dynamic> toJson() => _$DailySalesListModelToJson(this);
}
