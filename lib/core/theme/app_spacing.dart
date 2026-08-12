import 'package:flutter/widgets.dart';

/// Spacing scale (4pt grid). Use these instead of magic numbers so rhythm
/// stays consistent across screens.
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  /// Standard horizontal page padding.
  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: lg);

  /// Standard card inner padding.
  static const EdgeInsets card = EdgeInsets.all(lg);

  // Common gaps as const widgets — avoids allocating SizedBox everywhere.
  static const Widget gapXs = SizedBox(height: xs, width: xs);
  static const Widget h4 = SizedBox(height: 4);
  static const Widget h8 = SizedBox(height: 8);
  static const Widget h12 = SizedBox(height: 12);
  static const Widget h16 = SizedBox(height: 16);
  static const Widget h20 = SizedBox(height: 20);
  static const Widget h24 = SizedBox(height: 24);
  static const Widget h32 = SizedBox(height: 32);

  static const Widget w4 = SizedBox(width: 4);
  static const Widget w8 = SizedBox(width: 8);
  static const Widget w12 = SizedBox(width: 12);
  static const Widget w16 = SizedBox(width: 16);
  static const Widget w20 = SizedBox(width: 20);
}

/// Corner radius scale.
class AppRadii {
  const AppRadii._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius rXs = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));

  /// Rounded top corners for bottom sheets.
  static const BorderRadius sheet = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Responsive helpers. The app is portrait-first but must survive small
/// phones (320-360dp) and large ones (430dp+) without overflow.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double compact = 360;
  static const double medium = 400;
  static const double expanded = 600;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isExpanded(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= expanded;

  /// Clamp the OS text scale so large accessibility settings cannot blow up
  /// fixed-height rows into RenderFlex overflows.
  static double textScale(BuildContext context, {double max = 1.25}) {
    final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
    return scale > max ? max : scale;
  }

  /// Grid column count that adapts to width instead of being hardcoded to 2.
  static int gridColumns(BuildContext context, {int min = 2, int max = 4}) {
    final width = MediaQuery.sizeOf(context).width;
    final count = (width / 190).floor();
    return count.clamp(min, max);
  }

  /// Scales a value slightly on very small / very large screens so headers and
  /// hero areas keep their proportions.
  static double scaled(BuildContext context, double value) {
    final width = MediaQuery.sizeOf(context).width;
    final factor = (width / 390).clamp(0.85, 1.15);
    return value * factor;
  }
}