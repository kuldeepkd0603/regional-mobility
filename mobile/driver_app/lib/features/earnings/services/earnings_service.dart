
import '../../../core/services/api_service.dart';
import '../models/earnings_model.dart';

class EarningsService {
  static Future<DriverEarnings> getDriverEarnings() async {
    final response = await ApiService.get('/earnings/driver/me');

    return DriverEarnings.fromJson(response);
  }
}
