
import 'dart:async';
import 'package:flutter/material.dart';
import '../profile/refer_earn_screen.dart';
class OffersRewardsScreen extends StatefulWidget {
  const OffersRewardsScreen({super.key});

  @override
  State<OffersRewardsScreen> createState() => _OffersRewardsScreenState();
}

class _OffersRewardsScreenState extends State<OffersRewardsScreen> {
  static const Color navy = Color(0xFF064B68);
  static const Color green = Color(0xFF159B7C);
  static const Color darkText = Color(0xFF151B24);
  static const Color greyText = Color(0xFF68727D);
  static const Color pageBackground = Color(0xFFF5F8F7);
  static const Color borderColor = Color(0xFFE2E8E5);

  final PageController _pageController = PageController();
  Timer? _timer;

  int _currentSlide = 0;
  String _selectedCategory = 'All Offers';

  final List<Map<String, dynamic>> _offers = [
    {
      'code': 'MAHAKAL200',
      'description': 'Flat ₹200 OFF on Religious Tours',
      'category': 'Tour Offers',
      'image': 'assets/images/raahi_assets/offers/mahakal200.png',
      'color': const Color(0xFF6045A8),
      'minimum': 'Min. booking ₹1,999',
      'validity': '30 Nov 2026',
      'icon': Icons.temple_hindu_rounded,
    },
    {
      'code': 'RAAHI50',
      'description': 'Flat ₹50 OFF on Local Rides',
      'category': 'Ride Offers',
      'image': 'assets/images/raahi_assets/offers/raahi50.png',
      'color': const Color(0xFF2479B9),
      'minimum': 'Min. booking ₹299',
      'validity': '25 Nov 2026',
      'icon': Icons.directions_car_rounded,
    },
    {
      'code': 'OUTSTATION10',
      'description': '10% OFF on Outstation Rides',
      'category': 'Tour Offers',
      'image': 'assets/images/raahi_assets/offers/outstation10.png',
      'color': const Color(0xFFDB8739),
      'minimum': 'Max. discount ₹500',
      'validity': '30 Nov 2026',
      'icon': Icons.directions_car_rounded,
    },
    {
      'code': 'WALLET100',
      'description': 'Get ₹100 OFF on Wallet Top-up',
      'category': 'Wallet Offers',
      'image': 'assets/images/raahi_assets/offers/wallet100.png',
      'color': const Color(0xFF159B7C),
      'minimum': 'Min. add money ₹500',
      'validity': '31 Dec 2026',
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  final List<String> _categories = [
    'All Offers',
    'Ride Offers',
    'Tour Offers',
    'Wallet Offers',
  ];

  final Map<String, IconData> _categoryIcons = {
    'All Offers': Icons.local_offer_outlined,
    'Ride Offers': Icons.directions_car_outlined,
    'Tour Offers': Icons.temple_hindu_outlined,
    'Wallet Offers': Icons.account_balance_wallet_outlined,
  };

  List<Map<String, dynamic>> get _filteredOffers {
    if (_selectedCategory == 'All Offers') return _offers;

    return _offers
        .where((offer) => offer['category'] == _selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;

      final next = (_currentSlide + 1) % _offers.length;

      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _applyOffer(String code) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected coupon: $code'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: navy,
      ),
    );
  }

  void _showTerms() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  '1. Each offer is valid only for its stated category.\n\n'
                  '2. Minimum booking or wallet top-up requirements apply '
                  'where specified.\n\n'
                  '3. OUTSTATION10 is subject to the maximum discount '
                  'shown in the offer.\n\n'
                  '4. Offers are subject to their displayed validity dates.\n\n'
                  '5. Offer application and eligibility must be verified '
                  'when the booking or payment is processed.',
                  style: TextStyle(
                    fontSize: 13,
                    color: greyText,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: navy,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final height = constraints.maxHeight;
                  final scale = (height / 700).clamp(0.78, 1.0);

                  final titleHeight = 48.0 * scale;
                  final bannerHeight =
                      (height * 0.165).clamp(92.0, 125.0);
                  final summaryHeight =
                      (height * 0.125).clamp(70.0, 92.0);
                  final referralHeight =
                      (height * 0.125).clamp(78.0, 100.0);

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16 * scale,
                      5 * scale,
                      16 * scale,
                      4 * scale,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: titleHeight,
                          child: _titleSection(scale),
                        ),
                        SizedBox(height: 3 * scale),

                        SizedBox(
                          height: bannerHeight,
                          child: _promoCarousel(),
                        ),

                        SizedBox(height: 5 * scale),

                        _carouselIndicators(scale),

                        SizedBox(height: 8 * scale),

                        SizedBox(
                          height: summaryHeight,
                          child: _rewardSummary(scale),
                        ),

                        SizedBox(height: 9 * scale),

                        SizedBox(
                          height: 39 * scale,
                          child: _categoryFilters(scale),
                        ),

                        SizedBox(height: 8 * scale),

                        SizedBox(
                          height: 27 * scale,
                          child: _availableOffersHeading(scale),
                        ),

                        SizedBox(height: 5 * scale),

                        Expanded(
                          child: _offersList(scale),
                        ),

                        SizedBox(height: 7 * scale),

                        SizedBox(
                          height: referralHeight,
                          width: double.infinity,
                          child: _referEarnCard(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            _bottomDecoration(),
          ],
        ),
      ),
    );
  }

  // HEADER

  Widget _header() {
    return Container(
      height: 58,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: navy,
              size: 23,
            ),
          ),
          Expanded(
            child: Center(
              child: Image.asset(
                'assets/images/raahi_assets/brand/raahi_logo.png',
                height: 42,
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
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: navy,
              size: 25,
            ),
          ),
        ],
      ),
    );
  }

  // TITLE

  Widget _titleSection(double scale) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offers & Rewards',
          maxLines: 1,
          style: TextStyle(
            fontSize: 25 * scale,
            fontWeight: FontWeight.w900,
            color: darkText,
          ),
        ),
        SizedBox(height: 3 * scale),
        Text(
          'Save more on every journey with Raahi',
          maxLines: 1,
          style: TextStyle(
            fontSize: 13 * scale,
            color: greyText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // PROMOTIONAL CAROUSEL
  // The generated offer images already contain their own text.

  Widget _promoCarousel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(19),
      child: PageView.builder(
        controller: _pageController,
        itemCount: _offers.length,
        onPageChanged: (index) {
          if (mounted) {
            setState(() => _currentSlide = index);
          }
        },
        itemBuilder: (context, index) {
          final offer = _offers[index];

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                offer['image'],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [offer['color'] as Color, navy],
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      '${offer['code']}\n${offer['description']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _nextSlide,
                      child: const SizedBox(
                        height: 38,
                        width: 38,
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: navy,
                          size: 27,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _nextSlide() {
    if (!_pageController.hasClients) return;

    final next = (_currentSlide + 1) % _offers.length;

    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Widget _carouselIndicators(double scale) {
    return SizedBox(
      height: 9 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_offers.length, (index) {
          final selected = _currentSlide == index;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 7 * scale,
            width: (selected ? 21 : 7) * scale,
            decoration: BoxDecoration(
              color: selected ? green : const Color(0xFFCCD5D2),
              borderRadius: BorderRadius.circular(10),
            ),
          );
        }),
      ),
    );
  }

  // REWARD SUMMARY

  Widget _rewardSummary(double scale) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.card_giftcard_rounded,
            title: 'My Rewards',
            color: const Color(0xFF6045A8),
            scale: scale,
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: _summaryCard(
            icon: Icons.savings_rounded,
            title: 'Saved Till Now',
            color: green,
            scale: scale,
          ),
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: _summaryCard(
            icon: Icons.stars_rounded,
            title: 'Reward Points',
            color: const Color(0xFFDB8739),
            scale: scale,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required Color color,
    required double scale,
  }) {
    return Container(
      height: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 3 * scale,
        vertical: 2 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 26 * scale),
          SizedBox(height: 1 * scale),
          Text(
            'N/A',
            style: TextStyle(
              fontSize: 17 * scale,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
          SizedBox(height: 3 * scale),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10 * scale,
                color: greyText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // CATEGORY FILTERS

  Widget _categoryFilters(double scale) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const ClampingScrollPhysics(),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => SizedBox(width: 7 * scale),
      itemBuilder: (context, index) {
        final category = _categories[index];
        final selected = _selectedCategory == category;

        return GestureDetector(
          onTap: () {
            setState(() => _selectedCategory = category);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 12 * scale),
            decoration: BoxDecoration(
              color: selected ? navy : Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: selected ? navy : borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcons[category],
                  size: 15 * scale,
                  color: selected ? Colors.white : darkText,
                ),
                SizedBox(width: 5 * scale),
                Text(
                  category,
                  style: TextStyle(
                    color: selected ? Colors.white : greyText,
                    fontSize: 10.5 * scale,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // AVAILABLE OFFERS HEADING

  Widget _availableOffersHeading(double scale) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Available Offers',
            style: TextStyle(
              fontSize: 19 * scale,
              fontWeight: FontWeight.w900,
              color: darkText,
            ),
          ),
        ),
        GestureDetector(
          onTap: _showTerms,
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: navy,
                size: 14 * scale,
              ),
              SizedBox(width: 4 * scale),
              Text(
                'View Terms & Conditions',
                style: TextStyle(
                  fontSize: 9.5 * scale,
                  color: navy,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // OFFERS LIST
  // This list uses the remaining available height. It does not scroll.

  Widget _offersList(double scale) {
    final offers = _filteredOffers;

    if (offers.isEmpty) {
      return const Center(
        child: Text(
          'No offers in this category',
          style: TextStyle(color: greyText),
        ),
      );
    }

    return Column(
      children: [
        for (int i = 0; i < offers.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 5 * scale),
              child: _offerCard(offers[i], scale),
            ),
          ),
      ],
    );
  }

  Widget _offerCard(Map<String, dynamic> offer, double scale) {
    final color = offer['color'] as Color;
    final icon = offer['icon'] as IconData;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 9 * scale,
        vertical: 4 * scale,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 43 * scale,
            height: 43 * scale,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 25 * scale,
            ),
          ),
          SizedBox(width: 9 * scale),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer['code'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5 * scale,
                    fontWeight: FontWeight.w900,
                    color: darkText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  offer['description'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5 * scale,
                    color: greyText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  offer['minimum'],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9 * scale,
                    color: greyText,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 10 * scale,
                      color: greyText,
                    ),
                    SizedBox(width: 3 * scale),
                    Expanded(
                      child: Text(
                        'Valid till: ${offer['validity']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 8.5 * scale,
                          color: greyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 5 * scale),
          SizedBox(
            width: 67 * scale,
            height: 35 * scale,
            child: ElevatedButton(
              onPressed: () => _applyOffer(offer['code']),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE2F8E9),
                foregroundColor: const Color(0xFF168342),
                elevation: 0,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                  side: const BorderSide(
                    color: Color(0xFF168342),
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                'Apply',
                style: TextStyle(
                  fontSize: 11 * scale,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // GENERATED REFERRAL CARD
  // Use the complete supplied image, not a newly designed Flutter card.

  Widget _referEarnCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
            builder: (context) => const ReferEarnScreen(),
            ),
        );
        },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Image.asset(
          'assets/images/raahi_assets/offers/refer_earn.png',
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) {
            return Container(
              color: const Color(0xFFE2F8F0),
              alignment: Alignment.center,
              child: const Text(
                'Referral card image not found',
                style: TextStyle(color: navy),
              ),
            );
          },
        ),
      ),
    );
  }

  // BOTTOM CITY DECORATION

  Widget _bottomDecoration() {
    return SizedBox(
      height: 34,
      width: double.infinity,
      child: IgnorePointer(
        child: Image.asset(
          'assets/images/raahi_assets/header/city_skyline5.png',
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
