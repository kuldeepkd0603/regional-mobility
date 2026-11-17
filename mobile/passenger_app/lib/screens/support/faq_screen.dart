import 'package:flutter/material.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  static const Color navy = Color(0xFF075675);
  static const Color ink = Color(0xFF151B2B);
  static const Color muted = Color(0xFF64717D);
  static const Color border = Color(0xFFE2E7EB);
  static const Color page = Color(0xFFFAFBFC);

  // Update these paths to match the exact locations in your assets folder.
  static const String logoAsset =
      'assets/images/raahi_assets/brand/raahi_logo.png';
  static const String topSkylineAsset =
      'assets/images/raahi_assets/header/city_skyline54.png';
  static const String bottomSkycityAsset =
      'assets/images/raahi_assets/header/city_skyline53.png';

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Booking';
  String? _expandedQuestionId;

  final List<FaqCategory> _categories = const [
    FaqCategory(
      title: 'Booking',
      icon: Icons.directions_car_outlined,
      color: Color(0xFF087F98),
      background: Color(0xFFE5F6FA),
    ),
    FaqCategory(
      title: 'Fares & Charges',
      shortTitle: 'Fares &\nCharges',
      icon: Icons.toll_outlined,
      color: Color(0xFFF28A18),
      background: Color(0xFFFFF1E3),
    ),
    FaqCategory(
      title: 'Payments & Refunds',
      shortTitle: 'Payments\n& Refunds',
      icon: Icons.account_balance_wallet_outlined,
      color: Color(0xFF159B37),
      background: Color(0xFFE4F9ED),
    ),
    FaqCategory(
      title: 'Cancellations',
      icon: Icons.event_busy_outlined,
      color: Color(0xFFE32935),
      background: Color(0xFFFFE9EA),
    ),
    FaqCategory(
      title: 'Drivers & Vehicles',
      shortTitle: 'Drivers &\nVehicles',
      icon: Icons.support_agent_outlined,
      color: Color(0xFF7135C6),
      background: Color(0xFFF1E8FF),
    ),
    FaqCategory(
      title: 'Safety & Security',
      shortTitle: 'Safety &\nSecurity',
      icon: Icons.verified_user_outlined,
      color: Color(0xFF175BE5),
      background: Color(0xFFE8F1FF),
    ),
  ];

  late final List<FaqItem> _faqs = [
    const FaqItem(
      id: 'booking_1',
      category: 'Booking',
      question: 'How do I book a ride on Raahi?',
      answer:
          'Open the Raahi app, select your ride type (Local, Intercity or Religious Tour), choose pickup and drop location, select a vehicle, check the fare and tap “Book Ride”.',
    ),
    const FaqItem(
      id: 'booking_2',
      category: 'Booking',
      question: 'Can I schedule a ride for a later time?',
      answer:
          'Yes. Choose the scheduled ride option, select your pickup date and time, enter your trip details and confirm your booking.',
    ),
    const FaqItem(
      id: 'booking_3',
      category: 'Booking',
      question: 'What vehicle options are available?',
      answer:
          'Available vehicle options may include hatchbacks, sedans and larger family vehicles. The options shown depend on your route and driver availability.',
    ),
    const FaqItem(
      id: 'booking_4',
      category: 'Booking',
      question: 'Can I book a round trip or tour package?',
      answer:
          'Yes. Select Round Trip or Religious Tour, enter your journey details and review the estimated fare before confirming.',
    ),
    const FaqItem(
      id: 'fare_1',
      category: 'Fares & Charges',
      question: 'How is my ride fare calculated?',
      answer:
          'Your estimated fare is calculated using the selected trip type, route distance, vehicle category and applicable trip charges. Review the estimate before booking.',
    ),
    const FaqItem(
      id: 'fare_2',
      category: 'Fares & Charges',
      question: 'Are tolls, parking or state taxes included?',
      answer:
          'Any applicable toll, parking or state charges will be shown in the fare details or trip terms. Check the fare breakdown before confirming your ride.',
    ),
    const FaqItem(
      id: 'fare_3',
      category: 'Fares & Charges',
      question: 'Can the final fare change?',
      answer:
          'The final amount may change if your trip details, route or applicable extra charges change. Check the trip summary and fare breakdown.',
    ),
    const FaqItem(
      id: 'payment_1',
      category: 'Payments & Refunds',
      question: 'Which payment methods can I use?',
      answer:
          'The payment methods currently enabled for your booking will be displayed in the app at checkout.',
    ),
    const FaqItem(
      id: 'payment_2',
      category: 'Payments & Refunds',
      question: 'Where can I see my payment receipt?',
      answer:
          'Open your completed booking or trip history in the app to check the available payment details and receipt.',
    ),
    const FaqItem(
      id: 'payment_3',
      category: 'Payments & Refunds',
      question: 'When will I receive my refund?',
      answer:
          'Refund eligibility and processing time depend on the payment method and cancellation status. Check the refund update in your booking or contact support.',
    ),
    const FaqItem(
      id: 'cancel_1',
      category: 'Cancellations',
      question: 'How do I cancel my ride?',
      answer:
          'Open My Bookings, select the active booking and choose Cancel Ride. Review any cancellation details shown before confirming.',
    ),
    const FaqItem(
      id: 'cancel_2',
      category: 'Cancellations',
      question: 'Will I be charged a cancellation fee?',
      answer:
          'A cancellation charge may apply depending on the booking status and the applicable cancellation terms. Review the details shown in the app.',
    ),
    const FaqItem(
      id: 'cancel_3',
      category: 'Cancellations',
      question: 'Can I change my pickup or destination after booking?',
      answer:
          'Changes depend on the booking status and available app options. Contact support if the app does not allow you to update your trip.',
    ),
    const FaqItem(
      id: 'driver_1',
      category: 'Drivers & Vehicles',
      question: 'How can I contact my assigned driver?',
      answer:
          'Once a driver is assigned, open your booking details to view the contact options available for that trip.',
    ),
    const FaqItem(
      id: 'driver_2',
      category: 'Drivers & Vehicles',
      question: 'How do I identify my booked vehicle?',
      answer:
          'Your booking details show the available driver and vehicle information once the ride is assigned.',
    ),
    const FaqItem(
      id: 'driver_3',
      category: 'Drivers & Vehicles',
      question: 'What if my driver is delayed?',
      answer:
          'Check the live booking status and contact your assigned driver if a call option is available. You can also reach Raahi support.',
    ),
    const FaqItem(
      id: 'safety_1',
      category: 'Safety & Security',
      question: 'What should I do in an emergency?',
      answer:
          'Move to a safe place if possible and contact local emergency services when necessary. You can also contact Raahi support through the app.',
    ),
    const FaqItem(
      id: 'safety_2',
      category: 'Safety & Security',
      question: 'How can I report a safety concern?',
      answer:
          'Contact Raahi support and share your booking details and a clear description of the concern so the team can assist you.',
    ),
    const FaqItem(
      id: 'safety_3',
      category: 'Safety & Security',
      question: 'How is my personal information protected?',
      answer:
          'Raahi should handle your information according to its published privacy policy. Please review the policy in the app for the latest details.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaqItem> get _visibleFaqs {
    final query = _searchQuery.trim().toLowerCase();
    return _faqs.where((faq) {
      final categoryMatches = faq.category == _selectedCategory;
      final queryMatches = query.isEmpty ||
          faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.category.toLowerCase().contains(query);
      return categoryMatches && queryMatches;
    }).toList();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
      _expandedQuestionId = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _expandedQuestionId = null;
    });
  }

  void _contactSupport() {
    // Replace this with your support screen, phone, email or WhatsApp action.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Connect your Raahi support action here.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final scale = (screenHeight / 850).clamp(0.84, 1.0);

    return Scaffold(
      backgroundColor: page,
      body: SafeArea(
        child: Stack(
          children: [
            // Decorative upper skyline, positioned behind the heading.
            Positioned(
              top: 104 * scale,
              right: 0,
              width: 175 * scale,
              height: 76 * scale,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.95,
                  child: Image.asset(
                    topSkylineAsset,
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      14 * scale,
                      5 * scale,
                      14 * scale,
                      10 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitle(scale),
                        SizedBox(height: 12 * scale),
                        _buildSearch(scale),
                        SizedBox(height: 10 * scale),
                        _buildCategorySelector(scale),
                        SizedBox(height: 11 * scale),
                        _buildQuestionSection(scale),
                        SizedBox(height: 10 * scale),
                        _buildMoreQuestions(scale),
                        SizedBox(height: 12 * scale),
                        _buildSupportCard(scale),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Bottom skyline is decorative and does not cover the scroll content.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 66 * scale,
              child: IgnorePointer(
                child: Image.asset(
                  bottomSkycityAsset,
                  fit: BoxFit.fill,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 57,
      color: Colors.white.withValues(alpha: 0.96),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: IconButton(
              onPressed: () => Navigator.maybePop(context),
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: navy,
                size: 25,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                logoAsset,
                height: 43,
                width: 150,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Text(
                  'Raahi',
                  style: TextStyle(
                    color: navy,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildTitle(double scale) {
    return Column(
      children: [
        Text(
          'Frequently Asked Questions',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 19 * scale,
            height: 1.15,
            letterSpacing: -0.45,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 3 * scale),
        Text(
          'Find quick answers to common questions',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink,
            fontSize: 12 * scale,
            height: 1.2,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch(double scale) {
    return Container(
      height: 43 * scale,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(color: ink, fontSize: 12 * scale),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(
            Icons.search_rounded,
            color: ink,
            size: 22 * scale,
          ),
          hintText: 'Search questions, e.g. “How to book a ride?”',
          hintStyle: TextStyle(
            color: muted,
            fontSize: 11.5 * scale,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                  icon: Icon(Icons.close, size: 18 * scale),
                ),
          contentPadding: EdgeInsets.symmetric(vertical: 10 * scale),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(double scale) {
    return SizedBox(
      height: 78 * scale,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => SizedBox(width: 6 * scale),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category.title == _selectedCategory;
          return SizedBox(
            width: 75 * scale,
            child: Material(
              color: selected ? navy : Colors.white,
              borderRadius: BorderRadius.circular(13),
              child: InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: () => _selectCategory(category.title),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4 * scale,
                    vertical: 5 * scale,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: selected ? navy : border,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        category.icon,
                        size: 27 * scale,
                        color: selected ? Colors.white : category.color,
                      ),
                      SizedBox(height: 3 * scale),
                      Text(
                        category.shortTitle ?? category.title,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: selected ? Colors.white : ink,
                          fontSize: 9.5 * scale,
                          height: 1.05,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuestionSection(double scale) {
    final questions = _visibleFaqs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _searchQuery.isEmpty
              ? '${_selectedCategory == 'Booking' ? 'Booking' : _selectedCategory} Related Questions'
              : 'Search Results',
          style: TextStyle(
            color: ink,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 7 * scale),
        if (questions.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(13 * scale),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: Text(
              'No matching questions found. Try another search or category.',
              style: TextStyle(
                color: muted,
                fontSize: 11 * scale,
              ),
            ),
          )
        else
          ...questions.map((faq) => Padding(
                padding: EdgeInsets.only(bottom: 5 * scale),
                child: _buildFaqTile(faq, scale),
              )),
      ],
    );
  }

  Widget _buildFaqTile(FaqItem faq, double scale) {
    final expanded = _expandedQuestionId == faq.id;
    return Material(
      color: expanded ? const Color(0xFFE2F2FC) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _expandedQuestionId = expanded ? null : faq.id;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 11 * scale,
            vertical: 8 * scale,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: expanded ? const Color(0xFFD8EAF6) : border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.question,
                      style: TextStyle(
                        color: ink,
                        fontSize: 11.5 * scale,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: 5 * scale),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: ink,
                    size: 22 * scale,
                  ),
                ],
              ),
              if (expanded) ...[
                SizedBox(height: 6 * scale),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(9 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    faq.answer,
                    style: TextStyle(
                      color: ink,
                      fontSize: 10.5 * scale,
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreQuestions(double scale) {
    final otherCategories =
        _categories.where((category) => category.title != _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Questions',
          style: TextStyle(
            color: ink,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6 * scale),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < otherCategories.length; i++) ...[
                _categoryRow(otherCategories[i], scale),
                if (i != otherCategories.length - 1)
                  Divider(height: 1, color: border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _categoryRow(FaqCategory category, double scale) {
    final description = switch (category.title) {
      'Fares & Charges' => 'Pricing, tolls, additional charges and more',
      'Payments & Refunds' => 'UPI, cards, wallet, refunds and invoices',
      'Cancellations' => 'How to cancel, refund policy and charges',
      'Drivers & Vehicles' => 'Driver details, vehicle types, ratings and more',
      'Safety & Security' => 'Safety features, emergency help and support',
      _ => 'Bookings and ride information',
    };

    return InkWell(
      onTap: () => _selectCategory(category.title),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 5 * scale,
        ),
        child: Row(
          children: [
            Container(
              width: 43 * scale,
              height: 42 * scale,
              decoration: BoxDecoration(
                color: category.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                category.icon,
                color: category.color,
                size: 25 * scale,
              ),
            ),
            SizedBox(width: 8 * scale),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 11.5 * scale,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ink,
                      fontSize: 9.5 * scale,
                      height: 1.15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: ink,
              size: 22 * scale,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard(double scale) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10 * scale,
        vertical: 9 * scale,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F2FC),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headset_mic_outlined,
            color: navy,
            size: 31 * scale,
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Still have a question?',
                  style: TextStyle(
                    color: ink,
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Our support team is here to help you 24×7.',
                  maxLines: 2,
                  style: TextStyle(
                    color: ink,
                    fontSize: 9.5 * scale,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 5 * scale),
          SizedBox(
            height: 34 * scale,
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 14 * scale,
                color: Colors.white,
              ),
              label: Text(
                'Contact Support',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 9 * scale),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FaqCategory {
  final String title;
  final String? shortTitle;
  final IconData icon;
  final Color color;
  final Color background;

  const FaqCategory({
    required this.title,
    this.shortTitle,
    required this.icon,
    required this.color,
    required this.background,
  });
}

class FaqItem {
  final String id;
  final String category;
  final String question;
  final String answer;

  const FaqItem({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });
}
