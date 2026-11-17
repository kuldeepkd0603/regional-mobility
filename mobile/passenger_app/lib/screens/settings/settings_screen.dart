
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../profile/about_raahi_screen.dart';
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onLogout;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  const SettingsScreen({
    super.key,
    this.onLogout,
    this.onThemeModeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const navy = Color(0xFF102D50);
  static const teal = Color(0xFF08B99A);
  static const border = Color(0xFFE4E8EC);

  bool _locationEnabled = false;
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (mounted) {
        setState(() => _locationEnabled = enabled);
      }
    } catch (_) {}
  }

  Future<void> _toggleLocation(bool value) async {
    if (value) {
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _locationEnabled = false);
          _message('Location permission was not granted.');
        }
        return;
      }

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _locationEnabled = false);
          _message('Please enable location services on your phone.');
        }
        return;
      }
    }

    if (mounted) {
      setState(() => _locationEnabled = value);
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _chooseLanguage() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('Choose Language',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              title: const Text('English'),
              trailing: const Icon(Icons.check, color: teal),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: const Text('हिन्दी'),
              onTap: () {
                Navigator.pop(context);
                _message('Hindi language needs app-wide localization.');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _chooseTheme() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('App Appearance',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            _themeOption('Light', ThemeMode.light),
            _themeOption('Dark', ThemeMode.dark),
            _themeOption('System Default', ThemeMode.system),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(String title, ThemeMode mode) {
    return ListTile(
      title: Text(title),
      trailing: _themeMode == mode
          ? const Icon(Icons.check_circle, color: teal)
          : null,
      onTap: () {
        setState(() => _themeMode = mode);
        widget.onThemeModeChanged?.call(mode);
        Navigator.pop(context);
      },
    );
  }

  void _openInfo(String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text(
          'Are you sure you want to sign out from your Raahi account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              if (widget.onLogout != null) {
                widget.onLogout!();
              } else {
                _message('Connect your existing logout function here.');
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            final horizontal = constraints.maxWidth < 360 ? 12.0 : 18.0;
            final rowHeight = ((constraints.maxHeight -
                        (compact ? 205 : 245)) /
                    9)
                .clamp(48.0, 76.0);

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontal),
              child: Column(
                children: [
                  _header(compact),
                  SizedBox(height: compact ? 8 : 16),
                  Expanded(
                    child: Column(
                      children: [
                        _settingRow(
                          icon: Icons.language,
                          color: const Color(0xFF1976D2),
                          tileColor: const Color(0xFFE4F4FC),
                          title: 'Language',
                          subtitle: 'Choose your preferred language',
                          trailing: 'English',
                          height: rowHeight,
                          onTap: _chooseLanguage,
                        ),
                        _settingRow(
                          icon: Icons.notifications_none,
                          color: Colors.deepOrange,
                          tileColor: const Color(0xFFFFF0E3),
                          title: 'Notifications',
                          subtitle: 'Manage ride, payment and offer alerts',
                          height: rowHeight,
                          onTap: () => _openInfo(
                            'Notifications',
                            'Manage notification preferences in your phone settings.',
                          ),
                        ),
                        _settingRow(
                          icon: Icons.location_on_outlined,
                          color: Colors.green,
                          tileColor: const Color(0xFFE2F9ED),
                          title: 'Location Permission',
                          subtitle: 'Allow location access for better ride experience',
                          height: rowHeight,
                          trailingWidget: Switch(
                            value: _locationEnabled,
                            activeColor: navy,
                            onChanged: _toggleLocation,
                          ),
                          onTap: () => _toggleLocation(!_locationEnabled),
                        ),
                        _settingRow(
                          icon: Icons.palette_outlined,
                          color: Colors.deepPurple,
                          tileColor: const Color(0xFFF0E9FF),
                          title: 'App Appearance',
                          subtitle: 'Choose light, dark or system theme',
                          trailing: _themeMode == ThemeMode.light
                              ? 'Light'
                              : _themeMode == ThemeMode.dark
                                  ? 'Dark'
                                  : 'System',
                          height: rowHeight,
                          onTap: _chooseTheme,
                        ),
                        _settingRow(
                          icon: Icons.verified_user_outlined,
                          color: Colors.blue,
                          tileColor: const Color(0xFFE4F4FC),
                          title: 'Privacy & Data',
                          subtitle: 'Manage your data and privacy preferences',
                          height: rowHeight,
                          onTap: () => _openInfo(
                            'Privacy & Data',
                            'Privacy options and data controls can be connected here.',
                          ),
                        ),
                        _settingRow(
                          icon: Icons.lock_outline,
                          color: Colors.green,
                          tileColor: const Color(0xFFE2F9ED),
                          title: 'Security',
                          subtitle: 'Update PIN, enable biometric login',
                          height: rowHeight,
                          onTap: () => _openInfo(
                            'Security',
                            'PIN and biometric login are not configured yet.',
                          ),
                        ),
                        _settingRow(
                          icon: Icons.download_outlined,
                          color: Colors.deepPurple,
                          tileColor: const Color(0xFFF0E9FF),
                          title: 'App Updates',
                          subtitle: 'Check for the latest version',
                          trailing: 'v1.0.0',
                          height: rowHeight,
                          onTap: () => _openInfo(
                            'App Updates',
                            'You can connect Play Store version checking here.',
                          ),
                        ),
                        _settingRow(
                          icon: Icons.info_outline,
                          color: Colors.deepOrange,
                          tileColor: const Color(0xFFFFF0E3),
                          title: 'About Raahi',
                          subtitle: 'App version, terms, policies and more',
                          height: rowHeight,
                          onTap: () =>Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const AboutRaahiScreen(),
                            ),
                            ),
                        ),
                        _logoutRow(rowHeight),
                      ],
                    ),
                  ),
                  _footer(compact),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(bool compact) {
    return Column(
      children: [
        SizedBox(height: compact ? 3 : 10),
        SizedBox(
          height: compact ? 45 : 58,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.arrow_back, color: navy),
                ),
              ),
              Image.asset(
                'assets/images/raahi_assets/brand/raahi_logo.png',
                height: compact ? 43 : 55,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: compact ? 25 : 30,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF111827),
          ),
        ),
        Text(
          'Customize your app experience',
          style: TextStyle(
            fontSize: compact ? 12 : 15,
            color: navy,
          ),
        ),
        SizedBox(height: compact ? 7 : 15),
        Image.asset(
          'assets/images/raahi_assets/header/city_skyline54.png',
          height: compact ? 28 : 42,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _settingRow({
    required IconData icon,
    required Color color,
    required Color tileColor,
    required String title,
    required String subtitle,
    required double height,
    String? trailing,
    Widget? trailingWidget,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: border, width: 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: height * 0.78,
                    height: height * 0.78,
                    decoration: BoxDecoration(
                      color: tileColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: height * 0.48,
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            fontSize: height < 55 ? 12 : 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF111827),
                          ),
                        ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: height < 55 ? 9 : 11,
                            color: const Color(0xFF202B38),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing,
                      style: TextStyle(
                        fontSize: height < 55 ? 11 : 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (trailingWidget != null) trailingWidget,
                  const Icon(Icons.chevron_right, color: navy, size: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _logoutRow(double height) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 3),
        child: Material(
          color: const Color(0xFFFFF0F0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: Color(0xFFF4D8DC)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: _confirmLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Container(
                    width: height * 0.78,
                    height: height * 0.78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDDDF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: height * 0.48,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Logout',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          'Sign out from your Raahi account',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: height < 55 ? 9 : 11),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.red, size: 25),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(bool compact) {
    return Padding(
      padding: EdgeInsets.only(top: 5, bottom: compact ? 2 : 8),
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline53.png',
        height: compact ? 30 : 48,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(height: 8),
      ),
    );
  }
}
