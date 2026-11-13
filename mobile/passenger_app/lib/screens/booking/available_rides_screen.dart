import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'fare_estimation_screen.dart';
class AvailableRidesScreen extends StatefulWidget {
    @override
    State<AvailableRidesScreen> createState() =>
        _AvailableRidesScreenState();
    final List<Map<String, dynamic>> drivers;

    final double distanceKm;
    final String tripType;
    final String vehicleModel;
    final String pickupAddress;
    final String dropAddress;
    final String pickupCity;
    final String dropCity;

    const AvailableRidesScreen({
        super.key,
        required this.drivers,
        required this.distanceKm,
        required this.tripType,
        required this.vehicleModel,
        required this.pickupAddress,
        required this.dropAddress,
        required this.pickupCity,
        required this.dropCity,
    });
}

class _AvailableRidesScreenState
    extends State<AvailableRidesScreen> {
  Map<String, dynamic>? selectedDriver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Available Rides',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.white,
        iconTheme: const IconThemeData(
          color: AppColors.primary,
        ),
      ),
      body: widget.drivers.isEmpty
          ? const Center(
              child: Text('No available drivers found'),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${widget.drivers.length} drivers found near your pickup',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ...widget.drivers.map(
                        (driver) => _driverCard(driver),
                      ),
                    ],
                  ),
                ),

                if (selectedDriver != null)
                  _continueButton(),
              ],
            ),
    );
  }

  Widget _driverCard(Map<String, dynamic> driver) {
    final rating = driver['rating'] ?? 0;
    final distance = driver['distance_km'] ?? 0;
   

    final isSelected =
        selectedDriver?['driver_id'] == driver['driver_id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor:
                    AppColors.primary.withValues(alpha: 0.1),
                child: const Icon(
                  Icons.person,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['driver_name']?.toString() ?? 'Driver',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text('$rating'),
                      ],
                    ),
                  ],
                ),
              ),

              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                )
              else
                const Icon(
                  Icons.verified,
                  color: Colors.green,
                ),
            ],
          ),

          const Divider(height: 24),

          Row(
            children: [
              const Icon(
                Icons.directions_car,
                color: AppColors.primary,
                size: 25,
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['vehicle_name']?.toString() ?? 'Vehicle',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      driver['vehicle_type']?.toString() ??
                          'Unknown type',
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              Text(
                '${driver['seating_capacity']} Seats',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: AppColors.textGrey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  driver['registration_number']?.toString() ??
                      'Registration unavailable',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Text(
                '${distance.toString()} km from pickup',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _viewDriver(driver),
              child: Text(
                isSelected ? 'View Selected Driver' : 'View Driver',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDriver(Map<String, dynamic> driver) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => DriverDetailsScreen(driver: driver),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      selectedDriver = result;
    });
  }

  Widget _continueButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.white,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => FareEstimationScreen(
                    distanceKm: widget.distanceKm,
                    tripType: widget.tripType,
                    vehicleModel: widget.vehicleModel,
                    driver: selectedDriver!,
                    pickupAddress: widget.pickupAddress,
                    dropAddress: widget.dropAddress,
                    pickupCity: widget.pickupCity,
                    dropCity: widget.dropCity,
                ),
                ),
            );
            },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Continue to Fare Estimation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}


// =======================================================
// DRIVER DETAILS SCREEN
// =======================================================

class DriverDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> driver;

  const DriverDetailsScreen({
    super.key,
    required this.driver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        title: const Text('Driver Details'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor:
                  AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                size: 55,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              driver['driver_name']?.toString() ?? 'Driver',
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Driver information',
              style: TextStyle(color: AppColors.textGrey),
            ),

            const SizedBox(height: 24),

            _detail(
              'Vehicle',
              driver['vehicle_name']?.toString() ?? 'N/A',
            ),

            _detail(
              'Vehicle Type',
              driver['vehicle_type']?.toString() ?? 'N/A',
            ),

            _detail(
              'Registration Number',
              driver['registration_number']?.toString() ?? 'N/A',
            ),

            _detail(
              'Rating',
              driver['rating']?.toString() ?? 'N/A',
            ),

            _detail(
              'Seating Capacity',
              '${driver['seating_capacity'] ?? 'N/A'} Seats',
            ),

            _detail(
              'Distance from Pickup',
              '${driver['distance_km'] ?? 'N/A'} km',
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, driver);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Select This Driver',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
