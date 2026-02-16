/// Market Model
/// Data transfer object for markets

class MarketModel {
  final int id;
  final String name;
  final String? subdomain;
  final String? description;
  final bool isActive;
  final DateTime? expiresAt;
  final DateTime createdAt;

  MarketModel({
    required this.id,
    required this.name,
    this.subdomain,
    this.description,
    required this.isActive,
    this.expiresAt,
    required this.createdAt,
  });

  /// Create from JSON
  factory MarketModel.fromJson(Map<String, dynamic> json) {
    return MarketModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      subdomain: json['subdomain'],
      description: json['description'],
      isActive: json['isActive'] ?? false,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subdomain': subdomain,
      'description': description,
      'isActive': isActive,
      'expiresAt': expiresAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Register Market Request Model
class RegisterMarketRequestModel {
  final String name;
  final String? subdomain;
  final String? description;
  final DateTime? expiresAt;

  RegisterMarketRequestModel({
    required this.name,
    this.subdomain,
    this.description,
    this.expiresAt,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'subdomain': subdomain,
      'description': description,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

/// Register Market Response Model
class RegisterMarketResponseModel {
  final MarketModel market;
  final UserMarketModel owner;

  RegisterMarketResponseModel({
    required this.market,
    required this.owner,
  });

  /// Create from JSON
  factory RegisterMarketResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterMarketResponseModel(
      market: MarketModel.fromJson(json['market']),
      owner: UserMarketModel.fromJson(json['owner']),
    );
  }
}

/// User Market Model (simplified user info)
class UserMarketModel {
  final String id;
  final String fullName;
  final String username;
  final String? profileImage;
  final String role;
  final String language;
  final bool isActive;
  final int? marketId;

  UserMarketModel({
    required this.id,
    required this.fullName,
    required this.username,
    this.profileImage,
    required this.role,
    required this.language,
    required this.isActive,
    this.marketId,
  });

  /// Create from JSON
  factory UserMarketModel.fromJson(Map<String, dynamic> json) {
    return UserMarketModel(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      username: json['username'] ?? '',
      profileImage: json['profileImage'],
      role: json['role'] ?? '',
      language: json['language'] ?? 'uz',
      isActive: json['isActive'] ?? false,
      marketId: json['marketId'] is int ? json['marketId'] : null,
    );
  }
}

/// Update My Market Request Model
class UpdateMyMarketRequestModel {
  final String name;
  final String? description;

  UpdateMyMarketRequestModel({
    required this.name,
    this.description,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}
