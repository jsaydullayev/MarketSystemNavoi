/// Bitta qarzdorning yig'ma ko'rsatkichlari — `GET /Debts/customer/{id}/summary`.
///
/// Bitta mijoz bir necha marta qarz olishi mumkin, shuning uchun qarzdor
/// kartasiga bosilganda uchta raqam kerak: jami qarz, oxirgi (hozirgi) olingan
/// qarz va oxirgi to'lov. Backend'da aynan shu raqamlar PDF hisobotga ham
/// chiziladi (`CustomerDebtSummaryBuilder`), shuning uchun ekran va PDF hech
/// qachon farq qilmaydi.
///
/// Qo'lda yozilgan `fromJson` — json_serializable codegen'i shart emas, model
/// kichik va build_runner'ni ishga tushirishga arzimaydi.
class CustomerDebtSummary {
  const CustomerDebtSummary({
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.totalDebt,
    required this.totalOriginalDebt,
    required this.totalPaid,
    required this.openDebtCount,
    required this.lastDebtAmount,
    required this.lastDebtRemaining,
    this.lastDebtDate,
    required this.lastPaymentAmount,
    this.lastPaymentType,
    this.lastPaymentDate,
    this.oldestDebtDate,
    this.recentPayments = const [],
  });

  final String customerId;
  final String? customerName;
  final String? customerPhone;

  /// Jami qoldiq qarz — barcha ochiq qarzlar bo'yicha.
  final double totalDebt;

  /// Ochiq qarzlarning boshlang'ich summalari yig'indisi.
  final double totalOriginalDebt;

  /// Ochiq qarzlar bo'yicha to'langan summa.
  final double totalPaid;

  final int openDebtCount;

  /// Oxirgi (hozirgi) olingan qarzning boshlang'ich summasi.
  final double lastDebtAmount;

  /// Oxirgi olingan qarzning hozirgi qoldig'i.
  final double lastDebtRemaining;

  final DateTime? lastDebtDate;

  /// Oxirgi marta qarzga to'langan summa. To'lov bo'lmagan bo'lsa 0.
  final double lastPaymentAmount;

  /// Backend enum nomi: Cash / Terminal / Transfer / Click / Credit.
  final String? lastPaymentType;

  final DateTime? lastPaymentDate;
  final DateTime? oldestDebtDate;

  final List<DebtPaymentEntry> recentPayments;

  bool get hasPayment => lastPaymentDate != null;

  static double _toDouble(dynamic v) =>
      v == null ? 0 : (v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0);

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory CustomerDebtSummary.fromJson(Map<String, dynamic> json) {
    final rawPayments = json['recentPayments'];
    return CustomerDebtSummary(
      customerId: json['customerId']?.toString() ?? '',
      customerName: json['customerName']?.toString(),
      customerPhone: json['customerPhone']?.toString(),
      totalDebt: _toDouble(json['totalDebt']),
      totalOriginalDebt: _toDouble(json['totalOriginalDebt']),
      totalPaid: _toDouble(json['totalPaid']),
      openDebtCount: (json['openDebtCount'] as num?)?.toInt() ?? 0,
      lastDebtAmount: _toDouble(json['lastDebtAmount']),
      lastDebtRemaining: _toDouble(json['lastDebtRemaining']),
      lastDebtDate: _toDate(json['lastDebtDate']),
      lastPaymentAmount: _toDouble(json['lastPaymentAmount']),
      lastPaymentType: json['lastPaymentType']?.toString(),
      lastPaymentDate: _toDate(json['lastPaymentDate']),
      oldestDebtDate: _toDate(json['oldestDebtDate']),
      recentPayments: rawPayments is List
          ? rawPayments
                .whereType<Map>()
                .map((e) => DebtPaymentEntry.fromJson(Map<String, dynamic>.from(e)))
                .toList()
          : const [],
    );
  }
}

/// Qarz hisobiga tushgan bitta to'lov.
class DebtPaymentEntry {
  const DebtPaymentEntry({
    required this.id,
    required this.saleId,
    required this.amount,
    required this.paymentType,
    this.createdAt,
  });

  final String id;
  final String saleId;
  final double amount;
  final String paymentType;
  final DateTime? createdAt;

  factory DebtPaymentEntry.fromJson(Map<String, dynamic> json) => DebtPaymentEntry(
    id: json['id']?.toString() ?? '',
    saleId: json['saleId']?.toString() ?? '',
    amount: CustomerDebtSummary._toDouble(json['amount']),
    paymentType: json['paymentType']?.toString() ?? '',
    createdAt: CustomerDebtSummary._toDate(json['createdAt']),
  );
}
