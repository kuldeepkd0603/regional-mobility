
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/driver_profile.dart';
import '../../vehicles/models/vehicle_model.dart';
import '../models/driver_profile_model.dart';

class ProfileService {
  /// Fetch personal details, driver details and registered vehicles.
  static Future<DriverProfileModel> getProfile() async {
    final results = await Future.wait([
      ApiService.get(ApiConstants.authMe),
      ApiService.get(ApiConstants.driverMe),
      ApiService.getList('/vehicles/'),
    ]);

    final user = results[0] as Map<String, dynamic>;
    final driver = DriverProfile.fromJson(
      results[1] as Map<String, dynamic>,
    );

    final vehicles = (results[2] as List)
        .map(
          (json) => VehicleModel.fromJson(
            json as Map<String, dynamic>,
          ),
        )
        .toList();

    return DriverProfileModel(
      user: user,
      driver: driver,
      vehicles: vehicles,
    );
  }

  /// Update the driver's full name.
  static Future<Map<String, dynamic>> updateName(
    String fullName,
  ) async {
    final response = await ApiService.patch(
      ApiConstants.authMe,
      body: {'full_name': fullName.trim()},
    );

    return response;
  }
}
