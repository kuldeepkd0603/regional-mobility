
import 'package:flutter/material.dart';

import '../../../core/services/api_service.dart';
import '../../../theme/app_theme.dart';
import '../../dashboard/screens/driver_dashboard_screen.dart';
import '../services/auth_service.dart';
import 'approval_status_screen.dart';
import 'login_screen.dart';

class SplashRouter extends StatefulWidget {
  const SplashRouter({super.key});

  @override
  State<SplashRouter> createState() => _SplashRouterState();
}

class _SplashRouterState extends State<SplashRouter> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    try {
      final hasSession = await AuthService.hasSession();

      if (!mounted) return;

      if (!hasSession) {
        _goToLogin();
        return;
      }

      final profile = await AuthService.getDriverProfile();

      if (!mounted) return;

      if (profile.isVerified) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DriverDashboardScreen(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ApprovalStatusScreen(profile: profile),
          ),
        );
      }
    } on ApiException {
      await AuthService.logout();
      if (!mounted) return;
      _goToLogin();
    } catch (_) {
      if (!mounted) return;
      _goToLogin();
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final height = constraints.maxHeight;

            return Stack(
              children: [
                Positioned(
                  right: -90,
                  top: height * 0.34,
                  child: Container(
                    width: 210,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF36CEB5).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                Column(
                  children: [
                    const SizedBox(height: 18),

                    // Driver logo
                    Image.asset(
                      'assets/images/driver_icon.png',
                      height: height * 0.12,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your City. Your Ride. Your Way.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF073B3A),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Driver App badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7F5EE),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.directions_car_filled_rounded,
                            color: Color(0xFF07836A),
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Driver App',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073B3A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Dzire image
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Image.asset(
                          'assets/images/raahi_dzire_car.png',
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, error, stackTrace) {
                            return const Icon(
                              Icons.directions_car,
                              size: 110,
                              color: Color(0xFF07836A),
                            );
                          },
                        ),
                      ),
                    ),

                    // Driver benefits
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _DriverFeature(
                            icon: Icons.directions_car_outlined,
                            label: 'Accept\nRides',
                          ),
                          _DriverFeature(
                            icon: Icons.trending_up_rounded,
                            label: 'Track\nEarnings',
                          ),
                          _DriverFeature(
                            icon: Icons.route_rounded,
                            label: 'Flexible\nTrips',
                          ),
                          _DriverFeature(
                            icon: Icons.support_agent_rounded,
                            label: '24×7\nSupport',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Drive with Raahi. Earn with Freedom.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF073B3A),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PageDot(active: true),
                        _PageDot(),
                        _PageDot(),
                      ],
                    ),

                    const SizedBox(height: 18),

                    const _BottomWaves(),

                    const SizedBox(height: 6),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DriverFeature extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DriverFeature({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(
            icon,
            size: 30,
            color: const Color(0xFF087B5B),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: Color(0xFF172B35),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;

  const _PageDot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active
            ? const Color(0xFF39C928)
            : const Color(0xFFA7E5D9),
      ),
    );
  }
}

class _BottomWaves extends StatelessWidget {
  const _BottomWaves();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: CustomPaint(
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()..color = const Color(0xFF54CC38);
    final teal = Paint()..color = const Color(0xFF08BDA8);
    final darkTeal = Paint()..color = const Color(0xFF087E73);

    final greenPath = Path()
      ..moveTo(0, 10)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.8,
        size.width * 0.55,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.7,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final tealPath = Path()
      ..moveTo(0, 30)
      ..quadraticBezierTo(
        size.width * 0.4,
        size.height * 1.1,
        size.width * 0.7,
        size.height * 0.6,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.3,
        size.width,
        18,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final darkPath = Path()
      ..moveTo(0, 45)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.2,
        size.width,
        35,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(greenPath, green);
    canvas.drawPath(tealPath, teal);
    canvas.drawPath(darkPath, darkTeal);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
