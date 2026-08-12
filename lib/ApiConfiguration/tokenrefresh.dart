import 'package:shared_preferences/shared_preferences.dart';

/// Persists auth tokens + customer id + guest device id across app restarts.
class SessionManager {
  SessionManager._();

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyCustomerId = 'customer_id';
  static const _keyPhoneNumber = 'phone_number';

  // Guest cart device ID
  static const _keyGuestDeviceId = 'guest_device_id';

  // ─────────────────────────────────────────────────────────────
  // AUTH SESSION
  // ─────────────────────────────────────────────────────────────

  static Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    int? customerId,
    String? phoneNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyAccessToken,
      accessToken,
    );

    await prefs.setString(
      _keyRefreshToken,
      refreshToken,
    );

    if (customerId != null) {
      await prefs.setInt(
        _keyCustomerId,
        customerId,
      );
    }

    if (phoneNumber != null) {
      await prefs.setString(
        _keyPhoneNumber,
        phoneNumber,
      );
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

  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPhoneNumber);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();

    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────────────
  // GUEST CART DEVICE ID
  // ─────────────────────────────────────────────────────────────

  static Future<void> saveGuestDeviceId(
    String deviceId,
  ) async {
    if (deviceId.trim().isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _keyGuestDeviceId,
      deviceId.trim(),
    );
  }

  static Future<String?> getGuestDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(
      _keyGuestDeviceId,
    );
  }

  static Future<void> clearGuestDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _keyGuestDeviceId,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyCustomerId);

    // Keep phone number so login can prefill it.
    //
    // IMPORTANT:
    // Do NOT clear guest_device_id here automatically.
    //
    // The guest device ID may still be needed when returning
    // to guest mode.
  }
}