
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'find_your_driver_screen.dart';

class BookingConfirmationScreen extends StatefulWidget {
  final String tripType;
  final String vehicleModel;
  final double distanceKm;
  final String pickupAddress;
  final String dropAddress;
  final String pickupCity;
  final String dropCity;
  final dynamic estimatedFare;
  final DateTime scheduledAt;
  final DateTime? returnAt;
  final int passengerCount;
  final int luggageCount;
  final String specialInstructions;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;

  const BookingConfirmationScreen({
    super.key,
    required this.tripType,
    required this.vehicleModel,
    required this.distanceKm,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupCity,
    required this.dropCity,
    required this.estimatedFare,
    required this.scheduledAt,
    this.returnAt,
    required this.passengerCount,
    required this.luggageCount,
    required this.specialInstructions,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState
    extends State<BookingConfirmationScreen> {
  static const Color navy = Color(0xFF07516B);
  static const Color teal = Color(0xFF159B7C);
  static const Color mint = Color(0xFFE5F7F2);
  static const Color border = Color(0xFFE2E7EB);
  static const Color dark = Color(0xFF17212B);
  static const Color grey = Color(0xFF68727D);
  static const Color green = Color(0xFF168044);

  String selectedPayment = 'cash';
  bool isSubmitting = false;
  String? errorMessage;

  String get _vehicleName {
    final value = widget.vehicleModel.trim();
    if (value.isEmpty) return 'Vehicle';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get _vehicleImage =>
      'assets/images/raahi_assets/vehicles/${widget.vehicleModel.toLowerCase()}.png';

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

  String get _fare {
    final value = double.tryParse(widget.estimatedFare.toString());
    if (value == null) return '₹${widget.estimatedFare}';
    return '₹${value.toStringAsFixed(0)}';
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

  String _date(DateTime value) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];

    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _time(DateTime value) {
    return TimeOfDay.fromDateTime(value).format(context);
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return SizedBox(
      height: 82,
      child: Column(
        children: [
          SizedBox(
            height: 43,
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
                      color: dark,
                      size: 25,
                    ),
                  ),
                ),
                Image.asset(
                  'assets/images/raahi_assets/brand/raahi_logo.png',
                  width: 145,
                  height: 42,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const Text(
            'Booking Confirmation',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const Text(
            'Review your booking details before confirming',
            style: TextStyle(fontSize: 10, color: grey),
          ),
        ],
      ),
    );
  }

  // ---------------- ROUTE ----------------

  Widget _routeLine(
    IconData icon,
    Color color,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value.isEmpty ? '—' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: dark,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _routeCard() {
    return Container(
      height: 67,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _routeLine(
                  Icons.location_on,
                  teal,
                  widget.pickupCity,
                ),
                const SizedBox(height: 6),
                _routeLine(
                  Icons.location_on,
                  Colors.redAccent,
                  widget.dropCity,
                ),
              ],
            ),
          ),
          Container(width: 1, height: 45, color: border),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.route, size: 17, color: dark),
                const SizedBox(height: 3),
                Text(
                  '${widget.distanceKm.toStringAsFixed(1)} km',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- VEHICLE ----------------

  Widget _vehicleCard() {
    return Container(
      height: 69,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 95,
            height: 60,
            child: Image.asset(
              _vehicleImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car,
                color: navy,
                size: 42,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vehicleName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                Text(
                  _vehicleDescription,
                  style: const TextStyle(fontSize: 10, color: grey),
                ),
                Text(
                  _tripLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: teal,
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

  // ---------------- SECTION TITLE ----------------

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: dark,
        ),
      ),
    );
  }

  // ---------------- TRIP DETAILS ----------------

  Widget _detailCell(
    IconData icon,
    String title,
    String value,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 19, color: teal),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    color: grey,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripDetails() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _detailCell(
                Icons.calendar_month,
                'Travel Date',
                _date(widget.scheduledAt),
              ),
              _detailCell(
                Icons.access_time,
                'Pickup Time',
                _time(widget.scheduledAt),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _detailCell(
                Icons.people_outline,
                'Passengers',
                '${widget.passengerCount}',
              ),
              _detailCell(
                Icons.work_outline,
                'Luggage',
                '${widget.luggageCount}',
              ),
            ],
          ),
          if (widget.returnAt != null) ...[
            const SizedBox(height: 11),
            Row(
              children: [
                _detailCell(
                  Icons.event_repeat,
                  'Return Date',
                  _date(widget.returnAt!),
                ),
                _detailCell(
                  Icons.access_time,
                  'Return Time',
                  _time(widget.returnAt!),
                ),
              ],
            ),
          ],
          if (widget.specialInstructions.trim().isNotEmpty) ...[
            const Divider(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.notes,
                  size: 18,
                  color: teal,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.specialInstructions,
                    style: const TextStyle(
                      fontSize: 10,
                      color: dark,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- FARE SUMMARY ----------------

  Widget _fareSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Estimated Trip Fare',
                  style: TextStyle(fontSize: 12, color: dark),
                ),
              ),
              Text(
                _fare,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: dark,
                ),
              ),
            ],
          ),
          const Divider(height: 15),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Total Estimated Fare',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
              ),
              Text(
                _fare,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- PAYMENT METHODS ----------------

  Widget _paymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final selected = selectedPayment == id;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => selectedPayment = id);
        },
        borderRadius: BorderRadius.circular(11),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? mint : Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: selected ? teal : border,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? teal : grey,
                size: 21,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: selected ? teal : dark,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8,
                        color: grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 15,
                  color: teal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Select Payment Method'),
        const SizedBox(height: 7),
        Row(
          children: [
            _paymentOption(
              id: 'upi',
              icon: Icons.qr_code,
              title: 'UPI',
              subtitle: 'Online',
            ),
            const SizedBox(width: 7),
            _paymentOption(
              id: 'card',
              icon: Icons.credit_card,
              title: 'Card',
              subtitle: 'Debit/Credit',
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            _paymentOption(
              id: 'wallet',
              icon: Icons.account_balance_wallet_outlined,
              title: 'Wallet',
              subtitle: 'Online',
            ),
            const SizedBox(width: 7),
            _paymentOption(
              id: 'cash',
              icon: Icons.payments_outlined,
              title: 'Cash to Driver',
              subtitle: 'Pay after ride',
            ),
          ],
        ),
      ],
    );
  }

  // ---------------- SKYLINE ----------------

  Widget _skyline() {
    return SizedBox(
      height: 28,
      width: double.infinity,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline5.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  // ---------------- CONFIRM BUTTON ----------------

  Widget _confirmButton() {
    return SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _confirmBooking,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: navy.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Confirm Booking',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, size: 21),
                ],
              ),
      ),
    );
  }

  // ---------------- CREATE BOOKING ----------------

  Future<void> _confirmBooking() async {
    if (isSubmitting) return;

    setState(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final user = await ApiService.getCurrentUser();

      final passengerId = int.tryParse(
        (user['id'] ?? user['user_id'] ?? user['passenger_id'])
            .toString(),
      );

      if (passengerId == null) {
        throw Exception(
          'Passenger account not found. Please log in again.',
        );
      }

      final booking = await ApiService.createBooking(
        passengerId: passengerId,
        tripType: widget.tripType,
        preferredVehicleType: widget.vehicleModel,
        pickupCity: widget.pickupCity,
        dropCity: widget.dropCity,
        pickupAddress: widget.pickupAddress,
        dropAddress: widget.dropAddress,
        distanceKm: widget.distanceKm,
        scheduledAt: widget.scheduledAt,
        returnAt: widget.returnAt,
        passengerCount: widget.passengerCount,
        specialInstructions: widget.specialInstructions,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FindYourDriverScreen(
            booking: booking,
            pickupLatitude: widget.pickupLatitude,
            pickupLongitude: widget.pickupLongitude,
            vehicleType: widget.vehicleModel,
            passengerCount: widget.passengerCount,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isSubmitting = false;
      });
    }
  }

  // ---------------- RESPONSIVE ONE-PAGE LAYOUT ----------------

  Widget _confirmationContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
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
                    const SizedBox(height: 4),
                    _routeCard(),
                    const SizedBox(height: 7),
                    _vehicleCard(),
                    const SizedBox(height: 9),
                    _sectionTitle('Trip Details'),
                    const SizedBox(height: 6),
                    _tripDetails(),
                    const SizedBox(height: 9),
                    _sectionTitle('Fare Summary'),
                    const SizedBox(height: 6),
                    _fareSummary(),
                    const SizedBox(height: 9),
                    _paymentSection(),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        errorMessage!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                        ),
                      ),
                    ],

                    const Spacer(),
                    _skyline(),
                    const SizedBox(height: 4),
                    _confirmButton(),
                    const SizedBox(height: 4),
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
        child: _confirmationContent(),
      ),
    );
  }
}
