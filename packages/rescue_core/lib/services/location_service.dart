import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../error/result.dart';
import 'logger.dart';

/// Centralized location service for permission handling and position fetching
///
/// Used by:
/// - LocationRepository (for user location in search/home)
/// - GooglePlacesService (for "Use Current Location" in hosting address)
class LocationService {
  static const String _tag = 'LocationService';

  /// Check location permission status
  Future<LocationPermissionStatus> checkPermission() async {
    final permission = await Geolocator.checkPermission();
    return _mapPermission(permission);
  }

  /// Request location permission
  Future<LocationPermissionStatus> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return _mapPermission(permission);
  }

  /// Check if location services are enabled
  Future<bool> isServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  /// Get current position with configurable accuracy
  ///
  /// [accuracy] - LocationAccuracy level (low for speed, medium for balance)
  /// [timeoutSeconds] - Max time to wait for position (15s recommended for first GPS fix)
  /// [useLastKnown] - Try last known position first (faster, may be stale)
  ///
  /// Performance tips:
  /// - Use `useLastKnown: true` for instant results (good for approximate location)
  /// - Use `LocationAccuracy.low` for faster GPS lock (~1-3s vs 5-10s for medium/high)
  /// - First GPS fix after reboot can take 20-30s, always use lastKnown when possible
  ///
  /// Returns Result with Position or error message
  Future<Result<Position, String>> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.low,
    int timeoutSeconds = 15,
    bool useLastKnown = true,
  }) async {
    try {
      // Check if services are enabled
      final serviceEnabled = await isServiceEnabled();
      if (!serviceEnabled) {
        return Err('Location services disabled. Please enable in settings.');
      }

      // Check permission
      final permission = await checkPermission();
      if (permission == LocationPermissionStatus.denied) {
        // Try to request permission
        final requested = await requestPermission();
        if (requested == LocationPermissionStatus.denied ||
            requested == LocationPermissionStatus.deniedForever) {
          return Err('Location permission denied');
        }
      } else if (permission == LocationPermissionStatus.deniedForever) {
        return Err(
          'Location permission permanently denied. Enable in settings.',
        );
      }

      // Try last known position first if requested (instant, may be null)
      if (useLastKnown) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            Log.d(
              'Using last known position: ${lastKnown.latitude}, ${lastKnown.longitude}',
              tag: _tag,
            );
            return Ok(lastKnown);
          }
        } catch (e) {
          Log.w('getLastKnownPosition failed: $e', tag: _tag);
          // Continue to get fresh position
        }
      }

      // Get fresh position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: accuracy,
          timeLimit: Duration(seconds: timeoutSeconds),
        ),
      );

      Log.d(
        'Got current position: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)',
        tag: _tag,
      );

      return Ok(position);
    } on LocationServiceDisabledException {
      return Err('Location services disabled. Please enable in settings.');
    } on PermissionDeniedException {
      return Err('Location permission denied');
    } catch (e, stackTrace) {
      Log.e(
        'Failed to get current position',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return Err('Could not get your location. Please try again.');
    }
  }

  /// Reverse geocode coordinates to human-readable address
  ///
  /// [includeStreetAddress] - Include building/street details (default: true)
  ///   - true: "No. 10, Koramangala, Bangalore" (for navigation/delivery)
  ///   - false: "Koramangala, Bangalore" (for general area selection)
  ///
  /// Returns formatted address string
  Future<Result<String, String>> reverseGeocode({
    required double latitude,
    required double longitude,
    bool includeStreetAddress = true,
  }) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return Err('No address found for location');
      }

      final place = placemarks.first;

      // Build address from placemark components
      final parts = <String>[];

      // Include specific building/street address only if requested
      if (includeStreetAddress &&
          place.name != null &&
          place.name!.isNotEmpty) {
        parts.add(place.name!);
      }

      // Always include neighborhood and broader areas
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        parts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }
      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty) {
        parts.add(place.administrativeArea!);
      }

      final address = parts.join(', ');

      Log.d('Reverse geocoded: $address', tag: _tag);

      return Ok(address.isNotEmpty ? address : 'Unknown location');
    } catch (e, stackTrace) {
      Log.e(
        'Failed to reverse geocode',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return Err('Failed to get address');
    }
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return Geolocator.openLocationSettings();
  }

  /// Open app settings
  Future<bool> openAppSettings() async {
    return Geolocator.openAppSettings();
  }

  /// Map geolocator permission to our enum
  LocationPermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.denied:
        return LocationPermissionStatus.denied;
      case LocationPermission.deniedForever:
        return LocationPermissionStatus.deniedForever;
      case LocationPermission.whileInUse:
        return LocationPermissionStatus.whileInUse;
      case LocationPermission.always:
        return LocationPermissionStatus.always;
      case LocationPermission.unableToDetermine:
        return LocationPermissionStatus.notDetermined;
    }
  }
}

/// Location permission status
enum LocationPermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
  notDetermined,
}
