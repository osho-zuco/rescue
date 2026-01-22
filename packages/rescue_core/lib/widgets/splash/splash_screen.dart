import 'package:flutter/material.dart';
import 'animated_logo.dart';

/// Splash Screen Content - Shared Widget
///
/// Customizable splash screen used by both merchant and user apps.
/// Parent handles BLoC integration and navigation.
class SplashScreenContent extends StatelessWidget {
  /// Icon to show in animated logo
  final IconData logoIcon;

  /// Badge text for logo (null = no badge)
  final String? badgeText;

  /// Tagline text below logo
  final String tagline;

  const SplashScreenContent({
    super.key,
    required this.logoIcon,
    required this.tagline,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        // Fill entire screen
        width: double.infinity,
        height: double.infinity,
        // Gradient background (coral to mint)
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top spacer (pushes content down)
              const Spacer(flex: 3),

              // Animated logo
              AnimatedLogo(
                icon: logoIcon,
                badgeText: badgeText,
              ),

              const SizedBox(height: 16),

              // Tagline (fades in after logo)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                builder: (context, value, child) {
                  return Opacity(opacity: value, child: child);
                },
                child: Text(
                  tagline,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Bottom spacer (fills remaining space)
              const Spacer(flex: 4),

              // Loading indicator
              _LoadingIndicator(),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// Subtle loading indicator
class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeIn,
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator.adaptive(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            colorScheme.primary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

/// Default SplashScreen wrapper with Druto branding
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreenContent(
      logoIcon: Icons.pets,
      tagline: 'Loyalty rewards made simple',
    );
  }
}
