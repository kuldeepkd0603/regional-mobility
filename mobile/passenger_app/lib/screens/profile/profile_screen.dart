
import 'package:flutter/material.dart';
import '../support/help_support_screen.dart';
import '../../core/services/api_service.dart';
import '../auth/auth_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../settings/settings_screen.dart';
import '../offers/offers_rewards_screen.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color navy = Color(0xFF064B68);
  static const Color green = Color(0xFF159B52);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF687586);
  static const Color border = Color(0xFFE5E9ED);

  static const String logoPath =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  static const String footerPath =
      'assets/images/raahi_assets/header/city_skyline5.png';

  late Future<Map<String, dynamic>> userFuture;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  void loadProfile() {
    userFuture = ApiService.getCurrentUser();
  }

  Future<void> refreshProfile() async {
    setState(loadProfile);
    await userFuture;
  }

  String displayValue(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return 'N/A';
    }
    return value.toString();
  }

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (route) => false,
    );
  }

  Future<void> editProfile(String currentName) async {
    final controller = TextEditingController(text: currentName);
    String? errorText;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = controller.text.trim();

                          if (name.length < 2) {
                            setDialogState(() {
                              errorText = 'Enter a valid name';
                            });
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                            errorText = null;
                          });

                          try {
                            await ApiService.updateProfile(
                              fullName: name,
                            );

                            if (!dialogContext.mounted) return;
                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            setDialogState(() {
                              saving = false;
                              errorText = e
                                  .toString()
                                  .replaceFirst('Exception: ', '');
                            });
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (result == true && mounted) {
      setState(loadProfile);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: green,
        ),
      );
    }
  }

  void openBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MyBookingsScreen(),
      ),
    );
  }

  void openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }

  void comingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title - Coming Soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: userFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: green),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 55,
                      color: grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Unable to load profile'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: refreshProfile,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final user = snapshot.data!;
            final fullName = displayValue(user['full_name']);
            final phone = displayValue(user['phone']);
            final email = displayValue(user['email']);

            return LayoutBuilder(
              builder: (context, constraints) {
                final scale =
                    (constraints.maxHeight / 660).clamp(0.52, 1.0);

                double s(double size) => size * scale;

                return Column(
                  children: [
                    _header(s),

                    _profileHeader(
                      s,
                      fullName,
                      phone,
                      email,
                    ),

                    SizedBox(height: s(2)),

                    _statistics(s),

                    SizedBox(height: s(12)),

                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: s(16),
                        ),
                        child: Column(
                          children: [
                            _menuItem(
                              s,
                              icon: Icons.calendar_month_outlined,
                              title: 'My Bookings',
                              subtitle: 'View and manage your ride bookings',
                              color: const Color(0xFFE4F4FF),
                              iconColor: const Color(0xFF1672C4),
                              onTap: openBookings,
                            ),
                            _menuItem(
                              s,
                              icon: Icons.location_on_outlined,
                              title: 'Saved Places',
                              subtitle: 'Home, Work and other saved locations',
                              color: const Color(0xFFE4F9ED),
                              iconColor: green,
                              onTap: () => comingSoon('Saved Places'),
                            ),
                            _menuItem(
                              s,
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'My Payments',
                              subtitle: 'Transactions, invoices and payment methods',
                              color: const Color(0xFFF0E9FF),
                              iconColor: const Color(0xFF6336C7),
                              onTap: () => comingSoon('My Payments'),
                            ),
                            _menuItem(
                              s,
                              icon: Icons.notifications_none_rounded,
                              title: 'Notifications',
                              subtitle: 'Ride updates, payment alerts and offers',
                              color: const Color(0xFFFFF0DF),
                              iconColor: const Color(0xFFE87917),
                              onTap: openNotifications,
                            ),
                            _menuItem(
                              s,
                              icon: Icons.card_giftcard_outlined,
                              title: 'Offers & Rewards',
                              subtitle: 'View available offers and your rewards',
                              color: const Color(0xFFFFE8EB),
                              iconColor: Colors.red,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const OffersRewardsScreen(),
                                  ),
                                );
                              },
                            ),
                            _menuItem(
                              s,
                              icon: Icons.help_outline_rounded,
                              title: 'Help & Support',
                              subtitle: 'Get help, raise a request or contact support',
                              color: const Color(0xFFE5F3FF),
                              iconColor: Colors.blue,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HelpSupportScreen(),
                                  ),
                                );
                              },
                            ),
                            _menuItem(
                              s,
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              subtitle: 'App preferences, privacy and more',
                              color: const Color(0xFFF0E9FF),
                              iconColor: Colors.deepPurple,
                              onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            ),
                            _menuItem(
                              s,
                              icon: Icons.logout_rounded,
                              title: 'Logout',
                              subtitle: 'Sign out from your Raahi account',
                              color: const Color(0xFFFFE8EB),
                              iconColor: Colors.red,
                              onTap: logout,
                            ),
                          ],
                        ),
                      ),
                    ),

                    _bottomNavigation(s),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _header(double Function(double) s) {
    return SizedBox(
      height: s(105),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 12,
            top: s(10),
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(
                Icons.arrow_back,
                color: dark,
                size: 28,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: s(10),
            child: IconButton(
              onPressed: openNotifications,
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: dark,
                size: 27,
              ),
            ),
          ),
          Positioned(
            top: s(3),
            child: Image.asset(
              logoPath,
              height: s(65),
              width: 180,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Text(
                'Raahi',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: navy,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: s(1),
            child: Column(
              children: [
                Text(
                  'My Profile',
                  style: TextStyle(
                    fontSize: s(25),
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
                Text(
                  'Manage your account, bookings and preferences',
                  style: TextStyle(
                    fontSize: s(11.5),
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileHeader(
    double Function(double) s,
    String name,
    String phone,
    String email,
  ) {
    return Container(
      height: s(110),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: s(18)),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFF1FBFC),
            Color(0xFFE5F8F8),
            Colors.white,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: s(100),
            height: s(100),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE6F5F0),
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const Icon(
              Icons.person,
              size: 62,
              color: navy,
            ),
          ),
          SizedBox(width: s(12)),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: s(17),
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
                SizedBox(height: s(8)),
                _profileLine(
                  Icons.phone_outlined,
                  phone,
                  s,
                ),
                SizedBox(height: s(7)),
                _profileLine(
                  Icons.mail_outline,
                  email,
                  s,
                ),
              ],
            ),
          ),
          SizedBox(width: s(5)),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(height: s(16)),
              OutlinedButton.icon(
                onPressed: () => editProfile(name),
                icon: Icon(Icons.edit_outlined, size: s(14)),
                label: Text(
                  'Edit',
                  style: TextStyle(fontSize: s(11)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  side: const BorderSide(color: navy),
                  padding: EdgeInsets.symmetric(
                    horizontal: s(8),
                    vertical: s(7),
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _profileLine(
    IconData icon,
    String text,
    double Function(double) s,
  ) {
    return Row(
      children: [
        Icon(icon, size: s(17), color: dark),
        SizedBox(width: s(7)),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: s(11.5),
              color: dark,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statistics(double Function(double) s) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: s(16)),
      padding: EdgeInsets.symmetric(vertical: s(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(
            s,
            Icons.directions_car_outlined,
            'N/A',
            'Total Rides',
            const Color(0xFFE4F4FF),
            navy,
          ),
          _statDivider(s),
          _statItem(
            s,
            Icons.star_outline_rounded,
            'N/A',
            'Your Rating',
            const Color(0xFFFFF5DE),
            Colors.orange,
          ),
          _statDivider(s),
          _statItem(
            s,
            Icons.account_balance_wallet_outlined,
            'N/A',
            'Wallet Balance',
            const Color(0xFFE4F9ED),
            green,
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    double Function(double) s,
    IconData icon,
    String value,
    String label,
    Color background,
    Color color,
  ) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: s(38),
            height: s(38),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: s(23)),
          ),
          SizedBox(width: s(5)),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: s(15),
                    fontWeight: FontWeight.w900,
                    color: dark,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: s(9),
                    color: dark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider(double Function(double) s) {
    return Container(
      height: s(42),
      width: 1,
      color: border,
    );
  }

  Widget _menuItem(
    double Function(double) s, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(bottom: s(5)),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: s(12)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: border),
              ),
              child: Row(
                children: [
                  Container(
                    width: s(48),
                    height: s(48),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      icon,
                      color: iconColor,
                      size: s(27),
                    ),
                  ),
                  SizedBox(width: s(12)),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: s(14),
                            fontWeight: FontWeight.w900,
                            color: dark,
                          ),
                        ),
                        SizedBox(height: s(3)),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: s(10),
                            color: dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: s(25),
                    color: dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomNavigation(double Function(double) s) {
    return Container(
      height: s(66),
      padding: EdgeInsets.symmetric(horizontal: s(8)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: border),
        ),
      ),
      child: Row(
        children: [
          _bottomItem(s, Icons.home_outlined, 'Home', false),
          _bottomItem(s, Icons.directions_car_outlined, 'Book Ride', false),
          _bottomItem(s, Icons.calendar_month_outlined, 'My Bookings', false,
              onTap: openBookings),
          _bottomItem(s, Icons.account_balance_wallet_outlined, 'Wallet', false),
          _bottomItem(s, Icons.person_outline, 'Profile', true),
        ],
      ),
    );
  }

  Widget _bottomItem(
    double Function(double) s,
    IconData icon,
    String label,
    bool selected, {
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap ?? () => comingSoon(label),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: s(2),
            vertical: s(5),
          ),
          decoration: BoxDecoration(
            color: selected ? navy : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: s(23),
                color: selected ? Colors.white : dark,
              ),
              SizedBox(height: s(2)),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: s(8.5),
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : dark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
