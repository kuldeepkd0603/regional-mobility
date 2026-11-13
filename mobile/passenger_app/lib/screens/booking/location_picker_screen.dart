
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState
    extends State<LocationPickerScreen> {
  GoogleMapController? mapController;

  LatLng? pickupLocation;
  LatLng? dropLocation;

  bool selectingPickup = true;
  bool isLoadingLocation = false;

  static const LatLng defaultLocation =
      LatLng(23.1765, 75.7885); // Ujjain

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage('Please enable location services.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required to find you.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      await mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    } catch (e) {
      _showMessage('Unable to get current location.');
    } finally {
      if (mounted) {
        setState(() => isLoadingLocation = false);
      }
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      if (selectingPickup) {
        pickupLocation = position;
        selectingPickup = false;
      } else {
        dropLocation = position;
      }
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Set<Marker> get markers {
    final result = <Marker>{};

    if (pickupLocation != null) {
      result.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickupLocation!,
          infoWindow: const InfoWindow(title: 'Pickup'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (dropLocation != null) {
      result.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: dropLocation!,
          infoWindow: const InfoWindow(title: 'Destination'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
        ),
      );
    }

    return result;
  }

  Future<void> _confirmLocations() async {
    if (pickupLocation == null || dropLocation == null) {
        _showMessage('Please select both locations.');
        return;
    }

    if (pickupLocation == dropLocation) {
        _showMessage('Pickup and destination must be different.');
        return;
    }

    try {
        setState(() => isLoadingLocation = true);

        final pickupPlaces = await placemarkFromCoordinates(
        pickupLocation!.latitude,
        pickupLocation!.longitude,
        );

        final dropPlaces = await placemarkFromCoordinates(
        dropLocation!.latitude,
        dropLocation!.longitude,
        );

        if (pickupPlaces.isEmpty || dropPlaces.isEmpty) {
        throw Exception('Unable to identify selected addresses.');
        }

        final pickup = pickupPlaces.first;
        final drop = dropPlaces.first;

        String formatAddress(Placemark place) {
        return [
            place.name,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
            place.administrativeArea,
            place.postalCode,
        ].where((item) => item != null && item.trim().isNotEmpty)
        .toSet()
        .join(', ');
        }

        if (!mounted) return;

        Navigator.pop(context, {
        'pickup_latitude': pickupLocation!.latitude,
        'pickup_longitude': pickupLocation!.longitude,
        'drop_latitude': dropLocation!.latitude,
        'drop_longitude': dropLocation!.longitude,

        'pickup_address': formatAddress(pickup),
        'drop_address': formatAddress(drop),

        'pickup_city': pickup.locality ??
            pickup.subAdministrativeArea ??
            pickup.administrativeArea ??
            '',

        'drop_city': drop.locality ??
            drop.subAdministrativeArea ??
            drop.administrativeArea ??
            '',
        });
    } catch (e) {
        if (mounted) {
        _showMessage('Could not get addresses. Please try again.');
        }
    } finally {
        if (mounted) {
        setState(() => isLoadingLocation = false);
        }
    }
    }

  @override
  void dispose() {
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Locations'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.white,
            child: Column(
              children: [
                _locationOption(
                  title: 'Pickup Location',
                  subtitle: pickupLocation == null
                      ? 'Tap the map to select pickup'
                      : 'Location selected',
                  icon: Icons.my_location,
                  color: Colors.green,
                  selected: selectingPickup,
                  onTap: () {
                    setState(() => selectingPickup = true);
                  },
                ),
                const Divider(),
                _locationOption(
                  title: 'Destination',
                  subtitle: dropLocation == null
                      ? 'Tap the map to select destination'
                      : 'Location selected',
                  icon: Icons.location_on,
                  color: Colors.red,
                  selected: !selectingPickup,
                  onTap: () {
                    setState(() => selectingPickup = false);
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: defaultLocation,
                zoom: 12,
              ),
              onMapCreated: (controller) {
                mapController = controller;
              },
              onTap: _onMapTap,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),

          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                onPressed: isLoadingLocation ? null : _confirmLocations,
                child: isLoadingLocation
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Locations',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                        ),
                        ),
                )
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locationOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 28),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Colors.blue)
          : const Icon(Icons.circle_outlined),
    );
  }
}
