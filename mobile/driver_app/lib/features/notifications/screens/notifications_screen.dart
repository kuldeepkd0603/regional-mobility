
import 'package:flutter/material.dart';
import '../../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const Color navy = Color(0xFF102D50);
  static const Color teal = Color(0xFF08B99A);
  static const Color background = Color(0xFFF5F7FA);

  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;
  bool isMarkingAll = false;
  final Set<int> updatingIds = {};

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await ApiService.getNotifications();

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
        isLoading = false;
      });
    }
  }

  Future<void> markAsRead(int id) async {
    if (updatingIds.contains(id)) return;

    setState(() {
      updatingIds.add(id);
    });

    try {
      await ApiService.markNotificationRead(id);

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
          (item) => item['id']?.toString() == id.toString(),
        );

        if (index != -1) {
          notifications[index]['is_read'] = true;
        }

        updatingIds.remove(id);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        updatingIds.remove(id);
      });

      showMessage('Unable to update notification');
    }
  }

  Future<void> markAllAsRead() async {
    if (isMarkingAll) return;

    setState(() {
      isMarkingAll = true;
    });

    try {
      await ApiService.markAllNotificationsRead();

      if (!mounted) return;

      setState(() {
        for (final item in notifications) {
          item['is_read'] = true;
        }
        isMarkingAll = false;
      });

      showMessage('All notifications marked as read');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isMarkingAll = false;
      });

      showMessage('Unable to update notifications');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatDate(dynamic value) {
    if (value == null) return '';

    final date = DateTime.tryParse(value.toString())?.toLocal();

    if (date == null) return '';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}  '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications
        .where((item) => item['is_read'] != true)
        .length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: navy,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: navy,
          ),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: isMarkingAll ? null : markAllAsRead,
              child: isMarkingAll
                  ? const SizedBox(
                      height: 17,
                      width: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: teal,
                      ),
                    )
                  : const Text(
                      'Read all',
                      style: TextStyle(
                        color: teal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: teal),
            )
          : errorMessage != null
              ? _buildErrorState()
              : notifications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      color: teal,
                      onRefresh: loadNotifications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];

                          final id = int.tryParse(
                            item['id']?.toString() ?? '',
                          );

                          final isRead = item['is_read'] == true;
                          final isUpdating =
                              id != null && updatingIds.contains(id);

                          return _buildNotificationCard(
                            item: item,
                            id: id,
                            isRead: isRead,
                            isUpdating: isUpdating,
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _buildNotificationCard({
    required Map<String, dynamic> item,
    required int? id,
    required bool isRead,
    required bool isUpdating,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead ? Colors.white : const Color(0xFFEAF7F4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isRead
              ? const Color(0xFFE8EDF2)
              : teal.withValues(alpha: 0.25),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        leading: CircleAvatar(
          radius: 23,
          backgroundColor: teal.withValues(alpha: 0.12),
          child: const Icon(
            Icons.notifications_active_outlined,
            color: teal,
          ),
        ),
        title: Text(
          item['title']?.toString() ?? 'Notification',
          style: TextStyle(
            color: navy,
            fontSize: 15,
            fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['message']?.toString() ?? '',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                formatDate(item['created_at']),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        trailing: isUpdating
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: teal,
                ),
              )
            : isRead
                ? const Icon(
                    Icons.check_circle_outline,
                    color: Colors.grey,
                    size: 21,
                  )
                : const Icon(
                    Icons.circle,
                    color: teal,
                    size: 11,
                  ),
        onTap: () {
          if (!isRead && id != null) {
            markAsRead(id);
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: teal,
      onRefresh: loadNotifications,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 145),
          Icon(
            Icons.notifications_none_rounded,
            size: 75,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 18),
          Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: navy,
              ),
            ),
          ),
          SizedBox(height: 8),
          Center(
            child: Text(
              'Your ride updates and account alerts\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 55,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            Text(
              errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: const TextStyle(color: navy),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: navy,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
