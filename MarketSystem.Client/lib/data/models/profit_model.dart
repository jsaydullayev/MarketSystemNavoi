class ProfitSummaryModel {
  final double todayProfit;
  final double weekProfit;
  final double monthProfit;
  final double totalProfit;

  ProfitSummaryModel({
    required this.todayProfit,
    required this.weekProfit,
    required this.monthProfit,
    required this.totalProfit,
  });

  factory ProfitSummaryModel.fromJson(Map<String, dynamic> json) {
    return ProfitSummaryModel(
      todayProfit: json['todayProfit'] != null
          ? (json['todayProfit'] is num
              ? (json['todayProfit'] as num).toDouble()
              : double.tryParse(json['todayProfit'].toString()) ?? 0.0)
          : 0.0,
      weekProfit: json['weekProfit'] != null
          ? (json['weekProfit'] is num
              ? (json['weekProfit'] as num).toDouble()
              : double.tryParse(json['weekProfit'].toString()) ?? 0.0)
          : 0.0,
      monthProfit: json['monthProfit'] != null
          ? (json['monthProfit'] is num
              ? (json['monthProfit'] as num).toDouble()
              : double.tryParse(json['monthProfit'].toString()) ?? 0.0)
          : 0.0,
      totalProfit: json['totalProfit'] != null
          ? (json['totalProfit'] is num
              ? (json['totalProfit'] as num).toDouble()
              : double.tryParse(json['totalProfit'].toString()) ?? 0.0)
          : 0.0,
    );
  }
}

class CashBalanceModel {
  final double cashInRegister;
  final double cardPayments;
  final double totalBalance;

  CashBalanceModel({
    required this.cashInRegister,
    required this.cardPayments,
    required this.totalBalance,
  });

  factory CashBalanceModel.fromJson(Map<String, dynamic> json) {
    return CashBalanceModel(
      cashInRegister: json['cashInRegister'] != null
          ? (json['cashInRegister'] is num
              ? (json['cashInRegister'] as num).toDouble()
              : double.tryParse(json['cashInRegister'].toString()) ?? 0.0)
          : 0.0,
      cardPayments: json['cardPayments'] != null
          ? (json['cardPayments'] is num
              ? (json['cardPayments'] as num).toDouble()
              : double.tryParse(json['cardPayments'].toString()) ?? 0.0)
          : 0.0,
      totalBalance: json['totalBalance'] != null
          ? (json['totalBalance'] is num
              ? (json['totalBalance'] as num).toDouble()
              : double.tryParse(json['totalBalance'].toString()) ?? 0.0)
          : 0.0,
    );
  }
}

class DailySalesListItemModel {
  final String id;
  final DateTime createdAt;
  final String sellerName;
  final double totalAmount;
  final String paymentType;
  final String status;
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

  factory DailySalesListItemModel.fromJson(Map<String, dynamic> json) {
    return DailySalesListItemModel(
      id: json['id'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      sellerName: json['sellerName'] ?? 'Unknown',
      totalAmount: json['totalAmount'] != null
          ? (json['totalAmount'] is num
              ? (json['totalAmount'] as num).toDouble()
              : double.tryParse(json['totalAmount'].toString()) ?? 0.0)
          : 0.0,
      paymentType: json['paymentType'] ?? 'Cash',
      status: json['status'] ?? 'Draft',
      profit: json['profit'] != null
          ? (json['profit'] is num
              ? (json['profit'] as num).toDouble()
              : double.tryParse(json['profit'].toString()))
          : null,
      customerName: json['customerName'],
    );
  }
}

class DailySalesListModel {
  final DateTime date;
  final List<DailySalesListItemModel> sales;
  final double totalSales;
  final int totalTransactions;
  final double? summaryProfit;

  DailySalesListModel({
    required this.date,
    required this.sales,
    required this.totalSales,
    required this.totalTransactions,
    this.summaryProfit,
  });

  factory DailySalesListModel.fromJson(Map<String, dynamic> json) {
    var salesList = <DailySalesListItemModel>[];
    if (json['sales'] != null) {
      salesList = (json['sales'] as List)
          .map((i) => DailySalesListItemModel.fromJson(i))
          .toList();
    }

    return DailySalesListModel(
      date: json['date'] != null
          ? (json['date'] is DateTime
              ? json['date'] as DateTime
              : DateTime.parse(json['date'].toString()))
          : DateTime.now(),
      sales: salesList,
      totalSales: json['totalSales'] != null
          ? (json['totalSales'] is num
              ? (json['totalSales'] as num).toDouble()
              : double.tryParse(json['totalSales'].toString()) ?? 0.0)
          : 0.0,
      totalTransactions: json['totalTransactions'] ?? 0,
      summaryProfit: json['summaryProfit'] != null
          ? (json['summaryProfit'] is num
              ? (json['summaryProfit'] as num).toDouble()
              : double.tryParse(json['summaryProfit'].toString()))
          : null,
    );
  }
}
