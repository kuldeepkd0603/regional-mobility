
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class RecentTrips extends StatelessWidget {
  final List<Map<String, dynamic>> trips;
  final VoidCallback? onViewAll;

  const RecentTrips({
    super.key,
    required this.trips,
    this.onViewAll,
  });

  String _status(String? value) {
    switch (value?.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'ongoing':
        return 'In Progress';
      case 'driver_assigned':
        return 'Assigned';
      default:
        return value ?? 'Unknown';
    }
  }

  Color _statusColor(String? value) {
    switch (value?.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'ongoing':
        return Colors.orange;
      case 'driver_assigned':
        return AppColors.primary;
      default:
        return AppColors.textGrey;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final date = DateTime.tryParse(value.toString());
    if (date == null) return 'Date unavailable';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  String _formatFare(dynamic value) {
    if (value is num) return '₹${value.toStringAsFixed(0)}';
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent Trips',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text(
                  'View all',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (trips.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 34,
                  color: AppColors.textGrey,
                ),
                SizedBox(height: 10),
                Text(
                  'No trips yet',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your recent trips will appear here.',
                  style: TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          ...trips.map((trip) {
            final status = trip['booking_status']?.toString();

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_taxi_outlined,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${trip['pickup_city'] ?? 'Pickup'} → '
                          '${trip['drop_city'] ?? 'Drop'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _formatDate(
                            trip['completed_at'] ?? trip['scheduled_at'] ??
                                trip['created_at'],
                          ),
                          style: const TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _status(status),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatFare(
                      trip['final_fare'] ?? trip['estimated_fare'],
                    ),
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
