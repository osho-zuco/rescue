/// API Error class for handling backend errors
///
/// Mirrors the error structure from the backend.
/// Use with Result pattern for clean error handling.
class ApiError {
  final String code;
  final String message;
  final int httpStatus;
  final bool retryable;
  final Map<String, dynamic>? details;

  const ApiError({
    required this.code,
    required this.message,
    required this.httpStatus,
    this.retryable = false,
    this.details,
  });

  /// Parse from JSON response
  /// Handles both 'message' and 'error' fields from backend
  factory ApiError.fromJson(Map<String, dynamic> json) {
    // Backend may send 'error' or 'message' for the error message
    final errorMessage = json['message'] as String? ??
        json['error'] as String? ??
        'An unknown error occurred';

    return ApiError(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: errorMessage,
      httpStatus: json['httpStatus'] as int? ?? 500,
      retryable: json['retryable'] as bool? ?? false,
      details: json['details'] as Map<String, dynamic>?,
    );
  }

  /// Create from HTTP status code (fallback)
  factory ApiError.fromStatusCode(int statusCode, [String? message]) {
    switch (statusCode) {
      case 400:
        return ApiError(
          code: 'BAD_REQUEST',
          message: message ?? 'Invalid request',
          httpStatus: 400,
        );
      case 401:
        return ApiError(
          code: 'UNAUTHORIZED',
          message: message ?? 'Please log in to continue',
          httpStatus: 401,
        );
      case 403:
        return ApiError(
          code: 'FORBIDDEN',
          message: message ?? 'You do not have permission',
          httpStatus: 403,
        );
      case 404:
        return ApiError(
          code: 'NOT_FOUND',
          message: message ?? 'Resource not found',
          httpStatus: 404,
        );
      case 429:
        return ApiError(
          code: 'RATE_LIMITED',
          message: message ?? 'Too many requests. Please try again later.',
          httpStatus: 429,
          retryable: true,
        );
      case 500:
        return ApiError(
          code: 'SERVER_ERROR',
          message: message ?? 'Server error. Please try again.',
          httpStatus: 500,
          retryable: true,
        );
      case 503:
        return ApiError(
          code: 'SERVICE_UNAVAILABLE',
          message: message ?? 'Service unavailable. Please try again.',
          httpStatus: 503,
          retryable: true,
        );
      default:
        return ApiError(
          code: 'HTTP_ERROR',
          message: message ?? 'An error occurred',
          httpStatus: statusCode,
        );
    }
  }

  /// Network/connection error
  static const ApiError network = ApiError(
    code: 'NETWORK_ERROR',
    message: 'Network error. Please check your connection.',
    httpStatus: 0,
    retryable: true,
  );

  /// Timeout error
  static const ApiError timeout = ApiError(
    code: 'TIMEOUT',
    message: 'Request timed out. Please try again.',
    httpStatus: 0,
    retryable: true,
  );

  /// Unknown error
  static const ApiError unknown = ApiError(
    code: 'UNKNOWN_ERROR',
    message: 'An unexpected error occurred.',
    httpStatus: 0,
  );

  /// Check if error is authentication related
  bool get isAuthError => httpStatus == 401 || code == 'AUTH_TOKEN_EXPIRED';

  /// Check if user should retry
  bool get shouldRetry => retryable;

  @override
  String toString() => 'ApiError(code: $code, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApiError &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          httpStatus == other.httpStatus;

  @override
  int get hashCode => code.hashCode ^ httpStatus.hashCode;
}
