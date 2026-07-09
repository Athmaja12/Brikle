import 'package:brikle/AppStyle/appcolors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Consistent circular back button used across all detail/sub pages.
class AppBackButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  const AppBackButton({super.key, this.size = 40, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Get.back(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: size * 0.42,
          color: AppColors.inputText,
        ),
      ),
    );
  }
}