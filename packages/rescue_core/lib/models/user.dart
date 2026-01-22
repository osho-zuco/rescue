import 'package:equatable/equatable.dart';

/// User roles in the Druto platform
enum UserRole {
  customer('CUSTOMER'),
  merchantOwner('MERCHANT_OWNER'),
  admin('ADMIN');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }
}

/// User model
class User extends Equatable {
  final String id;
  final String phone;
  final String? name;
  final String? profilePhotoUrl;
  final UserRole role;

  const User({
    required this.id,
    required this.phone,
    this.name,
    this.profilePhotoUrl,
    required this.role,
  });

  /// Create from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String?,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      role: UserRole.fromString(json['role'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'profilePhotoUrl': profilePhotoUrl,
      'role': role.value,
    };
  }

  /// Create copy with updated fields
  User copyWith({
    String? id,
    String? phone,
    String? name,
    String? profilePhotoUrl,
    UserRole? role,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, phone, name, profilePhotoUrl, role];
}
