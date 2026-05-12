/// Mirror of the backend's `OwnerSummaryDto`.
class OwnerSummary {
  OwnerSummary({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.isActive,
    required this.createdAt,
    this.phone,
    this.marketId,
    this.marketName,
  });

  final String userId;
  final String fullName;
  final String username;
  final String? phone;
  final bool isActive;
  final int? marketId;
  final String? marketName;
  final DateTime createdAt;

  factory OwnerSummary.fromJson(Map<String, dynamic> json) {
    return OwnerSummary(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      marketId: json['marketId'] as int?,
      marketName: json['marketName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }
}
