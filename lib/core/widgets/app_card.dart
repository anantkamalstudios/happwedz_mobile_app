import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'pressable.dart';

/// Surface container used for every card-like block in the app.
///
/// Gives a consistent radius, soft shadow and optional press animation, so
/// screens stop hand-rolling Container + BoxDecoration + InkWell.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = AppSpacing.card,
    this.margin,
    this.radius = AppRadii.lg,
    this.color,
    this.gradient,
    this.border,
    this.shadow,
    this.width,
    this.height,
    this.clip = true,
    this.elevated = true,
  });

  /// Flat variant: 1px border, no shadow. Reads well inside dense lists.
  const AppCard.outlined({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding = AppSpacing.card,
    this.margin,
    this.radius = AppRadii.lg,
    this.color,
    this.gradient,
    this.width,
    this.height,
    this.clip = true,
  })  : border = const Border.fromBorderSide(
          BorderSide(color: AppColors.divider),
        ),
        shadow = const <BoxShadow>[],
        elevated = false;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final double? width;
  final double? height;
  final bool clip;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.surface) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: border,
        boxShadow: shadow ?? (elevated ? AppColors.shadowSm : null),
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      content = Pressable(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: borderRadius,
        scale: 0.985,
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}

/// Small translucent pill used for badges on top of imagery (rating, price,
/// "Featured", …).
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.icon,
    this.background,
    this.foreground,
    this.compact = false,
  });

  final String label;
  final IconData? icon;
  final Color? background;
  final Color? foreground;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final fg = foreground ?? Colors.white;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? Colors.black.withValues(alpha: 0.55),
        borderRadius: AppRadii.rPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: compact ? 11 : 13, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: compact ? 10.5 : 11.5,
                fontWeight: FontWeight.w600,
                color: fg,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
