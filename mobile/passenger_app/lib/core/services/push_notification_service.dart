
import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'api_service.dart';

class PushNotificationService {
  static StreamSubscription<String>? _registrationSubscription;
  static StreamSubscription<RemoteMessage>? _messageSubscription;
  static StreamSubscription<RemoteMessage>? _openedSubscription;

  static Future<void> initialize() async {
    try {
      final messaging = FirebaseMessaging.instance;

      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Register Firebase Installation ID.
      _registrationSubscription ??=
          messaging.onRegistered.listen((installationId) async {
        try {
          await ApiService.registerDeviceToken(installationId);
          debugPrint('Firebase installation registered successfully');
        } catch (e) {
          debugPrint('Installation registration error: $e');
        }
      });

      // Receive notifications while app is open.
      _messageSubscription ??=
          FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground notification received');
        debugPrint('Title: ${message.notification?.title}');
        debugPrint('Body: ${message.notification?.body}');
      });

      // Handle notification taps.
      _openedSubscription ??=
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened: ${message.data}');
      });

      await messaging.register();

      // Handle notification that opened the app from terminated state.
      final initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null) {
        debugPrint('App opened from notification: ${initialMessage.data}');
      }
    } catch (e) {
      debugPrint('Push notification initialization error: $e');
    }
  }
}
