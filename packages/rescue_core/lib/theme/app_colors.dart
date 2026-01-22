import 'package:flutter/material.dart';

/// Druto Color Palette
///
/// Coral + Mint theme - Food/Restaurant vibe
/// Primary: Coral Red (#FF6B6B) - Appetite, energy, action
/// Secondary: Mint/Teal (#4ECDC4) - Fresh, rewards, success
/// Tertiary: Navy (#2C3E50) - Trust, sophistication
abstract class AppColors {
  // ============================================
  // Brand Colors
  // ============================================

  /// Primary - Coral Red
  /// Used for: Primary buttons, CTAs, highlights
  static const Color primary = Color(0xFFFF6B6B);
  static const Color primaryLight = Color(0xFFFF8E8E);
  static const Color primaryDark = Color(0xFFE84545);

  /// Secondary - Mint/Teal
  /// Used for: Success states, rewards, stamps
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color secondaryLight = Color(0xFF7EE8E2);
  static const Color secondaryDark = Color(0xFF2AB7A9);

  /// Tertiary - Navy
  /// Used for: Text, cards, sophisticated elements
  static const Color tertiary = Color(0xFF2C3E50);
  static const Color tertiaryLight = Color(0xFF34495E);
  static const Color tertiaryDark = Color(0xFF1A252F);

  // ============================================
  // Semantic Colors
  // ============================================

  /// Success - Same as secondary (mint = rewards/success)
  static const Color success = Color(0xFF4ECDC4);

  /// Warning - Soft Yellow
  static const Color warning = Color(0xFFFFE66D);
  static const Color warningDark = Color(0xFFE6CF00);

  /// Error - Same as primary (coral)
  static const Color error = Color(0xFFFF6B6B);

  /// Info - Blue
  static const Color info = Color(0xFF3498DB);

  /// Star Rating - Golden
  static const Color starRating = Color(0xFFFFD93D);

  // ============================================
  // Light Theme Colors
  // ============================================

  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F5F5);
  static const Color lightOnBackground = Color(0xFF2C3E50);
  static const Color lightOnSurface = Color(0xFF2C3E50);
  static const Color lightOnSurfaceVariant = Color(0xFF6B7B8A);
  static const Color lightOutline = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);

  // ============================================
  // Dark Theme Colors
  // ============================================

  static const Color darkBackground = Color(0xFF1A1A2E);
  static const Color darkSurface = Color(0xFF16213E);
  static const Color darkSurfaceVariant = Color(0xFF1F2B47);
  static const Color darkOnBackground = Color(0xFFFFFFFF);
  static const Color darkOnSurface = Color(0xFFFFFFFF);
  static const Color darkOnSurfaceVariant = Color(0xFFB0B8C4);
  static const Color darkOutline = Color(0xFF3A4A5E);
  static const Color darkDivider = Color(0xFF2A3A4E);

  // ============================================
  // Stamp Card Colors
  // ============================================

  /// Empty stamp slot
  static const Color stampEmpty = Color(0xFFE0E0E0);
  static const Color stampEmptyDark = Color(0xFF3A4A5E);

  /// Filled stamp
  static const Color stampFilled = secondary;

  /// Stamp card gradient
  static const List<Color> stampCardGradient = [
    Color(0xFFFF6B6B),
    Color(0xFFFF8E8E),
  ];

  // ============================================
  // Helper Methods
  // ============================================

  /// Get primary color with opacity
  static Color primaryWithOpacity(double opacity) =>
      primary.withValues(alpha: opacity);

  /// Get secondary color with opacity
  static Color secondaryWithOpacity(double opacity) =>
      secondary.withValues(alpha: opacity);

  /// Get contrasting text color for a background
  static Color contrastText(Color background) {
    return background.computeLuminance() > 0.5 ? tertiary : Colors.white;
  }
}
