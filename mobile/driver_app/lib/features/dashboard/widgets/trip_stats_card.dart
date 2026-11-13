
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class TripStatsCard extends StatelessWidget {
  final int todayTrips;
  final int totalTrips;
  final double rating;

  const TripStatsCard({
    super.key,
    required this.todayTrips,
    required this.totalTrips,
    required this.rating,
  });

  Widget _buildStat({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 21),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          _buildStat(
            icon: Icons.today_outlined,
            title: 'Today Trips',
            value: todayTrips.toString(),
            iconColor: AppColors.secondary,
          ),
          Container(
            height: 65,
            width: 1,
            color: Colors.grey.shade200,
          ),
          _buildStat(
            icon: Icons.route_outlined,
            title: 'Total Trips',
            value: totalTrips.toString(),
            iconColor: AppColors.primary,
          ),
          Container(
            height: 65,
            width: 1,
            color: Colors.grey.shade200,
          ),
          _buildStat(
            icon: Icons.star_rounded,
            title: 'Rating',
            value: rating.toStringAsFixed(1),
            iconColor: const Color(0xFFF59E0B),
          ),
        ],
      ),
    );
  }
}
