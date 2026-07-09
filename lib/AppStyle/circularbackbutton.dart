import 'package:brikle/AppStyle/appcolors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CircularBackButton extends StatelessWidget {
  final VoidCallback? onTap;

  const CircularBackButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? SystemNavigator.pop,
      child: Container(
        height: 52,
        width: 52,
        decoration: const BoxDecoration(
          color: AppColors.primaryGreen,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
