import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// App Text Field - Styled text input with consistent design
///
/// A customizable text field with built-in styling that matches
/// the app's design system.
///
/// Example:
/// ```dart
/// AppTextField(
///   controller: nameController,
///   label: 'Full Name',
///   hint: 'Enter your name',
///   prefixIcon: Icons.person_outline,
/// )
/// ```
class AppTextField extends StatelessWidget {
  /// Text editing controller
  final TextEditingController? controller;

  /// Label text above the field
  final String? label;

  /// Hint text inside the field
  final String? hint;

  /// Helper text below the field
  final String? helperText;

  /// Error text (shows error state)
  final String? errorText;

  /// Prefix icon
  final IconData? prefixIcon;

  /// Suffix icon
  final IconData? suffixIcon;

  /// Suffix icon callback
  final VoidCallback? onSuffixTap;

  /// Whether the field is enabled
  final bool enabled;

  /// Whether the field is read-only
  final bool readOnly;

  /// Whether to obscure text (for passwords)
  final bool obscureText;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Text input action
  final TextInputAction? textInputAction;

  /// Text capitalization
  final TextCapitalization textCapitalization;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Max length
  final int? maxLength;

  /// Max lines
  final int? maxLines;

  /// Min lines
  final int? minLines;

  /// Called when text changes
  final ValueChanged<String>? onChanged;

  /// Called when editing is complete
  final VoidCallback? onEditingComplete;

  /// Called when field is submitted
  final ValueChanged<String>? onSubmitted;

  /// Called when field is tapped
  final VoidCallback? onTap;

  /// Focus node
  final FocusNode? focusNode;

  /// Autofocus
  final bool autofocus;

  /// Autofill hints
  final Iterable<String>? autofillHints;

  /// Whether to show character counter
  final bool showCounter;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.autofocus = false,
    this.autofillHints,
    this.showCounter = false,
  });

  /// Create a password text field with toggle visibility
  static Widget password({
    Key? key,
    TextEditingController? controller,
    String? label = 'Password',
    String? hint,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    return _PasswordTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }

  /// Create a multiline text field
  factory AppTextField.multiline({
    Key? key,
    TextEditingController? controller,
    String? label,
    String? hint,
    String? errorText,
    int maxLines = 4,
    int? minLines,
    int? maxLength,
    ValueChanged<String>? onChanged,
    bool showCounter = true,
  }) {
    return AppTextField(
      key: key,
      controller: controller,
      label: label,
      hint: hint,
      errorText: errorText,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      onChanged: onChanged,
      showCounter: showCounter,
      textCapitalization: TextCapitalization.sentences,
      keyboardType: TextInputType.multiline,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Text field
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          maxLines: maxLines,
          minLines: minLines,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          onSubmitted: onSubmitted,
          onTap: onTap,
          autofocus: autofocus,
          autofillHints: autofillHints,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            errorText: errorText,
            helperText: helperText,
            counterText: showCounter ? null : '',
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: colorScheme.onSurfaceVariant)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(suffixIcon, color: colorScheme.onSurfaceVariant),
                  )
                : null,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}

/// Password text field with visibility toggle
class _PasswordTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  const _PasswordTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  State<_PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<_PasswordTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      hint: widget.hint,
      errorText: widget.errorText,
      obscureText: _obscureText,
      prefixIcon: Icons.lock_outline,
      suffixIcon: _obscureText
          ? Icons.visibility_outlined
          : Icons.visibility_off_outlined,
      onSuffixTap: () => setState(() => _obscureText = !_obscureText),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.password],
    );
  }
}
