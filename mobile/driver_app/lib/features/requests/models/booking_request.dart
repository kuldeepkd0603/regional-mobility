class BookingRequest {
  final int id;
  final int passengerId;
  final int? driverId;
  final int? vehicleId;
  final String? preferredVehicleType;
  final String bookingStatus;
  final String tripType;
  final double estimatedFare;
  final DateTime? scheduledAt;
  final DateTime? returnAt;
  final int passengerCount;
  final String? specialInstructions;

  final String pickupCity;
  final String dropCity;
  final String pickupAddress;
  final String dropAddress;
  final double? distanceKm;

  const BookingRequest({
    required this.id,
    required this.passengerId,
    this.driverId,
    this.vehicleId,
    this.preferredVehicleType,
    required this.bookingStatus,
    required this.tripType,
    required this.estimatedFare,
    this.scheduledAt,
    this.returnAt,
    required this.passengerCount,
    this.specialInstructions,
    required this.pickupCity,
    required this.dropCity,
    required this.pickupAddress,
    required this.dropAddress,
    this.distanceKm,
  });

  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    final route = json['route'] as Map<String, dynamic>;

    return BookingRequest(
      id: json['id'] as int,
      passengerId: json['passenger_id'] as int,
      driverId: json['driver_id'] as int?,
      vehicleId: json['vehicle_id'] as int?,
      preferredVehicleType: json['preferred_vehicle_type'] as String?,
      bookingStatus: json['booking_status'] as String,
      tripType: json['trip_type'] as String,
      estimatedFare: (json['estimated_fare'] as num).toDouble(),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'])
          : null,
      returnAt: json['return_at'] != null
          ? DateTime.parse(json['return_at'])
          : null,
      passengerCount: json['passenger_count'] as int,
      specialInstructions: json['special_instructions'] as String?,
      pickupCity: route['pickup_city'] as String,
      dropCity: route['drop_city'] as String,
      pickupAddress: route['pickup_address'] as String,
      dropAddress: route['drop_address'] as String,
      distanceKm: (route['distance_km'] as num?)?.toDouble(),
    );
  }
}