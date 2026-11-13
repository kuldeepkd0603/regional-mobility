
class EarningsSummary {
  final double totalEarnings;
  final int completedTrips;
  final double averagePerTrip;

  const EarningsSummary({
    required this.totalEarnings,
    required this.completedTrips,
    required this.averagePerTrip,
  });

  factory EarningsSummary.fromJson(Map<String, dynamic> json) {
    return EarningsSummary(
      totalEarnings: (json['total_earnings'] as num?)?.toDouble() ?? 0,
      completedTrips: (json['completed_trips'] as num?)?.toInt() ?? 0,
      averagePerTrip: (json['average_per_trip'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EarningsRecord {
  final int bookingId;
  final double finalFare;
  final double estimatedFare;
  final double? actualDistanceKm;
  final DateTime? completedAt;
  final String tripType;

  const EarningsRecord({
    required this.bookingId,
    required this.finalFare,
    required this.estimatedFare,
    this.actualDistanceKm,
    this.completedAt,
    required this.tripType,
  });

  factory EarningsRecord.fromJson(Map<String, dynamic> json) {
    return EarningsRecord(
      bookingId: (json['booking_id'] as num).toInt(),
      finalFare: (json['final_fare'] as num).toDouble(),
      estimatedFare: (json['estimated_fare'] as num?)?.toDouble() ?? 0,
      actualDistanceKm:
          (json['actual_distance_km'] as num?)?.toDouble(),
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'].toString())
          : null,
      tripType: json['trip_type']?.toString() ?? 'local',
    );
  }
}

class DriverEarnings {
  final int driverId;
  final String currency;
  final EarningsSummary today;
  final EarningsSummary thisWeek;
  final EarningsSummary thisMonth;
  final EarningsSummary lifetime;
  final List<EarningsRecord> recentEarnings;

  const DriverEarnings({
    required this.driverId,
    required this.currency,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.lifetime,
    required this.recentEarnings,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    final records = json['recent_earnings'] as List? ?? [];

    return DriverEarnings(
      driverId: (json['driver_id'] as num).toInt(),
      currency: json['currency']?.toString() ?? 'INR',
      today: EarningsSummary.fromJson(
        Map<String, dynamic>.from(json['today'] ?? {}),
      ),
      thisWeek: EarningsSummary.fromJson(
        Map<String, dynamic>.from(json['this_week'] ?? {}),
      ),
      thisMonth: EarningsSummary.fromJson(
        Map<String, dynamic>.from(json['this_month'] ?? {}),
      ),
      lifetime: EarningsSummary.fromJson(
        Map<String, dynamic>.from(json['lifetime'] ?? {}),
      ),
      recentEarnings: records
          .whereType<Map>()
          .map((item) => EarningsRecord.fromJson(
                Map<String, dynamic>.from(item),
              ))
          .toList(),
    );
  }
}
