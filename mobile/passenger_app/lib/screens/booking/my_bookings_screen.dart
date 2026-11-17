
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'live_tracking_screen.dart';
import 'booking_summary_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool isLoading = true;
  String? errorMessage;

  List<Map<String, dynamic>> bookings = [];

  String selectedFilter = 'All Bookings';
  DateTime? selectedDate;

  static const Color navy = Color(0xFF064B68);
  static const Color teal = Color(0xFF159B7C);
  static const Color background = Color(0xFFF5F8F9);
  static const Color borderColor = Color(0xFFE2E9EC);

  static const String logoPath =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  static const String skylinePath =
      'assets/images/raahi_assets/header/city_skyline5.png';

  static const List<String> filters = [
    'All Bookings',
    'Upcoming',
    'Ongoing',
    'Completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getMyBookings();

      if (!mounted) return;

      setState(() {
        bookings = result;
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

  String _status(Map<String, dynamic> booking) {
    return (booking['booking_status'] ?? '')
        .toString()
        .toLowerCase()
        .trim();
  }

  bool _isUpcoming(String status) {
    return [
      'pending',
      'accepted',
      'driver_assigned',
    ].contains(status);
  }

  List<Map<String, dynamic>> get filteredBookings {
    List<Map<String, dynamic>> result;

    switch (selectedFilter) {
      case 'Upcoming':
        result = bookings.where((b) => _isUpcoming(_status(b))).toList();
        break;

      case 'Ongoing':
        result = bookings.where((b) => _status(b) == 'ongoing').toList();
        break;

      case 'Completed':
        result = bookings.where((b) => _status(b) == 'completed').toList();
        break;

      default:
        result = List<Map<String, dynamic>>.from(bookings);
    }

    if (selectedDate != null) {
      result = result.where((booking) {
        final date = DateTime.tryParse(
          booking['scheduled_at']?.toString() ?? '',
        )?.toLocal();

        return date != null &&
            date.year == selectedDate!.year &&
            date.month == selectedDate!.month &&
            date.day == selectedDate!.day;
      }).toList();
    }

    return result;
  }

  Map<String, dynamic> _route(Map<String, dynamic> booking) {
    final value = booking['route'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  String _value(dynamic value, {String fallback = 'N/A'}) {
    if (value == null) return fallback;

    final text = value.toString().trim();

    if (text.isEmpty || text.toLowerCase() == 'null') {
      return fallback;
    }

    return text;
  }

  String _prettyStatus(String status) {
    if (status.isEmpty) return 'Unknown';

    return status
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFF2878C8);

      case 'accepted':
      case 'driver_assigned':
        return const Color(0xFF2878C8);

      case 'ongoing':
        return const Color(0xFF159B7C);

      case 'completed':
        return const Color(0xFF159B45);

      case 'cancelled':
        return const Color(0xFFD84B4B);

      default:
        return AppColors.textGrey;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'ongoing':
        return const Color(0xFFE0F8EB);

      case 'completed':
        return const Color(0xFFE0F8E8);

      case 'cancelled':
        return const Color(0xFFFFEAEA);

      case 'pending':
      case 'accepted':
      case 'driver_assigned':
        return const Color(0xFFE5F3FF);

      default:
        return const Color(0xFFF0F2F3);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not scheduled';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Not scheduled';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year}  •  '
        '$hour:$minute $period';
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');

    return amount == null
        ? 'N/A'
        : '₹${amount.toStringAsFixed(0)}';
  }

  String _vehicleName(Map<String, dynamic> booking) {
    return _value(
      booking['vehicle_name'] ??
          booking['preferred_vehicle_type'],
    );
  }

  String _vehicleImage(Map<String, dynamic> booking) {
    final vehicle = _vehicleName(booking).toLowerCase();

    if (vehicle.contains('dzire')) {
      return 'assets/images/raahi_assets/vehicles/dzire.png';
    }

    if (vehicle.contains('eeco')) {
      return 'assets/images/raahi_assets/vehicles/eeco.png';
    }

    if (vehicle.contains('ertiga')) {
      return 'assets/images/raahi_assets/vehicles/ertiga.png';
    }

    if (vehicle.contains('innova')) {
      return 'assets/images/raahi_assets/vehicles/innova.png';
    }

    if (vehicle.contains('urbania')) {
      return 'assets/images/raahi_assets/vehicles/urbania.png';
    }

    return 'assets/images/raahi_dzire_car.png';
  }

  String _pickup(Map<String, dynamic> booking) {
    final route = _route(booking);

    return _value(
      route['pickup_city'] ??
          route['pickup_address'] ??
          booking['pickup_address'] ??
          booking['pickup_location'],
    );
  }

  String _drop(Map<String, dynamic> booking) {
    final route = _route(booking);

    return _value(
      route['drop_city'] ??
          route['drop_address'] ??
          booking['destination_address'] ??
          booking['destination_location'],
    );
  }

  String _registration(Map<String, dynamic> booking) {
    return _value(
      booking['registration_number'] ??
          booking['vehicle_number'] ??
          booking['vehicle_registration'],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select booking date',
    );

    if (picked != null && mounted) {
      setState(() => selectedDate = picked);
    }
  }

  void _openDetails(Map<String, dynamic> booking) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookingSummaryScreen(booking: booking),
      ),
    ).then((wasUpdated) {
      if (wasUpdated == true && mounted) {
        _loadBookings();
      }
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _trackRide(Map<String, dynamic> booking) {
    final bookingId = int.tryParse(booking['id']?.toString() ?? '');

    if (bookingId == null) {
      _showMessage('Invalid booking ID');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(bookingId: bookingId),
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 64,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back, size: 26),
            color: navy,
          ),
          const Expanded(
            child: Center(
              child: Image(
                image: AssetImage(logoPath),
                height: 46,
                fit: BoxFit.contain,
                errorBuilder: _logoFallback,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickDate,
            icon: const Icon(
              Icons.calendar_month_outlined,
              size: 27,
              color: navy,
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
        fontSize: 25,
        fontWeight: FontWeight.w900,
        color: navy,
      ),
    );
  }

  Widget _titleSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 5, 20, 15),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Bookings',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
              color: Color(0xFF17202D),
            ),
          ),
          SizedBox(height: 5),
          Text(
            'View and manage your ride bookings',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF68727D),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterTabs() {
    const icons = [
      Icons.calendar_month_outlined,
      Icons.event_available_outlined,
      Icons.directions_car_outlined,
      Icons.check_circle_outline,
    ];

    return Container(
      color: Colors.white,
      height: 68,
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 9),
      child: Row(
        children: List.generate(filters.length, (index) {
          final filter = filters[index];
          final selected = selectedFilter == filter;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => selectedFilter = filter);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected ? navy : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected ? navy : borderColor,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icons[index],
                      size: 21,
                      color: selected ? Colors.white : Colors.black87,
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        filter,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: selected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _dateFilter() {
    if (selectedDate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.event, color: navy, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
              style: const TextStyle(
                color: navy,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => selectedDate = null),
            child: const Text(
              'Clear',
              style: TextStyle(
                color: Colors.red,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bookingList() {
    final visibleBookings = filteredBookings;

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: navy),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 42,
                color: Colors.red,
              ),
              const SizedBox(height: 10),
              const Text(
                'Unable to load bookings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loadBookings,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (visibleBookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 75),
            Icon(
              Icons.receipt_long_outlined,
              size: 55,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Center(
              child: Text(
                'No bookings found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 6),
            Center(
              child: Text(
                'Your rides will appear here.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleBookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return _bookingCard(visibleBookings[index]);
        },
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final status = _status(booking);
    final statusColor = _statusColor(status);
    final statusBackground = _statusBackground(status);

    final bookingId = _value(booking['id'], fallback: '—');
    final pickup = _pickup(booking);
    final drop = _drop(booking);
    final vehicle = _vehicleName(booking);

    final fare = status == 'completed'
        ? booking['final_fare'] ?? booking['estimated_fare']
        : booking['estimated_fare'];

    final tripType = _prettyStatus(
      _value(booking['trip_type'], fallback: 'Trip'),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 9,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Booking ID: $bookingId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17202D),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'ongoing')
                        const Icon(
                          Icons.wifi_tethering,
                          size: 13,
                          color: Color(0xFF159B7C),
                        )
                      else if (status == 'completed')
                        const Icon(
                          Icons.check_circle,
                          size: 13,
                          color: Color(0xFF159B45),
                        )
                      else if (status == 'cancelled')
                        const Icon(
                          Icons.cancel,
                          size: 13,
                          color: Color(0xFFD84B4B),
                        )
                      else
                        const Icon(
                          Icons.calendar_month,
                          size: 13,
                          color: Color(0xFF2878C8),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _prettyStatus(status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(10, 1, 10, 10),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 82,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F5),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Image.asset(
                    _vehicleImage(booking),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) {
                      return Image.asset(
                        'assets/images/raahi_dzire_car.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const Icon(
                          Icons.directions_car,
                          color: navy,
                          size: 38,
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Color(0xFF159B45),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pickup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 3),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 15,
                              color: navy,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 17,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              drop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month_outlined,
                            size: 13,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              _formatDate(booking['scheduled_at']),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.directions_car_outlined,
                            size: 13,
                            color: AppColors.textGrey,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '$vehicle • ${_registration(booking)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 7),
                Container(
                  height: 65,
                  width: 1,
                  color: borderColor,
                ),
                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fare',
                      style: TextStyle(fontSize: 10),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _money(fare),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16833B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: status == 'ongoing'
                  ? const Color(0xFFF1FCF7)
                  : const Color(0xFFFAFBFC),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: _actionButtons(booking, status),
          ),
        ],
      ),
    );
  }

  Widget _actionButtons(
    Map<String, dynamic> booking,
    String status,
  ) {
    if (status == 'ongoing') {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              'Track Ride',
              Icons.location_on_outlined,
              () => _trackRide(booking),
              color: teal,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'Call Driver',
              Icons.call_outlined,
              () => _showMessage('Driver calling is not connected yet.'),
              color: teal,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'View Details',
              Icons.chevron_right,
              () => _openDetails(booking),
            ),
          ),
        ],
      );
    }

    if (_isUpcoming(status)) {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              'Modify',
              Icons.edit_outlined,
              () => _showMessage(
                'Booking modification is not connected yet.',
              ),
              color: teal,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'Cancel',
              Icons.cancel_outlined,
              () => _openDetails(booking),
              color: Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'View Details',
              Icons.chevron_right,
              () => _openDetails(booking),
            ),
          ),
        ],
      );
    }

    if (status == 'completed') {
      return Row(
        children: [
          Expanded(
            child: _actionButton(
              'Rate Driver',
              Icons.star_border,
              () => _openDetails(booking),
              color: teal,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'Invoice',
              Icons.receipt_long_outlined,
              () => _showMessage('Invoice download is not connected yet.'),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _actionButton(
              'View Details',
              Icons.chevron_right,
              () => _openDetails(booking),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Spacer(),
        _actionButton(
          'View Details',
          Icons.chevron_right,
          () => _openDetails(booking),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback onPressed, {
    Color color = navy,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.55)),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
        minimumSize: const Size(0, 35),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 3),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _templeFooter() {
    return SizedBox(
      height: 66,
      width: double.infinity,
      child: Image.asset(
        skylinePath,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _bottomNavigation() {
    return Container(
      height: 66,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: borderColor),
        ),
      ),
      child: Row(
        children: [
          _navItem(Icons.home_outlined, 'Home', false),
          _navItem(Icons.directions_car_outlined, 'Book Ride', false),
          _navItem(Icons.calendar_month_outlined, 'My Bookings', true),
          _navItem(Icons.account_balance_wallet_outlined, 'Wallet', false),
          _navItem(Icons.person_outline, 'Profile', false),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: selected
            ? null
            : () => _showMessage('$label navigation is not connected here yet.'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
          child: Container(
            decoration: BoxDecoration(
              color: selected ? navy : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 21,
                  color: selected ? Colors.white : const Color(0xFF17202D),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: selected
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: selected
                          ? Colors.white
                          : const Color(0xFF17202D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            _titleSection(),
            _dateFilter(),
            _filterTabs(),

            // Only this middle section scrolls.
            Expanded(
              child: _bookingList(),
            ),

            // Fixed temple artwork and bottom navigation.
            _templeFooter(),
            _bottomNavigation(),
          ],
        ),
      ),
    );
  }
}
