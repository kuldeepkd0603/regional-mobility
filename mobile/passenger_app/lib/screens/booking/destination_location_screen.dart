
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'trip_type_screen.dart';
import '../../core/services/api_service.dart';
import 'vehicle_selection_screen.dart';
import 'fare_estimation_screen.dart';
class DestinationLocationScreen extends StatefulWidget {
  final double pickupLatitude;
  final double pickupLongitude;
  final String pickupAddress;
  final String pickupCity;

  const DestinationLocationScreen({
    super.key,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.pickupAddress,
    required this.pickupCity,
  });

  @override
  State<DestinationLocationScreen> createState() =>
      _DestinationLocationScreenState();
}

class _DestinationLocationScreenState
    extends State<DestinationLocationScreen> {
  static const Color green = Color(0xFF079B80);
  static const Color navy = Color(0xFF06465D);
  static const Color dark = Color(0xFF17202D);

  GoogleMapController? _mapController;

  final TextEditingController _searchController =
      TextEditingController();

  // Default destination: Mahakaleshwar Temple, Ujjain
  LatLng _destination = const LatLng(23.1828, 75.7682);

  String _destinationAddress = 'Mahakaleshwar Temple';
  String _destinationCity = 'Ujjain';
  bool _loadingLocation = false;

  LatLng get _pickup => LatLng(
        widget.pickupLatitude,
        widget.pickupLongitude,
      );

  Set<Marker> get _markers => {
        Marker(
          markerId: const MarkerId('pickup'),
          position: _pickup,
          infoWindow: InfoWindow(
            title: 'Pickup',
            snippet: widget.pickupAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: _destination,
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: _destinationAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _setDestination(
    LatLng location, {
    bool moveCamera = false,
    String? knownAddress,
  }) async {
    setState(() {
      _destination = location;
      if (knownAddress != null) {
        _destinationAddress = knownAddress;
      }
    });

    if (moveCamera) {
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 14),
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

      if (places.isEmpty || !mounted) return;

      final place = places.first;
      final parts = [
        place.name,
        place.subLocality,
        place.locality,
      ].where((value) => value != null && value.isNotEmpty).toList();

      setState(() {
        _destinationAddress = parts.isEmpty
            ? 'Selected Location'
            : parts.join(', ');
        _destinationCity = place.locality ??
            place.subAdministrativeArea ??
            'Ujjain';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _destinationAddress = 'Selected Location');
      }
    }
  }

  Future<void> _searchDestination() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    try {
      final results = await locationFromAddress(query);

      if (results.isEmpty) {
        _message('Destination not found.');
        return;
      }

      await _setDestination(
        LatLng(
          results.first.latitude,
          results.first.longitude,
        ),
        moveCamera: true,
        knownAddress: query,
      );
    } catch (_) {
      _message('Unable to search this destination.');
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingLocation = true);

    try {
      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message('Location permission is required.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      await _setDestination(
        LatLng(position.latitude, position.longitude),
        moveCamera: true,
      );
    } catch (_) {
      _message('Unable to get current location.');
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  void _selectPopular(
    String name,
    String city,
    double latitude,
    double longitude,
  ) {
    _searchController.text = name;
    setState(() {
      _destinationAddress = name;
      _destinationCity = city;
    });

    _setDestination(
      LatLng(latitude, longitude),
      moveCamera: true,
      knownAddress: name,
    );
  }

  
  
  Future<void> _confirmDestination() async {
    // STEP 1: Open Trip Type screen
    final tripResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => const TripTypeScreen(),
      ),
    );

    if (tripResult == null || !mounted) return;

    // STEP 2: Calculate actual route distance
    double distanceKm;
    bool usingFallbackDistance = false;

    try {
      distanceKm = await ApiService.getRouteDistanceKm(
        pickupLatitude: widget.pickupLatitude,
        pickupLongitude: widget.pickupLongitude,
        dropLatitude: _destination.latitude,
        dropLongitude: _destination.longitude,
      );

      if (!distanceKm.isFinite || distanceKm <= 0) {
        throw Exception('Invalid distance returned by API');
      }

      debugPrint('API route distance: $distanceKm km');
    } catch (e) {
      debugPrint('Route distance API failed: $e');

      distanceKm = 100.0;
      usingFallbackDistance = true;

      debugPrint('Using fallback distance: 100 km');
    }

    if (!mounted) return;

    if (usingFallbackDistance) {
      _message(
        'Route distance unavailable. Temporary estimate: 100 km.',
      );
    }

    // STEP 3: Open Vehicle Selection screen
    final vehicleResult = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => VehicleSelectionScreen(
          pickupCity: widget.pickupCity,
          dropCity: _destinationCity,
          tripType: tripResult['trip_type'],
          distanceKm: distanceKm,
        ),
      ),
    );

    if (vehicleResult == null || !mounted) return;

    final vehicleType =
        vehicleResult['vehicle_type']?.toString() ?? '';

    if (vehicleType.isEmpty) {
      _message('Please select a vehicle.');
      return;
    }

    // STEP 4: Open Fare Estimation screen
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FareEstimationScreen(
          distanceKm: distanceKm,
          tripType: tripResult['trip_type'].toString(),
          vehicleModel: vehicleType,
          pickupAddress: widget.pickupAddress,
          dropAddress: _destinationAddress,
          pickupCity: widget.pickupCity,
          dropCity: _destinationCity,
          pickupLatitude: widget.pickupLatitude,
          pickupLongitude: widget.pickupLongitude,
          dropLatitude: _destination.latitude,
          dropLongitude: _destination.longitude,
          usingFallbackDistance: usingFallbackDistance,
        ),
      ),
    );
  }

  void _message(String value) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(value),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;

            // Compact proportions for different phone sizes.
            final headerHeight = height * 0.245;
            final bottomHeight = height * 0.485;

            return Stack(
              children: [
                // MAP
                Positioned(
                  top: headerHeight,
                  left: 0,
                  right: 0,
                  bottom: bottomHeight,
                  child: Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _destination,
                          zoom: 14,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          controller.animateCamera(
                            CameraUpdate.newLatLngBounds(
                              LatLngBounds(
                                southwest: LatLng(
                                  _pickup.latitude - 0.012,
                                  _pickup.longitude - 0.012,
                                ),
                                northeast: LatLng(
                                  _destination.latitude + 0.012,
                                  _destination.longitude + 0.012,
                                ),
                              ),
                              55,
                            ),
                          );
                        },
                        onTap: (position) {
                          _setDestination(position);
                        },
                        markers: _markers,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        compassEnabled: false,
                        mapToolbarEnabled: false,
                      ),

                      Positioned(
                        right: 14,
                        bottom: 15,
                        child: FloatingActionButton(
                          heroTag: 'destination_current_location',
                          mini: false,
                          backgroundColor: Colors.white,
                          elevation: 3,
                          onPressed: _useCurrentLocation,
                          child: _loadingLocation
                              ? const SizedBox(
                                  height: 21,
                                  width: 21,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: green,
                                  ),
                                )
                              : const Icon(
                                  Icons.my_location,
                                  color: dark,
                                  size: 24,
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
                  height: headerHeight,
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(16, 3, 16, 8),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 57,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: dark,
                                    size: 27,
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/raahi_assets/brand/raahi_logo.png',
                                height: 48,
                                width: 180,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Select Destination',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Where would you like to go?',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _searchDestination(),
                            decoration: InputDecoration(
                              hintText:
                                  'Search for destination, city or place',
                              hintStyle: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF858B92),
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 25,
                                color: Color(0xFF555D66),
                              ),
                              suffixIcon: IconButton(
                                onPressed: _searchDestination,
                                icon: const Icon(
                                  Icons.arrow_forward,
                                  color: green,
                                ),
                              ),
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDDE1E6),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: const BorderSide(
                                  color: Color(0xFFDDE1E6),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: const BorderSide(
                                  color: green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM PANEL
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: bottomHeight,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 12,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          height: 5,
                          width: 42,
                          decoration: BoxDecoration(
                            color: Color(0xFFADB6C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // SELECTED DESTINATION
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Container(
                            height: 65,
                            padding: const EdgeInsets.symmetric(horizontal: 11),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F4F7),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: const Color(0xFFE0E6EA),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFE53950),
                                  size: 27,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Destination',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: dark,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$_destinationAddress, $_destinationCity, MP',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    _searchController.text =
                                        _destinationAddress;
                                    FocusScope.of(context).requestFocus(
                                      FocusNode(),
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                    color: green,
                                    size: 23,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // SCROLLABLE DESTINATION CONTENT
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(15, 11, 15, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionTitle('Popular Destinations', 'View All'),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _popularCard(
                                        'Mahakaleshwar\nTemple',
                                        'assets/images/raahi_assets/destinations/ujjain.png',
                                        Icons.temple_hindu,
                                        () => _selectPopular(
                                          'Mahakaleshwar Temple',
                                          'Ujjain',
                                          23.1828,
                                          75.7682,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: _popularCard(
                                        'Omkareshwar',
                                        'assets/images/raahi_assets/destinations/omkareshwar.png',
                                        Icons.temple_hindu,
                                        () => _selectPopular(
                                          'Omkareshwar',
                                          'Khandwa',
                                          22.2425,
                                          76.1511,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: _popularCard(
                                        'Khatu Shyam',
                                        null,
                                        Icons.temple_hindu,
                                        () => _selectPopular(
                                          'Khatu Shyam Temple',
                                          'Sikar',
                                          27.3645,
                                          75.4017,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: _popularCard(
                                        'Baglamukhi',
                                        null,
                                        Icons.temple_hindu,
                                        () => _selectPopular(
                                          'Baglamukhi Temple',
                                          'Nalkheda',
                                          23.9912,
                                          76.0561,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _sectionTitle('Recent Searches', null),
                                _recentRow(
                                  'Indore',
                                  'Indore, Madhya Pradesh',
                                  () => _selectPopular(
                                    'Indore',
                                    'Indore',
                                    22.7196,
                                    75.8577,
                                  ),
                                ),
                                _recentRow(
                                  'Dewas',
                                  'Dewas, Madhya Pradesh',
                                  () => _selectPopular(
                                    'Dewas',
                                    'Dewas',
                                    22.9676,
                                    76.0534,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // FIXED CONFIRM BUTTON
                        Container(
                          padding: const EdgeInsets.fromLTRB(17, 9, 17, 14),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: Color(0xFFE9ECEF),
                              ),
                            ),
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: FilledButton(
                              onPressed: _confirmDestination,
                              style: FilledButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm Destination',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(Icons.arrow_forward, size: 24),
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
            );
          },
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String? action) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: dark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: () => _message('More destinations coming soon.'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View All →',
              style: TextStyle(
                color: green,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _popularCard(
    String title,
    String? imagePath,
    IconData fallbackIcon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 112,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7EBEF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: imagePath == null
                  ? Container(
                      width: double.infinity,
                      color: const Color(0xFFE9F4F1),
                      child: Icon(
                        fallbackIcon,
                        color: green,
                        size: 34,
                      ),
                    )
                  : Image.asset(
                      imagePath,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFFE9F4F1),
                        child: Icon(
                          fallbackIcon,
                          color: green,
                          size: 32,
                        ),
                      ),
                    ),
            ),
            SizedBox(
              height: 36,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentRow(
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 53),
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE8EBEF)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF0F4F5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.access_time,
                color: dark,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: dark,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
