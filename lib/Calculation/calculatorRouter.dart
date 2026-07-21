// lib/Calculation/calculator_router.dart

import 'package:brikle/Calculation/View/calculations_Page.dart';
import 'package:brikle/Calculation/View/cementcalculation_page.dart';
import 'package:brikle/Calculation/comingscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CalculatorRouter {
  static void openBySlug(BuildContext context, String slug) {
    switch (slug) {
      case 'paint-calculator':
        Get.to(() => const PaintCalculatorScreen());
        break;

      case 'cement-calculator':
        Get.to(() => const CementCalculationPage());
        break;

      case 'steel-weight-calculator':
        // Use named route navigation
        Get.toNamed('/steel-calculator');
        break;

      case 'aac-block-calculator':
        Get.toNamed('/block-calculator');
        break;

      case 'waterproofing-calculator':
        Get.toNamed('/waterproofing-calculator');
        break;

      default:
        Get.to(() => const CalculatorComingSoonScreen(title: 'Calculator'));
    }
  }
}