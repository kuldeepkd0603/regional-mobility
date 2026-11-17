import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  // Update these paths if your asset filenames are different.
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo.png';
  static const String topSkylineAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const String bottomSkylineAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';

  static const Color navy = Color(0xFF10172F);
  static const Color cyan = Color(0xFF12D5D5);
  static const Color paleBlue = Color(0xFFE7F7FC);

  static const List<_PolicySection> sections = [
    _PolicySection(
      title: '1. Information We Collect',
      summary:
          'We collect basic personal details, contact information, ride and booking related data.',
      details:
          'This may include your name, phone number, email address, profile details, booking history, trip details and information you provide while using Raahi. We collect only the information needed to operate and improve the service.',
      icon: Icons.storage_rounded,
      iconColor: Color(0xFF12A33A),
      tileColor: Color(0xFFE8FBEA),
    ),
    _PolicySection(
      title: '2. Location Information',
      summary:
          'We use your device location to find nearby drivers, calculate fares and provide a better ride experience.',
      details:
          'With your permission, Raahi may access your location while you use location-based features, such as selecting a pickup point, finding nearby drivers and tracking a trip. You can manage location permission in your device settings. Some features may not work without it.',
      icon: Icons.location_on_outlined,
      iconColor: Color(0xFF0876D8),
      tileColor: Color(0xFFE4F8FC),
    ),
    _PolicySection(
      title: '3. How We Use Your Information',
      summary:
          'To provide and improve our services, process bookings and payments, ensure safety and customer support.',
      details:
          'We use information to create and manage your account, connect passengers and drivers, confirm and manage bookings, calculate fares, provide trip updates, respond to support requests, prevent misuse and improve the app.',
      icon: Icons.person_outline_rounded,
      iconColor: Color(0xFFF28A16),
      tileColor: Color(0xFFFFF0E1),
    ),
    _PolicySection(
      title: '4. Payment & Security',
      summary:
          'Your payments are processed through secure and trusted payment partners. We do not store your full card details.',
      details:
          'Payment information is handled by the payment provider selected for the transaction. Please review that provider’s terms and privacy policy. Raahi does not intend to store full card credentials in the app.',
      icon: Icons.credit_card_outlined,
      iconColor: Color(0xFF6724D8),
      tileColor: Color(0xFFF1EAFE),
    ),
    _PolicySection(
      title: '5. Data Sharing',
      summary:
          'We do not sell your personal data. We may share limited information with trusted partners (e.g., drivers, payment providers) only to provide the service.',
      details:
          'Relevant trip details may be shared with the assigned driver. Information may also be processed by service providers that support payments, hosting, notifications, maps and customer support. We share information only as needed for these purposes or when required by law.',
      icon: Icons.share_outlined,
      iconColor: Color(0xFF0876D8),
      tileColor: Color(0xFFE6F4FC),
    ),
    _PolicySection(
      title: '6. Data Security',
      summary:
          'We use industry-standard security measures to protect your data from unauthorized access, misuse or loss.',
      details:
          'We apply reasonable technical and organizational safeguards designed to protect information. No internet transmission or electronic storage method can be guaranteed to be completely secure.',
      icon: Icons.verified_user_outlined,
      iconColor: Color(0xFFE51F36),
      tileColor: Color(0xFFFFE9ED),
    ),
    _PolicySection(
      title: '7. Your Rights',
      summary:
          'You can view, update or delete your personal information, manage permissions and request account deletion.',
      details:
          'You can review and update available profile information in the app and manage device permissions through your phone settings. You may contact our support team to ask about access, correction or deletion of your information, subject to applicable legal requirements.',
      icon: Icons.manage_accounts_outlined,
      iconColor: Color(0xFF159A43),
      tileColor: Color(0xFFE5FBEF),
    ),
    _PolicySection(
      title: '8. Account Deletion',
      summary:
          'You can permanently delete your Raahi account and associated data from the app settings or by contacting our support team.',
      details:
          'To request account deletion, use the account deletion option in the app if available, or email support@raahi.in. We may retain limited information where required for legal, safety, dispute-resolution or record-keeping purposes.',
      icon: Icons.delete_outline_rounded,
      iconColor: Color(0xFF7915A5),
      tileColor: Color(0xFFF5E8FC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              _buildIntroCard(),
              const SizedBox(height: 10),
              ...sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _PolicyExpansionTile(section: section),
                ),
              ),
              const SizedBox(height: 3),
              _buildContactCard(),
              const SizedBox(height: 2),
              SizedBox(
                height: 82,
                width: double.infinity,
                child: Image.asset(
                  bottomSkylineAsset,
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 158,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 16,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back, size: 30, color: navy),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                Image.asset(
                  logoAsset,
                  height: 56,
                  width: 180,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const SizedBox(
                    height: 62,
                    child: Center(
                      child: Text(
                        'Raahi',
                        style: TextStyle(
                          color: Color(0xFF087D9D),
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Your privacy is important to us',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -2,
            bottom: 0,
            child: Image.asset(
              topSkylineAsset,
              width: 150,
              height: 42,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 1, color: const Color(0xFFE6F4F7)),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0786C7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const Expanded(
            child: Text(
              'At Raahi, we are committed to protecting your personal data and your right to privacy. This Privacy Policy explains how we collect, use, store and protect your information.',
              style: TextStyle(
                color: navy,
                fontSize: 13,
                height: 1.28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final uri = Uri(
          scheme: 'mailto',
          path: 'support@raahi.in',
          query: 'subject=Privacy Policy Enquiry',
        );
        await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: paleBlue,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: navy, size: 34),
            SizedBox(width: 14),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: navy,
                    fontSize: 14,
                    height: 1.35,
                  ),
                  children: [
                    TextSpan(
                      text:
                          'For any questions related to this Privacy Policy, you can contact us at\n',
                    ),
                    TextSpan(
                      text: 'support@raahi.in',
                      style: TextStyle(
                        color: Color(0xFF0755C8),
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w700,
                      ),
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

class _PolicySection {
  final String title;
  final String summary;
  final String details;
  final IconData icon;
  final Color iconColor;
  final Color tileColor;

  const _PolicySection({
    required this.title,
    required this.summary,
    required this.details,
    required this.icon,
    required this.iconColor,
    required this.tileColor,
  });
}

class _PolicyExpansionTile extends StatelessWidget {
  final _PolicySection section;

  const _PolicyExpansionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EC), width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
          visualDensity: const VisualDensity(vertical: -2),
          leading: SizedBox(
            width: 58,
            height: 58,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: section.tileColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                section.icon,
                color: section.iconColor,
                size: 32,
              ),
            ),
          ),
          title: Text(
            section.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF10172F),
              fontSize: 14.5,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              section.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF171B2A),
                fontSize: 11.5,
                height: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF111827),
            size: 25,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                section.details,
                style: const TextStyle(
                  color: Color(0xFF303849),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
