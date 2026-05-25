// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profit_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfitSummaryModel _$ProfitSummaryModelFromJson(
  Map<String, dynamic> json,
) => ProfitSummaryModel(
  todayProfit: const FlexibleDoubleConverter().fromJson(json['todayProfit']),
  weekProfit: const FlexibleDoubleConverter().fromJson(json['weekProfit']),
  monthProfit: const FlexibleDoubleConverter().fromJson(json['monthProfit']),
  totalProfit: const FlexibleDoubleConverter().fromJson(json['totalProfit']),
);

Map<String, dynamic> _$ProfitSummaryModelToJson(
  ProfitSummaryModel instance,
) => <String, dynamic>{
  'todayProfit': const FlexibleDoubleConverter().toJson(instance.todayProfit),
  'weekProfit': const FlexibleDoubleConverter().toJson(instance.weekProfit),
  'monthProfit': const FlexibleDoubleConverter().toJson(instance.monthProfit),
  'totalProfit': const FlexibleDoubleConverter().toJson(instance.totalProfit),
};

CashBalanceModel _$CashBalanceModelFromJson(
  Map<String, dynamic> json,
) => CashBalanceModel(
  cashInRegister: const FlexibleDoubleConverter().fromJson(
    json['cashInRegister'],
  ),
  cardPayments: const FlexibleDoubleConverter().fromJson(json['cardPayments']),
  totalBalance: const FlexibleDoubleConverter().fromJson(json['totalBalance']),
);

Map<String, dynamic> _$CashBalanceModelToJson(
  CashBalanceModel instance,
) => <String, dynamic>{
  'cashInRegister': const FlexibleDoubleConverter().toJson(
    instance.cashInRegister,
  ),
  'cardPayments': const FlexibleDoubleConverter().toJson(instance.cardPayments),
  'totalBalance': const FlexibleDoubleConverter().toJson(instance.totalBalance),
};

DailySalesListItemModel _$DailySalesListItemModelFromJson(
  Map<String, dynamic> json,
) => DailySalesListItemModel(
  id: json['id'] as String? ?? '',
  createdAt: const IsoDateTimeConverter().fromJson(json['createdAt']),
  sellerName: json['sellerName'] as String? ?? 'Unknown',
  totalAmount: const FlexibleDoubleConverter().fromJson(json['totalAmount']),
  paymentType: json['paymentType'] as String? ?? 'Cash',
  status: json['status'] as String? ?? 'Draft',
  profit: const FlexibleNullableDoubleConverter().fromJson(json['profit']),
  customerName: json['customerName'] as String?,
);

Map<String, dynamic> _$DailySalesListItemModelToJson(
  DailySalesListItemModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'createdAt': const IsoDateTimeConverter().toJson(instance.createdAt),
  'sellerName': instance.sellerName,
  'totalAmount': const FlexibleDoubleConverter().toJson(instance.totalAmount),
  'paymentType': instance.paymentType,
  'status': instance.status,
  'profit': const FlexibleNullableDoubleConverter().toJson(instance.profit),
  'customerName': instance.customerName,
};

DailySalesListModel _$DailySalesListModelFromJson(Map<String, dynamic> json) =>
    DailySalesListModel(
      date: const IsoDateTimeConverter().fromJson(json['date']),
      sales:
          (json['sales'] as List<dynamic>?)
              ?.map(
                (e) =>
                    DailySalesListItemModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalSales: const FlexibleDoubleConverter().fromJson(json['totalSales']),
      totalPaidSales: const FlexibleDoubleConverter().fromJson(
        json['totalPaidSales'],
      ),
      totalDebtSales: const FlexibleDoubleConverter().fromJson(
        json['totalDebtSales'],
      ),
      totalTransactions: (json['totalTransactions'] as num?)?.toInt() ?? 0,
      summaryProfit: const FlexibleNullableDoubleConverter().fromJson(
        json['summaryProfit'],
      ),
    );

Map<String, dynamic> _$DailySalesListModelToJson(
  DailySalesListModel instance,
) => <String, dynamic>{
  'date': const IsoDateTimeConverter().toJson(instance.date),
  'sales': instance.sales,
  'totalSales': const FlexibleDoubleConverter().toJson(instance.totalSales),
  'totalPaidSales': const FlexibleDoubleConverter().toJson(
    instance.totalPaidSales,
  ),
  'totalDebtSales': const FlexibleDoubleConverter().toJson(
    instance.totalDebtSales,
  ),
  'totalTransactions': instance.totalTransactions,
  'summaryProfit': const FlexibleNullableDoubleConverter().toJson(
    instance.summaryProfit,
  ),
};
