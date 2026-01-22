import 'package:equatable/equatable.dart';
import 'user.dart';

/// Response from OTP verification
class AuthResponse extends Equatable {
  final String token;
  final String refreshToken;
  final User user;
  final bool isNewUser;

  const AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
    required this.isNewUser,
  });

  /// Create from JSON
  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken, user, isNewUser];
}

/// Response from token refresh
class TokenResponse extends Equatable {
  final String token;
  final String refreshToken;

  const TokenResponse({
    required this.token,
    required this.refreshToken,
  });

  /// Create from JSON
  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  @override
  List<Object?> get props => [token, refreshToken];
}
