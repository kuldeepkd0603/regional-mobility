
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'destination_location_screen.dart';

class PickupLocationScreen extends StatefulWidget {
  const PickupLocationScreen({super.key});

  @override
  State<PickupLocationScreen> createState() =>
      _PickupLocationScreenState();
}

class _PickupLocationScreenState extends State<PickupLocationScreen> {
  static const Color green = Color(0xFF079B80);
  static const Color navy = Color(0xFF06465D);
  static const Color dark = Color(0xFF17202D);

  GoogleMapController? _mapController;

  LatLng _pickup = const LatLng(23.1765, 75.7885);
  String _pickupAddress = 'My Current Location';
  String _pickupCity = 'Ujjain';
  bool _loadingLocation = false;

  final TextEditingController _searchController =
      TextEditingController();

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup,
          infoWindow: const InfoWindow(title: 'Pickup Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _loadingLocation = true);

    try {
      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      await _setPickup(location, moveCamera: true);
    } catch (e) {
      _showMessage('Unable to get current location.');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _setPickup(
    LatLng location, {
    bool moveCamera = false,
    String? knownAddress,
  }) async {
    setState(() {
      _pickup = location;
      if (knownAddress != null) {
        _pickupAddress = knownAddress;
      }
    });

    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    }

    if (knownAddress == null) {
      await _reverseGeocode(location);
    }
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      final places = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (places.isNotEmpty && mounted) {
        final place = places.first;

        final addressParts = [
          place.name,
          place.subLocality,
          place.locality,
        ].where((part) => part != null && part.isNotEmpty).toList();

        setState(() {
          _pickupAddress = addressParts.isEmpty
              ? 'Selected Location'
              : addressParts.join(', ');
          _pickupCity = place.locality ??
              place.subAdministrativeArea ??
              'Ujjain';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _pickupAddress = 'Selected Location');
      }
    }
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) return;

    try {
      final locations = await locationFromAddress(query);

      if (locations.isEmpty) {
        _showMessage('Location not found.');
        return;
      }

      final result = LatLng(
        locations.first.latitude,
        locations.first.longitude,
      );

      await _setPickup(
        result,
        moveCamera: true,
        knownAddress: query,
      );
    } catch (_) {
      _showMessage('Unable to search this location.');
    }
  }

  void _selectSuggestedPlace(String address) {
    _searchController.text = address;
    _searchLocation();
  }

  Future<void> _confirmPickup() async {
    final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
        builder: (_) => DestinationLocationScreen(
            pickupLatitude: _pickup.latitude,
            pickupLongitude: _pickup.longitude,
            pickupAddress: _pickupAddress,
            pickupCity: _pickupCity,
        ),
        ),
    );

    if (result != null && mounted) {
        Navigator.pop(context, {
        'pickup_latitude': _pickup.latitude,
        'pickup_longitude': _pickup.longitude,
        'pickup_address': _pickupAddress,
        'pickup_city': _pickupCity,
        ...result,
        });
    }
    }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // MAP
            Positioned(
              top: 205,
              left: 0,
              right: 0,
              bottom: screenHeight * 0.49,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _pickup,
                      zoom: 14,
                    ),
                    onMapCreated: (controller) {
                      _mapController = controller;
                    },
                    onTap: (position) {
                      _setPickup(position);
                    },
                    markers: _markers,
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    compassEnabled: false,
                    mapToolbarEnabled: false,
                  ),

                  Positioned(
                    top: 110,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: navy,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Text(
                          'Pickup Here',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 15,
                    bottom: 18,
                    child: FloatingActionButton(
                      heroTag: 'pickup_current_location',
                      mini: false,
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _getCurrentLocation,
                      child: _loadingLocation
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: green,
                              ),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: dark,
                              size: 25,
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // HEADER
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                child: Column(
                  children: [
                    SizedBox(
                      height: 65,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back,
                                size: 28,
                                color: dark,
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/raahi_assets/brand/raahi_logo.png',
                            height: 54,
                            width: 190,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Select Pickup Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: dark,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      'Choose your pickup point on the map or search below',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      height: 53,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFDDE1E6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            color: Color(0xFF555D66),
                            size: 27,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _searchLocation(),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText:
                                    'Search for area, landmark or address',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF858B92),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _searchLocation,
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM LOCATION PANEL
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: screenHeight * 0.50,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 15,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    Container(
                      height: 5,
                      width: 43,
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CURRENT LOCATION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: _getCurrentLocation,
                        borderRadius: BorderRadius.circular(15),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: green,
                                size: 30,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'My Current Location',
                                      style: TextStyle(
                                        color: dark,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$_pickupCity, Madhya Pradesh',
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.check_circle,
                                color: green,
                                size: 25,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // SAVED AND RECENT PLACES
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 15, 18, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionHeader('Saved Places', 'Manage'),

                            _placeRow(
                              Icons.home_rounded,
                              'Home',
                              'Nanakedha, Ujjain, MP',
                              const Color(0xFF079B80),
                              () => _selectSuggestedPlace(
                                'Nanakedha, Ujjain, Madhya Pradesh',
                              ),
                              showMenu: true,
                            ),

                            _placeRow(
                              Icons.work_outline_rounded,
                              'Work',
                              'Freeganj, Ujjain, MP',
                              const Color(0xFF079B80),
                              () => _selectSuggestedPlace(
                                'Freeganj, Ujjain, Madhya Pradesh',
                              ),
                              showMenu: true,
                            ),

                            const SizedBox(height: 8),

                            _sectionHeader('Recent Locations', null),

                            _placeRow(
                              Icons.access_time_rounded,
                              'Mahakaleshwar Temple',
                              'Jaisinghpura, Ujjain, MP',
                              dark,
                              () => _selectSuggestedPlace(
                                'Mahakaleshwar Temple, Ujjain',
                              ),
                            ),

                            _placeRow(
                              Icons.access_time_rounded,
                              'Ujjain Railway Station',
                              'Station Road, Ujjain, MP',
                              dark,
                              () => _selectSuggestedPlace(
                                'Ujjain Railway Station',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // CONFIRM BUTTON
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE9ECEF)),
                        ),
                      ),
                      child: SizedBox(
                        height: 60,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _confirmPickup,
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
                                'Confirm Pickup Location',
                                style: TextStyle(
                                  fontSize: 17,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String? action) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: dark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: () => _showMessage('Saved places management coming soon.'),
              child: const Text(
                'Manage',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeRow(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap, {
    bool showMenu = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8EBEF)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 25,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              showMenu
                  ? Icons.more_vert
                  : Icons.chevron_right_rounded,
              color: dark,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }
}
