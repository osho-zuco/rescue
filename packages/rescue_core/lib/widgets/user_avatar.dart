// User Avatar Widget
//
// Reusable widget for displaying user profile pictures with consistent fallback behavior.
// Supports both circular and custom border radius avatars.
//
// Usage:
//   UserAvatar(
//     photoUrl: user.photoUrl,
//     name: user.name,
//     radius: 36,
//   )
//
//   UserAvatar(
//     photoUrl: message.senderPhotoUrl,
//     name: message.senderName,
//     radius: 18,
//     showImageViewerOnTap: false, // Disable image viewer
//   )
//
//   UserAvatar(
//     photoUrl: reviewer.photoUrl,
//     name: reviewer.name,
//     size: 48, // Use size for non-circular avatars
//     borderRadius: 12,
//   )

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../widgets/image_viewer.dart' show showImageViewerDialog;

class UserAvatar extends StatelessWidget {
  /// User's photo URL
  final String? photoUrl;

  /// User's name (for fallback initial)
  final String? name;

  /// Radius for circular avatar (CircleAvatar)
  final double? radius;

  /// Size for square/rounded avatar (Container)
  final double? size;

  /// Border radius for non-circular avatars (when using size)
  final double? borderRadius;

  /// Background color for placeholder
  final Color? backgroundColor;

  /// Text/icon color for placeholder
  final Color? foregroundColor;

  /// Whether to use CircleAvatar (true) or Container (false)
  final bool circular;

  /// Whether tapping the avatar should open the image viewer
  final bool showImageViewerOnTap;

  /// Custom placeholder widget (overrides name initial)
  final Widget? placeholder;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.name,
    this.radius,
    this.size,
    this.borderRadius,
    this.backgroundColor,
    this.foregroundColor,
    this.circular = true,
    this.showImageViewerOnTap = true,
    this.placeholder,
  }) : assert(
         radius != null || size != null,
         'Either radius or size must be provided',
       );

  /// Get the first character of the name for fallback
  String _getInitial() {
    if (name == null || name!.isEmpty) return '?';
    return name![0].toUpperCase();
  }

  /// Check if we have a valid photo URL
  bool get _hasPhotoUrl => photoUrl != null && photoUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = foregroundColor ?? colorScheme.onPrimaryContainer;

    if (circular && radius != null) {
      // Calculate cache size based on device pixel ratio for memory efficiency
      final pixelRatio = MediaQuery.of(context).devicePixelRatio;
      final cacheSize = (radius! * 2 * pixelRatio).round();

      // Use CircleAvatar
      final circleAvatar = CircleAvatar(
        radius: radius!,
        backgroundColor: bgColor,
        backgroundImage: _hasPhotoUrl
            ? CachedNetworkImageProvider(
                photoUrl!,
                maxWidth: cacheSize,
                maxHeight: cacheSize,
              )
            : null,
        child: !_hasPhotoUrl
            ? (placeholder ??
                Text(
                  _getInitial(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: fgColor,
                    fontWeight: FontWeight.w500,
                  ),
                ))
            : null,
      );

      if (showImageViewerOnTap && _hasPhotoUrl) {
        return GestureDetector(
          onTap: () {
            showImageViewerDialog(context, imageUrl: photoUrl!);
          },
          child: circleAvatar,
        );
      }
      return circleAvatar;
    }

    // Use Container with ClipRRect for non-circular or custom size
    final avatarSize = size ?? (radius != null ? radius! * 2 : 48);
    final borderRadiusValue =
        borderRadius ??
        (circular
            ? avatarSize / 2
            : 12); // Default to circular if circular=true

    // Calculate cache size based on device pixel ratio for memory efficiency
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final cacheSize = (avatarSize * pixelRatio).round();

    final avatarChild = _hasPhotoUrl
        ? ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusValue),
            child: CachedNetworkImage(
              imageUrl: photoUrl!,
              fit: BoxFit.cover,
              width: avatarSize,
              height: avatarSize,
              memCacheWidth: cacheSize,
              memCacheHeight: cacheSize,
              placeholder: (context, url) => Container(
                width: avatarSize,
                height: avatarSize,
                color: bgColor,
                child: Center(
                  child: SizedBox(
                    width: avatarSize * 0.4,
                    height: avatarSize * 0.4,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: fgColor,
                    ),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                width: avatarSize,
                height: avatarSize,
                color: bgColor,
                child: Center(
                  child: placeholder ??
                      Text(
                        _getInitial(),
                        style: TextStyle(
                          fontSize: avatarSize * 0.4,
                          color: fgColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ),
            ),
          )
        : Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(borderRadiusValue),
            ),
            child: Center(
              child: placeholder ??
                  Text(
                    _getInitial(),
                    style: TextStyle(
                      fontSize: avatarSize * 0.4,
                      color: fgColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            ),
          );

    if (showImageViewerOnTap && _hasPhotoUrl) {
      return GestureDetector(
        onTap: () {
          showImageViewerDialog(context, imageUrl: photoUrl!);
        },
        child: avatarChild,
      );
    }
    return avatarChild;
  }
}
