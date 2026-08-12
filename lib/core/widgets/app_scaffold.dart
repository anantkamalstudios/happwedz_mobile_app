import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../theme/app_typography.dart';
import 'error_state.dart';
import 'pressable.dart';

/// App bar used on plain (white) screens.
///
/// Returns a real [PreferredSizeWidget] so it drops into `Scaffold.appBar`
/// without any layout surprises.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.centerTitle = false,
    this.bottom,
    this.backgroundColor,
    this.foregroundColor,
    this.elevated = false,
  });

  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Adds a hairline shadow — use when content scrolls under the bar.
  final bool elevated;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? AppColors.textPrimary;
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: backgroundColor ?? Colors.white,
      surfaceTintColor: Colors.transparent,
      foregroundColor: fg,
      elevation: elevated ? 0.5 : 0,
      scrolledUnderElevation: elevated ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      centerTitle: centerTitle,
      titleSpacing: showBack && canPop ? 0 : AppSpacing.lg,
      systemOverlayStyle: (backgroundColor ?? Colors.white).computeLuminance() > 0.5
          ? AppTheme.darkStatusBar
          : AppTheme.lightStatusBar,
      leading: showBack && canPop
          ? AppBackButton(color: fg, onTap: onBack)
          : null,
      automaticallyImplyLeading: false,
      title: titleWidget ??
          (title == null
              ? null
              : Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.pageTitle.copyWith(color: fg),
                )),
      actions: actions,
      bottom: bottom,
    );
  }
}

/// Circular back button with press feedback, used across screens.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onTap,
    this.color,
    this.background,
    this.size = 38,
  });

  final VoidCallback? onTap;
  final Color? color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Pressable(
        scale: 0.9,
        onTap: onTap ?? () => Navigator.of(context).maybePop(),
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(left: AppSpacing.sm),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background ?? Colors.transparent,
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Gradient header used on hero screens (home, category, detail).
///
/// Sized by its content — no fixed height — so it never overflows when text
/// scales up.
class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.xl,
    ),
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(AppRadii.xl),
    ),
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.lightStatusBar,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient ?? AppColors.brandGradient,
          borderRadius: borderRadius,
          boxShadow: AppColors.shadowMd,
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Renders one of loading / error / empty / content from a single state.
///
/// Screens keep their existing API calls and simply describe what to show:
/// ```dart
/// AsyncView(
///   isLoading: _loading,
///   error: _error,
///   isEmpty: _items.isEmpty,
///   loading: Skeletons.listCards(),
///   empty: const EmptyState(title: 'No Vendors Found'),
///   onRetry: _fetch,
///   child: _list(),
/// )
/// ```
class AsyncView extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.isLoading,
    required this.child,
    this.error,
    this.isEmpty = false,
    this.loading,
    this.empty,
    this.onRetry,
    this.errorTitle,
    this.errorMessage,
  });

  final bool isLoading;
  final Object? error;
  final bool isEmpty;

  /// Skeleton shown while [isLoading]. Falls back to a small spinner.
  final Widget? loading;
  final Widget? empty;
  final Widget child;
  final VoidCallback? onRetry;
  final String? errorTitle;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = KeyedSubtree(
        key: const ValueKey('async-loading'),
        child: loading ?? const AppLoader(),
      );
    } else if (error != null) {
      content = KeyedSubtree(
        key: const ValueKey('async-error'),
        child: _errorView(),
      );
    } else if (isEmpty) {
      content = KeyedSubtree(
        key: const ValueKey('async-empty'),
        child: empty ?? const _DefaultEmpty(),
      );
    } else {
      content = KeyedSubtree(key: const ValueKey('async-data'), child: child);
    }

    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      switchOutCurve: AppMotion.exit,
      child: content,
    );
  }

  Widget _errorView() => ErrorState(
        error: error,
        title: errorTitle,
        message: errorMessage,
        onRetry: onRetry,
      );
}

class _DefaultEmpty extends StatelessWidget {
  const _DefaultEmpty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Text(
          'Nothing here yet',
          style: AppText.bodySm,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Small, brand-coloured spinner. Use only for short inline waits — lists and
/// cards should use a shimmer skeleton instead.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 26, this.color, this.padding});

  final double size;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.xxl),
        child: SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated heart used for wishlist / favourite toggles.
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.isFavorite,
    this.onTap,
    this.size = 34,
    this.iconSize = 18,
    this.background,
    this.inactiveColor,
    this.isLoading = false,
  });

  final bool isFavorite;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? inactiveColor;
  final bool isLoading;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AppMotion.normal,
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void didUpdateWidget(covariant FavoriteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Pop only when it becomes a favourite; removing should feel quiet.
    if (!oldWidget.isFavorite && widget.isFavorite) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      scale: 0.85,
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.background ?? Colors.white.withValues(alpha: 0.92),
          boxShadow: AppColors.shadowSm,
        ),
        alignment: Alignment.center,
        child: widget.isLoading
            ? SizedBox(
                width: widget.iconSize - 4,
                height: widget.iconSize - 4,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  // 1 → 1.35 → 1 pop
                  final t = _c.value;
                  final scale = 1 + 0.35 * (t < 0.5 ? t * 2 : (1 - t) * 2);
                  return Transform.scale(scale: scale, child: child);
                },
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: Icon(
                    widget.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    key: ValueKey(widget.isFavorite),
                    size: widget.iconSize,
                    color: widget.isFavorite
                        ? AppColors.primary
                        : widget.inactiveColor ?? AppColors.textSecondary,
                  ),
                ),
              ),
      ),
    );
  }
}
