import 'package:flutter/material.dart';

/// HappyWedz color system.
///
/// IMPORTANT: These are the *existing* HappyWedz colors, extracted from the
/// app as-is. Nothing here introduces a new palette — the values are the same
/// pinks/blushes/neutrals already used across the screens. This file only gives
/// them names so every screen uses the same value instead of re-typing hex.
class AppColors {
  const AppColors._();

  // ---------------------------------------------------------------------------
  // Brand — primary pinks (existing)
  // ---------------------------------------------------------------------------

  /// Most used brand color across the app (Color(0xFFE91E63)).
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFD81B60);
  static const Color primaryDeep = Color(0xFFAD1457);
  static const Color primaryLight = Color(0xFFF06292);

  /// Hot pink used in headers / bottom nav gradient.
  static const Color hotPink = Color(0xFFFF69B4);

  /// Deep pink, the second stop of the signature gradient.
  static const Color deepPink = Color(0xFFFF1493);

  /// Soft pink used for gradient tails and light surfaces.
  static const Color lightPink = Color(0xFFFFB6C1);

  /// Rose accent used on cards and highlights.
  static const Color rose = Color(0xFFFF6B9D);
  static const Color roseSoft = Color(0xFFFF8FA3);
  static const Color magenta = Color(0xFFFF4081);

  // ---------------------------------------------------------------------------
  // Accent — gold (existing, used on premium / decor sections)
  // ---------------------------------------------------------------------------

  static const Color gold = Color(0xFFC89C74);
  static const Color goldLight = Color(0xFFDDB79B);

  // ---------------------------------------------------------------------------
  // Surfaces & backgrounds (existing)
  // ---------------------------------------------------------------------------

  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;

  /// Blush tinted surfaces already used behind pink sections.
  static const Color blush = Color(0xFFFFF1F6);
  static const Color blushDeep = Color(0xFFFDE8EF);
  static const Color blushWarm = Color(0xFFFFE4E1);
  static const Color pinkSurface = Color(0xFFFCE4EC);
  static const Color pinkSurfaceStrong = Color(0xFFF8BBD0);

  static const Color divider = Color(0xFFE9ECEF);
  static const Color border = Color(0xFFEDEDED);

  // ---------------------------------------------------------------------------
  // Text (existing greys)
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Colors.white;
  static const Color textDark = Color(0xFF424242);

  // ---------------------------------------------------------------------------
  // Status (existing)
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF25D366);
  static const Color successDark = Color(0xFF1B9E4B);
  static const Color error = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFB71C1C);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF1E88E5);

  // ---------------------------------------------------------------------------
  // Shimmer
  // ---------------------------------------------------------------------------

  static const Color shimmerBase = Color(0xFFEDEDED);
  static const Color shimmerHighlight = Color(0xFFF8F8F8);

  // ---------------------------------------------------------------------------
  // Gradients (existing combinations, unchanged)
  // ---------------------------------------------------------------------------

  /// The signature bottom-nav / button gradient.
  static const LinearGradient brandGradient = LinearGradient(
    colors: [hotPink, deepPink],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Horizontal variant for wide buttons and chips.
  static const LinearGradient brandGradientH = LinearGradient(
    colors: [hotPink, deepPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// The header wash used on category / detail screens.
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [hotPink, lightPink, Colors.white],
    stops: [0.0, 0.3, 0.6],
  );

  /// Subtle blush wash for page backgrounds.
  static const LinearGradient blushGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blush, Colors.white],
  );

  /// Scrim placed over imagery so white text stays readable.
  static const LinearGradient imageScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0x99000000)],
    stops: [0.45, 1.0],
  );

  // ---------------------------------------------------------------------------
  // Elevation — soft, brand-tinted shadows
  // ---------------------------------------------------------------------------

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  /// Pink-tinted glow for primary CTAs.
  static List<BoxShadow> shadowBrand = [
    BoxShadow(
      color: primary.withValues(alpha: 0.28),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}