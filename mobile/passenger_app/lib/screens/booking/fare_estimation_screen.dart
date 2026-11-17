
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'booking_details_screen.dart';

class FareEstimationScreen extends StatefulWidget {
  final double distanceKm;
  final String tripType;
  final String vehicleModel;
  final Map<String, dynamic> driver;
  final String pickupAddress;
  final String dropAddress;
  final String pickupCity;
  final String dropCity;

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;
  final bool usingFallbackDistance;

  const FareEstimationScreen({
    super.key,
    required this.distanceKm,
    required this.tripType,
    required this.vehicleModel,
    this.driver = const {},
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupCity,
    required this.dropCity,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
    this.usingFallbackDistance = false,
  });

  @override
  State<FareEstimationScreen> createState() =>
      _FareEstimationScreenState();
}

class _FareEstimationScreenState extends State<FareEstimationScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? fareData;

  static const Color navy = Color(0xFF07516B);
  static const Color teal = Color(0xFF159B7C);
  static const Color mint = Color(0xFFE4F7F1);
  static const Color border = Color(0xFFE1E6E9);
  static const Color dark = Color(0xFF17212B);
  static const Color grey = Color(0xFF68727D);
  static const Color green = Color(0xFF168044);

  @override
  void initState() {
    super.initState();
    _loadFareEstimate();
  }

  Future<void> _loadFareEstimate() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.estimateFare(
        tripType: widget.tripType,
        vehicleType: widget.vehicleModel,
        distanceKm: widget.distanceKm,
        passengerCount: 1,
      );

      if (!mounted) return;

      setState(() {
        fareData = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  double? _number(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  String _money(dynamic value) {
    final amount = _number(value);
    if (amount == null) return '—';
    return '₹${amount.toStringAsFixed(0)}';
  }

  String _distance(dynamic value) {
    final amount = _number(value);
    if (amount == null) return '—';
    return '${amount.toStringAsFixed(1)} km';
  }

  String get _vehicleName {
    final value = widget.vehicleModel.trim();
    if (value.isEmpty) return 'Vehicle';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get _vehicleDescription {
    switch (widget.vehicleModel.toLowerCase()) {
      case 'dzire':
        return 'Sedan • 4 + 1 Seater';
      case 'eeco':
        return 'Van • 7 Seater';
      case 'ertiga':
        return 'MUV • 6 + 1 Seater';
      case 'innova':
        return 'SUV • 7 Seater';
      case 'urbania':
        return 'Luxury Van';
      default:
        return 'Comfortable Travel';
    }
  }

  String get _tripLabel {
    switch (widget.tripType.toLowerCase()) {
      case 'intercity':
        return 'Intercity Travel';
      case 'local':
        return 'Local Ride';
      case 'round_trip':
        return 'Round Trip';
      case 'religious_tour':
        return 'Religious Tour';
      default:
        return widget.tripType.replaceAll('_', ' ');
    }
  }

  String get _vehicleImage =>
      'assets/images/raahi_assets/vehicles/${widget.vehicleModel.toLowerCase()}.png';

  void _bookRide() {
    final fare = fareData;
    if (fare == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailsScreen(
          tripType: widget.tripType,
          vehicleModel: widget.vehicleModel,
          distanceKm: widget.distanceKm,
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropAddress,
          pickupCity: widget.pickupCity,
          dropCity: widget.dropCity,
          estimatedFare: fare['estimated_fare'],
          pickupLatitude: widget.pickupLatitude,
          pickupLongitude: widget.pickupLongitude,
          dropLatitude: widget.dropLatitude,
          dropLongitude: widget.dropLongitude,
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return SizedBox(
      height: 91,
      child: Column(
        children: [
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      size: 26,
                      color: dark,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/raahi_assets/brand/raahi_logo.png',
                  height: 47,
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const SizedBox(height: 1),
          const Text(
            'Fare Estimate',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const Text(
            'Review trip details, fare breakdown and book your ride',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: grey,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ROUTE CARD ----------------

  Widget _routeLocation(
    IconData icon,
    Color color,
    String name,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name.isEmpty ? '—' : name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _routeCard() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _routeLocation(
                  Icons.location_on,
                  teal,
                  widget.pickupCity,
                ),
                const SizedBox(height: 7),
                _routeLocation(
                  Icons.location_on,
                  Colors.redAccent,
                  widget.dropCity,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 53, color: border),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, size: 17, color: dark),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _distance(
                          fareData?['distance_km'] ?? widget.distanceKm,
                        ),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: dark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 17, color: dark),
                    SizedBox(width: 6),
                    Text(
                      '—',
                      style: TextStyle(fontSize: 12, color: dark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.edit_outlined,
              size: 21,
              color: teal,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- VEHICLE CARD ----------------

  Widget _vehicleCard() {
    return Container(
      height: 79,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 105,
            height: 68,
            child: Image.asset(
              _vehicleImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car,
                size: 48,
                color: navy,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vehicleName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                Text(
                  _vehicleDescription,
                  style: const TextStyle(
                    fontSize: 11,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '♧  $_tripLabel',
                    style: const TextStyle(
                      color: teal,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 48, width: 1, color: border),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                color: teal,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FARE BREAKDOWN ----------------

  Widget _fareRow({
    required IconData icon,
    required String title,
    required String value,
    Color valueColor = dark,
  }) {
    return SizedBox(
      height: 29,
      child: Row(
        children: [
          Icon(icon, size: 19, color: dark),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: dark,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareBreakdown() {
    final fare = fareData ?? {};

    final rate = _number(fare['per_km_rate']);
    final chargeableDistance =
        _number(fare['chargeable_distance_km']);

    final distanceCharge =
        rate != null && chargeableDistance != null
            ? rate * chargeableDistance
            : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          const SizedBox(
            width: double.infinity,
            child: Text(
              'Fare Breakdown',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: dark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _fareRow(
            icon: Icons.directions_car_outlined,
            title: 'Base Fare',
            value: _money(fare['base_fare']),
          ),
          _fareRow(
            icon: Icons.route,
            title: 'Distance Charge',
            value: distanceCharge == null
                ? '—'
                : _money(distanceCharge),
          ),
          _fareRow(
            icon: Icons.person_outline,
            title: 'Driver Allowance',
            value: '—',
          ),
          _fareRow(
            icon: Icons.toll_outlined,
            title: 'Toll Charges (Estimated)',
            value: '—',
          ),
          _fareRow(
            icon: Icons.local_parking_outlined,
            title: 'Parking (Estimated)',
            value: '—',
          ),
          Container(
            height: 29,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FAF4),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.discount_outlined,
                  size: 19,
                  color: teal,
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Text(
                    'Offer Discount',
                    style: TextStyle(
                      fontSize: 12,
                      color: green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Text(
                  '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TOTAL FARE ----------------

  Widget _totalFare() {
    return Container(
      height: 53,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    'Total Estimated Fare',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Icon(
                  Icons.info_outline,
                  size: 17,
                  color: teal,
                ),
              ],
            ),
          ),
          Text(
            _money(fareData?['estimated_fare']),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DISCLAIMER ----------------

  Widget _disclaimer() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 19,
            color: teal,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Final fare may vary based on actual distance, tolls, parking and waiting time.',
              maxLines: 2,
              style: TextStyle(
                fontSize: 9,
                color: dark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TRUST FEATURES ----------------

  Widget _trustFeatures() {
    return Container(
      height: 57,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _TrustItem(
              icon: Icons.verified_user_outlined,
              first: 'Verified',
              second: 'Drivers',
            ),
          ),
          _TrustDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.currency_exchange,
              first: 'Transparent',
              second: 'Fares',
            ),
          ),
          _TrustDivider(),
          Expanded(
            child: _TrustItem(
              icon: Icons.headset_mic_outlined,
              first: '24×7',
              second: 'Support',
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SKYLINE ----------------

  Widget _skyline() {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline5.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  // ---------------- BOOK BUTTON ----------------

  Widget _bookButton() {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _bookRide,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Book Ride Now',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward, size: 23),
          ],
        ),
      ),
    );
  }

  // ---------------- ERROR VIEW ----------------

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 52,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to calculate fare',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadFareEstimate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- ONE SCREEN, NO SCROLL ----------------

  Widget _fareView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // The design is laid out at 790 logical pixels high.
        // It scales down proportionally on shorter devices.
        const designHeight = 790.0;

        return Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: constraints.maxWidth,
              height: designHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 7),
                    _routeCard(),
                    const SizedBox(height: 9),
                    _vehicleCard(),
                    const SizedBox(height: 10),
                    _fareBreakdown(),
                    const SizedBox(height: 9),
                    _totalFare(),
                    const SizedBox(height: 8),
                    _disclaimer(),
                    const SizedBox(height: 8),
                    _trustFeatures(),
                    const Spacer(),
                    _skyline(),
                    const SizedBox(height: 5),
                    _bookButton(),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: teal),
              )
            : errorMessage != null
                ? _errorView()
                : fareData != null
                    ? _fareView()
                    : const Center(
                        child: Text('Fare information unavailable.'),
                      ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  final IconData icon;
  final String first;
  final String second;

  const _TrustItem({
    required this.icon,
    required this.first,
    required this.second,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: const Color(0xFF159B7C), size: 23),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF17212B),
                ),
              ),
              Text(
                second,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF17212B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 1,
      color: const Color(0xFFE1E6E9),
    );
  }
}
