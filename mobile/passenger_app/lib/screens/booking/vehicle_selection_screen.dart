
import 'package:flutter/material.dart';

class VehicleSelectionScreen extends StatefulWidget {
  final String pickupCity;
  final String dropCity;
  final String tripType;
  final double distanceKm;

  const VehicleSelectionScreen({
    super.key,
    required this.pickupCity,
    required this.dropCity,
    required this.tripType,
    required this.distanceKm,
  });

  @override
  State<VehicleSelectionScreen> createState() =>
      _VehicleSelectionScreenState();
}

class _VehicleSelectionScreenState
    extends State<VehicleSelectionScreen> {
  static const Color green = Color(0xFF079B80);
  static const Color navy = Color(0xFF06465D);
  static const Color dark = Color(0xFF17202D);

  String selectedVehicle = 'dzire';

  final List<Map<String, dynamic>> vehicles = [
    {
      'id': 'dzire',
      'name': 'Dzire',
      'image': 'assets/images/raahi_assets/vehicles/dzire.png',
      'description': 'Sedan • Comfortable & Economical',
      'seats': '4 + 1',
      'bags': '2 Bags',
      'price': '₹1,299',
    },
    {
      'id': 'eeco',
      'name': 'Eeco',
      'image': 'assets/images/raahi_assets/vehicles/eeco.png',
      'description': '7 Seater • Spacious & Budget Friendly',
      'seats': '7 + 1',
      'bags': '4 Bags',
      'price': '₹1,499',
    },
    {
      'id': 'ertiga',
      'name': 'Ertiga',
      'image': 'assets/images/raahi_assets/vehicles/ertiga.png',
      'description': '7 Seater • Family & Group Travel',
      'seats': '7 + 1',
      'bags': '4 Bags',
      'price': '₹1,799',
    },
    {
      'id': 'innova',
      'name': 'Innova',
      'image': 'assets/images/raahi_assets/vehicles/innova.png',
      'description': '7/8 Seater • Premium & Comfortable',
      'seats': '7 + 1',
      'bags': '5 Bags',
      'price': '₹2,499',
    },
    {
      'id': 'urbania',
      'name': 'Urbania',
      'image': 'assets/images/raahi_assets/vehicles/urbania.png',
      'description': '12–17 Seater • Groups & Tours',
      'seats': '12–17',
      'bags': '10 Bags',
      'price': '₹4,999',
    },
  ];

  String get tripTypeLabel {
    switch (widget.tripType) {
      case 'local':
        return 'Local Ride';
      case 'intercity':
        return 'Intercity Travel';
      case 'round_trip':
        return 'Round Trip';
      case 'religious_tour':
        return 'Religious Tour';
      default:
        return widget.tripType;
    }
  }

  void _continue() {
    Navigator.pop(context, {
      'vehicle_type': selectedVehicle,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // HEADER
            SizedBox(
              height: 133,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    SizedBox(
                      height: 54,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                size: 27,
                                color: dark,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/raahi_assets/brand/raahi_logo.png',
                            width: 190,
                            height: 48,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Select Vehicle',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: dark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Choose a vehicle that suits your group and travel plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ROUTE SUMMARY
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 5, 17, 12),
              child: _routeSummary(),
            ),

            // VEHICLE LIST
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(17, 3, 17, 8),
                itemCount: vehicles.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  return _vehicleCard(vehicles[index]);
                },
              ),
            ),

            // FARE NOTE
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 5, 17, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F7FA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: green,
                      size: 23,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Fare is an estimated price and may vary based on date, time and demand.',
                        style: TextStyle(
                          color: dark,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // CONTINUE BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 13),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: FilledButton(
                  onPressed: _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: navy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward, size: 25),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _routeSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F9FB),
        border: Border.all(color: const Color(0xFFDDE3E8)),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: green,
                size: 22,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.pickupCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward, size: 23),
              const SizedBox(width: 8),
              const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 22,
              ),
              Expanded(
                child: Text(
                  widget.dropCity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: dark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: green,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Icon(
                Icons.alt_route,
                color: green,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tripTypeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: dark,
                  ),
                ),
              ),
              Text(
                '~ ${widget.distanceKm.toStringAsFixed(0)} km',
                style: const TextStyle(
                  fontSize: 12,
                  color: dark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _vehicleCard(Map<String, dynamic> vehicle) {
    final bool isSelected = selectedVehicle == vehicle['id'];

    return InkWell(
      onTap: () {
        setState(() {
          selectedVehicle = vehicle['id'];
        });
      },
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 105,
        padding: const EdgeInsets.symmetric(
          horizontal: 7,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF0FCF8)
              : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isSelected
                ? green
                : const Color(0xFFDDE1E5),
            width: isSelected ? 2 : 1.2,
          ),
        ),
        child: Row(
          children: [
            // VEHICLE IMAGE
            SizedBox(
              width: 112,
              height: 85,
              child: Image.asset(
                vehicle['image'],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car,
                  size: 55,
                  color: Colors.blueGrey,
                ),
              ),
            ),

            const SizedBox(width: 5),

            // VEHICLE DETAILS
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle['name'],
                    style: const TextStyle(
                      color: dark,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    vehicle['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _detailTag(
                        Icons.person_outline,
                        vehicle['seats'],
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: _detailTag(
                          Icons.work_outline,
                          vehicle['bags'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // PRICE AND RADIO
            Container(
              width: 91,
              height: 78,
              padding: const EdgeInsets.only(left: 9),
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Color(0xFFDDE3E8),
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    vehicle['price'],
                    style: const TextStyle(
                      color: green,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: isSelected
                        ? green
                        : Colors.blueGrey,
                    size: 23,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE1E5E8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: dark),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: dark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
