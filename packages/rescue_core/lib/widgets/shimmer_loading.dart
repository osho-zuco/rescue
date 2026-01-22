import 'package:flutter/material.dart';

/// Shimmer Loading - Skeleton loading placeholder
///
/// Shows animated shimmer effect while content is loading.
///
/// Example:
/// ```dart
/// ShimmerLoading(
///   child: ShimmerCard(),
/// )
/// ```
class ShimmerLoading extends StatefulWidget {
  /// Child widget(s) to show shimmer effect on
  final Widget child;

  /// Whether shimmer is active
  final bool isLoading;

  /// Shimmer base color
  final Color? baseColor;

  /// Shimmer highlight color
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final colorScheme = Theme.of(context).colorScheme;
    final baseColor =
        widget.baseColor ?? colorScheme.surfaceContainerHighest;
    final highlightColor =
        widget.highlightColor ?? colorScheme.surface;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform(this.slidePercent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0, 0);
  }
}

/// Shimmer placeholder box
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Shimmer placeholder for a card
class ShimmerCard extends StatelessWidget {
  final double height;

  const ShimmerCard({
    super.key,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

/// Shimmer placeholder for merchant card
class ShimmerMerchantCard extends StatelessWidget {
  const ShimmerMerchantCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image
            const ShimmerBox(height: 160, borderRadius: 16),
            const SizedBox(height: 12),
            // Title
            const ShimmerBox(width: 180, height: 20),
            const SizedBox(height: 8),
            // Subtitle
            const ShimmerBox(width: 120, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Shimmer placeholder for list item
class ShimmerListItem extends StatelessWidget {
  final bool showAvatar;

  const ShimmerListItem({
    super.key,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            if (showAvatar) ...[
              const ShimmerBox(width: 48, height: 48, borderRadius: 24),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  ShimmerBox(
                    width: MediaQuery.of(context).size.width * 0.5,
                    height: 12,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Build a list of shimmer items
class ShimmerList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final EdgeInsets? padding;

  const ShimmerList({
    super.key,
    this.itemCount = 5,
    required this.itemBuilder,
    this.padding,
  });

  /// Create a shimmer list for merchant cards
  factory ShimmerList.merchantCards({int itemCount = 3}) {
    return ShimmerList(
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerMerchantCard(),
      padding: const EdgeInsets.all(16),
    );
  }

  /// Create a shimmer list for list items
  factory ShimmerList.listItems({int itemCount = 5, bool showAvatar = true}) {
    return ShimmerList(
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerListItem(showAvatar: showAvatar),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
    );
  }
}
