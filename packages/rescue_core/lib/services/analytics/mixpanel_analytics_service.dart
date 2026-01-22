import 'package:flutter/foundation.dart';
import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import '../logger.dart';
import 'i_analytics_service.dart';

/// Mixpanel implementation of analytics service
class MixpanelAnalyticsService implements IAnalyticsService {
  Mixpanel? _mixpanel;
  bool _initialized = false;

  /// Initialize Mixpanel with project token
  Future<void> initialize(String token) async {
    try {
      _mixpanel = await Mixpanel.init(
        token,
        trackAutomaticEvents: true, // Auto-track app opens, sessions
      );
      _initialized = true;
      _logDebug('Mixpanel initialized');
    } catch (e) {
      Log.e('Failed to initialize Mixpanel', tag: 'Analytics', error: e);
    }
  }

  // ============================================
  // User Properties
  // ============================================

  @override
  Future<void> setUserId(String? userId) async {
    if (!_initialized) return;
    try {
      if (userId != null) {
        _mixpanel?.identify(userId);
        _logDebug('User ID set: $userId');
      } else {
        _mixpanel?.reset(); // Clear user identity
        _logDebug('User ID cleared');
      }
    } catch (e) {
      Log.e('Failed to set user ID', tag: 'Analytics', error: e);
    }
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    if (!_initialized) return;
    try {
      _mixpanel?.getPeople().set(name, value);
      _logDebug('User property set: $name = $value');
    } catch (e) {
      Log.e('Failed to set user property', tag: 'Analytics', error: e);
    }
  }

  @override
  Future<void> setIsHost(bool isHost) async {
    await setUserProperty(name: 'is_host', value: isHost ? 'true' : 'false');
  }

  @override
  Future<void> setUserCity(String? city) async {
    await setUserProperty(name: 'city', value: city);
  }

  @override
  Future<void> setUserName(String? name) async {
    await setUserProperty(name: '\$name', value: name);
  }

  @override
  Future<void> setUserGender(String? gender) async {
    await setUserProperty(name: 'gender', value: gender);
  }

  @override
  Future<void> setHasProfileImage(bool hasImage) async {
    await setUserProperty(name: 'has_profile_image', value: hasImage ? 'true' : 'false');
  }

  // ============================================
  // Auth Events
  // ============================================

  @override
  Future<void> logAppOpened() async {
    // Automatically tracked by Mixpanel's trackAutomaticEvents
    // But we can add custom properties
    await logEvent('app_opened');
  }

  @override
  Future<void> logSignUp({required String method}) async {
    await logEvent('sign_up', parameters: {'method': method});
  }

  @override
  Future<void> logLogin({required String method}) async {
    await logEvent('login', parameters: {'method': method});
  }

  @override
  Future<void> logLogout() async {
    await logEvent('logout');
    await setUserId(null); // Clear identity
  }

  @override
  Future<void> logAuthLoginStarted({String? userType}) async {
    await logEvent(
      'auth_login_started',
      parameters: {
        if (userType != null) 'user_type': userType,
      },
    );
  }

  @override
  Future<void> logAuthOtpSent({required String phone}) async {
    await logEvent(
      'auth_otp_sent',
      parameters: {
        'phone_masked': _maskPhone(phone),
      },
    );
  }

  @override
  Future<void> logAuthOtpVerified({required String phone}) async {
    await logEvent(
      'auth_otp_verified',
      parameters: {
        'phone_masked': _maskPhone(phone),
      },
    );
  }

  @override
  Future<void> logAuthOtpResent({required String phone}) async {
    await logEvent(
      'auth_otp_resent',
      parameters: {
        'phone_masked': _maskPhone(phone),
      },
    );
  }

  @override
  Future<void> logAuthError({
    required String errorType,
    required String screen,
    String? errorMessage,
  }) async {
    await logEvent(
      'auth_error',
      parameters: {
        'error_type': errorType,
        'screen': screen,
        if (errorMessage != null) 'error_message': errorMessage,
      },
    );
  }

  @override
  Future<void> logAadhaarVerified() async {
    await logEvent('aadhaar_verified');
    await setUserProperty(name: 'aadhaar_verified', value: 'true');
  }

  // ============================================
  // Search & Discovery Events
  // ============================================

  @override
  Future<void> logSearch({
    required String searchQuery,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await logEvent(
      'search',
      parameters: {
        'search_term': searchQuery,
        if (city != null) 'city': city,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      },
    );
  }

  @override
  Future<void> logSearchResultsViewed({
    required int resultCount,
    required String city,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) async {
    await logEvent(
      'search_results_viewed',
      parameters: {
        'result_count': resultCount,
        'city': city,
        if (startDate != null) 'start_date': startDate.toIso8601String().split('T')[0],
        if (endDate != null) 'end_date': endDate.toIso8601String().split('T')[0],
        if (sortBy != null) 'sort_by': sortBy,
      },
    );
  }

  @override
  Future<void> logHostCardClicked({
    required String hostId,
    required int position,
    required String source,
  }) async {
    await logEvent(
      'host_card_clicked',
      parameters: {
        'host_id': hostId,
        'position': position,
        'source': source,
      },
    );
  }

  @override
  Future<void> logFilterApplied({
    required String filterType,
    required String filterValue,
  }) async {
    await logEvent(
      'filter_applied',
      parameters: {
        'filter_type': filterType,
        'filter_value': filterValue,
      },
    );
  }

  @override
  Future<void> logViewHostProfile({
    required String hostId,
    String? source,
  }) async {
    await logEvent(
      'view_host_profile',
      parameters: {'host_id': hostId, if (source != null) 'source': source},
    );
  }

  // ============================================
  // Booking Events
  // ============================================

  @override
  Future<void> logBookingInitiated({
    required String hostId,
    required int nightCount,
    required int petCount,
    String? petType,
    String? source,
  }) async {
    await logEvent(
      'booking_initiated',
      parameters: {
        'host_id': hostId,
        'nights': nightCount,
        'pet_count': petCount,
        if (petType != null) 'pet_type': petType,
        if (source != null) 'source': source,
      },
    );
  }

  @override
  Future<void> logBookingDatesSelected({
    required int nightCount,
    required DateTime startDate,
    required DateTime endDate,
    required int daysInAdvance,
  }) async {
    await logEvent(
      'booking_dates_selected',
      parameters: {
        'nights': nightCount,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'days_in_advance': daysInAdvance,
      },
    );
  }

  @override
  Future<void> logBookingPetSelected({
    required String petId,
    required String petType,
  }) async {
    await logEvent(
      'booking_pet_selected',
      parameters: {
        'pet_id': petId,
        'pet_type': petType,
      },
    );
  }

  @override
  Future<void> logBookingCreated({
    required String bookingId,
    required String hostId,
    required double amount,
    required int nightCount,
    required int petCount,
    String? petType,
    String? bookingType,
    int? daysInAdvance,
    String? source,
  }) async {
    await logEvent(
      'booking_created',
      parameters: {
        'booking_id': bookingId,
        'host_id': hostId,
        'value': amount,
        'currency': 'INR',
        'nights': nightCount,
        'pet_count': petCount,
        if (petType != null) 'pet_type': petType,
        if (bookingType != null) 'booking_type': bookingType,
        if (daysInAdvance != null) 'days_in_advance': daysInAdvance,
        if (source != null) 'source': source,
      },
    );
  }

  @override
  Future<void> logBookingAccepted({
    required String bookingId,
    required double amount,
    required int responseTimeMinutes,
  }) async {
    await logEvent(
      'booking_accepted',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'response_time_minutes': responseTimeMinutes,
      },
    );
  }

  @override
  Future<void> logBookingDeclined({
    required String bookingId,
    String? reason,
    required int responseTimeMinutes,
  }) async {
    await logEvent(
      'booking_declined',
      parameters: {
        'booking_id': bookingId,
        if (reason != null) 'reason': reason,
        'response_time_minutes': responseTimeMinutes,
      },
    );
  }

  @override
  Future<void> logBookingConfirmed({
    required String bookingId,
    required double amount,
    required bool requiresPayment,
  }) async {
    await logEvent(
      'booking_confirmed',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'requires_payment': requiresPayment,
      },
    );
  }

  @override
  Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
    required String cancelledByRole,
    int? daysBeforeStart,
  }) async {
    await logEvent(
      'booking_cancelled',
      parameters: {
        'booking_id': bookingId,
        'reason': reason,
        'cancelled_by': cancelledByRole,
        if (daysBeforeStart != null) 'days_before_start': daysBeforeStart,
      },
    );
  }

  @override
  Future<void> logBookingHandoverMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
  }) async {
    await logEvent(
      'booking_handover_marked',
      parameters: {
        'booking_id': bookingId,
        'has_photo': hasPhoto,
        'has_notes': hasNotes,
      },
    );
  }

  @override
  Future<void> logBookingPickupMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
    required int daysInProgress,
  }) async {
    await logEvent(
      'booking_pickup_marked',
      parameters: {
        'booking_id': bookingId,
        'has_photo': hasPhoto,
        'has_notes': hasNotes,
        'days_in_progress': daysInProgress,
      },
    );
  }

  @override
  Future<void> logBookingCompleted({
    required String bookingId,
    required double amount,
    required int totalDays,
  }) async {
    await logEvent(
      'booking_completed',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'total_days': totalDays,
      },
    );
  }

  // ============================================
  // Payment Events
  // ============================================

  @override
  Future<void> logPaymentInitiated({
    required String bookingId,
    required double amount,
    String? gateway,
  }) async {
    await logEvent(
      'payment_initiated',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        if (gateway != null) 'gateway': gateway,
      },
    );
  }

  @override
  Future<void> logUpiAppsDetected({
    required int installedAppsCount,
    required List<String> appNames,
  }) async {
    await logEvent(
      'upi_apps_detected',
      parameters: {
        'installed_apps_count': installedAppsCount,
        'app_names': appNames.take(5).join(','), // Top 5 apps
      },
    );
  }

  @override
  Future<void> logPaymentMethodSelected({
    required String bookingId,
    required double amount,
    required String paymentMethod,
    String? upiAppName,
  }) async {
    await logEvent(
      'payment_method_selected',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'payment_method': paymentMethod,
        if (upiAppName != null) 'upi_app': upiAppName,
      },
    );
  }

  @override
  Future<void> logUpiIntentLaunched({
    required String bookingId,
    required double amount,
    required String appName,
  }) async {
    await logEvent(
      'upi_intent_launched',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'app_name': appName,
      },
    );
  }

  @override
  Future<void> logPaymentVerificationStarted({
    required String bookingId,
    required String verificationMethod,
  }) async {
    await logEvent(
      'payment_verification_started',
      parameters: {
        'booking_id': bookingId,
        'verification_method': verificationMethod,
      },
    );
  }

  @override
  Future<void> logPaymentVerificationCompleted({
    required String bookingId,
    required bool verified,
    required String verificationMethod,
    required int timeToVerificationSeconds,
  }) async {
    await logEvent(
      'payment_verification_completed',
      parameters: {
        'booking_id': bookingId,
        'verified': verified,
        'verification_method': verificationMethod,
        'time_to_verification_seconds': timeToVerificationSeconds,
      },
    );
  }

  @override
  Future<void> logPaymentSuccess({
    required String bookingId,
    required String paymentId,
    required double amount,
    String? paymentMethod,
    String? gateway,
  }) async {
    await logEvent(
      'payment_success',
      parameters: {
        'transaction_id': paymentId,
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (gateway != null) 'gateway': gateway,
      },
    );
  }

  @override
  Future<void> logPaymentFailed({
    required String bookingId,
    required double amount,
    String? errorReason,
    String? errorCode,
    String? paymentMethod,
    String? stage,
  }) async {
    await logEvent(
      'payment_failed',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        if (errorReason != null) 'error': errorReason,
        if (errorCode != null) 'error_code': errorCode,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (stage != null) 'stage': stage,
      },
    );
  }

  @override
  Future<void> logPaymentOrderExpired({
    required String bookingId,
    required int attemptNumber,
  }) async {
    await logEvent(
      'payment_order_expired',
      parameters: {
        'booking_id': bookingId,
        'attempt_number': attemptNumber,
      },
    );
  }

  @override
  Future<void> logPaymentRecovery({
    required String bookingId,
    required String recoverySource,
  }) async {
    await logEvent(
      'payment_recovery',
      parameters: {
        'booking_id': bookingId,
        'recovery_source': recoverySource,
      },
    );
  }

  // ============================================
  // Host Events
  // ============================================

  @override
  Future<void> logBecameHost() async {
    await logEvent('became_host');
    await setIsHost(true);
  }

  @override
  Future<void> logHostProfileUpdated() async {
    await logEvent('host_profile_updated');
  }

  @override
  Future<void> logHostAvailabilityUpdated() async {
    await logEvent('host_availability_updated');
  }

  @override
  Future<void> logProfessionalBoardingInterest() async {
    await logEvent('professional_boarding_interest');
  }

  // ============================================
  // Pet Events
  // ============================================

  @override
  Future<void> logPetAdded({required String petType}) async {
    await logEvent('pet_added', parameters: {'pet_type': petType});
  }

  @override
  Future<void> logPetUpdated({required String petType}) async {
    await logEvent('pet_updated', parameters: {'pet_type': petType});
  }

  // ============================================
  // Profile Events
  // ============================================

  @override
  Future<void> logProfileCompleted() async {
    await logEvent('profile_completed');
  }

  @override
  Future<void> logProfilePictureUpdated() async {
    await logEvent('profile_picture_updated');
  }

  // ============================================
  // Chat Events
  // ============================================

  @override
  Future<void> logChatMessageSent({
    required String bookingId,
    bool isHost = false,
  }) async {
    await logEvent(
      'chat_message_sent',
      parameters: {
        'booking_id': bookingId,
        'user_type': isHost ? 'host' : 'guest',
      },
    );
  }

  @override
  Future<void> logPhotoUpdateSent({required String bookingId}) async {
    await logEvent('photo_update_sent', parameters: {'booking_id': bookingId});
  }

  // ============================================
  // Review Events
  // ============================================

  @override
  Future<void> logReviewSubmitted({
    required String bookingId,
    required double rating,
  }) async {
    await logEvent(
      'review_submitted',
      parameters: {'booking_id': bookingId, 'rating': rating},
    );
  }

  // ============================================
  // Notification Events
  // ============================================

  @override
  Future<void> logNotificationReceived({
    required String notificationType,
    String? bookingId,
  }) async {
    await logEvent(
      'notification_received',
      parameters: {
        'notification_type': notificationType,
        if (bookingId != null) 'booking_id': bookingId,
      },
    );
  }

  @override
  Future<void> logNotificationOpened({
    required String notificationType,
    String? bookingId,
    required String source,
  }) async {
    await logEvent(
      'notification_opened',
      parameters: {
        'notification_type': notificationType,
        if (bookingId != null) 'booking_id': bookingId,
        'source': source,
      },
    );
  }

  // ============================================
  // Screen Tracking
  // ============================================

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await logEvent(
      'screen_view',
      parameters: {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
    );
  }

  // ============================================
  // Generic Event Logging
  // ============================================

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {

    if (!_initialized) {
      Log.w('Mixpanel not initialized, skipping event: $name', tag: 'Mixpanel');
      return;
    }
    if (_mixpanel == null) {
      Log.w(
        'Mixpanel instance is null, skipping event: $name',
        tag: 'Mixpanel',
      );
      return;
    }
    try {
      _mixpanel?.track(name, properties: parameters);
      _logDebug('Event logged: $name ${parameters ?? ''}');
      // Log in production too for debugging
      Log.d('Mixpanel event tracked: $name', tag: 'Mixpanel');
    } catch (e, stackTrace) {
      Log.e(
        'Failed to log event: $name',
        tag: 'Mixpanel',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================
  // Debug Helpers
  // ============================================

  void _logDebug(String message) {
    if (kDebugMode) {
      Log.d(message, tag: 'Mixpanel');
    }
  }

  /// Mask phone number for privacy (show only last 4 digits)
  /// Example: 9876543210 -> *******3210
  String _maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length > 4) {
      return '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
    }
    return digits;
  }
}
