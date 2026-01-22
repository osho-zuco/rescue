import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:get_it/get_it.dart';

import '../services/google_places_service.dart';
import '../services/logger.dart';

/// Reusable widget for selecting a location with Google Places autocomplete
///
/// Features:
/// - Google Places autocomplete search field
/// - "Use My Current Location" button (icon in suffix)
/// - Displays selected location as removable card
/// - Clean, minimal UI matching app design system
/// - Configurable label text
class LocationInputWidget extends StatefulWidget {
  /// Initial address to display (for edit mode)
  final String? initialAddress;

  /// Initial latitude (for edit mode)
  final double? initialLatitude;

  /// Initial longitude (for edit mode)
  final double? initialLongitude;

  /// Callback when location is selected or cleared
  final Function(LocationData?) onLocationSelected;

  /// Error text to display below the field
  final String? errorText;

  /// Label shown above selected location (default: 'Selected Location')
  final String selectedLocationLabel;

  /// Hint text for the search field
  final String hintText;

  /// Countries to restrict search to (default: ['in'] for India)
  final List<String> countries;

  /// Debounce time in milliseconds (default: 600)
  final int debounceTime;

  const LocationInputWidget({
    super.key,
    this.initialAddress,
    this.initialLatitude,
    this.initialLongitude,
    required this.onLocationSelected,
    this.errorText,
    this.selectedLocationLabel = 'Selected Location',
    this.hintText = 'Search for your location',
    this.countries = const ['in'],
    this.debounceTime = 600,
  });

  @override
  State<LocationInputWidget> createState() => _LocationInputWidgetState();
}

class _LocationInputWidgetState extends State<LocationInputWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final _placesService = GetIt.I<GooglePlacesService>();

  LocationData? _selectedLocation;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill from initial values if provided
    if (widget.initialAddress != null &&
        widget.initialLatitude != null &&
        widget.initialLongitude != null) {
      _selectedLocation = LocationData(
        address: widget.initialAddress!,
        latitude: widget.initialLatitude!,
        longitude: widget.initialLongitude!,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);

    try {
      final result = await _placesService.getCurrentLocation();

      result.when(
        ok: (location) {
          if (mounted) {
            setState(() {
              _selectedLocation = location;
              _isLoadingCurrentLocation = false;
            });
            widget.onLocationSelected(location);

            Log.d(
              'Selected current location: ${location.address}',
              tag: 'LocationInput',
            );
          }
        },
        err: (error) {
          if (mounted) {
            setState(() => _isLoadingCurrentLocation = false);

            // Show user-friendly error message
            final message = error.contains('timeout')
                ? 'Location request timed out. Please try searching instead or enable location services.'
                : error.contains('permission')
                    ? 'Location permission required. Please enable in settings.'
                    : error;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }
  }

  void _handlePlaceSelected(Prediction prediction) {
    // Extract coordinates from prediction if available
    final lat =
        prediction.lat != null ? double.tryParse(prediction.lat!) : null;
    final lng =
        prediction.lng != null ? double.tryParse(prediction.lng!) : null;

    if (lat != null && lng != null) {
      final location = LocationData(
        address: prediction.description ?? '',
        latitude: lat,
        longitude: lng,
      );

      setState(() {
        _selectedLocation = location;
        _searchController.clear();
      });

      widget.onLocationSelected(location);

      Log.d('Selected place: ${location.address}', tag: 'LocationInput');
    } else {
      // Fallback: show error if coordinates not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to get location coordinates'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  void _handleRemoveLocation() {
    setState(() {
      _selectedLocation = null;
      _searchController.clear();
    });
    widget.onLocationSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show selected location as card
        if (_selectedLocation != null) ...[
          _buildSelectedLocationCard(theme, colorScheme),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                widget.errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            ),
        ]
        // Show search field if no location selected
        else
          _buildSearchField(theme, colorScheme),
      ],
    );
  }

  /// Build the selected location card (clean modern design)
  Widget _buildSelectedLocationCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Clean icon badge
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.location_on_rounded,
              size: 18,
              color: colorScheme.onPrimary,
            ),
          ),
          const SizedBox(width: 12),

          // Address text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.selectedLocationLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _selectedLocation!.address,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          // Remove button
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: _handleRemoveLocation,
            tooltip: 'Remove location',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Build the search field with autocomplete (clean modern design)
  Widget _buildSearchField(ThemeData theme, ColorScheme colorScheme) {
    return GooglePlaceAutoCompleteTextField(
      textEditingController: _searchController,
      focusNode: _searchFocusNode,
      googleAPIKey: GooglePlacesService.getApiKey(),
      inputDecoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
          fontSize: 15,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: colorScheme.onSurfaceVariant,
          size: 22,
        ),
        suffixIcon: _isLoadingCurrentLocation
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              )
            : IconButton(
                icon: Icon(
                  Icons.my_location_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                onPressed: _handleCurrentLocation,
                tooltip: 'Use current location',
              ),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        errorText: widget.errorText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      debounceTime: widget.debounceTime,
      countries: widget.countries,
      isLatLngRequired: true,
      getPlaceDetailWithLatLng: (prediction) {
        _handlePlaceSelected(prediction);
      },
      itemClick: (prediction) {
        _searchController.text = prediction.description ?? '';
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      },
      boxDecoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      seperatedBuilder: Divider(
        color: colorScheme.outline.withValues(alpha: 0.1),
        height: 1,
      ),
      containerHorizontalPadding: 0,
      itemBuilder: (context, index, prediction) {
        // Clean dropdown item design
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prediction.description ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
