// auth_api_service.dart
import 'dart:convert';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    debugPrint('[AuthApiService] ── loginWithGoogle() START ──');
    debugPrint('[AuthApiService] Posting to ${ApiConfig.googleLoginUrl}');
    debugPrint('[AuthApiService] idToken length: ${idToken.length}');

    final response = await http.post(
      Uri.parse(ApiConfig.googleLoginUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_token": idToken}),
    );

    debugPrint('[AuthApiService] Raw response body: ${response.body}');
    debugPrint('[AuthApiService] Status code: ${response.statusCode}');

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      debugPrint(
        '[AuthApiService] ✅ 200 OK — keys in response: ${data.keys.toList()}',
      );
      debugPrint(
        '[AuthApiService]   access present: ${data["access"] != null}',
      );
      debugPrint(
        '[AuthApiService]   refresh present: ${data["refresh"] != null}',
      );
      debugPrint('[AuthApiService]   customer_id: ${data["customer_id"]}');
      debugPrint('[AuthApiService]   phone_number: ${data["phone_number"]}');

      await SessionManager.saveSession(
        accessToken: data["access"] as String,
        refreshToken: data["refresh"] as String,
        customerId: data["customer_id"] as int?,
        phoneNumber: data["phone_number"] as String?,
      );
      debugPrint('[AuthApiService] ✅ Session saved via SessionManager');
      debugPrint('[AuthApiService] ── loginWithGoogle() END (success) ──');
      return data;
    } else {
      debugPrint('[AuthApiService] ❌ Non-200 response: ${data["error"]}');
      debugPrint('[AuthApiService] ── loginWithGoogle() END (error) ──');
      throw Exception(data["error"] ?? "Google login failed");
    }
  }
}
