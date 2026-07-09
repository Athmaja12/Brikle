import 'package:flutter/material.dart';

/// Colors extracted from the latest Figma spec (onboarding flow).
class AppColors {
  AppColors._();

  // rgba(27, 141, 45, 1) — primary CTA / active states
  static const Color primaryGreen = Color(0xFF1B8D2D);

  // rgba(26, 28, 28, 1) — headline text (e.g. "Everything for Construction")
  static const Color textDark = Color(0xFF1A1C1C);

  // rgba(63, 74, 60, 1) — body/subtitle text
  // NOTE: Figma dev-mode listed this under "background" on a text node,
  // which is a known export quirk — it's actually the text fill color.
  static const Color textMuted = Color(0xFF3F4A3C);

  static const Color textGray = Color(
    0xFF6B7280,
  ); // kept for old screens using it

  static const Color background = Colors.white;
  static const Color skipPillBg = Colors.white;
  static const Color dotInactive = Color(0xFFD9D9D9);

  static const Color inputText = Color(0xFF1F2937);
  static const Color fieldBorder = Color.fromRGBO(27, 141, 45, 0.75);
  static const Color fieldFill = Color(0xFFF9FAFB);
  static const Color errorRed = Color(0xFFDC2626);

  static const Color inputBorder = Color(
    0xFFE2E2E2,
  ); // rgba(226,226,226,1) — Login screen field border
}
