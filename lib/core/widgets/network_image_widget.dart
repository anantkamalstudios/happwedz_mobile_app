import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'loading_shimmer.dart';

/// Single entry point for every remote image in the app.
///
/// Handles caching, a shimmer placeholder, fade-in, and a branded error
/// placeholder. URLs are passed straight through — nothing here rewrites them.
class NetworkImageWidget extends StatelessWidget {
  const NetworkImageWidget({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.radius = 0,
    this.borderRadius,
    this.aspectRatio,
    this.placeholderIcon = Icons.image_outlined,
    this.errorIcon = Icons.image_not_supported_outlined,
    this.backgroundColor,
    this.memCacheWidth,
    this.heroTag,
    this.scrim = false,
  });

  /// May be null/empty — the error placeholder is shown in that case.
  final String? url;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Convenience uniform radius. Ignored when [borderRadius] is provided.
  final double radius;
  final BorderRadius? borderRadius;

  /// When set, the image is wrapped in an [AspectRatio] so the layout does not
  /// jump between the placeholder and the loaded image.
  final double? aspectRatio;

  final IconData placeholderIcon;
  final IconData errorIcon;
  final Color? backgroundColor;

  /// Decode width in px. Set this for thumbnails to keep memory low.
  final int? memCacheWidth;

  final Object? heroTag;

  /// Paints a bottom gradient scrim so overlaid white text stays readable.
  final bool scrim;

  BorderRadius get _radius =>
      borderRadius ?? BorderRadius.circular(radius);

  @override
  Widget build(BuildContext context) {
    Widget image;

    final src = url?.trim() ?? '';
    final valid = src.isNotEmpty && src.startsWith('http');

    if (!valid) {
      image = _Placeholder(icon: errorIcon, background: backgroundColor);
    } else {
      image = CachedNetworkImage(
        imageUrl: src,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        fadeInDuration: AppMotion.normal,
        fadeOutDuration: AppMotion.instant,
        placeholder: (_, __) => LoadingShimmer(
          child: Container(
            width: width,
            height: height,
            color: Colors.white,
          ),
        ),
        errorWidget: (_, __, ___) =>
            _Placeholder(icon: errorIcon, background: backgroundColor),
      );
    }

    if (scrim) {
      image = Stack(
        fit: StackFit.passthrough,
        children: [
          image,
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.imageScrim),
            ),
          ),
        ],
      );
    }

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    Widget result = ClipRRect(borderRadius: _radius, child: image);

    if (aspectRatio != null) {
      result = AspectRatio(aspectRatio: aspectRatio!, child: result);
    }

    return result;
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon, this.background});

  final IconData icon;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background ?? AppColors.blush,
      alignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Scale the glyph to the box so tiny thumbnails don't clip it.
          final side = constraints.biggest.shortestSide;
          final size = side.isFinite ? (side * 0.28).clamp(14.0, 40.0) : 24.0;
          return Icon(
            icon,
            size: size,
            color: AppColors.primary.withValues(alpha: 0.28),
          );
        },
      ),
    );
  }
}

/// Circular avatar backed by [NetworkImageWidget] with an initials fallback.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.url,
    this.name,
    this.size = 44,
    this.borderColor,
  });

  final String? url;
  final String? name;
  final double size;
  final Color? borderColor;

  String get _initials {
    final parts = (name ?? '').trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = (url ?? '').trim().startsWith('http');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.blushDeep,
        border: borderColor == null
            ? null
            : Border.all(color: borderColor!, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: hasUrl
          ? NetworkImageWidget(
              url: url,
              width: size,
              height: size,
              memCacheWidth: (size * 3).round(),
              fit: BoxFit.cover,
            )
          : Text(
              _initials,
              style: TextStyle(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
    );
  }
}
