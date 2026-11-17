import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import 'live_tracking_screen.dart';

class DriverAssignedScreen extends StatelessWidget {
  final int bookingId;
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? driver;

  const DriverAssignedScreen({
    super.key,
    required this.bookingId,
    required this.booking,
    this.driver,
  });

  String _value(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return 'N/A';
    return value.toString().trim();
  }

  String _firstValue(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return 'N/A';
  }

  String _prettyTripType(String value) {
    if (value == 'N/A') return value;
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  Future<void> _callDriver(BuildContext context) async {
    final phone = _firstValue([
      driver?['phone'],
      driver?['phone_number'],
      driver?['mobile'],
    ]);

    if (phone == 'N/A') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is unavailable')),
      );
      return;
    }

    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open phone dialer')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final driverName = _firstValue([
      driver?['driver_name'],
      driver?['name'],
      booking['driver_name'],
    ]);

    final vehicleName = _firstValue([
      driver?['vehicle_name'],
      booking['vehicle_name'],
      driver?['vehicle_model'],
    ]);

    final vehicleType = _firstValue([
      driver?['vehicle_type'],
      booking['preferred_vehicle_type'],
    ]);

    final pickup = _firstValue([
      booking['pickup_address'],
      booking['pickup_location'],
      booking['pickup'],
      (booking['route'] is Map) ? booking['route']['pickup_address'] : null,
      (booking['route'] is Map) ? booking['route']['origin'] : null,
    ]);

    final destination = _firstValue([
      booking['destination_address'],
      booking['destination_location'],
      booking['destination'],
      (booking['route'] is Map)
          ? booking['route']['destination_address']
          : null,
      (booking['route'] is Map) ? booking['route']['destination'] : null,
    ]);

    final passengerCount = _value(booking['passenger_count']);
    final tripType = _prettyTripType(_value(booking['trip_type']));
    final rating = _firstValue([
      driver?['rating'],
      driver?['average_rating'],
    ]);
    final rides = _firstValue([
      driver?['total_rides'],
      driver?['rides_count'],
      driver?['completed_rides'],
    ]);
    final verification = _firstValue([
      driver?['verification_status'],
      driver?['verification'],
      driver?['is_verified'] == true
          ? 'Verified Driver'
          : (driver?['is_verified'] == false ? 'Not verified' : null),
    ]);
    final registration = _firstValue([
      driver?['vehicle_number'],
      driver?['registration_number'],
      driver?['vehicle_registration'],
    ]);
    final eta = _firstValue([
      driver?['estimated_arrival'],
      driver?['eta'],
      booking['estimated_arrival'],
      booking['eta'],
    ]);
    final driverDistance = _firstValue([
      driver?['distance_away'],
      driver?['distance_km'],
      booking['driver_distance_km'],
    ]);
    final tripDistance = _firstValue([
      booking['distance_km'],
      booking['estimated_distance'],
      booking['total_distance'],
    ]);
    final duration = _firstValue([
      booking['estimated_duration'],
      booking['duration'],
      booking['duration_text'],
    ]);

    final driverPhoto = _firstValue([
      driver?['photo_url'],
      driver?['profile_image'],
      driver?['profile_photo'],
      driver?['image_url'],
    ]);
    final vehiclePhoto = _firstValue([
      driver?['vehicle_image_url'],
      driver?['vehicle_image'],
      booking['vehicle_image_url'],
    ]);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 27),
                      ),
                      const Spacer(),
                      Image.asset(
                        'assets/images/raahi_assets/brand/raahi_logo.png',
                        height: 54,
                        errorBuilder: (_, __, ___) => const Text(
                          'Raahi',
                          style: TextStyle(
                            fontSize: 29,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Color(0xFF159B55), size: 35),
                      SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          'Driver Assigned!',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF151B24),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Your ride is confirmed. Driver is on the way to pickup.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Color(0xFF333A43)),
                  ),
                  const SizedBox(height: 20),

                  // Driver details
                  _card(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _profileImage(driverPhoto),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    driverName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF151B24),
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Color(0xFFFFB000), size: 22),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          '$rating  ($rides rides)',
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE5F7F0),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.verified_user,
                                            color: Color(0xFF159B55), size: 18),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            verification == 'N/A'
                                                ? 'Driver verification: N/A'
                                                : verification,
                                            style:
                                                const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 17),
                        const Divider(color: Color(0xFFE2E7EB)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _actionButton(
                                icon: Icons.call,
                                label: 'Call Driver',
                                color: const Color(0xFF159B7C),
                                onPressed: () => _callDriver(context),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _actionButton(
                                icon: Icons.chat_bubble_outline,
                                label: 'Chat',
                                onPressed: null,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: _actionButton(
                                icon: Icons.send_outlined,
                                label: 'Share Trip',
                                color: const Color(0xFF40577D),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Trip sharing will be available soon',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Vehicle details
                  _card(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 125,
                          height: 92,
                          child: _vehicleImage(vehiclePhoto),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vehicleName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF151B24),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '$vehicleType • $passengerCount passengers',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Registration: $registration',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Driver arrival estimate
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F8F2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car,
                            color: Color(0xFF159B7C), size: 39),
                        const SizedBox(width: 13),
                        const Expanded(
                          child: Text(
                            'Estimated Arrival',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          eta == 'N/A' ? 'N/A' : eta,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF159B7C),
                          ),
                        ),
                        if (driverDistance != 'N/A') ...[
                          const SizedBox(width: 7),
                          Text(
                            '($driverDistance)',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Trip route and trip details
                  _card(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _locationRow(
                                Icons.location_on,
                                'Pickup',
                                pickup,
                                const Color(0xFF159B7C),
                              ),
                              const SizedBox(height: 17),
                              _locationRow(
                                Icons.location_on,
                                'Destination',
                                destination,
                                const Color(0xFFE0445E),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 116,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          color: const Color(0xFFE2E7EB),
                        ),
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.route,
                                  size: 23, color: Color(0xFF20252B)),
                              const SizedBox(height: 5),
                              Text(
                                tripDistance == 'N/A'
                                    ? 'Distance: N/A'
                                    : 'Distance: $tripDistance',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 15),
                              const Icon(Icons.access_time,
                                  size: 23, color: Color(0xFF20252B)),
                              const SizedBox(height: 5),
                              Text(
                                duration == 'N/A'
                                    ? 'Duration: N/A'
                                    : 'Duration: $duration',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 10),
                              if (tripType != 'N/A')
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE5F7F0),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0xFFB5E8D8),
                                    ),
                                  ),
                                  child: Text(
                                    tripType,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF126B57),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Track button is placed before the reminder, as in the reference.
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                LiveTrackingScreen(bookingId: bookingId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on_outlined, size: 29),
                      label: const Text(
                        'Track Live Location  →',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Pickup reminder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5F6FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.primary, size: 25),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Note: Driver will reach your pickup location shortly. Please be ready at the pickup point.',
                            style: TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const _RaahiSkylineFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileImage(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return ClipOval(
        child: Image.network(
          imageUrl,
          width: 88,
          height: 88,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultProfile(),
        ),
      );
    }
    return _defaultProfile();
  }

  Widget _defaultProfile() {
    return const CircleAvatar(
      radius: 44,
      backgroundColor: Color(0xFFE5F6FA),
      child: Icon(Icons.person, size: 52, color: AppColors.primary),
    );
  }

  Widget _vehicleImage(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _defaultVehicle(),
      );
    }
    return _defaultVehicle();
  }

  Widget _defaultVehicle() {
    return const Center(
      child: Icon(Icons.directions_car_filled,
          size: 72, color: AppColors.primary),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final enabledColor = color ?? const Color(0xFF777D84);
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: onPressed == null
            ? const Color(0xFFB8BBC0)
            : enabledColor,
        side: BorderSide(
          color: onPressed == null
              ? const Color(0xFFE0E2E5)
              : enabledColor.withValues(alpha: 0.75),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E7EB)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _locationRow(
    IconData icon,
    String title,
    String address,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 27),
        const SizedBox(width: 7),
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
              const SizedBox(height: 4),
              Text(
                address,
                style: const TextStyle(fontSize: 13, height: 1.3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RaahiSkylineFooter extends StatelessWidget {
  const _RaahiSkylineFooter();

  @override
  Widget build(BuildContext context) {
    const skylineColor = Color(0xFF8BD9E8);
    return SizedBox(
      height: 82,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 28,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD7F7F5), Color(0xFF7DDFD1)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(80),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 17,
            child: Icon(Icons.temple_hindu,
                size: 43, color: skylineColor.withValues(alpha: 0.9)),
          ),
          Positioned(
            left: 58,
            bottom: 17,
            child: Icon(Icons.account_balance,
                size: 34, color: skylineColor.withValues(alpha: 0.85)),
          ),
          Positioned(
            right: 58,
            bottom: 17,
            child: Icon(Icons.temple_hindu,
                size: 45, color: skylineColor.withValues(alpha: 0.9)),
          ),
          Positioned(
            right: 8,
            bottom: 17,
            child: Icon(Icons.account_balance,
                size: 35, color: skylineColor.withValues(alpha: 0.85)),
          ),
          Positioned(
            bottom: 12,
            child: Icon(Icons.location_city,
                size: 40, color: skylineColor.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
