import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'animated_page.dart';
import 'premium_button.dart';

/// Shown when an API returned successfully but there is nothing to display.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.search_off_rounded,
    this.illustration,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.compact = false,
    this.padding,
  });

  final String title;
  final String? message;
  final IconData icon;

  /// Optional custom illustration replacing the icon badge.
  final Widget? illustration;

  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  /// Tighter spacing for use inside a section rather than a whole screen.
  final bool compact;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final double badge = compact ? 72 : 96;

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding ??
            EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: compact ? AppSpacing.xl : AppSpacing.xxxl,
            ),
        child: FadeSlideIn(
          duration: AppMotion.slow,
          offset: const Offset(0, 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              illustration ??
                  Container(
                    width: badge,
                    height: badge,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.blush,
                          AppColors.pinkSurface.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: badge * 0.42,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ),
              SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
              Text(
                title,
                textAlign: TextAlign.center,
                style: compact ? AppText.cardTitle : AppText.sectionTitle,
              ),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppText.bodySm,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xxl),
                PremiumButton(
                  label: actionLabel!,
                  onPressed: onAction,
                  size: PremiumButtonSize.medium,
                  expanded: false,
                ),
              ],
              if (secondaryActionLabel != null &&
                  onSecondaryAction != null) ...[
                const SizedBox(height: AppSpacing.sm),
                PremiumButton.text(
                  label: secondaryActionLabel!,
                  onPressed: onSecondaryAction,
                  size: PremiumButtonSize.small,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
