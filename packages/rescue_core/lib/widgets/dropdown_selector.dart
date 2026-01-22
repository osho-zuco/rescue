/// Dropdown Selector Widget
///
/// A reusable dropdown selector with a clean, modern design.
/// Uses PopupMenuButton for consistent behavior across the app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A generic dropdown option
class DropdownOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DropdownOption({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// A clean, modern dropdown selector widget
///
/// Example usage:
/// ```dart
/// DropdownSelector<int?>(
///   value: selectedValue,
///   hint: 'Select option',
///   options: [
///     DropdownOption(value: null, label: 'Not specified'),
///     DropdownOption(value: 1, label: '1 item'),
///     DropdownOption(value: 2, label: '2 items'),
///   ],
///   onChanged: (value) => setState(() => selectedValue = value),
/// )
/// ```
class DropdownSelector<T> extends StatelessWidget {
  /// Currently selected value
  final T value;

  /// Hint text shown when no value is selected (null)
  final String hint;

  /// List of options to display
  final List<DropdownOption<T>> options;

  /// Callback when selection changes
  final ValueChanged<T> onChanged;

  /// Optional leading icon
  final IconData? leadingIcon;

  /// Whether the dropdown is full width
  final bool isExpanded;

  const DropdownSelector({
    super.key,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.leadingIcon,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Find current label
    final currentOption = options.cast<DropdownOption<T>?>().firstWhere(
      (o) => o?.value == value,
      orElse: () => null,
    );
    final displayLabel = currentOption?.label ?? hint;
    final isDefault = currentOption == null;

    return PopupMenuButton<T>(
      onSelected: (newValue) {
        HapticFeedback.selectionClick();
        onChanged(newValue);
      },
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surface,
      itemBuilder: (context) => options.map((option) {
        final isSelected = option.value == value;

        return PopupMenuItem<T>(
          value: option.value,
          child: Row(
            children: [
              if (isSelected)
                Icon(Icons.check, size: 18, color: colorScheme.primary)
              else
                const SizedBox(width: 18),
              const SizedBox(width: 12),
              if (option.icon != null) ...[
                Icon(
                  option.icon,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  option.label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        width: isExpanded ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
            ],
            if (isExpanded)
              Expanded(
                child: Text(
                  displayLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: isDefault
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              )
            else
              Text(
                displayLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isDefault
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.onSurface,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
