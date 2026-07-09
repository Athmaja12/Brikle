import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/circularbackbutton.dart';
import 'package:brikle/AppStyle/custombutton.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/LoginOtp/Controller/loginotp_provider.dart';
import 'package:brikle/LoginOtp/View/otpdigitbox.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// VIEW — pure UI. Reads/writes state only through OtpController.
/// Accepts [flow] so the controller knows which endpoint to hit and
/// where to navigate after a successful verification.
class OtpView extends StatelessWidget {
  final String phoneNumber;
  final String countryCode;
  final OtpFlow flow;

  const OtpView({
    super.key,
    required this.phoneNumber,
    required this.flow,
    this.countryCode = '+91',
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OtpController>(tag: phoneNumber)) {
      Get.put(
        OtpController(
          phoneNumber: phoneNumber,
          countryCode: countryCode,
          flow: flow,
        ),
        tag: phoneNumber,
      );
    }
    final controller = Get.find<OtpController>(tag: phoneNumber);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.space(context, 24),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Responsive.space(context, 1)),
                      const CircularBackButton(),
                      SizedBox(height: Responsive.space(context, 24)),

                      Text("Confirm it's you", style: AppTextStyles.welcomeBack(context)),
                      SizedBox(height: Responsive.space(context, 8)),

                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.loginSubtitle(context),
                          children: [
                            const TextSpan(text: 'Enter the OTP Code we sent to\n'),
                            TextSpan(text: controller.model.maskedPhoneNumber),
                          ],
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 36)),

                      // OTP digit boxes
                      SizedBox(
                        width: double.infinity,
                        child: Obx(
                          () => Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(4, (index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < 3 ? Responsive.space(context, 10) : 0,
                                ),
                                child: OtpDigitBox(
                                  controller: controller.digitControllers[index],
                                  focusNode: controller.digitFocusNodes[index],
                                  isValid: controller.isOtpValid.value,
                                  onChanged: (value) =>
                                      controller.onDigitChanged(index, value),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 28)),

                      // Calls controller.verifyOtp() which:
                      //   signup flow -> navigates to LoginView
                      //   login flow  -> saves session + navigates to Home
                      Obx(() => CustomButton(
                        label: 'Continue',
                        isLoading: controller.isLoading.value,
                        onPressed: controller.verifyOtp,
                      )),

                      SizedBox(height: Responsive.space(context, 8)),

                      // Resend link with 30s cooldown
                      Obx(
                        () => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Didn't Receive the Code ? ", style: AppTextStyles.termsText(context)),
                            GestureDetector(
                              onTap: controller.resendOtp,
                              child: Text(
                                controller.resendCooldown.value > 0
                                    ? 'Resend (${controller.resendCooldown.value}s)'
                                    : 'Resend',
                                style: AppTextStyles.linkText(context).copyWith(
                                  color: controller.resendCooldown.value > 0
                                      ? AppColors.textGray
                                      : AppColors.primaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: Responsive.space(context, 32)),
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: AppTextStyles.termsText(context),
                              children: [
                                const TextSpan(text: 'By clicking Continue, you agree to our '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Text('Terms of Service', style: AppTextStyles.linkText(context)),
                                ),
                                const TextSpan(text: ' and '),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Text('Privacy Policy', style: AppTextStyles.linkText(context)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 16)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}