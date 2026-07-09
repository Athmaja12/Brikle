import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens + customer id across app restarts.
///
/// Add to pubspec.yaml if not already present:
///   shared_preferences: ^2.2.0
class SessionManager {
  SessionManager._();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyCustomerId = 'customer_id';
  static const _keyPhoneNumber = 'phone_number';

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    int? customerId,
    String? phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    if (customerId != null) {
      await prefs.setInt(_keyCustomerId, customerId);
    }
    if (phoneNumber != null) {
      await prefs.setString(_keyPhoneNumber, phoneNumber);
    }
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<int?> getCustomerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCustomerId);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyCustomerId);
    // phone number is left in place so the login screen can prefill it
  }
}