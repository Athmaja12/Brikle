import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/LoginScreen/Model/login_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// CONTROLLER — owns state + business logic for the Login screen.
class LoginController extends GetxController {
  final LoginModel model = LoginModel();

  final TextEditingController phoneController = TextEditingController();

  final RxBool isPhoneValid = true.obs;
  final RxBool isLoading = false.obs;

  // NEW: separate flag for the Google Sign-In flow so it doesn't
  // interfere with the phone/OTP loading state, and so the button
  // + overlay can react to it independently.
  final RxBool isGoogleLoading = false.obs;

  final RxString countryCode = '+91'.obs;
  String lastOtp = '';

  @override
  void onInit() {
    super.onInit();
    debugPrint('[LoginController] onInit');
  }

  void onPhoneChanged(String value) {
    model.phoneNumber = value;
    debugPrint('[LoginController] phone changed → "$value"');
    if (!isPhoneValid.value) {
      isPhoneValid.value = model.isPhoneValid;
    }
  }

  void onCountryCodeChanged(String code) {
    countryCode.value = code;
    model.countryCode = code;
    debugPrint('[LoginController] country code changed → "$code"');
  }

  Future<bool> login() async {
    debugPrint('[LoginController] login() called');
    debugPrint('[LoginController]   phone: "${model.phoneNumber}"');

    if (!model.isPhoneValid) {
      debugPrint('[LoginController] validation FAILED — phone invalid');
      isPhoneValid.value = false;
      return false;
    }

    debugPrint('[LoginController] validation passed — calling login API');
    isLoading.value = true;

    try {
      final response = await ApiService.login(phoneNumber: model.phoneNumber);

      final otp = response['otp']?.toString() ?? 'N/A';
      lastOtp = otp;

      debugPrint('┌─────────────────────────────────┐');
      debugPrint('│  LOGIN OTP: $otp                 ');
      debugPrint('│  Phone: ${response['phone_number']}  ');
      debugPrint('└─────────────────────────────────┘');

      isLoading.value = false;

      Get.snackbar(
        'OTP Sent',
        'Your OTP is: $otp',
        backgroundColor: const Color(0xFF12914C),
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.TOP,
      );

      debugPrint('[LoginController] login() SUCCESS → navigating to OTP');
      return true;
    } on ApiException catch (e) {
      debugPrint('[LoginController] ApiException → ${e.message}');
      isLoading.value = false;
      Get.snackbar('Login Failed', e.message);
      return false;
    } catch (e) {
      debugPrint('[LoginController] unexpected error → $e');
      isLoading.value = false;
      Get.snackbar('Login Failed', 'Something went wrong. Please try again.');
      return false;
    }
  }

  @override
  void onClose() {
    debugPrint('[LoginController] onClose');
    phoneController.dispose();
    super.onClose();
  }
}
