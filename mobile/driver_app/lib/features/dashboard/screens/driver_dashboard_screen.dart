
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/screens/login_screen.dart';
import '../services/dashboard_service.dart';
import '../widgets/availability_card.dart';
import '../widgets/recent_trips.dart';
import '../../vehicles/screens/my_vehicles_screen.dart';
import '../../requests/screens/available_requests_screen.dart';
import '../../location/services/driver_location_service.dart';
import '../../trips/screens/my_trips_screen.dart';
import '../../earnings/screens/earnings_screen.dart';
import '../../profile/screens/driver_profile_screen.dart';
import '../../reviews/screens/driver_reviews_screen.dart';
import '../../notifications/screens/notifications_screen.dart';
class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() =>
      _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  DashboardData? _dashboard;
  bool _isLoading = true;
  bool _isUpdatingAvailability = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_dashboard == null && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    } else if (mounted) {
      setState(() => _error = null);
    }

    try {
      final data = await DashboardService.fetchDashboard();

      if (!mounted) return;

      if (!data.driver.isVerified) {
        await DriverLocationService.stopTracking();

        if (!mounted) return;

        Navigator.of(context).pushReplacementNamed('/');
        return;
      }

      setState(() {
        _dashboard = data;
        _isLoading = false;
        _error = null;
      });

      if (data.driver.isAvailable) {
        await _resumeLocationTracking(data.driver.id);
      } else {
        await DriverLocationService.stopTracking();
      }
    } on ApiException catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load dashboard. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAvailability(bool value) async {
    final dashboard = _dashboard;

    if (dashboard == null || _isUpdatingAvailability) return;

    if (!dashboard.driver.isVerified && value) {
      _showMessage(
        'Your account must be verified before going online.',
      );
      return;
    }

    setState(() => _isUpdatingAvailability = true);

    try {
      if (value) {
        await DriverLocationService.ensurePermission();

        await DashboardService.updateAvailability(
          driverId: dashboard.driver.id,
          isAvailable: true,
        );

        try {
          await DriverLocationService.startTracking(
            dashboard.driver.id,
          );
        } catch (_) {
          await DriverLocationService.stopTracking();

          await DashboardService.updateAvailability(
            driverId: dashboard.driver.id,
            isAvailable: false,
          );

          rethrow;
        }
      } else {
        await DashboardService.updateAvailability(
          driverId: dashboard.driver.id,
          isAvailable: false,
        );

        await DriverLocationService.stopTracking();
      }

      await _loadDashboard();

      if (!mounted) return;

      _showMessage(
        value
            ? 'You are online. Location sharing is active.'
            : 'You are offline. Location sharing stopped.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvailability = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'Are you sure you want to sign out of Raahi Driver?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await DriverLocationService.stopTracking();
    await AuthService.logout();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  String _firstName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Driver';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  Future<void> _openEarnings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const EarningsScreen(),
      ),
    );

    if (mounted) {
      await _loadDashboard();
    }
  }

  Widget _buildHeader(DashboardData data) {
    final name = _firstName(data.user['full_name']?.toString() ?? 'Driver');
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 12, 17, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF062F3A), Color(0xFF064B52)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            height: 42, width: 42, padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13)),
            child: Image.asset('assets/images/driver_icon.png', fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.local_taxi_rounded, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Text('Raahi Driver', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900))),
          _roundHeaderButton(icon: Icons.notifications_none_rounded, tooltip: 'Notifications', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          const SizedBox(width: 7),
          _roundHeaderButton(icon: Icons.person_outline_rounded, tooltip: 'My profile', onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
          }),
        ]),
        const SizedBox(height: 19),
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Good to see you, $name 👋', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            const Text('Ready for your next ride?', style: TextStyle(color: Color(0xFFD4E8EA), fontSize: 13)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: const Color(0xFF08B99A), borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 14), SizedBox(width: 4),
              Text('Verified', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
            ])),
        ]),
      ]),
    );
  }

  Widget _roundHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      child: IconButton(
        onPressed: onTap,
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.primary),
      ),
    );
  }

  Widget _buildCarHero(DashboardData data) {
    final online = data.driver.isAvailable;
    return Container(
      height: 194, width: double.infinity, clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF07505B), Color(0xFF087F86), Color(0xFF063B4A)]),
        borderRadius: BorderRadius.circular(23),
        boxShadow: [BoxShadow(color: const Color(0xFF064B52).withValues(alpha: .18), blurRadius: 16, offset: const Offset(0, 7))],
      ),
      child: Stack(children: [
        Positioned(right: -24, top: -45, child: Container(height: 160, width: 160,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: .06)))),
        Positioned(left: 18, top: 19, right: 18, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Container(width: 9, height: 9, decoration: BoxDecoration(
              color: online ? const Color(0xFF19E68C) : Colors.orange, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(online ? 'You are Online' : 'You are Offline', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            ]),
            const SizedBox(height: 5),
            Text(online ? 'You can now receive ride requests' : 'Go online to receive ride requests',
              style: const TextStyle(color: Color(0xFFE1F1F2), fontSize: 12)),
          ])),
          Switch.adaptive(value: online, onChanged: _isUpdatingAvailability ? null : _toggleAvailability,
            activeColor: Colors.white, activeTrackColor: const Color(0xFF08C96B),
            inactiveThumbColor: Colors.white, inactiveTrackColor: Colors.white24),
        ])),
        Positioned(right: 0, bottom: -2, width: 230, height: 112,
          child: Image.network(
            'https://www.marutisuzuki.com/adobe/assets/urn:aaid:aem:9f29148e-6fff-42c1-8b53-2e6b197e7ff/as/B130CE5AA61242A9BD400C3F9E1D2B96.jpg',
            fit: BoxFit.contain, alignment: Alignment.bottomRight,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )),
        Positioned(left: 16, bottom: 13, child: Text('DRIVE  •  EARN  •  GROW',
          style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.1))),
      ]),
    );
  }

  Widget _buildTodaySummary(DashboardData data) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.account_balance_wallet_outlined,
            label: "Today's earnings",
            value: '₹${data.stats.todayEarnings}',
            accent: AppColors.secondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.route_outlined,
            label: "Today's trips",
            value: '${data.stats.todayCompletedTrips}',
            accent: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textGrey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.secondary, size: 24),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 9, crossAxisSpacing: 9, childAspectRatio: .82,
      children: [
        _buildQuickAction(icon: Icons.calendar_month_rounded, title: 'My Trips', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTripsScreen()));
        }),
        _buildQuickAction(icon: Icons.account_balance_wallet_outlined, title: 'Earnings', onTap: _openEarnings),
        _buildQuickAction(icon: Icons.star_outline_rounded, title: 'Reviews', onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverReviewsScreen()));
        }),
        _buildQuickAction(icon: Icons.support_agent_rounded, title: 'Support', onTap: () => _showMessage('Help & Support will be available soon.')),
      ],
    );
  }

  Widget _buildMoreOptions() {
    return Column(
      children: [
        _buildVehicleManagementCard(),
        const SizedBox(height: 9),
        _buildNavigationCard(
          icon: Icons.folder_open_rounded,
          title: 'Documents',
          subtitle: 'Manage your driver documents and verification',
          onTap: () => _showMessage('Documents section is coming soon.'),
        ),
        const SizedBox(height: 9),
        _buildNavigationCard(
          icon: Icons.headset_mic_rounded,
          title: 'Help & Support',
          subtitle: 'Get help with rides and your account',
          onTap: () => _showMessage('Help & Support is coming soon.'),
        ),
        const SizedBox(height: 9),
        _buildNotificationsCard(),
      ],
    );
  }


  Widget _buildRideRequestsCard() {
    return Material(
      color: const Color(0xFFE0F8E9), borderRadius: BorderRadius.circular(19),
      child: InkWell(borderRadius: BorderRadius.circular(19), onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AvailableRequestsScreen()));
      }, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        child: Row(children: [
          const Icon(Icons.bolt_rounded, color: Color(0xFF08A85B), size: 30),
          const SizedBox(width: 12),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('New Ride Requests', style: TextStyle(color: Color(0xFF102D28), fontSize: 16, fontWeight: FontWeight.w900)),
            SizedBox(height: 4), Text('Find and accept your next ride', style: TextStyle(color: Color(0xFF45665B), fontSize: 12)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF087F55), size: 27),
        ])),
      ),
    );
  }

  Widget _buildDocumentsCard() {
    return _buildNavigationCard(
      icon: Icons.badge_outlined, title: 'Documents',
      subtitle: 'Keep your documents up to date',
      onTap: () => _showMessage('Documents section is coming soon.'),
    );
  }

  Widget _buildSectionTitle(String title, {String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
        top: 21,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveTrip(DashboardData data) {
    if (data.activeTrips.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.route_outlined,
                color: AppColors.textGrey,
                size: 25,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No active trip',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Your ongoing trip will appear here.',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final trip = data.activeTrips.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppColors.secondary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ongoing Trip',
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '#${trip['id']}',
                style: const TextStyle(
                  color: AppColors.textGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Divider(height: 1),
          ),
          _routeRow(
            Icons.trip_origin,
            'Pickup',
            trip['pickup_city']?.toString() ?? 'Not available',
          ),
          const SizedBox(height: 15),
          _routeRow(
            Icons.location_on_outlined,
            'Destination',
            trip['drop_city']?.toString() ?? 'Not available',
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Estimated fare: ₹${trip['estimated_fare'] ?? '—'}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.secondary,
        ),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: AppColors.textGrey,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedTrips(DashboardData data) {
    final assigned = data.assignedTrips;

    if (assigned.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.event_available_outlined,
            color: Color(0xFFD97706),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${assigned.length} assigned trip${assigned.length == 1 ? '' : 's'} waiting to start',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleManagementCard() {
    return _buildNavigationCard(
      icon: Icons.directions_car_outlined,
      title: 'My Vehicles',
      subtitle: 'Register and manage your vehicles',
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyVehiclesScreen(),
          ),
        );
      },
    );
  }

  Widget _buildNavigationCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: AppColors.secondary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 15,
                color: AppColors.textGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(DashboardData data) {
    return RefreshIndicator(
      onRefresh: _loadDashboard, color: AppColors.secondary,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        children: [
          _buildHeader(data),
          Padding(padding: const EdgeInsets.fromLTRB(16, 15, 16, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCarHero(data),
            const SizedBox(height: 15),
            _buildTodaySummary(data),
            const SizedBox(height: 19),
            _buildRideRequestsCard(),
            _buildSectionTitle('Current Trip', subtitle: 'Your active ride status'),
            _buildActiveTrip(data),
            if (data.assignedTrips.isNotEmpty) ...[
              const SizedBox(height: 10), _buildAssignedTrips(data),
            ],
            _buildSectionTitle('Quick Actions'),
            _buildQuickActions(),
            const SizedBox(height: 15),
            _buildDocumentsCard(),
            const SizedBox(height: 9),
            _buildNavigationCard(icon: Icons.support_agent_rounded, title: 'Help & Support',
              subtitle: 'Get assistance with rides and your account',
              onTap: () => _showMessage('Help & Support will be available soon.')),
          ])),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: AppColors.textGrey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Could not load dashboard',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please check your internet connection.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _resumeLocationTracking(int driverId) async {
    try {
      await DriverLocationService.ensurePermission();
      await DriverLocationService.startTracking(driverId);
    } catch (e) {
      debugPrint('Unable to resume driver location tracking: $e');

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: SafeArea(
        top: false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.secondary))
            : _error != null ? _buildError() : _dashboard == null ? _buildError() : _buildDashboard(_dashboard!),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, currentIndex: 0,
        selectedItemColor: const Color(0xFF08C96B), unselectedItemColor: const Color(0xFF9AAAB2),
        backgroundColor: const Color(0xFF063B45), selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTripsScreen()));
          } else if (index == 2) {
            _openEarnings();
          } else if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const DriverProfileScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.directions_car_filled_outlined), label: 'Trips'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Earnings'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNotificationsCard() {
    return _buildNavigationCard(
      icon: Icons.notifications_none_outlined,
      title: 'Notifications',
      subtitle: 'View ride updates and account alerts',
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NotificationsScreen(),
          ),
        );
      },
    );
  }
}
