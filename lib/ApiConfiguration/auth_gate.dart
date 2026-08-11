import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/LoginScreen/View/loginscreen.dart';
import 'package:flutter/material.dart';

/// Single entry point for gating account-only actions (add address,
/// checkout) while the rest of the app stays browsable as a guest.
class AuthGate {
  AuthGate._();

  static Future<bool> isLoggedIn() => SessionManager.isLoggedIn();

  /// If already logged in, runs [onAuthenticated] immediately.
  /// Otherwise pushes LoginView in "modal" mode and only runs
  /// [onAuthenticated] if the user completes login/registration
  /// (LoginView pops `true` on success — see loginscreen.dart).
  static Future<T?> requireAuth<T>(
    BuildContext context, {
    required Future<T> Function() onAuthenticated,
    String reason = 'Please log in to continue',
  }) async {
    if (await isLoggedIn()) {
      return onAuthenticated();
    }

    final loggedIn = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => LoginView(checkoutReason: reason),
      ),
    );

    if (loggedIn == true) {
      return onAuthenticated();
    }
    return null; // user backed out — caller does nothing
  }
}