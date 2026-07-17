import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/tokenrefresh.dart';
import 'package:brikle/LoginOtp/Model/otp_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum OtpFlow { signup, login }

class OtpController extends GetxController {
  late final OtpModel model;
  final OtpFlow flow;
  final String? prefillOtp;

  final List<TextEditingController> digitControllers = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final List<FocusNode> digitFocusNodes = List.generate(4, (_) => FocusNode());

  final RxBool isOtpValid = true.obs;
  final RxBool isLoading = false.obs;
  final RxInt resendCooldown = 0.obs;

  OtpController({
    required String phoneNumber,
    String countryCode = '+91',
    this.flow = OtpFlow.signup,
    this.prefillOtp,
  }) {
    model = OtpModel(phoneNumber: phoneNumber, countryCode: countryCode);
  }
  @override
  void onInit() {
    super.onInit();
    debugPrint(
      '[OtpController] onInit — flow: $flow, phone: ${model.phoneNumber}',
    );

    if (prefillOtp != null && prefillOtp!.length == 4) {
      debugPrint('[OtpController] scheduling auto-fill: $prefillOtp');
      // Defer to next frame so digit TextFields are mounted first
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (int i = 0; i < 4; i++) {
          digitControllers[i].text = prefillOtp![i];
        }
        _syncOtpCode();
        debugPrint(
          '[OtpController] auto-fill done — otpCode: "${model.otpCode}"',
        );
      });
    }
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
      '[OtpController] verifyOtp() called — otpCode: "${model.otpCode}", flow: $flow',
    );

    if (!model.isOtpComplete) {
      debugPrint('[OtpController] OTP incomplete — showing error');
      isOtpValid.value = false;
      return;
    }

    isLoading.value = true;
    debugPrint('[OtpController] calling verify API...');

    try {
      final Map<String, dynamic> response;
      int? customerId;

      if (flow == OtpFlow.signup) {
        debugPrint('[OtpController] hitting /customer-verify-otp/');
        response = await ApiService.verifyRegisterOtp(
          phoneNumber: model.phoneNumber,
          otp: model.otpCode,
        );
      } else {
        debugPrint('[OtpController] hitting /customer-login-verify/');
        response = await ApiService.verifyLoginOtp(
          phoneNumber: model.phoneNumber,
          otp: model.otpCode,
        );
        customerId = response['customer_id'] as int?;
        debugPrint('[OtpController] customer_id: $customerId');
      }

      debugPrint(
        '[OtpController] verify SUCCESS — message: ${response['message']}',
      );
      isLoading.value = false;

      Get.snackbar(
        'Verified',
        response['message']?.toString() ?? 'Verified successfully!',
      );

      if (flow == OtpFlow.signup) {
        debugPrint('[OtpController] signup flow — saving session + going Home');
        // verifyRegisterOtp already returns access + refresh tokens

        debugPrint("===== VERIFY RESPONSE =====");
        debugPrint(response.toString());
        debugPrint("ACCESS  : ${response['access']}");
        debugPrint("REFRESH : ${response['refresh']}");
        debugPrint("===========================");

        await SessionManager.saveSession(
          accessToken: response['access'] as String,
          refreshToken: response['refresh'] as String,
          phoneNumber: model.phoneNumber,
        );
        debugPrint('[OtpController] signup session saved — going to /home');
        Get.offAllNamed('/home'); // ← skips login entirely
      } else {
        debugPrint(
          '[OtpController] login flow — saving session + navigating Home',
        );
        await SessionManager.saveSession(
          accessToken: response['access'] as String,
          refreshToken: response['refresh'] as String,
          customerId: customerId,
          phoneNumber: model.phoneNumber,
        );
        debugPrint('[OtpController] session saved — going to /home');
        Get.offAllNamed('/home');
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

  Future<void> resendOtp() async {
    debugPrint(
      '[OtpController] resendOtp() called — cooldown: ${resendCooldown.value}',
    );
    if (resendCooldown.value > 0) return;

    try {
      if (flow == OtpFlow.signup) {
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

        // Auto-fill only if backend actually returns the otp (dev/test mode)
        if (otp != null && otp.length == 4) {
          for (int i = 0; i < 4; i++) {
            digitControllers[i].text = otp[i];
          }
          _syncOtpCode();
          debugPrint(
            '[OtpController] resend auto-fill done — otpCode: "${model.otpCode}"',
          );
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
          for (int i = 0; i < 4; i++) {
            digitControllers[i].text = otp[i];
          }
          _syncOtpCode();
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

  /// mm:ss for the countdown display, e.g. "00:30"
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
    debugPrint('[OtpController] onClose — flow: $flow');
    for (final c in digitControllers) c.dispose();
    for (final f in digitFocusNodes) f.dispose();
    super.onClose();
  }
}
