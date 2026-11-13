import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'live_tracking_screen.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool isLoading = true;
  String? errorMessage;
  List<Map<String, dynamic>> bookings = [];
  String selectedFilter = 'All';
  DateTime? selectedDate;

  static const List<String> filters = [
    'All',
    'Pending',
    'Active',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Select booking date',
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      selectedDate = null;
    });
  }

  String _status(Map<String, dynamic> booking) {
    return (booking['booking_status'] ?? '').toString().toLowerCase();
  }

  List<Map<String, dynamic>> get filteredBookings {
    List<Map<String, dynamic>> result;

    switch (selectedFilter) {
      case 'Pending':
        result = bookings.where((b) => _status(b) == 'pending').toList();
        break;

      case 'Active':
        result = bookings.where((b) {
          return [
            'accepted',
            'driver_assigned',
            'ongoing',
          ].contains(_status(b));
        }).toList();
        break;

      case 'Completed':
        result = bookings.where((b) => _status(b) == 'completed').toList();
        break;

      case 'Cancelled':
        result = bookings.where((b) => _status(b) == 'cancelled').toList();
        break;

      default:
        result = List<Map<String, dynamic>>.from(bookings);
    }

    // Apply selected date filter.
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;

      case 'accepted':
      case 'driver_assigned':
        return Colors.blue;

      case 'ongoing':
        return Colors.green;

      case 'completed':
        return Colors.teal;

      case 'cancelled':
        return Colors.red;

      default:
        return AppColors.textGrey;
    }
  }

  String _prettyStatus(String status) {
    if (status.isEmpty) return 'Unknown';

    return status
        .split('_')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not scheduled';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Not scheduled';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '$hour:$minute $period';
  }

  String _formatSelectedDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');

    if (amount == null) return '—';

    return '₹${amount.toStringAsFixed(0)}';
  }

  Map<String, dynamic> _route(Map<String, dynamic> booking) {
    final value = booking['route'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  @override
  Widget build(BuildContext context) {
    final visibleBookings = filteredBookings;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Filter by date',
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_month),
          ),
          if (selectedDate != null)
            IconButton(
              tooltip: 'Clear date filter',
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.filter_alt_off),
            ),
        ],
      ),
      body: Column(
        children: [
          if (selectedDate != null)
            Container(
              width: double.infinity,
              color: AppColors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                children: [
                  const Icon(Icons.event, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Date: ${_formatSelectedDate(selectedDate!)}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearDateFilter,
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),

          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = filters[index];
                final selected = selectedFilter == filter;

                return ChoiceChip(
                  label: Text(filter),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      selectedFilter = filter;
                    });
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.white,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),

          Expanded(child: _buildBody(visibleBookings)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> visibleBookings) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Unable to load bookings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
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
          children: [
            const SizedBox(height: 100),
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'No bookings found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                selectedDate != null
                    ? 'No bookings found for this date.'
                    : selectedFilter == 'All'
                    ? 'Your bookings will appear here.'
                    : 'No ${selectedFilter.toLowerCase()} bookings yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ),
            if (selectedDate != null) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: _clearDateFilter,
                  child: const Text('Clear date filter'),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: visibleBookings.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final booking = visibleBookings[index];

          return _bookingCard(booking);
        },
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking) {
    final route = _route(booking);
    final status = _status(booking);
    final statusColor = _statusColor(status);

    final bookingId = booking['id']?.toString() ?? '—';

    final pickup = route['pickup_city']?.toString() ?? 'Pickup unavailable';

    final drop = route['drop_city']?.toString() ?? 'Drop unavailable';

    final tripType = (booking['trip_type'] ?? 'Trip').toString().replaceAll(
      '_',
      ' ',
    );

    final vehicle = (booking['preferred_vehicle_type'] ?? 'Vehicle')
        .toString()
        .toUpperCase();

    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: booking),
            ),
          ).then((wasCancelled) {
            if (wasCancelled == true && mounted) {
              _loadBookings();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking #$bookingId',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _prettyStatus(status),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              _locationLine(Icons.trip_origin, pickup, Colors.green),

              Padding(
                padding: const EdgeInsets.only(left: 9),
                child: Container(
                  height: 17,
                  width: 1.5,
                  color: Colors.grey.shade300,
                ),
              ),

              _locationLine(Icons.location_on, drop, Colors.red),

              const Divider(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_prettyStatus(tripType)} • $vehicle',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _money(booking['estimated_fare']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _formatDate(booking['scheduled_at']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ),
                  const Text(
                    'View details  ›',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationLine(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({super.key, required this.booking});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  bool isCancelling = false;
  bool isLoadingReview = true;
  bool isSubmittingReview = false;

  Map<String, dynamic>? existingReview;
  String? reviewLoadError;

  int selectedRating = 0;

  final TextEditingController reviewController = TextEditingController();
  @override
  void initState() {
    super.initState();

    final status = (widget.booking['booking_status'] ?? '')
        .toString()
        .toLowerCase();

    debugPrint('⭐ Review initialization: $status');

    if (status == 'completed') {
      _loadExistingReview();
    } else {
      isLoadingReview = false;
    }
  }
  Map<String, dynamic> get route {
    final value = widget.booking['route'];

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }
  @override
  void dispose() {
    reviewController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Not scheduled';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return 'Not scheduled';

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} ${date.year}, '
        '$hour:$minute $period';
  }

  String _money(dynamic value) {
    final amount = double.tryParse(value?.toString() ?? '');

    return amount == null ? '—' : '₹${amount.toStringAsFixed(2)}';
  }

  Future<void> _cancelBooking() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel booking?'),
        content: const Text(
          'Are you sure you want to cancel this booking? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );

    if (shouldCancel != true || !mounted) return;

    final bookingId = int.tryParse(widget.booking['id'].toString());

    if (bookingId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid booking ID')));
      return;
    }

    setState(() {
      isCancelling = true;
    });

    try {
      await ApiService.cancelBooking(bookingId: bookingId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Future<void> _loadExistingReview() async {
    final bookingId = int.tryParse(widget.booking['id']?.toString() ?? '');

    if (bookingId == null) {
      setState(() {
        isLoadingReview = false;
        reviewLoadError = 'Invalid booking ID';
      });
      return;
    }

    try {
      final result = await ApiService.getBookingReview(bookingId: bookingId);

      if (!mounted) return;

      setState(() {
        existingReview = result;
        selectedRating = result == null
            ? 0
            : int.tryParse(result['rating'].toString()) ?? 0;
        reviewController.text = result?['review']?.toString() ?? '';
        isLoadingReview = false;
        reviewLoadError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingReview = false;
        reviewLoadError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _submitReview() async {
    if (selectedRating < 1 || selectedRating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating')),
      );
      return;
    }

    final bookingId = int.tryParse(widget.booking['id']?.toString() ?? '');

    if (bookingId == null) return;

    setState(() {
      isSubmittingReview = true;
    });

    try {
      final result = await ApiService.submitDriverReview(
        bookingId: bookingId,
        rating: selectedRating,
        review: reviewController.text.trim().isEmpty
            ? null
            : reviewController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        existingReview = result;
        isSubmittingReview = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you! Your review was submitted.')),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmittingReview = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  Widget _buildDriverReviewSection() {
    return _section('Rate Your Driver', [
      if (isLoadingReview)
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          ),
        )
      else if (reviewLoadError != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(reviewLoadError!, style: const TextStyle(color: Colors.red)),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  isLoadingReview = true;
                  reviewLoadError = null;
                });
                _loadExistingReview();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        )
      else if (existingReview != null)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have already rated this trip.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$selectedRating out of 5 stars',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (reviewController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                reviewController.text,
                style: const TextStyle(color: AppColors.textGrey),
              ),
            ],
          ],
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How was your ride?',
              style: TextStyle(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {
                    setState(() {
                      selectedRating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 36,
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                selectedRating == 0
                    ? 'Select your rating'
                    : '$selectedRating out of 5 stars',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reviewController,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Write your experience (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: selectedRating == 0 || isSubmittingReview
                    ? null
                    : _submitReview,
                icon: isSubmittingReview
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(
                  isSubmittingReview ? 'Submitting...' : 'Submit Review',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final status = (widget.booking['booking_status'] ?? '').toString();
    debugPrint('BOOKING STATUS: $status');
    final statusColor = status == 'pending'
        ? Colors.orange
        : status == 'cancelled'
        ? Colors.red
        : status == 'completed'
        ? Colors.teal
        : Colors.blue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking #${widget.booking['id'] ?? ''}'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Status',
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _section('Journey Details', [
              _detail('Pickup City', route['pickup_city']),
              _detail('Pickup Address', route['pickup_address']),
              _detail('Drop City', route['drop_city']),
              _detail('Drop Address', route['drop_address']),
              _detail(
                'Distance',
                route['distance_km'] == null
                    ? null
                    : '${route['distance_km']} km',
              ),
            ]),

            const SizedBox(height: 16),

            _section('Trip Information', [
              _detail(
                'Trip Type',
                widget.booking['trip_type']?.toString().replaceAll('_', ' '),
              ),
              _detail('Vehicle', widget.booking['preferred_vehicle_type']),
              _detail('Passengers', widget.booking['passenger_count']),
              _detail(
                'Pickup Date & Time',
                _formatDate(widget.booking['scheduled_at']),
              ),
              if (widget.booking['return_at'] != null)
                _detail(
                  'Return Date & Time',
                  _formatDate(widget.booking['return_at']),
                ),
              _detail(
                'Special Instructions',
                widget.booking['special_instructions'],
              ),
            ]),

            const SizedBox(height: 16),

            _section('Fare Details', [
              _detail(
                'Estimated Fare',
                _money(widget.booking['estimated_fare']),
              ),
              _detail('Final Fare', _money(widget.booking['final_fare'])),
            ]),
            if (status.toLowerCase() == 'completed') ...[
              const SizedBox(height: 16),
              _buildDriverReviewSection(),
            ],

            const SizedBox(height: 16),

            _section('Assignment Details', [
              _detail('Driver ID', widget.booking['driver_id']),
              _detail('Vehicle ID', widget.booking['vehicle_id']),
            ]),

            if (status == 'pending') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isCancelling ? null : _cancelBooking,
                  icon: isCancelling
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel_outlined),
                  label: Text(
                    isCancelling ? 'Cancelling...' : 'Cancel Booking',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            if (status == 'driver_assigned' || status == 'ongoing') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final bookingId = int.tryParse(
                      widget.booking['id'].toString(),
                    );

                    if (bookingId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid booking ID')),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LiveTrackingScreen(bookingId: bookingId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.location_searching),
                  label: const Text('Track Driver Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    final display = value == null || value.toString().trim().isEmpty
        ? '—'
        : value.toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            display,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
