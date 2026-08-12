import 'package:flutter/material.dart';

/// Central animation vocabulary.
///
/// Keep durations short — the app should feel quick, not theatrical. Anything
/// longer than [slow] is almost certainly a mistake for UI feedback.
class AppMotion {
  const AppMotion._();

  /// Taps, ripples, colour changes.
  static const Duration instant = Duration(milliseconds: 120);

  /// Press scale, chip selection, icon swaps.
  static const Duration fast = Duration(milliseconds: 180);

  /// Default for most transitions: cards, sheets, expand/collapse.
  static const Duration normal = Duration(milliseconds: 260);

  /// Page transitions, dialogs.
  static const Duration slow = Duration(milliseconds: 340);

  /// Success/error icon draw-ins.
  static const Duration celebrate = Duration(milliseconds: 520);

  /// Per-item delay used by staggered list entrances.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Cap on stagger index so long lists don't animate in forever.
  static const int maxStaggerIndex = 8;

  // Curves ------------------------------------------------------------------
  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutQuart;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve spring = Curves.easeOutBack;

  /// Total delay for the [index]-th item in a staggered list.
  static Duration staggerFor(int index) =>
      stagger * (index > maxStaggerIndex ? maxStaggerIndex : index);
}
