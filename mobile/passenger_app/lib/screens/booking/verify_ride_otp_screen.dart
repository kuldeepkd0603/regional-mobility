import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ride_in_progress_screen.dart';  
import '../../core/constants/app_colors.dart';
import 'live_tracking_screen.dart';

/// DEMO ONLY:
/// This screen uses a fixed OTP until the backend OTP API is implemented.
/// Remove the demo OTP and connect the real generate/verify endpoints later.
class VerifyRideOtpScreen extends StatefulWidget {
  final int bookingId;
  final Map<String, dynamic> booking;
  final Map<String, dynamic>? driver;

  const VerifyRideOtpScreen({
    super.key,
    required this.bookingId,
    required this.booking,
    this.driver,
  });

  @override
  State<VerifyRideOtpScreen> createState() => _VerifyRideOtpScreenState();
}

class _VerifyRideOtpScreenState extends State<VerifyRideOtpScreen> {
  static const String _demoOtp = '7429';

  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _isVerifying = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _value(dynamic value) {
    if (value == null) return 'N/A';
    final text = value.toString().trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return 'N/A';
    return text;
  }

  String _first(List<dynamic> values) {
    for (final value in values) {
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return 'N/A';
  }

  String get _driverName => _first([
        widget.driver?['driver_name'],
        widget.driver?['name'],
        widget.booking['driver_name'],
      ]);

  String get _vehicleName => _first([
        widget.driver?['vehicle_name'],
        widget.booking['vehicle_name'],
      ]);

  String get _vehicleType => _first([
        widget.driver?['vehicle_type'],
        widget.booking['preferred_vehicle_type'],
      ]);

  String get _vehicleNumber => _first([
        widget.driver?['vehicle_number'],
        widget.driver?['registration_number'],
        widget.booking['vehicle_number'],
      ]);

  String get _pickup => _first([
        widget.booking['pickup_address'],
        widget.booking['pickup_location'],
        widget.booking['pickup'],
      ]);

  String get _destination => _first([
        widget.booking['destination_address'],
        widget.booking['destination_location'],
        widget.booking['destination'],
      ]);

  String get _tripType => _value(widget.booking['trip_type']);

  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 30);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() => _secondsRemaining = 0);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  String get _enteredOtp =>
      _controllers.map((controller) => controller.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < 4; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      _focusNodes[digits.length.clamp(0, 3)].requestFocus();
    } else if (value.isNotEmpty && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() => _errorText = null);
  }

  Future<void> _copyOtp() async {
    await Clipboard.setData(const ClipboardData(text: _demoOtp));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo OTP copied: 7429')),
    );
  }

  void _resendOtp() {
    if (_secondsRemaining > 0) return;
    for (final controller in _controllers) {
      controller.clear();
    }
    _startCountdown();
    _focusNodes.first.requestFocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Demo OTP resent: 7429')),
    );
  }

  Future<void> _verifyAndStartRide() async {
    if (_enteredOtp.length != 4) {
      setState(() => _errorText = 'Please enter the 4-digit OTP.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = null;
    });

    // Simulate a verification request while the backend endpoint is pending.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    if (_enteredOtp != _demoOtp) {
      setState(() {
        _isVerifying = false;
        _errorText = 'Incorrect OTP. For demo, use 7429.';
      });
      return;
    }

    _countdownTimer?.cancel();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified. Demo ride started!')),
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTrackingScreen(bookingId: widget.bookingId),
      ),
    );
  }

  Widget _logo() {
    return Image.asset(
      'assets/images/raahi_assets/brand/raahi_logo.png',
      height: 54,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const Text(
        'Raahi',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 31,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _card({required Widget child, EdgeInsets padding = const EdgeInsets.all(14)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _otpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 55,
          height: 61,
          margin: EdgeInsets.only(right: index == 3 ? 0 : 9),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 4,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.secondary, width: 1.3),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onChanged: (value) => _onDigitChanged(index, value),
          ),
        );
      }),
    );
  }

  Widget _driverVehicleCard() {
    return _card(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 29,
            backgroundColor: Color(0xFFE5F6FA),
            child: Icon(Icons.person, color: AppColors.primary, size: 34),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
                const SizedBox(height: 5),
                const Text(
                  '★  N/A  (N/A rides)',
                  style: TextStyle(fontSize: 11, color: AppColors.textDark),
                ),
                const SizedBox(height: 5),
                const Text(
                  '✓  Verified: N/A',
                  style: TextStyle(fontSize: 10, color: AppColors.success),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 70, color: AppColors.border),
          const SizedBox(width: 9),
          const Icon(Icons.directions_car_filled, color: AppColors.primary, size: 38),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _vehicleName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  _vehicleNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard() {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _place(Icons.location_on, 'Pickup', _pickup, AppColors.success),
                const SizedBox(height: 14),
                _place(Icons.location_on, 'Destination', _destination, AppColors.error),
              ],
            ),
          ),
          Container(width: 1, height: 100, color: AppColors.border),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SmallMetric(icon: Icons.route, value: 'N/A'),
                const SizedBox(height: 14),
                const _SmallMetric(icon: Icons.access_time, value: 'N/A'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.mintBackground,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _tripType == 'N/A' ? 'Trip: N/A' : _tripType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _place(IconData icon, String title, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _footerDecoration() {
    return SizedBox(
      height: 58,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 34,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB9F0F0), Color(0xFF54C9D2)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(70)),
            ),
          ),
          const Positioned(
            bottom: 7,
            left: 0,
            right: 0,
            child: Icon(Icons.temple_hindu, color: Color(0xFF42BFD0), size: 37),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                        ),
                        Expanded(child: Center(child: _logo())),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Verify Ride OTP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Share this 4-digit OTP with your driver to start the ride',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE7F8F2),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Your Ride OTP',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _otpBoxes(),
                              const SizedBox(width: 14),
                              InkWell(
                                onTap: _copyOtp,
                                borderRadius: BorderRadius.circular(12),
                                child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Column(
                                    children: [
                                      Icon(Icons.copy, color: AppColors.success, size: 27),
                                      SizedBox(height: 4),
                                      Text(
                                        'Copy',
                                        style: TextStyle(
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'DEMO OTP: 7429',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: const TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.infoBackground,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                          SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Tell this OTP to your driver to verify and start the trip.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _driverVehicleCard(),
                    const SizedBox(height: 10),
                    _routeCard(),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 53,
                      child: ElevatedButton.icon(
                        onPressed: _isVerifying ? null : _verifyAndStartRide,
                        icon: _isVerifying
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline, size: 25),
                        label: Text(
                          _isVerifying ? 'Verifying...' : 'Verify & Start Ride  →',
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _card(
                      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Didn’t get OTP?',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _secondsRemaining == 0 ? _resendOtp : null,
                            icon: const Icon(Icons.refresh, size: 21),
                            label: Text(
                              _secondsRemaining == 0
                                  ? 'Resend OTP'
                                  : 'Resend OTP (00:${_secondsRemaining.toString().padLeft(2, '0')})',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Support contact is not configured yet.')),
                      ),
                      icon: const Icon(Icons.headset_mic_outlined, color: AppColors.success),
                      label: const Text(
                        'Need Help?  Contact Support  ›',
                        style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _footerDecoration(),
                    const SizedBox(height: 4),
                    const Text(
                      'Demo mode: OTP verification is local only.',
                      style: TextStyle(fontSize: 10, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallMetric extends StatelessWidget {
  final IconData icon;
  final String value;

  const _SmallMetric({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textDark),
        const SizedBox(width: 7),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
