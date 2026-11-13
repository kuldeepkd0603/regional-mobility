
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/storage_keys.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  static  Future<Map<String, String>> _headers({
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await StorageService.read(StorageKeys.accessToken);

      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static dynamic _decodeResponse(http.Response response) {
    if (response.body.isEmpty) return <String, dynamic>{};

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw ApiException(
        'Invalid server response (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
  }

  static void _checkResponse(http.Response response, dynamic body) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final detail = body is Map ? body['detail'] : null;
    String message;

    if (detail is String) {
      message = detail;
    } else if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      message = first is Map
          ? (first['msg']?.toString() ?? 'Validation error')
          : first.toString();
    } else {
      message = 'An error occurred (${response.statusCode})';
    }

    throw ApiException(message, statusCode: response.statusCode);
  }

  static Map<String, dynamic> _handleMapResponse(
    http.Response response,
  ) {
    final body = _decodeResponse(response);
    _checkResponse(response, body);

    if (body is Map<String, dynamic>) return body;

    throw ApiException(
      'Expected an object response from server',
      statusCode: response.statusCode,
    );
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool authenticated = false,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(authenticated: authenticated),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    return _handleMapResponse(response);
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(authenticated: authenticated),
        )
        .timeout(const Duration(seconds: 15));

    return _handleMapResponse(response);
  }

  // Fetch endpoints that return a list, such as driver trip history.
  static Future<List<Map<String, dynamic>>> getList(
    String path, {
    bool authenticated = true,
  }) async {
    final response = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}$path'),
          headers: await _headers(authenticated: authenticated),
        )
        .timeout(const Duration(seconds: 15));

    final body = _decodeResponse(response);
    _checkResponse(response, body);

    if (body is List) {
      return body
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    throw ApiException(
      'Expected a list response from server',
      statusCode: response.statusCode,
    );
  }

  // PATCH requests for availability, trip start and trip completion.
  static Future<Map<String, dynamic>> patch(
  String path, {
  Map<String, dynamic> body = const {},
  bool authenticated = true,
}) async {
  final response = await http
      .patch(
        Uri.parse('${ApiConstants.baseUrl}$path'),
        headers: await _headers(authenticated: authenticated),
        body: jsonEncode(body),
      )
      .timeout(const Duration(seconds: 15));

  return _handleMapResponse(response);
}
static Future<List<Map<String, dynamic>>> getMyReviews() async {
  return getList('/reviews/driver/my-reviews');
}


// Fetch notifications for the logged-in driver.
static Future<List<Map<String, dynamic>>> getNotifications() async {
  return getList('/notifications/');
}

// Mark one notification as read.
static Future<void> markNotificationRead(int notificationId) async {
  await patch('/notifications/$notificationId/read');
}

// Mark all notifications as read.
static Future<void> markAllNotificationsRead() async {
  await patch('/notifications/read-all');
}
}
