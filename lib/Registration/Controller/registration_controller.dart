import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Registration/Model/registretion_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// CONTROLLER — owns state for the Signup/Register screen.
class SignupController extends GetxController {
  final SignupModel model = SignupModel();

  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController address1Controller = TextEditingController();
  final TextEditingController address2Controller = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  final TextEditingController gstController = TextEditingController();

  final RxBool isFullNameValid = true.obs;
  final RxBool isPhoneValid = true.obs;
  final RxBool isAddress1Valid = true.obs;
  final RxBool isAddress2Valid = true.obs;
  final RxBool isPincodeValid = true.obs;
  final RxBool isGstValid = true.obs;
  final Rx<CustomerType> customerType = CustomerType.individual.obs;
  final RxBool isLoading = false.obs;
  String lastOtp = '';

  bool get isGstRequired => customerType.value == CustomerType.contractor;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[SignupController] onInit');
  }

  void onFullNameChanged(String value) {
    model.fullName = value;
    if (!isFullNameValid.value) isFullNameValid.value = model.isFullNameValid;
  }

  void onPhoneChanged(String value) {
    model.phoneNumber = value;
    if (!isPhoneValid.value) isPhoneValid.value = model.isPhoneValid;
  }

  void onAddress1Changed(String value) {
    model.streetAddress1 = value;
    if (!isAddress1Valid.value)
      isAddress1Valid.value = model.isStreetAddress1Valid;
  }

  void onAddress2Changed(String value) {
    model.streetAddress2 = value;
    if (!isAddress2Valid.value)
      isAddress2Valid.value = model.isStreetAddress2Valid;
  }

  void onPincodeChanged(String value) {
    model.pincode = value;
    if (!isPincodeValid.value) isPincodeValid.value = model.isPincodeValid;
  }

  void onGstChanged(String value) {
    model.gstNumber = value;
    if (!isGstValid.value) isGstValid.value = model.isGstValid;
  }

  void onCustomerTypeChanged(CustomerType type) {
    customerType.value = type;
    model.customerType = type;
    // Re-validate GST immediately when switching type — e.g. switching away
    // from contractor should clear any stale GST error, switching to
    // contractor with empty GST should show one if they try to submit.
    isGstValid.value = model.isGstValid;
  }

  // In SignupController, alongside customerType:
  final RxString countryCode = '+91'.obs;

  void onCountryCodeChanged(String code) {
    countryCode.value = code;
    model.countryCode = code;
  }

  Future<bool> createAccount() async {
    debugPrint('[SignupController] createAccount() called');

    isFullNameValid.value = model.isFullNameValid;
    isPhoneValid.value = model.isPhoneValid;
    isAddress1Valid.value = model.isStreetAddress1Valid;
    isAddress2Valid.value = model.isStreetAddress2Valid;
    isPincodeValid.value = model.isPincodeValid;
    isGstValid.value = model.isGstValid;

    if (!model.isFormValid) {
      debugPrint('[SignupController] validation FAILED — form invalid');
      return false;
    }

    debugPrint('[SignupController] validation passed — calling register API');
    isLoading.value = true;

    try {
      final response = await ApiService.register(
        fullName: model.fullName,
        phoneNumber: model.phoneNumber,
        pincode: model.pincode,
        streetAddress1: model.streetAddress1,
        streetAddress2: model.streetAddress2,
        customerType: model.customerType.apiValue,
        gstNumber: model.isGstRequired
            ? model.gstNumber.trim().toUpperCase()
            : null,
      );

      final otp = response['otp']?.toString() ?? 'N/A';
      lastOtp = otp;

      debugPrint('┌─────────────────────────────────┐');
      debugPrint('│  SIGNUP OTP: $otp                ');
      debugPrint('│  Phone: ${response['phone_number']} ');
      debugPrint('└─────────────────────────────────┘');

      isLoading.value = false;

      Get.snackbar(
        'OTP Sent',
        'Your OTP is: $otp',
        backgroundColor: const Color(0xFF1B8D2D),
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        snackPosition: SnackPosition.TOP,
      );

      return true;
    } on ApiException catch (e) {
      debugPrint('[SignupController] ApiException → ${e.message}');
      isLoading.value = false;
      Get.snackbar('Signup Failed', e.message);
      return false;
    } catch (e) {
      debugPrint('[SignupController] unexpected error → $e');
      isLoading.value = false;
      Get.snackbar('Signup Failed', 'Something went wrong. Please try again.');
      return false;
    }
  }

  @override
  void onClose() {
    fullNameController.dispose();
    phoneController.dispose();
    address1Controller.dispose();
    address2Controller.dispose();
    pincodeController.dispose();
    gstController.dispose();
    super.onClose();
  }
}
