/// Mirror of the backend's `RegistrationRequestDto` (see
/// `MarketSystem.Application/DTOs/RegistrationRequestDTOs.cs`). Plain
/// data class — no business logic.
class RegistrationRequest {
  RegistrationRequest({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.status,
    required this.createdAt,
    this.processedAt,
    this.processedByUserName,
    this.createdUserId,
    this.createdMarketId,
    this.rejectReason,
  });

  final String id;
  final String fullName;
  final String phone;
  final String status; // "Pending" | "Approved" | "Rejected"
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? processedByUserName;
  final String? createdUserId;
  final int? createdMarketId;
  final String? rejectReason;

  bool get isPending => status == 'Pending';
  bool get isApproved => status == 'Approved';
  bool get isRejected => status == 'Rejected';

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending',
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String).toUtc()
          : null,
      processedByUserName: json['processedByUserName'] as String?,
      createdUserId: json['createdUserId'] as String?,
      createdMarketId: json['createdMarketId'] as int?,
      rejectReason: json['rejectReason'] as String?,
    );
  }
}
