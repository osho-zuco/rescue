import 'package:equatable/equatable.dart';
import '../../models/user.dart';
import '../../error/api_error.dart';

/// Auth state
class AuthState extends Equatable {
  /// Current authentication status
  final AuthStatus status;

  /// Current authenticated user (null if not authenticated)
  final User? user;

  /// Error message if any
  final ApiError? error;

  /// Phone number being used for auth
  final String? phone;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.phone,
  });

  /// Initial state
  const AuthState.initial()
      : status = AuthStatus.initial,
        user = null,
        error = null,
        phone = null;

  /// Loading state
  const AuthState.loading({String? phone})
      : status = AuthStatus.loading,
        user = null,
        error = null,
        phone = phone;

  /// OTP sent state
  const AuthState.otpSent({required String phone})
      : status = AuthStatus.otpSent,
        user = null,
        error = null,
        phone = phone;

  /// Authenticated state
  const AuthState.authenticated({required User user})
      : status = AuthStatus.authenticated,
        user = user,
        error = null,
        phone = null;

  /// Unauthenticated state
  const AuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        error = null,
        phone = null;

  /// Error state
  const AuthState.error({
    required ApiError error,
    String? phone,
  })  : status = AuthStatus.error,
        user = null,
        error = error,
        phone = phone;

  /// Copy with new values
  AuthState copyWith({
    AuthStatus? status,
    User? user,
    ApiError? error,
    String? phone,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error ?? this.error,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [status, user, error, phone];
}

/// Authentication status
enum AuthStatus {
  /// Initial state - checking authentication
  initial,

  /// Loading - processing auth request
  loading,

  /// OTP sent successfully
  otpSent,

  /// User is authenticated
  authenticated,

  /// User is not authenticated
  unauthenticated,

  /// Error occurred
  error,
}
