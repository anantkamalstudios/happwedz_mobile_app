/// Vendor listing filters — a port of the website's filter stack:
///
///  - `src/data/filtersConfig.js`          → [kVendorFilterConfig] / [kDefaultVendorFilters]
///  - `src/hooks/useFilters.js:20-27`      → [filterKeyFor]
///  - `src/utils/priceFilterUtils.js`      → [parsePriceRange], [parseCapacityRange], the extractors
///  - `src/hooks/useInfiniteScroll.js:268-377` → [vendorFilterQueryParams]
///  - `components/layouts/aside/DynamicAside.jsx` + `TopFilter.jsx`
///                                         → [showVendorFilterSheet] (pending vs applied selection)
///
/// Everything above the widget section is pure Dart so it can be unit tested
/// without a Flutter binding.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/core.dart';

// ---------------------------------------------------------------------------
// Config (filtersConfig.js — every live key, groups and options verbatim;
// the web's commented-out groups are left out exactly as the web leaves them).
// ---------------------------------------------------------------------------

/// Key used for [kDefaultVendorFilters] when no config key matches.
const String kDefaultFilterKey = 'DEFAULT';

const List<String> _venueCapacity = ['<100', '100-200', '200-500', '500-1000', '1000+'];
const List<String> _venuePlate = ['<1,000', '1,000-2,000', '2,000-3,000', '3,000+'];
const List<String> _venueRooms = ['<10', '10-20', '20-30', '30-40', '40-50', '50-100', '100+'];
const List<String> _ratingOptions = [
  'all ratings',
  'rated <4',
  'rated 4+',
  'rated 4.5+',
  'rated 4.8+',
];
const List<String> _reviewOptions = [
  '<5 reviews',
  '5+ reviews',
  '15+ reviews',
  '30+ reviews',
];

/// `FILTER_CONFIG` from `src/data/filtersConfig.js:1-568`.
const Map<String, Map<String, List<String>>> kVendorFilterConfig = {
  'photographers': {
    'prices': [
      '40,000',
      '40,000-80,000',
      '80,000-1,20,000',
      '1,20,000-1,60,000',
      '1,60,000+',
    ],
  },
  'bridal-makeup': {
    'price (Bridal Makeup)': [
      '12,000',
      '12,000-16,000',
      '16,000-20,000',
      '20,000-25,000',
      '25,000+',
    ],
    'price (Engagement)': ['12,000', '12,000-18,000', '18,000-25,000', '25,000+'],
  },
  'makeup': {
    'price Bridal Makeup': [
      '12,000',
      '12,000-16,000',
      '16,000-20,000',
      '20,000-25,000',
      '25,000+',
    ],
    'price Engagement': ['12,000', '12,000-18,000', '18,000-25,000', '25,000+'],
  },
  'wedding-planners': {
    'prices': ['<200,000', '200,000-300,000', '300,000-500,000', '500,000+'],
  },
  'decorators': {
    'decor Price': [
      '<50,000',
      '50,000-1,00,000',
      '1,00,000-1,50,000',
      '1,50,000-2,50,000',
      '2,50,000-4,00,000',
    ],
    'home Function Decor': [
      '<30,000',
      '30,000-50,000',
      '50,000-75,000',
      '75,000-1,20,000',
      '1,20,000+',
    ],
  },
  'mehandi': {
    'bridal Price': ['<5,000', '5,000-10,000', '10,000-20,000', '20,000+'],
    'package Price': ['<2,000', '2,000-5,000', '5,001-8,000', '8,000+'],
  },
  'venues': {
    'venue Type': [
      'Banquet Halls',
      'Marriage Garden / lawns',
      'Wedding Farmhouses',
      'Wedding Resorts',
      'Destination Wedding Venues',
      'Kalyana Mandapams',
      '4 Star And Above Wedding Hotels',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'banquet-halls': {
    'venue Type': [
      'Marriage Garden / lawns',
      'Wedding Farmhouses',
      'Wedding Resorts',
      'Destination Wedding Venues',
      'Kalyana Mandapams',
      '4 Star & Above Wedding Hotels',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': ['<1000', '1000-2000', '2000-3000', '3000+'],
    'rooms': _venueRooms,
  },
  'wedding-resorts': {
    'venue Type': [
      'Wedding Resorts',
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Destination Wedding Venues',
      'Kalyana Mandapams',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'destination-wedding-venues': {
    'venue Type': [
      'Destination Wedding Venues',
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'small-functions--party-halls': {
    'venue Type': [
      'small function / party halls',
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
      'Destination Wedding Venues',
      '4 Star & Above Wedding Hotels',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'marriage-garden--lawns': {
    'venue Type': [
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
      'Destination Wedding Venues',
      'Kalyana Mandapams',
      '4 Star & Above Wedding Hotels',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'wedding-farmhouses': {
    'venue Type': [
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
      'Destination Wedding Venues',
      'Kalyana Mandapams',
      '4 Star & Above Wedding Hotels',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'kalyana-mandapams': {
    'venue Type': [
      'Kalyana Mandapams',
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
      'Destination Wedding Venues',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  '4-star-and-above-wedding-hotels': {
    'venue Type': [
      '4 Star And Above Wedding Hotels',
      'Wedding Farmhouses',
      'Marriage Garden / lawns',
      'Banquet Halls',
      'Wedding Resorts',
      'Destination Wedding Venues',
    ],
    'capacity': _venueCapacity,
    'price Per Plate': _venuePlate,
    'rooms': _venueRooms,
  },
  'catering': {
    'price Per Plate': ['<500', '500-1,000', '1,000-1,500', '1,500+'],
    'capacity': ['<100', '100-300', '300-500', '500+'],
  },
  'jewellery': {
    'price Range': [
      '<50,000',
      '50,000-1,00,000',
      '1,00,000-2,00,000',
      '2,00,000+',
    ],
  },
  'wedding-cakes': {
    'price Range': ['<5,000', '5,000-10,000', '10,000-20,000', '20,000+'],
  },
  'invitations': {
    'price Range': ['<50', '50-100', '100-200', '200+'],
    'physical Invite Price': ['<50', '50-100', '100-200', '200-400', '400+'],
  },
  'groom': {
    'price Range': ['<10,000', '10,000-20,000', '20,000-50,000', '50,000+'],
  },
  'bridal': {
    'price Range': ['<20,000', '20,000-50,000', '50,000-1,00,000', '1,00,000+'],
    'rental Available': ['yes', 'no'],
  },
  'bands': {
    'price Range': ['<20,000', '20,000-50,000', '50,000+'],
  },
  'choreographers': {
    'package Price': ['<10,000', '10,000-20,000', '20,000-30,000', '30,000+'],
  },
  'gifts': {
    'price Range': ['<500', '500-1,000', '1,000-5,000', '5,000+'],
  },
  'honeymoon': {
    'destinations': ['maldives', 'bali', 'paris', 'switzerland', 'kashmir'],
    'budget': ['<50,000', '50,000-1,00,000', '1,00,000-2,00,000', '2,00,000+'],
    'duration': ['3 days', '5 days', '7 days', '10 days+'],
    'rating': _ratingOptions,
    'review Count': _reviewOptions,
  },
  'djs': {
    'Starting Price': ['<20,000', '20,000-40,000', '40,000-80,000', '80,000+'],
  },
  'sangeet-choreographers': {
    'package Price 10Songs': [
      '<30,000',
      '30,000-50,000',
      '50,000-75,000',
      '75,000+',
    ],
  },
  'wedding-entertainment': {
    'price': [
      '<7,500',
      '7,500-12,000',
      '12,000-20,000',
      '20,000-30,000',
      '30,000-50,000',
      '50,000-75,000',
      '75,000+',
    ],
  },
  'trousseau-packers': {},
  'catering-services': {
    'price Per Plate': [
      '<1,000',
      '1,000-1,500',
      '1,500-2,000',
      '2,000-3,000',
      '3,000+',
    ],
    'max Capacity': ['<100', '100-500', '500-1000', '1000+'],
    'min Capacity': ['<30', '<50', '<70', '<100', '<200'],
  },
  'cakes': {
    'price Per Kg': ['500-1,000', '1,000-1,500', '1,500-2,500', '2,500-5,000'],
  },
  'bartenders': {
    'type': [
      'general bartenders',
      'flair bartenders',
      'international bartenders',
    ],
    'services': [
      'only bartenders',
      'glassware',
      'mixers & garnishes',
      'ice',
      'theme based bar counters',
    ],
    'pricing For 200 Guests': [
      '<10,000',
      '10,000-20,000',
      '20,000-50,000',
      '50,000-1,00,000',
      '1,00,000+',
    ],
    'rating': _ratingOptions,
    'review Count': _reviewOptions,
  },
  'pre-wedding-shoot-location': {},
  'pre-wedding-photographers': {
    'pricing': ['<10,000', '10,000-25,000', '25,000-50,000', '50,000+'],
  },
  'bridal-lehengas': {},
  'sherwani': {},
  'accessories': {
    'Starting Price': ['500+', '1000+', '1500+', '2000+', '3000+'],
  },
  'wedding-pandits': {
    'pricing': [
      '<11,000',
      '11,000-21,000',
      '21,000-31,000',
      '31,000-51,000',
      '51,000+',
    ],
  },
  'beauty-wellness': {
    'price Range': ['<5,000', '5,000-10,000', '10,000-20,000', '20,000+'],
  },
};

/// `DEFAULT_FILTERS` from `src/data/filtersConfig.js:570-585`.
const Map<String, List<String>> kDefaultVendorFilters = {
  'Price': ['₹10,000 - ₹50,000', '₹50,000 - ₹1,00,000', '₹1,00,000 and more'],
};

/// Resolves the filter-config key for a listing, mirroring
/// `useFilters.js:20-27` (`section === "venues" && !slug → "venues"`, else
/// `slug || section` lower-cased with whitespace → `-`) and
/// `DynamicAside.jsx:30` (`slug: vendorType || slug`, so the vendor type wins).
///
/// App-side differences, all additive:
///  - [isVenues] with a [subcategory] keys on the subcategory (the web gets
///    that from the URL slug of the venue sub-page);
///  - when the web's plain `\s+ → -` rule misses, the URL-slug form is also
///    tried (`&` → `and`, other punctuation dropped, each space → `-`), which
///    is how the web's own slugs like `marriage-garden--lawns` are shaped, so
///    a display name such as "Marriage Garden / Lawns" still finds its key;
///  - a key that is not in [kVendorFilterConfig] returns [kDefaultFilterKey],
///    matching the web's `FILTER_CONFIG[key] || DEFAULT_FILTERS` fallback.
String filterKeyFor({String? vendorType, String? subcategory, bool isVenues = false}) {
  final vt = (vendorType ?? '').trim();
  final sub = (subcategory ?? '').trim();

  String raw;
  if (isVenues) {
    if (sub.isEmpty) return 'venues';
    raw = sub;
  } else {
    raw = vt.isNotEmpty ? vt : sub;
  }
  if (raw.isEmpty) return kDefaultFilterKey;

  final lower = raw.toLowerCase().trim();
  final webKey = lower.replaceAll(RegExp(r'\s+'), '-');
  if (kVendorFilterConfig.containsKey(webKey)) return webKey;

  final slugKey = lower
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
      .replaceAll(RegExp(r'\s'), '-');
  if (kVendorFilterConfig.containsKey(slugKey)) return slugKey;

  return kDefaultFilterKey;
}

/// Filter groups for [key] (`FILTER_CONFIG[key] || DEFAULT_FILTERS`).
Map<String, List<String>> vendorFilterGroupsFor(String key) =>
    kVendorFilterConfig[key] ?? kDefaultVendorFilters;

// ---------------------------------------------------------------------------
// Range parsing (priceFilterUtils.js)
// ---------------------------------------------------------------------------

/// A parsed `{min, max}` range; either bound may be open (null).
@immutable
class FilterRange {
  const FilterRange({this.min, this.max});
  final num? min;
  final num? max;

  @override
  bool operator ==(Object other) =>
      other is FilterRange && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'FilterRange(min: $min, max: $max)';
}

int? _digits(String s) {
  final d = s.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return null;
  return int.tryParse(d);
}

/// `parsePriceRange` (`priceFilterUtils.js:953-1010`).
///
/// Commas are stripped and every non-digit is ignored when reading a number,
/// so `₹` / `Rs` prefixes never matter. Rules: `<N` or `under N` → max N-1;
/// `N+` → min N; `A-B` → min/max of the two; a bare number → max N.
///
/// Deliberate fix of a web bug: the web treats the DEFAULT option
/// `"₹1,00,000 and more"` as a bare number, i.e. **max** 1,00,000 — the
/// opposite of what the label says. Here any value containing `and more`,
/// `and above` or `above` is read as **min** N instead.
FilterRange? parsePriceRange(String? rangeString) {
  if (rangeString == null || rangeString.isEmpty) return null;
  final clean = rangeString.replaceAll(',', '').trim().toLowerCase();

  if (clean.startsWith('<') || clean.startsWith('under')) {
    final v = _digits(clean);
    if (v != null && v > 0) return FilterRange(max: v - 1);
    return null;
  }

  if (clean.contains('+')) {
    final v = _digits(clean);
    if (v != null && v > 0) return FilterRange(min: v);
    return null;
  }

  // App fix (see doc comment): "and more" / "above" is an open upper bound.
  if (clean.contains('and more') || clean.contains('above')) {
    final v = _digits(clean);
    if (v != null && v > 0) return FilterRange(min: v);
    return null;
  }

  if (clean.contains('-')) {
    final parts = clean.split('-').map((p) => _digits(p.trim())).toList();
    if (parts.length >= 2 && parts[0] != null && parts[1] != null) {
      final a = parts[0]!;
      final b = parts[1]!;
      return FilterRange(min: a < b ? a : b, max: a < b ? b : a);
    }
    final single = _digits(clean);
    if (single != null && single > 0) return FilterRange(max: single);
    return null;
  }

  final v = _digits(clean);
  if (v != null && v > 0) return FilterRange(max: v);
  return null;
}

/// `parseCapacityRange` (`priceFilterUtils.js:1126-1154`) — also used for rooms.
FilterRange? parseCapacityRange(String? rangeString) {
  if (rangeString == null || rangeString.isEmpty) return null;
  final clean = rangeString.replaceAll(',', '').trim().toLowerCase();

  if (clean.startsWith('<') || clean.startsWith('under')) {
    final v = _digits(clean);
    if (v != null && v > 0) return FilterRange(max: v - 1);
    return null;
  }
  if (clean.contains('+')) {
    final v = _digits(clean);
    if (v != null && v > 0) return FilterRange(min: v);
    return null;
  }
  if (clean.contains('-')) {
    final parts = clean.split('-');
    final a = _digits(parts[0]);
    final b = parts.length > 1 ? _digits(parts[1]) : null;
    if (a != null && b != null) {
      return FilterRange(min: a < b ? a : b, max: a < b ? b : a);
    }
  }
  final v = _digits(clean);
  if (v != null && v > 0) return FilterRange(max: v);
  return null;
}

/// `parseRatingToken` (`priceFilterUtils.js:1252-1262`).
FilterRange? _parseRatingToken(String token) {
  final t = token.toLowerCase();
  if (t.contains('all')) return const FilterRange();
  final num = double.tryParse(t.replaceAll(RegExp(r'[^0-9.]'), ''));
  if (num == null) return null;
  if (t.contains('<')) return FilterRange(max: num);
  if (t.contains('+')) return FilterRange(min: num);
  return FilterRange(min: num);
}

/// `parseReviewToken` (`priceFilterUtils.js:1287-1294`). Note `<5` is max 5
/// here (not 4) — the web's review parser does not subtract one.
FilterRange? _parseReviewToken(String token) {
  final t = token.toLowerCase();
  final num = _digits(t);
  if (num == null) return null;
  if (t.contains('<')) return FilterRange(max: num);
  if (t.contains('+')) return FilterRange(min: num);
  return FilterRange(min: num);
}

/// Union bounding box used by every web extractor: lowest min, highest max,
/// dropped entirely when min > max.
FilterRange _union(List<FilterRange> ranges) {
  final mins = ranges.map((r) => r.min).whereType<num>().toList();
  final maxs = ranges.map((r) => r.max).whereType<num>().toList();
  final num? min = mins.isEmpty ? null : mins.reduce((a, b) => a < b ? a : b);
  final num? max = maxs.isEmpty ? null : maxs.reduce((a, b) => a > b ? a : b);
  if (min != null && max != null && min > max) return const FilterRange();
  return FilterRange(min: min, max: max);
}

/// Whether [key] is one of the price-like groups `extractPriceFilters`
/// folds into `minPrice`/`maxPrice` (`priceFilterUtils.js:1027-1045`).
/// `price per plate` and `price per kg` are excluded.
bool isPriceFilterGroup(String key) {
  final k = key.toLowerCase();
  final matches = k.contains('price') ||
      k == 'prices' ||
      k == 'pricing' ||
      k.contains('bridal price') ||
      k.contains('package price') ||
      k.contains('price range') ||
      k.contains('starting price') ||
      k.contains('decor price') ||
      k.contains('home function decor') ||
      k.contains('physical invite price') ||
      k.contains('pricing for 200 guests');
  return matches && !k.contains('price per plate') && !k.contains('price per kg');
}

/// Groups the web strips out of the `filters` JSON
/// (`useInfiniteScroll.js:346-373`) — this also silently drops
/// `price Per Kg`, which has no dedicated extractor either.
bool _excludedFromFiltersJson(String key) {
  final k = key.toLowerCase();
  return k == 'search' ||
      k.contains('price') ||
      k == 'prices' ||
      k == 'pricing' ||
      k.contains('bridal price') ||
      k.contains('package price') ||
      k.contains('price per plate') ||
      k.contains('price per kg') ||
      k.contains('price range') ||
      k.contains('starting price') ||
      k.contains('decor price') ||
      k.contains('home function decor') ||
      k.contains('physical invite price') ||
      k.contains('pricing for 200 guests') ||
      k == 'capacity' ||
      k == 'venue type' ||
      k == 'rooms' ||
      k == 'rating' ||
      k == 'review count';
}

/// `extractPriceFilters` (`priceFilterUtils.js:1018-1121`).
FilterRange extractPriceRange(Map<String, List<String>> active) {
  final ranges = <FilterRange>[];
  for (final e in active.entries) {
    if (!isPriceFilterGroup(e.key)) continue;
    for (final v in e.value) {
      final r = parsePriceRange(v);
      if (r != null) ranges.add(r);
    }
  }
  if (ranges.isEmpty) return const FilterRange();

  final mins = ranges.map((r) => r.min).whereType<num>().toList();
  final maxs = ranges.map((r) => r.max).whereType<num>().toList();
  final num? minPrice = mins.isEmpty ? null : mins.reduce((a, b) => a < b ? a : b);
  final num? maxPrice = maxs.isEmpty ? null : maxs.reduce((a, b) => a > b ? a : b);

  // Web lines 1090-1112: a max-only pick plus a min-only pick that do not
  // overlap (e.g. "<40,000" + "1,60,000+") means "show everything".
  final hasMaxOnly = ranges.any((r) => r.min == null && r.max != null);
  final hasMinOnly = ranges.any((r) => r.min != null && r.max == null);
  if (hasMaxOnly && hasMinOnly && mins.isNotEmpty && maxs.isNotEmpty) {
    final lowestMax = maxs.reduce((a, b) => a < b ? a : b);
    final highestMin = mins.reduce((a, b) => a > b ? a : b);
    if (lowestMax < highestMin) return const FilterRange();
  }
  if (minPrice != null && maxPrice != null && minPrice > maxPrice) {
    return const FilterRange();
  }
  return FilterRange(min: minPrice, max: maxPrice);
}

List<String> _groupCI(Map<String, List<String>> active, String lowerName) {
  for (final e in active.entries) {
    if (e.key.toLowerCase() == lowerName) return e.value;
  }
  return const [];
}

FilterRange _extract(
  Map<String, List<String>> active,
  String lowerName,
  FilterRange? Function(String) parse,
) {
  final ranges = _groupCI(active, lowerName).map(parse).whereType<FilterRange>().toList();
  if (ranges.isEmpty) return const FilterRange();
  return _union(ranges);
}

/// JS `Number.prototype.toString` for the values the web appends
/// (`4` not `4.0`, `4.5` stays `4.5`).
String _jsNum(num n) {
  if (n is int) return n.toString();
  if (n == n.roundToDouble()) return n.toInt().toString();
  return n.toString();
}

/// Builds exactly the filter query params the website appends to
/// `GET /vendor-services` for a set of selected options
/// (`useInfiniteScroll.js:268-377`).
///
/// [selected] maps group label → selected option labels (as they appear in
/// [kVendorFilterConfig]). Only groups that exist for [configKey] are
/// considered — the web clears a listing's selection whenever the key changes
/// (`DynamicAside.jsx:44-56`), so a stale group from another category must
/// never reach the request. Empty groups are dropped as the web's
/// `toggleFilter` reducer does (`filterSlice.js:30-35`).
///
/// Returned keys (only when they have a value): `subCategory`, `minPrice`,
/// `maxPrice`, `minCapacity`, `maxCapacity`, `minFoodPrice`, `maxFoodPrice`,
/// `minRooms`, `maxRooms`, `minRating`, `maxRating`, `minReviews`,
/// `maxReviews`, `filters` (JSON of the leftover groups). The caller still
/// adds vendorType/city/page/limit itself; when `subCategory` is absent it
/// should fall back to its own slug-derived subCategory like the web does.
Map<String, String> vendorFilterQueryParams(
  String configKey,
  Map<String, List<String>> selected,
) {
  final allowed = vendorFilterGroupsFor(configKey);
  final active = <String, List<String>>{};
  for (final e in selected.entries) {
    if (!allowed.containsKey(e.key)) continue;
    final values = e.value.where((v) => v.trim().isNotEmpty).toList();
    if (values.isEmpty) continue;
    active[e.key] = values;
  }

  final params = <String, String>{};
  void put(String name, num? v) {
    if (v != null) params[name] = _jsNum(v);
  }

  // extractVenueSubCategories (priceFilterUtils.js:1186-1196)
  final venueTypes = _groupCI(active, 'venue type');
  if (venueTypes.isNotEmpty) {
    final joined = venueTypes.join(',');
    if (joined.trim().isNotEmpty) params['subCategory'] = joined;
  }

  final price = extractPriceRange(active);
  put('minPrice', price.min);
  put('maxPrice', price.max);

  final capacity = _extract(active, 'capacity', parseCapacityRange);
  put('minCapacity', capacity.min);
  put('maxCapacity', capacity.max);

  final food = _extract(active, 'price per plate', parsePriceRange);
  put('minFoodPrice', food.min);
  put('maxFoodPrice', food.max);

  final rooms = _extract(active, 'rooms', parseCapacityRange);
  put('minRooms', rooms.min);
  put('maxRooms', rooms.max);

  final rating = _extract(active, 'rating', _parseRatingToken);
  put('minRating', rating.min);
  put('maxRating', rating.max);

  final reviews = _extract(active, 'review count', _parseReviewToken);
  put('minReviews', reviews.min);
  put('maxReviews', reviews.max);

  final rest = <String, List<String>>{
    for (final e in active.entries)
      if (!_excludedFromFiltersJson(e.key)) e.key: e.value,
  };
  if (rest.isNotEmpty) params['filters'] = jsonEncode(rest);

  return params;
}

/// `capitalize` from `TopFilter.jsx:28-29`: `_` → space, then the first
/// word character after every word boundary upper-cased.
String capitalizeFilterLabel(String s) => s
    .replaceAll('_', ' ')
    .replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());

// ---------------------------------------------------------------------------
// Bottom sheet (DynamicAside.jsx + TopFilter.jsx)
// ---------------------------------------------------------------------------

/// What [showVendorFilterSheet] returns when the user applies or clears.
@immutable
class VendorFilterSheetResult {
  const VendorFilterSheetResult({
    this.groups = const {},
    this.city = '',
    this.minRating = 0,
  });

  /// Applied selection: group label → selected options. Empty groups omitted.
  final Map<String, List<String>> groups;

  /// App-only city filter (only meaningful when the sheet had `showCity`).
  final String city;

  /// App-only minimum rating 0–5 (only meaningful with `showRating`).
  final double minRating;

  bool get isEmpty => groups.isEmpty && city.trim().isEmpty && minRating <= 0;

  /// Total selected options, like TopFilter's badge count.
  int get groupCount => groups.values.fold(0, (s, v) => s + v.length);
}

/// Opens the filter sheet for [filterKey] (see [filterKeyFor]).
///
/// Mirrors the web's pending-vs-applied model: toggling options only changes
/// the pending selection; **Apply** (enabled only when pending differs from
/// [applied], like TopFilter's `hasPendingChanges`) returns it; **Clear**
/// resets everything and returns an empty result immediately, as the web's
/// `handleClearFilters` does. Dismissing the sheet returns `null` (nothing
/// changes).
///
/// [showCity] / [showRating] add app-only sections (a city text field on top,
/// a minimum-rating slider at the bottom); [extraTop] / [extraBottom] let the
/// caller inject any further widgets.
Future<VendorFilterSheetResult?> showVendorFilterSheet(
  BuildContext context, {
  required String filterKey,
  Map<String, List<String>> applied = const {},
  bool showCity = false,
  String city = '',
  bool showRating = false,
  double minRating = 0,
  String title = 'Filters',
  WidgetBuilder? extraTop,
  WidgetBuilder? extraBottom,
}) {
  return AppBottomSheet.show<VendorFilterSheetResult>(
    context,
    title: title,
    child: VendorFilterPanel(
      groups: vendorFilterGroupsFor(filterKey),
      applied: applied,
      showCity: showCity,
      city: city,
      showRating: showRating,
      minRating: minRating,
      extraTop: extraTop,
      extraBottom: extraBottom,
      onDone: (r) => Navigator.of(context).pop(r),
    ),
  );
}

/// The sheet body. Public so it can be embedded or widget-tested directly.
class VendorFilterPanel extends StatefulWidget {
  const VendorFilterPanel({
    super.key,
    required this.groups,
    required this.onDone,
    this.applied = const {},
    this.showCity = false,
    this.city = '',
    this.showRating = false,
    this.minRating = 0,
    this.extraTop,
    this.extraBottom,
  });

  final Map<String, List<String>> groups;
  final Map<String, List<String>> applied;
  final ValueChanged<VendorFilterSheetResult> onDone;
  final bool showCity;
  final String city;
  final bool showRating;
  final double minRating;
  final WidgetBuilder? extraTop;
  final WidgetBuilder? extraBottom;

  @override
  State<VendorFilterPanel> createState() => _VendorFilterPanelState();
}

class _VendorFilterPanelState extends State<VendorFilterPanel> {
  late Map<String, List<String>> _pending;
  late final TextEditingController _city = TextEditingController(text: widget.city);
  late double _minRating = widget.minRating.clamp(0, 5).toDouble();

  @override
  void initState() {
    super.initState();
    _pending = {
      for (final e in widget.applied.entries)
        if (e.value.isNotEmpty) e.key: List<String>.from(e.value),
    };
  }

  @override
  void dispose() {
    _city.dispose();
    super.dispose();
  }

  void _toggle(String group, String value) {
    setState(() {
      final list = List<String>.from(_pending[group] ?? const []);
      if (list.contains(value)) {
        list.remove(value);
      } else {
        list.add(value);
      }
      if (list.isEmpty) {
        _pending.remove(group);
      } else {
        _pending[group] = list;
      }
    });
  }

  bool get _hasPendingChanges {
    if (widget.showCity && _city.text.trim() != widget.city.trim()) return true;
    if (widget.showRating && _minRating != widget.minRating) return true;
    final a = {
      for (final e in widget.applied.entries)
        if (e.value.isNotEmpty) e.key: e.value,
    };
    if (a.length != _pending.length) return true;
    for (final e in _pending.entries) {
      final other = a[e.key];
      if (other == null || other.length != e.value.length) return true;
      for (var i = 0; i < other.length; i++) {
        if (other[i] != e.value[i]) return true;
      }
    }
    return false;
  }

  void _apply() {
    widget.onDone(VendorFilterSheetResult(
      groups: {for (final e in _pending.entries) e.key: List.unmodifiable(e.value)},
      city: widget.showCity ? _city.text.trim() : widget.city,
      minRating: widget.showRating ? _minRating : widget.minRating,
    ));
  }

  void _clear() {
    widget.onDone(const VendorFilterSheetResult());
  }

  @override
  Widget build(BuildContext context) {
    final groups = widget.groups.entries.where((e) => e.value.isNotEmpty).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showCity) ...[
          AppTextField(
            controller: _city,
            label: 'City',
            hint: 'e.g. Mumbai',
            prefixIcon: Icons.location_on_outlined,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (widget.extraTop != null) widget.extraTop!(context),
        for (final g in groups) _buildGroup(g.key, g.value),
        if (groups.isEmpty && !widget.showCity && !widget.showRating)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'No filters available for this category.',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
          ),
        if (widget.showRating) _buildRating(),
        if (widget.extraBottom != null) widget.extraBottom!(context),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: PremiumButton.outlined(
                label: 'Clear',
                icon: Icons.clear_rounded,
                onPressed: _clear,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PremiumButton(
                label: 'Apply',
                icon: Icons.check_rounded,
                enabled: _hasPendingChanges,
                onPressed: _apply,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGroup(String group, List<String> options) {
    final count = _pending[group]?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  capitalizeFilterLabel(group),
                  style: AppText.cardTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: AppText.labelSm.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final option in options)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              value: _pending[group]?.contains(option) ?? false,
              onChanged: (_) => _toggle(group, option),
              title: Text(capitalizeFilterLabel(option), style: AppText.body),
            ),
          const Divider(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Minimum rating', style: AppText.cardTitle)),
            Text(
              _minRating <= 0 ? 'Any' : '${_minRating.toStringAsFixed(1)}★ & up',
              style: AppText.label.copyWith(color: AppColors.primary),
            ),
          ],
        ),
        Slider(
          value: _minRating,
          min: 0,
          max: 5,
          divisions: 10,
          activeColor: AppColors.primary,
          label: _minRating <= 0 ? 'Any' : _minRating.toStringAsFixed(1),
          onChanged: (v) => setState(() => _minRating = v),
        ),
      ],
    );
  }
}
