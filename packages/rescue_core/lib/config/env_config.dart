/// Environment Configuration
///
/// Manages different configurations for dev/staging/prod environments.
///
/// Secrets are passed via --dart-define flags:
/// - MIXPANEL_TOKEN_DEV → Development Mixpanel token
/// - MIXPANEL_TOKEN_STAGING → Staging Mixpanel token
/// - MIXPANEL_TOKEN_PROD → Production Mixpanel token
/// - GOOGLE_PLACES_API_KEY_ANDROID_DEV → Dev Google Places (Android)
/// - GOOGLE_PLACES_API_KEY_ANDROID_STAGING → Staging Google Places (Android)
/// - GOOGLE_PLACES_API_KEY_ANDROID_PROD → Prod Google Places (Android)
/// - GOOGLE_PLACES_API_KEY_IOS_DEV → Dev Google Places (iOS)
/// - GOOGLE_PLACES_API_KEY_IOS_STAGING → Staging Google Places (iOS)
/// - GOOGLE_PLACES_API_KEY_IOS_PROD → Prod Google Places (iOS)
///
/// How to use:
/// 1. Development (default):
///    flutter run
///
/// 2. Staging:
///    flutter run --dart-define=ENV=staging
///
/// 3. Production:
///    flutter run --release --dart-define=ENV=prod
///    flutter build apk --dart-define=ENV=prod
///
/// Access config anywhere:
///    final apiUrl = EnvConfig.instance.apiBaseUrl;

/// Available environments
enum Environment { dev, staging, prod }

/// Environment-specific configuration
class EnvConfig {
  final Environment environment;
  final String apiBaseUrl;
  final String appName;
  final bool enableLogging;
  final bool enableCrashlytics;
  final String? sentryDsn;
  final bool useFirebaseAuth;
  final String mixpanelToken;
  final String googlePlacesApiKeyAndroid;
  final String googlePlacesApiKeyIos;

  EnvConfig._({
    required this.environment,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableLogging,
    required this.enableCrashlytics,
    required this.mixpanelToken,
    required this.googlePlacesApiKeyAndroid,
    required this.googlePlacesApiKeyIos,
    this.sentryDsn,
    this.useFirebaseAuth = false,
  });

  /// Singleton instance - initialized once at app startup
  static late EnvConfig _instance;
  static EnvConfig get instance => _instance;

  /// Check if initialized (useful for tests)
  static bool get isInitialized => _isInitialized;
  static bool _isInitialized = false;

  /// Initialize from flavor or --dart-define
  ///
  /// Priority:
  /// 1. Runtime parameters (apiBaseUrl, environment) - for bootstrap pattern
  /// 2. --flavor (Flutter build flavor, auto-detected)
  /// 3. --dart-define=ENV=xxx (fallback for tests/CI)
  /// 4. Default to dev
  ///
  /// Call this in main() before runApp():
  ///   EnvConfig.initialize();
  /// Or with bootstrap pattern:
  ///   EnvConfig.initialize(apiBaseUrl: 'http://localhost:3000/api/v1', environment: 'development');
  static void initialize({String? apiBaseUrl, String? environment}) {
    if (_isInitialized) return;

    // If runtime parameters provided, use custom config
    if (apiBaseUrl != null && environment != null) {
      final env = environment == 'production'
          ? Environment.prod
          : (environment == 'staging' ? Environment.staging : Environment.dev);

      _instance = EnvConfig._(
        environment: env,
        apiBaseUrl: apiBaseUrl,
        appName: env == Environment.prod ? 'Druto' : 'Druto ${env.name}',
        enableLogging: env != Environment.prod,
        enableCrashlytics:
            env == Environment.prod || env == Environment.staging,
        sentryDsn: env == Environment.prod || env == Environment.staging
            ? 'https://ae361a5e6c076570fee38fff4e0f00c1@o4510473158000640.ingest.us.sentry.io/4510532361256960'
            : null,
        useFirebaseAuth: false,
        mixpanelToken: '',
        googlePlacesApiKeyAndroid: '',
        googlePlacesApiKeyIos: '',
      );
      _isInitialized = true;
      return;
    }

    // Flutter automatically sets this when using --flavor
    const flavor = String.fromEnvironment('FLUTTER_APP_FLAVOR');

    // Fallback to explicit ENV define (for tests or when not using flavors)
    const envOverride = String.fromEnvironment('ENV');

    // Priority: flavor > ENV > dev
    final envString = flavor.isNotEmpty
        ? flavor
        : (envOverride.isNotEmpty ? envOverride : 'dev');

    final env = Environment.values.firstWhere(
      (e) => e.name == envString,
      orElse: () => Environment.dev,
    );

    _instance = _configFor(env);
    _isInitialized = true;
  }

  /// Get config for a specific environment
  static EnvConfig _configFor(Environment env) {
    switch (env) {
      case Environment.dev:
        // Dev API URL can be overridden via --dart-define=DEV_API_URL=http://your-ip:3000/api/v1
        // Default: Android emulator uses 10.0.2.2 to reach host machine
        // For physical device: Use --dart-define=DEV_API_URL=http://YOUR_IP:3000/api/v1
        // TIP: Run `ipconfig getifaddr en0` (Mac) or `ipconfig` (Windows) to find your IP

        // For iOS Simulator: Use 'http://localhost:3000/api/v1'
        // For Android Emulator: Use 'http://10.0.2.2:3000/api/v1'
        // For Physical Device: Use 'http://YOUR_LOCAL_IP:3000/api/v1'
        const devApiUrl = 'http://192.168.0.108:8080/api/v1';

        return EnvConfig._(
          environment: Environment.dev,
          apiBaseUrl: devApiUrl,
          appName: 'Zuco Dev',
          enableLogging: true,
          enableCrashlytics: false,
          sentryDsn: null,
          useFirebaseAuth: false,
          mixpanelToken: const String.fromEnvironment(
            'MIXPANEL_TOKEN_DEV',
            defaultValue: '',
          ),
          googlePlacesApiKeyAndroid: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_ANDROID_DEV',
            defaultValue: '',
          ),
          googlePlacesApiKeyIos: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_IOS_DEV',
            defaultValue: '',
          ),
        );

      case Environment.staging:
        return EnvConfig._(
          environment: Environment.staging,
          // Staging server on Railway
          apiBaseUrl: 'https://api-staging.getzuco.com/api/v1',
          appName: 'Zuco Staging',
          enableLogging: true,
          enableCrashlytics: true, // Track staging crashes
          sentryDsn:
              'https://ae361a5e6c076570fee38fff4e0f00c1@o4510473158000640.ingest.us.sentry.io/4510532361256960',
          mixpanelToken: const String.fromEnvironment(
            'MIXPANEL_TOKEN_STAGING',
            defaultValue: '',
          ),
          googlePlacesApiKeyAndroid: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_ANDROID_STAGING',
            defaultValue: '',
          ),
          googlePlacesApiKeyIos: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_IOS_STAGING',
            defaultValue: '',
          ),
        );

      case Environment.prod:
        return EnvConfig._(
          environment: Environment.prod,
          // Production server on Railway
          apiBaseUrl: 'https://api.getzuco.com/api/v1',
          appName: 'Zuco',
          enableLogging: false, // No console logs in prod
          enableCrashlytics: true, // Track prod crashes
          sentryDsn:
              'https://ae361a5e6c076570fee38fff4e0f00c1@o4510473158000640.ingest.us.sentry.io/4510532361256960',
          mixpanelToken: const String.fromEnvironment(
            'MIXPANEL_TOKEN_PROD',
            defaultValue: '',
          ),
          googlePlacesApiKeyAndroid: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_ANDROID_PROD',
            defaultValue: '',
          ),
          googlePlacesApiKeyIos: const String.fromEnvironment(
            'GOOGLE_PLACES_API_KEY_IOS_PROD',
            defaultValue: '',
          ),
        );
    }
  }

  /// Helper getters
  bool get isDev => environment == Environment.dev;
  bool get isStaging => environment == Environment.staging;
  bool get isProd => environment == Environment.prod;

  /// For debugging - shows current environment
  @override
  String toString() {
    return 'EnvConfig(env: ${environment.name}, api: $apiBaseUrl)';
  }
}
