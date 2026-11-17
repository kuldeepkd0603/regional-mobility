import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo.png';
  static const String topSkylineAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const String bottomSkylineAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';

  static const Color navy = Color(0xFF10172F);
  static const Color paleBlue = Color(0xFFE7F7FC);

  static const List<_TermsSection> sections = [
    _TermsSection(
      title: '1. Use of the App',
      summary: 'You must be at least 18 years old and provide accurate details to create and use your Raahi account.',
      details: 'You are responsible for maintaining accurate account information and keeping your login credentials secure. Use the app only for lawful purposes and in accordance with these Terms & Conditions.',
      icon: Icons.person_outline_rounded,
      iconColor: Color(0xFF159A43),
      tileColor: Color(0xFFE5FBEF),
    ),
    _TermsSection(
      title: '2. Booking Rules',
      summary: 'Book local rides, intercity trips or tour packages with correct pickup, drop and passenger details.',
      details: 'Review your pickup location, destination, travel date, passenger count and selected vehicle before confirming a booking. Booking requests are subject to driver and vehicle availability. Keep your phone reachable for trip-related communication.',
      icon: Icons.calendar_month_outlined,
      iconColor: Color(0xFF0876D8),
      tileColor: Color(0xFFE6F4FC),
    ),
    _TermsSection(
      title: '3. Fares & Charges',
      summary: 'Fares are calculated based on distance, time, vehicle type, tolls and other applicable charges.',
      details: 'The fare shown in the app is an estimate or quote based on the trip details and applicable pricing. Additional charges may apply where disclosed, including tolls, parking, waiting time or route changes. Review the fare details before confirming.',
      icon: Icons.currency_rupee_rounded,
      iconColor: Color(0xFFE98219),
      tileColor: Color(0xFFFFF0E1),
    ),
    _TermsSection(
      title: '4. Cancellations & Refunds',
      summary: 'You can cancel a booking as per the cancellation policy. Eligible refunds (if any) will be credited to your wallet or source.',
      details: 'Cancellation charges, refund eligibility and processing time depend on the booking type and the cancellation policy shown for that booking. Contact support with your booking details if you need help.',
      icon: Icons.event_busy_outlined,
      iconColor: Color(0xFFE32636),
      tileColor: Color(0xFFFFE9ED),
    ),
    _TermsSection(
      title: '5. Payments',
      summary: 'Pay securely via UPI, cards, net banking or Raahi Wallet. All transactions are processed through trusted partners.',
      details: 'Available payment methods may vary. You must use a valid payment method that you are authorized to use. Payment processing may be subject to the terms of the relevant payment provider.',
      icon: Icons.credit_card_outlined,
      iconColor: Color(0xFF6724D8),
      tileColor: Color(0xFFF1EAFE),
    ),
    _TermsSection(
      title: '6. Driver Responsibilities',
      summary: 'Drivers must be verified, follow safety rules, maintain vehicle standards and provide a courteous service.',
      details: 'Drivers using the platform are expected to maintain valid licences and vehicle documents, follow applicable traffic laws, keep their vehicles roadworthy and treat passengers respectfully. Driver onboarding and verification are subject to Raahi processes.',
      icon: Icons.airline_seat_recline_normal,
      iconColor: Color(0xFF0876D8),
      tileColor: Color(0xFFE6F4FC),
    ),
    _TermsSection(
      title: '7. Prohibited Activities',
      summary: 'Do not misuse the app, book with false details, engage in unlawful activities or behave inappropriately with drivers.',
      details: 'You must not interfere with app operations, submit misleading information, misuse another person’s account, harass users, attempt fraud or use Raahi for any unlawful purpose. We may restrict access where misuse is identified.',
      icon: Icons.block_outlined,
      iconColor: Color(0xFFE32636),
      tileColor: Color(0xFFFFE9ED),
    ),
    _TermsSection(
      title: '8. Safety & Conduct',
      summary: 'Maintain respectful behaviour, follow app safety guidelines and use the in-app emergency features when needed.',
      details: 'Share accurate trip information, follow reasonable safety instructions and report safety concerns through available support channels. Passengers and drivers should behave respectfully throughout the trip.',
      icon: Icons.verified_user_outlined,
      iconColor: Color(0xFF159A43),
      tileColor: Color(0xFFE5FBEF),
    ),
    _TermsSection(
      title: '9. Dispute Resolution',
      summary: 'In case of any dispute, please contact our support team. We will try to resolve the issue fairly and in a timely manner.',
      details: 'For booking, payment or service-related concerns, contact support@raahi.in and include relevant booking details. We will review the concern and communicate the next steps. Applicable laws and jurisdiction will govern unresolved disputes.',
      icon: Icons.balance_outlined,
      iconColor: Color(0xFF6724D8),
      tileColor: Color(0xFFF1EAFE),
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
              _header(context),
              const SizedBox(height: 8),
              _introCard(),
              const SizedBox(height: 10),
              ...sections.map(
                (section) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _TermsExpansionTile(section: section),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: paleBlue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: navy, size: 23),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'These Terms & Conditions may be updated from time to time. Continued use of the app means you accept the latest version.',
                        style: TextStyle(
                          color: navy,
                          fontSize: 11.5,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _header(BuildContext context) {
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
                  'Terms & Conditions',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 25,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                const Text(
                  'Please read our terms carefully',
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

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
      decoration: BoxDecoration(
        color: paleBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 66,
            height: 66,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF087D9D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fact_check_outlined,
              color: Colors.white,
              size: 43,
            ),
          ),
          const Expanded(
            child: Text(
              'By using the Raahi app, you agree to the following Terms & Conditions. These terms govern your use of our ride, outstation and tour services.',
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
}

class _TermsSection {
  final String title;
  final String summary;
  final String details;
  final IconData icon;
  final Color iconColor;
  final Color tileColor;

  const _TermsSection({
    required this.title,
    required this.summary,
    required this.details,
    required this.icon,
    required this.iconColor,
    required this.tileColor,
  });
}

class _TermsExpansionTile extends StatelessWidget {
  final _TermsSection section;

  const _TermsExpansionTile({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EC), width: 1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 1),
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
                size: 31,
              ),
            ),
          ),
          title: Text(
            section.title,
            maxLines: 1,
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
              maxLines: 2,
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
