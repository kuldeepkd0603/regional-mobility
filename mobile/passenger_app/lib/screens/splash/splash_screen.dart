import 'package:flutter/material.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  // Keep these paths aligned with the filenames in pubspec.yaml.
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo_vertical.png';

  static const String skylineAsset =
      'assets/images/raahi_assets/header/city_skyline55.png';

  static const String carAsset =
      'assets/images/raahi_assets/header/White_Suzuki_Dzire.png';

  static const Color navy = Color(0xFF073B5C);
  static const Color teal = Color(0xFF08B69D);

  void _getStarted(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingScreen(),
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
            final width = constraints.maxWidth;
            final height = constraints.maxHeight;

            // All positions are proportional to the available screen area,
            // so the layout scales on different phone sizes.
            final compact = height < 680;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // 1. Raahi logo
                Positioned(
                  top: height * (compact ? 0.105 : 0.115),
                  left: width * 0.205,
                  right: width * 0.205,
                  height: height * (compact ? 0.205 : 0.225),
                  child: Image.asset(
                    logoAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.center,
                    errorBuilder: (_, __, ___) =>
                        const Center(child: Icon(Icons.image_not_supported)),
                  ),
                ),

                // 2. Tagline
                Positioned(
                  top: height * (compact ? 0.335 : 0.345),
                  left: width * 0.055,
                  right: width * 0.055,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: const Text(
                      'Your Local & Intercity Travel Partner',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF555555),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                // 3. Launch cities
                Positioned(
                  top: height * (compact ? 0.395 : 0.405),
                  left: width * 0.19,
                  right: width * 0.19,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CityLabel('Ujjain'),
                      _CityDivider(),
                      _CityLabel('Indore'),
                      _CityDivider(),
                      _CityLabel('Dewas'),
                    ],
                  ),
                ),

                // 4. Faded temple and city illustration.
                // This stays behind the car and the wave artwork.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.385,
                  height: height * 0.415,
                  child: Opacity(
                    opacity: 0.22,
                    child: Image.asset(
                      skylineAsset,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                ),

                // 5. Curved navy and teal ribbon waves.
                // The painter is intentionally transparent outside the
                // ribbons, leaving the button area white.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.255,
                  height: height * 0.335,
                  child: const IgnorePointer(
                    child: CustomPaint(
                      painter: _WelcomeWavePainter(),
                    ),
                  ),
                ),

                // 6. White Raahi Dzire, layered over the skyline and waves.
                Positioned(
                  right: width * 0.50,
                  bottom: height * 0.335,
                  width: width * 0.47,
                  height: height * 0.175,
                  child: Image.asset(
                    carAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),

                // 7. Three onboarding page indicators.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: height * 0.245,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PageDot(active: true),
                      _PageDot(),
                      _PageDot(),
                    ],
                  ),
                ),

                // 8. Get Started button on a clean white area.
                Positioned(
                  left: width * 0.055,
                  right: width * 0.055,
                  bottom: height * 0.065,
                  height: height * 0.075,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(36),
                      onTap: () => _getStarted(context),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFF08B69D),
                              Color(0xFF079C88),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(36),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Get Started',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(width: 14),
                            Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 29,
                            ),
                          ],
                        ),
                      ),
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

class _CityLabel extends StatelessWidget {
  final String city;

  const _CityLabel(this.city);

  @override
  Widget build(BuildContext context) {
    return Text(
      city,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF222222),
      ),
    );
  }
}

class _CityDivider extends StatelessWidget {
  const _CityDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 23,
      color: SplashScreen.teal,
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool active;

  const _PageDot({this.active = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: active ? 12 : 11,
      height: active ? 12 : 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? SplashScreen.teal : const Color(0xFFC6D2DC),
      ),
    );
  }
}

class _WelcomeWavePainter extends CustomPainter {
  const _WelcomeWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final tealPaint = Paint()
      ..color = SplashScreen.teal
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final navyPaint = Paint()
      ..color = SplashScreen.navy
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Navy ribbon: a broad, smooth curve running from lower-left
    // toward the upper-right.
    final navyPath = Path()
      ..moveTo(0, size.height * 0.54)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.78,
        size.width * 0.39,
        size.height * 0.82,
        size.width * 0.60,
        size.height * 0.64,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.48,
        size.width * 0.91,
        size.height * 0.35,
        size.width,
        size.height * 0.30,
      )
      ..lineTo(size.width, size.height * 0.53)
      ..cubicTo(
        size.width * 0.83,
        size.height * 0.60,
        size.width * 0.72,
        size.height * 0.83,
        size.width * 0.53,
        size.height * 0.91,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 1.02,
        size.width * 0.13,
        size.height * 0.83,
        0,
        size.height * 0.76,
      )
      ..close();

    // Teal ribbon: a second curved band crossing in front of the navy.
    final tealPath = Path()
      ..moveTo(0, size.height * 0.68)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.91,
        size.width * 0.39,
        size.height * 0.96,
        size.width * 0.59,
        size.height * 0.79,
      )
      ..cubicTo(
        size.width * 0.78,
        size.height * 0.63,
        size.width * 0.91,
        size.height * 0.48,
        size.width,
        size.height * 0.43,
      )
      ..lineTo(size.width, size.height * 0.67)
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.75,
        size.width * 0.71,
        size.height * 0.96,
        size.width * 0.52,
        size.height,
      )
      ..cubicTo(
        size.width * 0.31,
        size.height * 1.08,
        size.width * 0.13,
        size.height * 0.96,
        0,
        size.height * 0.90,
      )
      ..close();

    canvas.drawPath(navyPath, navyPaint);
    canvas.drawPath(tealPath, tealPaint);
  }

  @override
  bool shouldRepaint(covariant _WelcomeWavePainter oldDelegate) => false;
}
