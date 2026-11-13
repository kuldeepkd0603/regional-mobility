
import 'package:flutter/material.dart';

import '../../core/services/api_service.dart';
import '../home/home_screen.dart';
import 'auth_screen.dart';
import '../../core/services/push_notification_service.dart';
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> sessionCheck;

  @override
  void initState() {
    super.initState();
    sessionCheck = checkSession();
  }

  Future<bool> checkSession() async {
    try {
      await ApiService.getCurrentUser().timeout(
        const Duration(seconds: 8),
      );
      await PushNotificationService.initialize();
      return true;
    } catch (e) {
      debugPrint('Session check error: $e');
      return false;
    }
  }
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: sessionCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return const HomeScreen();
        }

        return const AuthScreen();
      },
    );
  }
}
