import 'package:flutter/material.dart';

/// Standard border radius values for the app
abstract class AppRadius {
  /// Extra small radius (4.0) - for small elements like chips
  static const double xs = 4.0;

  /// Small radius (8.0) - for buttons, small cards
  static const double sm = 8.0;

  /// Medium radius (12.0) - for cards, dialogs
  static const double md = 12.0;

  /// Large radius (16.0) - for bottom sheets, large cards
  static const double lg = 16.0;

  /// Extra large radius (24.0) - for modals, prominent elements
  static const double xl = 24.0;

  /// Full/Circular radius (999.0) - for pills, avatars
  static const double full = 999.0;

  // BorderRadius constants for convenience
  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get fullAll => BorderRadius.circular(full);

  // Top-only variants (for bottom sheets, etc.)
  static BorderRadius get lgTop => const BorderRadius.vertical(
        top: Radius.circular(lg),
      );
  static BorderRadius get xlTop => const BorderRadius.vertical(
        top: Radius.circular(xl),
      );
}
