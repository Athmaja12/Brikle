import 'package:brikle/AppStyle/responsive.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'appcolors.dart';

/// Single source of truth for text styles. Fonts: Hanken Grotesk for
/// display/headline text, Inter for body/UI text — per latest Figma spec.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle welcomeBack(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w800,
        fontSize: Responsive.font(context, 30),
        height: 1.0,
        letterSpacing: 0,
        color: AppColors.primaryGreen,
      );

  static TextStyle loginSubtitle(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.font(context, 16),
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textGray,
  );

  static TextStyle fieldLabel(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.font(context, 14),
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.textGray,
  );

  static TextStyle inputText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w500,
    fontSize: Responsive.font(context, 16),
    color: AppColors.inputText,
  );

  /// Button label — Inter SemiBold 14 / line-height 20px / letter-spacing 0.1px
  static TextStyle buttonText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.font(context, 14),
    height: 20 / 14,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static TextStyle errorText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.font(context, 12),
    color: AppColors.errorRed,
  );

  static TextStyle splashAppName(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w800,
        fontSize: Responsive.font(context, 24),
        color: Colors.white,
      );

  /// Onboarding headline — Hanken Grotesk Bold 32 / line-height 40px / letter-spacing -0.8px
  static TextStyle onboardingTitle(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: Responsive.font(context, 32),
        height: 40 / 32,
        letterSpacing: -0.8,
        color: AppColors.textDark,
      );

  /// Onboarding supporting line — Inter Regular 16 / line-height 22px
  static TextStyle onboardingSubtitle(BuildContext context) =>
      GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: Responsive.font(context, 16),
        height: 22 / 16,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );

  static TextStyle authPromptText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.font(context, 13),
    color: AppColors.textGray,
  );

  static TextStyle authPromptLink(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: Responsive.font(context, 13),
        color: AppColors.primaryGreen,
      );

  static TextStyle linkText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.font(context, 14),
    height: 1.0,
    letterSpacing: 0,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primaryGreen,
    color: AppColors.primaryGreen,
  );

  static TextStyle termsText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w400,
    fontSize: Responsive.font(context, 12),
    height: 1.0,
    letterSpacing: 0,
    color: AppColors.textGray,
  );

  /// "Skip" pill label
  static TextStyle skipText(BuildContext context) => GoogleFonts.inter(
    fontWeight: FontWeight.w600,
    fontSize: Responsive.font(context, 13),
    color: AppColors.textDark,
  );

  /// "B" of the Brikle logo on Login screen
  static TextStyle brikleLogoAccent(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: Responsive.font(context, 32),
        height: 40 / 32,
        letterSpacing: -0.8,
        color: AppColors.primaryGreen,
      );

  /// "rikle" of the Brikle logo on Login screen
  static TextStyle brikleLogoDark(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w700,
        fontSize: Responsive.font(context, 32),
        height: 40 / 32,
        letterSpacing: -0.8,
        color: AppColors.textDark,
      );

  /// "Welcome Back" — Hanken Grotesk SemiBold 22 / line-height 28px
  static TextStyle welcomeBackTitle(BuildContext context) =>
      GoogleFonts.hankenGrotesk(
        fontWeight: FontWeight.w600,
        fontSize: Responsive.font(context, 22),
        height: 28 / 22,
        letterSpacing: 0,
        color: AppColors.textDark,
      );

  /// "Sign in to manage your construction materials." — Inter Regular 14 / 20px, centered
  static TextStyle loginSubtitleCentered(BuildContext context) =>
      GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: Responsive.font(context, 14),
        height: 20 / 14,
        letterSpacing: 0,
        color: AppColors.textMuted,
      );
}
