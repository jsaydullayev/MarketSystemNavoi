// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cash_register_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CashRegisterModel _$CashRegisterModelFromJson(Map<String, dynamic> json) =>
    CashRegisterModel(
      id: json['id'] as String,
      currentBalance: const FlexibleDoubleConverter().fromJson(
        json['currentBalance'],
      ),
      lastUpdated: const IsoDateTimeConverter().fromJson(json['lastUpdated']),
      withdrawals:
          (json['withdrawals'] as List<dynamic>?)
              ?.map(
                (e) => CashWithdrawalModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$CashRegisterModelToJson(CashRegisterModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'currentBalance': const FlexibleDoubleConverter().toJson(
        instance.currentBalance,
      ),
      'lastUpdated': const IsoDateTimeConverter().toJson(instance.lastUpdated),
      'withdrawals': instance.withdrawals,
    };

CashWithdrawalModel _$CashWithdrawalModelFromJson(Map<String, dynamic> json) =>
    CashWithdrawalModel(
      id: json['id'] as String,
      amount: const FlexibleDoubleConverter().fromJson(json['amount']),
      comment: json['comment'] as String,
      withdrawalDate: const IsoDateTimeConverter().fromJson(
        json['withdrawalDate'],
      ),
      userName: json['userName'] as String?,
    );

Map<String, dynamic> _$CashWithdrawalModelToJson(
  CashWithdrawalModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'amount': const FlexibleDoubleConverter().toJson(instance.amount),
  'comment': instance.comment,
  'withdrawalDate': const IsoDateTimeConverter().toJson(
    instance.withdrawalDate,
  ),
  'userName': instance.userName,
};

TodaySalesSummaryModel _$TodaySalesSummaryModelFromJson(
  Map<String, dynamic> json,
) => TodaySalesSummaryModel(
  totalSales: (json['totalSales'] as num).toInt(),
  totalAmount: const FlexibleDoubleConverter().fromJson(json['totalAmount']),
  totalPaid: const FlexibleDoubleConverter().fromJson(json['totalPaid']),
  cashPaid: const FlexibleDoubleConverter().fromJson(json['cashPaid']),
  cardPaid: const FlexibleDoubleConverter().fromJson(json['cardPaid']),
  clickPaid: const FlexibleDoubleConverter().fromJson(json['clickPaid']),
  debtAmount: const FlexibleDoubleConverter().fromJson(json['debtAmount']),
  date: const IsoDateTimeConverter().fromJson(json['date']),
);

Map<String, dynamic> _$TodaySalesSummaryModelToJson(
  TodaySalesSummaryModel instance,
) => <String, dynamic>{
  'totalSales': instance.totalSales,
  'totalAmount': const FlexibleDoubleConverter().toJson(instance.totalAmount),
  'totalPaid': const FlexibleDoubleConverter().toJson(instance.totalPaid),
  'cashPaid': const FlexibleDoubleConverter().toJson(instance.cashPaid),
  'cardPaid': const FlexibleDoubleConverter().toJson(instance.cardPaid),
  'clickPaid': const FlexibleDoubleConverter().toJson(instance.clickPaid),
  'debtAmount': const FlexibleDoubleConverter().toJson(instance.debtAmount),
  'date': const IsoDateTimeConverter().toJson(instance.date),
};
