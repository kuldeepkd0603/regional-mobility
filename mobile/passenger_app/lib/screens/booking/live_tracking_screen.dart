
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'verify_ride_otp_screen.dart';
import '../safety/emergency_sos_screens.dart';

class LiveTrackingScreen extends StatefulWidget {
  final int bookingId;

  const LiveTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;

  Map<String, dynamic>? _driverDetails;
  Map<String, dynamic>? _bookingDetails;

  LatLng? _driverPosition;
  LatLng? _pickupPosition;
  LatLng? _destinationPosition;

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  static const LatLng _mapFallback = LatLng(23.1765, 75.7885);

  @override
  void initState() {
    super.initState();

    _loadBookingDetails();
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

  // ---------------- BASIC HELPERS ----------------

  String _value(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  dynamic _first(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  dynamic _nested(dynamic value, String key) {
    return value is Map ? value[key] : null;
  }

  String? _stringValue(dynamic value) {
    return value is String ? value : null;
  }

  LatLng? _latLng(dynamic latitude, dynamic longitude) {
    final lat = double.tryParse(latitude?.toString() ?? '');
    final lng = double.tryParse(longitude?.toString() ?? '');

    if (lat == null || lng == null) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return null;
    }
    if (lat == 0 && lng == 0) return null;

    return LatLng(lat, lng);
  }

  LatLng? _bookingPosition(
    Map<String, dynamic> data,
    String prefix,
  ) {
    final nested = prefix == 'pickup'
        ? _first([data['pickup'], data['pickup_location']])
        : _first([
            data['destination'],
            data['destination_location'],
          ]);

    return _latLng(
      _first([
        data['${prefix}_latitude'],
        data['${prefix}_lat'],
        _nested(nested, 'latitude'),
        _nested(nested, 'lat'),
      ]),
      _first([
        data['${prefix}_longitude'],
        data['${prefix}_lng'],
        data['${prefix}_lon'],
        _nested(nested, 'longitude'),
        _nested(nested, 'lng'),
        _nested(nested, 'lon'),
      ]),
    );
  }

  // ---------------- OTP NAVIGATION ----------------

  void _openOtpScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VerifyRideOtpScreen(
          bookingId: widget.bookingId,
          booking: _bookingDetails ?? <String, dynamic>{},
          driver: _driverDetails,
        ),
      ),
    );
  }

  // ---------------- BOOKING DETAILS ----------------

  Future<void> _loadBookingDetails() async {
    try {
      final bookings = await ApiService.getMyBookings();

      for (final item in bookings) {
        final id = int.tryParse(
          (item['id'] ?? item['booking_id']).toString(),
        );

        if (id == widget.bookingId) {
          if (!mounted) return;

          final booking = Map<String, dynamic>.from(item);

          setState(() {
            _bookingDetails = booking;
            _pickupPosition = _bookingPosition(booking, 'pickup');
            _destinationPosition =
                _bookingPosition(booking, 'destination');
          });

          _fitLocations();
          return;
        }
      }
    } catch (error) {
      debugPrint('Booking details error: $error');
    }
  }

  // ---------------- DRIVER GPS ----------------

  Future<void> _fetchDriverLocation({bool silent = false}) async {
    if (_isRefreshing) return;

    if (mounted) {
      setState(() {
        _isRefreshing = true;
        if (!silent) _errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getAssignedDriverLocation(
        bookingId: widget.bookingId,
      );

      if (!mounted) return;

      final position = _latLng(
        result['latitude'],
        result['longitude'],
      );

      if (position == null) {
        throw Exception('Driver GPS location unavailable');
      }

      setState(() {
        _driverDetails = Map<String, dynamic>.from(result);
        _driverPosition = position;
        _errorMessage = null;
        _isLoading = false;
      });

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(position, 14),
        );
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _driverPosition = null;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // ---------------- MAP ----------------

  void _fitLocations() {
    final points = <LatLng>[
      if (_pickupPosition != null) _pickupPosition!,
      if (_destinationPosition != null) _destinationPosition!,
      if (_driverPosition != null) _driverPosition!,
    ];

    if (points.isEmpty || _mapController == null) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;

    for (final point in points.skip(1)) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    if (minLat == maxLat && minLng == maxLng) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        55,
      ),
    );
  }

  Set<Marker> get _markers => {
        if (_driverPosition != null)
          Marker(
            markerId: const MarkerId('driver'),
            position: _driverPosition!,
            infoWindow: InfoWindow(
              title: _driverName,
              snippet: _vehicleName,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        if (_pickupPosition != null)
          Marker(
            markerId: const MarkerId('pickup'),
            position: _pickupPosition!,
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet: _pickupAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        if (_destinationPosition != null)
          Marker(
            markerId: const MarkerId('destination'),
            position: _destinationPosition!,
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: _destinationAddress,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
      };

  Widget _map() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _driverPosition ??
                    _pickupPosition ??
                    _destinationPosition ??
                    _mapFallback,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitLocations();
              },
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
            ),
          ),
          if (_driverPosition == null)
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_off,
                      color: Colors.deepOrange,
                      size: 17,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage ?? 'Waiting for driver GPS location',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            right: 8,
            top: 8,
            child: Column(
              children: [
                _mapButton(
                  Icons.my_location,
                  () {
                    if (_driverPosition != null) {
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(_driverPosition!, 15),
                      );
                    } else {
                      _fitLocations();
                    }
                  },
                ),
                const SizedBox(height: 7),
                _mapButton(
                  Icons.refresh,
                  () => _fetchDriverLocation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 39,
          height: 39,
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 21,
          ),
        ),
      ),
    );
  }

  // ---------------- DISPLAY DATA ----------------

  String get _driverName =>
      _value(_driverDetails?['driver_name']);

  String get _vehicleName =>
      _value(_driverDetails?['vehicle_name']);

  String get _vehicleType =>
      _value(_driverDetails?['vehicle_type']);

  String get _pickupAddress => _value(
        _first([
          _bookingDetails?['pickup_address'],
          _stringValue(_bookingDetails?['pickup_location']),
          _nested(_bookingDetails?['pickup'], 'address'),
        ]),
      );

  String get _destinationAddress => _value(
        _first([
          _bookingDetails?['destination_address'],
          _stringValue(_bookingDetails?['destination_location']),
          _nested(_bookingDetails?['destination'], 'address'),
        ]),
      );

  String get _tripType => _value(_bookingDetails?['trip_type']);

  // ---------------- UI COMPONENTS ----------------

  Widget _panel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(9),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E6E9)),
      ),
      child: child,
    );
  }

  Widget _header() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            color: AppColors.primary,
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Raahi',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencySosSafetyScreen(),
                ),
              );
            },
            icon: const Icon(Icons.call, size: 14),
            label: const Text('SOS', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingSummary() {
    final status = _value(_bookingDetails?['booking_status']);
    final ongoing = status.toLowerCase() == 'ongoing';
    final assigned = status.toLowerCase() == 'driver_assigned';

    return _panel(
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.directions_car_filled,
                color: AppColors.success,
                size: 25,
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'On the Way\nTo Pickup',
                  style: TextStyle(fontSize: 12, height: 1.15),
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              const SizedBox(width: 8),
              const Icon(
                Icons.access_time,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'ETA\nN/A',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
              ),
              Container(width: 1, height: 34, color: AppColors.border),
              const SizedBox(width: 8),
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.success,
                size: 22,
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'Distance\nN/A',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              _progressPoint(true),
              Expanded(child: _progressLine(true)),
              _progressPoint(assigned || ongoing),
              Expanded(child: _progressLine(ongoing)),
              _progressPoint(ongoing),
            ],
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Ride Accepted',
                  style: TextStyle(fontSize: 9),
                ),
              ),
              Expanded(
                child: Text(
                  'Driver En Route',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9),
                ),
              ),
              Expanded(
                child: Text(
                  'Pickup',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressPoint(bool active) {
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? AppColors.success : Colors.white,
        border: Border.all(
          color: active ? AppColors.success : AppColors.border,
          width: 2,
        ),
      ),
    );
  }

  Widget _progressLine(bool active) {
    return Container(
      height: 2,
      color: active ? AppColors.success : AppColors.border,
    );
  }

  Widget _driverVehicle() {
    return _panel(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Color(0xFFE5F6FA),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Rating: N/A',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
                const Text(
                  'Verified status: N/A',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 49, color: AppColors.border),
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_car_filled,
            color: AppColors.primary,
            size: 32,
          ),
          const SizedBox(width: 6),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vehicleName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _vehicleType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGrey,
                  ),
                ),
                const Text(
                  'Vehicle number: N/A',
                  style: TextStyle(
                    fontSize: 9,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeLine(IconData icon, String address, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            address,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, height: 1.15),
          ),
        ),
      ],
    );
  }

  Widget _routeCard() {
    return _panel(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _placeLine(
                  Icons.location_on,
                  _pickupAddress,
                  AppColors.success,
                ),
                const SizedBox(height: 8),
                _placeLine(
                  Icons.location_on,
                  _destinationAddress,
                  AppColors.error,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 62, color: AppColors.border),
          const SizedBox(width: 9),
          const Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SmallMetric(
                  icon: Icons.route,
                  label: 'Distance: N/A',
                ),
                SizedBox(height: 6),
                _SmallMetric(
                  icon: Icons.access_time,
                  label: 'Duration: N/A',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            Icons.call,
            'Call Driver',
            AppColors.success,
            _callDriver,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _actionButton(
            Icons.chat_bubble_outline,
            'Chat',
            AppColors.textDark,
            () => _message('Chat is not available yet'),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _actionButton(
            Icons.send_outlined,
            'Share Trip',
            AppColors.textDark,
            () => _message('Trip sharing is not available yet'),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 15),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.65)),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _otpButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton.icon(
        onPressed: _openOtpScreen,
        icon: const Icon(Icons.lock_open, size: 18),
        label: const Text(
          'Open OTP Screen',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _reminder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 21,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Your driver is on the way to your pickup location. '
              'Please be ready at the pickup point.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CALL DRIVER ----------------

  Future<void> _callDriver() async {
    final phone = _first([
      _driverDetails?['phone'],
      _driverDetails?['phone_number'],
      _bookingDetails?['driver_phone'],
    ]);

    if (phone == null) {
      _message('Driver phone number is unavailable');
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: phone.toString(),
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _message('Unable to open phone dialer');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ---------------- MAIN SCREEN ----------------

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 4, 10, 7),
          child: Column(
            children: [
              _header(),

              const SizedBox(height: 3),

              const Text(
                'Live Ride Tracking',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),

              const SizedBox(height: 2),

              const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Track your driver’s live location and trip progress',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
              ),

              const SizedBox(height: 7),

              Expanded(
                flex: height < 700 ? 28 : 34,
                child: _map(),
              ),

              const SizedBox(height: 6),

              Expanded(
                flex: height < 700 ? 66 : 70,
                child: Column(
                  children: [
                    _trackingSummary(),

                    const SizedBox(height: 5),

                    _driverVehicle(),

                    const SizedBox(height: 5),

                    _routeCard(),

                    const SizedBox(height: 5),

                    _actions(),

                    const SizedBox(height: 5),

                    _otpButton(),

                    const SizedBox(height: 5),

                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _reminder(),
                      ),
                    ),
                  ],
                ),
              ),

              if (_isLoading && _driverDetails == null)
                const LinearProgressIndicator(minHeight: 2),

              if (_isRefreshing)
                const SizedBox(
                  height: 2,
                  child: LinearProgressIndicator(minHeight: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- SMALL METRIC WIDGET ----------------

class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SmallMetric({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.textDark,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }
}
