import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/api_service.dart';
import 'booking_details_screen.dart';

class FareEstimationScreen extends StatefulWidget {
  final double distanceKm;
  final String tripType;
  final String vehicleModel;
  final Map<String, dynamic> driver;
  final String pickupAddress;
  final String dropAddress;
  final String pickupCity;
  final String dropCity;

  const FareEstimationScreen({
    super.key,
    required this.distanceKm,
    required this.tripType,
    required this.vehicleModel,
    required this.driver,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupCity,
    required this.dropCity,
  });

  @override
  State<FareEstimationScreen> createState() =>
      _FareEstimationScreenState();
}

class _FareEstimationScreenState
    extends State<FareEstimationScreen> {
  bool isLoading = true;
  String? errorMessage;
  Map<String, dynamic>? fareData;

  @override
  void initState() {
    super.initState();
    _loadFareEstimate();
  }

  Future<void> _loadFareEstimate() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.estimateFare(
        tripType: widget.tripType,
        vehicleType: widget.vehicleModel,
        distanceKm: widget.distanceKm,
        passengerCount: 1,
      );

      if (!mounted) return;

      setState(() {
        fareData = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  String _formatMoney(dynamic value) {
    final amount = double.tryParse(value.toString());

    if (amount == null) return 'N/A';

    return '₹${amount.toStringAsFixed(2)}';
  }

  String _formatDistance(dynamic value) {
    final distance = double.tryParse(value.toString());

    if (distance == null) return 'N/A';

    return '${distance.toStringAsFixed(2)} km';
  }

  Widget _fareRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationDetails() {
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.trip_origin, color: Colors.green, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PICKUP',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.pickupAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (widget.pickupCity.isNotEmpty)
                      Text(
                        widget.pickupCity,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 9, top: 8, bottom: 8),
            child: Container(
              height: 24,
              width: 1,
              color: Colors.grey.shade400,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DROP',
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.dropAddress,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (widget.dropCity.isNotEmpty)
                      Text(
                        widget.dropCity,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Fare Estimation'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : errorMessage != null
              ? _errorView()
              : _fareView(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 55,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to calculate fare',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadFareEstimate,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fareView() {
    final fare = fareData!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected driver
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  child: Icon(Icons.person),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.driver['driver_name']
                                ?.toString() ??
                            'Selected Driver',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.driver['vehicle_name']
                                ?.toString() ??
                            widget.vehicleModel,
                        style: const TextStyle(
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.verified,
                  color: Colors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Pickup & Drop Details',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          _locationDetails(),

          const SizedBox(height: 24),

          const Text(
            'Journey Details',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _fareRow(
                  'Trip Type',
                  widget.tripType.replaceAll('_', ' '),
                ),
                const Divider(),
                _fareRow(
                  'Vehicle',
                  widget.vehicleModel.toUpperCase(),
                ),
                const Divider(),
                _fareRow(
                  'Journey Distance',
                  _formatDistance(fare['distance_km']),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Fare Breakdown',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _fareRow(
                  'Base Fare',
                  _formatMoney(fare['base_fare']),
                ),
                const Divider(),
                _fareRow(
                  'Per KM Rate',
                  '${_formatMoney(fare['per_km_rate'])}/km',
                ),
                const Divider(),
                _fareRow(
                  'Chargeable Distance',
                  _formatDistance(
                    fare['chargeable_distance_km'],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Estimated total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                const Text(
                  'Estimated Total Fare',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatMoney(fare['estimated_fare']),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Final fare may vary according to applicable charges.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingDetailsScreen(
                      tripType: widget.tripType,
                      vehicleModel: widget.vehicleModel,
                      distanceKm: widget.distanceKm,
                      pickupAddress: widget.pickupAddress,
                      dropAddress: widget.dropAddress,
                      pickupCity: widget.pickupCity,
                      dropCity: widget.dropCity,
                      estimatedFare: fare['estimated_fare'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.event_available),
              label: const Text('Continue to Booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _loadFareEstimate,
              icon: const Icon(Icons.refresh),
              label: const Text('Recalculate Fare'),
            ),
          ),
        ],
      ),
    );
  }
}