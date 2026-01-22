import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../error/result.dart';
import '../network/dio_client.dart';
import '../services/theme_service.dart';
import '../repositories/auth_repository.dart';
import '../repositories/merchant_repository.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup all dependencies for the app
///
/// Call this in main() before runApp()
///
/// Example:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await setupServiceLocator();
///   runApp(MyApp());
/// }
/// ```
Future<void> setupServiceLocator() async {
  // ============================================
  // External Dependencies
  // ============================================

  // SharedPreferences (async singleton)
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  // FlutterSecureStorage (singleton)
  getIt.registerSingleton<FlutterSecureStorage>(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );

  // ============================================
  // Core Services
  // ============================================

  // Theme Service (singleton - uses its own instance pattern)
  // Initialize it with SharedPreferences
  await ThemeService.instance.initialize();
  getIt.registerSingleton<ThemeService>(ThemeService.instance);

  // ============================================
  // Networking
  // ============================================

  // Dio Client (singleton)
  getIt.registerSingleton<DioClient>(DioClient());

  // ============================================
  // Repositories
  // ============================================

  // Auth Repository (lazy singleton)
  getIt.registerLazySingleton<AuthRepository>(
    () {
      final authRepo = AuthRepositoryImpl(
        dioClient: getIt<DioClient>(),
        secureStorage: getIt<FlutterSecureStorage>(),
      );

      // Wire up automatic token refresh
      final dioClient = getIt<DioClient>();
      dioClient.setTokenRefreshCallback(() async {
        final result = await authRepo.refreshToken();
        return result.when(
          ok: (tokenResponse) => Ok(tokenResponse.token),
          err: (error) => Err(error),
        );
      });
      dioClient.setLogoutCallback(() => authRepo.logout());

      return authRepo;
    },
  );

  // Merchant Repository (lazy singleton)
  getIt.registerLazySingleton<MerchantRepository>(
    () => MerchantRepositoryImpl(
      dioClient: getIt<DioClient>(),
    ),
  );

  // ============================================
  // BLoCs/Cubits will be registered as factories
  // ============================================
  // Example:
  // getIt.registerFactory<AuthBloc>(
  //   () => AuthBloc(authRepository: getIt<AuthRepository>()),
  // );
}

/// Reset all registrations (useful for testing)
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
