
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../support/privacy_policy_screen.dart';
import '../support/terms_conditions_screen.dart';
class AboutRaahiScreen extends StatelessWidget {
  const AboutRaahiScreen({super.key});

  static const navy = Color(0xFF102C46);
  static const teal = Color(0xFF087D91);
  static const green = Color(0xFF159B55);
  static const blue = Color(0xFF1764C0);
  static const border = Color(0xFFE1E7EB);
  static const paleBlue = Color(0xFFE7F6FA);
  static const paleGreen = Color(0xFFE7F8EF);

  static const website = 'https://www.raahi.in';
  static const phone = '9302877673';
  static const email = 'support@raahi.in';

  Future<void> _openLink(
    BuildContext context,
    String value, {
    LaunchMode mode = LaunchMode.externalApplication,
  }) async {
    final uri = Uri.tryParse(value);

    if (uri == null || !await canLaunchUrl(uri)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open this link.')),
        );
      }
      return;
    }

    await launchUrl(uri, mode: mode);
  }

  Future<void> _call(BuildContext context) async {
    await _openLink(context, 'tel:$phone');
  }

  Future<void> _whatsapp(BuildContext context) async {
    await _openLink(context, 'https://wa.me/91$phone');
  }

  Future<void> _email(BuildContext context) async {
    await _openLink(context, 'mailto:$email');
  }

  Future<void> _website(BuildContext context) async {
    await _openLink(context, website);
  }

  void _notConfigured(BuildContext context, String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$item link is not configured yet.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 10),
                    _brandDescription(),
                    const SizedBox(height: 12),
                    _missionCard(),
                    const SizedBox(height: 14),
                    _sectionTitle('App Information'),
                    const SizedBox(height: 7),
                    _appInformation(context),
                    const SizedBox(height: 14),
                    _sectionTitle('Contact Us'),
                    const SizedBox(height: 7),
                    _contactCard(context),
                    const SizedBox(height: 13),
                    _sectionTitle('Follow Us'),
                    const SizedBox(height: 8),
                    _socialRow(context),
                    const SizedBox(height: 14),
                    _policyButtons(context),
                    const SizedBox(height: 14),
                    _footer(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 45,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back,
                    color: navy,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              Image.asset(
                'assets/images/raahi_assets/brand/raahi_logo.png',
                width: 170,
                height: 44,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 29,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'About Raahi',
          style: TextStyle(
            color: navy,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Your City. Your Ride. Your Way.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: navy,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: 28,
          width: double.infinity,
          child: Image.asset(
            'assets/images/raahi_assets/header/city_skyline54.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _brandDescription() {
    return SizedBox(
      height: 105,
      child: Row(
        children: [
          Container(
            height: 94,
            width: 94,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1FBFC),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: border),
            ),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car,
                color: teal,
                size: 48,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 90, color: border),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raahi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: navy,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Raahi is a regional mobility platform for Ujjain, Indore and Dewas, offering reliable local rides, intercity travel and religious tour services.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _missionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -2,
            bottom: -2,
            child: Image.asset(
              'assets/images/raahi_assets/header/city_skyline52.png',
              width: 112,
              height: 94,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.track_changes, color: navy, size: 23),
                  SizedBox(width: 8),
                  Text(
                    'Our Mission',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              const Padding(
                padding: EdgeInsets.only(right: 58),
                child: Text(
                  'To make travel in Ujjain, Indore and Dewas more convenient, safe and affordable, especially for local, outstation and pilgrimage journeys.',
                  style: TextStyle(
                    color: navy,
                    fontSize: 11.5,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: navy,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _appInformation(BuildContext context) {
    return _groupCard([
      _informationRow(
        Icons.phone_android,
        const Color(0xFFE6F3FF),
        Colors.blue,
        'App Version',
        'v1.0.0',
      ),
      _informationRow(
        Icons.language,
        const Color(0xFFF0E9FF),
        Colors.deepPurple,
        'Official Website',
        'www.raahi.in',
        trailingIcon: Icons.open_in_new,
        onTap: () => _website(context),
        valueColor: blue,
      ),
      _informationRow(
        Icons.calendar_month,
        paleGreen,
        green,
        'Last Updated',
        'N/A',
        showDivider: false,
      ),
    ]);
  }

  Widget _contactCard(BuildContext context) {
    return _groupCard([
      _informationRow(
        Icons.call_outlined,
        paleGreen,
        green,
        'Customer Support',
        '+91 $phone',
        trailingIcon: Icons.call_outlined,
        onTap: () => _call(context),
        valueColor: blue,
      ),
      _informationRow(
        Icons.chat,
        paleGreen,
        green,
        'WhatsApp Support',
        '+91 $phone',
        trailingIcon: Icons.chat,
        onTap: () => _whatsapp(context),
        valueColor: blue,
      ),
      _informationRow(
        Icons.mail_outline,
        const Color(0xFFFFF1E4),
        Colors.deepOrange,
        'Email',
        email,
        trailingIcon: Icons.mail_outline,
        onTap: () => _email(context),
        valueColor: blue,
        showDivider: false,
      ),
    ]);
  }

  Widget _groupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(children: children),
    );
  }

  Widget _informationRow(
    IconData icon,
    Color tileColor,
    Color iconColor,
    String title,
    String value, {
    IconData? trailingIcon,
    VoidCallback? onTap,
    Color valueColor = navy,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 48,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(icon, color: iconColor, size: 21),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 11,
                          color: valueColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 5),
                      Icon(
                        trailingIcon,
                        size: 17,
                        color: valueColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (showDivider)
              const Divider(
                height: 1,
                thickness: 0.7,
                color: border,
              ),
          ],
        ),
      ),
    );
  }

  Widget _socialRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(
          Icons.camera_alt_outlined,
          const Color(0xFFE1306C),
          'Instagram',
          context,
        ),
        _socialButton(
          Icons.play_arrow_rounded,
          Colors.red,
          'YouTube',
          context,
        ),
        _socialButton(
          Icons.facebook,
          const Color(0xFF1877F2),
          'Facebook',
          context,
        ),
        _socialButton(
          Icons.business,
          const Color(0xFF0A66C2),
          'LinkedIn',
          context,
        ),
      ],
    );
  }

  Widget _socialButton(
    IconData icon,
    Color color,
    String name,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 11),
      child: InkWell(
        onTap: () => _notConfigured(context, name),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F4F8),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 29),
        ),
      ),
    );
  }

  Widget _policyButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _policyButton(
            Icons.description_outlined,
            'Terms & Conditions',
            () {
            Navigator.push(
                context,
                MaterialPageRoute(
                builder: (_) => const TermsConditionsScreen(),
                ),
            );
            }
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _policyButton(
            Icons.verified_user_outlined,
            'Privacy Policy',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _policyButton(
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 13),
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.chevron_right, size: 19),
        ],
      ),
    );
  }

  Widget _footer() {
    return SizedBox(
      width: double.infinity,
      height: 49,
      child: Image.asset(
        'assets/images/raahi_assets/header/city_skyline53.png',
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}
