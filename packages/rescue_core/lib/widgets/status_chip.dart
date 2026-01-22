import 'package:flutter/material.dart';

/// Status Chip - Badge for verification, subscription status, etc.
///
/// Shows a small chip indicating status with icon and label.
///
/// Example:
/// ```dart
/// StatusChip.verified()
/// StatusChip.active()
/// StatusChip.custom(
///   label: 'Premium',
///   icon: Icons.star,
///   color: Colors.amber,
/// )
/// ```
class StatusChip extends StatelessWidget {
  /// Chip label
  final String label;

  /// Chip icon
  final IconData? icon;

  /// Chip color
  final Color color;

  /// Whether to use outlined style
  final bool outlined;

  /// Size variant
  final StatusChipSize size;

  const StatusChip({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.outlined = false,
    this.size = StatusChipSize.small,
  });

  /// Verified status chip
  factory StatusChip.verified({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Verified',
      icon: Icons.verified_rounded,
      color: Colors.blue,
      size: size,
    );
  }

  /// Active status chip
  factory StatusChip.active({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Active',
      icon: Icons.check_circle_rounded,
      color: Colors.green,
      size: size,
    );
  }

  /// Inactive status chip
  factory StatusChip.inactive({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Inactive',
      icon: Icons.cancel_rounded,
      color: Colors.grey,
      size: size,
      outlined: true,
    );
  }

  /// Pending status chip
  factory StatusChip.pending({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Pending',
      icon: Icons.schedule_rounded,
      color: Colors.orange,
      size: size,
    );
  }

  /// Trial status chip
  factory StatusChip.trial({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Trial',
      icon: Icons.hourglass_top_rounded,
      color: Colors.purple,
      size: size,
    );
  }

  /// Expired status chip
  factory StatusChip.expired({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Expired',
      icon: Icons.error_rounded,
      color: Colors.red,
      size: size,
    );
  }

  /// New status chip
  factory StatusChip.isNew({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'New',
      icon: Icons.fiber_new_rounded,
      color: Colors.teal,
      size: size,
    );
  }

  /// Premium status chip
  factory StatusChip.premium({StatusChipSize size = StatusChipSize.small}) {
    return StatusChip(
      label: 'Premium',
      icon: Icons.workspace_premium_rounded,
      color: Colors.amber.shade700,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (horizontalPadding, verticalPadding, iconSize, fontSize) =
        switch (size) {
      StatusChipSize.small => (8.0, 4.0, 12.0, 10.0),
      StatusChipSize.medium => (10.0, 6.0, 14.0, 12.0),
      StatusChipSize.large => (12.0, 8.0, 16.0, 14.0),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: color, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(width: size == StatusChipSize.small ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Size variants for StatusChip
enum StatusChipSize {
  small,
  medium,
  large,
}

/// Simple dot status indicator
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool pulsing;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.pulsing = false,
  });

  factory StatusDot.online() => const StatusDot(color: Colors.green);
  factory StatusDot.offline() => const StatusDot(color: Colors.grey);
  factory StatusDot.busy() => const StatusDot(color: Colors.red);
  factory StatusDot.away() => const StatusDot(color: Colors.orange);

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (!pulsing) return dot;

    return _PulsingDot(color: color, size: size);
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  final double size;

  const _PulsingDot({required this.color, required this.size});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
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

    _animation = Tween<double>(begin: 1, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size * _animation.value,
          height: widget.size * _animation.value,
          decoration: BoxDecoration(
            color: widget.color
                .withValues(alpha: 1.5 - _animation.value), // Fade as it grows
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}
