class CashRegisterModel {
  final String id;
  final double currentBalance;
  final DateTime lastUpdated;
  final List<CashWithdrawalModel> withdrawals;

  CashRegisterModel({
    required this.id,
    required this.currentBalance,
    required this.lastUpdated,
    required this.withdrawals,
  });

  factory CashRegisterModel.fromJson(Map<String, dynamic> json) {
    var withdrawalsList = <CashWithdrawalModel>[];
    if (json['withdrawals'] != null) {
      withdrawalsList = (json['withdrawals'] as List)
          .map((i) => CashWithdrawalModel.fromJson(i))
          .toList();
    }

    return CashRegisterModel(
      id: json['id'] ?? '',
      currentBalance: (json['currentBalance'] ?? 0).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      withdrawals: withdrawalsList,
    );
  }
}

class CashWithdrawalModel {
  final String id;
  final double amount;
  final String comment;
  final DateTime withdrawalDate;
  final String? userName;

  CashWithdrawalModel({
    required this.id,
    required this.amount,
    required this.comment,
    required this.withdrawalDate,
    this.userName,
  });

  factory CashWithdrawalModel.fromJson(Map<String, dynamic> json) {
    return CashWithdrawalModel(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      comment: json['comment'] ?? '',
      withdrawalDate: DateTime.parse(json['withdrawalDate'] ?? DateTime.now().toIso8601String()),
      userName: json['userName'],
    );
  }
}

class TodaySalesSummaryModel {
  final int totalSales;
  final double totalAmount;
  final double totalPaid;
  final double cashPaid;
  final double cardPaid;
  final DateTime date;

  TodaySalesSummaryModel({
    required this.totalSales,
    required this.totalAmount,
    required this.totalPaid,
    required this.cashPaid,
    required this.cardPaid,
    required this.date,
  });

  factory TodaySalesSummaryModel.fromJson(Map<String, dynamic> json) {
    return TodaySalesSummaryModel(
      totalSales: json['totalSales'] ?? 0,
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] is num
              ? (json['totalAmount'] as num).toDouble()
              : double.tryParse(json['totalAmount'].toString()) ?? 0.0)
          : 0.0,
      totalPaid: json['totalPaid'] != null
          ? (json['totalPaid'] is num
              ? (json['totalPaid'] as num).toDouble()
              : double.tryParse(json['totalPaid'].toString()) ?? 0.0)
          : 0.0,
      cashPaid: json['cashPaid'] != null
          ? (json['cashPaid'] is num
              ? (json['cashPaid'] as num).toDouble()
              : double.tryParse(json['cashPaid'].toString()) ?? 0.0)
          : 0.0,
      cardPaid: json['cardPaid'] != null
          ? (json['cardPaid'] is num
              ? (json['cardPaid'] as num).toDouble()
              : double.tryParse(json['cardPaid'].toString()) ?? 0.0)
          : 0.0,
      date: json['date'] != null
          ? (json['date'] is DateTime
              ? json['date'] as DateTime
              : DateTime.parse(json['date'].toString()))
          : DateTime.now(),
    );
  }
}
