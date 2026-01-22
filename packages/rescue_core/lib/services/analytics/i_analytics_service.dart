/// Analytics service interface
/// Allows swapping between Firebase, Mixpanel, Amplitude, etc.
abstract class IAnalyticsService {
  // ============================================
  // User Properties
  // ============================================

  Future<void> setUserId(String? userId);
  Future<void> setUserProperty({required String name, required String? value});
  Future<void> setIsHost(bool isHost);
  Future<void> setUserCity(String? city);
  Future<void> setUserName(String? name);
  Future<void> setUserGender(String? gender);
  Future<void> setHasProfileImage(bool hasImage);

  // ============================================
  // Auth Events
  // ============================================

  Future<void> logAppOpened();
  Future<void> logSignUp({required String method});
  Future<void> logLogin({required String method});
  Future<void> logLogout();
  Future<void> logAadhaarVerified();

  // Auth flow events for login/OTP
  Future<void> logAuthLoginStarted({String? userType}); // merchant or user
  Future<void> logAuthOtpSent({required String phone});
  Future<void> logAuthOtpVerified({required String phone});
  Future<void> logAuthOtpResent({required String phone});
  Future<void> logAuthError({
    required String errorType, // network, validation, server_error
    required String screen, // login, otp
    String? errorMessage,
  });

  // ============================================
  // Search & Discovery Events
  // ============================================

  Future<void> logSearch({
    required String searchQuery,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Track when search results are displayed to user
  Future<void> logSearchResultsViewed({
    required int resultCount,
    required String city,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  });

  /// Track when user clicks on a host card from search results
  Future<void> logHostCardClicked({
    required String hostId,
    required int position, // 0-indexed position in search results
    required String source, // search, featured, recommended
  });

  /// Track when user applies a filter
  Future<void> logFilterApplied({
    required String filterType, // pet_type, price_range, rating, distance
    required String filterValue,
  });

  Future<void> logViewHostProfile({required String hostId, String? source});

  // ============================================
  // Booking Events
  // ============================================

  Future<void> logBookingInitiated({
    required String hostId,
    required int nightCount,
    required int petCount,
    String? petType,
    String? source, // search, host_profile, broadcast, rebook
  });

  Future<void> logBookingDatesSelected({
    required int nightCount,
    required DateTime startDate,
    required DateTime endDate,
    required int daysInAdvance,
  });

  Future<void> logBookingPetSelected({
    required String petId,
    required String petType,
  });

  Future<void> logBookingCreated({
    required String bookingId,
    required String hostId,
    required double amount,
    required int nightCount,
    required int petCount,
    String? petType,
    String? bookingType, // free, paid, platform_fee_only
    int? daysInAdvance,
    String? source, // search, host_profile, broadcast, rebook
  });

  Future<void> logBookingAccepted({
    required String bookingId,
    required double amount,
    required int responseTimeMinutes, // time from request to accept
  });

  Future<void> logBookingDeclined({
    required String bookingId,
    String? reason,
    required int responseTimeMinutes,
  });

  Future<void> logBookingConfirmed({
    required String bookingId,
    required double amount,
    required bool requiresPayment,
  });

  Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
    required String cancelledByRole, // guest, host
    int? daysBeforeStart,
  });

  Future<void> logBookingHandoverMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
  });

  Future<void> logBookingPickupMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
    required int daysInProgress,
  });

  Future<void> logBookingCompleted({
    required String bookingId,
    required double amount,
    required int totalDays,
  });

  // ============================================
  // Payment Events
  // ============================================

  Future<void> logPaymentInitiated({
    required String bookingId,
    required double amount,
    String? gateway, // razorpay, cashfree
  });

  Future<void> logUpiAppsDetected({
    required int installedAppsCount,
    required List<String> appNames,
  });

  Future<void> logPaymentMethodSelected({
    required String bookingId,
    required double amount,
    required String paymentMethod, // upi_app, manual_upi, cards, net_banking, webview
    String? upiAppName,
  });

  Future<void> logUpiIntentLaunched({
    required String bookingId,
    required double amount,
    required String appName,
  });

  Future<void> logPaymentVerificationStarted({
    required String bookingId,
    required String verificationMethod, // polling, webhook, app_resume
  });

  Future<void> logPaymentVerificationCompleted({
    required String bookingId,
    required bool verified,
    required String verificationMethod,
    required int timeToVerificationSeconds,
  });

  Future<void> logPaymentSuccess({
    required String bookingId,
    required String paymentId,
    required double amount,
    String? paymentMethod,
    String? gateway,
  });

  Future<void> logPaymentFailed({
    required String bookingId,
    required double amount,
    String? errorReason,
    String? errorCode,
    String? paymentMethod,
    String? stage, // init, checkout, verification
  });

  Future<void> logPaymentOrderExpired({
    required String bookingId,
    required int attemptNumber,
  });

  Future<void> logPaymentRecovery({
    required String bookingId,
    required String recoverySource, // webhook_recovery, app_resume, booking_fetch
  });

  // ============================================
  // Host Events
  // ============================================

  Future<void> logBecameHost();
  Future<void> logHostProfileUpdated();
  Future<void> logHostAvailabilityUpdated();
  Future<void> logProfessionalBoardingInterest();

  // ============================================
  // Pet Events
  // ============================================

  Future<void> logPetAdded({required String petType});
  Future<void> logPetUpdated({required String petType});

  // ============================================
  // Profile Events
  // ============================================

  Future<void> logProfileCompleted();
  Future<void> logProfilePictureUpdated();

  // ============================================
  // Chat Events
  // ============================================

  Future<void> logChatMessageSent({
    required String bookingId,
    bool isHost = false,
  });
  Future<void> logPhotoUpdateSent({required String bookingId});

  // ============================================
  // Review Events
  // ============================================

  Future<void> logReviewSubmitted({
    required String bookingId,
    required double rating,
  });

  // ============================================
  // Notification Events
  // ============================================

  /// Track when a push notification is received (foreground)
  Future<void> logNotificationReceived({
    required String notificationType, // booking_request, booking_accepted, chat_message, etc.
    String? bookingId,
  });

  /// Track when user opens a notification
  Future<void> logNotificationOpened({
    required String notificationType,
    String? bookingId,
    required String source, // foreground, background, terminated
  });

  // ============================================
  // Screen Tracking
  // ============================================

  Future<void> logScreenView({required String screenName, String? screenClass});

  // ============================================
  // Generic Event Logging
  // ============================================

  Future<void> logEvent(String name, {Map<String, Object>? parameters});
}
