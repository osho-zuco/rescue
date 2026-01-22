import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Error Dialog - Standardized error display
///
/// Shows a consistent error dialog with optional retry action.
///
/// Example:
/// ```dart
/// ErrorDialog.show(
///   context,
///   title: 'Connection Error',
///   message: 'Unable to connect to server. Please check your internet.',
///   onRetry: () => fetchData(),
/// );
/// ```
class ErrorDialog {
  ErrorDialog._();

  /// Show an error dialog
  static Future<void> show(
    BuildContext context, {
    String title = 'Something went wrong',
    required String message,
    VoidCallback? onRetry,
    String retryLabel = 'Try Again',
    String dismissLabel = 'OK',
    bool barrierDismissible = true,
  }) async {
    HapticFeedback.mediumImpact();

    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _ErrorDialogContent(
        title: title,
        message: message,
        onRetry: onRetry,
        retryLabel: retryLabel,
        dismissLabel: dismissLabel,
      ),
    );
  }

  /// Show a simple error snackbar (for non-blocking errors)
  static void showSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      ),
    );
  }
}

class _ErrorDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final String dismissLabel;

  const _ErrorDialogContent({
    required this.title,
    required this.message,
    this.onRetry,
    required this.retryLabel,
    required this.dismissLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.error_outline_rounded,
          color: colorScheme.error,
          size: 32,
        ),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        if (onRetry != null) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(dismissLabel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: Text(retryLabel),
          ),
        ] else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(dismissLabel),
          ),
      ],
    );
  }
}

/// Confirmation dialog for destructive actions
class ConfirmDialog {
  ConfirmDialog._();

  /// Show a confirmation dialog
  static Future<bool> show(
    BuildContext context, {
    String title = 'Are you sure?',
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelLabel),
          ),
          if (isDestructive)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(confirmLabel),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
        ],
      ),
    );

    return result ?? false;
  }
}
