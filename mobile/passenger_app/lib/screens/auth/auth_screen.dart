import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';
import '../../core/services/push_notification_service.dart';
import '../home/home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Color navy = Color(0xFF073B5C);
  static const Color teal = Color(0xFF08B69D);

  // Change these paths only if your asset filenames are different.
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo_vertical.png';
  static const String skylineAsset =
      'assets/images/raahi_assets/header/city_skyline55.png';
  static const String carAsset =
      'assets/images/raahi_assets/header/White_Suzuki_Dzire.png';

  bool isLogin = true;
  bool isLoading = false;
  bool hidePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (isLogin) {
        await ApiService.login(
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await ApiService.register(
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
        );
      }

      await PushNotificationService.initialize();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void toggleMode() {
    setState(() {
      isLogin = !isLogin;
      errorMessage = null;
      _passwordController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final h = constraints.maxHeight;
            final w = constraints.maxWidth;
            final scale = (h / 850).clamp(0.78, 1.12);
            final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Bottom decorative scene: kept separate from the form.
                if (!keyboardOpen) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    // Skyline sits in the lower artwork zone, above the waves.
                    bottom: h * 0.205,
                    height: h * 0.225,
                    child: IgnorePointer(
                      child: Image.asset(
                        skylineAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  // Navy/teal curved background is only at the very bottom.
                  Positioned(
                    left: 0,
                    right: 0,
                    // Wave ribbons stop above the benefit row; the bottom stays white.
                    bottom: h * 0.12,
                    height: h * 0.14,
                    child: const IgnorePointer(
                      child: CustomPaint(painter: _AuthBottomWavePainter()),
                    ),
                  ),
                  // Car sits in front of the temple and behind the benefits.
                  Positioned(
                    right: w * 0.075,
                    // Car overlaps the lower skyline and rests visually on the wave.
                    bottom: h * 0.185,
                    width: w * 0.48,
                    height: h * 0.13,
                    child: IgnorePointer(
                      child: Image.asset(
                        carAsset,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  // Benefits are a distinct row below the car, not over it.
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: h * 0.018,
                    height: h * 0.095,
                    child: const Align(
                      alignment: Alignment.center,
                      child: _BenefitsRow(),
                    ),
                  ),
                ],

                // Form occupies the upper area. It can scroll on small screens
                // and when the keyboard is visible; it never scrolls over the
                // bottom artwork because it has its own bounded height.
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: keyboardOpen ? h : h * 0.79,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      4 * scale,
                      24,
                      14 * scale,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 38 * scale,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.maybePop(context),
                                icon: const Icon(
                                  Icons.arrow_back,
                                  size: 30,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8 * scale),

                          SizedBox(
                            height: 132 * scale,
                            child: Image.asset(
                              logoAsset,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(height: 18 * scale),

                          Text(
                            isLogin ? 'Login or Sign Up' : 'Create Account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28 * scale,
                              height: 1.12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF101820),
                            ),
                          ),
                          SizedBox(height: 8 * scale),
                          Text(
                            isLogin
                                ? 'Enter your mobile number to continue'
                                : 'Enter your details to create your account',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17 * scale,
                              color: const Color(0xFF252525),
                            ),
                          ),
                          SizedBox(height: 24 * scale),

                          if (!isLogin) ...[
                            _buildNameField(scale),
                            SizedBox(height: 12 * scale),
                          ],
                          _buildPhoneField(scale),
                          SizedBox(height: 14 * scale),
                          _buildPasswordField(scale),

                          if (errorMessage != null) ...[
                            SizedBox(height: 8 * scale),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12 * scale,
                              ),
                            ),
                          ],

                          SizedBox(height: 20 * scale),
                          SizedBox(
                            height: 58 * scale,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: navy,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: navy.withOpacity(0.7),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(22 * scale),
                                ),
                              ),
                              child: isLoading
                                  ? SizedBox(
                                      height: 22 * scale,
                                      width: 22 * scale,
                                      child: const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          isLogin
                                              ? 'Continue'
                                              : 'Create Account',
                                          style: TextStyle(
                                            fontSize: 19 * scale,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 14 * scale),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 27 * scale,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          SizedBox(height: 20 * scale),
                          Center(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              children: [
                                Text(
                                  isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                  style: TextStyle(
                                    fontSize: 15 * scale,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: isLoading ? null : toggleMode,
                                  child: Text(
                                    isLogin ? 'Register' : 'Login',
                                    style: TextStyle(
                                      fontSize: 15 * scale,
                                      color: teal,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _buildNameField(double scale) {
    return SizedBox(
      height: 62 * scale,
      child: TextFormField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        decoration: _decoration(
          hint: 'Enter your full name',
          scale: scale,
          prefix: Icon(Icons.person_outline, size: 22 * scale),
        ),
        validator: (value) {
          if (!isLogin && (value == null || value.trim().isEmpty)) {
            return 'Please enter your full name';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPhoneField(double scale) {
    return SizedBox(
      height: 62 * scale,
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        decoration: _decoration(
          hint: 'Enter mobile number',
          scale: scale,
          prefix: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🇮🇳', style: TextStyle(fontSize: 22 * scale)),
              SizedBox(width: 8 * scale),
              Text(
                '+91',
                style: TextStyle(
                  fontSize: 18 * scale,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 5 * scale),
              Icon(Icons.keyboard_arrow_down, size: 23 * scale),
              SizedBox(width: 7 * scale),
              SizedBox(
                height: 30 * scale,
                child: const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFBFC5CC),
                ),
              ),
              SizedBox(width: 9 * scale),
            ],
          ),
        ).copyWith(counterText: ''),
        validator: (value) {
          if (value == null ||
              !RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
            return 'Enter a valid 10-digit mobile number';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField(double scale) {
    return SizedBox(
      height: 62 * scale,
      child: TextFormField(
        controller: _passwordController,
        obscureText: hidePassword,
        decoration: _decoration(
          hint: 'Enter password',
          scale: scale,
          prefix: Icon(Icons.lock_outline, size: 22 * scale),
        ).copyWith(
          suffixIcon: IconButton(
            onPressed: () => setState(() => hidePassword = !hidePassword),
            icon: Icon(
              hidePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey,
              size: 23 * scale,
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.length < 8) {
            return 'Password must be at least 8 characters';
          }
          return null;
        },
      ),
    );
  }

  InputDecoration _decoration({
    required String hint,
    required double scale,
    Widget? prefix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: const Color(0xFF858585),
        fontSize: 16 * scale,
      ),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 0,
        minHeight: 0,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: 14 * scale,
        vertical: 16 * scale,
      ),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22 * scale),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22 * scale),
        borderSide: const BorderSide(
          color: Color(0xFFD1D5DB),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(22 * scale),
        borderSide: const BorderSide(color: Color(0xFF08B69D), width: 1.8),
      ),
      errorStyle: TextStyle(fontSize: 10 * scale),
    );
  }
}

class _BenefitsRow extends StatelessWidget {
  const _BenefitsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Benefit(
            icon: Icons.verified_user_outlined,
            label: 'Safe & Reliable',
          ),
        ),
        _BenefitDivider(),
        Expanded(
          child: _Benefit(
            icon: Icons.currency_rupee_rounded,
            label: 'Transparent\nFares',
          ),
        ),
        _BenefitDivider(),
        Expanded(
          child: _Benefit(
            icon: Icons.headset_mic_outlined,
            label: '24×7 Support',
          ),
        ),
      ],
    );
  }
}

class _Benefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Benefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: const Color(0xFF075B4F), size: 31),
        const SizedBox(height: 5),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            height: 1.12,
            color: Color(0xFF17212B),
          ),
        ),
      ],
    );
  }
}

class _BenefitDivider extends StatelessWidget {
  const _BenefitDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: const Color(0xFFBFC5CC),
    );
  }
}

class _AuthBottomWavePainter extends CustomPainter {
  const _AuthBottomWavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Upper navy ribbon. It is a curved band, not a filled rectangle.
    final navyPath = Path()
      ..moveTo(0, size.height * 0.20)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.78,
        size.width,
        size.height * 0.16,
      )
      ..lineTo(size.width, size.height * 0.40)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.98,
        0,
        size.height * 0.45,
      )
      ..close();

    // Teal ribbon follows underneath the navy curve.
    final tealPath = Path()
      ..moveTo(0, size.height * 0.46)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 1.00,
        size.width,
        size.height * 0.42,
      )
      ..lineTo(size.width, size.height * 0.67)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 1.20,
        0,
        size.height * 0.72,
      )
      ..close();

    canvas.drawPath(navyPath, Paint()..color = const Color(0xFF073B5C));
    canvas.drawPath(tealPath, Paint()..color = const Color(0xFF08B69D));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
