
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../auth/models/driver_profile.dart';
import '../models/dashboard_stats.dart';

class DashboardData {
  final DriverProfile driver;
  final Map<String, dynamic> user;
  final List<Map<String, dynamic>> trips;
  final DashboardStats stats;

  const DashboardData({
    required this.driver,
    required this.user,
    required this.trips,
    required this.stats,
  });

  List<Map<String, dynamic>> get activeTrips {
    return trips.where((trip) {
      return trip['booking_status']?.toString().toLowerCase() ==
          'ongoing';
    }).toList();
  }

  List<Map<String, dynamic>> get assignedTrips {
    return trips.where((trip) {
      return trip['booking_status']?.toString().toLowerCase() ==
          'driver_assigned';
    }).toList();
  }

  List<Map<String, dynamic>> get recentTrips {
    final sorted = [...trips];

    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(
            (a['created_at'] ?? '').toString(),
          ) ??
          DateTime(2000);

      final dateB = DateTime.tryParse(
            (b['created_at'] ?? '').toString(),
          ) ??
          DateTime(2000);

      return dateB.compareTo(dateA);
    });

    return sorted.take(5).toList();
  }
}

class DashboardService {
  static Future<DashboardData> fetchDashboard() async {
    final profileJson = await ApiService.get(
      ApiConstants.driverMe,
    );

    final driver = DriverProfile.fromJson(profileJson);

    final user = await ApiService.get(
      ApiConstants.authMe,
    );

    final trips = await ApiService.getList(
      '/trips/driver/${driver.id}',
    );

    final stats = DashboardStats.fromTrips(
      trips,
      rating: driver.rating,
    );

    return DashboardData(
      driver: driver,
      user: user,
      trips: trips,
      stats: stats,
    );
  }

  static Future<void> updateAvailability({
    required int driverId,
    required bool isAvailable,
  }) async {
    await ApiService.patch(
      '/drivers/$driverId/availability',
      body: {'is_available': isAvailable},
    );
  }
}
