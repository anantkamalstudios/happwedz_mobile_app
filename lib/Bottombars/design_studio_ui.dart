/// Design Studio presentation kit.
///
/// PRESENTATION ONLY. Nothing in this file performs networking, parses a
/// response, holds business state or touches auth. It exists so every Design
/// Studio screen draws from one vocabulary instead of hand-rolling containers,
/// and it is built strictly on top of `core/core.dart` — no new brand colours,
/// no new type ramp, no competing radius scale.
///
/// The one addition is [StudioTokens.canvas]: photo-editor surfaces need a
/// dark backdrop so the user's photo carries the screen. The old code already
/// used `Colors.black`/`Colors.grey[850]` for this; the token simply replaces
/// those ad-hoc values with a single brand-tinted near-black.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/core.dart';

// ---------------------------------------------------------------------------
// Tokens
// ---------------------------------------------------------------------------

/// Design-Studio-local surfaces. Everything else comes from [AppColors].
class StudioTokens {
  const StudioTokens._();

  /// Photo stage backdrop — near-black with a brand plum undertone so the
  /// dark screens still read as part of HappyWedz rather than neutral grey.
  static const Color canvas = Color(0xFF17090F);

  /// Slightly lifted canvas, used for panels sitting on [canvas].
  static const Color canvasRaised = Color(0xFF231218);

  /// Hairline on dark surfaces.
  static const Color canvasBorder = Color(0x1FFFFFFF);

  /// Body text on dark surfaces.
  static const Color onCanvas = Color(0xFFFFFFFF);
  static const Color onCanvasMuted = Color(0xB3FFFFFF);
  static const Color onCanvasFaint = Color(0x80FFFFFF);

  /// Scrim used over hero photography so copy stays legible.
  static const LinearGradient heroScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x8A17090F),
      Color(0x3317090F),
      Color(0xB317090F),
      Color(0xF217090F),
    ],
    stops: [0.0, 0.34, 0.72, 1.0],
  );

  /// Scrim for option/experience cards — lighter at the top, solid at the
  /// bottom where the label sits.
  static const LinearGradient cardScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x0017090F),
      Color(0x5917090F),
      Color(0xE617090F),
    ],
    stops: [0.35, 0.65, 1.0],
  );

  /// Maximum content width so the studio does not stretch into unreadable
  /// line lengths on tablets.
  static const double maxContentWidth = 560;
}

/// Maps an API category name onto a meaningful glyph.
///
/// This is presentation only — it never invents a category, it just picks an
/// icon for whatever name the API returned (and falls back gracefully).
class StudioIcons {
  const StudioIcons._();

  static IconData forCategory(String name) {
    final n = name.toLowerCase();
    if (n.contains('lip')) return Icons.water_drop_rounded;
    if (n.contains('blush')) return Icons.brightness_1_rounded;
    if (n.contains('found')) return Icons.format_paint_rounded;
    if (n.contains('conceal')) return Icons.healing_rounded;
    if (n.contains('contour')) return Icons.gradient_rounded;
    if (n.contains('eyeshadow') || n.contains('eye')) {
      return Icons.remove_red_eye_rounded;
    }
    if (n.contains('kajal') || n.contains('liner')) return Icons.edit_rounded;
    if (n.contains('mascara')) return Icons.brush_rounded;
    if (n.contains('lens') || n.contains('contact')) {
      return Icons.lens_blur_rounded;
    }
    if (n.contains('bindi')) return Icons.circle_rounded;
    return Icons.auto_awesome_rounded;
  }
}

// ---------------------------------------------------------------------------
// Images
// ---------------------------------------------------------------------------

/// Renders whatever the products API happens to hand back for an image field:
/// a `data:image/...;base64,` URI, an http(s) URL, or nothing at all.
///
/// Base64 payloads are decoded once and memoised — the previous code decoded
/// on every single build of every rail item, which is the kind of thing that
/// makes a horizontal list stutter.
class StudioImage extends StatelessWidget {
  const StudioImage({
    super.key,
    required this.source,
    this.fit = BoxFit.cover,
    this.radius = AppRadii.sm,
    this.background,
    this.placeholderIcon = Icons.image_outlined,
    this.placeholderColor,
  });

  final String? source;
  final BoxFit fit;
  final double radius;
  final Color? background;
  final IconData placeholderIcon;
  final Color? placeholderColor;

  static final Map<String, Uint8List?> _decoded = <String, Uint8List?>{};

  static Uint8List? _bytesFor(String dataUri) {
    if (_decoded.containsKey(dataUri)) return _decoded[dataUri];
    Uint8List? bytes;
    try {
      bytes = base64Decode(dataUri.split(',').last);
    } catch (_) {
      bytes = null;
    }
    // Keep the cache from growing without bound on long catalogues.
    if (_decoded.length > 120) _decoded.clear();
    _decoded[dataUri] = bytes;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final src = source?.trim() ?? '';
    final borderRadius = BorderRadius.circular(radius);

    Widget fallback() => DecoratedBox(
          decoration: BoxDecoration(
            color: background ?? AppColors.background,
            borderRadius: borderRadius,
          ),
          child: Center(
            child: Icon(
              placeholderIcon,
              size: 20,
              color: placeholderColor ?? AppColors.textTertiary,
            ),
          ),
        );

    if (src.isEmpty) return fallback();

    if (src.startsWith('data:image')) {
      final bytes = _bytesFor(src);
      if (bytes == null || bytes.isEmpty) return fallback();
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.memory(
          bytes,
          fit: fit,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback(),
        ),
      );
    }

    if (src.startsWith('http')) {
      return NetworkImageWidget(
        url: src,
        fit: fit,
        borderRadius: borderRadius,
        backgroundColor: background,
        placeholderIcon: placeholderIcon,
      );
    }

    return fallback();
  }
}

// ---------------------------------------------------------------------------
// Chrome
// ---------------------------------------------------------------------------

/// The studio's app bar. Transparent by default so it can sit over artwork;
/// pass [onCanvas] false when it sits on a light surface.
class StudioTopBar extends StatelessWidget {
  const StudioTopBar({
    super.key,
    this.title,
    this.subtitle,
    this.onCanvas = true,
    this.trailing,
    this.centerTitle = true,
  });

  final String? title;
  final String? subtitle;
  final bool onCanvas;
  final Widget? trailing;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final fg = onCanvas ? StudioTokens.onCanvas : AppColors.textPrimary;
    final sub = onCanvas ? StudioTokens.onCanvasMuted : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          AppBackButton(color: fg),
          Expanded(
            child: Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    textAlign: centerTitle ? TextAlign.center : TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.pageTitle.copyWith(color: fg),
                  ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      textAlign:
                          centerTitle ? TextAlign.center : TextAlign.start,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: sub),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 44,
            child: trailing == null
                ? null
                : Align(alignment: Alignment.centerRight, child: trailing),
          ),
        ],
      ),
    );
  }
}

/// Small uppercase eyebrow used above studio headlines.
class StudioEyebrow extends StatelessWidget {
  const StudioEyebrow({
    super.key,
    required this.label,
    this.icon,
    this.onCanvas = true,
  });

  final String label;
  final IconData? icon;
  final bool onCanvas;

  @override
  Widget build(BuildContext context) {
    final fg = onCanvas ? StudioTokens.onCanvas : AppColors.primaryDeep;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: onCanvas
            ? Colors.white.withValues(alpha: 0.12)
            : AppColors.blushDeep,
        borderRadius: AppRadii.rPill,
        border: Border.all(
          color: onCanvas
              ? Colors.white.withValues(alpha: 0.22)
              : AppColors.pinkSurfaceStrong,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.overline.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent chip used over photography (before/after tags, status pills).
class StudioGlassChip extends StatelessWidget {
  const StudioGlassChip({
    super.key,
    required this.label,
    this.icon,
    this.accent,
  });

  final String label;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: StudioTokens.canvas.withValues(alpha: 0.62),
        borderRadius: AppRadii.rPill,
        border: Border.all(color: StudioTokens.canvasBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (accent != null) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
          ] else if (icon != null) ...[
            Icon(icon, size: 13, color: StudioTokens.onCanvas),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppText.caption.copyWith(
              color: StudioTokens.onCanvas,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hairline corner ticks that frame hero photography.
///
/// Replaces the old heavy 3px white L-brackets with a restrained inset frame.
class StudioFramePainter extends CustomPainter {
  const StudioFramePainter({this.inset = 22, this.tick = 26, this.opacity = 0.5});

  final double inset;
  final double tick;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= inset * 2 || size.height <= inset * 2) return;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final l = inset;
    final t = inset;
    final r = size.width - inset;
    final b = size.height - inset;
    final len = tick.clamp(8.0, size.shortestSide / 3);

    void corner(Offset origin, double dx, double dy) {
      canvas.drawLine(origin, origin.translate(dx * len, 0), paint);
      canvas.drawLine(origin, origin.translate(0, dy * len), paint);
    }

    corner(Offset(l, t), 1, 1);
    corner(Offset(r, t), -1, 1);
    corner(Offset(l, b), 1, -1);
    corner(Offset(r, b), -1, -1);
  }

  @override
  bool shouldRepaint(covariant StudioFramePainter old) =>
      old.inset != inset || old.tick != tick || old.opacity != opacity;
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

/// Full-bleed photographic tile used on the "choose one" screens.
///
/// [available] false does not disable the tile — the existing screens still
/// respond to a tap (with a "coming soon" snackbar), so the card only signals
/// status rather than swallowing the gesture.
class StudioOptionCard extends StatelessWidget {
  const StudioOptionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.onTap,
    this.subtitle,
    this.available = true,
    this.availableLabel = 'Available now',
    this.comingSoonLabel = 'Coming soon',
    this.aspectRatio = 16 / 11,
    this.fallbackIcon = Icons.person_rounded,
  });

  final String title;
  final String imagePath;
  final VoidCallback onTap;
  final String? subtitle;
  final bool available;
  final String availableLabel;
  final String comingSoonLabel;
  final double aspectRatio;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: available ? title : '$title, $comingSoonLabel',
      child: Pressable(
        onTap: onTap,
        scale: 0.985,
        borderRadius: AppRadii.rXl,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadii.rXl,
            boxShadow: AppColors.shadowMd,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.rXl,
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: StudioTokens.canvas,
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(
                          fallbackIcon,
                          size: 56,
                          color: StudioTokens.onCanvasFaint,
                        ),
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(gradient: StudioTokens.cardScrim),
                    child: SizedBox.expand(),
                  ),

                  // Status pill
                  Positioned(
                    top: AppSpacing.md,
                    left: AppSpacing.md,
                    child: available
                        ? StudioGlassChip(
                            label: availableLabel,
                            accent: AppColors.success,
                          )
                        : StudioGlassChip(
                            label: comingSoonLabel,
                            icon: Icons.schedule_rounded,
                          ),
                  ),

                  // Title block
                  Positioned(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.sectionTitle.copyWith(
                                  color: StudioTokens.onCanvas,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              if (subtitle != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.bodySm.copyWith(
                                      color: StudioTokens.onCanvasMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: available
                                ? AppColors.primary
                                : Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: available
                                  ? Colors.transparent
                                  : StudioTokens.canvasBorder,
                            ),
                          ),
                          child: Icon(
                            available
                                ? Icons.arrow_forward_rounded
                                : Icons.lock_outline_rounded,
                            size: 18,
                            color: StudioTokens.onCanvas,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single "how to get the best result" guideline row.
class StudioTipRow extends StatelessWidget {
  const StudioTipRow({
    super.key,
    required this.icon,
    required this.title,
    this.onCanvas = false,
  });

  final IconData icon;
  final String title;
  final bool onCanvas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onCanvas
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.blushDeep,
            ),
            child: Icon(
              icon,
              size: 14,
              color: onCanvas ? StudioTokens.onCanvas : AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                title,
                style: AppText.bodySm.copyWith(
                  color: onCanvas
                      ? StudioTokens.onCanvasMuted
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium consent row — replaces the stock [Checkbox] + [Row].
class StudioConsentTile extends StatelessWidget {
  const StudioConsentTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      button: true,
      child: Pressable(
        onTap: () => onChanged(!value),
        scale: 0.995,
        borderRadius: AppRadii.rMd,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: value ? AppColors.blush : AppColors.surface,
            borderRadius: AppRadii.rMd,
            border: Border.all(
              color: value ? AppColors.primaryLight : AppColors.divider,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? AppColors.primary : Colors.transparent,
                  borderRadius: AppRadii.rXs,
                  border: Border.all(
                    color: value ? AppColors.primary : AppColors.textTertiary,
                    width: 1.6,
                  ),
                ),
                child: AnimatedOpacity(
                  duration: AppMotion.fast,
                  opacity: value ? 1 : 0,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  text,
                  style: AppText.bodySm.copyWith(
                    color: AppColors.textDark,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Editor chrome
// ---------------------------------------------------------------------------

/// Animated pill tab bar for the editor's three views.
class StudioSegmentedTabs extends StatelessWidget {
  const StudioSegmentedTabs({
    super.key,
    required this.labels,
    required this.icons,
    required this.index,
    required this.onChanged,
  });

  final List<String> labels;
  final List<IconData> icons;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(labels.length == icons.length);
    // Icon-only below this width so three labels never clip.
    final tight = MediaQuery.sizeOf(context).width < AppBreakpoints.compact;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.rPill,
        border: Border.all(color: AppColors.divider),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = labels.length;
          final itemWidth = constraints.maxWidth / count;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                left: itemWidth * index,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppColors.brandGradientH,
                    borderRadius: AppRadii.rPill,
                    boxShadow: AppColors.shadowSm,
                  ),
                ),
              ),
              Row(
                children: List.generate(count, (i) {
                  final selected = i == index;
                  final fg = selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary;
                  return Expanded(
                    child: Semantics(
                      selected: selected,
                      button: true,
                      label: labels[i],
                      child: Pressable(
                        onTap: () => onChanged(i),
                        scale: 0.97,
                        borderRadius: AppRadii.rPill,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icons[i], size: 15, color: fg),
                              if (!tight) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    labels[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppText.buttonSm.copyWith(color: fg),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Full-cover processing overlay for the photo stage.
class StudioProcessingOverlay extends StatelessWidget {
  const StudioProcessingOverlay({
    super.key,
    required this.message,
    this.radius = AppRadii.xl,
  });

  final String message;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: StudioTokens.canvas.withValues(alpha: 0.66),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoader(color: Colors.white, size: 30),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(color: StudioTokens.onCanvas),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: 132,
                  child: ClipRRect(
                    borderRadius: AppRadii.rPill,
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal intensity control docked under the stage.
class StudioIntensitySlider extends StatelessWidget {
  const StudioIntensitySlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.swatch,
    this.enabled = true,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final String label;
  final Color? swatch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          if (swatch != null) ...[
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: swatch,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppText.labelSm.copyWith(color: AppColors.textSecondary),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.divider,
                thumbColor: AppColors.surface,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 9,
                  elevation: 2,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: enabled ? onChanged : null,
              ),
            ),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '$pct%',
              textAlign: TextAlign.end,
              style: AppText.labelSm.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Breadcrumb + back control for the categories → brands → shades drill-down.
class StudioBreadcrumb extends StatelessWidget {
  const StudioBreadcrumb({
    super.key,
    required this.crumbs,
    this.onBack,
    this.trailing,
  });

  /// Ordered trail; the last entry is the current level.
  final List<String> crumbs;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          if (onBack != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Pressable(
                onTap: onBack,
                borderRadius: AppRadii.rPill,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.blush,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.pinkSurface),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 17,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < crumbs.length; i++) ...[
                  if (i > 0)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 15,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  Flexible(
                    child: Text(
                      crumbs[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: i == crumbs.length - 1
                          ? AppText.cardTitle
                          : AppText.labelSm.copyWith(
                              color: AppColors.textTertiary,
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }
}

/// Small count pill used beside breadcrumbs and section headers.
class StudioCountPill extends StatelessWidget {
  const StudioCountPill({super.key, required this.count, this.noun});

  final int count;
  final String? noun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.blushDeep,
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        noun == null ? '$count' : '$count $noun',
        style: AppText.caption.copyWith(
          color: AppColors.primaryDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Picker tiles
// ---------------------------------------------------------------------------

/// Category tile. Uses the API's own `product_detailed_image` when the
/// response carries one, and falls back to a name-derived glyph when it
/// does not — no invented artwork either way.
class StudioCategoryTile extends StatelessWidget {
  const StudioCategoryTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    this.imageSource,
    this.itemCount,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final String? imageSource;
  final int? itemCount;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageSource?.trim().isNotEmpty ?? false);

    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: Pressable(
        onTap: onTap,
        scale: 0.96,
        borderRadius: AppRadii.rLg,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          width: 96,
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? AppColors.blush : AppColors.surface,
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? AppColors.shadowSm : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: hasImage
                    ? StudioImage(
                        source: imageSource,
                        radius: AppRadii.sm,
                        background: AppColors.background,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.pinkSurface
                              : AppColors.background,
                          borderRadius: AppRadii.rSm,
                        ),
                        child: Icon(
                          StudioIcons.forCategory(name),
                          size: 21,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: selected
                    ? AppText.labelSm.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w600,
                      )
                    : AppText.labelSm,
              ),
              if (itemCount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    '$itemCount',
                    style: AppText.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brand/product tile with a live preview strip of that product's own shades.
class StudioBrandTile extends StatelessWidget {
  const StudioBrandTile({
    super.key,
    required this.name,
    required this.selected,
    required this.onTap,
    required this.shades,
    this.imageSource,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final List<Color> shades;
  final String? imageSource;

  @override
  Widget build(BuildContext context) {
    const maxDots = 5;
    final dots = shades.take(maxDots).toList();
    final extra = shades.length - dots.length;

    return Semantics(
      selected: selected,
      button: true,
      label: name,
      child: Pressable(
        onTap: onTap,
        scale: 0.97,
        borderRadius: AppRadii.rLg,
        child: AnimatedContainer(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          width: 176,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.blush : AppColors.surface,
            borderRadius: AppRadii.rLg,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
              width: selected ? 1.6 : 1,
            ),
            boxShadow: selected ? AppColors.shadowSm : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  SizedBox(
                    width: 38,
                    height: 38,
                    child: StudioImage(
                      source: imageSource,
                      radius: AppRadii.sm,
                      background: AppColors.background,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: selected
                          ? AppText.label.copyWith(
                              color: AppColors.primaryDeep,
                              fontWeight: FontWeight.w600,
                            )
                          : AppText.label,
                    ),
                  ),
                ],
              ),
              if (dots.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    for (final c in dots)
                      Container(
                        width: 13,
                        height: 13,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.4,
                          ),
                          boxShadow: AppColors.shadowSm,
                        ),
                      ),
                    if (extra > 0)
                      Text(
                        '+$extra',
                        style: AppText.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shade swatch with a selected ring and check affordance.
class StudioShadeSwatch extends StatelessWidget {
  const StudioShadeSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  /// Picks black or white for the check glyph so it stays legible on any shade.
  Color get _onColor =>
      color.computeLuminance() > 0.55 ? AppColors.textPrimary : Colors.white;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label ?? 'Shade',
      child: Pressable(
        onTap: onTap,
        scale: 0.94,
        child: SizedBox(
          width: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AppMotion.fast,
                curve: AppMotion.standard,
                width: 52,
                height: 52,
                padding: EdgeInsets.all(selected ? 3 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: selected ? 2 : 0,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: AnimatedOpacity(
                    duration: AppMotion.fast,
                    opacity: selected ? 1 : 0,
                    child: Icon(
                      Icons.check_rounded,
                      size: 19,
                      color: _onColor,
                    ),
                  ),
                ),
              ),
              if (label != null) ...[
                const SizedBox(height: 6),
                Text(
                  label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(
                    color: selected
                        ? AppColors.primaryDeep
                        : AppColors.textTertiary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary card for one applied product in the finished look.
class StudioLookCard extends StatelessWidget {
  const StudioLookCard({
    super.key,
    required this.category,
    required this.brand,
    required this.swatch,
    required this.detail,
  });

  final String category;
  final String brand;
  final Color swatch;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: AppRadii.rSm,
              border: Border.all(color: AppColors.divider),
              boxShadow: AppColors.shadowSm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardTitle,
                ),
                Text(
                  brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.cardSubtitle,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            detail,
            style: AppText.caption.copyWith(
              color: AppColors.primaryDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Centres and width-caps studio content so tablets do not stretch it.
class StudioContent extends StatelessWidget {
  const StudioContent({super.key, required this.child, this.maxWidth});

  final Widget child;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? StudioTokens.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
