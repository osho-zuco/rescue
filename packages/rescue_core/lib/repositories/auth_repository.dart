import 'package:rxdart/rxdart.dart';

import '../error/result.dart';
import '../error/api_error.dart';
import '../models/user.dart';
import '../models/auth_response.dart';
import '../network/dio_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/logger_service.dart';

/// Auth Repository interface
abstract class AuthRepository {
  /// Send OTP to phone number
  Future<ApiResult<void>> sendOtp(String phone);

  /// Verify OTP and get auth tokens
  Future<ApiResult<AuthResponse>> verifyOtp(String phone, String otp);

  /// Refresh access token using refresh token
  Future<ApiResult<TokenResponse>> refreshToken();

  /// Logout (clear tokens)
  Future<void> logout();

  /// Get current user (if authenticated)
  User? get currentUser;

  /// Stream of authentication state
  Stream<bool> get isAuthenticatedStream;

  /// Check if user is authenticated
  bool get isAuthenticated;
}

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final DioClient _dioClient;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';

  final BehaviorSubject<bool> _authStateController =
      BehaviorSubject<bool>.seeded(false);

  User? _currentUser;

  AuthRepositoryImpl({
    required DioClient dioClient,
    required FlutterSecureStorage secureStorage,
  })  : _dioClient = dioClient,
        _secureStorage = secureStorage {
    _initializeAuth();
  }

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      if (token != null) {
        // Set token in DioClient
        _dioClient.setAuthToken(token);

        // Load user data
        final userJson = await _secureStorage.read(key: _userKey);
        if (userJson != null) {
          // Parse stored user data
          // In production, you'd parse JSON properly
          _authStateController.add(true);
        }
      }
    } catch (e, stackTrace) {
      Log.e('Failed to initialize auth', e, stackTrace, 'AuthRepository');
    }
  }

  @override
  Future<ApiResult<void>> sendOtp(String phone) async {
    try {
      final result = await _dioClient.post<void>(
        '/auth/otp/send',
        data: {'phone': phone},
      );

      return result.when(
        ok: (_) {
          Log.i('OTP sent to $phone', 'AuthRepository');
          return Ok(null);
        },
        err: (error) {
          Log.e('Failed to send OTP', error, null, 'AuthRepository');
          return Err(error);
        },
      );
    } catch (e, stackTrace) {
      Log.e('Failed to send OTP', e, stackTrace, 'AuthRepository');
      return Err(ApiError.unknown);
    }
  }

  @override
  Future<ApiResult<AuthResponse>> verifyOtp(String phone, String otp) async {
    try {
      final result = await _dioClient.post<AuthResponse>(
        '/auth/otp/verify',
        data: {'phone': phone, 'otp': otp},
        fromJson: (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
      );

      return result.when(
        ok: (authResponse) async {
          // Store tokens securely
          await _secureStorage.write(
            key: _tokenKey,
            value: authResponse.token,
          );
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: authResponse.refreshToken,
          );

          // Store user data
          await _secureStorage.write(
            key: _userKey,
            value: authResponse.user.toJson().toString(),
          );

          // Set token in DioClient
          _dioClient.setAuthToken(authResponse.token);

          // Update state
          _currentUser = authResponse.user;
          _authStateController.add(true);

          Log.i('User authenticated: ${authResponse.user.id}', 'AuthRepository');

          return Ok(authResponse);
        },
        err: (error) {
          Log.e('Failed to verify OTP', error, null, 'AuthRepository');
          return Err(error);
        },
      );
    } catch (e, stackTrace) {
      Log.e('Failed to verify OTP', e, stackTrace, 'AuthRepository');
      return Err(ApiError.unknown);
    }
  }

  @override
  Future<ApiResult<TokenResponse>> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);

      if (refreshToken == null) {
        return const Err(ApiError(
          code: 'NO_REFRESH_TOKEN',
          message: 'No refresh token available',
          httpStatus: 401,
        ));
      }

      final result = await _dioClient.post<TokenResponse>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
        fromJson: (json) => TokenResponse.fromJson(json as Map<String, dynamic>),
      );

      return result.when(
        ok: (tokenResponse) async {
          // Store new tokens
          await _secureStorage.write(
            key: _tokenKey,
            value: tokenResponse.token,
          );
          await _secureStorage.write(
            key: _refreshTokenKey,
            value: tokenResponse.refreshToken,
          );

          // Update DioClient token
          _dioClient.setAuthToken(tokenResponse.token);

          Log.i('Token refreshed successfully', 'AuthRepository');

          return Ok(tokenResponse);
        },
        err: (error) async {
          Log.e('Failed to refresh token', error, null, 'AuthRepository');
          // If refresh fails, logout user
          await logout();
          return Err(error);
        },
      );
    } catch (e, stackTrace) {
      Log.e('Failed to refresh token', e, stackTrace, 'AuthRepository');
      return Err(ApiError.unknown);
    }
  }

  @override
  Future<void> logout() async {
    try {
      // Clear stored tokens
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _secureStorage.delete(key: _userKey);

      // Clear DioClient token
      _dioClient.clearAuthToken();

      // Update state
      _currentUser = null;
      _authStateController.add(false);

      Log.i('User logged out', 'AuthRepository');
    } catch (e, stackTrace) {
      Log.e('Failed to logout', e, stackTrace, 'AuthRepository');
    }
  }

  @override
  User? get currentUser => _currentUser;

  @override
  Stream<bool> get isAuthenticatedStream => _authStateController.stream;

  @override
  bool get isAuthenticated => _authStateController.value;

  /// Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
