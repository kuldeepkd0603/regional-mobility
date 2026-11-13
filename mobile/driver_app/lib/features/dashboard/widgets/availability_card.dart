
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

class AvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final bool isVerified;
  final bool isLoading;
  final ValueChanged<bool> onChanged;

  const AvailabilityCard({
    super.key,
    required this.isAvailable,
    required this.isVerified,
    required this.isLoading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final canGoOnline = isVerified && !isLoading;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable
              ? AppColors.success.withValues(alpha: 0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: isAvailable
                  ? AppColors.success.withValues(alpha: 0.10)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isAvailable ? Icons.wifi_tethering : Icons.wifi_off,
              color: isAvailable
                  ? AppColors.success
                  : AppColors.textGrey,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isAvailable ? 'You are Online' : 'You are Offline',
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  !isVerified
                      ? 'Verification required to go online'
                      : isAvailable
                          ? 'You can receive ride requests'
                          : 'Go online to receive ride requests',
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          else
            Switch.adaptive(
              value: isAvailable,
              onChanged: canGoOnline ? onChanged : null,
              activeTrackColor: AppColors.secondary,
            ),
        ],
      ),
    );
  }
}
