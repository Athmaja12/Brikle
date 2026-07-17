// auth_api_service.dart
import 'dart:convert';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApiService {
  static const String baseUrl = "https://backend.brikle.in/api";

  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/google/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"id_token": idToken}),
    );

    final data = jsonDecode(response.body);

    debugPrint("Response body : $data");
    debugPrint(
      "Status code   : ${response.statusCode}",
    ); // ← was $response.statuscode

    if (response.statusCode == 200) {
      await SessionManager.saveSession(
        accessToken: data["access"] as String,
        refreshToken: data["refresh"] as String,
      );
      debugPrint("ACCESS TOKEN SAVED via SessionManager");
      return data;
    } else {
      throw Exception(data["error"] ?? "Google login failed");
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("refresh_token");
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access_token");
    await prefs.remove("refresh_token");
  }
}
