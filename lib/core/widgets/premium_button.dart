import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
enum PremiumButtonVariant {
  /// Solid brand gradient — the main call to action on a screen.
  primary,

  /// Soft blush fill — secondary action beside a primary one.
  secondary,

  /// Transparent with a brand border.
  outlined,

  /// No fill, no border — tertiary/inline action.
  text,

  /// Solid destructive action.
  danger,
}

enum PremiumButtonSize { small, medium, large }

/// The app's single button component.
///
/// Handles loading, disabled, icons, press animation and ripple so screens
/// never need to hand-roll a Container+InkWell button again.
class PremiumButton extends StatefulWidget {
  const PremiumButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.size = PremiumButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = true,
    this.enabled = true,
  });

  /// Convenience constructor for the secondary variant.
  const PremiumButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PremiumButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = true,
    this.enabled = true,
  }) : variant = PremiumButtonVariant.secondary;

  /// Convenience constructor for the outlined variant.
  const PremiumButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PremiumButtonSize.large,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = true,
    this.enabled = true,
  }) : variant = PremiumButtonVariant.outlined;

  /// Convenience constructor for the text variant.
  const PremiumButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.size = PremiumButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = false,
    this.enabled = true,
  }) : variant = PremiumButtonVariant.text;

  final String label;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final PremiumButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;

  /// When true the button fills the available width. Set false inside Rows.
  final bool expanded;
  final bool enabled;

  bool get _interactive => enabled && !isLoading && onPressed != null;

  double get _height => switch (size) {
        PremiumButtonSize.small => 40,
        PremiumButtonSize.medium => 46,
        PremiumButtonSize.large => 54,
      };

  double get _radius => switch (size) {
        PremiumButtonSize.small => AppRadii.sm,
        PremiumButtonSize.medium => AppRadii.md,
        PremiumButtonSize.large => AppRadii.md,
      };

  EdgeInsets get _padding => switch (size) {
        PremiumButtonSize.small =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        PremiumButtonSize.medium =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        PremiumButtonSize.large =>
          const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      };

  TextStyle get _textStyle =>
      size == PremiumButtonSize.small ? AppText.buttonSm : AppText.button;

  double get _iconSize => size == PremiumButtonSize.small ? 16 : 18;

  Color _foreground() {
    if (!_interactive && !isLoading) {
      return switch (variant) {
        PremiumButtonVariant.primary ||
        PremiumButtonVariant.danger =>
          Colors.white.withValues(alpha: 0.85),
        _ => AppColors.textTertiary,
      };
    }
    return switch (variant) {
      PremiumButtonVariant.primary || PremiumButtonVariant.danger => Colors.white,
      PremiumButtonVariant.secondary => AppColors.primaryDeep,
      PremiumButtonVariant.outlined || PremiumButtonVariant.text =>
        AppColors.primary,
    };
  }

  BoxDecoration _decoration() {
    final disabled = !_interactive && !isLoading;
    final radius = BorderRadius.circular(_radius);

    switch (variant) {
      case PremiumButtonVariant.primary:
        return BoxDecoration(
          borderRadius: radius,
          gradient: disabled
              ? LinearGradient(
                  colors: [
                    AppColors.lightPink.withValues(alpha: 0.7),
                    AppColors.lightPink.withValues(alpha: 0.7),
                  ],
                )
              : AppColors.brandGradientH,
          boxShadow: disabled ? null : AppColors.shadowBrand,
        );
      case PremiumButtonVariant.danger:
        return BoxDecoration(
          borderRadius: radius,
          color: disabled ? AppColors.error.withValues(alpha: 0.45) : AppColors.error,
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.24),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
      case PremiumButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: radius,
          color: disabled ? AppColors.background : AppColors.blushDeep,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: disabled ? 0.08 : 0.16),
          ),
        );
      case PremiumButtonVariant.outlined:
        return BoxDecoration(
          borderRadius: radius,
          color: Colors.white,
          border: Border.all(
            color: disabled
                ? AppColors.divider
                : AppColors.primary.withValues(alpha: 0.55),
            width: 1.3,
          ),
        );
      case PremiumButtonVariant.text:
        return BoxDecoration(borderRadius: radius, color: Colors.transparent);
    }
  }


  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget._interactive || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final fg = w._foreground();
    final radius = BorderRadius.circular(w._radius);
    final interactive = w._interactive;

    final content = AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.standard,
      child: w.isLoading
          ? SizedBox(
              key: const ValueKey('loading'),
              height: w._iconSize + 2,
              width: w._iconSize + 2,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fg),
              ),
            )
          : Row(
              key: const ValueKey('label'),
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (w.icon != null) ...[
                  Icon(w.icon, size: w._iconSize, color: fg),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Flexible(
                  child: Text(
                    w.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: w._textStyle.copyWith(color: fg),
                  ),
                ),
                if (w.trailingIcon != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Icon(w.trailingIcon, size: w._iconSize, color: fg),
                ],
              ],
            ),
    );

    final button = AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: w._height,
        decoration: w._decoration(),
        clipBehavior: Clip.antiAlias,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: interactive ? w.onPressed : null,
            onHighlightChanged: _setPressed,
            splashColor: fg.withValues(alpha: 0.12),
            highlightColor: fg.withValues(alpha: 0.05),
            child: Padding(
              padding: w._padding,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );

    final semantic = Semantics(
      button: true,
      enabled: interactive,
      label: w.label,
      child: button,
    );

    return w.expanded
        ? SizedBox(width: double.infinity, child: semantic)
        : semantic;
  }
}
