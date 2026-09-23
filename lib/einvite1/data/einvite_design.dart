/// The e-invite card model, ported from the website's `einviteDesign.js`.
///
/// **Source.** `src (1)` is missing `layouts/einvites/design/` entirely, so
/// every rule here was read from the live production bundle instead
/// (`happywedz.com/assets/EinvitePage-*.js`, 2026-09-21): the field
/// normaliser `v`, the legacy converters `se`/`ne`, the page builder `Se`, and
/// the render maths in `ce`. Where a rule looks odd it is because the website
/// does it that way — cards saved from the app must open unchanged on the web
/// and vice versa, so this is a port, not a redesign.
///
/// **Why the old editor could not be kept.** Every live template is
/// `designVersion: 2`: a field's `x`/`y`/`width` are *fractions of the card*
/// (0.1 = 10% across) and `fontSize` is in units of a 1000-wide canvas. The
/// previous editor placed `x`/`y` as raw pixels, so every field landed in the
/// top-left corner at many times the card's size — and saving from it would
/// have written pixel positions back into cards the website reads as
/// fractions.
library;

import 'dart:convert';
import 'dart:math' as math;

/// The design canvas width that `fontSize` and `letterSpacing` are measured
/// against (`k=1e3` in the bundle). A card drawn `w` pixels wide scales text
/// by `w / kDesignWidth`.
const double kDesignWidth = 1000;

/// Height ÷ width of a still card page (`V=1.4`).
const double kCardAspect = 1.4;

/// Height ÷ width of a video scene (`B=16/9`).
const double kSceneAspect = 16 / 9;

/// Default scene length in seconds when a video has none (`G=10`).
const double _kDefaultSceneSeconds = 10;

/// Upper bound on a field's animation delay in seconds (`z=60`).
const double _kMaxAnimDelay = 60;

/// Entrance animations the website knows (`J`); anything else becomes "fade".
const List<String> kFieldAnimations = [
  'none',
  'fade',
  'slide-up',
  'zoom-in',
  'reveal',
];

const List<String> _kAligns = ['left', 'center', 'right'];

/// One editable line or block of text on a card page.
///
/// Holds exactly the keys the website's normaliser emits, in the same shape,
/// so [toJson] produces what the web itself would save.
class EinviteField {
  EinviteField({
    required this.id,
    required this.label,
    required this.defaultText,
    required this.x,
    required this.y,
    required this.width,
    required this.align,
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.fontWeight,
    required this.fontStyle,
    required this.letterSpacing,
    required this.lineHeight,
    required this.uppercase,
    required this.characterLimit,
    required this.required,
    required this.animation,
    required this.animDelay,
  });

  final String id;
  final String label;

  /// The text shown on the card. The website stores the *customer's* text in
  /// this same key — there is no separate "value" field.
  String defaultText;

  /// Left edge as a fraction of card width.
  final double x;

  /// Top edge as a fraction of card height.
  final double y;

  /// Box width as a fraction of card width, or null for an unwrapped line
  /// that sizes to its text (`white-space: pre`).
  final double? width;

  final String align;
  final String fontFamily;

  /// In [kDesignWidth] units, not screen pixels.
  double fontSize;

  final String color;

  /// Either 400 or 700 — the website collapses everything else.
  final int fontWeight;

  final String fontStyle;
  final double letterSpacing;
  final double lineHeight;
  final bool uppercase;
  final int? characterLimit;
  final bool required;
  final String animation;
  final double animDelay;

  /// The most characters the text box accepts — the field's own limit, else
  /// the website's textarea cap of 1000.
  int get maxLength => characterLimit ?? 1000;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'defaultText': defaultText,
        'x': x,
        'y': y,
        'width': width,
        'align': align,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'color': color,
        'fontWeight': fontWeight,
        'fontStyle': fontStyle,
        'letterSpacing': letterSpacing,
        'lineHeight': lineHeight,
        'uppercase': uppercase,
        'characterLimit': characterLimit,
        'required': required,
        'animation': animation,
        'animDelay': animDelay,
      };

  /// Port of the website's field normaliser `v(e, t)`.
  ///
  /// [index] is the field's position *after* image fields are filtered out,
  /// matching `.filter(A).map(v)`; it only feeds the fallback id and label.
  static EinviteField normalize(Map<String, dynamic> e, int index) {
    final width = e['width'];
    final limit = e['characterLimit'];
    final animation = e['animation'];
    final align = e['align'];
    final family = e['fontFamily'];
    final color = e['color'];

    return EinviteField(
      id: _truthyString(e['id']) ??
          'field_${DateTime.now().millisecondsSinceEpoch}_$index',
      label: _truthyString(e['label']) ?? 'Text ${index + 1}',
      defaultText: e['defaultText'] is String ? e['defaultText'] as String : '',
      x: _h(e, 'x', -0.5, 1.5, 0.1),
      y: _h(e, 'y', -0.5, 1.5, 0.1),
      width: width == null ? null : _h(e, 'width', 0.02, 1.5, 0.8),
      align: _kAligns.contains(align) ? align as String : 'center',
      fontFamily: _truthyString(family) ?? 'Playfair Display',
      fontSize: _h(e, 'fontSize', 4, 400, 48),
      color: _truthyString(color) ?? '#000000',
      fontWeight: _jsNumber(e, 'fontWeight') >= 600 ? 700 : 400,
      fontStyle: e['fontStyle'] == 'italic' ? 'italic' : 'normal',
      letterSpacing: _h(e, 'letterSpacing', -20, 100, 0),
      lineHeight: _h(e, 'lineHeight', 0.6, 3, 1.2),
      uppercase: e['uppercase'] == true,
      characterLimit: (limit == null || limit == '')
          ? null
          : _h(e, 'characterLimit', 1, 1000, 100).round(),
      required: e['required'] == true,
      animation: kFieldAnimations.contains(animation)
          ? animation as String
          : 'fade',
      animDelay: _h(e, 'animDelay', 0, _kMaxAnimDelay, 0),
    );
  }
}

/// One page of a card (or one scene of a video invitation).
class EinvitePage {
  EinvitePage({
    required this.id,
    required this.name,
    required this.backgroundUrl,
    required this.fields,
    this.aspect,
    this.start,
    this.end,
  });

  final String id;
  final String name;
  final String backgroundUrl;
  final List<EinviteField> fields;

  /// Only set for video scenes; still pages use [kCardAspect].
  final double? aspect;
  final double? start;
  final double? end;

  /// Height ÷ width — port of `K`.
  double get heightFactor =>
      aspect ?? (start != null ? kSceneAspect : kCardAspect);

  /// The shape the website saves (`pages.map(p => ({id, name,
  /// backgroundUrl, fields}))`). Scene timing is not part of a card save.
  Map<String, dynamic> toSaveJson() => {
        'id': id,
        'name': name,
        'backgroundUrl': backgroundUrl,
        'fields': fields.map((f) => f.toJson()).toList(),
      };
}

/// Port of the website's `getCardPages` (`Se`).
///
/// A card with a non-empty `pages` array is read page by page. Older cards
/// carry a single `editableFields` list instead: design-version-2 lists are
/// already in fractions, while version-1 lists are converted from the two
/// legacy pixel canvases the website used to use.
List<EinvitePage> getCardPages(Map<String, dynamic>? card) {
  if (card == null) return const [];

  final pages = card['pages'];
  if (pages is List && pages.isNotEmpty) {
    final isVideo = card['cardType'] == 'video';
    final video = card['video'];
    final videoDuration = video is Map ? _jsNumberOf(video['duration']) : 0.0;

    return [
      for (var s = 0; s < pages.length; s++)
        _buildPage(pages[s], s, isVideo, videoDuration),
    ];
  }

  final legacy = _parseList(card['editableFields'])
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .where(_isTextField)
      .toList();

  final isV2 = _jsNumber(card, 'designVersion') >= 2;
  EinviteField Function(Map<String, dynamic>, int) convert =
      EinviteField.normalize;
  if (!isV2) {
    convert = card['isTemplate'] == false
        ? _fromLegacyInstance
        : _fromLegacyTemplate;
  }

  return [
    EinvitePage(
      id: 'page_1',
      name: 'Page 1',
      backgroundUrl: _truthyString(card['backgroundUrl']) ??
          _truthyString(card['background_url']) ??
          '',
      fields: [
        for (var i = 0; i < legacy.length; i++) convert(legacy[i], i),
      ],
    ),
  ];
}

EinvitePage _buildPage(
  dynamic raw,
  int s,
  bool isVideo,
  double videoDuration,
) {
  final r = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
  final fields = _parseList(r['fields'])
      .whereType<Map>()
      .map((m) => Map<String, dynamic>.from(m))
      .where(_isTextField)
      .toList();

  double? start;
  double? end;
  if (isVideo) {
    start = _orZero(_jsNumber(r, 'start'));
    final ownEnd = _orZero(_jsNumber(r, 'end'));
    end = ownEnd != 0
        ? ownEnd
        : (videoDuration.isFinite && videoDuration != 0
            ? videoDuration
            : _kDefaultSceneSeconds);
  }

  return EinvitePage(
    id: _truthyString(r['id']) ?? 'page_${s + 1}',
    name: _truthyString(r['name']) ?? 'Page ${s + 1}',
    backgroundUrl: _truthyString(r['backgroundUrl']) ?? '',
    fields: [
      for (var i = 0; i < fields.length; i++)
        EinviteField.normalize(fields[i], i),
    ],
    aspect: isVideo ? kSceneAspect : null,
    start: start,
    end: end,
  );
}

/// Port of `A` (`!e.src && e.label !== "image" && e.defaultText !==
/// "image"`): image placeholders are drawn by the background, not edited.
bool _isTextField(Map<String, dynamic> e) {
  final src = e['src'];
  final hasImage = !(src == null || src == false || src == '' || src == 0);
  return !hasImage && e['label'] != 'image' && e['defaultText'] != 'image';
}

/// Port of `se` — version-1 templates, drawn on a 350×500 canvas with `y`
/// measured to the text baseline.
EinviteField _fromLegacyTemplate(Map<String, dynamic> e, int index) {
  final size = _orDefault(_jsNumber(e, 'fontSize'), 24);
  return EinviteField.normalize({
    ...e,
    'x': _orZero(_jsNumber(e, 'x')) / 350,
    'y': (_orZero(_jsNumber(e, 'y')) - size * 0.85) / 500,
    'width': null,
    'align': 'left',
    'fontSize': size * kDesignWidth / 350,
    'lineHeight': 1.15,
  }, index);
}

/// Port of `ne` — version-1 customer copies, saved from a 414×659.288
/// canvas-editor with its own origin and scale conventions.
EinviteField _fromLegacyInstance(Map<String, dynamic> e, int index) {
  final size = _orDefault(_jsNumber(e, 'fontSize'), 30) *
      _orDefault(_jsNumber(e, 'scaleX'), 1);
  final centred = e['originX'] == 'center';

  var x = _orDefault(_jsNumber(e, 'x'), 414 / 2) / 414;
  var y = _orDefault(_jsNumber(e, 'y'), 100) / 659.288;
  if (e['originY'] == 'center') y -= size * 1.16 / 2 / 659.288;
  if (centred) x -= 0.4;

  final weight = e['fontWeight'];
  return EinviteField.normalize({
    ...e,
    'x': x,
    'y': y,
    'width': centred ? 0.8 : null,
    'align': centred ? 'center' : (_truthyString(e['textAlign']) ?? 'left'),
    'fontSize': size * kDesignWidth / 414,
    'fontWeight': (weight == 'bold' || _jsNumberOf(weight) >= 600) ? 700 : 400,
    'lineHeight': 1.16,
  }, index);
}

// -----------------------------------------------------------------------------
// JavaScript coercion, reproduced so edge cases match the website exactly.
// -----------------------------------------------------------------------------

/// `N` — a list, or a JSON-encoded list, else empty.
List<dynamic> _parseList(dynamic value) {
  if (value is List) return value;
  if (value is String) {
    try {
      final decoded = jsonDecode(value);
      return decoded is List ? decoded : const [];
    } catch (_) {
      return const [];
    }
  }
  return const [];
}

/// `h(value, min, max, fallback)`: clamp when `Number(value)` is finite,
/// otherwise the fallback.
double _h(Map<String, dynamic> e, String key, double min, double max,
    double fallback) {
  final r = _jsNumber(e, key);
  if (!r.isFinite) return fallback;
  return math.min(max, math.max(min, r));
}

/// `Number(e[key])`, treating a missing key as `undefined` (NaN) and an
/// explicit null as `null` (0) — the distinction JavaScript makes.
double _jsNumber(Map<String, dynamic> e, String key) {
  if (!e.containsKey(key)) return double.nan;
  return _jsNumberOf(e[key]);
}

double _jsNumberOf(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is bool) return value ? 1 : 0;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 0;
    return double.tryParse(trimmed) ?? double.nan;
  }
  return double.nan;
}

/// `Number(v) || fallback` — NaN and 0 both fall through.
double _orDefault(double value, double fallback) =>
    (value.isNaN || value == 0) ? fallback : value;

double _orZero(double value) => value.isNaN ? 0 : value;

/// A non-empty string, else null — JavaScript's `value || fallback` for the
/// string-typed keys here.
String? _truthyString(dynamic value) {
  if (value is String && value.isNotEmpty) return value;
  if (value is num && value != 0) return value.toString();
  return null;
}
