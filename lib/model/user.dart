/// Model đại diện cho thông tin người dùng
class User {
  final String id;
  final String fullName;
  final String email;
  final String? avatar;
  final String? bio;
  final String authProvider; // 'local' hoặc 'google'
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Thống kê của user (optional - có thể null nếu không load)
  final UserStats? stats;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.avatar,
    this.bio,
    required this.authProvider,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
    this.stats,
  });

  /// Chuyển đổi từ JSON sang đối tượng User
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      bio: json['bio'],
      authProvider: json['authProvider'] ?? 'local',
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      stats: null, // Stats được load riêng
    );
  }

  /// Chuyển đổi từ đối tượng User sang JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'avatar': avatar,
      'bio': bio,
      'authProvider': authProvider,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Tạo bản sao của User với một số trường được cập nhật
  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? avatar,
    String? bio,
    String? authProvider,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      authProvider: authProvider ?? this.authProvider,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stats: stats ?? this.stats,
    );
  }
}

/// Model nhỏ cho thống kê user (nằm trong User)
class UserStats {
  final int totalRecipes;
  final int totalCollections;
  final int totalFavorites;

  UserStats({
    required this.totalRecipes,
    required this.totalCollections,
    required this.totalFavorites,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRecipes: json['totalRecipes'] ?? 0,
      totalCollections: json['totalCollections'] ?? 0,
      totalFavorites: json['totalFavorites'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalRecipes': totalRecipes,
      'totalCollections': totalCollections,
      'totalFavorites': totalFavorites,
    };
  }
}