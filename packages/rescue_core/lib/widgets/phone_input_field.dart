import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Phone Input Field with +91 prefix - Shared Widget
///
/// Features:
/// - Fixed +91 country code (India only for MVP)
/// - 10-digit validation
/// - Numeric keyboard
/// - Auto-formats as user types
class PhoneInputField extends StatelessWidget {
  /// Controller for the phone number (without country code)
  final TextEditingController controller;

  /// Called when user submits (presses done on keyboard)
  final VoidCallback? onSubmitted;

  /// Error message to display (null = no error)
  final String? errorText;

  /// Whether the field is enabled
  final bool enabled;

  /// Auto-focus when widget builds
  final bool autofocus;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.onSubmitted,
    this.errorText,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.done,
      maxLength: 10,
      style: theme.textTheme.titleLarge?.copyWith(
        letterSpacing: 2,
        fontWeight: FontWeight.w500,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        // Country code prefix
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🇮🇳',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(width: 8),
              Text(
                '+91',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                margin: const EdgeInsets.only(left: 12),
                width: 1,
                height: 20,
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: '98765 43210',
        hintStyle: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          letterSpacing: 2,
        ),
        errorText: errorText,
        counterText: '', // Hide character counter
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      onSubmitted: (_) => onSubmitted?.call(),
    );
  }

  /// Validate phone number (static utility)
  static bool isValid(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return cleaned.length == 10;
  }

  /// Format phone with country code
  static String formatWithCountryCode(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'\D'), '');
    return '+91$cleaned';
  }
}
