import '../../../core/services/api_service.dart';
import '../models/driver_trip.dart';

class TripService {
  static Future<List<DriverTrip>> getDriverTrips(int driverId) async {
    final response = await ApiService.getList(
      '/trips/driver/$driverId',
    );

    return response.map(DriverTrip.fromJson).toList();
  }

  static Future<DriverTrip> getTripDetails(int bookingId) async {
    final response = await ApiService.get(
      '/trips/$bookingId',
    );

    return DriverTrip.fromJson(response);
  }

  static Future<void> startTrip(int bookingId) async {
    await ApiService.patch('/trips/$bookingId/start');
  }

  static Future<Map<String, dynamic>> completeTrip({
    required int bookingId,
    required double actualDistanceKm,
  }) async {
    return ApiService.patch(
      '/trips/$bookingId/complete',
      body: {
        'actual_distance_km': actualDistanceKm,
      },
    );
  }
}