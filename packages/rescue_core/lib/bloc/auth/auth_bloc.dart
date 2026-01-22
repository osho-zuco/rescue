import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../error/api_error.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../services/logger_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

/// BLoC for authentication state management
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  StreamSubscription<bool>? _authStateSubscription;

  AuthBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository,
        super(const AuthState.initial()) {
    // Register event handlers
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthOtpSendRequested>(_onOtpSendRequested);
    on<AuthOtpVerifyRequested>(_onOtpVerifyRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);

    // Listen to auth state changes from repository
    _authStateSubscription = _authRepository.isAuthenticatedStream.listen(
      (isAuthenticated) {
        // Dispatch event to check auth state
        add(const AuthCheckRequested());
      },
    );
  }

  /// Check if user is already authenticated
  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Log.i('Checking authentication status', 'AuthBloc');

      if (_authRepository.isAuthenticated) {
        // Try to get user from cache first
        final cachedUser = _userRepository.cachedUser;
        if (cachedUser != null) {
          emit(AuthState.authenticated(user: cachedUser));
          Log.i('User authenticated from cache: ${cachedUser.id}', 'AuthBloc');
          return;
        }

        // Fetch user from API
        final result = await _userRepository.getCurrentUser();
        result.when(
          ok: (user) {
            emit(AuthState.authenticated(user: user));
            Log.i('User authenticated: ${user.id}', 'AuthBloc');
          },
          err: (error) {
            Log.e('Failed to fetch user, logging out', error, null, 'AuthBloc');
            add(const AuthLogoutRequested());
          },
        );
      } else {
        emit(const AuthState.unauthenticated());
        Log.i('User not authenticated', 'AuthBloc');
      }
    } catch (e, stackTrace) {
      Log.e('Error checking auth', e, stackTrace, 'AuthBloc');
      emit(const AuthState.unauthenticated());
    }
  }

  /// Send OTP to phone number
  Future<void> _onOtpSendRequested(
    AuthOtpSendRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Log.i('Sending OTP to ${event.phone}', 'AuthBloc');
      emit(AuthState.loading(phone: event.phone));

      final result = await _authRepository.sendOtp(event.phone);

      result.when(
        ok: (_) {
          emit(AuthState.otpSent(phone: event.phone));
          Log.i('OTP sent successfully', 'AuthBloc');
        },
        err: (error) {
          emit(AuthState.error(error: error, phone: event.phone));
          Log.e('Failed to send OTP', error, null, 'AuthBloc');
        },
      );
    } catch (e, stackTrace) {
      Log.e('Error sending OTP', e, stackTrace, 'AuthBloc');
      emit(AuthState.error(
        error: ApiError.unknown,
        phone: event.phone,
      ));
    }
  }

  /// Verify OTP
  Future<void> _onOtpVerifyRequested(
    AuthOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Log.i('Verifying OTP for ${event.phone}', 'AuthBloc');
      emit(AuthState.loading(phone: event.phone));

      final result = await _authRepository.verifyOtp(event.phone, event.otp);

      result.when(
        ok: (authResponse) async {
          // Cache user data
          await _userRepository.cacheUser(authResponse.user);

          emit(AuthState.authenticated(user: authResponse.user));
          Log.i('User authenticated: ${authResponse.user.id}', 'AuthBloc');
        },
        err: (error) {
          emit(AuthState.error(error: error, phone: event.phone));
          Log.e('Failed to verify OTP', error, null, 'AuthBloc');
        },
      );
    } catch (e, stackTrace) {
      Log.e('Error verifying OTP', e, stackTrace, 'AuthBloc');
      emit(AuthState.error(
        error: ApiError.unknown,
        phone: event.phone,
      ));
    }
  }

  /// Logout user
  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Log.i('Logging out user', 'AuthBloc');

      await _authRepository.logout();
      await _userRepository.clearCache();

      emit(const AuthState.unauthenticated());
      Log.i('User logged out successfully', 'AuthBloc');
    } catch (e, stackTrace) {
      Log.e('Error logging out', e, stackTrace, 'AuthBloc');
      // Still emit unauthenticated even if there's an error
      emit(const AuthState.unauthenticated());
    }
  }

  /// Refresh auth token
  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Log.i('Refreshing auth token', 'AuthBloc');

      final result = await _authRepository.refreshToken();

      result.when(
        ok: (_) {
          Log.i('Token refreshed successfully', 'AuthBloc');
          // State remains the same, just token refreshed
        },
        err: (error) {
          Log.e('Failed to refresh token, logging out', error, null, 'AuthBloc');
          add(const AuthLogoutRequested());
        },
      );
    } catch (e, stackTrace) {
      Log.e('Error refreshing token', e, stackTrace, 'AuthBloc');
      add(const AuthLogoutRequested());
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
