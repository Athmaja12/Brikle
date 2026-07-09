import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/LoginScreen/Controller/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Reusable phone number field with a fixed country-code prefix.
/// Matches Login screen Figma spec: h=48, radius=12, border=#E2E2E2,
/// bg=white, shadow=0px 4px 12px rgba(0,0,0,0.04).
class CustomPhoneField extends StatelessWidget {
  final LoginController controller;

  const CustomPhoneField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: Responsive.height(context, 48),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.isPhoneValid.value
                    ? AppColors.inputBorder
                    : AppColors.errorRed,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                SizedBox(width: Responsive.space(context, 16)),
                Icon(
                  Icons.phone_iphone_rounded,
                  size: Responsive.space(context, 20),
                  color: AppColors.textGray,
                ),
                SizedBox(width: Responsive.space(context, 8)),
                Text(
                  controller.model.countryCode,
                  style: AppTextStyles.inputText(context),
                ),
                SizedBox(width: Responsive.space(context, 8)),
                Container(width: 1, height: 20, color: AppColors.inputBorder),
                SizedBox(width: Responsive.space(context, 8)),
                Expanded(
                  child: TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    style: AppTextStyles.inputText(context),
                    onChanged: controller.onPhoneChanged,
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: 'Phone Number',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                SizedBox(width: Responsive.space(context, 12)),
              ],
            ),
          ),
          if (!controller.isPhoneValid.value)
            Padding(
              padding: EdgeInsets.only(
                top: 6,
                left: Responsive.space(context, 4),
              ),
              child: Text(
                'Enter a valid 10-digit phone number',
                style: AppTextStyles.errorText(context),
              ),
            ),
        ],
      ),
    );
  }
}
