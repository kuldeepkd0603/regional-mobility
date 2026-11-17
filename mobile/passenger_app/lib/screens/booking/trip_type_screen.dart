
import 'package:flutter/material.dart';
class TripTypeScreen extends StatefulWidget {
  const TripTypeScreen({super.key});

  @override
  State<TripTypeScreen> createState() => _TripTypeScreenState();
}

class _TripTypeScreenState extends State<TripTypeScreen> {
  static const Color green = Color(0xFF079B80);
  static const Color navy = Color(0xFF06465D);
  static const Color dark = Color(0xFF17202D);

  String selectedTripType = 'local';

  final List<Map<String, dynamic>> tripTypes = [
    {
      'id': 'local',
      'title': 'Local Ride',
      'description': 'For travel within the same city\n(Ujjain / Indore / Dewas)',
      'tags': ['Quick', 'Affordable'],
      'icons': [Icons.access_time, Icons.currency_rupee],
      'illustration': Icons.location_city_rounded,
      'color': const Color(0xFFE5F8F3),
      'illustrationColor': const Color(0xFF079B80),
    },
    {
      'id': 'intercity',
      'title': 'Intercity Travel',
      'description': 'One-way travel between cities\n(e.g. Ujjain ⇄ Indore, Ujjain ⇄ Dewas)',
      'tags': ['Intercity', 'Best Fare'],
      'icons': [Icons.add_road, Icons.currency_rupee],
      'illustration': Icons.directions_car_filled_rounded,
      'color': const Color(0xFFF5F8FA),
      'illustrationColor': const Color(0xFF087F91),
    },
    {
      'id': 'round_trip',
      'title': 'Round Trip',
      'description': 'Travel to a destination and return\n(same day or multi-day)',
      'tags': ['Return Ride', 'Flexible'],
      'icons': [Icons.sync, Icons.calendar_month],
      'illustration': Icons.event_repeat_rounded,
      'color': const Color(0xFFFFF9F0),
      'illustrationColor': const Color(0xFFBD8B20),
    },
    {
      'id': 'religious_tour',
      'title': 'Religious Tour',
      'description': 'Special travel for pilgrimage & darshan\n(Mahakal, Omkareshwar, Khatu Shyam, etc.)',
      'tags': ['Darshan Trip', 'Group & Family'],
      'icons': [Icons.temple_hindu, Icons.groups],
      'illustration': Icons.temple_hindu_rounded,
      'color': const Color(0xFFF8F2FF),
      'illustrationColor': const Color(0xFF7950A4),
    },
  ];

  void _continue() {
    Navigator.pop(context, {
      'trip_type': selectedTripType,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;

            return Column(
              children: [
                // HEADER
                SizedBox(
                  height: compact ? 132 : 145,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 3, 18, 0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 54,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.arrow_back,
                                    color: dark,
                                    size: 27,
                                  ),
                                ),
                              ),
                              Image.asset(
                                'assets/images/raahi_assets/brand/raahi_logo.png',
                                height: 49,
                                width: 190,
                                fit: BoxFit.contain,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Select Trip Type',
                          style: TextStyle(
                            fontSize: compact ? 23 : 25,
                            fontWeight: FontWeight.w900,
                            color: dark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose the ride that best fits your travel need',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: compact ? 13 : 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // TRIP TYPE CARDS
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(17, 5, 17, 8),
                    child: Column(
                      children: [
                        for (final trip in tripTypes) ...[
                          _tripCard(
                            trip,
                            compact: compact,
                          ),
                          const SizedBox(height: 10),
                        ],

                        // INFORMATION STRIP
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F7FA),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: green,
                                size: 23,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You can review & change trip details in the next step.',
                                  style: TextStyle(
                                    color: dark,
                                    fontSize: compact ? 12 : 13,
                                    fontWeight: FontWeight.w500,
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

                // FIXED CONTINUE BUTTON
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      onPressed: _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.arrow_forward, size: 25),
                        ],
                      ),
                    ),
                  ),
                ),

                // SMALL DECORATIVE FOOTER
                SizedBox(
                  height: 20,
                  child: Image.asset(
                    'assets/images/raahi_assets/header/city_skyline5.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox.shrink(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _tripCard(
    Map<String, dynamic> trip, {
    required bool compact,
  }) {
    final isSelected = selectedTripType == trip['id'];
    final Color illustrationColor = trip['illustrationColor'];

    return InkWell(
      onTap: () {
        setState(() {
          selectedTripType = trip['id'];
        });
      },
      borderRadius: BorderRadius.circular(19),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        height: compact ? 108 : 119,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF0FCF8)
              : Colors.white,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF16A58D)
                : const Color(0xFFDDE1E5),
            width: isSelected ? 2 : 1.3,
          ),
        ),
        child: Row(
          children: [
            // ILLUSTRATION AREA
            SizedBox(
              width: compact ? 105 : 116,
              child: Center(
                child: Container(
                  width: 88,
                  height: 82,
                  decoration: BoxDecoration(
                    color: trip['color'],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    trip['illustration'],
                    size: 52,
                    color: illustrationColor,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // TITLE, DESCRIPTION AND TAGS
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip['title'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: dark,
                      fontSize: compact ? 15 : 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    trip['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: compact ? 10 : 11.5,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _tag(
                        trip['tags'][0],
                        trip['icons'][0],
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: _tag(
                          trip['tags'][1],
                          trip['icons'][1],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 5),

            // RADIO SELECTION
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? const Color(0xFF079B80)
                  : Colors.blueGrey.shade300,
              size: 25,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E7E9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: const Color(0xFF247F73),
            size: 13,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: dark,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
