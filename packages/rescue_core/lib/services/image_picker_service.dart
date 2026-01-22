/// Image Picker Service
///
/// Centralized service for picking images from camera or gallery.
/// Handles permission requests, compression, and error handling.
///
/// Usage:
/// ```dart
/// final service = getIt<ImagePickerService>();
/// final path = await service.showPickerSheet(context);
/// if (path != null) {
///   // Use the image path
/// }
/// ```

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// Configuration for image picking
class ImagePickerConfig {
  /// Max dimension for camera photos (smaller = faster upload)
  final double cameraMaxDimension;

  /// Max dimension for gallery photos
  final double galleryMaxDimension;

  /// JPEG quality for camera (0-100)
  final int cameraQuality;

  /// JPEG quality for gallery (0-100)
  final int galleryQuality;

  /// Preferred camera (front/rear)
  final CameraDevice preferredCamera;

  /// Whether to show remove option when photo exists
  final bool showRemoveOption;

  const ImagePickerConfig({
    this.cameraMaxDimension = 800.0,
    this.galleryMaxDimension = 1200.0,
    this.cameraQuality = 70,
    this.galleryQuality = 85,
    this.preferredCamera = CameraDevice.rear,
    this.showRemoveOption = false,
  });

  /// Default config for profile photos (front camera, smaller size)
  static const profile = ImagePickerConfig(
    cameraMaxDimension: 800.0,
    galleryMaxDimension: 1200.0,
    cameraQuality: 70,
    galleryQuality: 85,
    preferredCamera: CameraDevice.front,
  );

  /// Default config for home/environment photos (rear camera)
  static const homePhotos = ImagePickerConfig(
    cameraMaxDimension: 800.0,
    galleryMaxDimension: 1200.0,
    cameraQuality: 70,
    galleryQuality: 85,
    preferredCamera: CameraDevice.rear,
  );

  /// Create a copy with some fields overridden
  ImagePickerConfig copyWith({
    double? cameraMaxDimension,
    double? galleryMaxDimension,
    int? cameraQuality,
    int? galleryQuality,
    CameraDevice? preferredCamera,
    bool? showRemoveOption,
  }) {
    return ImagePickerConfig(
      cameraMaxDimension: cameraMaxDimension ?? this.cameraMaxDimension,
      galleryMaxDimension: galleryMaxDimension ?? this.galleryMaxDimension,
      cameraQuality: cameraQuality ?? this.cameraQuality,
      galleryQuality: galleryQuality ?? this.galleryQuality,
      preferredCamera: preferredCamera ?? this.preferredCamera,
      showRemoveOption: showRemoveOption ?? this.showRemoveOption,
    );
  }
}

/// Result of image picking operation
sealed class ImagePickerResult {}

/// Successfully picked an image
class ImagePicked extends ImagePickerResult {
  final String path;
  ImagePicked(this.path);
}

/// User cancelled the picker
class ImagePickerCancelled extends ImagePickerResult {}

/// User chose to remove existing photo
class ImageRemoved extends ImagePickerResult {}

/// Error occurred during picking
class ImagePickerError extends ImagePickerResult {
  final String message;
  ImagePickerError(this.message);
}

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  /// Show bottom sheet with camera/gallery options and pick image
  ///
  /// Returns [ImagePickerResult]:
  /// - [ImagePicked] with path if image was selected
  /// - [ImagePickerCancelled] if user dismissed
  /// - [ImageRemoved] if user chose to remove existing photo
  /// - [ImagePickerError] if something went wrong
  Future<ImagePickerResult> showPickerSheet(
    BuildContext context, {
    ImagePickerConfig config = const ImagePickerConfig(),
    bool hasExistingPhoto = false,
  }) async {
    final source = await showModalBottomSheet<_PickerAction>(
      context: context,
      builder: (ctx) => _PickerBottomSheet(
        showRemove: hasExistingPhoto && config.showRemoveOption,
      ),
    );

    if (source == null) return ImagePickerCancelled();

    if (source == _PickerAction.remove) return ImageRemoved();

    final imageSource = source == _PickerAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    return pickImage(imageSource, config: config);
  }

  /// Pick image directly from specified source
  Future<ImagePickerResult> pickImage(
    ImageSource source, {
    ImagePickerConfig config = const ImagePickerConfig(),
  }) async {
    try {
      final maxDimension = source == ImageSource.camera
          ? config.cameraMaxDimension
          : config.galleryMaxDimension;
      final quality = source == ImageSource.camera
          ? config.cameraQuality
          : config.galleryQuality;

      final image = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        imageQuality: quality,
        preferredCameraDevice: config.preferredCamera,
      );

      if (image == null) return ImagePickerCancelled();

      HapticFeedback.lightImpact();
      return ImagePicked(image.path);
    } on PlatformException catch (e) {
      return ImagePickerError(e.message ?? 'Permission denied');
    } catch (e) {
      return ImagePickerError('Failed to pick image');
    }
  }
}

enum _PickerAction { camera, gallery, remove }

class _PickerBottomSheet extends StatelessWidget {
  final bool showRemove;

  const _PickerBottomSheet({required this.showRemove});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () => Navigator.pop(context, _PickerAction.camera),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select an existing photo'),
              onTap: () => Navigator.pop(context, _PickerAction.gallery),
            ),
            if (showRemove)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                title: const Text('Remove Photo'),
                onTap: () => Navigator.pop(context, _PickerAction.remove),
              ),
          ],
        ),
      ),
    );
  }
}
