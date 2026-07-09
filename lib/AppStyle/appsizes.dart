/// Centralized dimensions/spacing pulled from Figma dev-mode specs.
/// Raw px values below; wrap with Responsive.* at call sites like your
/// other styles do.
class AppSizes {
  AppSizes._();

  // Screen
  static const double screenHPadding = 24;

  // Onboarding illustration
  static const double onboardingImageHeight = 320;

  // Buttons
  static const double buttonHeight = 56;
  static const double buttonRadius = 16;

  // Skip pill
  static const double skipPillRadius = 24;
  static const double skipHPadding = 16;
  static const double skipVPadding = 8;

  // Dots
  static const double dotSize = 8;
  static const double dotActiveWidth = 20;
  static const double dotGap = 6;

  // Text block widths (from Figma, mostly informational — used as maxWidth)
  static const double titleMaxWidth = 260;
  static const double subtitleMaxWidth = 260;
}