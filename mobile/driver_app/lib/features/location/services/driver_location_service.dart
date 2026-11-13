import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/api_service.dart';

class DriverLocationService {
  static Timer? _timer;
  static int? _driverId;
  static bool _isSending = false;

  static Future<void> ensurePermission() async {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception('Please enable your phone location service.');
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Location permission was denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission is permanently denied. Enable it in app settings.',
      );
    }
  }

  static Future<void> startTracking(int driverId) async {
    if (_driverId == driverId && _timer != null) return;

    await stopTracking();

    _driverId = driverId;

    // Send the first location immediately.
    await _sendLocation();

    // Continue updating every 10 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _sendLocation(),
    );
  }

  static Future<void> _sendLocation() async {
    if (_isSending || _driverId == null) return;

    _isSending = true;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await ApiService.patch(
        '/drivers/$_driverId/location',
        body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
    } catch (e) {
      debugPrint('Driver location update failed: $e');
    } finally {
      _isSending = false;
    }
  }

  static Future<void> stopTracking() async {
    _timer?.cancel();
    _timer = null;
    _driverId = null;
  }
}