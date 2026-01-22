import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../error/result.dart';
import '../error/api_error.dart';
import '../models/user.dart';
import '../network/dio_client.dart';
import '../services/logger_service.dart';

/// User Repository interface
abstract class UserRepository {
  /// Get current user from cache
  User? get cachedUser;

  /// Fetch current user from API
  Future<ApiResult<User>> getCurrentUser();

  /// Update user profile
  Future<ApiResult<User>> updateProfile({
    String? name,
    String? profilePhotoUrl,
  });

  /// Cache user data locally
  Future<void> cacheUser(User user);

  /// Clear cached user data
  Future<void> clearCache();
}

/// Implementation of UserRepository
class UserRepositoryImpl implements UserRepository {
  final DioClient _dioClient;
  final SharedPreferences _sharedPreferences;

  static const String _userCacheKey = 'cached_user';

  User? _cachedUser;

  UserRepositoryImpl({
    required DioClient dioClient,
    required SharedPreferences sharedPreferences,
  })  : _dioClient = dioClient,
        _sharedPreferences = sharedPreferences {
    _loadCachedUser();
  }

  /// Load cached user on initialization
  void _loadCachedUser() {
    try {
      final userJson = _sharedPreferences.getString(_userCacheKey);
      if (userJson != null) {
        final userMap = json.decode(userJson) as Map<String, dynamic>;
        _cachedUser = User.fromJson(userMap);
        Log.i('Loaded cached user: ${_cachedUser?.id}', 'UserRepository');
      }
    } catch (e, stackTrace) {
      Log.e('Failed to load cached user', e, stackTrace, 'UserRepository');
    }
  }

  @override
  User? get cachedUser => _cachedUser;

  @override
  Future<ApiResult<User>> getCurrentUser() async {
    try {
      final result = await _dioClient.get<Map<String, dynamic>>('/users/me');

      return result.when(
        ok: (data) async {
          final user = User.fromJson(data);
          await cacheUser(user);
          Log.i('Fetched current user: ${user.id}', 'UserRepository');
          return Ok(user);
        },
        err: (error) {
          Log.e('Failed to fetch current user', error, null, 'UserRepository');
          return Err(error);
        },
      );
    } catch (e, stackTrace) {
      Log.e('Failed to fetch current user', e, stackTrace, 'UserRepository');
      return Err(ApiError.unknown);
    }
  }

  @override
  Future<ApiResult<User>> updateProfile({
    String? name,
    String? profilePhotoUrl,
  }) async {
    try {
      // Build request data
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (profilePhotoUrl != null) data['profilePhotoUrl'] = profilePhotoUrl;

      final result = await _dioClient.patch<Map<String, dynamic>>(
        '/users/me',
        data: data,
      );

      return result.when(
        ok: (responseData) async {
          final user = User.fromJson(responseData);
          await cacheUser(user);
          Log.i('Updated user profile: ${user.id}', 'UserRepository');
          return Ok(user);
        },
        err: (error) {
          Log.e('Failed to update profile', error, null, 'UserRepository');
          return Err(error);
        },
      );
    } catch (e, stackTrace) {
      Log.e('Failed to update profile', e, stackTrace, 'UserRepository');
      return Err(ApiError.unknown);
    }
  }

  @override
  Future<void> cacheUser(User user) async {
    try {
      _cachedUser = user;
      final userJson = json.encode(user.toJson());
      await _sharedPreferences.setString(_userCacheKey, userJson);
      Log.i('Cached user data: ${user.id}', 'UserRepository');
    } catch (e, stackTrace) {
      Log.e('Failed to cache user', e, stackTrace, 'UserRepository');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      _cachedUser = null;
      await _sharedPreferences.remove(_userCacheKey);
      Log.i('Cleared user cache', 'UserRepository');
    } catch (e, stackTrace) {
      Log.e('Failed to clear user cache', e, stackTrace, 'UserRepository');
    }
  }
}
