
import '../../auth/models/driver_profile.dart';
import '../../vehicles/models/vehicle_model.dart';

class DriverProfileModel {
  final Map<String, dynamic> user;
  final DriverProfile driver;
  final List<VehicleModel> vehicles;

  const DriverProfileModel({
    required this.user,
    required this.driver,
    required this.vehicles,
  });

  String get fullName => user['full_name']?.toString() ?? 'Driver';

  String get phone => user['phone']?.toString() ?? '';

  int get userId => user['id'] as int;
}
