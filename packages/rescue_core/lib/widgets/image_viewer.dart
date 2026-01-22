/// Image Viewer Widget
///
/// Full-screen image viewer with zoom and pan support using photo_view package.
/// Supports both single images and galleries with page indicators.
/// Features swipe-down-to-close gesture for a modern UX.
///
/// Usage:
///   showImageViewer(
///     context,
///     imageUrl: 'https://example.com/image.jpg',
///   );
///
///   showImageViewer(
///     context,
///     imageUrls: ['url1', 'url2', 'url3'],
///     initialIndex: 1,
///   );
///
/// Dialog-style viewer for avatars (WhatsApp/Facebook style):
///   showImageViewerDialog(
///     context,
///     imageUrl: 'https://example.com/avatar.jpg',
///   );

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

/// Show a single image in full-screen viewer
void showImageViewer(
  BuildContext context, {
  required String imageUrl,
  String? heroTag,
  VoidCallback? onSave,
  VoidCallback? onShare,
}) {
  showImageViewerGallery(
    context,
    imageUrls: [imageUrl],
    initialIndex: 0,
    heroTag: heroTag,
    onSave: onSave,
    onShare: onShare,
  );
}

/// Show a gallery of images in full-screen viewer
void showImageViewerGallery(
  BuildContext context, {
  required List<String> imageUrls,
  int initialIndex = 0,
  String? heroTag,
  VoidCallback? onSave,
  VoidCallback? onShare,
}) {
  if (imageUrls.isEmpty) return;

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => _ImageViewerPage(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
        heroTag: heroTag,
        onSave: onSave,
        onShare: onShare,
      ),
      fullscreenDialog: true,
    ),
  );
}

/// Show an image in a dialog overlay (WhatsApp/Facebook style)
/// Best for avatars and profile pictures
void showImageViewerDialog(
  BuildContext context, {
  required String imageUrl,
  String? heroTag,
}) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    barrierDismissible: true,
    builder: (dialogContext) =>
        _ImageViewerDialog(imageUrl: imageUrl, heroTag: heroTag),
  );
}

class _ImageViewerDialog extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const _ImageViewerDialog({required this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;
    final maxHeight = size.height * 0.8;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      shadowColor: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Centered image with zoom support
            Center(
              child: GestureDetector(
                onTap: () {}, // Prevent tap from propagating to parent
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: maxWidth,
                      maxHeight: maxHeight,
                    ),
                    color: Colors.grey[900],
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        width: maxWidth,
                        height: maxHeight * 0.6,
                        color: Colors.grey[900],
                        child: const Center(
                          child: CircularProgressIndicator.adaptive(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: maxWidth,
                        height: maxHeight * 0.6,
                        color: Colors.grey[900],
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: Colors.white70,
                                size: 48,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Failed to load image',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      imageBuilder: (context, imageProvider) => PhotoView(
                        imageProvider: imageProvider,
                        heroAttributes: heroTag != null
                            ? PhotoViewHeroAttributes(tag: heroTag!)
                            : null,
                        initialScale: PhotoViewComputedScale.contained,
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 2,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        tightMode: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageViewerPage extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const _ImageViewerPage({
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
    this.onSave,
    this.onShare,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;

  // Drag-to-close state
  double _dragOffset = 0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  static const double _dismissThreshold = 120;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _springController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _springController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() => _dragOffset += details.delta.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;

    if (_dragOffset.abs() > _dismissThreshold || velocity.abs() > 600) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop();
    } else {
      _animateBack();
    }
  }

  void _animateBack() {
    final startOffset = _dragOffset;
    _springController.reset();

    // Use spring curve for natural bounce-back
    _springAnimation = Tween<double>(begin: startOffset, end: 0).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.elasticOut,
      ),
    )..addListener(() {
        setState(() => _dragOffset = _springAnimation.value);
      });

    _springController.duration = const Duration(milliseconds: 400);
    _springController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isMultiple = widget.imageUrls.length > 1;
    final progress = (_dragOffset.abs() / 300).clamp(0.0, 1.0);
    final bgOpacity = 1.0 - progress;

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(bgOpacity),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: _GlassIconButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
        title: isMultiple
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1} of ${widget.imageUrls.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              )
            : null,
        centerTitle: true,
      ),
      body: GestureDetector(
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: [
            // Image gallery - simple vertical offset only
            Transform.translate(
              offset: Offset(0, _dragOffset),
              child: PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: widget.imageUrls.length,
                builder: (context, index) {
                  final imageUrl = widget.imageUrls[index];
                  final isHeroImage =
                      index == widget.initialIndex && widget.heroTag != null;

                  return PhotoViewGalleryPageOptions(
                    imageProvider: NetworkImage(imageUrl),
                    heroAttributes: isHeroImage
                        ? PhotoViewHeroAttributes(tag: widget.heroTag!)
                        : null,
                    initialScale: PhotoViewComputedScale.contained,
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_rounded,
                            color: Colors.white38,
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                onPageChanged: _onPageChanged,
                scrollPhysics: const BouncingScrollPhysics(),
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
              ),
            ),

            // Floating action bar
            if (widget.onSave != null || widget.onShare != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: (1.0 - progress * 2).clamp(0.0, 1.0),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Center(
                        child: _GlassActionBar(
                          onSave: widget.onSave,
                          onShare: widget.onShare,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Page indicators
            if (isMultiple)
              Positioned(
                bottom: (widget.onSave != null || widget.onShare != null)
                    ? 100
                    : 50,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: (1.0 - progress * 2).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.imageUrls.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        width: _currentIndex == index ? 20 : 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: _currentIndex == index
                              ? Colors.white
                              : Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Glass-style icon button for app bar
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 0.5,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Minimal floating action buttons
class _GlassActionBar extends StatelessWidget {
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  const _GlassActionBar({this.onSave, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onSave != null) ...[
          _CircleAction(
            icon: Icons.download_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onSave!();
            },
          ),
          const SizedBox(width: 16),
        ],
        if (onShare != null)
          _CircleAction(
            icon: Icons.ios_share_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              onShare!();
            },
          ),
      ],
    );
  }
}

/// Minimal circular action button
class _CircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: Colors.white24,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.12),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 0.5,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
