import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int bookingId;

  const LiveTrackingScreen({super.key, required this.bookingId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  Map<String, dynamic>? _driver;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshing = false;

  // Used only until the first valid driver coordinate is received.
  static const LatLng _initialPosition = LatLng(23.1765, 75.7885);

  @override
  void initState() {
    super.initState();
    _fetchDriverLocation();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _fetchDriverLocation(silent: true),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  LatLng? get _driverPosition {
    final latitude = double.tryParse(_driver?['latitude']?.toString() ?? '');
    final longitude = double.tryParse(_driver?['longitude']?.toString() ?? '');
    if (latitude == null || longitude == null) return null;
    if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  Future<void> _fetchDriverLocation({bool silent = false}) async {
    if (_isRefreshing) return;
    if (mounted) {
      setState(() {
        _isRefreshing = true;
        if (!silent && _driver == null) _isLoading = true;
        if (!silent) _errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getAssignedDriverLocation(
        bookingId: widget.bookingId,
      );
      if (!mounted) return;

      final latitude = double.tryParse(result['latitude']?.toString() ?? '');
      final longitude = double.tryParse(result['longitude']?.toString() ?? '');
      if (latitude == null || longitude == null ||
          latitude < -90 || latitude > 90 ||
          longitude < -180 || longitude > 180) {
        throw Exception('The driver location data is invalid.');
      }

      setState(() {
        _driver = result;
        _errorMessage = null;
        _isLoading = false;
      });

      final position = LatLng(latitude, longitude);
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  String _lastUpdatedText() {
    final value = _driver?['location_updated_at'];
    final parsed = value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
    if (parsed == null) return 'Last update time unavailable';
    final time = '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}:${parsed.second.toString().padLeft(2, '0')}';
    return 'Driver GPS updated at $time';
  }

  Set<Marker> get _markers {
    final position = _driverPosition;
    if (position == null) return {};
    return {
      Marker(
        markerId: const MarkerId('assigned_driver'),
        position: position,
        infoWindow: InfoWindow(
          title: (_driver?['driver_name'] ?? 'Assigned Driver').toString(),
          snippet: (_driver?['vehicle_name'] ?? 'Driver location').toString(),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final position = _driverPosition;
    final driverName = (_driver?['driver_name'] ?? 'Assigned driver').toString();
    final vehicleName = (_driver?['vehicle_name'] ?? 'Vehicle details unavailable').toString();
    final vehicleType = (_driver?['vehicle_type'] ?? '').toString();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Driver Tracking'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        actions: [
          IconButton(
            tooltip: 'Refresh location',
            onPressed: _isRefreshing ? null : () => _fetchDriverLocation(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position ?? _initialPosition,
                zoom: position == null ? 11 : 16,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                final current = _driverPosition;
                if (current != null) {
                  controller.animateCamera(CameraUpdate.newLatLngZoom(current, 16));
                }
              },
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE8F0FE),
                      child: Icon(Icons.person, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(driverName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 3),
                          Text(
                            vehicleType.isEmpty ? vehicleName : '$vehicleName • $vehicleType',
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    if (_isRefreshing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.gps_fixed, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isLoading && _driver == null)
                  const LinearProgressIndicator(),
                if (_errorMessage != null) ...[
                  Text(
                    _driver == null
                        ? _errorMessage!
                        : 'Could not refresh location: $_errorMessage',
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  position == null
                      ? 'Waiting for the driver to share a GPS location.'
                      : _lastUpdatedText(),
                  style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Location refreshes automatically every 10 seconds.',
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
                if (_driver == null && !_isLoading) ...[
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _isRefreshing ? null : () => _fetchDriverLocation(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
