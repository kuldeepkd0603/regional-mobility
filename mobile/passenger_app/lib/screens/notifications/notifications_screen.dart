
import 'package:flutter/material.dart';
import '../../core/services/api_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
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

  Future<void> markAsRead(int id, int index) async {
    try {
      await ApiService.markNotificationRead(id);

      if (!mounted) return;

      setState(() {
        notifications[index]['is_read'] = true;
      });
    } catch (e) {
      showMessage('Unable to update notification');
    }
  }

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
    } catch (e) {
      showMessage('Unable to update notifications');
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final unreadCount = notifications.where(
      (item) => item['is_read'] != true,
    ).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1746A2),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markAllAsRead,
              child: const Text('Read all'),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: loadNotifications,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : notifications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadNotifications,
                      child: ListView(
                        children: const [
                          SizedBox(height: 150),
                          Icon(
                            Icons.notifications_none,
                            size: 65,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'No notifications yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Your booking updates will appear here.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(14),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          final item = notifications[index];

                          final id = item['id'] as int?;
                          final isRead = item['is_read'] == true;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isRead
                                ? Colors.white
                                : const Color(0xFFEAF1FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF1746A2)
                                    .withValues(alpha: 0.1),
                                child: const Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFF1746A2),
                                ),
                              ),
                              title: Text(
                                item['title']?.toString() ??
                                    'Notification',
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['message']?.toString() ?? '',
                                    ),
                                    const SizedBox(height: 8),
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
                              trailing: isRead
                                  ? const Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.grey,
                                    )
                                  : const Icon(
                                      Icons.circle,
                                      color: Color(0xFF1746A2),
                                      size: 11,
                                    ),
                              onTap: () {
                                if (!isRead && id != null) {
                                  markAsRead(id, index);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
