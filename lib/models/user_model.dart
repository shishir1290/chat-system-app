class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String? phone;
  final bool isEmailVerified;
  final DateTime? createdAt;
  bool isOnline;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.phone,
    this.isEmailVerified = false,
    this.createdAt,
    this.isOnline = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      phone: json['phone']?.toString(),
      isEmailVerified: json['is_email_verified'] == true || json['isEmailVerified'] == true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      isOnline: json['is_online'] == true || json['isOnline'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt?.toIso8601String(),
      'is_online': isOnline,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? phone,
    bool? isEmailVerified,
    DateTime? createdAt,
    bool? isOnline,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
