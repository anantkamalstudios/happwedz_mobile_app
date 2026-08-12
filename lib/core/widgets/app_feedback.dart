import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'premium_button.dart';

/// Animated status glyph used by the success/error popups.
///
/// Draws the ring first, then strokes the check / cross. Pure CustomPaint —
/// no asset or Lottie file needed, so it stays cheap.
class AnimatedStatusIcon extends StatefulWidget {
  const AnimatedStatusIcon({
    super.key,
    required this.success,
    this.size = 84,
    this.color,
  });

  final bool success;
  final double size;
  final Color? color;

  @override
  State<AnimatedStatusIcon> createState() => _AnimatedStatusIconState();
}

class _AnimatedStatusIconState extends State<AnimatedStatusIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.celebrate,
  )..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ??
        (widget.success ? AppColors.success : AppColors.error);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          return CustomPaint(
            painter: _StatusPainter(
              progress: _c.value,
              color: color,
              success: widget.success,
            ),
          );
        },
      ),
    );
  }
}

class _StatusPainter extends CustomPainter {
  _StatusPainter({
    required this.progress,
    required this.color,
    required this.success,
  });

  final double progress;
  final Color color;
  final bool success;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 4;

    // Halo
    final haloT = Curves.easeOut.transform(math.min(1, progress / 0.4));
    canvas.drawCircle(
      center,
      radius * (0.6 + 0.4 * haloT),
      Paint()..color = color.withValues(alpha: 0.10 * haloT),
    );

    // Ring sweep
    final ringT = Curves.easeOutCubic.transform(math.min(1, progress / 0.55));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * ringT,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055
        ..strokeCap = StrokeCap.round,
    );

    // Glyph stroke
    final glyphT = progress <= 0.45
        ? 0.0
        : Curves.easeOutCubic.transform(((progress - 0.45) / 0.55).clamp(0, 1));
    if (glyphT <= 0) return;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (success) {
      final a = Offset(size.width * 0.30, size.height * 0.52);
      final b = Offset(size.width * 0.44, size.height * 0.66);
      final c = Offset(size.width * 0.71, size.height * 0.37);
      path.moveTo(a.dx, a.dy);
      path.lineTo(b.dx, b.dy);
      path.lineTo(c.dx, c.dy);
    } else {
      path.moveTo(size.width * 0.34, size.height * 0.34);
      path.lineTo(size.width * 0.66, size.height * 0.66);
      path.moveTo(size.width * 0.66, size.height * 0.34);
      path.lineTo(size.width * 0.34, size.height * 0.66);
    }

    canvas.drawPath(_trim(path, glyphT), stroke);
  }

  /// Returns the first [t] fraction of every subpath, so the glyph draws in.
  Path _trim(Path source, double t) {
    if (t >= 1) return source;
    final result = Path();
    for (final metric in source.computeMetrics()) {
      result.addPath(
        metric.extractPath(0, metric.length * t),
        Offset.zero,
      );
    }
    return result;
  }

  @override
  bool shouldRepaint(_StatusPainter old) =>
      old.progress != progress || old.color != color || old.success != success;
}

/// Shared dialog shell: scale+fade entrance, rounded card, consistent spacing.
class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog({
    required this.icon,
    required this.title,
    this.message,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.danger = false,
  });

  final Widget icon;
  final String title;
  final String? message;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.rXl),
      child: ConstrainedBox(
        // Keeps the dialog usable on small screens and with the keyboard open.
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: media.size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xxl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.sectionTitle,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySm,
                ),
              ],
              if (primaryLabel != null || secondaryLabel != null) ...[
                const SizedBox(height: AppSpacing.xxl),
                if (secondaryLabel != null && primaryLabel != null)
                  Row(
                    children: [
                      Expanded(
                        child: PremiumButton.outlined(
                          label: secondaryLabel!,
                          size: PremiumButtonSize.medium,
                          onPressed: onSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PremiumButton(
                          label: primaryLabel!,
                          size: PremiumButtonSize.medium,
                          variant: danger
                              ? PremiumButtonVariant.danger
                              : PremiumButtonVariant.primary,
                          onPressed: onPrimary,
                        ),
                      ),
                    ],
                  )
                else if (primaryLabel != null)
                  PremiumButton(
                    label: primaryLabel!,
                    size: PremiumButtonSize.medium,
                    variant: danger
                        ? PremiumButtonVariant.danger
                        : PremiumButtonVariant.primary,
                    onPressed: onPrimary,
                  )
                else
                  PremiumButton.outlined(
                    label: secondaryLabel!,
                    size: PremiumButtonSize.medium,
                    onPressed: onSecondary,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> _showAnimatedDialog<T>(
  BuildContext context, {
  required Widget child,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    transitionDuration: AppMotion.normal,
    pageBuilder: (_, __, ___) => child,
    transitionBuilder: (context, animation, _, dialog) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.standard,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: dialog,
        ),
      );
    },
  );
}

/// Premium success feedback.
///
/// ```dart
/// await SuccessPopup.show(context, title: 'Booking confirmed');
/// ```
class SuccessPopup {
  const SuccessPopup._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,

    /// When set, the popup closes itself after this delay.
    Duration? autoDismissAfter = const Duration(milliseconds: 1800),
    bool barrierDismissible = true,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool closed = false;

    void close() {
      if (closed) return;
      closed = true;
      if (navigator.canPop()) navigator.pop();
    }

    if (autoDismissAfter != null && actionLabel == null) {
      Future<void>.delayed(autoDismissAfter, close);
    }

    await _showAnimatedDialog<void>(
      context,
      barrierDismissible: barrierDismissible,
      child: _FeedbackDialog(
        icon: const AnimatedStatusIcon(success: true),
        title: title,
        message: message,
        primaryLabel: actionLabel,
        onPrimary: onAction == null
            ? null
            : () {
                close();
                onAction();
              },
      ),
    );
    closed = true;
  }
}

/// Premium error feedback with an optional retry.
class ErrorPopup {
  const ErrorPopup._();

  static Future<void> show(
    BuildContext context, {
    String title = 'Something went wrong',
    String? message = "We couldn't complete your request. Please try again.",
    String? retryLabel,
    VoidCallback? onRetry,
    String dismissLabel = 'Close',
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);

    await _showAnimatedDialog<void>(
      context,
      child: _FeedbackDialog(
        icon: const AnimatedStatusIcon(success: false),
        title: title,
        message: message,
        primaryLabel: onRetry != null ? (retryLabel ?? 'Try Again') : dismissLabel,
        onPrimary: () {
          if (navigator.canPop()) navigator.pop();
          onRetry?.call();
        },
        secondaryLabel: onRetry != null ? dismissLabel : null,
        onSecondary: () {
          if (navigator.canPop()) navigator.pop();
        },
      ),
    );
  }
}

/// Confirmation dialog (delete, logout, discard …). Returns true on confirm.
class ConfirmPopup {
  const ConfirmPopup._();

  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    IconData icon = Icons.help_outline_rounded,
    bool danger = false,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    final accent = danger ? AppColors.error : AppColors.primary;

    final result = await _showAnimatedDialog<bool>(
      context,
      child: _FeedbackDialog(
        danger: danger,
        icon: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.10),
          ),
          child: Icon(icon, size: 30, color: accent),
        ),
        title: title,
        message: message,
        primaryLabel: confirmLabel,
        onPrimary: () => navigator.pop(true),
        secondaryLabel: cancelLabel,
        onSecondary: () => navigator.pop(false),
      ),
    );

    return result ?? false;
  }
}

/// Bottom sheet shell with the app's radius, drag handle and safe-area
/// handling. Content is scrollable and keyboard-aware by default.
class AppBottomSheet {
  const AppBottomSheet._();

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool showHandle = true,
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(
      AppSpacing.xl,
      AppSpacing.sm,
      AppSpacing.xl,
      AppSpacing.xl,
    ),
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      showDragHandle: false,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return SafeArea(
          top: false,
          child: Padding(
            // Lifts the sheet above the keyboard so fields stay reachable.
            padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showHandle)
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(
                        top: AppSpacing.md,
                        bottom: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  if (title != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.sm,
                        AppSpacing.xl,
                        0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(title, style: AppText.sectionTitle),
                          ),
                          IconButton(
                            splashRadius: 20,
                            icon: const Icon(Icons.close_rounded, size: 20),
                            color: AppColors.textSecondary,
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: padding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
