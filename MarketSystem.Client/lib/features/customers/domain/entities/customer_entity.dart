/// Customer Entity
/// Mijoz obyekti - biznes mantik uchun asosiy model

import 'package:equatable/equatable.dart';

/// Customer Entity - mijoz obyekti
class CustomerEntity extends Equatable {
  final String id;
  final String phone;
  final String? fullName;
  final String? comment;
  final double totalDebt;
  final DateTime createdAt;
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

  /// JSON dan CustomerEntity yaratish
  factory CustomerEntity.fromJson(Map<String, dynamic> json) {
    return CustomerEntity(
      id: json['id']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      fullName: json['fullName']?.toString(),
      comment: json['comment']?.toString(),
      totalDebt: json['totalDebt'] != null
          ? (json['totalDebt'] is num
              ? (json['totalDebt'] as num).toDouble()
              : double.tryParse(json['totalDebt'].toString()) ?? 0.0)
          : 0.0,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt'] as DateTime
              : DateTime.parse(json['createdAt'].toString()))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt'] as DateTime
              : DateTime.parse(json['updatedAt'].toString()))
          : null,
    );
  }

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

  /// CustomerEntity ni JSON ga aylantirish
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'fullName': fullName,
      'comment': comment,
      'totalDebt': totalDebt,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, phone, fullName, comment, totalDebt, createdAt, updatedAt];
}
