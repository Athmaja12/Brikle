import 'package:flutter/material.dart';

/// Single source of truth for responsive scaling across the app.
///
/// Figma frames were designed at 375px width (standard iPhone frame).
/// We scale font sizes / paddings / heights proportionally to the
/// device's actual width, clamped so things don't blow up on tablets
/// or shrink too far on tiny phones.
class Responsive {
  Responsive._();

  static const double _designWidth = 375.0;

  // Breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileMaxWidth && width < tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  /// Raw scale factor vs the 375px Figma frame, clamped to a sane range
  /// so text/paddings don't shrink below 85% on tiny phones or balloon
  /// past 130% on large tablets (where we want generous whitespace, not
  /// giant fonts).
  static double scaleFactor(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final raw = width / _designWidth;
    return raw.clamp(0.85, 1.3);
  }

  /// Scales a font size from the Figma spec to the current device.
  static double font(BuildContext context, double figmaSize) {
    return figmaSize * scaleFactor(context);
  }

  /// Scales a spacing/padding value from the Figma spec to the current device.
  static double space(BuildContext context, double figmaValue) {
    return figmaValue * scaleFactor(context);
  }

  /// Scales a fixed component height (e.g. button height) from Figma.
  static double height(BuildContext context, double figmaValue) {
    return figmaValue * scaleFactor(context);
  }

  /// Caps content width on large screens (tablet/desktop) so layouts
  /// don't stretch edge-to-edge — centers a max-width column instead.
  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 480;
    if (isTablet(context)) return 420;
    return double.infinity;
  }
}