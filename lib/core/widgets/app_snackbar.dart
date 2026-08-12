import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppSnackType { success, error, warning, info }

/// The app's only snackbar API.
///
/// Replaces ad-hoc `ScaffoldMessenger.showSnackBar(SnackBar(...))` calls so
/// every transient message looks the same.
class AppSnackbar {
  const AppSnackbar._();

  static void success(BuildContext context, String message, {String? title}) =>
      _show(context, message, AppSnackType.success, title);

  static void error(BuildContext context, String message, {String? title}) =>
      _show(context, message, AppSnackType.error, title);

  static void warning(BuildContext context, String message, {String? title}) =>
      _show(context, message, AppSnackType.warning, title);

  static void info(BuildContext context, String message, {String? title}) =>
      _show(context, message, AppSnackType.info, title);

  /// Hides any snackbar currently on screen.
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.maybeOf(context)?.hideCurrentSnackBar();
  }

  static void show(
    BuildContext context, {
    required String message,
    String? title,
    AppSnackType type = AppSnackType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _show(
      context,
      message,
      type,
      title,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void _show(
    BuildContext context,
    String message,
    AppSnackType type,
    String? title, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final (Color accent, IconData icon) = switch (type) {
      AppSnackType.success => (AppColors.successDark, Icons.check_circle_rounded),
      AppSnackType.error => (AppColors.error, Icons.error_rounded),
      AppSnackType.warning => (AppColors.warning, Icons.warning_rounded),
      AppSnackType.info => (AppColors.primary, Icons.info_rounded),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          margin: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.rMd),
          content: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: accent.withValues(alpha: 0.22)),
              boxShadow: AppColors.shadowMd,
            ),
            child: Row(
              children: [
                // Accent rail
                Container(
                  width: 4,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(AppRadii.md),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Icon(icon, color: accent, size: 20),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.label.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        Text(
                          message,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.bodySm.copyWith(
                            color: title == null
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (actionLabel != null && onAction != null)
                  TextButton(
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
                      onAction();
                    },
                    child: Text(
                      actionLabel,
                      style: AppText.buttonSm.copyWith(color: accent),
                    ),
                  )
                else
                  const SizedBox(width: AppSpacing.md),
              ],
            ),
          ),
        ),
      );
  }
}
