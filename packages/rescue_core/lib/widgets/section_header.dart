import 'package:flutter/material.dart';

/// Section Header - Consistent section headers
///
/// Used for section titles like "AVAILABLE REWARDS", "REVIEWS", etc.
///
/// Example:
/// ```dart
/// SectionHeader(
///   title: 'AVAILABLE REWARDS',
///   trailing: TextButton(child: Text('See All')),
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// Section title
  final String title;

  /// Optional trailing widget (e.g., "See All" button)
  final Widget? trailing;

  /// Optional leading icon
  final IconData? leadingIcon;

  /// Whether to use uppercase title
  final bool uppercase;

  /// Additional padding
  final EdgeInsets padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.leadingIcon,
    this.uppercase = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: padding,
      child: Row(
        children: [
          // Leading icon
          if (leadingIcon != null) ...[
            Icon(
              leadingIcon,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],

          // Title
          Expanded(
            child: Text(
              uppercase ? title.toUpperCase() : title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: uppercase ? 0.5 : 0,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // Trailing widget
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Section header with "See All" button
class SectionHeaderWithAction extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final int? count;
  final bool uppercase;

  const SectionHeaderWithAction({
    super.key,
    required this.title,
    this.actionLabel = 'See all',
    required this.onAction,
    this.count,
    this.uppercase = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SectionHeader(
      title: title,
      uppercase: uppercase,
      trailing: TextButton(
        onPressed: onAction,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          count != null ? '$actionLabel $count' : actionLabel,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
