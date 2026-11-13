import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../../vehicles/services/vehicle_service.dart';
import '../models/booking_request.dart';
import '../services/request_service.dart';

class AvailableRequestsScreen extends StatefulWidget {
  const AvailableRequestsScreen({super.key});

  @override
  State<AvailableRequestsScreen> createState() =>
      _AvailableRequestsScreenState();
}

class _AvailableRequestsScreenState extends State<AvailableRequestsScreen> {
  List<BookingRequest> _requests = [];
  List<VehicleModel> _vehicles = [];

  bool _isLoading = true;
  bool _isAccepting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        RequestService.getAvailableRequests(),
        VehicleService.getMyVehicles(),
      ]);

      if (!mounted) return;

      setState(() {
        _requests = results[0] as List<BookingRequest>;
        _vehicles = (results[1] as List<VehicleModel>)
            .where((vehicle) => vehicle.isActive)
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _acceptRequest(BookingRequest request) async {
    if (_vehicles.isEmpty) {
      _showMessage('Please add an active vehicle first.');
      return;
    }

    final suitableVehicles = _vehicles
        .where((vehicle) => vehicle.seatingCapacity >= request.passengerCount)
        .toList();

    if (suitableVehicles.isEmpty) {
      _showMessage('No vehicle has enough passenger capacity.');
      return;
    }

    int selectedVehicleId = suitableVehicles.first.id;

    final selectedId = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select your vehicle'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...suitableVehicles.map((vehicle) {
                    return ListTile(
                        leading: Radio<int>(
                        value: vehicle.id,
                        groupValue: selectedVehicleId,
                        onChanged: (value) {
                            if (value != null) {
                            setDialogState(() {
                                selectedVehicleId = value;
                            });
                            }
                        },
                        ),
                        title: Text(vehicle.vehicleName),
                        subtitle: Text(
                        '${vehicle.registrationNumber} • '
                        '${vehicle.seatingCapacity} seats',
                        ),
                        onTap: () {
                        setDialogState(() {
                            selectedVehicleId = vehicle.id;
                        });
                        },
                    );
                    }),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(dialogContext, selectedVehicleId);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (selectedId == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Accept this ride?'),
        content: Text(
          'Booking #${request.id}\n'
          '${request.pickupCity} → ${request.dropCity}\n'
          'Estimated fare: ₹${request.estimatedFare.toStringAsFixed(0)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Accept ride'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isAccepting = true);

    try {
      await RequestService.acceptRequest(
        bookingId: request.id,
        vehicleId: selectedId,
      );

      if (!mounted) return;

      _showMessage('Ride accepted successfully!');
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to accept ride: $e');
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.route,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Booking #${request.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '₹${request.estimatedFare.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _locationRow(
              Icons.trip_origin,
              request.pickupCity,
              request.pickupAddress,
            ),
            const SizedBox(height: 14),
            _locationRow(
              Icons.location_on,
              request.dropCity,
              request.dropAddress,
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _info(Icons.people, '${request.passengerCount} passengers'),
                _info(
                  Icons.directions_car,
                  request.preferredVehicleType ?? 'Any vehicle',
                ),
                _info(Icons.category, request.tripType),
                if (request.distanceKm != null)
                  _info(
                    Icons.straighten,
                    '${request.distanceKm!.toStringAsFixed(1)} km',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (request.scheduledAt != null)
              Text(
                'Pickup: ${request.scheduledAt!.toLocal()}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
            if (request.specialInstructions?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${request.specialInstructions}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isAccepting
                    ? null
                    : () => _acceptRequest(request),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Accept Ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationRow(
    IconData icon,
    String title,
    String address,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondary, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textGrey),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Requests'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _requests.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 140),
                          Icon(
                            Icons.inbox_outlined,
                            size: 65,
                            color: AppColors.textGrey,
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'No ride requests available',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Pull down to refresh',
                              style: TextStyle(
                                color: AppColors.textGrey,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _requests.length,
                        itemBuilder: (context, index) =>
                            _buildRequestCard(_requests[index]),
                      ),
                    ),
    );
  }
}