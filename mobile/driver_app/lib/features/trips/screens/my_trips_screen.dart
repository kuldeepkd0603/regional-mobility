import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../models/driver_trip.dart';
import '../services/trip_service.dart';
import 'trip_details_screen.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({super.key});

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<DriverTrip> _trips = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTrips();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profile = await AuthService.getDriverProfile();
      final trips = await TripService.getDriverTrips(profile.id);

      if (!mounted) return;

      setState(() {
        _trips = trips;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<DriverTrip> _filteredTrips(int index) {
    switch (index) {
      case 1:
        return _trips.where((trip) => trip.isAssigned).toList();
      case 2:
        return _trips.where((trip) => trip.isOngoing).toList();
      case 3:
        return _trips.where((trip) => trip.isCompleted).toList();
      default:
        return _trips;
    }
  }

  Color _statusColor(DriverTrip trip) {
    if (trip.isCompleted) return AppColors.success;
    if (trip.isOngoing) return Colors.orange;
    return AppColors.primary;
  }

  String _date(DateTime? value) {
    if (value == null) return 'Date unavailable';

    final date = value.toLocal();

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  Widget _tripCard(DriverTrip trip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 13),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TripDetailsScreen(
                bookingId: trip.id,
              ),
            ),
          ).then((_) => _loadTrips());
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
                      'Booking #${trip.id}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      trip.bookingStatus.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(trip),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor:
                        _statusColor(trip).withValues(alpha: 0.10),
                    side: BorderSide.none,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const Divider(height: 22),
              _location(
                Icons.trip_origin,
                'Pickup',
                '${trip.pickupCity} - ${trip.pickupAddress}',
              ),
              const SizedBox(height: 13),
              _location(
                Icons.location_on_outlined,
                'Destination',
                '${trip.dropCity} - ${trip.dropAddress}',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 17,
                    color: AppColors.textGrey,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${trip.passengerCount} passengers',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '₹${(trip.finalFare ?? trip.estimatedFare).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _date(trip.scheduledAt ?? trip.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'View Details',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _location(IconData icon, String title, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: AppColors.secondary),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 45),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTrips,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final trips = _filteredTrips(_tabController.index);

    if (trips.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTrips,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Icon(
              Icons.route_outlined,
              size: 60,
              color: AppColors.textGrey,
            ),
            SizedBox(height: 15),
            Center(
              child: Text(
                'No trips found',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                'Your trips will appear here.',
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrips,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: trips.length,
        itemBuilder: (context, index) => _tripCard(trips[index]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadTrips,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Assigned'),
            Tab(text: 'Ongoing'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _buildContent(),
    );
  }
}