import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/circularbackbutton.dart';
import 'package:brikle/AppStyle/custombutton.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/LoginOtp/Controller/loginotp_provider.dart';
import 'package:brikle/LoginOtp/View/otpdigitbox.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OtpView extends StatefulWidget {
  final String phoneNumber;
  final String countryCode;
  final OtpFlow flow;
  final String? prefillOtp;

  const OtpView({
    super.key,
    required this.phoneNumber,
    required this.flow,
    this.countryCode = '+91',
    this.prefillOtp,
  });

  @override
  State<OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<OtpView> {
  late final OtpController controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<OtpController>(tag: widget.phoneNumber)) {
      Get.delete<OtpController>(tag: widget.phoneNumber, force: true);
    }
    controller = Get.put(
      OtpController(
        phoneNumber: widget.phoneNumber,
        countryCode: widget.countryCode,
        flow: widget.flow,
        prefillOtp: widget.prefillOtp,
      ),
      tag: widget.phoneNumber,
    );
  }

  @override
  void dispose() {
    Get.delete<OtpController>(tag: widget.phoneNumber, force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    // back button pinned at top; rest of content
                    // centered in the remaining space — matches Figma
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Responsive.space(context, 8)),
                      const CircularBackButton(),

                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // "Verify Phone" — dark/bold, matches
                              // Login page's "Welcome Back" style
                              Text(
                                "Verify Phone",
                                style: AppTextStyles.welcomeBackTitle(context),
                              ),
                              SizedBox(height: Responsive.space(context, 8)),

                              Text(
                                "Enter the 4-digit code sent to your phone.",
                                style: AppTextStyles.loginSubtitle(context),
                              ),
                              SizedBox(height: Responsive.space(context, 4)),

                              // Full number, bold green — matches Figma
                              Text(
                                controller.model.maskedPhoneNumber,
                                style: AppTextStyles.loginSubtitle(context)
                                    .copyWith(
                                      color: AppColors.primaryGreen,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              SizedBox(height: Responsive.space(context, 32)),

                              // 4 OTP digit boxes, centered
                              SizedBox(
                                width: double.infinity,
                                child: Obx(
                                  () => Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(4, (index) {
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: index < 3
                                              ? Responsive.space(context, 10)
                                              : 0,
                                        ),
                                        child: OtpDigitBox(
                                          controller: controller
                                              .digitControllers[index],
                                          focusNode:
                                              controller.digitFocusNodes[index],
                                          isValid: controller.isOtpValid.value,
                                          onChanged: (value) => controller
                                              .onDigitChanged(index, value),
                                        ),
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              SizedBox(height: Responsive.space(context, 24)),

                              // Timer + Resend OTP, stacked & centered
                              SizedBox(
                                width: double.infinity,
                                child: Obx(
                                  () => Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      if (controller.resendCooldown.value >
                                          0) ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.access_time_rounded,
                                              size: Responsive.font(
                                                context,
                                                16,
                                              ),
                                              color: AppColors.textGray,
                                            ),
                                            SizedBox(
                                              width: Responsive.space(
                                                context,
                                                4,
                                              ),
                                            ),
                                            Text(
                                              controller.formattedCooldown,
                                              style: AppTextStyles.termsText(
                                                context,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: Responsive.space(context, 8),
                                        ),
                                      ],
                                      GestureDetector(
                                        onTap:
                                            controller.resendCooldown.value == 0
                                            ? controller.resendOtp
                                            : null,
                                        child: Text(
                                          'Resend OTP',
                                          style: AppTextStyles.linkText(context)
                                              .copyWith(
                                                color:
                                                    controller
                                                            .resendCooldown
                                                            .value >
                                                        0
                                                    ? AppColors.textGray
                                                    : AppColors.primaryGreen,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: Responsive.space(context, 28)),

                              // "Verify"
                              Obx(
                                () => CustomButton(
                                  label: 'Verify',
                                  isLoading: controller.isLoading.value,
                                  onPressed: controller.verifyOtp,
                                ),
                              ),
                            ],
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
