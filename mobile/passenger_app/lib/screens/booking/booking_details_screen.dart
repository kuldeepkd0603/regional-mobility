import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String tripType;
  final String vehicleModel;
  final double distanceKm;
  final String pickupAddress;
  final String dropAddress;
  final String pickupCity;
  final String dropCity;
  final dynamic estimatedFare;

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
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  DateTime? _travelDate;
  TimeOfDay? _travelTime;
  DateTime? _returnDate;
  TimeOfDay? _returnTime;
  int _passengerCount = 1;
  final TextEditingController _instructionsController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic>? _bookingResult;
  String? _errorMessage;

  bool get _isRoundTrip => widget.tripType.toLowerCase() == 'round_trip';

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  DateTime? _combineDateAndTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _selectTravelDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _travelDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _travelDate = picked);
  }

  Future<void> _selectTravelTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _travelTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _travelTime = picked);
  }

  Future<void> _selectReturnDate() async {
    final now = _travelDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _returnDate = picked);
  }

  Future<void> _selectReturnTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _returnTime ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _returnTime = picked);
  }

  String _dateLabel(DateTime? value) {
    if (value == null) return 'Select date';
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  String _timeLabel(TimeOfDay? value) =>
      value == null ? 'Select time' : value.format(context);

  int? _readPassengerId(Map<String, dynamic> user) {
    final candidates = [user['id'], user['user_id'], user['passenger_id']];
    for (final value in candidates) {
      if (value is int) return value;
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  Future<void> _submitBooking() async {
    final scheduledAt = _combineDateAndTime(_travelDate, _travelTime);
    if (scheduledAt == null) {
      setState(() => _errorMessage = 'Please select your travel date and time.');
      return;
    }
    if (scheduledAt.isBefore(DateTime.now())) {
      setState(() => _errorMessage = 'Travel date and time must be in the future.');
      return;
    }

    DateTime? returnAt;
    if (_isRoundTrip) {
      returnAt = _combineDateAndTime(_returnDate, _returnTime);
      if (returnAt == null) {
        setState(() => _errorMessage = 'Please select your return date and time.');
        return;
      }
      if (!returnAt.isAfter(scheduledAt)) {
        setState(() => _errorMessage = 'Return date and time must be after departure.');
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.getCurrentUser();
      final passengerId = _readPassengerId(user);
      if (passengerId == null) {
        throw Exception('Could not find your passenger ID in the login profile. Please share the /auth/me response with support.');
      }

      final result = await ApiService.createBooking(
        passengerId: passengerId,
        tripType: widget.tripType,
        preferredVehicleType: widget.vehicleModel,
        pickupCity: widget.pickupCity,
        dropCity: widget.dropCity,
        pickupAddress: widget.pickupAddress,
        dropAddress: widget.dropAddress,
        distanceKm: widget.distanceKm,
        scheduledAt: scheduledAt,
        returnAt: returnAt,
        passengerCount: _passengerCount,
        specialInstructions: _instructionsController.text.trim().isEmpty
            ? null
            : _instructionsController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _bookingResult = result;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });
    }
  }

  Widget _sectionCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _pickerRow({required String title, required String value, required VoidCallback onTap, required IconData icon}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppColors.textGrey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ])),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final booking = _bookingResult;
    if (booking != null) return _successView(booking);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Journey', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _sectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.trip_origin, color: Colors.green), const SizedBox(width: 10),
              Expanded(child: Text('${widget.pickupAddress}\n${widget.pickupCity}', style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            const Padding(padding: EdgeInsets.only(left: 10, top: 8, bottom: 8), child: Icon(Icons.more_vert, size: 18, color: Colors.grey)),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.location_on, color: Colors.red), const SizedBox(width: 10),
              Expanded(child: Text('${widget.dropAddress}\n${widget.dropCity}', style: const TextStyle(fontWeight: FontWeight.w600))),
            ]),
            const Divider(height: 24),
            Text('Vehicle: ${widget.vehicleModel.toUpperCase()}'),
            const SizedBox(height: 6),
            Text('Distance: ${widget.distanceKm.toStringAsFixed(2)} km'),
            const SizedBox(height: 6),
            Text('Estimated fare: ₹${widget.estimatedFare}'),
          ])),
          const SizedBox(height: 20),
          const Text('Travel Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _sectionCard(child: Column(children: [
            _pickerRow(title: 'Travel date', value: _dateLabel(_travelDate), onTap: _selectTravelDate, icon: Icons.calendar_today),
            const Divider(height: 1),
            _pickerRow(title: 'Departure time', value: _timeLabel(_travelTime), onTap: _selectTravelTime, icon: Icons.access_time),
            if (_isRoundTrip) ...[
              const Divider(height: 1),
              _pickerRow(title: 'Return date', value: _dateLabel(_returnDate), onTap: _selectReturnDate, icon: Icons.event_repeat),
              const Divider(height: 1),
              _pickerRow(title: 'Return time', value: _timeLabel(_returnTime), onTap: _selectReturnTime, icon: Icons.access_time),
            ],
          ])),
          const SizedBox(height: 20),
          const Text('Passengers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _sectionCard(child: Row(children: [
            const Expanded(child: Text('Number of passengers', style: TextStyle(fontWeight: FontWeight.w600))),
            IconButton(onPressed: _passengerCount > 1 ? () => setState(() => _passengerCount--) : null, icon: const Icon(Icons.remove_circle_outline)),
            Text('$_passengerCount', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: _passengerCount < 12 ? () => setState(() => _passengerCount++) : null, icon: const Icon(Icons.add_circle_outline)),
          ])),
          const SizedBox(height: 20),
          const Text('Special instructions (optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          TextField(
            controller: _instructionsController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any luggage, pickup landmark or other request...',
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitBooking,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Booking Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Your booking will remain pending until an admin assigns a driver.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _successView(Map<String, dynamic> booking) {
    final bookingId = booking['booking_id'] ?? booking['id'] ?? 'Submitted';
    final status = booking['status']?.toString().toUpperCase() ?? 'PENDING';
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 76),
          const SizedBox(height: 18),
          const Text('Booking Request Submitted', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Booking ID: $bookingId', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Status: $status', style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 14),
          const Text('Your request has been sent. A driver will be assigned after admin confirmation.', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Back to Home'),
          )),
        ],
      ))),
    );
  }
}
