import 'package:flutter/material.dart';

/// Empty State - Placeholder for empty lists/screens
///
/// Shows a consistent empty state with icon, title, description,
/// and optional action button.
///
/// Example:
/// ```dart
/// EmptyState(
///   icon: Icons.inbox_outlined,
///   title: 'No messages',
///   description: 'Your inbox is empty',
///   actionLabel: 'Refresh',
///   onAction: () => refresh(),
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// Icon to display
  final IconData icon;

  /// Title text
  final String title;

  /// Description text (optional)
  final String? description;

  /// Action button label (optional)
  final String? actionLabel;

  /// Action button callback (optional)
  final VoidCallback? onAction;

  /// Icon size
  final double iconSize;

  /// Whether to use a compact layout
  final bool compact;

  /// Custom icon widget (overrides icon parameter)
  final Widget? customIcon;

  /// Secondary action label (optional)
  final String? secondaryActionLabel;

  /// Secondary action callback (optional)
  final VoidCallback? onSecondaryAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.actionLabel,
    this.onAction,
    this.iconSize = 64,
    this.compact = false,
    this.customIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  /// Create an empty state for no search results
  factory EmptyState.noResults({
    String title = 'No results found',
    String? description = 'Try adjusting your search or filters',
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.search_off_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Create an empty state for network error
  factory EmptyState.networkError({
    String title = 'No connection',
    String? description = 'Please check your internet connection',
    String actionLabel = 'Try Again',
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: Icons.wifi_off_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Create an empty state for empty list
  factory EmptyState.emptyList({
    required IconData icon,
    required String title,
    String? description,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return EmptyState(
      icon: icon,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            customIcon ??
                Container(
                  width: compact ? 60 : 80,
                  height: compact ? 60 : 80,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: compact ? iconSize * 0.5 : iconSize * 0.6,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),

            SizedBox(height: compact ? 16 : 24),

            // Title
            Text(
              title,
              style: compact
                  ? theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    )
                  : theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              textAlign: TextAlign.center,
            ),

            // Description
            if (description != null) ...[
              SizedBox(height: compact ? 8 : 12),
              Text(
                description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // Actions
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 16 : 24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],

            if (secondaryActionLabel != null && onSecondaryAction != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Inline empty state for smaller sections
class EmptyStateInline extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateInline({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
