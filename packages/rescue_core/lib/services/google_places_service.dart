import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:get_it/get_it.dart';

import '../config/env_config.dart';
import '../error/result.dart';
import 'location_service.dart';
import 'logger.dart';

/// Service for Google Places autocomplete and location services
///
/// Features:
/// - Search places with autocomplete
/// - Get place details (address + coordinates)
/// - Reverse geocode coordinates to address (delegates to LocationService)
/// - Get current device location (delegates to LocationService)
class GooglePlacesService {
  final _locationService = GetIt.I<LocationService>();

  /// Search for places matching the query
  /// Returns list of place predictions for autocomplete
  Future<Result<List<Prediction>, String>> searchPlaces(String query) async {
    try {
      if (query.isEmpty) {
        return Ok([]);
      }

      // Note: The google_places_flutter package handles API calls internally
      // We just need to provide the query
      // The actual API call is made by the GooglePlaceAutoCompleteTextField widget

      Log.d('Searching places: $query', tag: 'GooglePlacesService');

      // For now, return empty list as the widget handles this internally
      // If we need to make direct API calls, we'd use the Places API REST endpoint
      return Ok([]);
    } catch (e, stackTrace) {
      Log.e(
        'Failed to search places',
        tag: 'GooglePlacesService',
        error: e,
        stackTrace: stackTrace,
      );
      return Err('Failed to search places');
    }
  }

  /// Get current device location with address
  /// Optimized for speed - uses cached location first
  Future<Result<LocationData, String>> getCurrentLocation() async {
    // Get position using shared LocationService
    // Strategy: Try last known first (instant), then low accuracy (fast)
    final positionResult = await _locationService.getCurrentPosition(
      accuracy: LocationAccuracy.low, // Faster, good enough for neighborhood
      timeoutSeconds: 15, // Longer timeout for slow GPS
      useLastKnown: true, // Use cached location for instant result
    );

    return positionResult.when(
      ok: (position) async {
        // Reverse geocode to get address (area-level only for hosting location)
        final addressResult = await _locationService.reverseGeocode(
          latitude: position.latitude,
          longitude: position.longitude,
          includeStreetAddress: false, // Skip building details for hosting
        );

        final address = addressResult.when(
          ok: (addr) => addr,
          err: (_) => 'Unknown location', // Graceful fallback
        );

        return Ok(
          LocationData(
            latitude: position.latitude,
            longitude: position.longitude,
            address: address,
          ),
        );
      },
      err: (error) => Err(error),
    );
  }

  /// Extract city and state from a place
  Future<Result<PlaceDetails, String>> getPlaceDetails(String placeId) async {
    try {
      // For google_places_flutter package, place details are returned
      // with the prediction when selected
      // This method is here for future use if needed
      Log.d('Getting place details: $placeId', tag: 'GooglePlacesService');
      return Err('Not implemented - use prediction data directly');
    } catch (e, stackTrace) {
      Log.e(
        'Failed to get place details',
        tag: 'GooglePlacesService',
        error: e,
        stackTrace: stackTrace,
      );
      return Err('Failed to get place details');
    }
  }

  /// Get API key for current platform
  static String getApiKey() {
    final config = EnvConfig.instance;

    // Return platform-specific key
    final key = Platform.isAndroid
        ? config.googlePlacesApiKeyAndroid
        : config.googlePlacesApiKeyIos;

    // Warn if missing (helpful in development)
    if (key.isEmpty) {
      Log.w(
        'Google Places API key not configured for ${Platform.operatingSystem}. '
        'Set via --dart-define=GOOGLE_PLACES_API_KEY_${Platform.isAndroid ? 'ANDROID' : 'IOS'}_${config.environment.name.toUpperCase()}',
        tag: 'GooglePlacesService',
      );
    }

    return key;
  }
}

/// Location data with coordinates and address
class LocationData {
  final double latitude;
  final double longitude;
  final String address;
  final String? city;
  final String? state;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.city,
    this.state,
  });
}

/// Place details with address components
class PlaceDetails {
  final String address;
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? postalCode;

  PlaceDetails({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.postalCode,
  });
}
