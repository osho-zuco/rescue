import 'package:flutter/material.dart';

/// Animated Druto Logo - Shared Widget
///
/// Fades in and scales up when the widget first builds.
/// Uses TweenAnimationBuilder for a simple one-shot animation.
///
/// Customizable for merchant vs user apps via props.
class AnimatedLogo extends StatelessWidget {
  /// Icon to display in the logo circle
  final IconData icon;

  /// Badge text to show below logo (null = no badge)
  final String? badgeText;

  /// Duration of the entrance animation
  final Duration duration;

  /// Delay before animation starts
  final Duration delay;

  const AnimatedLogo({
    super.key,
    required this.icon,
    this.badgeText,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOutBack, // Slight overshoot for polish
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + (value * 0.5), // Start at 50%, end at 100%
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo icon (gradient circle)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // App name
          Text(
            'Druto',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: 2,
                ),
          ),

          // Optional badge (e.g., "FOR MERCHANTS")
          if (badgeText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                badgeText!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
