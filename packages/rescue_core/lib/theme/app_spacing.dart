import 'package:flutter/material.dart';

/// Standard spacing values for the app
abstract class AppSpacing {
  // ============================================
  // Base Values
  // ============================================

  /// Extra extra small spacing (2.0)
  static const double xxs = 2.0;

  /// Extra small spacing (4.0)
  static const double xs = 4.0;

  /// Small spacing (8.0)
  static const double sm = 8.0;

  /// Medium spacing (12.0)
  static const double md = 12.0;

  /// Regular/Default spacing (16.0)
  static const double regular = 16.0;

  /// Large spacing (24.0)
  static const double lg = 24.0;

  /// Extra large spacing (32.0)
  static const double xl = 32.0;

  /// Extra extra large spacing (48.0)
  static const double xxl = 48.0;

  // ============================================
  // EdgeInsets Shortcuts
  // ============================================

  /// Horizontal padding - regular
  static const EdgeInsets horizontalRegular =
      EdgeInsets.symmetric(horizontal: regular);

  /// Horizontal padding - large
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);

  /// Vertical padding - regular
  static const EdgeInsets verticalRegular =
      EdgeInsets.symmetric(vertical: regular);

  /// All sides - regular
  static const EdgeInsets allRegular = EdgeInsets.all(regular);

  /// All sides - small
  static const EdgeInsets allSm = EdgeInsets.all(sm);

  /// All sides - medium
  static const EdgeInsets allMd = EdgeInsets.all(md);

  /// Screen padding (horizontal regular, vertical small)
  static const EdgeInsets screen = EdgeInsets.symmetric(
    horizontal: regular,
    vertical: sm,
  );

  /// Card padding
  static const EdgeInsets card = EdgeInsets.all(regular);

  /// List item padding
  static const EdgeInsets listItem = EdgeInsets.symmetric(
    horizontal: regular,
    vertical: md,
  );

  // ============================================
  // SizedBox Shortcuts
  // ============================================

  static const SizedBox verticalXxs = SizedBox(height: xxs);
  static const SizedBox verticalXs = SizedBox(height: xs);
  static const SizedBox verticalSm = SizedBox(height: sm);
  static const SizedBox verticalMd = SizedBox(height: md);
  static const SizedBox verticalRegularBox = SizedBox(height: regular);
  static const SizedBox verticalLg = SizedBox(height: lg);
  static const SizedBox verticalXl = SizedBox(height: xl);
  static const SizedBox verticalXxl = SizedBox(height: xxl);

  static const SizedBox horizontalXxs = SizedBox(width: xxs);
  static const SizedBox horizontalXs = SizedBox(width: xs);
  static const SizedBox horizontalSm = SizedBox(width: sm);
  static const SizedBox horizontalMd = SizedBox(width: md);
  static const SizedBox horizontalRegularBox = SizedBox(width: regular);
  static const SizedBox horizontalLgBox = SizedBox(width: lg);
  static const SizedBox horizontalXl = SizedBox(width: xl);
}
