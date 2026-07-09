import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/SplashScreen/Controller/splashscreen_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SplashController()); // starts the nav timer on first build
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // TODO: replace with your logo asset:
            // Image.asset('assets/images/logo.png', width: 90, height: 90)
            const Icon(Icons.water_drop_rounded, size: 90, color: Colors.white),
            const SizedBox(height: 12),
            Text('Brikle', style: AppTextStyles.splashAppName(context)),
          ],
        ),
      ),
    );
  }
}
