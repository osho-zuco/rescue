import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Loading Button - Button with loading state
///
/// A button that shows a loading indicator when in loading state.
/// Supports filled, outlined, and text variants.
///
/// Example:
/// ```dart
/// LoadingButton(
///   onPressed: () => submit(),
///   isLoading: isSubmitting,
///   child: Text('Submit'),
/// )
/// ```
class LoadingButton extends StatelessWidget {
  /// Called when button is pressed (disabled when loading)
  final VoidCallback? onPressed;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Button content
  final Widget child;

  /// Button variant
  final LoadingButtonVariant variant;

  /// Custom loading indicator
  final Widget? loadingIndicator;

  /// Minimum width (null for auto)
  final double? minWidth;

  /// Whether button expands to full width
  final bool expanded;

  /// Button height
  final double height;

  /// Icon to show before the child
  final IconData? icon;

  /// Whether to show haptic feedback on press
  final bool hapticFeedback;

  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.variant = LoadingButtonVariant.filled,
    this.loadingIndicator,
    this.minWidth,
    this.expanded = false,
    this.height = 56,
    this.icon,
    this.hapticFeedback = true,
  });

  /// Create a filled loading button
  const LoadingButton.filled({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.loadingIndicator,
    this.minWidth,
    this.expanded = false,
    this.height = 56,
    this.icon,
    this.hapticFeedback = true,
  }) : variant = LoadingButtonVariant.filled;

  /// Create an outlined loading button
  const LoadingButton.outlined({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.loadingIndicator,
    this.minWidth,
    this.expanded = false,
    this.height = 56,
    this.icon,
    this.hapticFeedback = true,
  }) : variant = LoadingButtonVariant.outlined;

  /// Create a text loading button
  const LoadingButton.text({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.loadingIndicator,
    this.minWidth,
    this.expanded = false,
    this.height = 48,
    this.icon,
    this.hapticFeedback = true,
  }) : variant = LoadingButtonVariant.text;

  void _onPressed() {
    if (hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = _buildChild(context);

    final buttonStyle = switch (variant) {
      LoadingButtonVariant.filled => FilledButton.styleFrom(
          minimumSize: Size(minWidth ?? 0, height),
        ),
      LoadingButtonVariant.outlined => OutlinedButton.styleFrom(
          minimumSize: Size(minWidth ?? 0, height),
        ),
      LoadingButtonVariant.text => TextButton.styleFrom(
          minimumSize: Size(minWidth ?? 0, height),
        ),
    };

    Widget button = switch (variant) {
      LoadingButtonVariant.filled => icon != null && !isLoading
          ? FilledButton.icon(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 20),
              label: buttonChild,
            )
          : FilledButton(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              child: buttonChild,
            ),
      LoadingButtonVariant.outlined => icon != null && !isLoading
          ? OutlinedButton.icon(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 20),
              label: buttonChild,
            )
          : OutlinedButton(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              child: buttonChild,
            ),
      LoadingButtonVariant.text => icon != null && !isLoading
          ? TextButton.icon(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              icon: Icon(icon, size: 20),
              label: buttonChild,
            )
          : TextButton(
              onPressed: isLoading ? null : _onPressed,
              style: buttonStyle,
              child: buttonChild,
            ),
    };

    if (expanded) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  Widget _buildChild(BuildContext context) {
    if (isLoading) {
      return loadingIndicator ??
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                variant == LoadingButtonVariant.filled
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
          );
    }

    return child;
  }
}

/// Button variant types
enum LoadingButtonVariant {
  filled,
  outlined,
  text,
}
