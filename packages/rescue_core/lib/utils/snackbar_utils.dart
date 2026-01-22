import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for showing enhanced SnackBars throughout the app
///
/// Provides consistent styling and behavior for success, error,
/// info, and warning notifications.
class SnackBarUtils {
  /// Private constructor to prevent instantiation
  SnackBarUtils._();

  /// Show a success SnackBar with haptic feedback
  ///
  /// Example:
  /// ```dart
  /// SnackBarUtils.showSuccess(context, 'Login successful!');
  /// ```
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    HapticFeedback.lightImpact();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.green.shade600,
      icon: Icons.check_circle,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show an error SnackBar with haptic feedback
  ///
  /// Example:
  /// ```dart
  /// SnackBarUtils.showError(context, 'Invalid phone number');
  /// ```
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    HapticFeedback.mediumImpact();
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.red.shade600,
      icon: Icons.error,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show an info SnackBar
  ///
  /// Example:
  /// ```dart
  /// SnackBarUtils.showInfo(context, 'OTP sent to your phone');
  /// ```
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.blue.shade600,
      icon: Icons.info,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show a warning SnackBar
  ///
  /// Example:
  /// ```dart
  /// SnackBarUtils.showWarning(context, 'Please verify your phone number');
  /// ```
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: Colors.orange.shade700,
      icon: Icons.warning,
      iconColor: Colors.white,
      duration: duration,
      action: action,
    );
  }

  /// Show a custom SnackBar
  ///
  /// Use this for full customization when the predefined types
  /// don't fit your use case.
  static void showCustom(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    _showSnackBar(
      context,
      message: message,
      backgroundColor: backgroundColor,
      icon: icon,
      iconColor: iconColor,
      duration: duration,
      action: action,
    );
  }

  /// Internal method to show the SnackBar
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    Color? iconColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    // Dismiss any existing SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();

    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Colors.white,
                size: 24,
                semanticLabel: _getSemanticLabel(icon),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 6,
        action: action,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  /// Get semantic label for icon based on icon type
  static String _getSemanticLabel(IconData icon) {
    if (icon == Icons.check_circle) return 'Success';
    if (icon == Icons.error) return 'Error';
    if (icon == Icons.info) return 'Information';
    if (icon == Icons.warning) return 'Warning';
    return 'Notification';
  }
}
