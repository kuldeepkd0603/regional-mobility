
import '../../../core/services/api_service.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  // Fetch vehicles belonging to the logged-in driver.
  static Future<List<VehicleModel>> getMyVehicles() async {
    final response = await ApiService.getList('/vehicles/');

    return response
        .map((json) => VehicleModel.fromJson(json))
        .toList();
  }

  // Register a new vehicle.
  static Future<VehicleModel> registerVehicle({
    required int driverId,
    required String vehicleName,
    required String vehicleType,
    required String registrationNumber,
    required int seatingCapacity,
  }) async {
    final response = await ApiService.post(
      '/vehicles/',
      {
        'driver_id': driverId,
        'vehicle_name': vehicleName,
        'vehicle_type': vehicleType,
        'registration_number': registrationNumber,
        'seating_capacity': seatingCapacity,
      },
    );

    return VehicleModel.fromJson(response);
  }

  // Update an existing vehicle.
  static Future<VehicleModel> updateVehicle({
    required int vehicleId,
    required Map<String, dynamic> updates,
  }) async {
    final response = await ApiService.patch(
      '/vehicles/$vehicleId',
      body: updates,
    );

    return VehicleModel.fromJson(response);
  }
}
