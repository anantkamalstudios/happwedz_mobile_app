/// Facet derivation and filtering for hotel results.
///
/// A port of the filtering the web client does in `HotelbedsHotelsPage.jsx`
/// (`buildLocalFilterGroups` + the `visibleHotels` memo). Like the website,
/// these run **client-side** over the page of results already fetched — the
/// `hotels/search` endpoint does the sorting and paging, and the sidebar
/// narrows what came back. Building the groups from the loaded list is also
/// what lets every option carry a truthful count.
///
/// Star rating and price bands are ordinal: they read 5-4-3-2 and
/// cheapest-first, never "whichever bucket happens to have the most hotels".
/// Everything else is unordered and stays sorted by popularity.
library;

import '../models/honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Price bands
// ---------------------------------------------------------------------------

const String kPriceUnder3000 = 'UNDER_3000';
const String kPrice3000To6000 = '3000_6000';
const String kPrice6000To10000 = '6000_10000';
const String kPriceAbove10000 = 'ABOVE_10000';

const List<String> kPriceRangeOrder = [
  kPriceUnder3000,
  kPrice3000To6000,
  kPrice6000To10000,
  kPriceAbove10000,
];

const Map<String, String> kPriceRangeLabels = {
  kPriceUnder3000: 'Under ₹3,000',
  kPrice3000To6000: '₹3,000 - ₹6,000',
  kPrice6000To10000: '₹6,000 - ₹10,000',
  kPriceAbove10000: 'Above ₹10,000',
};

/// Which band a total price falls into, or null when there is no price.
String? priceRangeBucket(double value) {
  if (value <= 0) return null;
  if (value < 3000) return kPriceUnder3000;
  if (value < 6000) return kPrice3000To6000;
  if (value < 10000) return kPrice6000To10000;
  return kPriceAbove10000;
}

const String kRefundable = 'REFUNDABLE';
const String kNonRefundable = 'NON_REFUNDABLE';

// ---------------------------------------------------------------------------
// Groups
// ---------------------------------------------------------------------------

/// The filter groups, in the order the sheet presents them.
enum HotelFilterGroup {
  ratings,
  priceRange,
  propertyType,
  mealType,
  cancellationPolicy,
  amenities,
}

extension HotelFilterGroupLabel on HotelFilterGroup {
  String get label => switch (this) {
    HotelFilterGroup.ratings => 'Star rating',
    HotelFilterGroup.priceRange => 'Price range',
    HotelFilterGroup.propertyType => 'Property type',
    HotelFilterGroup.mealType => 'Meal plan',
    HotelFilterGroup.cancellationPolicy => 'Cancellation',
    HotelFilterGroup.amenities => 'Amenities',
  };
}

class HotelFacetItem {
  const HotelFacetItem({
    required this.value,
    required this.label,
    required this.count,
  });

  final String value;
  final String label;
  final int count;
}

class HotelFacetGroup {
  const HotelFacetGroup({required this.group, required this.options});

  final HotelFilterGroup group;
  final List<HotelFacetItem> options;
}

/// The amenity list the web card and the amenity facet both work from.
///
/// The website caps a hotel's amenities at four before aggregating, and matches
/// against that same four — so a facet's count always equals the number of
/// hotels the option will actually leave on screen.
List<String> topAmenities(HotelResult hotel) =>
    hotel.facilities.take(4).toList();

/// Build every group from the loaded hotels, dropping groups with nothing in
/// them. Counts describe the full list, not the currently filtered one.
List<HotelFacetGroup> buildHotelFacets(List<HotelResult> hotels) {
  if (hotels.isEmpty) return const [];

  HotelFacetGroup? aggregate(
    HotelFilterGroup group,
    Iterable<String> values, {
    String Function(String value)? label,
    int Function(HotelFacetItem a, HotelFacetItem b)? order,
  }) {
    final counts = <String, int>{};
    for (final raw in values) {
      final v = raw.trim();
      if (v.isEmpty) continue;
      counts[v] = (counts[v] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;

    final options = counts.entries
        .map(
          (e) => HotelFacetItem(
            value: e.key,
            label: label?.call(e.key) ?? e.key,
            count: e.value,
          ),
        )
        .toList();

    options.sort(
      order ??
          // Popularity first, then alphabetically so the order is stable
          // between identical counts.
          (a, b) {
            final byCount = b.count.compareTo(a.count);
            return byCount != 0 ? byCount : a.label.compareTo(b.label);
          },
    );

    return HotelFacetGroup(group: group, options: options);
  }

  return [
    aggregate(
      HotelFilterGroup.ratings,
      hotels
          .where((h) => h.starRating > 0)
          .map((h) => h.starRating.round().toString()),
      label: (v) => '$v star',
      order: (a, b) =>
          (int.tryParse(b.value) ?? 0).compareTo(int.tryParse(a.value) ?? 0),
    ),
    aggregate(
      HotelFilterGroup.priceRange,
      hotels.map((h) => priceRangeBucket(h.price)).whereType<String>(),
      label: (v) => kPriceRangeLabels[v] ?? v,
      order: (a, b) => kPriceRangeOrder
          .indexOf(a.value)
          .compareTo(kPriceRangeOrder.indexOf(b.value)),
    ),
    aggregate(HotelFilterGroup.propertyType, hotels.map((h) => h.propertyType)),
    aggregate(HotelFilterGroup.mealType, hotels.map((h) => h.mealBasis)),
    aggregate(
      HotelFilterGroup.cancellationPolicy,
      hotels.map((h) => h.isRefundable ? kRefundable : kNonRefundable),
      label: (v) => v == kRefundable ? 'Free cancellation' : 'Non-refundable',
    ),
    aggregate(HotelFilterGroup.amenities, hotels.expand(topAmenities)),
  ].whereType<HotelFacetGroup>().toList();
}

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

/// Immutable selection state for the hotel filter sheet.
class HotelFilters {
  const HotelFilters({this.selections = const {}, this.nameQuery = ''});

  /// Selected values per group. A group absent from the map is unfiltered.
  final Map<HotelFilterGroup, Set<String>> selections;

  /// Free-text match against the hotel name.
  final String nameQuery;

  static const HotelFilters empty = HotelFilters();

  Set<String> of(HotelFilterGroup group) => selections[group] ?? const {};

  bool isSelected(HotelFilterGroup group, String value) =>
      of(group).contains(value);

  int get activeCount =>
      selections.values.fold<int>(0, (n, s) => n + s.length) +
      (nameQuery.trim().isEmpty ? 0 : 1);

  bool get isEmpty => activeCount == 0;

  HotelFilters toggle(HotelFilterGroup group, String value) {
    final next = {
      for (final e in selections.entries) e.key: Set<String>.from(e.value),
    };
    final set = next.putIfAbsent(group, () => <String>{});
    if (!set.remove(value)) set.add(value);
    if (set.isEmpty) next.remove(group);
    return HotelFilters(selections: next, nameQuery: nameQuery);
  }

  HotelFilters clearGroup(HotelFilterGroup group) {
    final next = {
      for (final e in selections.entries)
        if (e.key != group) e.key: Set<String>.from(e.value),
    };
    return HotelFilters(selections: next, nameQuery: nameQuery);
  }

  HotelFilters withName(String query) =>
      HotelFilters(selections: selections, nameQuery: query);

  /// Drop selections the new result set cannot satisfy, so filters carried
  /// across a re-search never silently empty the list.
  HotelFilters reconcile(List<HotelFacetGroup> facets) {
    final allowed = {
      for (final g in facets) g.group: g.options.map((o) => o.value).toSet(),
    };
    final next = <HotelFilterGroup, Set<String>>{};
    for (final entry in selections.entries) {
      final valid = allowed[entry.key];
      if (valid == null) continue;
      final kept = entry.value.where(valid.contains).toSet();
      if (kept.isNotEmpty) next[entry.key] = kept;
    }
    return HotelFilters(selections: next, nameQuery: nameQuery);
  }
}

// ---------------------------------------------------------------------------
// Filtering
// ---------------------------------------------------------------------------

/// Narrow [hotels] by [filters], in the same order the website applies them.
List<HotelResult> filterHotels(List<HotelResult> hotels, HotelFilters filters) {
  if (filters.isEmpty) return hotels;

  var next = hotels;

  final query = filters.nameQuery.trim().toLowerCase();
  if (query.isNotEmpty) {
    next = next.where((h) => h.name.toLowerCase().contains(query)).toList();
  }

  final ratings = filters.of(HotelFilterGroup.ratings);
  if (ratings.isNotEmpty) {
    next = next
        .where((h) => ratings.contains(h.starRating.round().toString()))
        .toList();
  }

  final priceRanges = filters.of(HotelFilterGroup.priceRange);
  if (priceRanges.isNotEmpty) {
    next = next.where((h) {
      final bucket = priceRangeBucket(h.price);
      return bucket != null && priceRanges.contains(bucket);
    }).toList();
  }

  final propertyTypes = filters.of(HotelFilterGroup.propertyType);
  if (propertyTypes.isNotEmpty) {
    next = next.where((h) => propertyTypes.contains(h.propertyType)).toList();
  }

  final mealTypes = filters.of(HotelFilterGroup.mealType);
  if (mealTypes.isNotEmpty) {
    next = next.where((h) => mealTypes.contains(h.mealBasis)).toList();
  }

  final cancellation = filters.of(HotelFilterGroup.cancellationPolicy);
  if (cancellation.isNotEmpty) {
    next = next
        .where(
          (h) => cancellation.contains(
            h.isRefundable ? kRefundable : kNonRefundable,
          ),
        )
        .toList();
  }

  final amenities = filters.of(HotelFilterGroup.amenities);
  if (amenities.isNotEmpty) {
    // "Any of", not "all of" — matching the website, where ticking two
    // amenities widens the list rather than narrowing it to hotels with both.
    next = next.where((h) {
      final have = topAmenities(h).map((a) => a.toLowerCase()).toSet();
      return amenities.any((a) => have.contains(a.toLowerCase()));
    }).toList();
  }

  return next;
}

// ---------------------------------------------------------------------------
// Applied-filter chips
// ---------------------------------------------------------------------------

class HotelFilterChip {
  const HotelFilterChip({
    required this.group,
    required this.value,
    required this.label,
  });

  /// Null for the free-text name chip, which is not part of any group.
  final HotelFilterGroup? group;
  final String value;
  final String label;
}

List<HotelFilterChip> describeHotelFilters(
  HotelFilters filters,
  List<HotelFacetGroup> facets,
) {
  final chips = <HotelFilterChip>[];

  final name = filters.nameQuery.trim();
  if (name.isNotEmpty) {
    chips.add(HotelFilterChip(group: null, value: name, label: '“$name”'));
  }

  for (final group in HotelFilterGroup.values) {
    final selected = filters.of(group);
    if (selected.isEmpty) continue;
    final options = facets
        .where((g) => g.group == group)
        .expand((g) => g.options)
        .toList();
    for (final value in selected) {
      final label = options.where((o) => o.value == value).firstOrNull?.label;
      chips.add(
        HotelFilterChip(group: group, value: value, label: label ?? value),
      );
    }
  }

  return chips;
}

HotelFilters removeHotelChip(HotelFilters filters, HotelFilterChip chip) =>
    chip.group == null
    ? filters.withName('')
    : filters.toggle(chip.group!, chip.value);
