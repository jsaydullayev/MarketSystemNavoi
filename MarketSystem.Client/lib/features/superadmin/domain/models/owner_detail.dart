/// Mirrors the backend's `OwnerDetailDto` (Owner + Market + live stats).
class OwnerDetail {
  OwnerDetail({
    required this.userId,
    required this.fullName,
    required this.username,
    required this.isActive,
    required this.language,
    required this.createdAt,
    required this.stats,
    this.phone,
    this.market,
  });

  final String userId;
  final String fullName;
  final String username;
  final String? phone;
  final bool isActive;
  final String language;
  final DateTime createdAt;
  final OwnerDetailMarket? market;
  final OwnerDetailStats stats;

  factory OwnerDetail.fromJson(Map<String, dynamic> json) {
    return OwnerDetail(
      userId: json['userId'] as String,
      fullName: json['fullName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      language: json['language'] as String? ?? 'uz',
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
      market: json['market'] is Map<String, dynamic>
          ? OwnerDetailMarket.fromJson(json['market'] as Map<String, dynamic>)
          : null,
      stats: json['stats'] is Map<String, dynamic>
          ? OwnerDetailStats.fromJson(json['stats'] as Map<String, dynamic>)
          : const OwnerDetailStats(),
    );
  }
}

class OwnerDetailMarket {
  OwnerDetailMarket({
    required this.id,
    required this.name,
    required this.isActive,
    required this.isBlocked,
    required this.createdAt,
    this.subdomain,
    this.description,
    this.blockedAt,
    this.blockedReason,
    this.expiresAt,
  });

  final int id;
  final String name;
  final String? subdomain;
  final String? description;
  final bool isActive;
  final bool isBlocked;
  final DateTime? blockedAt;
  final String? blockedReason;
  final DateTime? expiresAt;
  final DateTime createdAt;

  factory OwnerDetailMarket.fromJson(Map<String, dynamic> json) {
    return OwnerDetailMarket(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      subdomain: json['subdomain'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? false,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockedAt: json['blockedAt'] is String
          ? DateTime.tryParse(json['blockedAt'] as String)
          : null,
      blockedReason: json['blockedReason'] as String?,
      expiresAt: json['expiresAt'] is String
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
  }
}

class OwnerDetailStats {
  const OwnerDetailStats({
    this.productsCount = 0,
    this.salesCount = 0,
    this.customersCount = 0,
    this.cashiersCount = 0,
    this.outstandingDebt = 0,
  });

  final int productsCount;
  final int salesCount;
  final int customersCount;
  final int cashiersCount;
  final double outstandingDebt;

  factory OwnerDetailStats.fromJson(Map<String, dynamic> json) {
    return OwnerDetailStats(
      productsCount: json['productsCount'] as int? ?? 0,
      salesCount: json['salesCount'] as int? ?? 0,
      customersCount: json['customersCount'] as int? ?? 0,
      cashiersCount: json['cashiersCount'] as int? ?? 0,
      outstandingDebt: (json['outstandingDebt'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
