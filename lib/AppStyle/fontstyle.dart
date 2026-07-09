import 'package:flutter/material.dart';

/// Centralized text style scale for the app.
/// If you already have a fontstyles.dart in AppStyle/, ignore this file and
/// just make sure your import path in onboardingscreen.dart matches it —
/// this version exists only to match the heading3 / bodySmall / bodyMedium
/// calls used in OnboardingScreen.
class FontStyles {
  FontStyles._();

  static const String _fontFamily = 'Manrope';

  static TextStyle _base({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  static TextStyle heading1({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w800,
    double? height,
  }) => _base(size: 28, weight: weight, color: color, height: height);

  static TextStyle heading2({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w800,
    double? height,
  }) => _base(size: 24, weight: weight, color: color, height: height);

  static TextStyle heading3({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w700,
    double? height,
  }) => _base(size: 20, weight: weight, color: color, height: height);

  static TextStyle bodyLarge({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => _base(size: 16, weight: weight, color: color, height: height);

  static TextStyle bodyMedium({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => _base(size: 14, weight: weight, color: color, height: height);

  static TextStyle bodySmall({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => _base(size: 12, weight: weight, color: color, height: height);

  static TextStyle caption({
    Color color = Colors.black,
    FontWeight weight = FontWeight.w400,
    double? height,
  }) => _base(size: 11, weight: weight, color: color, height: height);
}