import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../theme/app_theme.dart';
import '../models/driver_trip.dart';
import '../services/trip_service.dart';

class TripDetailsScreen extends StatefulWidget {
  final int bookingId;

  const TripDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<TripDetailsScreen> createState() =>
      _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  DriverTrip? _trip;
  bool _loading = true;
  bool _processing = false;
  String? _error;

  final _distanceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _distanceController.dispose();
    super.dispose();
  }

  Future<void> _loadTrip() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final trip = await TripService.getTripDetails(widget.bookingId);

      if (!mounted) return;

      _trip = trip;
      _distanceController.text =
          trip.distanceKm?.toStringAsFixed(1) ?? '';

      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _navigateTo(String address) async {
    if (address.trim().isEmpty) {
      _showMessage('Location address is unavailable.');
      return;
    }

    final uri = Uri.https(
      'www.google.com',
      '/maps/dir/',
      {
        'api': '1',
        'destination': address,
        'travelmode': 'driving',
      },
    );

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage('Could not open Google Maps.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Could not open navigation.');
      }
    }
  }

  Future<void> _startTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start this trip?'),
        content: const Text(
          'Start the trip only after reaching pickup and boarding the passenger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start Trip'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      await TripService.startTrip(widget.bookingId);
      await _loadTrip();

      if (mounted) {
        _showMessage('Trip started successfully.');
      }
    } catch (e) {
      if (mounted) _showMessage('Unable to start trip: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _completeTrip() async {
    final distance = double.tryParse(_distanceController.text.trim());

    if (distance == null || distance <= 0) {
      _showMessage('Enter a valid actual distance in kilometres.');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete this trip?'),
        content: Text(
          'Actual distance: ${distance.toStringAsFixed(1)} km\n'
          'The backend will calculate the final fare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete Trip'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      final result = await TripService.completeTrip(
        bookingId: widget.bookingId,
        actualDistanceKm: distance,
      );

      await _loadTrip();

      if (!mounted) return;

      final fare = result['final_fare'];

      _showMessage(
        'Trip completed. Final fare: ₹${fare ?? 'calculated'}',
      );
    } catch (e) {
      if (mounted) _showMessage('Unable to complete trip: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _info(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Trip Details')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadTrip,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : trip == null
                  ? const Center(child: Text('Trip not found'))
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking #${trip.id}',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(
                                    trip.bookingStatus.replaceAll('_', ' ').toUpperCase(),
                                  ),
                                ),
                                const Divider(height: 25),
                                _info(
                                  'Pickup',
                                  '${trip.pickupCity}\n${trip.pickupAddress}',
                                  Icons.trip_origin,
                                ),
                                _info(
                                  'Destination',
                                  '${trip.dropCity}\n${trip.dropAddress}',
                                  Icons.location_on,
                                ),
                                _info(
                                  'Passengers',
                                  '${trip.passengerCount}',
                                  Icons.people_outline,
                                ),
                                _info(
                                  'Trip type',
                                  trip.tripType,
                                  Icons.route,
                                ),
                                _info(
                                  'Estimated fare',
                                  '₹${trip.estimatedFare.toStringAsFixed(2)}',
                                  Icons.currency_rupee,
                                ),
                                if (trip.finalFare != null)
                                  _info(
                                    'Final fare',
                                    '₹${trip.finalFare!.toStringAsFixed(2)}',
                                    Icons.payments_outlined,
                                  ),
                                _info(
                                  'Scheduled pickup',
                                  trip.scheduledAt?.toLocal().toString() ?? 'Not specified',
                                  Icons.schedule,
                                ),
                                if (trip.startedAt != null)
                                  _info(
                                    'Started',
                                    trip.startedAt!.toLocal().toString(),
                                    Icons.play_circle_outline,
                                  ),
                                if (trip.completedAt != null)
                                  _info(
                                    'Completed',
                                    trip.completedAt!.toLocal().toString(),
                                    Icons.check_circle_outline,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!trip.isCompleted) ...[
                          OutlinedButton.icon(
                            onPressed: () => _navigateTo(trip.isOngoing
                                ? trip.dropAddress
                                : trip.pickupAddress),
                            icon: const Icon(Icons.navigation),
                            label: Text(
                              trip.isOngoing
                                  ? 'Navigate to Destination'
                                  : 'Navigate to Pickup',
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        if (trip.isAssigned)
                          FilledButton.icon(
                            onPressed: _processing ? null : _startTrip,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Trip'),
                          ),

                        if (trip.isOngoing) ...[
                          TextField(
                            controller: _distanceController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              labelText: 'Actual distance (km)',
                              border: OutlineInputBorder(),
                              helperText:
                                  'Enter the actual distance travelled.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _processing ? null : _completeTrip,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Complete Trip'),
                          ),
                        ],

                        if (trip.isCompleted)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text(
                                'This trip is completed. Details are read-only.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),

                        if (_processing)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
    );
  }
}