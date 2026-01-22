/// Theme Service
///
/// Manages app theme preference (light/dark/system).
/// Persists to SharedPreferences.
///
/// Usage:
/// ```dart
/// // In main/bootstrap
/// await ThemeService.instance.initialize();
///
/// // Listen to changes
/// ValueListenableBuilder<ThemeMode>(
///   valueListenable: ThemeService.instance.themeModeNotifier,
///   builder: (context, mode, _) => MaterialApp(themeMode: mode, ...),
/// )
///
/// // Change theme
/// ThemeService.instance.setThemeMode(ThemeMode.dark);
/// ```

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';

  // Singleton
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  late SharedPreferences _prefs;

  /// Current theme mode as a ValueNotifier for reactive updates
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  /// Current theme mode
  ThemeMode get themeMode => themeModeNotifier.value;

  /// Initialize the service (call in bootstrap)
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final savedMode = _prefs.getString(_themeKey);
    themeModeNotifier.value = _parseThemeMode(savedMode);
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    await _prefs.setString(_themeKey, _themeModeToString(mode));
  }

  /// Parse theme mode from string
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get display name for theme mode
  static String getDisplayName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get icon for theme mode
  static IconData getIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
