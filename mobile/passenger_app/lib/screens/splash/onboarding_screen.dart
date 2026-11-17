import 'package:flutter/material.dart';
import '../auth/auth_gate.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const Color navy = Color(0xFF073B5C);
  static const Color teal = Color(0xFF08B69D);

  static const String heroAsset =
      'assets/images/raahi_assets/header/onboarding_hero.png';
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo_vertical.png';
  static const String skylineAsset =
      'assets/images/raahi_assets/header/city_skyline55.png';

  void _continue(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Keep the composition proportional on different phone sizes.
            final heroHeight = h * 0.640;
            final headingTop = h * 0.392;
            final cardsTop = h * 0.565;
            final cardHeight = h * 0.105;
            final skylineHeight = h * 0.205;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Hero photograph: temple, road and Raahi car.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 500,
                  height: heroHeight,
                  child: Image.asset(
                    heroAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                      color: Color(0xFFEAF7FA),
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: teal,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. White curved separator with the thin teal accent.
                Positioned(
                  top: h * 0.5,
                  left: 0,
                  right: 0,
                  height: h * 0,
                  child: const CustomPaint(
                    painter: _HeroWavePainter(),
                  ),
                ),

                // 3. Raahi logo over the hero image.
                Positioned(
                  top: h * 0.015,
                  left: w * 0.0,
                  width: w * 0.405,
                  height: h * 0.200,
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.topLeft,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),

                // 4. Skip action.
                Positioned(
                  top: h * 0.025,
                  right: w * 0.045,
                  child: TextButton(
                    onPressed: () => _continue(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 19,
                        color: Color(0xFF102B42),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // 5. Main heading and supporting text.
                Positioned(
                  top: headingTop,
                  left: w * 0.055,
                  right: w * 0.055,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Your Local & Intercity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (w * 0.067).clamp(24.0, 29.0),
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF111111),
                        ),
                      ),
                      Text(
                        'Travel Partner',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (w * 0.073).clamp(27.0, 32.0),
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          color: teal,
                        ),
                      ),
                      SizedBox(height: h * 0.014),
                      Text(
                        'Reliable, affordable and comfortable rides\\n'
                        'across Ujjain, Indore and Dewas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: (w * 0.041).clamp(14.0, 17.0),
                          height: 1.38,
                          color: const Color(0xFF333333),
                        ),
                      ),
                    ],
                  ),
                ),

                // 6. Four service cards in one evenly spaced row.
                Positioned(
                  top: cardsTop,
                  left: w * 0.065,
                  right: w * 0.065,
                  height: cardHeight,
                  child: const Row(
                    children: [
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.directions_car_filled_rounded,
                          title: 'Local\nRides',
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.add_road_rounded,
                          title: 'Intercity\nTravel',
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.autorenew_rounded,
                          title: 'Round\nTrips',
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _ServiceCard(
                          icon: Icons.temple_hindu_rounded,
                          title: 'Religious\nTours',
                        ),
                      ),
                    ],
                  ),
                ),

                // 7. Page indicators, immediately below the service cards.
                Positioned(
                  top: cardsTop + cardHeight + h * 0.012,
                  left: 0,
                  right: 0,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Dot(active: true),
                      _Dot(),
                      _Dot(),
                    ],
                  ),
                ),

                // 8. Light city/temple illustration near the bottom.
                // It is intentionally behind the button and bottom waves.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.105,
                  height: skylineHeight,
                  child: Opacity(
                    opacity: 0.42,
                    child: Image.asset(
                      skylineAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // 9. Bottom decorative waves.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: h * 0.105,
                  child: const CustomPaint(
                    painter: _BottomWavePainter(),
                  ),
                ),

                // 10. Get Started button, anchored above the system navigation.
                Positioned(
                  left: w * 0.055,
                  right: w * 0.055,
                  bottom: h * 0.035,
                  height: (h * 0.061).clamp(48.0, 58.0),
                  child: ElevatedButton(
                    onPressed: () => _continue(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.arrow_forward_rounded, size: 27),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _ServiceCard({
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE4EBF0)),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withValues(alpha: 0.055),
            blurRadius: 7,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: const Color(0xFF08A990),
            size: 33,
          ),
          const SizedBox(height: 5),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w500,
              color: Color(0xFF17212B),
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
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? const Color(0xFF08B69D) : const Color(0xFFC6D2DC),
      ),
    );
  }
}

class _HeroWavePainter extends CustomPainter {
  const _HeroWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final whitePath = Path()
      ..moveTo(0, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 1.05,
        size.width,
        size.height * 0.15,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(whitePath, Paint()..color = Colors.white);

    final tealAccent = Path()
      ..moveTo(0, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 0.94,
        size.width,
        size.height * 0.08,
      )
      ..lineTo(size.width, size.height * 0.18)
      ..quadraticBezierTo(
        size.width * 0.40,
        size.height * 1.08,
        0,
        size.height * 0.62,
      )
      ..close();

    canvas.drawPath(tealAccent, Paint()..color = const Color(0xFF08B69D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomWavePainter extends CustomPainter {
  const _BottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final palePath = Path()
      ..moveTo(0, size.height * 0.48)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.02,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(palePath, Paint()..color = const Color(0xFFE9F9F7));

    final tealPath = Path()
      ..moveTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.10,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(tealPath, Paint()..color = const Color(0xFF08B69D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
