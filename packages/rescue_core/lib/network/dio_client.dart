import 'package:dio/dio.dart';
import '../config/env_config.dart';
import '../error/api_error.dart';
import '../error/result.dart';

/// Callback for refreshing auth tokens
/// Returns the new access token on success
typedef TokenRefreshCallback = Future<ApiResult<String>> Function();

/// Callback for logging out on auth failure
typedef LogoutCallback = Future<void> Function();

/// Dio HTTP Client wrapper
///
/// Provides:
/// - Base URL configuration
/// - Auth token injection
/// - Automatic token refresh on 401
/// - Error handling
/// - Request/response logging
class DioClient {
  late final Dio _dio;
  String? _authToken;
  TokenRefreshCallback? _tokenRefreshCallback;
  LogoutCallback? _logoutCallback;
  bool _isRefreshing = false;

  DioClient() {
    final config = EnvConfig.instance;
    _dio = Dio(
      BaseOptions(
        baseUrl: config.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(_AuthInterceptor(this));

    // Add logging in development
    if (config.environment == Environment.dev) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
        ),
      );
    }
  }

  /// Set callback for refreshing tokens (called on 401)
  void setTokenRefreshCallback(TokenRefreshCallback callback) {
    _tokenRefreshCallback = callback;
  }

  /// Set callback for logout (called when refresh fails)
  void setLogoutCallback(LogoutCallback callback) {
    _logoutCallback = callback;
  }

  /// Set auth token for requests
  void setAuthToken(String? token) {
    _authToken = token;
  }

  /// Get current auth token
  String? get authToken => _authToken;

  /// Clear auth token
  void clearAuthToken() {
    _authToken = null;
  }

  /// GET request
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.get(path, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  /// POST request
  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.post(path, data: data, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  /// PUT request
  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.put(path, data: data, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  /// PATCH request
  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.patch(path, data: data, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  /// DELETE request
  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? fromJson,
  }) async {
    return _request(
      () => _dio.delete(path, data: data, queryParameters: queryParameters),
      fromJson: fromJson,
    );
  }

  /// Execute request with error handling and automatic token refresh
  Future<ApiResult<T>> _request<T>(
    Future<Response> Function() request, {
    T Function(dynamic json)? fromJson,
    bool isRetry = false,
  }) async {
    try {
      final response = await request();
      final data = response.data;

      // Check for API error response
      if (data is Map<String, dynamic> && data['ok'] == false) {
        return Err(ApiError.fromJson(data));
      }

      // Parse successful response
      if (fromJson != null) {
        // If response has 'data' field, use that
        final responseData =
            data is Map<String, dynamic> && data.containsKey('data')
                ? data['data']
                : data;
        return Ok(fromJson(responseData));
      }

      return Ok(data as T);
    } on DioException catch (e) {
      final error = _handleDioError(e);

      // Attempt token refresh on auth errors (only once)
      if (error.isAuthError && !isRetry && _tokenRefreshCallback != null) {
        final refreshResult = await _attemptTokenRefresh();
        if (refreshResult) {
          // Retry the original request with new token
          return _request(request, fromJson: fromJson, isRetry: true);
        }
      }

      return Err(error);
    } catch (e) {
      return Err(ApiError.unknown);
    }
  }

  /// Attempt to refresh the access token
  Future<bool> _attemptTokenRefresh() async {
    if (_isRefreshing || _tokenRefreshCallback == null) {
      return false;
    }

    _isRefreshing = true;

    try {
      final result = await _tokenRefreshCallback!();

      return result.when(
        ok: (newToken) {
          _authToken = newToken;
          _isRefreshing = false;
          return true;
        },
        err: (error) async {
          _isRefreshing = false;
          // Refresh failed, logout user
          if (_logoutCallback != null) {
            await _logoutCallback!();
          }
          return false;
        },
      );
    } catch (e) {
      _isRefreshing = false;
      return false;
    }
  }

  /// Convert DioException to ApiError
  ApiError _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout;

      case DioExceptionType.connectionError:
        return ApiError.network;

      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null) {
          final data = response.data;
          if (data is Map<String, dynamic>) {
            return ApiError.fromJson(data);
          }
          return ApiError.fromStatusCode(response.statusCode ?? 500);
        }
        return ApiError.unknown;

      case DioExceptionType.cancel:
        return const ApiError(
          code: 'REQUEST_CANCELLED',
          message: 'Request was cancelled',
          httpStatus: 0,
        );

      default:
        return ApiError.unknown;
    }
  }
}

/// Auth interceptor to add token to requests
class _AuthInterceptor extends Interceptor {
  final DioClient _client;

  _AuthInterceptor(this._client);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _client.authToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
