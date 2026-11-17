
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'live_tracking_screen.dart';

class BookingSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingSummaryScreen({
    super.key,
    required this.booking,
  });

  static const Color navy = Color(0xFF092C43);
  static const Color green = Color(0xFF07963E);
  static const Color paleGreen = Color(0xFFE4F9ED);
  static const Color border = Color(0xFFE2E8EC);

  Map<String, dynamic> get route {
    final data = booking['route'];
    return data is Map ? Map<String, dynamic>.from(data) : {};
  }

  String val(dynamic data) {
    if (data == null || data.toString().trim().isEmpty ||
        data.toString() == 'null') {
      return 'N/A';
    }
    return data.toString().trim();
  }

  String get pickup => val(
        route['pickup_address'] ??
            route['pickup_city'] ??
            booking['pickup_address'],
      );

  String get destination => val(
        route['drop_address'] ??
            route['drop_city'] ??
            booking['destination_address'],
      );

  String get status => val(booking['booking_status'])
      .toLowerCase()
      .replaceAll(' ', '_');

  String get statusText {
    switch (status) {
      case 'completed':
        return 'Ride Completed';
      case 'ongoing':
        return 'Ride in Progress';
      case 'driver_assigned':
      case 'accepted':
        return 'Driver Assigned';
      case 'pending':
        return 'Finding Your Driver';
      case 'cancelled':
        return 'Ride Cancelled';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }

  String money(dynamic amount) {
    final number = double.tryParse(amount?.toString() ?? '');
    return number == null ? 'N/A' : '₹ ${number.toStringAsFixed(0)}';
  }

  String get totalFare =>
      money(booking['final_fare'] ?? booking['estimated_fare']);

  String date(dynamic input) {
    if (input == null) return 'N/A';
    final d = DateTime.tryParse(input.toString())?.toLocal();
    if (d == null) return 'N/A';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';

    return '${d.day} ${months[d.month - 1]} ${d.year}, '
        '$hour:$minute $ampm';
  }

  String get vehicleType {
    return val(
      booking['preferred_vehicle_type'] ??
          booking['vehicle_name'] ??
          booking['vehicle_type'],
    );
  }

  String get vehicleAsset {
    final type = vehicleType.toLowerCase();

    if (type.contains('dzire') || type.contains('swift')) {
      return 'assets/images/raahi_assets/vehicles/dzire.png';
    }
    if (type.contains('eeco')) {
      return 'assets/images/raahi_assets/vehicles/eeco.png';
    }
    if (type.contains('ertiga')) {
      return 'assets/images/raahi_assets/vehicles/ertiga.png';
    }
    if (type.contains('innova')) {
      return 'assets/images/raahi_assets/vehicles/innova.png';
    }
    if (type.contains('urbania')) {
      return 'assets/images/raahi_assets/vehicles/urbania.png';
    }

    return '';
  }

  bool get canTrack =>
      status == 'driver_assigned' ||
      status == 'accepted' ||
      status == 'ongoing';

  void trackRide(BuildContext context) {
    final id = int.tryParse(booking['id']?.toString() ?? '');
    if (id == null) {
      _message(context, 'Booking ID is not available');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(bookingId: id),
      ),
    );
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: 390,
                  height: 820,
                  child: _design(context),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _design(BuildContext context) {
    return Column(
        mainAxisSize: MainAxisSize.max,
        children: [
            _header(context),
            const SizedBox(height: 5),
            _statusBanner(),
            const SizedBox(height: 5),
            _mapView(),
            const SizedBox(height: 3),
            _locations(),
            const SizedBox(height: 3),
            _driverVehicle(),
            const SizedBox(height: 5),
            _tripStats(),
            const SizedBox(height: 5),
            _fareCard(),
            const SizedBox(height: 5),
            _paymentStrip(),
            const SizedBox(height: 5),
            _bookingInfo(),
            const Spacer(),
            _actions(context),
            const SizedBox(height: 4),
            _footer(),
        ],
    );
  }

  

  Widget _header(BuildContext context) {
    return SizedBox(
      height: 74,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 7,
            top: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back,
                size: 27,
                color: navy,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/raahi_assets/brand/raahi_logo.png',
                height: 42,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: 25,
                  color: navy,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBanner() {
    final completed = status == 'completed';

    return Container(
      height: 57,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F5FD),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            height: 39,
            width: 39,
            decoration: const BoxDecoration(
              color: green,
              shape: BoxShape.circle,
            ),
            child: Icon(
              completed ? Icons.check : Icons.directions_car,
              color: Colors.white,
              size: 27,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Your booking details',
                  style: TextStyle(
                    color: navy,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 38, color: Colors.blueGrey),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Total Fare',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                totalFare,
                style: const TextStyle(
                  fontSize: 20,
                  color: green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mapView() {
    return Container(
      height: 78,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFE6F2E8),
        borderRadius: BorderRadius.circular(13),
      ),
      child: CustomPaint(
        painter: _MapPainter(),
        child: Stack(
          children: [
            Positioned(
              left: 12,
              top: 29,
              child: _mapLabel(pickup),
            ),
            Positioned(
              right: 12,
              top: 29,
              child: _mapLabel(destination),
            ),
            const Positioned(
              left: 62,
              top: 5,
              child: Icon(
                Icons.location_on,
                color: green,
                size: 30,
              ),
            ),
            const Positioned(
              right: 67,
              top: 5,
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 30,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 29,
              child: Icon(
                Icons.directions_car,
                color: navy,
                size: 23,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapLabel(String text) {
    return SizedBox(
      width: 105,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: navy,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _locations() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Column(
        children: [
          _locationRow(
            'Pickup',
            pickup,
            date(booking['scheduled_at']),
            green,
            Icons.radio_button_checked,
          ),
          const Divider(height: 5, color: border),
          _locationRow(
            'Drop',
            destination,
            val(booking['drop_time'] ?? booking['completed_at']) == 'N/A'
                ? 'N/A'
                : date(booking['completed_at']),
            Colors.red,
            Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _locationRow(
    String label,
    String address,
    String time,
    Color color,
    IconData icon,
  ) {
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(.13),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      color: color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.calendar_month, size: 13, color: navy),
          const SizedBox(width: 4),
          Text(
            time,
            style: const TextStyle(
              fontSize: 9,
              color: navy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverVehicle() {
    final driverName = val(booking['driver_name']);
    final driverPhoto = booking['driver_photo'] ?? booking['driver_image'];

    return Container(
      height: 73,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: border),
          bottom: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFFE7F5EF),
            backgroundImage: driverPhoto is String &&
                    driverPhoto.startsWith('http')
                ? NetworkImage(driverPhoto)
                : null,
            child: driverPhoto == null
                ? Text(
                    driverName == 'N/A'
                        ? '?'
                        : driverName[0].toUpperCase(),
                    style: const TextStyle(
                      color: green,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 7),
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '★ ${val(booking['driver_rating'])}  '
                  '(${val(booking['driver_rides'])} rides)',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  '✓ Verified Driver',
                  style: TextStyle(
                    fontSize: 9,
                    color: green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 48, width: 1, color: border),
          const SizedBox(width: 5),
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: vehicleAsset.isEmpty
                      ? const Icon(
                          Icons.directions_car,
                          size: 38,
                          color: navy,
                        )
                      : Image.asset(
                          vehicleAsset,
                          height: 48,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car,
                            size: 38,
                            color: navy,
                          ),
                        ),
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: navy,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        val(
                          booking['vehicle_number'] ??
                              booking['registration_number'],
                        ),
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
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
    );
  }

  Widget _tripStats() {
    final distance = route['distance_km'];
    final duration = booking['duration'] ?? booking['duration_minutes'];

    return SizedBox(
      height: 43,
      child: Row(
        children: [
          _stat(Icons.directions_car_outlined, 'Trip Type',
              val(booking['trip_type']).replaceAll('_', ' ')),
          _stat(Icons.route_outlined, 'Distance',
              distance == null ? 'N/A' : '$distance km'),
          _stat(Icons.access_time, 'Duration',
              duration == null ? 'N/A' : '$duration'),
          _stat(Icons.person_outline, 'Passengers',
              val(booking['passenger_count'])),
        ],
      ),
    );
  }

  Widget _stat(IconData icon, String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: border)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: navy),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, maxLines: 1,
                      style: const TextStyle(fontSize: 8)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9,
                      color: navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fareCard() {
    final base = booking['base_fare'];
    final distanceCharge = booking['distance_charge'];
    final allowance = booking['driver_allowance'];
    final toll = booking['toll_charges'];
    final parking = booking['parking_charges'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long, color: green, size: 22),
              SizedBox(width: 7),
              Text(
                'Fare Summary',
                style: TextStyle(
                  color: navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _fareLine('Base Fare', money(base)),
          _fareLine('Distance Charge', money(distanceCharge)),
          _fareLine('Driver Allowance', money(allowance)),
          _fareLine('Toll Charges', money(toll)),
          _fareLine('Parking Charges', money(parking)),
          Container(
            height: 29,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: paleGreen,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Fare',
                  style: TextStyle(
                    color: navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  totalFare,
                  style: const TextStyle(
                    color: green,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fareLine(String label, String amount) {
    return SizedBox(
      height: 21,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 10, color: navy),
            ),
          ),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 10,
              color: navy,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentStrip() {
    return Container(
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: paleGreen,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: green, size: 23),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Payment Status',
              style: TextStyle(
                fontSize: 12,
                color: navy,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            val(booking['payment_status']),
            style: const TextStyle(
              color: green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.account_balance_wallet,
              color: Colors.deepOrange, size: 20),
        ],
      ),
    );
  }

  Widget _bookingInfo() {
    return Container(
      height: 43,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(Icons.receipt_long, color: green, size: 22),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking ID', style: TextStyle(fontSize: 9)),
                Text(
                  val(booking['id']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: navy,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 30, width: 1, color: border),
          const SizedBox(width: 8),
          const Icon(Icons.calendar_month, color: green, size: 22),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Booking Date & Time',
                    style: TextStyle(fontSize: 9)),
                Text(
                  date(booking['created_at']),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          _action(
            Icons.headset_mic_outlined,
            'Contact Support',
            () => _message(context, 'Support contact is not configured.'),
          ),
          const SizedBox(width: 6),
          _action(
            Icons.download_outlined,
            'Download Invoice',
            () => _message(context, 'Invoice generation is not configured.'),
          ),
          const SizedBox(width: 6),
          _action(
            Icons.share_outlined,
            'Share Trip',
            () => _message(context, 'Trip sharing is not configured.'),
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: SizedBox(
        height: 34,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: green,
            padding: const EdgeInsets.symmetric(horizontal: 2),
            side: const BorderSide(color: green),
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    color: navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _footer() {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline5.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE7F3E8);
    canvas.drawRect(Offset.zero & size, background);

    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final smallRoad = Paint()
      ..color = const Color(0xFFD0E4D0)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final path = Path()
        ..moveTo(0, i * 22.0)
        ..quadraticBezierTo(
          size.width * .45,
          i * 22.0 + 12,
          size.width,
          i * 22.0 - 5,
        );
      canvas.drawPath(path, smallRoad);
    }

    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(i * 75.0, 0),
        Offset(i * 75.0 + 25, size.height),
        smallRoad,
      );
    }

    final route = Path()
      ..moveTo(size.width * .19, size.height * .62)
      ..cubicTo(
        size.width * .37,
        size.height * .15,
        size.width * .60,
        size.height * .92,
        size.width * .82,
        size.height * .60,
      );

    final routePaint = Paint()
      ..color = const Color(0xFF1878E8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
