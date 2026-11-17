
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'booking_confirmation_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String tripType;
  final String vehicleModel;
  final double distanceKm;
  final String pickupAddress;
  final String dropAddress;
  final String pickupCity;
  final String dropCity;
  final dynamic estimatedFare;

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropLatitude;
  final double? dropLongitude;

  const BookingDetailsScreen({
    super.key,
    required this.tripType,
    required this.vehicleModel,
    required this.distanceKm,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupCity,
    required this.dropCity,
    required this.estimatedFare,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropLatitude,
    this.dropLongitude,
  });

  @override
  State<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  DateTime? _travelDate;
  TimeOfDay? _travelTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;

  int _passengerCount = 1;
  int _luggageCount = 0;

  final TextEditingController _instructionsController =
      TextEditingController();

  String? _errorMessage;

  bool get _isRoundTrip =>
      widget.tripType.toLowerCase() == 'round_trip';

  static const Color navy = Color(0xFF07516B);
  static const Color teal = Color(0xFF159B7C);
  static const Color mint = Color(0xFFE5F7F2);
  static const Color borderColor = Color(0xFFE2E7EB);
  static const Color dark = Color(0xFF17212B);
  static const Color grey = Color(0xFF68727D);
  static const Color green = Color(0xFF168044);

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  String get _vehicleName {
    final value = widget.vehicleModel.trim();
    if (value.isEmpty) return 'Vehicle';
    return value[0].toUpperCase() + value.substring(1);
  }

  String get _vehicleSeats {
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
        return 'Luxury Van • 17 Seater';
      default:
        return 'Comfortable Travel';
    }
  }

  String get _vehicleImage =>
      'assets/images/raahi_assets/vehicles/${widget.vehicleModel.toLowerCase()}.png';

  String get _fareLabel {
    final amount = double.tryParse(widget.estimatedFare.toString());
    if (amount == null) return '₹${widget.estimatedFare}';
    return '₹${amount.toStringAsFixed(0)}';
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

  DateTime? _combineDateAndTime(
    DateTime? date,
    TimeOfDay? time,
  ) {
    if (date == null || time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _selectTravelDate() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: teal,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _travelDate = picked;
        _errorMessage = null;

        if (_returnDate != null &&
            _returnDate!.isBefore(picked)) {
          _returnDate = null;
          _returnTime = null;
        }
      });
    }
  }

  Future<void> _selectTravelTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _travelTime ?? TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: teal,
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _travelTime = picked;
        _errorMessage = null;
      });
    }
  }

  Future<void> _selectReturnDate() async {
    final now = _travelDate ?? DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked != null) {
      setState(() => _returnDate = picked);
    }
  }

  Future<void> _selectReturnTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() => _returnTime = picked);
    }
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Select date';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    const weekdays = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    return '${weekdays[value.weekday - 1]}, ${value.day} ${months[value.month - 1]}';
  }

  String _timeLabel(TimeOfDay? value) {
    return value == null ? 'Select time' : value.format(context);
  }

  // ---------------- HEADER ----------------

  Widget _header() {
    return SizedBox(
      height: 85,
      child: Column(
        children: [
          SizedBox(
            height: 45,
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
                  height: 44,
                  width: 145,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
          const Text(
            'Schedule Your Ride',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w800,
              color: dark,
            ),
          ),
          const Text(
            'Choose your preferred date, time and other details',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: grey,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ROUTE CARD ----------------

  Widget _routeLine(
    IconData icon,
    Color color,
    String city,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            city.isEmpty ? '—' : city,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _routeCard() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
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
          Container(
            height: 50,
            width: 1,
            color: borderColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.route, size: 17),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '~ ${widget.distanceKm.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: dark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                const Row(
                  children: [
                    Icon(Icons.access_time, size: 17),
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
        ],
      ),
    );
  }

  // ---------------- VEHICLE CARD ----------------

  Widget _vehicleCard() {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 65,
            child: Image.asset(
              _vehicleImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car,
                size: 43,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                Text(
                  _vehicleSeats,
                  style: const TextStyle(
                    fontSize: 10,
                    color: dark,
                  ),
                ),
                const SizedBox(height: 3),
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
          Container(height: 45, width: 1, color: borderColor),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'To change vehicle, go back to Vehicle Selection.',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Change',
              style: TextStyle(
                fontSize: 12,
                color: teal,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SECTION TITLE ----------------

  Widget _sectionTitle(
    IconData icon,
    String title, {
    String? trailing,
  }) {
    return Row(
      children: [
        Icon(icon, color: teal, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: dark,
            ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 11,
              color: teal,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  // ---------------- DATE AND TIME ----------------

  Widget _selectionBox({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 59,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 21, color: teal),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 10,
                        color: grey,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
        ),
      ),
    );
  }

  Widget _dateTimeSelectors() {
    return Row(
      children: [
        _selectionBox(
          icon: Icons.calendar_month,
          title: 'Travel Date',
          value: _dateLabel(_travelDate),
          onTap: _selectTravelDate,
        ),
        const SizedBox(width: 9),
        _selectionBox(
          icon: Icons.access_time,
          title: 'Pickup Time',
          value: _timeLabel(_travelTime),
          onTap: _selectTravelTime,
        ),
      ],
    );
  }

  // ---------------- COUNTERS ----------------

  Widget _counterRow({
    required IconData icon,
    required String title,
    String? subtitle,
    required int value,
    required int minimum,
    required int maximum,
    required VoidCallback onMinus,
    required VoidCallback onPlus,
  }) {
    return SizedBox(
      height: 43,
      child: Row(
        children: [
          Icon(icon, color: teal, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: dark,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 9,
                      color: grey,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 34,
            decoration: BoxDecoration(
              border: Border.all(color: teal),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _counterButton(
                  Icons.remove,
                  value > minimum ? onMinus : null,
                ),
                SizedBox(
                  width: 23,
                  child: Text(
                    '$value',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _counterButton(
                  Icons.add,
                  value < maximum ? onPlus : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _counterButton(
    IconData icon,
    VoidCallback? onPressed,
  ) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: teal),
      ),
    );
  }

  // ---------------- INSTRUCTIONS ----------------

  Widget _instructionsField() {
    return TextField(
      controller: _instructionsController,
      maxLines: 2,
      maxLength: 200,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        hintText: 'Hotel pickup, extra stop, elderly passenger, etc.',
        hintStyle: const TextStyle(
          fontSize: 11,
          color: grey,
        ),
        counterStyle: const TextStyle(
          fontSize: 9,
          color: grey,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: teal),
        ),
      ),
    );
  }

  // ---------------- FARE ----------------

  Widget _fareCard() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: mint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 21,
            color: teal,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Estimated Fare',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: dark,
              ),
            ),
          ),
          Text(
            _fareLabel,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: green,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SKYLINE ----------------

  Widget _skyline() {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline5.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  // ---------------- BUTTON ----------------

  Widget _confirmButton() {
    return SizedBox(
      height: 51,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _confirmSchedule,
        style: ElevatedButton.styleFrom(
          backgroundColor: navy,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Confirm Schedule',
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

  // ---------------- ROUND TRIP ----------------

  Widget _returnSelectors() {
    return Row(
      children: [
        _selectionBox(
          icon: Icons.calendar_month,
          title: 'Return Date',
          value: _dateLabel(_returnDate),
          onTap: _selectReturnDate,
        ),
        const SizedBox(width: 9),
        _selectionBox(
          icon: Icons.access_time,
          title: 'Return Time',
          value: _timeLabel(_returnTime),
          onTap: _selectReturnTime,
        ),
      ],
    );
  }

  // ---------------- VALIDATION AND NAVIGATION ----------------

  Future<void> _confirmSchedule() async {
    final scheduledAt = _combineDateAndTime(
      _travelDate,
      _travelTime,
    );

    if (scheduledAt == null) {
      setState(() {
        _errorMessage = 'Please select your travel date and time.';
      });
      return;
    }

    if (scheduledAt.isBefore(DateTime.now())) {
      setState(() {
        _errorMessage = 'Travel date and time must be in the future.';
      });
      return;
    }

    DateTime? returnAt;

    if (_isRoundTrip) {
      returnAt = _combineDateAndTime(
        _returnDate,
        _returnTime,
      );

      if (returnAt == null) {
        setState(() {
          _errorMessage = 'Please select your return date and time.';
        });
        return;
      }

      if (!returnAt.isAfter(scheduledAt)) {
        setState(() {
          _errorMessage =
              'Return date and time must be after departure.';
        });
        return;
      }
    }

    setState(() => _errorMessage = null);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(
          tripType: widget.tripType,
          vehicleModel: widget.vehicleModel,
          distanceKm: widget.distanceKm,
          pickupAddress: widget.pickupAddress,
          dropAddress: widget.dropAddress,
          pickupCity: widget.pickupCity,
          dropCity: widget.dropCity,
          estimatedFare: widget.estimatedFare,
          scheduledAt: scheduledAt,
          returnAt: returnAt,
          passengerCount: _passengerCount,
          luggageCount: _luggageCount,
          specialInstructions:
              _instructionsController.text.trim(),
          pickupLatitude: widget.pickupLatitude,
          pickupLongitude: widget.pickupLongitude,
          dropLatitude: widget.dropLatitude,
          dropLongitude: widget.dropLongitude,
        ),
      ),
    );
  }

  // ---------------- RESPONSIVE ONE-PAGE SCREEN ----------------

  Widget _scheduleContent() {
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
                    const SizedBox(height: 5),

                    _routeCard(),
                    const SizedBox(height: 8),

                    _vehicleCard(),
                    const SizedBox(height: 13),

                    _sectionTitle(
                      Icons.calendar_month,
                      'Select Date',
                    ),
                    const SizedBox(height: 7),
                    _dateTimeSelectors(),

                    if (_isRoundTrip) ...[
                      const SizedBox(height: 9),
                      _sectionTitle(
                        Icons.event_repeat,
                        'Return Schedule',
                      ),
                      const SizedBox(height: 7),
                      _returnSelectors(),
                    ],

                    const SizedBox(height: 9),

                    _counterRow(
                      icon: Icons.person_outline,
                      title: 'Number of Passengers',
                      value: _passengerCount,
                      minimum: 1,
                      maximum: 12,
                      onMinus: () {
                        setState(() => _passengerCount--);
                      },
                      onPlus: () {
                        setState(() => _passengerCount++);
                      },
                    ),

                    _counterRow(
                      icon: Icons.work_outline,
                      title: 'Luggage (Optional)',
                      subtitle: 'Helps arrange a suitable vehicle',
                      value: _luggageCount,
                      minimum: 0,
                      maximum: 10,
                      onMinus: () {
                        setState(() => _luggageCount--);
                      },
                      onPlus: () {
                        setState(() => _luggageCount++);
                      },
                    ),

                    const SizedBox(height: 5),

                    _sectionTitle(
                      Icons.description_outlined,
                      'Special Instructions',
                      trailing: 'Optional',
                    ),
                    const SizedBox(height: 6),
                    _instructionsField(),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    _fareCard(),

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
        child: _scheduleContent(),
      ),
    );
  }
}
