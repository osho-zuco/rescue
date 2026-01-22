import 'firebase_analytics_service.dart';
import '../logger.dart';
import 'i_analytics_service.dart';
import 'mixpanel_analytics_service.dart';

/// Composite analytics service that sends events to multiple providers
/// Currently: Firebase Analytics + Mixpanel
///
/// Event Strategy:
/// - CORE events (conversions): Firebase + Mixpanel
///   - booking_created, payment_success, booking_completed
///   - sign_up, login, became_host
/// - DETAILED events (funnel analysis): Mixpanel only
///   - booking_dates_selected, booking_pet_selected
///   - payment_method_selected, upi_intent_launched, etc.
///
/// All analytics calls are wrapped in try-catch to prevent app crashes.
class CompositeAnalyticsService implements IAnalyticsService {
  final FirebaseAnalyticsService _firebaseAnalytics;
  final MixpanelAnalyticsService _mixpanelAnalytics;

  CompositeAnalyticsService({
    required FirebaseAnalyticsService firebaseAnalytics,
    required MixpanelAnalyticsService mixpanelAnalytics,
  }) : _firebaseAnalytics = firebaseAnalytics,
       _mixpanelAnalytics = mixpanelAnalytics;

  /// Safely execute analytics calls - catches all exceptions to prevent crashes
  Future<void> _safeCall(String eventName, Future<void> Function() call) async {
    try {
      await call();
    } catch (e, stackTrace) {
      // Log error but don't crash the app
      Log.e(
        'Analytics error for $eventName',
        tag: 'CompositeAnalytics',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================
  // User Properties
  // ============================================

  @override
  Future<void> setUserId(String? userId) async {
    await _safeCall('setUserId', () => Future.wait([
      _firebaseAnalytics.setUserId(userId),
      _mixpanelAnalytics.setUserId(userId),
    ]));
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _safeCall('setUserProperty', () => Future.wait([
      _firebaseAnalytics.setUserProperty(name: name, value: value),
      _mixpanelAnalytics.setUserProperty(name: name, value: value),
    ]));
  }

  @override
  Future<void> setIsHost(bool isHost) async {
    await _safeCall('setIsHost', () => Future.wait([
      _firebaseAnalytics.setIsHost(isHost),
      _mixpanelAnalytics.setIsHost(isHost),
    ]));
  }

  @override
  Future<void> setUserCity(String? city) async {
    await _safeCall('setUserCity', () => Future.wait([
      _firebaseAnalytics.setUserCity(city),
      _mixpanelAnalytics.setUserCity(city),
    ]));
  }

  @override
  Future<void> setUserName(String? name) async {
    await _safeCall('setUserName', () => Future.wait([
      _firebaseAnalytics.setUserName(name),
      _mixpanelAnalytics.setUserName(name),
    ]));
  }

  @override
  Future<void> setUserGender(String? gender) async {
    await _safeCall('setUserGender', () => Future.wait([
      _firebaseAnalytics.setUserGender(gender),
      _mixpanelAnalytics.setUserGender(gender),
    ]));
  }

  @override
  Future<void> setHasProfileImage(bool hasImage) async {
    await _safeCall('setHasProfileImage', () => Future.wait([
      _firebaseAnalytics.setHasProfileImage(hasImage),
      _mixpanelAnalytics.setHasProfileImage(hasImage),
    ]));
  }

  // ============================================
  // Auth Events
  // ============================================

  @override
  Future<void> logAppOpened() async {
    await _safeCall('logAppOpened', () => Future.wait([
      _firebaseAnalytics.logAppOpened(),
      _mixpanelAnalytics.logAppOpened(),
    ]));
  }

  @override
  Future<void> logSignUp({required String method}) async {
    await _safeCall('logSignUp', () => Future.wait([
      _firebaseAnalytics.logSignUp(method: method),
      _mixpanelAnalytics.logSignUp(method: method),
    ]));
  }

  @override
  Future<void> logLogin({required String method}) async {
    await _safeCall('logLogin', () => Future.wait([
      _firebaseAnalytics.logLogin(method: method),
      _mixpanelAnalytics.logLogin(method: method),
    ]));
  }

  @override
  Future<void> logLogout() async {
    await _safeCall('logLogout', () => Future.wait([
      _firebaseAnalytics.logLogout(),
      _mixpanelAnalytics.logLogout(),
    ]));
  }

  @override
  Future<void> logAadhaarVerified() async {
    await _safeCall('logAadhaarVerified', () async {
      await _mixpanelAnalytics.logAadhaarVerified();
      await _firebaseAnalytics.logEvent('aadhaar_verified');
    });
  }

  @override
  Future<void> logAuthLoginStarted({String? userType}) async {
    await _safeCall('logAuthLoginStarted', () => Future.wait([
      _firebaseAnalytics.logAuthLoginStarted(userType: userType),
      _mixpanelAnalytics.logAuthLoginStarted(userType: userType),
    ]));
  }

  @override
  Future<void> logAuthOtpSent({required String phone}) async {
    await _safeCall('logAuthOtpSent', () => Future.wait([
      _firebaseAnalytics.logAuthOtpSent(phone: phone),
      _mixpanelAnalytics.logAuthOtpSent(phone: phone),
    ]));
  }

  @override
  Future<void> logAuthOtpVerified({required String phone}) async {
    await _safeCall('logAuthOtpVerified', () => Future.wait([
      _firebaseAnalytics.logAuthOtpVerified(phone: phone),
      _mixpanelAnalytics.logAuthOtpVerified(phone: phone),
    ]));
  }

  @override
  Future<void> logAuthOtpResent({required String phone}) async {
    await _safeCall('logAuthOtpResent', () => Future.wait([
      _firebaseAnalytics.logAuthOtpResent(phone: phone),
      _mixpanelAnalytics.logAuthOtpResent(phone: phone),
    ]));
  }

  @override
  Future<void> logAuthError({
    required String errorType,
    required String screen,
    String? errorMessage,
  }) async {
    await _safeCall('logAuthError', () => Future.wait([
      _firebaseAnalytics.logAuthError(
        errorType: errorType,
        screen: screen,
        errorMessage: errorMessage,
      ),
      _mixpanelAnalytics.logAuthError(
        errorType: errorType,
        screen: screen,
        errorMessage: errorMessage,
      ),
    ]));
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
    await _safeCall('logSearch', () => Future.wait([
      _firebaseAnalytics.logSearch(
        searchQuery: searchQuery,
        city: city,
        startDate: startDate,
        endDate: endDate,
      ),
      _mixpanelAnalytics.logSearch(
        searchQuery: searchQuery,
        city: city,
        startDate: startDate,
        endDate: endDate,
      ),
    ]));
  }

  @override
  Future<void> logSearchResultsViewed({
    required int resultCount,
    required String city,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logSearchResultsViewed', () =>
      _mixpanelAnalytics.logSearchResultsViewed(
        resultCount: resultCount,
        city: city,
        startDate: startDate,
        endDate: endDate,
        sortBy: sortBy,
      ),
    );
  }

  @override
  Future<void> logHostCardClicked({
    required String hostId,
    required int position,
    required String source,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logHostCardClicked', () =>
      _mixpanelAnalytics.logHostCardClicked(
        hostId: hostId,
        position: position,
        source: source,
      ),
    );
  }

  @override
  Future<void> logFilterApplied({
    required String filterType,
    required String filterValue,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logFilterApplied', () =>
      _mixpanelAnalytics.logFilterApplied(
        filterType: filterType,
        filterValue: filterValue,
      ),
    );
  }

  @override
  Future<void> logViewHostProfile({
    required String hostId,
    String? source,
  }) async {
    await _safeCall('logViewHostProfile', () => Future.wait([
      _firebaseAnalytics.logViewHostProfile(hostId: hostId, source: source),
      _mixpanelAnalytics.logViewHostProfile(hostId: hostId, source: source),
    ]));
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
    await _safeCall('logBookingInitiated', () => Future.wait([
      _firebaseAnalytics.logBookingInitiated(
        hostId: hostId,
        nightCount: nightCount,
        petCount: petCount,
        petType: petType,
        source: source,
      ),
      _mixpanelAnalytics.logBookingInitiated(
        hostId: hostId,
        nightCount: nightCount,
        petCount: petCount,
        petType: petType,
        source: source,
      ),
    ]));
  }

  @override
  Future<void> logBookingDatesSelected({
    required int nightCount,
    required DateTime startDate,
    required DateTime endDate,
    required int daysInAdvance,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingDatesSelected', () =>
      _mixpanelAnalytics.logBookingDatesSelected(
        nightCount: nightCount,
        startDate: startDate,
        endDate: endDate,
        daysInAdvance: daysInAdvance,
      ),
    );
  }

  @override
  Future<void> logBookingPetSelected({
    required String petId,
    required String petType,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingPetSelected', () =>
      _mixpanelAnalytics.logBookingPetSelected(petId: petId, petType: petType),
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
    await _safeCall('logBookingCreated', () => Future.wait([
      _firebaseAnalytics.logBookingCreated(
        bookingId: bookingId,
        hostId: hostId,
        amount: amount,
        nightCount: nightCount,
        petCount: petCount,
        petType: petType,
        bookingType: bookingType,
        daysInAdvance: daysInAdvance,
        source: source,
      ),
      _mixpanelAnalytics.logBookingCreated(
        bookingId: bookingId,
        hostId: hostId,
        amount: amount,
        nightCount: nightCount,
        petCount: petCount,
        petType: petType,
        bookingType: bookingType,
        daysInAdvance: daysInAdvance,
        source: source,
      ),
    ]));
  }

  @override
  Future<void> logBookingAccepted({
    required String bookingId,
    required double amount,
    required int responseTimeMinutes,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingAccepted', () =>
      _mixpanelAnalytics.logBookingAccepted(
        bookingId: bookingId,
        amount: amount,
        responseTimeMinutes: responseTimeMinutes,
      ),
    );
  }

  @override
  Future<void> logBookingDeclined({
    required String bookingId,
    String? reason,
    required int responseTimeMinutes,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingDeclined', () =>
      _mixpanelAnalytics.logBookingDeclined(
        bookingId: bookingId,
        reason: reason,
        responseTimeMinutes: responseTimeMinutes,
      ),
    );
  }

  @override
  Future<void> logBookingConfirmed({
    required String bookingId,
    required double amount,
    required bool requiresPayment,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingConfirmed', () =>
      _mixpanelAnalytics.logBookingConfirmed(
        bookingId: bookingId,
        amount: amount,
        requiresPayment: requiresPayment,
      ),
    );
  }

  @override
  Future<void> logBookingCancelled({
    required String bookingId,
    required String reason,
    required String cancelledByRole,
    int? daysBeforeStart,
  }) async {
    await _safeCall('logBookingCancelled', () => Future.wait([
      _firebaseAnalytics.logBookingCancelled(
        bookingId: bookingId,
        reason: reason,
        cancelledByRole: cancelledByRole,
        daysBeforeStart: daysBeforeStart,
      ),
      _mixpanelAnalytics.logBookingCancelled(
        bookingId: bookingId,
        reason: reason,
        cancelledByRole: cancelledByRole,
        daysBeforeStart: daysBeforeStart,
      ),
    ]));
  }

  @override
  Future<void> logBookingHandoverMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingHandoverMarked', () =>
      _mixpanelAnalytics.logBookingHandoverMarked(
        bookingId: bookingId,
        hasPhoto: hasPhoto,
        hasNotes: hasNotes,
      ),
    );
  }

  @override
  Future<void> logBookingPickupMarked({
    required String bookingId,
    required bool hasPhoto,
    required bool hasNotes,
    required int daysInProgress,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logBookingPickupMarked', () =>
      _mixpanelAnalytics.logBookingPickupMarked(
        bookingId: bookingId,
        hasPhoto: hasPhoto,
        hasNotes: hasNotes,
        daysInProgress: daysInProgress,
      ),
    );
  }

  @override
  Future<void> logBookingCompleted({
    required String bookingId,
    required double amount,
    required int totalDays,
  }) async {
    await _safeCall('logBookingCompleted', () => Future.wait([
      _firebaseAnalytics.logBookingCompleted(
        bookingId: bookingId,
        amount: amount,
        totalDays: totalDays,
      ),
      _mixpanelAnalytics.logBookingCompleted(
        bookingId: bookingId,
        amount: amount,
        totalDays: totalDays,
      ),
    ]));
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
    await _safeCall('logPaymentInitiated', () => Future.wait([
      _firebaseAnalytics.logPaymentInitiated(
        bookingId: bookingId,
        amount: amount,
        gateway: gateway,
      ),
      _mixpanelAnalytics.logPaymentInitiated(
        bookingId: bookingId,
        amount: amount,
        gateway: gateway,
      ),
    ]));
  }

  @override
  Future<void> logUpiAppsDetected({
    required int installedAppsCount,
    required List<String> appNames,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logUpiAppsDetected', () =>
      _mixpanelAnalytics.logUpiAppsDetected(
        installedAppsCount: installedAppsCount,
        appNames: appNames,
      ),
    );
  }

  @override
  Future<void> logPaymentMethodSelected({
    required String bookingId,
    required double amount,
    required String paymentMethod,
    String? upiAppName,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logPaymentMethodSelected', () =>
      _mixpanelAnalytics.logPaymentMethodSelected(
        bookingId: bookingId,
        amount: amount,
        paymentMethod: paymentMethod,
        upiAppName: upiAppName,
      ),
    );
  }

  @override
  Future<void> logUpiIntentLaunched({
    required String bookingId,
    required double amount,
    required String appName,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logUpiIntentLaunched', () =>
      _mixpanelAnalytics.logUpiIntentLaunched(
        bookingId: bookingId,
        amount: amount,
        appName: appName,
      ),
    );
  }

  @override
  Future<void> logPaymentVerificationStarted({
    required String bookingId,
    required String verificationMethod,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logPaymentVerificationStarted', () =>
      _mixpanelAnalytics.logPaymentVerificationStarted(
        bookingId: bookingId,
        verificationMethod: verificationMethod,
      ),
    );
  }

  @override
  Future<void> logPaymentVerificationCompleted({
    required String bookingId,
    required bool verified,
    required String verificationMethod,
    required int timeToVerificationSeconds,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logPaymentVerificationCompleted', () =>
      _mixpanelAnalytics.logPaymentVerificationCompleted(
        bookingId: bookingId,
        verified: verified,
        verificationMethod: verificationMethod,
        timeToVerificationSeconds: timeToVerificationSeconds,
      ),
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
    await _safeCall('logPaymentSuccess', () => Future.wait([
      _firebaseAnalytics.logPaymentSuccess(
        bookingId: bookingId,
        paymentId: paymentId,
        amount: amount,
        paymentMethod: paymentMethod,
        gateway: gateway,
      ),
      _mixpanelAnalytics.logPaymentSuccess(
        bookingId: bookingId,
        paymentId: paymentId,
        amount: amount,
        paymentMethod: paymentMethod,
        gateway: gateway,
      ),
    ]));
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
    await _safeCall('logPaymentFailed', () => Future.wait([
      _firebaseAnalytics.logPaymentFailed(
        bookingId: bookingId,
        amount: amount,
        errorReason: errorReason,
        errorCode: errorCode,
        paymentMethod: paymentMethod,
        stage: stage,
      ),
      _mixpanelAnalytics.logPaymentFailed(
        bookingId: bookingId,
        amount: amount,
        errorReason: errorReason,
        errorCode: errorCode,
        paymentMethod: paymentMethod,
        stage: stage,
      ),
    ]));
  }

  @override
  Future<void> logPaymentOrderExpired({
    required String bookingId,
    required int attemptNumber,
  }) async {
    await _safeCall('logPaymentOrderExpired', () => Future.wait([
      _firebaseAnalytics.logPaymentOrderExpired(
        bookingId: bookingId,
        attemptNumber: attemptNumber,
      ),
      _mixpanelAnalytics.logPaymentOrderExpired(
        bookingId: bookingId,
        attemptNumber: attemptNumber,
      ),
    ]));
  }

  @override
  Future<void> logPaymentRecovery({
    required String bookingId,
    required String recoverySource,
  }) async {
    await _safeCall('logPaymentRecovery', () => Future.wait([
      _firebaseAnalytics.logPaymentRecovery(
        bookingId: bookingId,
        recoverySource: recoverySource,
      ),
      _mixpanelAnalytics.logPaymentRecovery(
        bookingId: bookingId,
        recoverySource: recoverySource,
      ),
    ]));
  }

  // ============================================
  // Host Events
  // ============================================

  @override
  Future<void> logBecameHost() async {
    await _safeCall('logBecameHost', () => Future.wait([
      _firebaseAnalytics.logBecameHost(),
      _mixpanelAnalytics.logBecameHost(),
    ]));
  }

  @override
  Future<void> logHostProfileUpdated() async {
    await _safeCall('logHostProfileUpdated', () => Future.wait([
      _firebaseAnalytics.logHostProfileUpdated(),
      _mixpanelAnalytics.logHostProfileUpdated(),
    ]));
  }

  @override
  Future<void> logHostAvailabilityUpdated() async {
    await _safeCall('logHostAvailabilityUpdated', () => Future.wait([
      _firebaseAnalytics.logHostAvailabilityUpdated(),
      _mixpanelAnalytics.logHostAvailabilityUpdated(),
    ]));
  }

  @override
  Future<void> logProfessionalBoardingInterest() async {
    await _safeCall('logProfessionalBoardingInterest', () => Future.wait([
      _firebaseAnalytics.logProfessionalBoardingInterest(),
      _mixpanelAnalytics.logProfessionalBoardingInterest(),
    ]));
  }

  // ============================================
  // Pet Events
  // ============================================

  @override
  Future<void> logPetAdded({required String petType}) async {
    await _safeCall('logPetAdded', () => Future.wait([
      _firebaseAnalytics.logPetAdded(petType: petType),
      _mixpanelAnalytics.logPetAdded(petType: petType),
    ]));
  }

  @override
  Future<void> logPetUpdated({required String petType}) async {
    await _safeCall('logPetUpdated', () => Future.wait([
      _firebaseAnalytics.logPetUpdated(petType: petType),
      _mixpanelAnalytics.logPetUpdated(petType: petType),
    ]));
  }

  // ============================================
  // Profile Events
  // ============================================

  @override
  Future<void> logProfileCompleted() async {
    await _safeCall('logProfileCompleted', () => Future.wait([
      _firebaseAnalytics.logProfileCompleted(),
      _mixpanelAnalytics.logProfileCompleted(),
    ]));
  }

  @override
  Future<void> logProfilePictureUpdated() async {
    await _safeCall('logProfilePictureUpdated', () => Future.wait([
      _firebaseAnalytics.logProfilePictureUpdated(),
      _mixpanelAnalytics.logProfilePictureUpdated(),
    ]));
  }

  // ============================================
  // Chat Events
  // ============================================

  @override
  Future<void> logChatMessageSent({
    required String bookingId,
    bool isHost = false,
  }) async {
    await _safeCall('logChatMessageSent', () => Future.wait([
      _firebaseAnalytics.logChatMessageSent(
        bookingId: bookingId,
        isHost: isHost,
      ),
      _mixpanelAnalytics.logChatMessageSent(
        bookingId: bookingId,
        isHost: isHost,
      ),
    ]));
  }

  @override
  Future<void> logPhotoUpdateSent({required String bookingId}) async {
    await _safeCall('logPhotoUpdateSent', () => Future.wait([
      _firebaseAnalytics.logPhotoUpdateSent(bookingId: bookingId),
      _mixpanelAnalytics.logPhotoUpdateSent(bookingId: bookingId),
    ]));
  }

  // ============================================
  // Review Events
  // ============================================

  @override
  Future<void> logReviewSubmitted({
    required String bookingId,
    required double rating,
  }) async {
    await _safeCall('logReviewSubmitted', () => Future.wait([
      _firebaseAnalytics.logReviewSubmitted(
        bookingId: bookingId,
        rating: rating,
      ),
      _mixpanelAnalytics.logReviewSubmitted(
        bookingId: bookingId,
        rating: rating,
      ),
    ]));
  }

  // ============================================
  // Notification Events
  // ============================================

  @override
  Future<void> logNotificationReceived({
    required String notificationType,
    String? bookingId,
  }) async {
    // Mixpanel only - detailed funnel event
    await _safeCall('logNotificationReceived', () =>
      _mixpanelAnalytics.logNotificationReceived(
        notificationType: notificationType,
        bookingId: bookingId,
      ),
    );
  }

  @override
  Future<void> logNotificationOpened({
    required String notificationType,
    String? bookingId,
    required String source,
  }) async {
    // Both Firebase and Mixpanel - important conversion event
    await _safeCall('logNotificationOpened', () => Future.wait([
      _firebaseAnalytics.logNotificationOpened(
        notificationType: notificationType,
        bookingId: bookingId,
        source: source,
      ),
      _mixpanelAnalytics.logNotificationOpened(
        notificationType: notificationType,
        bookingId: bookingId,
        source: source,
      ),
    ]));
  }

  // ============================================
  // Screen Tracking
  // ============================================

  @override
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _safeCall('logScreenView', () =>
      _firebaseAnalytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      ),
    );
  }

  // ============================================
  // Generic Event Logging
  // ============================================

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _safeCall('logEvent:$name', () => Future.wait([
      _firebaseAnalytics.logEvent(name, parameters: parameters),
      _mixpanelAnalytics.logEvent(name, parameters: parameters),
    ]));
  }
}
