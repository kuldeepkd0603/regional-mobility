class DriverTrip {
  final int id;
  final int passengerId;
  final int? driverId;
  final int? vehicleId;
  final String bookingStatus;
  final String tripType;
  final double estimatedFare;
  final double? finalFare;
  final int passengerCount;
  final String pickupCity;
  final String dropCity;
  final String pickupAddress;
  final String dropAddress;
  final double? distanceKm;
  final double? actualDistanceKm;
  final DateTime? scheduledAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  const DriverTrip({
    required this.id,
    required this.passengerId,
    this.driverId,
    this.vehicleId,
    required this.bookingStatus,
    required this.tripType,
    required this.estimatedFare,
    this.finalFare,
    required this.passengerCount,
    required this.pickupCity,
    required this.dropCity,
    required this.pickupAddress,
    required this.dropAddress,
    this.distanceKm,
    this.actualDistanceKm,
    this.scheduledAt,
    this.startedAt,
    this.completedAt,
    this.createdAt,
  });

  factory DriverTrip.fromJson(Map<String, dynamic> json) {
    double? number(dynamic value) =>
        value is num ? value.toDouble() : double.tryParse('$value');

    DateTime? date(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString());

    return DriverTrip(
      id: json['id'] as int,
      passengerId: json['passenger_id'] as int,
      driverId: json['driver_id'] as int?,
      vehicleId: json['vehicle_id'] as int?,
      bookingStatus: json['booking_status']?.toString() ?? '',
      tripType: json['trip_type']?.toString() ?? '',
      estimatedFare: number(json['estimated_fare']) ?? 0,
      finalFare: number(json['final_fare']),
      passengerCount: json['passenger_count'] as int? ?? 1,
      pickupCity: json['pickup_city']?.toString() ?? '',
      dropCity: json['drop_city']?.toString() ?? '',
      pickupAddress: json['pickup_address']?.toString() ?? '',
      dropAddress: json['drop_address']?.toString() ?? '',
      distanceKm: number(json['distance_km']),
      actualDistanceKm: number(json['actual_distance_km']),
      scheduledAt: date(json['scheduled_at']),
      startedAt: date(json['started_at']),
      completedAt: date(json['completed_at']),
      createdAt: date(json['created_at']),
    );
  }

  bool get isAssigned => bookingStatus.toLowerCase() == 'driver_assigned';
  bool get isOngoing => bookingStatus.toLowerCase() == 'ongoing';
  bool get isCompleted => bookingStatus.toLowerCase() == 'completed';
}