
import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../booking/location_picker_screen.dart';
import '../../core/services/api_service.dart';
import '../booking/available_rides_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Temporary frontend-only distance used only when Google Routes fails.
  static const double _fallbackDistanceKm = 100.0;

  String selectedRide = 'Local';
  String selectedVehicle = 'dzire';
  bool isSearching = false;

  final TextEditingController pickupController =
      TextEditingController();

  final TextEditingController destinationController =
      TextEditingController();

  Map<String, double>? selectedCoordinates;
  String? distanceSource;

  // Readable route details returned by LocationPickerScreen.
  String pickupAddress = '';
  String dropAddress = '';
  String pickupCity = '';
  String dropCity = '';

  final List<Map<String, dynamic>> vehicles = [
    {
      'id': 'dzire',
      'name': 'Dzire',
      'seats': '4 Seater',
      'icon': Icons.directions_car,
      'asset': 'assets/images/raahi_assets/vehicles/dzire.png',
    },
    {
      'id': 'eeco',
      'name': 'Eeco',
      'seats': '7 Seater',
      'icon': Icons.airport_shuttle,
      'asset': 'assets/images/raahi_assets/vehicles/eeco.png',
    },
    {
      'id': 'ertiga',
      'name': 'Ertiga',
      'seats': '6 Seater',
      'icon': Icons.directions_car_filled,
      'asset': 'assets/images/raahi_assets/vehicles/ertiga.png',
    },
    {
      'id': 'innova',
      'name': 'Innova',
      'seats': '7 Seater',
      'icon': Icons.airport_shuttle,
      'asset': 'assets/images/raahi_assets/vehicles/innova.png',
    },
    {
      'id': 'urbania',
      'name': 'Urbania',
      'seats': '17 Seater',
      'icon': Icons.directions_bus,
      'asset': 'assets/images/raahi_assets/vehicles/urbania.png',
    },
  ];

  @override
  void dispose() {
    pickupController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const LocationPickerScreen(),
      ),
    );

    if (!mounted || result == null) return;

    final pickupLat =
        (result['pickup_latitude'] as num?)?.toDouble();
    final pickupLng =
        (result['pickup_longitude'] as num?)?.toDouble();
    final dropLat =
        (result['drop_latitude'] as num?)?.toDouble();
    final dropLng =
        (result['drop_longitude'] as num?)?.toDouble();

    final newPickupAddress =
        result['pickup_address']?.toString().trim() ?? '';
    final newDropAddress =
        result['drop_address']?.toString().trim() ?? '';
    final newPickupCity =
        result['pickup_city']?.toString().trim() ?? '';
    final newDropCity =
        result['drop_city']?.toString().trim() ?? '';

    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      return;
    }

    setState(() {
      selectedCoordinates = {
        'pickup_latitude': pickupLat,
        'pickup_longitude': pickupLng,
        'drop_latitude': dropLat,
        'drop_longitude': dropLng,
      };

      pickupAddress = newPickupAddress;
      dropAddress = newDropAddress;
      pickupCity = newPickupCity;
      dropCity = newDropCity;

      pickupController.text = pickupAddress.isNotEmpty
          ? pickupAddress
          : '${pickupLat.toStringAsFixed(5)}, ${pickupLng.toStringAsFixed(5)}';

      destinationController.text = dropAddress.isNotEmpty
          ? dropAddress
          : '${dropLat.toStringAsFixed(5)}, ${dropLng.toStringAsFixed(5)}';

      distanceSource = null;
    });
  }

  
String get _tripTypeValue =>
      selectedRide.toLowerCase().replaceAll(' ', '_');

  Future<double> _getDistanceForSelectedRoute() async {
    // Always try the actual road distance first.
    try {
      final distanceKm = await ApiService.getRouteDistanceKm(
        pickupLatitude: selectedCoordinates!['pickup_latitude']!,
        pickupLongitude: selectedCoordinates!['pickup_longitude']!,
        dropLatitude: selectedCoordinates!['drop_latitude']!,
        dropLongitude: selectedCoordinates!['drop_longitude']!,
      );

      if (distanceKm <= 0 || distanceKm > 2000) {
        throw Exception('Google returned an invalid distance.');
      }

      if (!mounted) throw Exception('Screen is no longer active.');

      setState(() {
        distanceSource = 'Google Routes';
      });
      return distanceKm;
    } catch (_) {
      // This is a temporary estimate, not the route's actual road distance.
      if (!mounted) throw Exception('Screen is no longer active.');

      setState(() {
        distanceSource = 'Temporary default';
      });
      return _fallbackDistanceKm;
    }
  }

  Future<void> _searchRides() async {
    if (selectedCoordinates == null) {
      _showMessage('Please select pickup and destination on Google Maps');
      return;
    }

    if (pickupAddress.isEmpty ||
        dropAddress.isEmpty ||
        pickupCity.isEmpty ||
        dropCity.isEmpty) {
      _showMessage(
        'Please reselect both locations so their addresses can be identified.',
      );
      return;
    }

    setState(() {
      isSearching = true;
    });

    try {
      // Calculate distance before searching for drivers.
      final distanceKm = await _getDistanceForSelectedRoute();

      if (!mounted) return;

      final drivers = await ApiService.findNearbyDrivers(
        latitude: selectedCoordinates!['pickup_latitude']!,
        longitude: selectedCoordinates!['pickup_longitude']!,
        vehicleType: selectedVehicle,
        passengerCount: 1,
        radiusKm: 10,
      );

      if (!mounted) return;

      if (drivers.isEmpty) {
        _showMessage('No available drivers found within 10 km');
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AvailableRidesScreen(
            drivers: drivers,
            distanceKm: distanceKm,
            tripType: _tripTypeValue,
            vehicleModel: selectedVehicle,
            pickupAddress: pickupAddress,
            dropAddress: dropAddress,
            pickupCity: pickupCity,
            dropCity: dropCity,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() {
          isSearching = false;
        });
      }
    }
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static const Color _green = Color(0xFF078B4B);
  static const Color _deepGreen = Color(0xFF006B4A);
  static const Color _ink = Color(0xFF111827);
  static const Color _line = Color(0xFFE1E7EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: _buildBookingPanel(),
                    ),
                    _buildVehicleSection(),
                    _buildDestinationSection(),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: _buildBottomNavigation(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBDEFFF), Color(0xFFEAF9FF), Color(0xFFF7F9FA)],
          stops: [0, 0.62, 1],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_rounded, color: _ink, size: 27),
              const SizedBox(width: 13),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Image.asset(
                    'assets/images/raahi_assets/brand/raahi_logo.png',
                    width: 140,
                    height: 48,
                    fit: BoxFit.contain,
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              _roundHeaderAction(
                Icons.notifications_none_rounded,
                () => _openNotifications(),
              ),
              const SizedBox(width: 9),
              _roundHeaderAction(
                Icons.person_rounded,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                filled: true,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Hi, Kuldeep 👋',
            style: TextStyle(
              color: _ink,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Where would you like to go today?',
            style: TextStyle(
              color: Color(0xFF17212B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 58,
              width: double.infinity,
              child: Image.asset(
                'assets/images/raahi_assets/header/temple_header.png',
                fit: BoxFit.contain,
                alignment: Alignment.centerRight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundHeaderAction(IconData icon, VoidCallback onTap, {bool filled = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: filled ? _green : Colors.white.withValues(alpha: 0.65),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: filled ? Colors.white : _ink, size: 23),
      ),
    );
  }

  Widget _buildBookingPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF182B36).withValues(alpha: 0.13),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 49,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F4),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _bookingTab(
                    icon: Icons.directions_car_filled_rounded,
                    label: 'Book a Ride',
                    selected: true,
                    onTap: () {},
                  ),
                ),
                Expanded(
                  child: _bookingTab(
                    icon: Icons.directions_bus_rounded,
                    label: 'Tour & Travels',
                    selected: false,
                    onTap: () => _showMessage('Tour & Travels coming soon'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _referenceLocationField(
            controller: pickupController,
            hint: 'Pickup Location',
            leading: const Icon(Icons.circle, color: Color(0xFF23B34B), size: 19),
            trailing: IconButton(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.my_location_rounded, color: _deepGreen),
              tooltip: 'Choose pickup and destination on map',
            ),
          ),
          const SizedBox(height: 9),
          _referenceLocationField(
            controller: destinationController,
            hint: 'Destination',
            leading: const Icon(Icons.location_on, color: Colors.red, size: 22),
            trailing: IconButton(
              onPressed: _openMapPicker,
              icon: const Icon(Icons.swap_vert_rounded, color: _deepGreen),
              tooltip: 'Choose destination on map',
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _referenceTripCard('Local', Icons.directions_car_filled_rounded),
                const SizedBox(width: 8),
                _referenceTripCard('Intercity', Icons.alt_route_rounded),
                const SizedBox(width: 8),
                _referenceTripCard('Round Trip', Icons.sync_rounded),
                const SizedBox(width: 8),
                _referenceTripCard('Religious Tour', Icons.temple_hindu_rounded),
              ],
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF49D20A), Color(0xFF00865B), Color(0xFF006B51)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isSearching ? null : _searchRides,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: isSearching
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Find Available Rides',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward_rounded, size: 24),
                        ],
                      ),
              ),
            ),
          ),
          if (distanceSource != null) ...[
            const SizedBox(height: 9),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                distanceSource == 'Google Routes'
                    ? 'Road distance calculated by Google Routes'
                    : 'Temporary estimate: 100 km (Google Routes unavailable)',
                style: TextStyle(
                  color: distanceSource == 'Temporary default'
                      ? const Color(0xFF9A6A21)
                      : Colors.blueGrey,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bookingTab({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF48D20A), Color(0xFF007D59)])
              : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: selected
              ? [BoxShadow(color: _green.withValues(alpha: 0.25), blurRadius: 5, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : _deepGreen, size: 23),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : _ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _referenceLocationField({
    required TextEditingController controller,
    required String hint,
    required Widget leading,
    required Widget trailing,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _line, width: 1.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          leading,
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (_) {
                setState(() {
                  selectedCoordinates = null;
                  distanceSource = null;
                  if (controller == pickupController) {
                    pickupAddress = '';
                    pickupCity = '';
                  } else {
                    dropAddress = '';
                    dropCity = '';
                  }
                });
              },
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF4B5563), fontSize: 15),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15, color: _ink),
            ),
          ),
          trailing,
          const SizedBox(width: 5),
        ],
      ),
    );
  }

  Widget _referenceTripCard(String label, IconData icon) {
    final selected = selectedRide == label;
    return InkWell(
      onTap: () => setState(() => selectedRide = label),
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: label == 'Religious Tour' ? 132 : 105,
        height: 83,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE4F9E9) : const Color(0xFFFCFDFE),
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? const Color(0xFF20B943) : const Color(0xFFE5E9ED),
            width: selected ? 1.7 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF087D37), size: 27),
            const SizedBox(height: 5),
            FittedBox(
              child: Text(
                label,
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Choose Your Vehicle',
                    style: TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                const Text('View All  ›', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 2),
              scrollDirection: Axis.horizontal,
              itemCount: vehicles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _referenceVehicleCard(
                  id: vehicle['id'],
                  name: vehicle['name'],
                  seats: vehicle['seats'],
                  icon: vehicle['icon'],
                  asset: vehicle['asset'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _referenceVehicleCard({
    required String id,
    required String name,
    required String seats,
    required IconData icon,
    required String asset,
  }) {
    final selected = selectedVehicle == id;
    return GestureDetector(
      onTap: () => setState(() => selectedVehicle = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 112,
        padding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE9F9EF) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: selected ? const Color(0xFF20B943) : _line, width: selected ? 1.6 : 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 7, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 59,
              width: double.infinity,
              child: Image.asset(
                asset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(icon, size: 48, color: _deepGreen),
              ),
            ),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: _ink)),
            const SizedBox(height: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline_rounded, size: 15),
                const SizedBox(width: 3),
                Flexible(child: Text(seats, maxLines: 1, style: const TextStyle(fontSize: 10, color: _ink))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDestinationSection() {
    final destinations = [
      {'name': 'Ujjain', 'sub': '(Mahakal)', 'asset': 'assets/images/raahi_assets/destinations/ujjain.png'},
      {'name': 'Indore', 'sub': '', 'asset': 'assets/images/raahi_assets/destinations/indore.png'},
      {'name': 'Dewas', 'sub': '', 'asset': 'assets/images/raahi_assets/destinations/dewas.png'},
      {'name': 'Omkareshwar', 'sub': '', 'asset': 'assets/images/raahi_assets/destinations/omkareshwar.png'},
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: const [
                Icon(Icons.location_on_rounded, color: Color(0xFF20B943), size: 25),
                SizedBox(width: 5),
                Expanded(
                  child: Text('Popular Destinations', style: TextStyle(color: _ink, fontSize: 19, fontWeight: FontWeight.w900)),
                ),
                Text('View All  ›', style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            height: 128,
            child: ListView.separated(
              padding: const EdgeInsets.only(right: 2),
              scrollDirection: Axis.horizontal,
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final city = destination['name'] as String;
                return InkWell(
                  onTap: () {
                    setState(() {
                      destinationController.text = city;
                      dropAddress = city;
                      dropCity = city;
                      selectedCoordinates = null;
                      distanceSource = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    width: 124,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(color: _line),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            child: Image.asset(
                              destination['asset'] as String,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.place_rounded, color: _green, size: 48),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(3, 5, 3, 6),
                          child: Column(
                            children: [
                              Text(city, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: _ink)),
                              if ((destination['sub'] as String).isNotEmpty)
                                Text(destination['sub'] as String, style: const TextStyle(fontSize: 10, color: _ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.09), blurRadius: 15, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _bottomNavItem(Icons.home_filled, 'Home', true, () {}),
          _bottomNavItem(Icons.calendar_month_rounded, 'My Bookings', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen()));
          }),
          _bottomNavItem(Icons.notifications_none_rounded, 'Notifications', false, () {
            _openNotifications();
          }),
          _bottomNavItem(Icons.person_outline_rounded, 'Profile', false, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }),
        ],
      ),
    );
  }

  Widget _bottomNavItem(IconData icon, String label, bool selected, VoidCallback onTap) {
    final color = selected ? _green : const Color(0xFF111827);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 36,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFD5F7E3) : Colors.transparent,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 25),
            ),
            const SizedBox(height: 3),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 10, fontWeight: selected ? FontWeight.w800 : FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
