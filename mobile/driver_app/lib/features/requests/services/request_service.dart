import '../../../core/services/api_service.dart';
import '../models/booking_request.dart';

class RequestService {
  static Future<List<BookingRequest>> getAvailableRequests() async {
    final response = await ApiService.getList('/bookings/available');

    return response
        .map((json) => BookingRequest.fromJson(json))
        .toList();
  }

  static Future<BookingRequest> acceptRequest({
    required int bookingId,
    required int vehicleId,
  }) async {
    final response = await ApiService.patch(
      '/bookings/$bookingId/accept',
      body: {
        'vehicle_id': vehicleId,
      },
    );

    return BookingRequest.fromJson(response);
  }
}