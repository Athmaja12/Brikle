import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appsizes.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/OnboardingScreens/Controller/onboarding_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: controller.pageController,
                    itemCount: controller.pages.length,
                    onPageChanged: controller.onPageChanged,
                    itemBuilder: (context, index) {
                      final page = controller.pages[index];
                      return Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Image.asset(
                            page.imageAsset,
                            height: AppSizes.onboardingImageHeight,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.construction_rounded,
                              size: 120,
                              color: Colors.black26,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Obx(() {
                      final isLast = controller.isLastPage;
                      return AnimatedOpacity(
                        opacity: isLast ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: GestureDetector(
                          onTap: controller.skip,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSizes.skipHPadding,
                              vertical: AppSizes.skipVPadding,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.skipPillBg,
                              borderRadius: BorderRadius.circular(
                                AppSizes.skipPillRadius,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'Skip',
                              style: AppTextStyles.skipText(context),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            Obx(() {
              final page = controller.pages[controller.currentPage.value];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.titleMaxWidth,
                      ),
                      child: Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingTitle(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppSizes.subtitleMaxWidth,
                      ),
                      child: Text(
                        page.subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.onboardingSubtitle(context),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
            Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(controller.pages.length, (index) {
                  final active = controller.currentPage.value == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(
                      horizontal: AppSizes.dotGap / 2,
                    ),
                    width: active ? AppSizes.dotActiveWidth : AppSizes.dotSize,
                    height: AppSizes.dotSize,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primaryGreen
                          : AppColors.dotInactive,
                      borderRadius: BorderRadius.circular(AppSizes.dotSize / 2),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSizes.buttonRadius,
                        ),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      controller.isLastPage ? 'Get Started' : 'Next',
                      style: AppTextStyles.buttonText(context),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
