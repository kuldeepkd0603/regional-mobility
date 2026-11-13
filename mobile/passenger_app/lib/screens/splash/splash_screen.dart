
import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../auth/auth_gate.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const AuthGate(),
        ),
      );
    });
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
                  right: -100,
                  top: height * 0.34,
                  child: Container(
                    width: 230,
                    height: 180,
                    decoration: BoxDecoration(
                      color: const Color(0xFF45D6B9)
                          .withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                Positioned(
                  left: -100,
                  bottom: 0,
                  child: Container(
                    width: 230,
                    height: 130,
                    decoration: BoxDecoration(
                      color: const Color(0xFF54CC38)
                          .withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),

                Column(
                  children: [
                    const SizedBox(height: 20),

                    // Raahi logo
                    Image.asset(
                      'assets/images/app_icon.png',
                      height: height * 0.105,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Your City. Your Ride. Your Way.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF073B3A),
                      ),
                    ),

                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
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
                            Icons.groups_rounded,
                            color: Color(0xFF07836A),
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Passenger App',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF073B3A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Dzire image
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                        child: Image.asset(
                          'assets/images/raahi_dzire_car.png',
                          width: double.infinity,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    // Service categories
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          _ServiceItem(
                            icon: Icons.directions_car_outlined,
                            label: 'Local\nRides',
                          ),
                          _ServiceItem(
                            icon: Icons.route_outlined,
                            label: 'Outstation\nTrips',
                          ),
                          _ServiceItem(
                            icon: Icons.temple_hindu_outlined,
                            label: 'Religious\nTours',
                          ),
                          _ServiceItem(
                            icon: Icons.business_center_outlined,
                            label: 'Corporate\nTravel',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(active: true),
                        _Dot(),
                        _Dot(),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const _BottomWaves(),

                    const SizedBox(height: 8),
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

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ServiceItem({
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
            color: const Color(0xFF087B5B),
            size: 31,
          ),
          const SizedBox(height: 7),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF172B35),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final bool active;

  const _Dot({this.active = false});

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
      height: 65,
      width: double.infinity,
      child: CustomPaint(
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final green = Paint()
      ..color = const Color(0xFF54CC38);

    final teal = Paint()
      ..color = const Color(0xFF08BDA8);

    final darkTeal = Paint()
      ..color = const Color(0xFF087E73);

    Path greenPath = Path()
      ..moveTo(0, 10)
      ..quadraticBezierTo(
        size.width * 0.28,
        size.height * 0.75,
        size.width * 0.55,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.72,
        size.width,
        0,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    Path tealPath = Path()
      ..moveTo(0, 30)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 1.1,
        size.width * 0.65,
        size.height * 0.65,
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

    Path darkPath = Path()
      ..moveTo(0, 48)
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
