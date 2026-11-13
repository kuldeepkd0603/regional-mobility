import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../models/driver_profile.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../../dashboard/screens/driver_dashboard_screen.dart';

class ApprovalStatusScreen extends StatefulWidget {
  final DriverProfile profile;
  const ApprovalStatusScreen({super.key, required this.profile});

  @override
  State<ApprovalStatusScreen> createState() => _ApprovalStatusScreenState();
}

class _ApprovalStatusScreenState extends State<ApprovalStatusScreen> {
  bool _isRefreshing = false;
  late DriverProfile _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.profile;
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);

    try {
      final updated = await AuthService.getDriverProfile();

      if (!mounted) return;

      if (updated.isVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DriverDashboardScreen(),
          ),
        );
        return;
      }

      setState(() => _profile = updated);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Account Status'),
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textGrey),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.secondary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildProfileCard(),
              if (_profile.isPending || _profile.isRejected) ...[
                const SizedBox(height: 16),
                _buildRefreshButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (_profile.isVerified) {
      return _StatusCard(
        icon: Icons.verified_rounded,
        iconColor: AppColors.success,
        backgroundColor: const Color(0xFFEFFEF5),
        borderColor: AppColors.success,
        title: 'Account Verified!',
        subtitle: 'Your account has been approved. You can now proceed to the next stage of onboarding.',
        badge: 'VERIFIED',
        badgeColor: AppColors.success,
      );
    } else if (_profile.isRejected) {
      return const _StatusCard(
        icon: Icons.cancel_rounded,
        iconColor: AppColors.error,
        backgroundColor: Color(0xFFFEF2F2),
        borderColor: AppColors.error,
        title: 'Verification Rejected',
        subtitle:
            'Unfortunately, your driver verification was rejected. '
            'Please contact our support team for assistance.',
        badge: 'REJECTED',
        badgeColor: AppColors.error,
        supportInfo: true,
      );
    } else {
      // PENDING
      return const _StatusCard(
        icon: Icons.hourglass_top_rounded,
        iconColor: Color(0xFFD97706),
        backgroundColor: Color(0xFFFFFBEB),
        borderColor: Color(0xFFD97706),
        title: 'Pending Approval',
        subtitle:
            'Your application is under review by our admin team. '
            'This typically takes 24-48 hours. Pull down to refresh your status.',
        badge: 'PENDING',
        badgeColor: Color(0xFFD97706),
      );
    }
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Driver Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow(Icons.badge_outlined, 'Driver ID', '#${_profile.id}'),
          const SizedBox(height: 10),
          _infoRow(Icons.credit_card_outlined, 'Licence Number', _profile.licenseNumber),
          const SizedBox(height: 10),
          _infoRow(Icons.star_outline, 'Rating', '${_profile.rating.toStringAsFixed(1)} / 5.0'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textGrey),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRefreshButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isRefreshing ? null : _refresh,
        icon: _isRefreshing
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh Status'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final bool supportInfo;

  const _StatusCard({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    this.supportInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 60, color: iconColor),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badge,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          if (supportInfo) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.support_agent, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Contact: support@raahi.app',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
