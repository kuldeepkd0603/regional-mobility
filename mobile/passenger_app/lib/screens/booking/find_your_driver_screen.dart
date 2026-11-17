import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import 'driver_assigned_screen.dart';
import 'live_tracking_screen.dart';

class FindYourDriverScreen extends StatefulWidget {
  final dynamic booking;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final String vehicleType;
  final int passengerCount;

  const FindYourDriverScreen({
    super.key,
    required this.booking,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.vehicleType,
    required this.passengerCount,
  });

  @override
  State<FindYourDriverScreen> createState() =>
      _FindYourDriverScreenState();
}

class _FindYourDriverScreenState extends State<FindYourDriverScreen> {
  static const Color navy = Color(0xFF064B68);
  static const Color green = Color(0xFF10A887);
  static const Color paleGreen = Color(0xFFE7F8F4);
  static const Color textColor = Color(0xFF171B22);
  static const Color muted = Color(0xFF68717D);

  bool _isSearching = true;
  bool _searchFailed = false;
  bool _isCancelled = false;
  bool _isCheckingBooking = false;
  bool _isDriverAssigned = false;
  bool _openingTracking = false;
  bool _openingAssignedScreen = false;

  List<dynamic> _nearbyDrivers = [];
  String? _errorMessage;
  Map<String, dynamic>? _assignedDriver;
  Timer? _bookingPollTimer;

  String _pickupAddress = '';
  String _dropAddress = '';
  String _pickupCity = '';
  String _dropCity = '';
  String _tripType = '';
  String _bookingId = '';

  int? get _parsedBookingId => int.tryParse(_bookingId);

  @override
  void initState() {
    super.initState();
    _readBookingDetails();
    _readInitialAssignment();

    // Verify the booking in the database before the first nearby search.
    _startInitialFlow();

    // Keep checking for driver acceptance while this screen is visible.
    // The initial database check is already running in _startInitialFlow().
    _bookingPollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkBookingStatus(),
    );
  }

  @override
  void dispose() {
    _bookingPollTimer?.cancel();
    super.dispose();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }
    return {};
  }

  String _value(dynamic value) {
    if (value == null) return 'N/A';
    final result = value.toString().trim();
    if (result.isEmpty || result.toLowerCase() == 'null') {
      return 'N/A';
    }
    return result;
  }

  void _readBookingDetails() {
    final booking = _asMap(widget.booking);

    _pickupAddress = _value(
      booking['pickup_address'] ?? booking['pickupAddress'],
    );
    _dropAddress = _value(
      booking['drop_address'] ?? booking['dropAddress'],
    );
    _pickupCity = _value(
      booking['pickup_city'] ?? booking['pickupCity'],
    );
    _dropCity = _value(
      booking['drop_city'] ?? booking['dropCity'],
    );
    _tripType = _value(
      booking['trip_type'] ?? booking['tripType'],
    );
    _bookingId = _value(
      booking['id'] ??
          booking['booking_id'] ??
          booking['bookingId'],
    );
  }

  void _readInitialAssignment() {
    final booking = _asMap(widget.booking);
    final driver = booking['assigned_driver'] ??
        booking['assignedDriver'] ??
        booking['driver'];

    final status = _normaliseStatus(
      booking['booking_status'] ?? booking['bookingStatus'],
    );

    if (driver is Map && driver.isNotEmpty) {
      _assignedDriver = _asMap(driver);
    }

    if (status == 'driver_assigned' || status == 'ongoing') {
      _isDriverAssigned = true;
      _isSearching = false;
    }
  }

  String _normaliseStatus(dynamic value) {
    if (value == null) return '';
    return value
        .toString()
        .toLowerCase()
        .split('.')
        .last
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  Future<Map<String, dynamic>?> _getCurrentBookingFromDatabase() async {
    final bookingId = _parsedBookingId;
    if (bookingId == null) return null;

    final bookings = await ApiService.getMyBookings();

    for (final item in bookings) {
      final booking = _asMap(item);
      final id = int.tryParse(
        (booking['id'] ?? booking['booking_id'] ?? '').toString(),
      );

      if (id == bookingId) return booking;
    }

    return null;
  }

  Future<void> _startInitialFlow() async {
    if (_parsedBookingId == null) {
      await _searchDrivers();
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
        _searchFailed = false;
        _errorMessage = null;
      });
    }

    try {
      final booking = await _getCurrentBookingFromDatabase();
      if (!mounted || _isCancelled) return;

      if (booking == null) {
        setState(() {
          _isSearching = false;
          _searchFailed = true;
          _errorMessage = 'Unable to verify your booking. Please try again.';
        });
        return;
      }

      final status = _normaliseStatus(
        booking['booking_status'] ?? booking['bookingStatus'],
      );

      if (status == 'driver_assigned' || status == 'ongoing') {
        await _openAssignedScreen(booking);
      } else if (status == 'pending') {
        await _searchDrivers();
      } else {
        setState(() {
          _isSearching = false;
          _searchFailed = true;
          _errorMessage = 'Booking status: ${status.isEmpty ? 'N/A' : status}. Please check your booking.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchFailed = true;
        _errorMessage = 'Could not verify booking status. Please try again.';
      });
    }
  }

  Future<void> _openAssignedScreen(Map<String, dynamic> booking) async {
    if (!mounted || _openingAssignedScreen || _parsedBookingId == null) return;

    _openingAssignedScreen = true;
    _bookingPollTimer?.cancel();

    Map<String, dynamic> driver = {};
    final assignedDriver = booking['assigned_driver'] ??
        booking['assignedDriver'] ??
        booking['driver'];

    if (assignedDriver is Map) {
      driver = _asMap(assignedDriver);
    }

    // The assignment status is authoritative. Location/details may not
    // be available immediately, so failure here must not block navigation.
    try {
      final location = await ApiService.getAssignedDriverLocation(
        bookingId: _parsedBookingId!,
      );
      driver = {...driver, ..._asMap(location)};
    } catch (_) {
      // Keep the available driver data and continue to the assigned screen.
    }

    if (!mounted) return;

    setState(() {
      _isDriverAssigned = true;
      _isSearching = false;
      _assignedDriver = driver.isEmpty ? null : driver;
    });

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DriverAssignedScreen(
          bookingId: _parsedBookingId!,
          booking: booking,
          driver: driver.isEmpty ? null : driver,
        ),
      ),
    );
  }

  Future<void> _checkBookingStatus() async {
    if (_isCheckingBooking ||
        _isCancelled ||
        _isDriverAssigned ||
        _openingAssignedScreen ||
        _parsedBookingId == null) {
      return;
    }

    _isCheckingBooking = true;

    try {
      final booking = await _getCurrentBookingFromDatabase();
      if (!mounted || _isCancelled || booking == null) return;

      final status = _normaliseStatus(
        booking['booking_status'] ?? booking['bookingStatus'],
      );

      if (status == 'driver_assigned' || status == 'ongoing') {
        await _openAssignedScreen(booking);
      }
    } catch (_) {
      // A temporary polling failure does not mean the booking is unassigned.
    } finally {
      _isCheckingBooking = false;
    }
  }

  Future<void> _searchDrivers() async {
    if (widget.pickupLatitude == null ||
        widget.pickupLongitude == null) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchFailed = true;
        _errorMessage = 'Location unavailable. Your booking is still active.';
      });
      return;
    }

    try {
      final result = await ApiService.findNearbyDrivers(
        latitude: widget.pickupLatitude!,
        longitude: widget.pickupLongitude!,
        vehicleType: widget.vehicleType,
        passengerCount: widget.passengerCount,
      );

      if (!mounted || _isCancelled || _isDriverAssigned) return;

      final data = _asMap(result);
      dynamic drivers;

      if (result is List) {
        drivers = result;
      } else {
        drivers = data['drivers'] ??
            data['nearby_drivers'] ??
            data['results'] ??
            data['data'] ??
            [];
      }

      final driverList =
          drivers is List ? List<dynamic>.from(drivers) : <dynamic>[];

      setState(() {
        _nearbyDrivers = driverList;
        _isSearching = false;
        _searchFailed = false;
      });
    } catch (_) {
      if (!mounted || _isCancelled || _isDriverAssigned) return;

      setState(() {
        _isSearching = false;
        _searchFailed = true;
        _errorMessage = 'Unable to search nearby drivers. Please try again.';
      });
    }
  }

  Future<void> _retrySearch() async {
    if (_isDriverAssigned ||
        _isCheckingBooking ||
        _openingAssignedScreen ||
        _isSearching) {
      return;
    }

    setState(() {
      _isSearching = true;
      _searchFailed = false;
      _errorMessage = null;
    });

    _isCheckingBooking = true;
    try {
      // Always verify the latest database status before another search.
      final booking = await _getCurrentBookingFromDatabase();
      if (!mounted || _isCancelled) return;

      if (booking == null) {
        setState(() {
          _isSearching = false;
          _searchFailed = true;
          _errorMessage = 'Unable to verify your booking. Please try again.';
        });
        return;
      }

      final status = _normaliseStatus(
        booking['booking_status'] ?? booking['bookingStatus'],
      );

      if (status == 'driver_assigned' || status == 'ongoing') {
        await _openAssignedScreen(booking);
        return;
      }

      if (status == 'pending') {
        await _searchDrivers();
        return;
      }

      setState(() {
        _isSearching = false;
        _searchFailed = true;
        _errorMessage = 'Booking status: ${status.isEmpty ? 'N/A' : status}. Please check your booking.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchFailed = true;
        _errorMessage = 'Could not verify booking status. Please try again.';
      });
    } finally {
      _isCheckingBooking = false;
    }
  }

  Future<void> _openTracking() async {
    if (_openingTracking || _parsedBookingId == null) return;

    setState(() => _openingTracking = true);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(
          bookingId: _parsedBookingId!,
        ),
      ),
    );

    if (mounted) {
      setState(() => _openingTracking = false);
    }
  }

  Future<void> _cancelSearch() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave driver search?'),
        content: const Text(
          'This only leaves the search screen. '
          'It does not cancel your booking on the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue Searching'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Leave Search',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _isCancelled = true;
      _bookingPollTimer?.cancel();
      Navigator.pop(context);
    }
  }

  String _displayTripType() {
    if (_tripType == 'N/A') return 'Your Trip';

    return _tripType
        .replaceAll('_', ' ')
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  Widget _logo() {
    return Image.asset(
      'assets/images/raahi_assets/brand/raahi_logo.png',
      height: 65,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text(
        'Raahi',
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: navy,
        ),
      ),
    );
  }

  Widget _header() {
    final title =
        _isDriverAssigned ? 'Driver Assigned' : 'Finding Your Driver';

    final subtitle = _isDriverAssigned
        ? 'Your driver has accepted the booking.'
        : 'We are looking for the best available driver near you...';

    return Column(
      children: [
        SizedBox(
          height: 70,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, size: 28),
                ),
              ),
              _logo(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: muted),
        ),
      ],
    );
  }

  Widget _searchIllustration() {
    return SizedBox(
      height: 245,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.16,
              child: Image.asset(
                'assets/images/raahi_assets/header/city_skyline5.png',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Container(
            width: 205,
            height: 205,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: green.withValues(alpha: 0.15),
                width: 17,
              ),
            ),
          ),
          Container(
            width: 155,
            height: 155,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: green.withValues(alpha: 0.12),
              border: Border.all(
                color: green.withValues(alpha: 0.35),
                width: 12,
              ),
            ),
          ),
          Container(
            width: 105,
            height: 105,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: green,
            ),
            child: Icon(
              _isDriverAssigned
                  ? Icons.check
                  : Icons.directions_car_filled,
              color: Colors.white,
              size: 54,
            ),
          ),
          if (!_isDriverAssigned) ...[
            _mapPin(const Alignment(-0.78, -0.65)),
            _mapPin(const Alignment(0.78, -0.28)),
            _mapPin(const Alignment(-0.78, 0.63)),
            _mapPin(const Alignment(0.72, 0.65)),
          ],
        ],
      ),
    );
  }

  Widget _mapPin(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: green, width: 3),
          boxShadow: [
            BoxShadow(
              color: green.withValues(alpha: 0.15),
              blurRadius: 10,
            ),
          ],
        ),
        child: const Icon(
          Icons.directions_car_filled,
          color: navy,
          size: 24,
        ),
      ),
    );
  }

  Widget _routeCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0xFFE2E6EA)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _locationRow(
                  Icons.location_on,
                  green,
                  'Pickup',
                  _pickupAddress != 'N/A' ? _pickupAddress : _pickupCity,
                ),
                const SizedBox(height: 13),
                _locationRow(
                  Icons.location_on,
                  Colors.red,
                  'Destination',
                  _dropAddress != 'N/A' ? _dropAddress : _dropCity,
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 105,
            color: const Color(0xFFD9DEE3),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route, size: 22),
                const SizedBox(height: 5),
                Text(
                  _displayTripType(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Booking #$_bookingId',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationRow(
    IconData icon,
    Color color,
    String title,
    String address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address == 'N/A' ? 'N/A' : address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _searchStatus() {
    final title = _isDriverAssigned
        ? 'Your driver has been assigned'
        : _isSearching
            ? 'Searching for nearby drivers...'
            : _searchFailed
                ? 'Driver search unavailable'
                : _nearbyDrivers.isEmpty
                    ? 'No nearby drivers found yet'
                    : '${_nearbyDrivers.length} nearby driver(s) found';

    final subtitle = _isDriverAssigned
        ? 'You can now view your driver and ride status.'
        : _isSearching
            ? 'Checking available drivers for your ride'
            : _searchFailed
                ? (_errorMessage ?? 'Please try again.')
                : _nearbyDrivers.isEmpty
                    ? 'Your booking is still pending assignment.'
                    : 'Nearby drivers found. Your booking is awaiting acceptance.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: paleGreen,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _isDriverAssigned
                  ? Icons.check
                  : _isSearching
                      ? Icons.search
                      : _searchFailed
                          ? Icons.warning_amber_rounded
                          : Icons.directions_car,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          if (_isSearching)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _assignedDriverCard() {
    final driver = _assignedDriver ?? {};

    final driverName = _value(
      driver['name'] ?? driver['driver_name'] ?? driver['full_name'],
    );
    final vehicleName = _value(
      driver['vehicle_name'] ?? driver['name'],
    );
    final vehicleType = _value(
      driver['vehicle_type'] ?? driver['type'],
    );
    final phone = _value(
      driver['phone'] ?? driver['phone_number'],
    );
    final vehicleNumber = _value(
      driver['vehicle_number'] ?? driver['registration_number'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E6EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: paleGreen,
                child: Icon(
                  Icons.person,
                  size: 32,
                  color: navy,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.verified, color: green, size: 25),
            ],
          ),
          const Divider(height: 25),
          _detailRow('Vehicle', vehicleName),
          _detailRow('Vehicle type', vehicleType),
          _detailRow('Vehicle number', vehicleNumber),
          _detailRow('Rating', 'N/A'),
          _detailRow('ETA', 'N/A'),
          _detailRow('Distance', 'N/A'),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _openingTracking ? null : _openTracking,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Track Your Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: muted)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefits() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE7E9ED)),
      ),
      child: const Row(
        children: [
          Expanded(
            child: _Benefit(
              icon: Icons.verified_user_outlined,
              title: 'Verified\nDrivers',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _Benefit(
              icon: Icons.bolt,
              title: 'Quick\nMatching',
            ),
          ),
          _VerticalDivider(),
          Expanded(
            child: _Benefit(
              icon: Icons.directions_car_outlined,
              title: 'Reliable &\nSafe Ride',
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomArtwork() {
    return SizedBox(
      height: 65,
      width: double.infinity,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline5.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFFFF),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 5, 18, 12),
                child: Column(
                  children: [
                    _header(),
                    const SizedBox(height: 8),
                    _searchIllustration(),
                    const SizedBox(height: 12),
                    _routeCard(),
                    const SizedBox(height: 17),
                    if (_isDriverAssigned)
                      _assignedDriverCard()
                    else
                      _searchStatus(),
                    const SizedBox(height: 17),
                    if (!_isDriverAssigned) _benefits(),
                    if (!_isDriverAssigned &&
                        (_searchFailed ||
                            (!_isSearching && _nearbyDrivers.isEmpty))) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _retrySearch,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Search Again'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: green,
                            side: const BorderSide(color: green),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 10),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _cancelSearch,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 1.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isDriverAssigned ? 'Back' : 'Cancel Search',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            _bottomArtwork(),
          ],
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String title;

  const _Benefit({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF10A887), size: 30),
        const SizedBox(height: 5),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      color: const Color(0xFFD9DEE3),
    );
  }
}