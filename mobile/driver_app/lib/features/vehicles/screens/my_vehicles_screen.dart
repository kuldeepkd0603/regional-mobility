
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../models/vehicle_model.dart';
import '../services/vehicle_service.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<VehicleModel> _vehicles = [];
  int? _driverId;
  bool _isLoading = true;
  bool _isAdding = false;
  bool _isVerified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await AuthService.getDriverProfile();
      final vehicles = await VehicleService.getMyVehicles();

      if (!mounted) return;

      setState(() {
        _driverId = profile.id;
        _isVerified = profile.isVerified;
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load vehicles. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddVehicleDialog() async {
    if (_driverId == null || !_isVerified) {
      _showMessage('Only verified drivers can register vehicles.');
      return;
    }

    final nameController = TextEditingController();
    final numberController = TextEditingController();
    final capacityController = TextEditingController();

    String vehicleType = 'dzire';
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Register Vehicle'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Name',
                          hintText: 'Example: Maruti Dzire',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 2) {
                            return 'Enter a valid vehicle name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: vehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'dzire',
                            child: Text('Dzire'),
                          ),
                          DropdownMenuItem(
                            value: 'eeco',
                            child: Text('Eeco'),
                          ),
                          DropdownMenuItem(
                            value: 'ertiga',
                            child: Text('Ertiga'),
                          ),
                          DropdownMenuItem(
                            value: 'innova',
                            child: Text('Innova'),
                          ),
                          DropdownMenuItem(
                            value: 'urbania',
                            child: Text('Urbania'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              vehicleType = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: numberController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Registration Number',
                          hintText: 'MP09AB1234',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 5) {
                            return 'Enter a valid registration number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: capacityController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Seating Capacity',
                          hintText: '4',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final capacity = int.tryParse(value ?? '');
                          if (capacity == null ||
                              capacity < 1 ||
                              capacity > 50) {
                            return 'Enter capacity between 1 and 50';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      await _registerVehicle(
        name: nameController.text.trim(),
        type: vehicleType,
        number: numberController.text.trim().toUpperCase(),
        capacity: int.parse(capacityController.text.trim()),
      );
    }

    nameController.dispose();
    numberController.dispose();
    capacityController.dispose();
  }

  Future<void> _registerVehicle({
    required String name,
    required String type,
    required String number,
    required int capacity,
  }) async {
    setState(() => _isAdding = true);

    try {
      await VehicleService.registerVehicle(
        driverId: _driverId!,
        vehicleName: name,
        vehicleType: type,
        registrationNumber: number,
        seatingCapacity: capacity,
      );

      if (!mounted) return;

      _showMessage('Vehicle registered successfully.');
      await _loadVehicles();
    } catch (e) {
      if (!mounted) return;
      _showMessage('Vehicle registration failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildVehicleCard(VehicleModel vehicle) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: AppColors.primary,
                    size: 29,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.vehicleName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.vehicleType.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  vehicle.isActive ? Icons.check_circle : Icons.cancel,
                  color: vehicle.isActive
                      ? AppColors.success
                      : AppColors.error,
                ),
              ],
            ),
            const Divider(height: 25),
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
                    vehicle.registrationNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.people_outline,
                  size: 18,
                  color: AppColors.textGrey,
                ),
                const SizedBox(width: 5),
                Text('${vehicle.seatingCapacity} seats'),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: vehicle.isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  vehicle.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: vehicle.isActive
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Vehicles',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _loadVehicles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: !_isLoading &&
              _error == null &&
              _isVerified
          ? FloatingActionButton.extended(
              onPressed: _isAdding ? null : _showAddVehicleDialog,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Vehicle'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadVehicles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadVehicles,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text(
                        '${_vehicles.length} Registered Vehicles',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (!_isVerified)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'Your driver account must be verified before '
                              'you can register vehicles.',
                            ),
                          ),
                        ),
                      if (_vehicles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 55),
                          child: Column(
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 65,
                                color: AppColors.textGrey,
                              ),
                              SizedBox(height: 15),
                              Text(
                                'No vehicles registered yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Your registered vehicles will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ..._vehicles.map(_buildVehicleCard),
                      const SizedBox(height: 85),
                    ],
                  ),
                ),
    );
  }
}
