import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'ride_completed_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class RideInProgressScreen extends StatefulWidget {
  final int bookingId;

  const RideInProgressScreen({super.key, required this.bookingId});

  @override
  State<RideInProgressScreen> createState() => _RideInProgressScreenState();
}

class _RideInProgressScreenState extends State<RideInProgressScreen> {
  GoogleMapController? _mapController;
  Timer? _timer;

  Map<String, dynamic>? _booking;
  Map<String, dynamic>? _driver;

  LatLng? _driverPosition;
  LatLng? _pickupPosition;
  LatLng? _destinationPosition;

  bool _loading = true;
  bool _refreshing = false;
  bool _hasNavigated = false;
  String? _error;

  String _bookingStatus = 'LOADING';

  static const LatLng _fallbackLocation = LatLng(23.1765, 75.7885);

  static const String _logoPath =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  static const String _skylinePath =
      'assets/images/raahi_assets/header/city_skyline5.png';

  @override
  void initState() {
    super.initState();

    _refreshData();

    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _refreshData(silent: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ---------------- HELPERS ----------------

  String _value(dynamic value) {
    if (value == null) return 'N/A';

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return 'N/A';
    }

    return result;
  }

  String? _stringValue(dynamic value) {
    return value is String ? value : null;
  }

  dynamic _first(List<dynamic> values) {
    for (final value in values) {
      if (value != null &&
          value.toString().trim().isNotEmpty &&
          value.toString().toLowerCase() != 'null') {
        return value;
      }
    }

    return null;
  }

  dynamic _nested(dynamic value, String key) {
    return value is Map ? value[key] : null;
  }

  LatLng? _coordinates(dynamic lat, dynamic lng) {
    final latitude = double.tryParse(lat?.toString() ?? '');
    final longitude = double.tryParse(lng?.toString() ?? '');

    if (latitude == null || longitude == null) return null;

    if (!latitude.isFinite || !longitude.isFinite) return null;

    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }

    if (latitude == 0 && longitude == 0) return null;

    return LatLng(latitude, longitude);
  }

  LatLng? _getBookingPosition(Map<String, dynamic> data, String prefix) {
    final nested = prefix == 'pickup'
        ? _first([data['pickup'], data['pickup_location']])
        : _first([data['destination'], data['destination_location']]);

    return _coordinates(
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

  String _normalStatus(dynamic status) {
    return _value(status).toUpperCase().replaceAll(' ', '_');
  }

  bool get _isOngoing => _bookingStatus == 'ONGOING';

  // ---------------- BACKEND ----------------

  
Future<void> _refreshData({bool silent = false}) async {
  if (_refreshing || _hasNavigated) return;

  if (mounted) {
    setState(() {
      _refreshing = true;
      if (!silent) {
        _error = null;
      }
    });
  }

  try {
    final bookings = await ApiService.getMyBookings();

    Map<String, dynamic>? foundBooking;

    for (final item in bookings) {
      final id = int.tryParse(
        (item['id'] ?? item['booking_id']).toString(),
      );

      if (id == widget.bookingId) {
        foundBooking = Map<String, dynamic>.from(item);
        break;
      }
    }

    if (foundBooking == null) {
      throw Exception('Booking details not found');
    }

    final status = _normalStatus(foundBooking['booking_status']);

    Map<String, dynamic>? driverData;
    LatLng? driverPosition;

    if (status == 'ONGOING') {
      try {
        final result = await ApiService.getAssignedDriverLocation(
          bookingId: widget.bookingId,
        );

        driverData = Map<String, dynamic>.from(result);

        driverPosition = _coordinates(
          result['latitude'],
          result['longitude'],
        );
      } catch (error) {
        debugPrint('Driver location error: $error');
      }
    }

    if (!mounted) return;

    setState(() {
      _booking = foundBooking;
      _bookingStatus = status;
      _driver = driverData ?? _driver;
      _driverPosition = driverPosition;

      _pickupPosition = _getBookingPosition(foundBooking!, 'pickup');
      _destinationPosition = _getBookingPosition(
        foundBooking,
        'destination',
      );

      _loading = false;
      _error = null;
    });

    // Automatically open the completed screen.
    if (status == 'COMPLETED' && !_hasNavigated) {
      _hasNavigated = true;
      _timer?.cancel();


      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => RideCompletedScreen(
            bookingId: widget.bookingId,
            booking: foundBooking!,
            driver: driverData ?? _driver,
          ),
        ),
      );

      return;
    }

    _fitMap();
  } catch (error) {
    if (!mounted) return;

    setState(() {
      _loading = false;
      _error = error.toString().replaceFirst('Exception: ', '');
    });
  } finally {
    if (mounted) {
      setState(() {
        _refreshing = false;
      });
    }
  }
}


  // ---------------- DISPLAY DATA ----------------

  String get _driverName => _value(_driver?['driver_name']);

  String get _vehicleName => _value(_driver?['vehicle_name']);

  String get _vehicleType => _value(_driver?['vehicle_type']);

  String get _vehicleNumber => _value(
    _first([
      _driver?['vehicle_number'],
      _driver?['registration_number'],
      _driver?['vehicle_registration_number'],
      _booking?['vehicle_number'],
    ]),
  );

  String get _pickupAddress => _value(
    _first([
      _booking?['pickup_address'],
      _stringValue(_booking?['pickup_location']),
      _nested(_booking?['pickup'], 'address'),
    ]),
  );

  String get _destinationAddress => _value(
    _first([
      _booking?['destination_address'],
      _stringValue(_booking?['destination_location']),
      _nested(_booking?['destination'], 'address'),
    ]),
  );

  String get _tripType => _value(_booking?['trip_type']);

  String get _distance => _value(
    _first([
      _booking?['distance'],
      _booking?['distance_km'],
      _booking?['estimated_distance'],
      _booking?['total_distance'],
    ]),
  );

  String get _duration => _value(
    _first([
      _booking?['duration'],
      _booking?['duration_minutes'],
      _booking?['estimated_duration'],
      _booking?['estimated_time'],
    ]),
  );

  String get _eta =>
      _value(_first([_booking?['eta'], _booking?['estimated_arrival_time']]));

  String get _speed =>
      _value(_first([_driver?['speed'], _driver?['speed_kmh']]));

  String get _rating =>
      _value(_first([_driver?['rating'], _driver?['average_rating']]));

  // ---------------- MAP ----------------

  Set<Marker> get _markers => {
    if (_driverPosition != null)
      Marker(
        markerId: const MarkerId('driver'),
        position: _driverPosition!,
        infoWindow: InfoWindow(title: _driverName, snippet: _vehicleName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    if (_pickupPosition != null)
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPosition!,
        infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    if (_destinationPosition != null)
      Marker(
        markerId: const MarkerId('destination'),
        position: _destinationPosition!,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: _destinationAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
  };

  void _fitMap() {
    if (_mapController == null) return;

    final points = <LatLng>[
      if (_driverPosition != null) _driverPosition!,
      if (_pickupPosition != null) _pickupPosition!,
      if (_destinationPosition != null) _destinationPosition!,
    ];

    if (points.isEmpty) return;

    if (points.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 14),
      );
      return;
    }

    double minLat = points.first.latitude;
    double maxLat = minLat;
    double minLng = points.first.longitude;
    double maxLng = minLng;

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
        45,
      ),
    );
  }

  Widget _map() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target:
                    _driverPosition ??
                    _pickupPosition ??
                    _destinationPosition ??
                    _fallbackLocation,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitMap();
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
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Waiting for driver GPS location',
                  style: TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: FloatingActionButton.small(
              heroTag: 'ride_map_refresh',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: () {
                if (_driverPosition != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_driverPosition!, 15),
                  );
                } else {
                  _fitMap();
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- UI COMPONENTS ----------------

  Widget _header() {
    return SizedBox(
      height: 40,
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
              child: Image(
                image: AssetImage(_logoPath),
                height: 34,
                fit: BoxFit.contain,
                errorBuilder: _logoFallback,
              ),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () =>
                _showMessage('Emergency contact is not configured.'),
            icon: const Icon(Icons.call, size: 13),
            label: const Text('SOS', style: TextStyle(fontSize: 11)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _logoFallback(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return const Text(
      'Raahi',
      style: TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w900,
        fontSize: 23,
      ),
    );
  }

  Widget _metric(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.success, size: 18),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metrics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          _metric(Icons.route, 'Distance left', _distance),
          _verticalDivider(),
          _metric(Icons.access_time, 'ETA', _eta),
          _verticalDivider(),
          _metric(Icons.speed, 'Speed', _speed),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 32, width: 1, color: AppColors.border);
  }

  Widget _journeyProgress() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              _progressDot(true),
              Expanded(child: _progressLine(true)),
              _progressDot(true),
              Expanded(child: _progressLine(false)),
              _progressDot(false),
            ],
          ),
          const SizedBox(height: 5),
          const Row(
            children: [
              Expanded(child: Text('Started', style: TextStyle(fontSize: 9))),
              Expanded(
                child: Text(
                  'On the Way',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9),
                ),
              ),
              Expanded(
                child: Text(
                  'Destination',
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

  Widget _progressDot(bool active) {
    return Container(
      height: 12,
      width: 12,
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    );
  }

  Widget _driverVehicleCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE5F6FA),
            child: Icon(Icons.person, size: 27, color: AppColors.primary),
          ),
          const SizedBox(width: 7),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Rating: $_rating', style: const TextStyle(fontSize: 9)),
                const Text(
                  'Verified status: N/A',
                  style: TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          _verticalDivider(),
          const SizedBox(width: 7),
          const Icon(
            Icons.directions_car_filled,
            size: 29,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
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
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _vehicleType,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
                Text(
                  'Number: $_vehicleNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeRow(IconData icon, String label, String address, Color color) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
              ),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tripDetails() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Details',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  children: [
                    _placeRow(
                      Icons.location_on,
                      'PICKUP',
                      _pickupAddress,
                      AppColors.success,
                    ),
                    const SizedBox(height: 6),
                    _placeRow(
                      Icons.location_on,
                      'DROP',
                      _destinationAddress,
                      AppColors.error,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _verticalDivider(),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailText('Distance', _distance),
                    const SizedBox(height: 6),
                    _detailText('Duration', _duration),
                    const SizedBox(height: 6),
                    _detailText('Trip Type', _tripType),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailText(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _actionButtons() {
    return Row(
      children: [
        _actionButton(Icons.call, 'Call Driver'),
        const SizedBox(width: 5),
        _actionButton(Icons.chat, 'Chat'),
        const SizedBox(width: 5),
        _actionButton(Icons.share, 'Share Trip'),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => _showMessage('$label is not connected yet.'),
        icon: Icon(icon, size: 14),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, maxLines: 1, style: const TextStyle(fontSize: 10)),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
          minimumSize: const Size(0, 34),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }

  Widget _safetyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F7F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_outlined, color: AppColors.success, size: 19),
          SizedBox(width: 7),
          Expanded(
            child: Text(
              'Your ride is in progress. Share your trip with '
              'someone you trust for a safer journey.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skyline() {
    return SizedBox(
      height: 38,
      width: double.infinity,
      child: Image.asset(
        _skylinePath,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ---------------- STATUS SCREEN ----------------

  Widget _statusMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_car_outlined,
              size: 48,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              _loading ? 'Loading booking...' : 'Ride is not in progress',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _loading
                  ? 'Please wait while we check your booking.'
                  : 'Current booking status: $_bookingStatus',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 11),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => _refreshData(),
              icon: const Icon(Icons.refresh),
              label: const Text('Check Booking Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------- MAIN SCREEN ----------------

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: _loading || !_isOngoing
            ? Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _header(),
                  ),
                  Expanded(child: _statusMessage()),
                  _skyline(),
                ],
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(10, 3, 10, 4),
                    child: Column(
                      children: [
                        _header(),
                        const SizedBox(height: 2),
                        const Text(
                          'Ride in Progress',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'On your way to $_destinationAddress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textGrey,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          flex: screenHeight < 750 ? 30 : 34,
                          child: _map(),
                        ),
                        const SizedBox(height: 5),
                        _metrics(),
                        const SizedBox(height: 5),
                        _journeyProgress(),
                        const SizedBox(height: 5),
                        _driverVehicleCard(),
                        const SizedBox(height: 5),
                        _actionButtons(),
                        const SizedBox(height: 5),
                        _safetyBanner(),
                        const SizedBox(height: 5),
                        _tripDetails(),
                        const SizedBox(height: 3),
                        _skyline(),
                        if (_refreshing)
                          const SizedBox(
                            height: 2,
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
