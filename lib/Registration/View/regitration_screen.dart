import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/circularbackbutton.dart';
import 'package:brikle/AppStyle/custombutton.dart';
import 'package:brikle/AppStyle/customiconfield.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/LoginOtp/Controller/loginotp_provider.dart';
import 'package:brikle/LoginOtp/View/logiotppage.dart';
import 'package:brikle/LoginScreen/View/loginscreen.dart';
import 'package:brikle/Registration/Controller/registration_controller.dart';
import 'package:brikle/Registration/Model/registretion_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignupView extends GetView<SignupController> {
  /// Propagated from LoginView so the resulting OtpView knows whether
  /// to pop(true) back up to AuthGate on success.
  final bool isModal;

  const SignupView({super.key, this.isModal = false});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SignupController>()) {
      Get.put(SignupController());
    }

    Future<void> handleCreateAccount() async {
      final success = await controller.createAccount();
      if (!success) return;
      if (!context.mounted) return;

      final otpResult = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => OtpView(
            phoneNumber: controller.phoneController.text,
            countryCode: controller.model.countryCode,
            flow: OtpFlow.signup,
            prefillOtp: controller.lastOtp,
            isModal: isModal,
          ),
        ),
      );

      if (!context.mounted) return;

      if (isModal && otpResult == true) {
        Navigator.pop(context, true);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, 24),
                    ).copyWith(top: Responsive.space(context, 16)),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: CircularBackButton(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LoginView(
                                checkoutReason:
                                    isModal ? 'Please log in to continue' : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: Responsive.space(context, 16)),

                  Center(
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'B',
                            style: AppTextStyles.brikleLogoAccent(context),
                          ),
                          TextSpan(
                            text: 'rikle',
                            style: AppTextStyles.brikleLogoDark(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, 32)),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, 24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.welcomeBackTitle(context),
                        ),
                        SizedBox(height: Responsive.space(context, 6)),
                        Text(
                          "Let's set up your account",
                          textAlign: TextAlign.center,
                          style: AppTextStyles.loginSubtitleCentered(context),
                        ),
                        SizedBox(height: Responsive.space(context, 28)),

                        Text(
                          'Account Type',
                          style: AppTextStyles.fieldLabel(context),
                        ),
                        SizedBox(height: Responsive.space(context, 8)),
                        Obx(
                          () => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.inputBorder),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<CustomerType>(
                                value: controller.customerType.value,
                                isExpanded: true,
                                hint: Text(
                                  'Select Account Type',
                                  style: TextStyle(color: AppColors.textDark),
                                ),
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textDark,
                                ),
                                dropdownColor: AppColors.background,
                                borderRadius: BorderRadius.circular(12),
                                elevation: 8,
                                items: CustomerType.values.map((type) {
                                  final icon = _getIconForType(type);
                                  return DropdownMenuItem<CustomerType>(
                                    value: type,
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 20,
                                          color: AppColors.primaryGreen,
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          type.label,
                                          style: TextStyle(
                                            color: AppColors.textDark,
                                            fontSize: Responsive.font(
                                              context,
                                              15,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    controller.onCustomerTypeChanged(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: Responsive.space(context, 20)),

                        _FieldBlock(
                          label: 'Full Name',
                          child: Obx(
                            () => CustomIconField(
                              controller: controller.fullNameController,
                              icon: Icons.person_outline,
                              hintText: 'Full Name',
                              isValid: controller.isFullNameValid.value,
                              errorText: 'Please enter your full name',
                              onChanged: controller.onFullNameChanged,
                            ),
                          ),
                        ),

                        _FieldBlock(
                          label: 'Phone Number',
                          child: Obx(
                            () => CustomIconField(
                              controller: controller.phoneController,
                              icon: Icons.call_outlined,
                              hintText: 'Phone Number',
                              keyboardType: TextInputType.phone,
                              isValid: controller.isPhoneValid.value,
                              errorText: 'Enter a valid 10-digit phone number',
                              onChanged: controller.onPhoneChanged,
                            ),
                          ),
                        ),

                        _FieldBlock(
                          label: 'Street Address 1',
                          child: Obx(
                            () => CustomIconField(
                              controller: controller.address1Controller,
                              icon: Icons.location_on_outlined,
                              hintText: 'e.g. Building No 4B, Phase 1',
                              isValid: controller.isAddress1Valid.value,
                              errorText: 'Please enter your street address',
                              onChanged: controller.onAddress1Changed,
                            ),
                          ),
                        ),

                        _FieldBlock(
                          label: 'Street Address 2',
                          child: Obx(
                            () => CustomIconField(
                              controller: controller.address2Controller,
                              icon: Icons.location_city_outlined,
                              hintText: 'e.g. Infopark Kakkanad',
                              isValid: controller.isAddress2Valid.value,
                              errorText: 'Please enter the second address line',
                              onChanged: controller.onAddress2Changed,
                            ),
                          ),
                        ),

                        _FieldBlock(
                          label: 'Pincode',
                          bottomSpacing: 0,
                          child: Obx(
                            () => CustomIconField(
                              controller: controller.pincodeController,
                              icon: Icons.pin_drop_outlined,
                              hintText: 'Enter 6-digit Pincode',
                              keyboardType: TextInputType.number,
                              isValid: controller.isPincodeValid.value,
                              errorText: 'Enter a valid 6-digit pincode',
                              onChanged: controller.onPincodeChanged,
                            ),
                          ),
                        ),

                        Obx(() {
                          if (!controller.isGstRequired) {
                            return const SizedBox.shrink();
                          }
                          return _FieldBlock(
                            label: 'GST Number',
                            bottomSpacing: 0,
                            child: CustomIconField(
                              controller: controller.gstController,
                              icon: Icons.receipt_long_outlined,
                              hintText: 'e.g. 32ABCDE1234F1Z5',
                              isValid: controller.isGstValid.value,
                              errorText: 'Enter a valid GST number',
                              onChanged: controller.onGstChanged,
                            ),
                          );
                        }),

                        SizedBox(height: Responsive.space(context, 28)),
                        Obx(
                          () => CustomButton(
                            label: 'Create Account',
                            isLoading: controller.isLoading.value,
                            onPressed: handleCreateAccount,
                          ),
                        ),

                        SizedBox(height: Responsive.space(context, 20)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account?  ',
                              style: AppTextStyles.termsText(context),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LoginView(checkoutReason: isModal
                                            ? 'Please log in to continue'
                                            : null),
                                  ),
                                );
                              },
                              child: Text(
                                'Login',
                                style: AppTextStyles.linkText(context),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Responsive.space(context, 24)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(CustomerType type) {
    switch (type) {
      case CustomerType.individual:
        return Icons.person_outline_rounded;
      case CustomerType.contractor:
        return Icons.engineering_outlined;
      case CustomerType.reseller:
        return Icons.storefront_outlined;
      case CustomerType.applicator:
        return Icons.design_services_outlined;
      case CustomerType.seller:
        return Icons.sell_outlined;
    }
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;
  final double bottomSpacing;

  const _FieldBlock({
    required this.label,
    required this.child,
    this.bottomSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel(context)),
        SizedBox(height: Responsive.space(context, 8)),
        child,
        SizedBox(height: Responsive.space(context, bottomSpacing)),
      ],
    );
  }
}