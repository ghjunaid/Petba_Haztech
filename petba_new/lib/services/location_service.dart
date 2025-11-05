import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {

  // Check if location permissions are granted
  static Future<bool> checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  // Get current location and convert to readable address
  static Future<LocationResult> getCurrentLocation() async {
    try {
      print("Starting location fetch...");

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print("Location service enabled: $serviceEnabled");

      if (!serviceEnabled) {
        print("Location services disabled");
        return LocationResult(
            success: false,
            error: LocationError.serviceDisabled,
            message: 'Location services are disabled'
        );
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      print("Initial permission status: $permission");

      if (permission == LocationPermission.denied) {
        print("Requesting permission...");
        permission = await Geolocator.requestPermission();
        print("Permission after request: $permission");

        if (permission == LocationPermission.denied) {
          print("Permission denied");
          return LocationResult(
              success: false,
              error: LocationError.permissionDenied,
              message: 'Location permission denied'
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("Permission permanently denied");
        return LocationResult(
            success: false,
            error: LocationError.permissionPermanentlyDenied,
            message: 'Location permission permanently denied'
        );
      }

      print("Permissions OK, getting position...");

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15), // Increased timeout
      );

      print("Got position: ${position.latitude}, ${position.longitude}");

      // Get address from coordinates with better formatting
      print("Getting address from coordinates...");
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // Print all available placemark data for debugging
        print("=== PLACEMARK DEBUG INFO ===");
        print("Name: ${place.name}");
        print("Street: ${place.street}");
        print("SubLocality: ${place.subLocality}");
        print("Locality: ${place.locality}");
        print("SubAdministrativeArea: ${place.subAdministrativeArea}");
        print("AdministrativeArea: ${place.administrativeArea}");
        print("PostalCode: ${place.postalCode}");
        print("Country: ${place.country}");
        print("============================");

        String address = _formatAddressWithLandmarks(place);
        print("Final formatted address: $address");

        return LocationResult(
          success: true,
          address: address,
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }

      print("No placemarks found, using fallback");
      return LocationResult(
        success: true,
        address: 'Current Location',
        latitude: position.latitude,
        longitude: position.longitude,
      );

    } catch (e) {
      print("Error in getCurrentLocation: $e");
      return LocationResult(
          success: false,
          error: LocationError.unknown,
          message: 'Error getting location: $e'
      );
    }
  }

  // Enhanced address formatting with landmarks and proper hierarchy
  static String _formatAddressWithLandmarks(Placemark place) {
    List<String> addressParts = [];

    // Priority 1: Landmark or Point of Interest (name field often contains this)
    if (place.name != null && place.name!.isNotEmpty &&
        place.name != place.street &&
        place.name != place.locality &&
        !_isCoordinateString(place.name!)) {
      addressParts.add(place.name!);
    }

    // Priority 2: Street address
    if (place.street != null && place.street!.isNotEmpty &&
        !_isCoordinateString(place.street!) &&
        place.street != place.name) {
      addressParts.add(place.street!);
    }

    // Priority 3: SubLocality (neighborhood/area)
    if (place.subLocality != null && place.subLocality!.isNotEmpty &&
        !addressParts.contains(place.subLocality)) {
      addressParts.add(place.subLocality!);
    }

    // Priority 4: Locality (city/town)
    if (place.locality != null && place.locality!.isNotEmpty &&
        !addressParts.contains(place.locality)) {
      addressParts.add(place.locality!);
    }

    // Priority 5: Administrative Area (state) - only if we have less than 3 parts
    if (addressParts.length < 3 &&
        place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty &&
        !addressParts.contains(place.administrativeArea)) {
      addressParts.add(place.administrativeArea!);
    }

    // If we still don't have good address parts, try alternatives
    if (addressParts.isEmpty || addressParts.length == 1) {
      // Try subAdministrativeArea (district)
      if (place.subAdministrativeArea != null &&
          place.subAdministrativeArea!.isNotEmpty &&
          !addressParts.contains(place.subAdministrativeArea)) {
        addressParts.add(place.subAdministrativeArea!);
      }

      // Add locality if not already added
      if (place.locality != null && place.locality!.isNotEmpty &&
          !addressParts.contains(place.locality)) {
        addressParts.add(place.locality!);
      }

      // Add administrative area if not already added
      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty &&
          !addressParts.contains(place.administrativeArea)) {
        addressParts.add(place.administrativeArea!);
      }
    }

    // Final fallback - if still empty, create a basic location string
    if (addressParts.isEmpty) {
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      } else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      } else {
        return 'Current Location';
      }
    }

    // Join the parts and clean up
    String result = addressParts.join(', ');

    // Remove any redundant commas or spaces
    result = result.replaceAll(RegExp(r',\s*,'), ', ');
    result = result.replaceAll(RegExp(r'^\s*,\s*'), '');
    result = result.replaceAll(RegExp(r',\s*$'), '');

    return result.isNotEmpty ? result : 'Current Location';
  }

  // Helper method to check if a string looks like coordinates
  static bool _isCoordinateString(String text) {
    // Check if the string looks like coordinates (contains numbers and dots/commas)
    RegExp coordPattern = RegExp(r'^\d+\.\d+,?\s*\d*\.?\d*$');
    return coordPattern.hasMatch(text.replaceAll(' ', ''));
  }

  // Alternative method to get more detailed location info
  static Future<LocationResult> getCurrentLocationDetailed() async {
    try {
      // First get basic location
      LocationResult basicResult = await getCurrentLocation();

      if (!basicResult.success || basicResult.latitude == null || basicResult.longitude == null) {
        return basicResult;
      }

      // Try to get more detailed address using multiple API calls if needed
      print("Getting detailed location info...");

      List<Placemark> placemarks = await placemarkFromCoordinates(
        basicResult.latitude!,
        basicResult.longitude!,
      );

      if (placemarks.isNotEmpty) {
        // Try different placemarks to find the best one
        String? bestAddress;

        for (Placemark place in placemarks.take(3)) { // Check first 3 placemarks
          String testAddress = _formatAddressWithLandmarks(place);
          if (testAddress != 'Current Location' &&
              !_isCoordinateString(testAddress) &&
              testAddress.split(',').length >= 2) {
            bestAddress = testAddress;
            break;
          }
        }

        return LocationResult(
          success: true,
          address: bestAddress ?? basicResult.address ?? 'Current Location',
          latitude: basicResult.latitude,
          longitude: basicResult.longitude,
        );
      }

      return basicResult;

    } catch (e) {
      print("Error in detailed location: $e");
      return await getCurrentLocation(); // Fallback to basic method
    }
  }

  // Get coordinates from address (geocoding)
  static Future<LocationResult> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        Location location = locations[0];
        return LocationResult(
          success: true,
          address: address,
          latitude: location.latitude,
          longitude: location.longitude,
        );
      }

      return LocationResult(
          success: false,
          error: LocationError.addressNotFound,
          message: 'Could not find coordinates for the address'
      );
    } catch (e) {
      return LocationResult(
          success: false,
          error: LocationError.unknown,
          message: 'Error geocoding address: $e'
      );
    }
  }

  // Show location error dialogs
  static void showLocationErrorDialog(BuildContext context, LocationError error) {
    String title = '';
    String message = '';
    List<Widget> actions = [];

    switch (error) {
      case LocationError.serviceDisabled:
        title = 'Location Services Disabled';
        message = 'Please enable location services in your device settings to use this feature.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ];
        break;

      case LocationError.permissionDenied:
        title = 'Permission Denied';
        message = 'Location permission is required to get your current location.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ];
        break;

      case LocationError.permissionPermanentlyDenied:
        title = 'Permission Required';
        message = 'Location permission has been permanently denied. Please enable it in app settings.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text('Open Settings', style: TextStyle(color: Colors.blue)),
          ),
        ];
        break;

      default:
        title = 'Error';
        message = 'An error occurred while getting your location. Please try again.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: Colors.blue)),
          ),
        ];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          title: Text(title, style: TextStyle(color: Colors.white)),
          content: Text(message, style: TextStyle(color: Colors.grey)),
          actions: actions,
        );
      },
    );
  }
}

// Result class for location operations
class LocationResult {
  final bool success;
  final String? address;
  final double? latitude;
  final double? longitude;
  final LocationError? error;
  final String? message;

  LocationResult({
    required this.success,
    this.address,
    this.latitude,
    this.longitude,
    this.error,
    this.message,
  });
}

// Enum for different types of location errors
enum LocationError {
  serviceDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  addressNotFound,
  unknown,
}