import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Physical phone: use your computer's local IPv4 address.
  // Android emulator: use 10.0.2.2 instead of localhost.
  static const String baseUrl = 'http://192.168.29.201:8000';

  static Future<Map<String, dynamic>> login({
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      return data;
    }

    throw Exception(data['detail'] ?? 'Login failed');
  }

  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'full_name': fullName,
        'phone': phone,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access_token']);
      return data;
    }

    throw Exception(data['detail'] ?? 'Registration failed');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No login session found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      await logout();
      throw Exception('Session expired. Please login again.');
    }

    throw Exception('Unable to verify login session');
  }

  // Estimate ride fare.
  static Future<Map<String, dynamic>> estimateFare({
    required String tripType,
    required String vehicleType,
    required double distanceKm,
    int passengerCount = 1,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/fares/estimate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'trip_type': tripType,
        'vehicle_type': vehicleType,
        'distance_km': distanceKm,
        'passenger_count': passengerCount,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data as Map<String, dynamic>;
    }

    throw Exception(data['detail'] ?? 'Fare estimation failed');
  }

  // Create a passenger booking.
  static Future<Map<String, dynamic>> createBooking({
    required int passengerId,
    required String tripType,
    required String preferredVehicleType,
    required String pickupCity,
    required String dropCity,
    required String pickupAddress,
    required String dropAddress,
    required double distanceKm,
    required DateTime scheduledAt,
    DateTime? returnAt,
    int passengerCount = 1,
    String? specialInstructions,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/bookings/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'passenger_id': passengerId,
        'trip_type': tripType,
        'preferred_vehicle_type': preferredVehicleType,
        'pickup_city': pickupCity,
        'drop_city': dropCity,
        'pickup_address': pickupAddress,
        'drop_address': dropAddress,
        'distance_km': distanceKm,
        'scheduled_at': scheduledAt.toIso8601String(),
        'return_at': returnAt?.toIso8601String(),
        'passenger_count': passengerCount,
        'special_instructions': specialInstructions,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data as Map<String, dynamic>;
    }

    throw Exception(data['detail'] ?? 'Booking creation failed');
  }

  static Future<List<Map<String, dynamic>>> findNearbyDrivers({
    required double latitude,
    required double longitude,
    required String vehicleType,
    int passengerCount = 1,
    double radiusKm = 10,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final uri = Uri.parse('$baseUrl/locations/nearby').replace(
      queryParameters: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'radius_km': radiusKm.toString(),
        'passenger_count': passengerCount.toString(),
        'vehicle_type': vehicleType,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Unable to find nearby drivers'
          : 'Unable to find nearby drivers',
    );
  }
  // Get all bookings for the logged-in passenger.
  static Future<List<Map<String, dynamic>>> getMyBookings() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/bookings/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Unable to load bookings'
          : 'Unable to load bookings',
    );
  }

  // Get road distance from the backend Google Routes endpoint.
  // This method is intentionally declared only once.
  static Future<double> getRouteDistanceKm({
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/routes/distance'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'pickup_latitude': pickupLatitude,
            'pickup_longitude': pickupLongitude,
            'drop_latitude': dropLatitude,
            'drop_longitude': dropLongitude,
          }),
        )
        .timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return (data['distance_km'] as num).toDouble();
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Google Routes distance calculation failed'
          : 'Google Routes distance calculation failed',
    );
  }
  
  // Get the assigned driver's latest location for a booking.
  static Future<Map<String, dynamic>> getAssignedDriverLocation({
    required int bookingId,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/locations/booking/$bookingId/driver'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Unable to get driver location'
          : 'Unable to get driver location',
    );
  }

  
  // Cancel a pending passenger booking.
  static Future<Map<String, dynamic>> cancelBooking({
      required int bookingId,
    }) async {
      final token = await getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Please login first');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'booking_status': 'cancelled',
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return data as Map<String, dynamic>;
      }

      throw Exception(
        data is Map
            ? data['detail'] ?? 'Unable to cancel booking'
            : 'Unable to cancel booking',
      );
  }


  // Register Firebase device token with backend.
  static Future<void> registerDeviceToken(String fcmToken) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/notifications/device-token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': fcmToken,
        'platform': 'android',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Device token registration failed: ${response.body}');
    }
  }

  // Remove Firebase device token on logout.
  static Future<void> removeDeviceToken(String fcmToken) async {
    final token = await getToken();

    if (token == null || token.isEmpty) return;

    final uri = Uri.parse('$baseUrl/notifications/device-token')
        .replace(queryParameters: {'token': fcmToken});

    final response = await http.delete(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Device token removal failed: ${response.body}');
    }
  }

  // Fetch passenger notifications.
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw Exception('Unable to load notifications');
  }

  // Mark one notification as read.
  static Future<void> markNotificationRead(int notificationId) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to mark notification as read');
    }
  }

  // Mark all notifications as read.
  static Future<void> markAllNotificationsRead() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Unable to mark all notifications as read');
    }
  }


  // Update passenger profile.
  static Future<Map<String, dynamic>> updateProfile({
    required String fullName,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.patch(
      Uri.parse('$baseUrl/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'full_name': fullName.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Profile update failed'
          : 'Profile update failed',
    );
  }

  // Submit a driver review after completing a trip.
  static Future<Map<String, dynamic>> submitDriverReview({
    required int bookingId,
    required int rating,
    String? review,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/reviews/'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'booking_id': bookingId,
        'rating': rating,
        'review': review?.trim().isEmpty == true
            ? null
            : review?.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map
          ? data['detail'] ?? 'Unable to submit review'
          : 'Unable to submit review',
    );
  }

  // Get the review submitted for a particular booking.
  // Get the review submitted for a particular booking.
static Future<Map<String, dynamic>?> getBookingReview({
    required int bookingId,
  }) async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Please login first');
    }

    final uri = Uri.parse('$baseUrl/reviews/booking/$bookingId');

    print('⭐ Calling review API: $uri');

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 10));

    print('⭐ Review API status: ${response.statusCode}');
    print('⭐ Review API body: ${response.body}');

    if (response.statusCode == 200) {
      final body = response.body.trim();

      if (body.isEmpty || body == 'null') {
        return null;
      }

      final data = jsonDecode(body);
      return Map<String, dynamic>.from(data);
    }

    final body = response.body.trim();
    throw Exception(
      body.isNotEmpty
          ? (jsonDecode(body) is Map
              ? jsonDecode(body)['detail'] ?? 'Unable to load review'
              : 'Unable to load review')
          : 'Unable to load review',
    );
  }
}
