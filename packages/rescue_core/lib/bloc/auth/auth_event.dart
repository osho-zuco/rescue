import 'package:equatable/equatable.dart';

/// Base class for Auth events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Event to check if user is already authenticated
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Event to send OTP to phone number
class AuthOtpSendRequested extends AuthEvent {
  final String phone;

  const AuthOtpSendRequested({required this.phone});

  @override
  List<Object?> get props => [phone];
}

/// Event to verify OTP
class AuthOtpVerifyRequested extends AuthEvent {
  final String phone;
  final String otp;

  const AuthOtpVerifyRequested({
    required this.phone,
    required this.otp,
  });

  @override
  List<Object?> get props => [phone, otp];
}

/// Event to logout user
class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// Event to refresh auth token
class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}
