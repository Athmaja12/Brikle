import 'package:get/get.dart';
import 'package:flutter/material.dart';

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String imageAsset;
  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });
}

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingPageData> pages = const [
    OnboardingPageData(
      title: 'Everything for Construction',
      subtitle:
          'Your one-stop shop for all building materials. Professional grade, delivered to your site.',
      imageAsset: 'assets/images/Construction Materials.jpg',
    ),
    // TODO: replace with real slide 2 copy + asset
    OnboardingPageData(
      title: 'Fast, Reliable Delivery',
      subtitle:
          'Get materials delivered straight to your site, on schedule, every time.',
      imageAsset: 'assets/images/image1.png',
    ),
    // TODO: replace with real slide 3 copy + asset
    OnboardingPageData(
      title: 'Trusted by Builders',
      subtitle:
          'Thousands of contractors rely on us for quality materials every day.',
      imageAsset: 'assets/images/onboarding1.png',
    ),
  ];

  bool get isLastPage => currentPage.value == pages.length - 1;

  void onPageChanged(int index) => currentPage.value = index;

  void next() {
    if (isLastPage) {
      _goToAuth();
    } else {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void skip() => _goToAuth();

  void _goToAuth() {
    // TODO: check stored login/token here.
    // final hasCredentials = StorageService.hasToken();
    // Get.offAllNamed(hasCredentials ? '/login' : '/register');
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
