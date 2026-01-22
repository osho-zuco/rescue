import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'i_analytics_service.dart';
import '../logger.dart';

/// Firebase Analytics implementation
///
/// Wraps Firebase Analytics to provide:
/// - Type-safe event logging
/// - Centralized analytics configuration
/// - Easy debugging in dev mode
/// - User property management
class FirebaseAnalyticsService implements IAnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Firebase Analytics observer for automatic screen tracking
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ============================================
  // User Properties
  // ============================================

  /// Set user ID for tracking across sessions
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      _logDebug('User ID set: $userId');
    } catch (e) {
      Log.e('Failed to set user ID', tag: 'Analytics', error: e);
    }
  }

  /// Set user properties for segmentation
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      _logDebug('User property set: $name = $value');
    } catch (e) {
      Log.e('Failed to set user property', tag: 'Analytics', error: e);
    }
  }

  /// Set whether user is a host
  Future<void> setIsHost(bool isHost) async {
    await setUserProperty(name: 'is_host', value: isHost ? 'true' : 'false');
  }

  /// Set user's city for location-based analytics
  Future<void> setUserCity(String? city) async {
    await setUserProperty(name: 'city', value: city);
  }

  /// Set user's name
  @override
  Future<void> setUserName(String? name) async {
    await setUserProperty(name: 'user_name', value: name);
  }

  /// Set user's gender
  @override
  Future<void> setUserGender(String? gender) async {
    await setUserProperty(name: 'gender', value: gender);
  }

  /// Set whether user has profile image
  @override
  Future<void> setHasProfileImage(bool hasImage) async {
    await setUserProperty(name: 'has_profile_image', value: hasImage ? 'true' : 'false');
  }

  // ============================================
  // Auth Events
  // ============================================

  Future<void> logSignUp({required String method}) async {
    await logEvent(
      'sign_up',
      parameters: {'method': method}, // 'phone'
    );
  }

  Future<void> logLogin({required String method}) async {
    await logEvent(
      'login',
      parameters: {'method': method}, // 'phone'
    );
  }

  Future<void> logLogout() async {
    await logEvent('logout');
  }

  @override
  Future<void> logAppOpened() async {
    // Firebase tracks this automatically, but we can add custom event
    await logEvent('app_opened');
  }

  @override
  Future<void> logAuthLoginStarted({String? userType}) async {
    await logEvent(
      'auth_login_started',
      parameters: {
        if (userType != null) 'user_type': userType, // merchant or user
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
  }

  // ============================================
  // Search & Discovery Events
  // ============================================

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
      'view_search_results',
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
      'select_content',
      parameters: {
        'content_type': 'host_card',
        'item_id': hostId,
        'index': position,
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

  Future<void> logViewHostProfile({
    required String hostId,
    String? source,
  }) async {
    await logEvent(
      'view_item',
      parameters: {
        'item_id': hostId,
        'item_category': 'host_profile',
        if (source != null) 'source': source, // 'search', 'featured', etc.
      },
    );
  }

  // ============================================
  // Booking Events
  // ============================================

  Future<void> logBookingInitiated({
    required String hostId,
    required int nightCount,
    required int petCount,
    String? petType,
    String? source,
  }) async {
    await logEvent(
      'begin_checkout',
      parameters: {
        'host_id': hostId,
        'nights': nightCount,
        'pet_count': petCount,
        if (petType != null) 'pet_type': petType,
        if (source != null) 'source': source,
      },
    );
  }

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

  Future<void> logPaymentInitiated({
    required String bookingId,
    required double amount,
    String? gateway,
  }) async {
    await logEvent(
      'add_payment_info',
      parameters: {
        'booking_id': bookingId,
        'value': amount,
        'currency': 'INR',
        'payment_type': gateway ?? 'unknown',
      },
    );
  }

  Future<void> logUpiAppsDetected({
    required int installedAppsCount,
    required List<String> appNames,
  }) async {
    await logEvent(
      'upi_apps_detected',
      parameters: {
        'installed_apps_count': installedAppsCount,
        'app_names': appNames.take(5).join(','),
      },
    );
  }

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

  Future<void> logPaymentSuccess({
    required String bookingId,
    required String paymentId,
    required double amount,
    String? paymentMethod,
    String? gateway,
  }) async {
    await logEvent(
      'purchase',
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

  Future<void> logBecameHost() async {
    await logEvent('became_host');
  }

  Future<void> logHostProfileUpdated() async {
    await logEvent('host_profile_updated');
  }

  Future<void> logHostAvailabilityUpdated() async {
    await logEvent('host_availability_updated');
  }

  Future<void> logProfessionalBoardingInterest() async {
    await logEvent('professional_boarding_interest');
  }

  // ============================================
  // Pet Events
  // ============================================

  Future<void> logPetAdded({required String petType}) async {
    await logEvent('pet_added', parameters: {'pet_type': petType});
  }

  Future<void> logPetUpdated({required String petType}) async {
    await logEvent('pet_updated', parameters: {'pet_type': petType});
  }

  // ============================================
  // Profile Events
  // ============================================

  Future<void> logProfileCompleted() async {
    await logEvent('profile_completed');
  }

  Future<void> logProfilePictureUpdated() async {
    await logEvent('profile_picture_updated');
  }

  // ============================================
  // Chat Events
  // ============================================

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

  Future<void> logPhotoUpdateSent({required String bookingId}) async {
    await logEvent('photo_update_sent', parameters: {'booking_id': bookingId});
  }

  // ============================================
  // Review Events
  // ============================================

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
      'notification_receive',
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
      'notification_open',
      parameters: {
        'notification_type': notificationType,
        if (bookingId != null) 'booking_id': bookingId,
        'source': source,
      },
    );
  }

  // ============================================
  // Screen Tracking (Manual)
  // ============================================

  /// Log screen view manually (automatic tracking via observer is preferred)
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _logDebug('Screen view: $screenName');
    } catch (e) {
      Log.e('Failed to log screen view', tag: 'Analytics', error: e);
    }
  }

  // ============================================
  // Generic Event Logging
  // ============================================

  /// Log a custom event with optional parameters
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      _logDebug('Event logged: $name ${parameters ?? ''}');
    } catch (e) {
      Log.e('Failed to log event: $name', tag: 'Analytics', error: e);
    }
  }

  // ============================================
  // Debug Helpers
  // ============================================

  void _logDebug(String message) {
    if (kDebugMode) {
      Log.d(message, tag: 'Analytics');
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
