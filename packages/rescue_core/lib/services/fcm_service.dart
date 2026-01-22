/// FCM Service
///
/// Handles Firebase Cloud Messaging for push notifications.
///
/// Features:
/// - Request notification permissions (strategic timing)
/// - Handle foreground/background notifications
/// - Suppress notifications when user is on relevant chat screen
/// - Update FCM token on server
///
/// Permission Strategy (balances marketing & UX):
/// Primary: Auto-request on 2nd app open (after auth)
///   * User has seen app's value but hasn't necessarily booked
///   * Enables promotional notifications, re-engagement campaigns
///   * Not asking on first impression (better grant rate)
///   * Tracked in SharedPreferences to ask only once
///
/// Fallback: Just-in-time request during booking flow
///   * If user denied on 2nd open, booking flow can ask again
///   * When entering booking detail/chat (high value context)
///
/// iOS Notification Behavior:
/// 1. Background/terminated: iOS shows notification automatically from APNs payload
/// 2. Foreground + on chat screen: Suppress notification, trigger chat refresh
/// 3. Foreground + other screen: Show local notification manually
///
/// Usage:
/// ```dart
/// final fcm = getIt<FcmService>();
/// await fcm.initialize();
/// await fcm.requestPermission(); // Auto-called on 2nd open, or manually when needed
/// ```

import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../di/service_locator.dart';
import 'analytics/i_analytics_service.dart';
import 'logger.dart';

/// Callback type for handling notification taps
typedef OnNotificationTap = void Function(Map<String, dynamic> data);

/// Callback type for handling new messages while on chat screen
typedef OnChatMessage = void Function(String bookingId);

class FcmService {
  static const String _tag = 'FcmService';

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Stream controller for FCM token changes
  final _tokenController = StreamController<String>.broadcast();
  Stream<String> get tokenStream => _tokenController.stream;

  /// Stream controller for chat message events (for screens to subscribe)
  final _chatMessageController = StreamController<String>.broadcast();
  Stream<String> get chatMessageStream => _chatMessageController.stream;

  /// Stream for foreground notifications (for showing in-app banner)
  final _foregroundNotificationController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get foregroundNotificationStream => _foregroundNotificationController.stream;

  /// Current FCM token
  String? _currentToken;
  String? get currentToken => _currentToken;

  /// Callback when user taps a notification
  OnNotificationTap? onNotificationTap;

  /// Callback when chat message received (for refreshing chat)
  /// @deprecated Use chatMessageStream instead for more reliable delivery
  OnChatMessage? onChatMessage;

  /// Currently viewing booking ID (to suppress notifications)
  String? _activeBookingId;
  String? get activeBookingId => _activeBookingId;

  /// Track if we've already handled the initial message (prevents duplicate navigation)
  String? _handledInitialMessageId;

  /// Whether local notifications have been initialized
  bool _localNotificationsInitialized = false;

  /// Completer for the in-progress permission request (to share result with concurrent callers)
  /// If null or completed, no request is in progress. Otherwise, wait on this completer.
  Completer<bool>? _permissionRequestCompleter;

  /// Set the active booking ID (call when entering chat screen)
  void setActiveBooking(String? bookingId) {
    _activeBookingId = bookingId;
    Log.d('Active booking set: $bookingId', tag: _tag);
  }

  /// Check and log notification permission status (for debugging)
  Future<void> checkPermissions() async {
    try {
      // Check FCM permissions
      final settings = await _messaging.getNotificationSettings();
      Log.d(
        'FCM permissions - authorization: ${settings.authorizationStatus.name}, '
        'alert: ${settings.alert}, sound: ${settings.sound}, badge: ${settings.badge}',
        tag: _tag,
      );

      // On iOS, also check local notification permissions
      if (Platform.isIOS) {
        final iosPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>();
        
        if (iosPlugin != null) {
          final granted = await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
          Log.d('iOS local notifications permission: $granted', tag: _tag);
        }
      }
    } catch (e) {
      Log.w('Failed to check permissions: $e', tag: _tag);
    }
  }

  /// Initialize FCM service
  Future<void> initialize() async {
    Log.d('Initializing FCM service', tag: _tag);

    // Initialize local notifications (for foreground display)
    await _initLocalNotifications();

    // Configure iOS foreground notification behavior
    // alert: false = Don't show banner (we'll use in-app UI instead)
    // sound: false = Don't auto-play sound (we decide in onMessage handler)
    // badge: true = Update app badge
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false, // No system banner - we'll show in-app
        badge: true,  // Update badge count
        sound: false, // No auto-sound - we'll play conditionally
      );
      Log.d('iOS foreground: sound=false, alert=false (manual control)', tag: _tag);
    }

    // On iOS, proactively get APNS token (required for FCM token)
    if (Platform.isIOS) {
      try {
        // Request APNS token early (non-blocking)
        _messaging.getAPNSToken().then((apnsToken) {
          if (apnsToken != null) {
            Log.d(
              'APNS token initialized: ${apnsToken.substring(0, 10)}...',
              tag: _tag,
            );
          } else {
            Log.d(
              'APNS token not yet available (will retry when needed)',
              tag: _tag,
            );
          }
        }).catchError((e) {
          Log.w(
            'Failed to get APNS token during init (non-fatal): $e',
            tag: _tag,
          );
        });
      } catch (e) {
        Log.w(
          'Error requesting APNS token during init (non-fatal): $e',
          tag: _tag,
        );
      }
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      Log.d('FCM token refreshed', tag: _tag);
      _currentToken = token;
      _tokenController.add(token);
    });

    // Handle foreground messages - this is where we decide to show/suppress
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Check for initial message (app launched from terminated state)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Log.d('App launched from notification', tag: _tag);
      _handledInitialMessageId = initialMessage.messageId;
      // Small delay to let router initialize before navigating
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage, source: 'terminated');
      });
    }

    // Handle background message taps (app was in background)
    // Skip if this is the initial message we just handled above
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      if (message.messageId == _handledInitialMessageId) {
        Log.d('Skipping duplicate initial message', tag: _tag);
        return;
      }
      _handleNotificationTap(message, source: 'background');
    });

    // Check and log permissions for debugging
    checkPermissions();

    Log.i('FCM service initialized', tag: _tag);
  }

  /// Initialize local notifications plugin
  Future<void> _initLocalNotifications() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS: Don't request permission here - FCM requestPermission() handles it
      // The flutter_local_notifications package shares permission with FCM on iOS
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        // Important: These need to match what we want for foreground display
        defaultPresentAlert: true,
        defaultPresentBadge: true,
        defaultPresentSound: true,
      );

      const settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {
          Log.d('Local notification tapped: ${response.notificationResponseType}', tag: _tag);
          final payload = response.payload;
          if (payload != null) {
            _handleLocalNotificationTap(payload);
          }
        },
      );

      // On some platforms, initialize() returns null but succeeds
      // We'll assume success unless we catch an error
      _localNotificationsInitialized = initialized ?? true;
      Log.i('Local notifications initialized: $_localNotificationsInitialized', tag: _tag);

      // Create notification channel for Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'app_notifications', // id
          'App Notifications', // name
          description: 'Notifications for app updates',
          importance: Importance.high,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        
        Log.d('Android notification channel created', tag: _tag);
      }
    } catch (e, stackTrace) {
      Log.e('Failed to initialize local notifications', tag: _tag, error: e, stackTrace: stackTrace);
      // Still mark as initialized - we'll try to show notifications anyway
      _localNotificationsInitialized = true;
    }
  }

  /// Request notification permissions
  ///
  /// Call this just-in-time (e.g., after first booking confirmed)
  /// Returns true if granted
  /// 
  /// Thread-safe: If a request is already in progress, waits for it to complete
  /// and returns the same result to prevent Firebase errors.
  Future<bool> requestPermission() async {
    // Check if a request is already in progress
    // Use completer existence as the source of truth (more reliable than flag)
    var existingCompleter = _permissionRequestCompleter;
    if (existingCompleter != null && !existingCompleter.isCompleted) {
      Log.d('Permission request already in progress, waiting for result...', tag: _tag);
      return existingCompleter.future;
    }

    // Create new completer and set it as the active one
    // In Dart's single-threaded model, the check above is sufficient because
    // no other code can run between the check and this assignment
    final completer = Completer<bool>();
    _permissionRequestCompleter = completer;
    
    try {
      Log.d('Requesting notification permission (iOS: ${Platform.isIOS}, Android: ${Platform.isAndroid})', tag: _tag);

      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      Log.i(
        'Notification permission result: ${settings.authorizationStatus.name} (granted: $granted)',
        tag: _tag,
      );

      if (Platform.isIOS) {
        Log.d('iOS specific - alert: ${settings.alert}, sound: ${settings.sound}, badge: ${settings.badge}', tag: _tag);
        
        // Also request permission for local notifications on iOS
        // This is needed for foreground notifications to show
        if (granted) {
          try {
            final localNotificationsPlugin = _localNotifications
                .resolvePlatformSpecificImplementation<
                    IOSFlutterLocalNotificationsPlugin>();
            
            if (localNotificationsPlugin != null) {
              final localGranted = await localNotificationsPlugin
                  .requestPermissions(
                alert: true,
                badge: true,
                sound: true,
              );
              Log.d('Local notifications permission: $localGranted', tag: _tag);
            }
          } catch (e) {
            Log.w('Failed to request local notification permissions: $e', tag: _tag);
          }
        }
      }

      if (granted) {
        // On iOS, ensure APNS token is available before getting FCM token
        if (Platform.isIOS) {
          // Wait for APNS token to be set after permission grant
          // iOS can take 2-5 seconds to register with APNS
          await _waitForAPNSToken(maxAttempts: 8, initialDelay: 500);
        }

        // Get token after permission granted
        await getToken();
      }

      // Complete the completer so concurrent callers get the result
      // Only complete if not already completed (defensive check)
      if (!completer.isCompleted) {
        completer.complete(granted);
      }
      return granted;
    } catch (e, stackTrace) {
      // If error occurs, complete with false and log
      Log.e('Failed to request notification permission', tag: _tag, error: e, stackTrace: stackTrace);
      // Only complete if not already completed (defensive check)
      if (!completer.isCompleted) {
        completer.complete(false);
      }
      return false;
    } finally {
      // Reset state only if this completer is still the current one
      // This prevents race conditions where a new request started
      // before this one finished
      if (_permissionRequestCompleter == completer) {
        _permissionRequestCompleter = null;
      }
    }
  }

  /// Wait for APNS token to be available (iOS only)
  ///
  /// Retries with exponential backoff up to maxAttempts times
  /// APNS token can take 2-5 seconds to be available after app start or permission grant
  Future<void> _waitForAPNSToken({
    int maxAttempts = 8,
    int initialDelay = 500,
  }) async {
    if (!Platform.isIOS) return;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) {
          Log.d(
            'APNS token obtained (attempt $attempt): ${apnsToken.substring(0, 10)}...',
            tag: _tag,
          );
          return; // Success!
        }
      } catch (e) {
        Log.w('Error checking APNS token (attempt $attempt): $e', tag: _tag);
      }

      // If not the last attempt, wait before retrying
      if (attempt < maxAttempts) {
        // Exponential backoff: 500ms, 1000ms, 1500ms, 2000ms, 2500ms, 3000ms, 3500ms
        final delay = initialDelay * attempt;
        Log.d(
          'APNS token not available yet, waiting ${delay}ms before retry (attempt $attempt/$maxAttempts)...',
          tag: _tag,
        );
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    Log.w(
      'APNS token still not available after $maxAttempts attempts. FCM token request may fail.',
      tag: _tag,
    );
  }

  /// Get FCM token
  ///
  /// Returns null if permission not granted
  /// On iOS, ensures APNS token is set first
  Future<String?> getToken() async {
    try {
      // On iOS, wait for APNS token before getting FCM token
      // This is especially important after app restart when permission is already granted
      if (Platform.isIOS) {
        await _waitForAPNSToken(maxAttempts: 8, initialDelay: 500);
      }

      _currentToken = await _messaging.getToken();
      Log.d('FCM token obtained', tag: _tag);
      return _currentToken;
    } catch (e) {
      Log.e('Failed to get FCM token: $e', tag: _tag);
      return null;
    }
  }

  /// Handle foreground message
  ///
  /// iOS Foreground Behavior (WhatsApp-style):
  /// - User on chat/booking screen for this booking → Suppress chat refresh only, show other updates
  /// - User on other screen → Play sound + emit event for in-app banner
  ///
  /// We DON'T show system notifications when app is in foreground
  /// This matches WhatsApp/Telegram behavior and provides better UX
  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    final type = data['type'] as String?;
    final bookingId = data['bookingId'] as String?;

    Log.d(
      'Foreground message: type=$type, bookingId=$bookingId, '
      'activeBooking=$_activeBookingId, hasNotification=${notification != null}',
      tag: _tag,
    );

    // Track notification received (fire-and-forget)
    getIt<IAnalyticsService>().logNotificationReceived(
      notificationType: type ?? 'unknown',
      bookingId: bookingId,
    );

    // Case 1: Chat message while user is viewing this booking's chat
    // → Suppress notification and just refresh chat silently (no sound, no banner)
    if (type == 'chat_message' &&
        bookingId != null &&
        bookingId == _activeBookingId) {
      Log.d('Suppressing chat notification - user on chat screen (silent refresh)', tag: _tag);
      // Notify via both stream and callback for reliability
      _chatMessageController.add(bookingId);
      onChatMessage?.call(bookingId);
      // Return early - no sound, no banner
      return;
    }

    // Case 2: All other messages (including booking updates, or chat when not on screen)
    // → Play sound and show in-app banner
    Log.i('Foreground notification - emitting event for in-app display', tag: _tag);
    
    // Extract notification data for display
    final notificationData = {
      'type': type ?? '',
      'bookingId': bookingId ?? '',
      'broadcastId': data['broadcastId'] ?? '',
      'title': notification?.title ?? data['notificationTitle'] ?? 'Zuco',
      'body': notification?.body ?? data['notificationBody'] ?? '',
      'imageUrl': notification?.android?.imageUrl ?? data['notificationImageUrl'],
      'updateType': data['updateType'], // For booking updates
      'data': data,
    };
    
    // Emit event for app to show in-app banner
    _foregroundNotificationController.add(notificationData);
    
    // Play notification sound on iOS/Android
    _playNotificationSound();
  }


  /// Handle notification tap (from FCM)
  void _handleNotificationTap(RemoteMessage message, {String source = 'background'}) {
    Log.d('Notification tapped (source: $source)', tag: _tag);

    final data = message.data;
    final type = data['type'] as String?;
    final bookingId = data['bookingId'] as String?;

    // Track notification opened (fire-and-forget)
    getIt<IAnalyticsService>().logNotificationOpened(
      notificationType: type ?? 'unknown',
      bookingId: bookingId,
      source: source,
    );

    onNotificationTap?.call(data);
  }

  /// Handle local notification tap
  void _handleLocalNotificationTap(String payload) {
    Log.d('Local notification tapped', tag: _tag);

    // Parse payload back to map
    final data = <String, dynamic>{};
    for (final pair in payload.split('&')) {
      final parts = pair.split('=');
      if (parts.length == 2) {
        data[parts[0]] = parts[1];
      }
    }

    final type = data['type'] as String?;
    final bookingId = data['bookingId'] as String?;

    // Track notification opened (fire-and-forget)
    getIt<IAnalyticsService>().logNotificationOpened(
      notificationType: type ?? 'unknown',
      bookingId: bookingId,
      source: 'foreground',
    );

    onNotificationTap?.call(data);
  }

  /// Play notification sound
  /// 
  /// Plays a subtle notification sound via local notifications
  /// This gives us full control over when sound plays
  Future<void> _playNotificationSound() async {
    try {
      // Show a silent notification that only plays sound
      // On iOS, this plays the default notification sound
      const iosDetails = DarwinNotificationDetails(
        presentAlert: false, // Don't show alert
        presentBadge: false, // Don't update badge
        presentSound: true,  // Only play sound
        sound: 'default',    // Use default iOS sound (subtle)
      );

      const androidDetails = AndroidNotificationDetails(
        'app_notifications',
        'App Notifications',
        channelDescription: 'Notifications for app updates',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'), // Default sound
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Show notification with ID -1 (will be immediately dismissed, only sound plays)
      await _localNotifications.show(
        -1, // Special ID for sound-only notification
        '',
        '',
        details,
      );

      Log.d('Notification sound played', tag: _tag);
    } catch (e) {
      Log.w('Failed to play notification sound: $e', tag: _tag);
      // Non-fatal - continue without sound
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenController.close();
    _chatMessageController.close();
    _foregroundNotificationController.close();
  }
}

/// Background message handler
///
/// Must be a top-level function (not a method).
/// Called when app is in background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background messages are handled by system notification
  // No need to show local notification here
  Log.d('Background message received: ${message.messageId}', tag: 'FCM');
}
