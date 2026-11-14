class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'ADMIN', 'STAFF', 'SUPER_ADMIN'
  final String? avatar;
  final bool canViewPreviousQuotations;
  final bool canManageCatalog;
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
    this.canViewPreviousQuotations = false,
    this.canManageCatalog = false,
    this.isActive = true,
  });

  bool get isAdmin => role.toUpperCase() == 'ADMIN' || role.toUpperCase() == 'SUPER_ADMIN';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'STAFF',
      avatar: json['avatar']?.toString() ?? json['avatarUrl']?.toString(),
      canViewPreviousQuotations: json['canViewPreviousQuotations'] == true,
      canManageCatalog: json['canManageCatalog'] == true,
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar': avatar,
      'canViewPreviousQuotations': canViewPreviousQuotations,
      'canManageCatalog': canManageCatalog,
      'isActive': isActive,
    };
  }
}

