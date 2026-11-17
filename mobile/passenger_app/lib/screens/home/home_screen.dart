import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import '../booking/my_bookings_screen.dart';
import '../notifications/notifications_screen.dart';
import '../booking/pickup_location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color green = Color(0xFF079B80);
  static const Color dark = Color(0xFF151D2B);
  static const Color background = Color(0xFFF8FAFB);

  // home_hero.png already contains the car. Do not overlay a second car.
  static const String heroImage =
      'assets/images/raahi_assets/header/home_hero.png';
  static const String logoImage =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  // Popular destination photos (replace filenames only if your asset names differ).
  static const List<Map<String, String>> destinations = [
    {
      'name': 'Ujjain',
      'detail': 'Mahakaleshwar Temple & Shipra River',
      'image': 'assets/images/raahi_assets/destinations/ujjain.png',
    },
    {
      'name': 'Indore',
      'detail': 'Rajwada Palace',
      'image': 'assets/images/raahi_assets/destinations/indore.png',
    },
    {
      'name': 'Dewas',
      'detail': 'Chamunda Mata Tekri',
      'image': 'assets/images/raahi_assets/destinations/dewas.png',
    },
    {
      'name': 'Bhopal',
      'detail': 'Upper Lake & Taj-ul-Masajid',
      'image': 'assets/images/raahi_assets/destinations/bhopal.png',
    },
    {
      'name': 'Jabalpur',
      'detail': 'Bhedaghat Marble Rocks',
      'image': 'assets/images/raahi_assets/destinations/jabalpur.png',
    },
    {
      'name': 'Udaipur',
      'detail': 'Lake Pichola & City Palace',
      'image': 'assets/images/raahi_assets/destinations/udaipur.png',
    },
    {
      'name': 'Baglamukhi',
      'detail': 'Maa Baglamukhi Temple, Nalkheda',
      'image': 'assets/images/raahi_assets/destinations/baglamukhi.png',
    },
    {
      'name': 'Pachmarhi',
      'detail': 'Hill station & waterfalls',
      'image': 'assets/images/raahi_assets/destinations/pachmarhi.png',
    },
    {
      'name': 'Omkareshwar',
      'detail': 'Omkareshwar Temple & Narmada River',
      'image': 'assets/images/raahi_assets/destinations/omkareshwar.png',
    },
  ];

  // Promotion banner artwork: temple_1.png through temple_6.png are
  // promotional banners, not destination or route photos.
  static const List<String> promotionImages = [
    'assets/images/raahi_assets/destinations/temple_1.png',
    'assets/images/raahi_assets/destinations/temple_2.png',
    'assets/images/raahi_assets/destinations/temple_3.png',
    'assets/images/raahi_assets/destinations/temple_4.png',
    'assets/images/raahi_assets/destinations/temple_5.png',
    'assets/images/raahi_assets/destinations/temple_6.png',
  ];

  String selectedCity = 'Ujjain';
  int currentPromotionIndex = 0;

  final List<Map<String, dynamic>> tripTypes = [
    {
      'title': 'Local\nRides',
      'icon': Icons.directions_car_filled_rounded,
      'color': Color(0xFFDDF7F0),
      'iconColor': Color(0xFF079B80),
    },
    {
      'title': 'Intercity\nTravel',
      'icon': Icons.route_rounded,
      'color': Color(0xFFE0F3FC),
      'iconColor': Color(0xFF087C9C),
    },
    {
      'title': 'Round\nTrips',
      'icon': Icons.sync_rounded,
      'color': Color(0xFFFFF4DF),
      'iconColor': Color(0xFFD39116),
    },
    {
      'title': 'Religious\nTours',
      'icon': Icons.temple_hindu_rounded,
      'color': Color(0xFFF0E8FC),
      'iconColor': Color(0xFF7040A5),
    },
  ];


  Future<void> _startBookingFlow() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const PickupLocationScreen()),
    );

    if (result != null && mounted) {
      debugPrint('Selected pickup: ${result['pickup_address']}');
      debugPrint(
        'Pickup coordinates: '
        '${result['pickup_latitude']}, '
        '${result['pickup_longitude']}',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  void _openBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final screenWidth = constraints.maxWidth;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHero(screenHeight, screenWidth),
                        Transform.translate(
                          offset: const Offset(0, 0),
                          child: Column(
                            children: [
                              _buildLocationCard(),
                              _buildTripTypes(),
                              _buildPopularDestinations(),
                              const SizedBox(height: 8),
                              _buildPromotionBanner(),
                              const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            );
          },
        ),
      ),
    );
  }

  // HERO: use the complete home hero asset; it already includes the car.
  Widget _buildHero(double screenHeight, double screenWidth) {
    final heroHeight = (screenHeight * 0.245).clamp(185.0, 220.0);

    return SizedBox(
      height: heroHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: Image.asset(
              heroImage,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFEAF7F8),
              ),
            ),
          ),

          // Gentle lower fade so the location card blends into the hero.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.02),
                    Colors.white.withValues(alpha: 0.02),
                    const Color(0xFFE8F8F7).withValues(alpha: 0.45),
                  ],
                  stops: const [0, 0.65, 1],
                ),
              ),
            ),
          ),

          Positioned(
            top: 8,
            left: 18,
            right: 18,
            child: Row(
              children: [
                InkWell(
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Menu coming soon')),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  child: const SizedBox(
                    width: 34,
                    height: 42,
                    child: Icon(Icons.menu_rounded, size: 29, color: dark),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset(
                      logoImage,
                      height: 42,
                      fit: BoxFit.contain,
                      alignment: Alignment.centerLeft,
                      errorBuilder: (_, __, ___) => const Text(
                        'Raahi',
                        style: TextStyle(
                          color: dark,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
                _headerButton(Icons.notifications_none_rounded, _openNotifications),
              ],
            ),
          ),

          Positioned(
            left: 22,
            top: heroHeight * 0.23,
            right: screenWidth * 0.30,
            child: const Text(
              'Hello, Kuldeep 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: dark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Positioned(
            left: 22,
            top: heroHeight * 0.38,
            right: screenWidth * 0.28,
            child: const Text(
              'Book your ride for local, intercity\nand religious travel',
              style: TextStyle(
                color: dark,
                fontSize: 13.5,
                height: 1.28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          Positioned(
            left: 22,
            bottom: 17,
            child: InkWell(
              onTap: _showCityPicker,
              borderRadius: BorderRadius.circular(28),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.10),
                      blurRadius: 9,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on, color: green, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      selectedCity,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: dark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 21),
                  ],
                ),
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _headerButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 39,
        height: 39,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: dark, size: 24),
      ),
    );
  }

  void _showCityPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final cities = ['Ujjain', 'Indore', 'Dewas', 'Bhopal', 'Jabalpur', 'Udaipur'];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your city',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                ...cities.map(
                  (city) => ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: green),
                    title: Text(city),
                    trailing: selectedCity == city
                        ? const Icon(Icons.check_circle, color: green)
                        : null,
                    onTap: () {
                      setState(() => selectedCity = city);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // PICKUP AND DESTINATION CARD
  Widget _buildLocationCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Material(
        color: Colors.white,
        elevation: 5,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(25),
        child: InkWell(
          onTap: _startBookingFlow,
          borderRadius: BorderRadius.circular(25),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 10, 4),
            child: Column(
              children: [
                _locationRow(
                  icon: Icons.circle,
                  iconColor: green,
                  title: 'Pickup Location',
                  subtitle: 'My Current Location',
                  onTap: _startBookingFlow,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 38),
                  child: Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                ),
                _locationRow(
                  icon: Icons.location_on,
                  iconColor: const Color(0xFFE9273D),
                  title: 'Where to?',
                  subtitle: 'Enter destination, city or place',
                  onTap: _startBookingFlow,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _locationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 43,
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: dark,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (title == 'Pickup Location')
              IconButton(
                onPressed: onTap,
                icon: const Icon(Icons.my_location_rounded, color: dark, size: 23),
              ),
          ],
        ),
      ),
    );
  }

  // TRIP TYPE TILES
  Widget _buildTripTypes() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: tripTypes.map((trip) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                onTap: _startBookingFlow,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: trip['color'] as Color,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        trip['icon'] as IconData,
                        color: trip['iconColor'] as Color,
                        size: 31,
                      ),
                      const SizedBox(height: 7),
                      Text(
                        trip['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: dark,
                          fontSize: 12,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // POPULAR DESTINATIONS: compact horizontal cards, all nine requested places.
  Widget _buildPopularDestinations() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Popular Destinations',
                  style: TextStyle(
                    color: dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _showMessage('All destinations are shown below'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        color: green,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: green, size: 20),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 105,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: destinations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 7),
              itemBuilder: (context, index) {
                final place = destinations[index];
                return InkWell(
                  onTap: _startBookingFlow,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 116,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE6EBEF)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.045),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 56,
                          width: double.infinity,
                          child: Image.asset(
                            place['image']!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFEAF4F4),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.temple_hindu_rounded,
                                color: green,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(7, 4, 6, 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place['name']!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: dark,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                place['detail']!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.blueGrey.shade600,
                                  fontSize: 9,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // PROMOTION BANNERS: temple_1.png through temple_6.png are banner images.
  // They are displayed as a swipeable carousel, not as destination cards.
  Widget _buildPromotionBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        children: [
          SizedBox(
            height: 115,
            child: PageView.builder(
              itemCount: promotionImages.length,
              onPageChanged: (index) {
                setState(() => currentPromotionIndex = index);
              },
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox.expand(
                    child: Image.asset(
                      promotionImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAF4F4),
                        child: Center(
                          child: Icon(
                            Icons.local_offer_rounded,
                            color: green,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              promotionImages.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: currentPromotionIndex == index ? 13 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: currentPromotionIndex == index
                      ? green
                      : const Color(0xFFCAD3DA),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // BOTTOM NAVIGATION: same five destinations and existing callbacks.
  Widget _buildBottomNavigation() {
    return Container(
      height: 76,
      padding: const EdgeInsets.fromLTRB(5, 5, 5, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.09),
            blurRadius: 14,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          _navItem(Icons.home_filled, 'Home', true, () {}),
          _navItem(
            Icons.calendar_month_outlined,
            'My Bookings',
            false,
            _openBookings,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _startBookingFlow,
              child: Transform.translate(
                offset: const Offset(0, -15),
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: green.withValues(alpha: 0.22),
                        blurRadius: 9,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.directions_car_filled_rounded,
                        color: Colors.white,
                        size: 27,
                      ),
                      SizedBox(height: 1),
                      Text(
                        'Book Ride',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _navItem(
            Icons.account_balance_wallet_outlined,
            'Payments',
            false,
            () => _showMessage('Payments coming soon'),
          ),
          _navItem(
            Icons.person_outline_rounded,
            'Profile',
            false,
            _openProfile,
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool selected,
    VoidCallback onTap,
  ) {
    final color = selected ? green : dark;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 25),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
