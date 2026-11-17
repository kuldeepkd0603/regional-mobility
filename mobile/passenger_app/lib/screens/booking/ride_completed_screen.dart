
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_colors.dart';

class RideCompletedScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? driver;

  const RideCompletedScreen({
    super.key,
    required this.bookingId,
    required this.booking,
    this.driver,
  });

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int _rating = 0;

  static const String _logoPath =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  static const String _skylinePath =
      'assets/images/raahi_assets/header/city_skyline5.png';

  String _value(dynamic value) {
    if (value == null) return 'N/A';

    final result = value.toString().trim();

    if (result.isEmpty || result.toLowerCase() == 'null') {
      return 'N/A';
    }

    return result;
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

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');
    if (amount == null) return 'N/A';
    return '₹ ${amount.toStringAsFixed(0)}';
  }

  LatLng? _coordinates(dynamic lat, dynamic lng) {
    final latitude = double.tryParse(lat?.toString() ?? '');
    final longitude = double.tryParse(lng?.toString() ?? '');

    if (latitude == null || longitude == null) return null;

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      return null;
    }

    return LatLng(latitude, longitude);
  }

  LatLng? _position(String prefix) {
    final nested = prefix == 'pickup'
        ? _first([widget.booking['pickup'], widget.booking['pickup_location']])
        : _first([
            widget.booking['destination'],
            widget.booking['destination_location'],
          ]);

    return _coordinates(
      _first([
        widget.booking['${prefix}_latitude'],
        widget.booking['${prefix}_lat'],
        _nested(nested, 'latitude'),
        _nested(nested, 'lat'),
      ]),
      _first([
        widget.booking['${prefix}_longitude'],
        widget.booking['${prefix}_lng'],
        widget.booking['${prefix}_lon'],
        _nested(nested, 'longitude'),
        _nested(nested, 'lng'),
        _nested(nested, 'lon'),
      ]),
    );
  }

  String get _pickup => _value(
        _first([
          widget.booking['pickup_address'],
          widget.booking['pickup_location'] is String
              ? widget.booking['pickup_location']
              : null,
          _nested(widget.booking['pickup'], 'address'),
        ]),
      );

  String get _destination => _value(
        _first([
          widget.booking['destination_address'],
          widget.booking['destination_location'] is String
              ? widget.booking['destination_location']
              : null,
          _nested(widget.booking['destination'], 'address'),
        ]),
      );

  String get _driverName => _value(
        _first([
          widget.driver?['driver_name'],
          widget.booking['driver_name'],
          _nested(widget.booking['driver'], 'name'),
        ]),
      );

  String get _vehicleName => _value(
        _first([
          widget.driver?['vehicle_name'],
          widget.booking['vehicle_name'],
          widget.booking['preferred_vehicle_type'],
        ]),
      );

  String get _vehicleNumber => _value(
        _first([
          widget.driver?['vehicle_number'],
          widget.driver?['registration_number'],
          widget.booking['vehicle_number'],
          widget.booking['registration_number'],
        ]),
      );

  String get _distance => _value(
        _first([
          widget.booking['distance'],
          widget.booking['distance_km'],
          widget.booking['estimated_distance'],
          widget.booking['total_distance'],
        ]),
      );

  String get _duration => _value(
        _first([
          widget.booking['duration'],
          widget.booking['duration_minutes'],
          widget.booking['estimated_duration'],
          widget.booking['estimated_time'],
        ]),
      );

  String get _tripType => _value(widget.booking['trip_type']);

  String get _finalFare => _money(
        _first([
          widget.booking['final_fare'],
          widget.booking['estimated_fare'],
        ]),
      );

  String get _paymentStatus => _value(
        _first([
          widget.booking['payment_status'],
          widget.booking['payment_method'],
        ]),
      );

  Set<Marker> get _markers {
    final pickup = _position('pickup');
    final destination = _position('destination');

    return {
      if (pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: 'Pickup', snippet: _pickup),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      if (destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destination,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
    };
  }

  Widget _card({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }

  Widget _mapCard() {
    final pickup = _position('pickup');
    final destination = _position('destination');
    final points = [
      if (pickup != null) pickup,
      if (destination != null) destination,
    ];

    final initialPosition = pickup ??
        destination ??
        const LatLng(23.1765, 75.7885);

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 11,
              ),
              markers: _markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              onMapCreated: (controller) {
                if (points.length == 2) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngBounds(
                      LatLngBounds(
                        southwest: LatLng(
                          points[0].latitude < points[1].latitude
                              ? points[0].latitude
                              : points[1].latitude,
                          points[0].longitude < points[1].longitude
                              ? points[0].longitude
                              : points[1].longitude,
                        ),
                        northeast: LatLng(
                          points[0].latitude > points[1].latitude
                              ? points[0].latitude
                              : points[1].latitude,
                          points[0].longitude > points[1].longitude
                              ? points[0].longitude
                              : points[1].longitude,
                        ),
                      ),
                      35,
                    ),
                  );
                }
              },
            ),
          ),
          if (pickup == null || destination == null)
            Positioned(
              left: 8,
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Route coordinates are not available',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String title, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 21),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 9),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripMetrics() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      child: Row(
        children: [
          _metric(Icons.route, 'Trip Distance', _distance),
          Container(
            height: 35,
            width: 1,
            color: AppColors.border,
          ),
          _metric(Icons.access_time, 'Trip Duration', _duration),
          Container(
            height: 35,
            width: 1,
            color: AppColors.border,
          ),
          _metric(Icons.calendar_month, 'Trip Type', _tripType),
        ],
      ),
    );
  }

  Widget _driverCard() {
    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE5F6FA),
            child: Icon(
              Icons.person,
              size: 34,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rating: ${_value(widget.driver?['rating'])}',
                  style: const TextStyle(fontSize: 10),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Driver verification: N/A',
                  style: TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 1,
            color: AppColors.border,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.directions_car,
            size: 31,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Expanded(
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
                  _vehicleNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareSummary() {
    final finalFare = _finalFare;
    final estimatedFare = _money(widget.booking['estimated_fare']);

    return _card(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 5),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppColors.success,
                  size: 21,
                ),
                const SizedBox(width: 7),
                const Text(
                  'Fare Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (estimatedFare != 'N/A')
            _fareRow('Estimated Fare', estimatedFare),
          _fareRow('Final Fare', finalFare),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 9,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFFDDF8EC),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Fare',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  finalFare,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareRow(String title, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatus() {
    final paid = _paymentStatus.toLowerCase() == 'paid';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF8EC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            paid ? Icons.check_circle : Icons.info_outline,
            color: AppColors.success,
            size: 25,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Payment Status',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            _paymentStatus,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              children: [
                const Text(
                  'Rate Your Ride',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  child: Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        icon: Icon(
                          Icons.star,
                          size: 27,
                          color: index < _rating
                              ? Colors.amber
                              : Colors.grey.shade300,
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 48,
            width: 1,
            color: AppColors.border,
          ),
          Expanded(
            flex: 4,
            child: TextButton.icon(
              onPressed: () {
                _showMessage('Feedback is not connected yet.');
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: Colors.green,
                size: 19,
              ),
              label: const Text(
                'Share Feedback',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              _showMessage('New booking is not connected yet.');
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade800,
              side: const BorderSide(color: Colors.green),
              minimumSize: const Size(0, 43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const FittedBox(
              child: Text(
                'Book Another Ride',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_outlined, size: 20),
            label: const FittedBox(
              child: Text('Back to Home'),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 43),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header() {
    return SizedBox(
      height: 43,
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
                height: 37,
                fit: BoxFit.contain,
                errorBuilder: _logoFallback,
              ),
            ),
          ),
          const SizedBox(width: 40),
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
        fontSize: 23,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _skyline() {
    return SizedBox(
      height: 37,
      width: double.infinity,
      child: Image.asset(
        _skylinePath,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 730;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: [
                  _header(),
                  SizedBox(height: compact ? 1 : 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 31,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          'Ride Completed!',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: compact ? 19 : 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Thank you for riding with Raahi',
                    maxLines: 1,
                    style: TextStyle(fontSize: 11),
                  ),
                  SizedBox(height: compact ? 6 : 9),
                  Expanded(
                    flex: compact ? 24 : 27,
                    child: _mapCard(),
                  ),
                  const SizedBox(height: 5),
                  _tripMetrics(),
                  const SizedBox(height: 5),
                  _driverCard(),
                  const SizedBox(height: 5),
                  _fareSummary(),
                  const SizedBox(height: 5),
                  _buildPaymentStatus(),
                  const SizedBox(height: 5),
                  _ratingCard(),
                  const SizedBox(height: 5),
                  _buttons(),
                  const SizedBox(height: 2),
                  _skyline(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
