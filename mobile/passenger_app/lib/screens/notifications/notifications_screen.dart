
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navy = Color(0xFF064B68);
  static const Color green = Color(0xFF159B52);
  static const Color dark = Color(0xFF101B2D);
  static const Color grey = Color(0xFF687586);
  static const Color border = Color(0xFFE5E9ED);

  static const String logoPath =
      'assets/images/raahi_assets/brand/raahi_logo.png';

  static const String footerPath =
      'assets/images/raahi_assets/header/city_skyline5.png';

  List<Map<String, dynamic>> notifications = [];

  bool isLoading = true;
  String? errorMessage;
  String selectedTab = 'All';

  final List<String> tabs = [
    'All',
    'Rides',
    'Payments',
    'Offers',
  ];

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  // ------------------------------------------------------------
  // API: LOAD NOTIFICATIONS
  // ------------------------------------------------------------

  Future<void> loadNotifications() async {
    if (mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final result = await ApiService.getNotifications();

      if (!mounted) return;

      final sorted = List<Map<String, dynamic>>.from(result);

      sorted.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
                DateTime(2000);

        final dateB =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
                DateTime(2000);

        return dateB.compareTo(dateA);
      });

      setState(() {
        notifications = sorted;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  // ------------------------------------------------------------
  // API: MARK SINGLE NOTIFICATION AS READ
  // ------------------------------------------------------------

  Future<void> markAsRead(int id) async {
    try {
      await ApiService.markNotificationRead(id);

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          if (item['id'].toString() == id.toString()) {
            item['is_read'] = true;
          }
        }
      });
    } catch (_) {
      showMessage('Unable to update notification');
    }
  }

  // ------------------------------------------------------------
  // API: MARK ALL NOTIFICATIONS AS READ
  // ------------------------------------------------------------

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsRead();

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          item['is_read'] = true;
        }
      });

      showMessage('All notifications marked as read');
    } catch (_) {
      showMessage('Unable to update notifications');
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATION CATEGORY
  // ------------------------------------------------------------

  String category(Map<String, dynamic> item) {
    final raw = [
      item['category'],
      item['type'],
      item['title'],
      item['message'],
    ].where((e) => e != null).join(' ').toLowerCase();

    if (raw.contains('payment') ||
        raw.contains('paid') ||
        raw.contains('transaction') ||
        raw.contains('refund')) {
      return 'Payments';
    }

    if (raw.contains('offer') ||
        raw.contains('discount') ||
        raw.contains('coupon') ||
        raw.contains('promo')) {
      return 'Offers';
    }

    return 'Rides';
  }

  List<Map<String, dynamic>> get filteredNotifications {
    if (selectedTab == 'All') {
      return notifications;
    }

    return notifications
        .where((item) => category(item) == selectedTab)
        .toList();
  }

  // ------------------------------------------------------------
  // DATE AND TIME
  // ------------------------------------------------------------

  DateTime? notificationDate(Map<String, dynamic> item) {
    final raw = item['created_at'];

    if (raw == null) return null;

    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  String dateGroup(Map<String, dynamic> item) {
    final date = notificationDate(item);

    if (date == null) return 'Earlier';

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday =
        today.subtract(const Duration(days: 1));

    final dateOnly =
        DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';

    if (dateOnly == yesterday) return 'Yesterday';

    return '${date.day} ${_month(date.month)} ${date.year}';
  }

  String timeText(Map<String, dynamic> item) {
    final date = notificationDate(item);

    if (date == null) return '';

    final hour =
        date.hour % 12 == 0 ? 12 : date.hour % 12;

    final minute =
        date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final yesterday =
        today.subtract(const Duration(days: 1));

    final dateOnly =
        DateTime(date.year, date.month, date.day);

    final time = '$hour:$minute $period';

    if (dateOnly == today) return time;

    if (dateOnly == yesterday) {
      return 'Yesterday, $time';
    }

    return '${date.day} ${_month(date.month)}, $time';
  }

  String _month(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return months[month - 1];
  }

  // ------------------------------------------------------------
  // NOTIFICATION ICON
  // ------------------------------------------------------------

  IconData notificationIcon(Map<String, dynamic> item) {
    final text = [
      item['title'],
      item['message'],
      item['type'],
    ].where((e) => e != null).join(' ').toLowerCase();

    if (text.contains('completed')) {
      return Icons.check_circle_outline;
    }

    if (text.contains('arrived') || text.contains('driver')) {
      return Icons.directions_car_outlined;
    }

    if (text.contains('confirm') || text.contains('booking')) {
      return Icons.event_available_outlined;
    }

    if (text.contains('payment') || text.contains('paid')) {
      return Icons.account_balance_wallet_outlined;
    }

    if (text.contains('offer') || text.contains('discount')) {
      return Icons.local_offer_outlined;
    }

    if (text.contains('rate') || text.contains('review')) {
      return Icons.star_outline_rounded;
    }

    if (text.contains('temple') || text.contains('darshan')) {
      return Icons.temple_hindu_outlined;
    }

    return Icons.notifications_none_rounded;
  }

  Color notificationColor(Map<String, dynamic> item) {
    final text = [
      item['title'],
      item['message'],
      item['type'],
    ].where((e) => e != null).join(' ').toLowerCase();

    if (text.contains('completed') ||
        text.contains('payment') ||
        text.contains('paid')) {
      return const Color(0xFFE1F8EA);
    }

    if (text.contains('driver') || text.contains('arrived')) {
      return const Color(0xFFE4F3FC);
    }

    if (text.contains('confirm') || text.contains('booking')) {
      return const Color(0xFFF0E9FF);
    }

    if (text.contains('offer') || text.contains('discount')) {
      return const Color(0xFFFFE9E9);
    }

    if (text.contains('rate') || text.contains('review')) {
      return const Color(0xFFFFF1DF);
    }

    if (text.contains('temple') || text.contains('darshan')) {
      return const Color(0xFFE5F3FF);
    }

    return const Color(0xFFE8F5F1);
  }

  Color notificationIconColor(Map<String, dynamic> item) {
    final text = [
      item['title'],
      item['message'],
      item['type'],
    ].where((e) => e != null).join(' ').toLowerCase();

    if (text.contains('completed') ||
        text.contains('payment') ||
        text.contains('paid')) {
      return const Color(0xFF159B52);
    }

    if (text.contains('driver') || text.contains('arrived')) {
      return const Color(0xFF1266A0);
    }

    if (text.contains('confirm') || text.contains('booking')) {
      return const Color(0xFF6539C5);
    }

    if (text.contains('offer') || text.contains('discount')) {
      return const Color(0xFFE53935);
    }

    if (text.contains('rate') || text.contains('review')) {
      return const Color(0xFFE58A20);
    }

    return navy;
  }

  // ------------------------------------------------------------
  // RESPONSIVE MAIN SCREEN
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((item) => item['is_read'] != true)
        .length;

    final filtered = filteredNotifications;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adapt fixed header/footer dimensions to phone height.
            final compact = constraints.maxHeight < 650;

            final headerHeight = compact ? 52.0 : 58.0;
            final headingHeight = compact ? 68.0 : 76.0;
            final footerHeight = compact ? 36.0 : 48.0;

            return Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: _header(unreadCount),
                ),

                SizedBox(
                  height: headingHeight,
                  child: _heading(compact),
                ),

                _tabs(compact),

                // The notification section takes all remaining space.
                // Its list scrolls independently.
                Expanded(
                  child: _notificationSection(filtered),
                ),

                // Footer remains visible and does not cover the list.
                _footer(footerHeight),
              ],
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header(int unreadCount) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back,
              size: 26,
              color: dark,
            ),
          ),
        ),

        Image.asset(
          logoPath,
          width: 155,
          height: 54,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return const Text(
              'Raahi',
              style: TextStyle(
                color: navy,
                fontSize: 27,
                fontWeight: FontWeight.w900,
              ),
            );
          },
        ),

        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: loadNotifications,
            padding: EdgeInsets.zero,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 27,
                  color: dark,
                ),

                if (unreadCount > 0)
                  Positioned(
                    right: -1,
                    top: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // HEADING
  // ------------------------------------------------------------

  Widget _heading(bool compact) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          'Notifications',
          style: TextStyle(
            fontSize: compact ? 25 : 28,
            fontWeight: FontWeight.w900,
            color: dark,
            height: 1.15,
          ),
        ),

        SizedBox(height: compact ? 4 : 6),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'Stay updated with your rides, payments and offers',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: dark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // CATEGORY TABS
  // ------------------------------------------------------------

  Widget _tabs(bool compact) {
    return Container(
      height: compact ? 46 : 50,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        compact ? 6 : 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() {
                    selectedTab = tab;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: selectedTab == tab
                        ? navy
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _tabIcon(tab),
                        size: compact ? 17 : 19,
                        color: selectedTab == tab
                            ? Colors.white
                            : dark,
                      ),

                      const SizedBox(width: 4),

                      Flexible(
                        child: Text(
                          tab,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: selectedTab == tab
                                ? Colors.white
                                : dark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _tabIcon(String tab) {
    switch (tab) {
      case 'Rides':
        return Icons.directions_car_outlined;

      case 'Payments':
        return Icons.payments_outlined;

      case 'Offers':
        return Icons.local_offer_outlined;

      default:
        return Icons.notifications_none_rounded;
    }
  }

  // ------------------------------------------------------------
  // NOTIFICATION SECTION
  // ------------------------------------------------------------

  Widget _notificationSection(
    List<Map<String, dynamic>> items,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed section heading and read-all action.
          SizedBox(
            height: 39,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Notifications',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: dark,
                    ),
                  ),
                ),

                TextButton.icon(
                  onPressed: notifications.any(
                    (item) => item['is_read'] != true,
                  )
                      ? markAllAsRead
                      : null,
                  icon: const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                  ),
                  label: const Text(
                    'Mark All as Read',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1262B6),
                    disabledForegroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),

          // Only this area scrolls.
          Expanded(
            child: _buildNotificationList(items),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(
    List<Map<String, dynamic>> items,
  ) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: navy,
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: grey,
            ),

            const SizedBox(height: 8),

            const Text(
              'Unable to load notifications',
              style: TextStyle(
                color: dark,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: loadNotifications,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(
            color: grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Group notifications by date.
    final grouped =
        <String, List<Map<String, dynamic>>>{};

    for (final item in items) {
      final group = dateGroup(item);

      grouped.putIfAbsent(group, () => []).add(item);
    }

    // ListView allows every notification to be reached.
    // No Expanded widgets are used inside individual cards.
    return ListView(
      padding: const EdgeInsets.only(
        top: 2,
        bottom: 12,
      ),
      physics: const BouncingScrollPhysics(),
      children: [
        for (final entry in grouped.entries) ...[
          _groupHeading(entry.key),

          for (final item in entry.value)
            _notificationCard(item),
        ],
      ],
    );
  }

  // ------------------------------------------------------------
  // DATE GROUP HEADING
  // ------------------------------------------------------------

  Widget _groupHeading(String title) {
    return SizedBox(
      height: 32,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: dark,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // NOTIFICATION CARD
  // ------------------------------------------------------------

  Widget _notificationCard(
    Map<String, dynamic> item,
  ) {
    final isRead = item['is_read'] == true;

    final rawId = item['id'];

    final id = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '');

    final title =
        item['title']?.toString() ?? 'Notification';

    final message =
        item['message']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: !isRead && id != null
            ? () => markAsRead(id)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 9,
            vertical: 8,
          ),
          child: Row(
            children: [
              // Notification icon.
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: notificationColor(item),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  notificationIcon(item),
                  size: 27,
                  color: notificationIconColor(item),
                ),
              ),

              const SizedBox(width: 9),

              // Notification title and message.
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: dark,
                        fontSize: 12,
                        fontWeight: isRead
                            ? FontWeight.w600
                            : FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 5),

              // Time and unread indicator.
              SizedBox(
                width: 70,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText(item),
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: dark,
                        fontSize: 9,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (!isRead)
                      const CircleAvatar(
                        radius: 4,
                        backgroundColor:
                            Color(0xFF1265E8),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // FIXED RAahi FOOTER
  // ------------------------------------------------------------

  Widget _footer(double height) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        footerPath,
        fit: BoxFit.cover,
        alignment: Alignment.bottomCenter,
        errorBuilder: (_, __, ___) {
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
