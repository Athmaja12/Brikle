import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/LoginOtp/Model/otp_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum OtpFlow { signup, login }

class OtpController extends GetxController {
  late final OtpModel model;

  /// Rx so the signup flow can transition itself into a login flow
  /// in-place after registration verifies, instead of pushing a
  /// second OtpView.
  late final Rx<OtpFlow> flow;

  /// When true, on final (login) success this pops(true) back to
  /// whoever pushed this screen (AuthGate → LoginView/SignupView chain)
  /// instead of navigating to /home directly.
  final bool isModal;

  final String? prefillOtp;

  final List<TextEditingController> digitControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> digitFocusNodes = List.generate(4, (_) => FocusNode());

  final RxBool isOtpValid = true.obs;
  final RxBool isLoading = false.obs;
  final RxInt resendCooldown = 0.obs;

  /// True while silently swapping the just-verified registration OTP
  /// screen into a login OTP screen. The view shows a brief interstitial
  /// during this window.
  final RxBool isTransitioningToLogin = false.obs;

  OtpController({
    required String phoneNumber,
    String countryCode = '+91',
    OtpFlow flow = OtpFlow.signup,
    this.prefillOtp,
    this.isModal = false,
  }) {
    model = OtpModel(phoneNumber: phoneNumber, countryCode: countryCode);
    this.flow = flow.obs;
  }

  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '[OtpController] onInit — flow: ${flow.value}, phone: ${model.phoneNumber}, isModal: $isModal',
    );
    _maybeAutoFill(prefillOtp);
  }

  void _maybeAutoFill(String? otp) {
    if (otp == null || otp.length != 4) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < 4; i++) {
        digitControllers[i].text = otp[i];
      }
      _syncOtpCode();
      debugPrint('[OtpController] auto-fill done — otpCode: "${model.otpCode}"');
    });
  }

  void _clearDigits() {
    for (final c in digitControllers) {
      c.clear();
    }
    model.otpCode = '';
  }

  void onDigitChanged(int index, String value) {
    debugPrint('[OtpController] digit[$index] changed → "$value"');
    if (value.isNotEmpty && index < 3) {
      digitFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      digitFocusNodes[index - 1].requestFocus();
    }
    _syncOtpCode();
    debugPrint('[OtpController] otpCode after change: "${model.otpCode}"');
    if (!isOtpValid.value) {
      isOtpValid.value = true;
    }
  }

  void _syncOtpCode() {
    model.otpCode = digitControllers.map((c) => c.text).join();
  }

  Future<void> verifyOtp() async {
    _syncOtpCode();
    debugPrint(
      '[OtpController] verifyOtp() called — otpCode: "${model.otpCode}", flow: ${flow.value}',
    );

    if (!model.isOtpComplete) {
      debugPrint('[OtpController] OTP incomplete — showing error');
      isOtpValid.value = false;
      return;
    }

    isLoading.value = true;
    debugPrint('[OtpController] calling verify API...');

    try {
      if (flow.value == OtpFlow.signup) {
        await _verifySignupOtp();
      } else {
        await _verifyLoginOtp();
      }
    } on ApiException catch (e) {
      debugPrint(
        '[OtpController] ApiException → ${e.message} (status: ${e.statusCode})',
      );
      isLoading.value = false;
      isOtpValid.value = false;
      Get.snackbar('Verification Failed', e.message);
    } catch (e) {
      debugPrint('[OtpController] unexpected error → $e');
      isLoading.value = false;
      isOtpValid.value = false;
      Get.snackbar(
        'Verification Failed',
        'Something went wrong. Please try again.',
      );
    }
  }

  /// Registration OTP no longer returns tokens — it just confirms the
  /// account exists. Per the updated backend contract, immediately log
  /// the user in via the normal phone-login OTP flow, reusing this same
  /// controller/screen instead of pushing a second OtpView.
  Future<void> _verifySignupOtp() async {
    debugPrint('[OtpController] hitting /customer-verify-otp/');
    final response = await ApiService.verifyRegisterOtp(
      phoneNumber: model.phoneNumber,
      otp: model.otpCode,
    );
    debugPrint('[OtpController] signup verify SUCCESS — ${response['message']}');

    Get.snackbar(
      'Account Created',
      response['message']?.toString() ?? 'Now logging you in...',
    );

    isTransitioningToLogin.value = true;
    _clearDigits();

    debugPrint('[OtpController] signup verified — kicking off login OTP');
    final loginResponse = await ApiService.login(phoneNumber: model.phoneNumber);
    final loginOtp = loginResponse['otp']?.toString();

    debugPrint('┌─────────────────────────────────┐');
    debugPrint('│  POST-SIGNUP LOGIN OTP: $loginOtp');
    debugPrint('└─────────────────────────────────┘');

    isTransitioningToLogin.value = false;
    isLoading.value = false;
    flow.value = OtpFlow.login;
    resendCooldown.value = 0;

    if (loginOtp != null && loginOtp.length == 4) {
      _maybeAutoFill(loginOtp);
    }

    Get.snackbar(
      'OTP Sent',
      'Enter the code to finish logging in',
      backgroundColor: const Color(0xFF12914C),
      colorText: Colors.white,
      duration: const Duration(seconds: 6),
      snackPosition: SnackPosition.TOP,
    );
    // User now sees the same screen in login mode and taps Verify again.
  }

  Future<void> _verifyLoginOtp() async {
    debugPrint('[OtpController] hitting /customer-login-verify/');
    final response = await ApiService.verifyLoginOtp(
      phoneNumber: model.phoneNumber,
      otp: model.otpCode,
    );
    final customerId = response['customer_id'] as int?;
    debugPrint('[OtpController] login verify SUCCESS — customer_id: $customerId');

    await SessionManager.saveSession(
      accessToken: response['access'] as String,
      refreshToken: response['refresh'] as String,
      customerId: customerId,
      phoneNumber: model.phoneNumber,
    );

    isLoading.value = false;
    Get.snackbar(
      'Verified',
      response['message']?.toString() ?? 'Logged in successfully!',
    );

    // Fold any guest-cart items into the now-authenticated server cart
    // before handing control back, so checkout continues with the same
    // items the guest had rather than an empty server cart.
    if (Get.isRegistered<CartController>()) {
      await Get.find<CartController>().mergeGuestCartAfterLogin();
    }

    if (isModal) {
      debugPrint('[OtpController] modal flow — popping true to caller');
      Get.back(result: true);
    } else {
      debugPrint('[OtpController] non-modal flow — navigating to /home');
      Get.offAllNamed('/home');
    }
  }

  Future<void> resendOtp() async {
    debugPrint(
      '[OtpController] resendOtp() called — cooldown: ${resendCooldown.value}',
    );
    if (resendCooldown.value > 0) return;

    try {
      if (flow.value == OtpFlow.signup) {
        debugPrint(
          '[OtpController] resend for signup — calling /customer-resend-otp/',
        );
        final response = await ApiService.resendOtp(
          phoneNumber: model.phoneNumber,
        );

        final message =
            response['message']?.toString() ??
            'A new code has been sent to ${model.maskedPhoneNumber}';
        final otp = response['otp']?.toString();

        debugPrint('[OtpController] resend-otp response message: $message');

        if (otp != null && otp.length == 4) {
          _maybeAutoFill(otp);
        }

        Get.snackbar(
          'OTP Sent',
          message,
          backgroundColor: const Color(0xFF12914C),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      } else {
        debugPrint(
          '[OtpController] resend for login — re-calling /customer-login/',
        );
        final response = await ApiService.login(phoneNumber: model.phoneNumber);
        final otp = response['otp']?.toString() ?? 'N/A';

        debugPrint('┌─────────────────────────────────┐');
        debugPrint('│  RESEND LOGIN OTP: $otp          ');
        debugPrint('└─────────────────────────────────┘');

        if (otp.length == 4) {
          _maybeAutoFill(otp);
        }

        Get.snackbar(
          'OTP Sent',
          'Your new OTP is: $otp',
          backgroundColor: const Color(0xFF12914C),
          colorText: Colors.white,
          duration: const Duration(seconds: 8),
          snackPosition: SnackPosition.TOP,
        );
      }

      resendCooldown.value = 30;
      _startCooldown();
    } on ApiException catch (e) {
      debugPrint('[OtpController] resend ApiException → ${e.message}');
      Get.snackbar('Resend Failed', e.message);
    } catch (e) {
      debugPrint('[OtpController] resend unexpected error → $e');
      Get.snackbar('Resend Failed', 'Something went wrong. Please try again.');
    }
  }

  String get formattedCooldown {
    final minutes = (resendCooldown.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (resendCooldown.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startCooldown() async {
    debugPrint('[OtpController] cooldown started — 30s');
    while (resendCooldown.value > 0) {
      await Future.delayed(const Duration(seconds: 1));
      resendCooldown.value--;
    }
    debugPrint('[OtpController] cooldown ended');
  }

  @override
  void onClose() {
    debugPrint('[OtpController] onClose — flow: ${flow.value}');
    for (final c in digitControllers) c.dispose();
    for (final f in digitFocusNodes) f.dispose();
    super.onClose();
  }
}