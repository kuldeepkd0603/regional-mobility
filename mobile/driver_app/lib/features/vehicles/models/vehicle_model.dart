
class VehicleModel {
  final int id;
  final int driverId;
  final String vehicleName;
  final String vehicleType;
  final String registrationNumber;
  final int seatingCapacity;
  final bool isActive;

  const VehicleModel({
    required this.id,
    required this.driverId,
    required this.vehicleName,
    required this.vehicleType,
    required this.registrationNumber,
    required this.seatingCapacity,
    required this.isActive,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] as int,
      driverId: json['driver_id'] as int,
      vehicleName: json['vehicle_name'] as String,
      vehicleType: json['vehicle_type'] as String,
      registrationNumber: json['registration_number'] as String,
      seatingCapacity: json['seating_capacity'] as int,
      isActive: json['is_active'] as bool,
    );
  }
}
