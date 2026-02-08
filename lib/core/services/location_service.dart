import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class LocationService {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Constants for Geofencing
  // Placeholder coordinates (Please update with real office coordinates)
  // Example: Diskominfo Padang (approximate)
  static const double officeLat = -0.924855; // Replace with actual
  static const double officeLong = 100.362624; // Replace with actual
  static const double radiusInMeters = 50.0;

  /// Check if location services are enabled and permissions are granted
  Future<bool> _handlePermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return false;
    }

    return true;
  }

  /// Get current position
  Future<Position?> getCurrentPosition() async {
    bool hasPermission = await _handlePermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calculate distance between two points in meters
  double calculateDistance(
    double startLat,
    double startLong,
    double endLat,
    double endLong,
  ) {
    return Geolocator.distanceBetween(startLat, startLong, endLat, endLong);
  }

  /// Check if user is within the office radius
  Future<bool> isWithinOfficeRadius() async {
    final position = await getCurrentPosition();
    if (position == null) return false; // Default to false if no location

    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      officeLat,
      officeLong,
    );

    return distance <= radiusInMeters;
  }

  Future<String> getAddressFromCoordinates(double lat, double long) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Format: "Jl. Khatib Sulaiman, Padang Utara"
        // Adjust fields as needed for best output.
        // locality usually gives City (Kota Padang)
        // subLocality gives District (Padang Utara)
        // thoroughfare gives Street (Jl. Khatib Sulaiman)

        List<String> parts = [];
        if (place.thoroughfare != null && place.thoroughfare!.isNotEmpty) {
          parts.add(place.thoroughfare!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          parts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          parts.add(place.locality!);
        }

        if (parts.isEmpty) return "Lokasi: $lat, $long";

        return parts.take(2).join(', '); // Keep it short: Street, District
      }
      return "Alamat tidak ditemukan";
    } catch (e) {
      debugPrint("Geocoding Error: $e");
      // Fallback to coordinates if geocoding fails (common on some emulators)
      return "${lat.toStringAsFixed(5)}, ${long.toStringAsFixed(5)}";
    }
  }
}
