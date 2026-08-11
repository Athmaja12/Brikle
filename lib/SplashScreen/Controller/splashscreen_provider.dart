import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    super.onInit();
    _decideRoute();
  }

  Future<void> _decideRoute() async {
    final minDelay = Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

    await minDelay;

    // Guests always land on /home now — login/registration is deferred
    // to checkout via AuthGate, so there's no need to branch on session
    // state here.
    if (seenOnboarding) {
      Get.offAllNamed('/home');
    } else {
      Get.offAllNamed('/onboarding');
    }
  }
}