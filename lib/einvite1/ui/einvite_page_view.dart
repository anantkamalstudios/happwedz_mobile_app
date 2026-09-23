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
  });

  final EinvitePage page;

  /// Outlined, so the customer can see which field they are editing.
  final String? selectedFieldId;

  final ValueChanged<EinviteField>? onFieldTap;

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
