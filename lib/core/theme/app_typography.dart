import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins type scale for HappyWedz.
///
/// Every screen should pull text styles from here (or from
/// `Theme.of(context).textTheme`) so weights and sizes stay consistent.
/// Rule of thumb: SemiBold for titles, Medium for labels/buttons, Regular for
/// body. Bold is reserved for display/hero text only.
class AppText {
  const AppText._();

  static TextStyle _p(
    double size,
    FontWeight weight, {
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color ?? AppColors.textPrimary,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  // --- Display / hero -------------------------------------------------------
  static TextStyle get display => _p(30, FontWeight.w700, height: 1.2);
  static TextStyle get displaySm => _p(26, FontWeight.w700, height: 1.22);

  // --- Page & section titles ------------------------------------------------
  /// Screen title in an app bar.
  static TextStyle get pageTitle => _p(20, FontWeight.w600, height: 1.25);

  /// "Popular Venues", "Our Services" …
  static TextStyle get sectionTitle => _p(18, FontWeight.w600, height: 1.3);

  static TextStyle get sectionSubtitle =>
      _p(13, FontWeight.w400, color: AppColors.textSecondary, height: 1.4);

  // --- Cards ----------------------------------------------------------------
  static TextStyle get cardTitle => _p(15, FontWeight.w600, height: 1.3);
  static TextStyle get cardSubtitle =>
      _p(12.5, FontWeight.w400, color: AppColors.textSecondary, height: 1.35);

  // --- Body -----------------------------------------------------------------
  static TextStyle get bodyLg => _p(15, FontWeight.w400, height: 1.5);
  static TextStyle get body => _p(14, FontWeight.w400, height: 1.5);
  static TextStyle get bodySm =>
      _p(13, FontWeight.w400, color: AppColors.textSecondary, height: 1.45);

  static TextStyle get bodyStrong => _p(14, FontWeight.w500, height: 1.5);

  // --- Labels / UI chrome ---------------------------------------------------
  static TextStyle get label => _p(13, FontWeight.w500);
  static TextStyle get labelSm =>
      _p(12, FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle get formLabel =>
      _p(13, FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get button => _p(15, FontWeight.w600, letterSpacing: 0.2);
  static TextStyle get buttonSm => _p(13.5, FontWeight.w600, letterSpacing: 0.2);

  static TextStyle get caption =>
      _p(11.5, FontWeight.w400, color: AppColors.textTertiary, height: 1.35);

  static TextStyle get overline => _p(
    11,
    FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
  );

  // --- Feedback -------------------------------------------------------------
  static TextStyle get error =>
      _p(12, FontWeight.w400, color: AppColors.error, height: 1.35);
  static TextStyle get success =>
      _p(12, FontWeight.w500, color: AppColors.successDark, height: 1.35);

  // --- Price / metric -------------------------------------------------------
  static TextStyle get price =>
      _p(16, FontWeight.w600, color: AppColors.primary);
  static TextStyle get priceSm =>
      _p(13.5, FontWeight.w600, color: AppColors.primary);

  /// Builds the Material TextTheme so widgets that read from the theme
  /// (dialogs, menus, list tiles) also get Poppins.
  static TextTheme textTheme() {
    return TextTheme(
      displayLarge: display,
      displayMedium: displaySm,
      displaySmall: pageTitle,
      headlineLarge: pageTitle,
      headlineMedium: sectionTitle,
      headlineSmall: sectionTitle,
      titleLarge: sectionTitle,
      titleMedium: cardTitle,
      titleSmall: label,
      bodyLarge: bodyLg,
      bodyMedium: body,
      bodySmall: bodySm,
      labelLarge: button,
      labelMedium: label,
      labelSmall: caption,
    );
  }
}