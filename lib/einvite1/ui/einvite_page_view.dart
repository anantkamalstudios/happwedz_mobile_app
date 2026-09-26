/// Draws one e-invite page exactly as the website does.
///
/// Port of the web's `EinvitePage` component and its field-style function
/// `ce`, read from the live bundle:
///   * the card is `width × width·heightFactor`, on `#f3efea`;
///   * the background is stretched to fill (`objectFit: "fill"`), never
///     cropped — cropping would move the artwork out from under the text;
///   * each field's box sits at `x·W, y·H`, is `width·W` wide (or sizes to its
///     text, unwrapped, when width is null);
///   * font size and letter spacing scale by `W / 1000`.
/// Positions are fractions, so the same card lays out identically at any
/// size — which is what lets the phone and the website share saved cards.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../../core/theme/app_colors.dart';
import '../data/einvite_design.dart';

/// The website's card backdrop, shown behind a background still loading.
const Color _kCardBackdrop = Color(0xFFF3EFEA);

class EinvitePageView extends StatelessWidget {
  const EinvitePageView({
    super.key,
    required this.page,
    this.selectedFieldId,
    this.onFieldTap,
    this.videoUrl,
  });

  final EinvitePage page;

  /// Outlined, so the customer can see which field they are editing.
  final String? selectedFieldId;

  final ValueChanged<EinviteField>? onFieldTap;

  /// `card['video']['videoUrl']` for a `cardType: "video"` card.
  ///
  /// When set — and this page is a timed scene ([EinvitePage.start] is
  /// non-null) — the scene's footage plays behind the fields instead of the
  /// poster still. Left null everywhere else, so grid thumbnails keep showing
  /// the cheap poster rather than spinning up a video controller per tile.
  ///
  /// Video cards were unreachable until the category tile's `cardType` was
  /// corrected from `video_invitation` to `video`; this is what makes the
  /// card that fix surfaces actually play.
  final String? videoUrl;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 / page.heightFactor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width * page.heightFactor;
          final scale = width / kDesignWidth;

          return ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: _kCardBackdrop),
                ),
                if (page.backgroundUrl.isNotEmpty)
                  Positioned.fill(
                    child: Image.network(
                      page.backgroundUrl,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      // The website drops a background that fails to load and
                      // shows the backdrop; the text stays readable either way.
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                // Drawn over the poster, so a failure to load or decode the
                // footage degrades to the still rather than to a blank card.
                if (videoUrl != null &&
                    videoUrl!.isNotEmpty &&
                    page.start != null)
                  Positioned.fill(
                    child: _ScenePlayer(
                      url: videoUrl!,
                      start: page.start!,
                      end: page.end,
                    ),
                  ),
                for (final field in page.fields)
                  Positioned(
                    left: field.x * width,
                    top: field.y * height,
                    width: field.width == null ? null : field.width! * width,
                    child: _FieldText(
                      field: field,
                      scale: scale,
                      selected: field.id == selectedFieldId,
                      onTap: onFieldTap == null
                          ? null
                          : () => onFieldTap!(field),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Plays one scene of a video invitation, looping between its start and end.
///
/// Muted by design: the card's own `audioUrl` is a separate track the website
/// mixes in, and an invitation that blares sound the moment a grid scrolls
/// past it would be worse than silent. Falls back to rendering nothing — so
/// the poster underneath shows through — on any initialisation failure.
class _ScenePlayer extends StatefulWidget {
  const _ScenePlayer({
    required this.url,
    required this.start,
    this.end,
  });

  final String url;
  final double start;
  final double? end;

  @override
  State<_ScenePlayer> createState() => _ScenePlayerState();
}

class _ScenePlayerState extends State<_ScenePlayer> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void didUpdateWidget(covariant _ScenePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      // Tear the old controller down before opening the new source, or the
      // previous one leaks for the lifetime of the screen.
      final previous = _controller;
      _controller = null;
      previous?.removeListener(_onTick);
      previous?.dispose();
      _failed = false;
      _open();
    } else if (oldWidget.start != widget.start) {
      _seekToStart();
    }
  }

  Future<void> _open() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      await controller.setVolume(0);
      // The scene is a window into one longer file, so looping is driven by
      // the listener below rather than `setLooping`, which would restart the
      // whole video instead of this scene.
      await controller.seekTo(_startPosition);
      await controller.play();
      controller.addListener(_onTick);

      if (!mounted) {
        controller.removeListener(_onTick);
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (e) {
      debugPrint('E-invite scene playback failed: $e');
      await controller.dispose();
      if (!mounted) return;
      setState(() => _failed = true);
    }
  }

  Duration get _startPosition =>
      Duration(milliseconds: (widget.start * 1000).round());

  void _onTick() {
    final controller = _controller;
    final end = widget.end;
    if (controller == null || end == null) return;
    if (!controller.value.isInitialized) return;

    final endPosition = Duration(milliseconds: (end * 1000).round());
    if (controller.value.position >= endPosition) {
      _seekToStart();
    }
  }

  Future<void> _seekToStart() async {
    final controller = _controller;
    if (controller == null) return;
    await controller.seekTo(_startPosition);
    if (!controller.value.isPlaying) await controller.play();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onTick);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed || controller == null || !controller.value.isInitialized) {
      // Nothing of our own — the poster still is already painted underneath.
      return const SizedBox.shrink();
    }
    // `BoxFit.fill` matches the still path and the website's `objectFit:
    // "fill"`: the artwork must not be cropped, or the text drifts off it.
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _FieldText extends StatelessWidget {
  const _FieldText({
    required this.field,
    required this.scale,
    required this.selected,
    this.onTap,
  });

  final EinviteField field;
  final double scale;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = field.uppercase
        ? field.defaultText.toUpperCase()
        : field.defaultText;
    final wraps = field.width != null;

    final child = Text(
      text,
      textAlign: _align(field.align),
      // `white-space: pre-wrap` when boxed, `pre` otherwise: newlines are
      // always kept, but only a boxed field wraps long lines.
      softWrap: wraps,
      overflow: TextOverflow.visible,
      // Text scale is part of the design, not an accessibility preference —
      // enlarging it would push fields off the artwork.
      textScaler: TextScaler.noScaling,
      style: einviteTextStyle(field, scale),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // A foreground outline does not change the box's size, so selecting a
      // field never nudges the layout.
      child: Container(
        foregroundDecoration: selected
            ? BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 1.5),
              )
            : null,
        child: child,
      ),
    );
  }

  static TextAlign _align(String align) {
    switch (align) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }
}

/// The text style for [field] on a card drawn at [scale] (card width ÷ 1000).
///
/// Loads the field's Google font by name, as the website does. A family the
/// font service does not know falls back to Playfair Display, then to a serif
/// — the web's `"<family>", Georgia, serif` stack.
TextStyle einviteTextStyle(EinviteField field, double scale) {
  final base = TextStyle(
    fontSize: field.fontSize * scale,
    fontWeight: field.fontWeight >= 700 ? FontWeight.w700 : FontWeight.w400,
    fontStyle:
        field.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
    letterSpacing: field.letterSpacing * scale,
    height: field.lineHeight,
    // CSS line-height splits the extra space evenly above and below the
    // glyphs; Flutter's default does not, which would shift every line.
    leadingDistribution: TextLeadingDistribution.even,
    color: parseCssColor(field.color),
    fontFamilyFallback: const ['Georgia', 'serif'],
  );

  try {
    return GoogleFonts.getFont(field.fontFamily, textStyle: base);
  } catch (_) {
    try {
      return GoogleFonts.playfairDisplay(textStyle: base);
    } catch (_) {
      return base;
    }
  }
}

/// Parses the colour formats the card designer saves (`#rgb`, `#rrggbb`,
/// `#rrggbbaa`). Anything else draws black, the website's default.
Color parseCssColor(String value) {
  var hex = value.trim();
  if (!hex.startsWith('#')) return Colors.black;
  hex = hex.substring(1);

  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) hex = 'ff$hex';
  if (hex.length == 8 && value.trim().length == 9) {
    // CSS is #rrggbbaa; Flutter wants aarrggbb.
    hex = hex.substring(6) + hex.substring(0, 6);
  }

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null || hex.length != 8) return Colors.black;
  return Color(parsed);
}
