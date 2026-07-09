import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appsizes.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';

/// Reusable primary CTA button used across the app.
/// Figma spec: height 56, border-radius 16, background primaryGreen.
class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: Responsive.height(context, AppSizes.buttonHeight),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? SizedBox(
                width: Responsive.space(context, 22),
                height: Responsive.space(context, 22),
                child: const CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label, style: AppTextStyles.buttonText(context)),
      ),
    );
  }
}
