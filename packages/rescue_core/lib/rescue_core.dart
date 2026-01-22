/// Rescue Core Package
///
/// Shared utilities, theme, and services for Pet Rescue app.
library rescue_core;

// Config
export 'config/env_config.dart';

// Dependency Injection
export 'di/service_locator.dart';

// Error handling
export 'error/api_error.dart';
export 'error/result.dart';

// Models
export 'models/user.dart';
export 'models/auth_response.dart';

// Network
export 'network/dio_client.dart';

// Repositories
export 'repositories/auth_repository.dart';
export 'repositories/user_repository.dart';

// BLoC
export 'bloc/auth/auth.dart';

// Services
export 'services/theme_service.dart';
export 'services/logger.dart';
export 'services/cloudinary_upload_service.dart';
export 'services/image_picker_service.dart';
export 'services/location_service.dart';
export 'services/google_places_service.dart';
export 'services/fcm_service.dart';
export 'services/analytics/i_analytics_service.dart';
export 'services/analytics/firebase_analytics_service.dart';
export 'services/analytics/mixpanel_analytics_service.dart';
export 'services/analytics/composite_analytics_service.dart';

// Theme
export 'theme/app_colors.dart';
export 'theme/app_radius.dart';
export 'theme/app_spacing.dart';
export 'theme/app_theme.dart';

// Utils
export 'utils/string_utils.dart';
export 'utils/date_utils.dart';
export 'utils/snackbar_utils.dart';

// Widgets
export 'widgets/phone_input_field.dart';
export 'widgets/auth/login_screen.dart';
export 'widgets/auth/otp_screen.dart';
export 'widgets/splash/splash_screen.dart';
export 'widgets/splash/animated_logo.dart';
export 'widgets/dropdown_selector.dart';
export 'widgets/user_avatar.dart';
export 'widgets/image_viewer.dart';
export 'widgets/loading_button.dart';
export 'widgets/error_dialog.dart';
export 'widgets/empty_state.dart';
export 'widgets/app_text_field.dart';
export 'widgets/section_header.dart';
export 'widgets/shimmer_loading.dart';
export 'widgets/status_chip.dart';
export 'widgets/location_input_widget.dart';
