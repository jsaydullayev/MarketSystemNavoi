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
