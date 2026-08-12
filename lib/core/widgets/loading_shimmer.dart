import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Base shimmer wrapper. Wrap skeleton shapes (plain white boxes) in this.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      period: const Duration(milliseconds: 1300),
      child: child,
    );
  }
}

/// A single skeleton block. Compose these into layout-shaped skeletons.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadii.xs,
    this.margin,
    this.shape = BoxShape.rectangle,
  });

  const SkeletonBox.circle({super.key, required double size, this.margin})
      : width = size,
        height = size,
        radius = 0,
        shape = BoxShape.circle;

  final double? width;
  final double height;
  final double radius;
  final EdgeInsetsGeometry? margin;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: shape,
        borderRadius:
            shape == BoxShape.circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeletons that mirror the real layouts used across HappyWedz.
///
/// Each returns content already wrapped in [LoadingShimmer], so screens can
/// drop them straight into a `loading ? Skeletons.x() : realWidget` branch.
class Skeletons {
  const Skeletons._();

  /// Horizontal carousel of image cards (home sections, vendor rails).
  static Widget cardRail({
    double height = 210,
    double itemWidth = 160,
    int count = 4,
    EdgeInsetsGeometry padding =
        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
  }) {
    return SizedBox(
      height: height,
      child: LoadingShimmer(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          itemCount: count,
          separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
          itemBuilder: (_, __) => SizedBox(
            width: itemWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SkeletonBox(
                    width: itemWidth,
                    height: double.infinity,
                    radius: AppRadii.lg,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: itemWidth * 0.8, height: 11),
                const SizedBox(height: 6),
                SkeletonBox(width: itemWidth * 0.5, height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Vertical list of wide media cards (venues, vendors, bookings).
  static Widget listCards({
    int count = 4,
    double height = 230,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
  }) {
    return LoadingShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(
              width: double.infinity,
              height: height * 0.62,
              radius: AppRadii.lg,
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(width: 190, height: 13),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 130, height: 11),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: 90, height: 11),
          ],
        ),
      ),
    );
  }

  /// Compact rows with a leading thumbnail (search results, chats, reviews).
  static Widget listTiles({
    int count = 6,
    double thumbSize = 56,
    bool circle = false,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
  }) {
    return LoadingShimmer(
      child: ListView.separated(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, __) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            circle
                ? SkeletonBox.circle(size: thumbSize)
                : SkeletonBox(
                    width: thumbSize,
                    height: thumbSize,
                    radius: AppRadii.md,
                  ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  const SkeletonBox(width: double.infinity, height: 12),
                  const SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.6,
                    child: const SkeletonBox(
                      width: double.infinity,
                      height: 10,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FractionallySizedBox(
                    widthFactor: 0.35,
                    child: const SkeletonBox(
                      width: double.infinity,
                      height: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Two-column tile grid (categories, wishlist, ideas).
  static Widget grid({
    int count = 6,
    int columns = 2,
    double aspectRatio = 0.78,
    EdgeInsetsGeometry padding = const EdgeInsets.all(AppSpacing.lg),
  }) {
    return LoadingShimmer(
      child: GridView.builder(
        padding: padding,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: count,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
          childAspectRatio: aspectRatio,
        ),
        itemBuilder: (_, __) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: SkeletonBox(
                width: double.infinity,
                height: double.infinity,
                radius: AppRadii.lg,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const SkeletonBox(width: double.infinity, height: 11),
            const SizedBox(height: 6),
            FractionallySizedBox(
              widthFactor: 0.55,
              child: const SkeletonBox(width: double.infinity, height: 10),
            ),
          ],
        ),
      ),
    );
  }

  /// Detail-screen skeleton: hero image, title block, chips, paragraphs.
  static Widget detail({double heroHeight = 240}) {
    return LoadingShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(width: double.infinity, height: heroHeight),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 220, height: 18, radius: AppRadii.sm),
                const SizedBox(height: AppSpacing.md),
                const SkeletonBox(width: 150, height: 12),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: List.generate(
                    3,
                    (i) => const Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: SkeletonBox(
                        width: 86,
                        height: 30,
                        radius: AppRadii.pill,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                const SkeletonBox(width: double.infinity, height: 12),
                const SizedBox(height: AppSpacing.sm),
                const SkeletonBox(width: double.infinity, height: 12),
                const SizedBox(height: AppSpacing.sm),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: const SkeletonBox(width: double.infinity, height: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Profile header skeleton (avatar + name + stats).
  static Widget profileHeader() {
    return LoadingShimmer(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            const SkeletonBox.circle(size: 72),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 150, height: 15),
                  const SizedBox(height: AppSpacing.sm),
                  const SkeletonBox(width: 190, height: 11),
                  const SizedBox(height: AppSpacing.sm),
                  const SkeletonBox(width: 110, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A row of stat/summary tiles (dashboard, budget).
  static Widget statTiles({int count = 3, double height = 84}) {
    return LoadingShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(
            count,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == count - 1 ? 0 : AppSpacing.md),
                child: SkeletonBox(
                  width: double.infinity,
                  height: height,
                  radius: AppRadii.lg,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lines of text, e.g. a description block.
  static Widget textLines({int lines = 3, double width = double.infinity}) {
    return LoadingShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          lines,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: FractionallySizedBox(
              widthFactor: i == lines - 1 ? 0.6 : 1,
              child: const SkeletonBox(width: double.infinity, height: 11),
            ),
          ),
        ),
      ),
    );
  }
}
