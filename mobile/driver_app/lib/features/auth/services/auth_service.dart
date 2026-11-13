import '../../../core/constants/api_constants.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/driver_profile.dart';
import '../models/login_response.dart';

class AuthService {
  /// Login with phone + password. Returns LoginResponse.
  /// Throws ApiException if credentials are wrong or role is not 'driver'.
  static Future<LoginResponse> login(String phone, String password) async {
    final data = await ApiService.post(
      ApiConstants.login,
      {'phone': phone, 'password': password},
    );
    final response = LoginResponse.fromJson(data);
    if (response.role != 'driver') {
      throw const ApiException(
        'This app is only for Raahi drivers. Please use the passenger app.',
      );
    }
    // Persist token and identifiers
    await StorageService.write(StorageKeys.accessToken, response.accessToken);
    await StorageService.write(StorageKeys.userId, response.userId.toString());
    await StorageService.write(StorageKeys.userRole, response.role);
    return response;
  }

  /// Register a new driver.
  static Future<DriverProfile> registerDriver({
    required String fullName,
    required String phone,
    String? email,
    required String password,
    required String licenseNumber,
  }) async {
    final body = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'password': password,
      'license_number': licenseNumber,
    };
    if (email != null && email.isNotEmpty) {
      body['email'] = email;
    }
    final data = await ApiService.post(ApiConstants.driverRegister, body);
    return DriverProfile.fromJson(data);
  }

  /// Fetch the authenticated driver's profile (verification status etc.)
  static Future<DriverProfile> getDriverProfile() async {
    final data = await ApiService.get(ApiConstants.driverMe);
    return DriverProfile.fromJson(data);
  }

  /// Check if a valid session token exists.
  static Future<bool> hasSession() async {
    final token = await StorageService.read(StorageKeys.accessToken);
    final role = await StorageService.read(StorageKeys.userRole);
    return token != null && role == 'driver';
  }

  /// Clear all stored credentials (logout).
  static Future<void> logout() async {
    await StorageService.deleteAll();
  }
}
