
class DashboardStats {
  final int todayCompletedTrips;
  final int totalCompletedTrips;
  final double todayEarnings;
  final double totalEarnings;
  final double rating;

  const DashboardStats({
    required this.todayCompletedTrips,
    required this.totalCompletedTrips,
    required this.todayEarnings,
    required this.totalEarnings,
    required this.rating,
  });

  factory DashboardStats.fromTrips(
    List<Map<String, dynamic>> trips, {
    required double rating,
  }) {
    final now = DateTime.now();

    final completedTrips = trips.where((trip) {
      return trip['booking_status']?.toString().toLowerCase() ==
          'completed';
    }).toList();

    final todayTrips = completedTrips.where((trip) {
      final completedAt = trip['completed_at'] ??
          trip['scheduled_at'];

      if (completedAt == null) return false;

      final date = DateTime.tryParse(completedAt.toString());
      if (date == null) return false;

      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }).toList();

    double earnings(List<Map<String, dynamic>> items) {
      return items.fold<double>(0, (total, trip) {
        final fare = trip['final_fare'];
        return total + (fare is num ? fare.toDouble() : 0);
      });
    }

    return DashboardStats(
      todayCompletedTrips: todayTrips.length,
      totalCompletedTrips: completedTrips.length,
      todayEarnings: earnings(todayTrips),
      totalEarnings: earnings(completedTrips),
      rating: rating,
    );
  }
}
