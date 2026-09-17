/// Generic "Facilities & Features" renderer for a vendor's `*_master`
/// attribute — the rich per-category profile a vendor fills in through their
/// own dashboard (`venue_master` today; `photographer_master`,
/// `caterer_master` and so on the same way for every other category, since
/// the admin side already defines a master schema per category —
/// `components/pages/adminVendor/subVendors/*MasterConstants.js` on the
/// website, ~25 of them).
///
/// One renderer walks whichever `_master` object is present rather than
/// hand-porting each category's field list: every group (`identity`,
/// `rooms`, `food`, …) becomes a labelled block, every non-empty field
/// inside it becomes a row. This is what makes the section work identically
/// for a venue today and for a photographer or caterer tomorrow, with no
/// per-category code.
library;

import 'package:flutter/material.dart';

import '../core/core.dart';

/// Labels for the handful of group keys whose meaning is not obvious from a
/// plain Title Case of the key ("bookingFlex" does not read as "Booking &
/// Usage" on its own). Any group not listed here falls back to Title Case,
/// so a category-specific group nobody has special-cased yet still renders
/// sensibly instead of being dropped.
const Map<String, String> _groupLabels = {
  'identity': 'Property Identity',
  'categories': 'Highlights',
  'space_capacity': 'Space & Capacity',
  'pricing_booking': 'Pricing & Booking',
  'suitability': 'Suitability',
  'entertainment': 'Entertainment',
  'facilities': 'On-site Facilities',
  'rooms': 'Rooms & Stay',
  'alcohol': 'Alcohol',
  'food': 'Food & Catering',
  'decor': 'Decor',
};

/// Labels for the `categories` group's sub-keys specifically — these are
/// pre-bucketed category tags (`premium`, `locationBased`, …) whose values
/// are lists, and a naive Title Case of the key reads badly
/// ("bookingFlex" → "Booking Flex" instead of "Booking & Usage").
const Map<String, String> _categoryFieldLabels = {
  'premium': 'Premium & Experience',
  'locationBased': 'Location Based',
  'capacityBased': 'Capacity Based',
  'budgetBased': 'Budget Based',
  'functionSpecific': 'Function Specific',
  'facilityBased': 'Facility Based',
  'bookingFlex': 'Booking & Usage',
  'trendModern': 'Trend & Modern',
  'primary': 'Primary Category',
};

/// Groups whose content is internal (AI/CMS metadata) rather than something a
/// couple browsing the listing would want to read.
const Set<String> _hiddenGroups = {'image_intelligence'};

/// snake_case or camelCase -> "Title Case With Spaces".
String _titleCase(String key) {
  final spaced = key
      .replaceAll('_', ' ')
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      );
  return spaced
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

/// Renders one value for display, or null when there is nothing worth
/// showing (empty string/list, a bare `false`, an empty nested object).
String? _displayValue(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is bool) {
    // A lone boolean only says something when it is a "does this exist"
    // flag; most of these fields are strings like "Yes"/"No" already, so a
    // literal bool is rare, but when it shows up `true` alone is not
    // self-explanatory without the field's own label — the caller supplies
    // that, so this just renders Yes/No.
    return value ? 'Yes' : null;
  }
  if (value is num) return value.toString();
  if (value is List) {
    final items = value
        .map((e) => e is Map ? null : e?.toString().trim())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
    return items.isEmpty ? null : items.join(', ');
  }
  // Nested maps (`room_type_counts`, `spaces: [...]`) carry structure this
  // generic renderer does not attempt to lay out — they are skipped rather
  // than dumped as a raw Dart-map string.
  return null;
}

/// Builds a `masterAttrs`-shaped fallback from the flat legacy fields every
/// vendor-service already has (`parking`, `dJ_policy`, `rooms`, … for
/// venues; `Payment`, `Travel`, `Delivery`, `Offerings`, `PriceRange`, … for
/// photographers/makeup-artists/other service categories — the two schemas
/// don't overlap, so this just includes whichever fields are present), for a
/// vendor whose dashboard profile (`*_master`) hasn't been filled in yet.
/// Mirrors the website's own flat-field fallbacks in `getVendorFeatures()`
/// (`Detailed.jsx` — the venue block plus the "PHOTOGRAPHER/OTHER VENDOR"
/// block) so any vendor without a master profile still shows what it
/// already has instead of an empty section. Deliberately excludes fields
/// this screen already renders in their own dedicated section — decor/
/// catering policy (Policies), veg/non-veg price (Pricing), area (Spaces).
Map<String, dynamic> buildFallbackMasterAttrs(Map<String, dynamic> attributes) {
  String? str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  // Non-venue categories imported from the legacy site kept two parallel
  // copies of several fields — a newer snake_case one and an older
  // PascalCase one — and either can be the one actually filled in (see
  // `vendor_name`/`Name`, `about_us`/`Aboutus`, `Phone` elsewhere on this
  // screen for the same pattern), so both are checked.
  String? pick(String snakeCase, String pascalCase) =>
      str(attributes[snakeCase]) ?? str(attributes[pascalCase]);

  final groups = <String, Map<String, dynamic>>{
    'facilities': {'parking': str(attributes['parking'])},
    'entertainment': {'dj_policy': str(attributes['dJ_policy'])},
    'alcohol': {
      'policy': str(attributes['outside_alcohol'] ?? attributes['alcohol_policy']),
    },
    'rooms': {
      'num_rooms': str(attributes['rooms']),
      'space_type': str(attributes['space']),
    },
    'identity': {
      'established': str(attributes['start_venue']),
      'on_happywedz_since': pick('happywedz_since', 'HappyWedz'),
    },
    'pricing_booking': {
      'payment_terms': pick('payment_terms', 'Payment'),
      'price_range': str(attributes['PriceRange']),
      'photo_package_price': pick('photo_package_price', 'PhotoPackage_Price'),
      'photo_video_package_price':
          pick('photo_video_package_price', 'Photo_video_Price'),
    },
    'general': {
      'travel_info': pick('travel_info', 'Travel'),
      'delivery': pick('delivery_time', 'Delivery')
          ?.replaceFirst('Delivery time: ', ''),
      'offerings': pick('offerings', 'Offerings'),
    },
  };

  final result = <String, dynamic>{};
  for (final entry in groups.entries) {
    entry.value.removeWhere((_, v) => v == null);
    if (entry.value.isNotEmpty) result[entry.key] = entry.value;
  }
  return result;
}

class MasterFacilitiesSection extends StatefulWidget {
  const MasterFacilitiesSection({super.key, required this.masterAttrs});

  final Map<String, dynamic> masterAttrs;

  /// True when there is at least one field worth rendering — lets the caller
  /// decide whether to show the section header at all.
  static bool hasContent(Map<String, dynamic>? masterAttrs) {
    if (masterAttrs == null || masterAttrs.isEmpty) return false;
    for (final entry in masterAttrs.entries) {
      if (_hiddenGroups.contains(entry.key)) continue;
      if (entry.value is! Map) continue;
      final group = entry.value as Map;
      for (final fieldValue in group.values) {
        if (_displayValue(fieldValue) != null) return true;
      }
    }
    return false;
  }

  @override
  State<MasterFacilitiesSection> createState() =>
      _MasterFacilitiesSectionState();
}

class _MasterFacilitiesSectionState extends State<MasterFacilitiesSection> {
  /// Group keys currently showing every row instead of the 6-row preview.
  final Set<String> _expandedGroups = {};

  static const int _previewRowCount = 6;

  @override
  Widget build(BuildContext context) {
    final blocks = <Widget>[];

    for (final entry in widget.masterAttrs.entries) {
      if (_hiddenGroups.contains(entry.key)) continue;
      if (entry.value is! Map) continue;
      final group = Map<String, dynamic>.from(entry.value as Map);

      final isCategories = entry.key == 'categories';
      final rows = <MapEntry<String, String>>[];
      for (final field in group.entries) {
        // "*_other" free-text fields only matter once they carry real text —
        // an empty one is just the admin form's unused "please specify" box.
        final display = _displayValue(field.value);
        if (display == null) continue;

        final label = isCategories
            ? (_categoryFieldLabels[field.key] ?? _titleCase(field.key))
            : _titleCase(
                field.key.endsWith('_other')
                    ? '${field.key.substring(0, field.key.length - 6)} (other)'
                    : field.key,
              );
        rows.add(MapEntry(label, display));
      }

      if (rows.isEmpty) continue;

      final groupLabel = _groupLabels[entry.key] ?? _titleCase(entry.key);
      final expanded = _expandedGroups.contains(entry.key);
      final visibleRows = expanded ? rows : rows.take(_previewRowCount).toList();
      final hiddenCount = rows.length - visibleRows.length;

      blocks.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AppCard.outlined(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(groupLabel, style: AppText.bodyStrong),
                const SizedBox(height: AppSpacing.sm),
                for (final row in visibleRows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(row.key, style: AppText.caption),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 6,
                          child: Text(
                            row.value,
                            style: AppText.bodySm.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (hiddenCount > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PremiumButton.text(
                      label: 'Show $hiddenCount more',
                      size: PremiumButtonSize.small,
                      onPressed: () =>
                          setState(() => _expandedGroups.add(entry.key)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }
}
