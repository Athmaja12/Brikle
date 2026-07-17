import 'dart:async';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    // Keep the splash visible briefly regardless of how fast the checks run
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final loggedIn = await SessionManager.isLoggedIn();
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    await minDelay;

    if (loggedIn) {
      Get.offAllNamed('/home');
    } else if (seenOnboarding) {
      Get.offAllNamed('/login');
    } else {
      Get.offAllNamed('/onboarding');
    }
  }
}