
import 'package:flutter/material.dart';

import 'support_category_screen.dart';
import 'faq_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const Color navy = Color(0xFF064B68);
  static const Color green = Color(0xFF159B55);
  static const Color textColor = Color(0xFF101B2D);
  static const Color borderColor = Color(0xFFE4E8EC);

  String searchQuery = '';

  final List<Map<String, dynamic>> categories = [
    {
      'title': 'Frequently Asked Questions (FAQs)',
      'subtitle': 'Find answers to common questions',
      'icon': Icons.list_alt_rounded,
      'color': Color(0xFF1766D2),
      'background': Color(0xFFE5F4FC),
    },
    {
      'title': 'Ride & Booking Issues',
      'subtitle': 'Help with booking, cancellation, fare and more',
      'icon': Icons.directions_car_outlined,
      'color': Color(0xFFF07818),
      'background': Color(0xFFFFF0DF),
    },
    {
      'title': 'Payment & Refunds',
      'subtitle': 'Wallet, payments, refunds and invoices',
      'icon': Icons.account_balance_wallet_outlined,
      'color': Color(0xFF159B55),
      'background': Color(0xFFE2F9EC),
    },
    {
      'title': 'Account & Profile',
      'subtitle': 'Update profile, mobile number, or account issues',
      'icon': Icons.person_outline_rounded,
      'color': Color(0xFF5925C5),
      'background': Color(0xFFF0E8FF),
    },
    {
      'title': 'Safety & Reporting',
      'subtitle': 'Report an issue, driver behavior or safety concern',
      'icon': Icons.verified_user_outlined,
      'color': Color(0xFF1766D2),
      'background': Color(0xFFE5F4FC),
    },
  ];

  List<Map<String, dynamic>> get filteredCategories {
    if (searchQuery.trim().isEmpty) return categories;

    return categories.where((item) {
      final title = item['title'].toString().toLowerCase();
      final subtitle = item['subtitle'].toString().toLowerCase();
      final query = searchQuery.toLowerCase();

      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void openCategory(Map<String, dynamic> item) {
    // Open the dedicated FAQ screen when the FAQ category is tapped.
    if (item['title'] == 'Frequently Asked Questions (FAQs)') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const FaqScreen(),
        ),
      );
      return;
    }

    // Keep the existing navigation for all other help categories.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportCategoryScreen(
          title: item['title'],
          subtitle: item['subtitle'],
          icon: item['icon'],
          color: item['color'],
          backgroundColor: item['background'],
        ),
      ),
    );
  }

  void showComingSoon(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SupportCategoryScreen(
          title: title,
          subtitle: 'Our support service is being prepared.',
          icon: Icons.support_agent_rounded,
          color: navy,
          backgroundColor: const Color(0xFFE5F4FC),
        ),
      ),
    );
  }

  Widget header() {
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: textColor,
                  size: 28,
                ),
              ),
              const Spacer(),
              Image.asset(
                'assets/images/raahi_assets/brand/raahi_logo.png',
                height: 58,
                width: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Help & Support',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'We are here to help you 24×7',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: textColor,
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: Image.asset(
            'assets/images/raahi_assets/header/city_skyline5.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget searchBar() {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => searchQuery = value);
        },
        style: const TextStyle(fontSize: 14, color: textColor),
        decoration: InputDecoration(
          hintText: 'Search for help, issues or FAQs',
          hintStyle: const TextStyle(
            color: textColor,
            fontSize: 14,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: textColor,
            size: 25,
          ),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() => searchQuery = '');
                  },
                  icon: const Icon(Icons.close),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget quickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 3,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(17),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 34),
              const SizedBox(height: 9),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget categoryTile(Map<String, dynamic> item, {bool last = false}) {
    return InkWell(
      onTap: () => openCategory(item),
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: last
                ? BorderSide.none
                : const BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            Container(
              height: 54,
              width: 58,
              decoration: BoxDecoration(
                color: item['background'],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item['icon'],
                color: item['color'],
                size: 31,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['subtitle'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right,
              color: textColor,
              size: 27,
            ),
          ],
        ),
      ),
    );
  }

  Widget contactBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F4FC),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.headset_mic_outlined,
            color: navy,
            size: 42,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still Need Help?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Send us your query and our support team will get back to you shortly.',
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => showComingSoon('Contact Support'),
            style: ElevatedButton.styleFrom(
              backgroundColor: navy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
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
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 5, 16, 14),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 19,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header(),
                    const SizedBox(height: 9),
                    searchBar(),
                    const SizedBox(height: 17),

                    Row(
                      children: [
                        quickAction(
                          icon: Icons.call_outlined,
                          title: 'Call\nSupport',
                          color: const Color(0xFF159B55),
                          onTap: () => showComingSoon('Call Support'),
                        ),
                        const SizedBox(width: 8),
                        quickAction(
                          icon: Icons.chat_outlined,
                          title: 'WhatsApp\nSupport',
                          color: const Color(0xFF0CB85A),
                          onTap: () => showComingSoon('WhatsApp Support'),
                        ),
                        const SizedBox(width: 8),
                        quickAction(
                          icon: Icons.confirmation_number_outlined,
                          title: 'Raise a\nComplaint',
                          color: const Color(0xFF5925C5),
                          onTap: () => showComingSoon('Raise a Complaint'),
                        ),
                        const SizedBox(width: 8),
                        quickAction(
                          icon: Icons.shield_outlined,
                          title: 'Report\na Driver',
                          color: const Color(0xFFE31B23),
                          onTap: () => showComingSoon('Report a Driver'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        'Quick Help',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                        ),
                      ),
                    ),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: filteredCategories.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(22),
                              child: Center(
                                child: Text(
                                  'No matching help topics found.',
                                  style: TextStyle(color: textColor),
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0;
                                    i < filteredCategories.length;
                                    i++)
                                  categoryTile(
                                    filteredCategories[i],
                                    last: i == filteredCategories.length - 1,
                                  ),
                              ],
                            ),
                    ),

                    const SizedBox(height: 17),
                    contactBanner(),
                    const SizedBox(height: 18),

                    SizedBox(
                      height: 76,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/raahi_assets/header/city_skyline5.png',
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
