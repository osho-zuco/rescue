import 'api_error.dart';

/// Result Type
///
/// Functional error handling pattern - no throwing!
/// Forces explicit handling of success and failure cases.
///
/// Usage:
///   Result<User, ApiError> result = await getUser();
///   result.when(
///     ok: (user) => print('Got user: ${user.name}'),
///     err: (error) => print('Failed: ${error.message}'),
///   );

/// Sealed class representing either success (Ok) or failure (Err)
sealed class Result<T, E> {
  const Result();

  /// Pattern match on success/failure
  R when<R>({
    required R Function(T data) ok,
    required R Function(E error) err,
  });

  /// Check if result is success
  bool get isOk;

  /// Check if result is error
  bool get isErr;

  /// Get data if Ok, or null
  T? get dataOrNull;

  /// Get error if Err, or null
  E? get errorOrNull;
}

/// Success case
class Ok<T, E> extends Result<T, E> {
  final T data;
  const Ok(this.data);

  @override
  R when<R>({
    required R Function(T data) ok,
    required R Function(E error) err,
  }) =>
      ok(data);

  @override
  bool get isOk => true;

  @override
  bool get isErr => false;

  @override
  T? get dataOrNull => data;

  @override
  E? get errorOrNull => null;
}

/// Failure case
class Err<T, E> extends Result<T, E> {
  final E error;
  const Err(this.error);

  @override
  R when<R>({
    required R Function(T data) ok,
    required R Function(E error) err,
  }) =>
      err(error);

  @override
  bool get isOk => false;

  @override
  bool get isErr => true;

  @override
  T? get dataOrNull => null;

  @override
  E? get errorOrNull => error;
}


/// Type alias for API responses (Result with ApiError)
typedef ApiResult<T> = Result<T, ApiError>;
