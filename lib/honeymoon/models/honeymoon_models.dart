/// Models for the Honeymoon module.
///
/// Every constructor is defensive: the upstream TripJack payloads are deeply
/// nested and frequently omit fields, so nothing here uses `!`, and every
/// lookup tolerates null, wrong types and empty collections. A malformed
/// record yields a mostly-empty model rather than throwing.
library;

// ---------------------------------------------------------------------------
// Safe readers
// ---------------------------------------------------------------------------

/// Reads [key] from [source] when it is a map, otherwise null.
Object? _get(dynamic source, String key) {
  if (source is Map) return source[key];
  return null;
}

/// Walks a nested path, stopping at the first link that cannot be indexed.
/// Accepts string keys for maps and int indices for lists.
Object? _dig(dynamic source, List<Object> path) {
  dynamic current = source;
  for (final key in path) {
    if (key is int) {
      if (current is! List || key < 0 || key >= current.length) return null;
      current = current[key];
    } else {
      if (current is! Map) return null;
      current = current[key];
    }
  }
  return current;
}

String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is String) return value.trim();
  return value.toString().trim();
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(cleaned) ?? fallback;
  }
  return fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9\-]'), '');
    return int.tryParse(cleaned) ?? fallback;
  }
  return fallback;
}

/// Always returns a list — never null — filtering out null entries.
List<dynamic> asList(dynamic value) {
  if (value is List) return value.where((e) => e != null).toList();
  return const [];
}

/// First non-empty string among [candidates].
String firstNonEmpty(List<dynamic> candidates, {String fallback = ''}) {
  for (final c in candidates) {
    final s = asString(c);
    if (s.isNotEmpty) return s;
  }
  return fallback;
}

/// Public wrappers so sibling libraries (the booking models) can read the same
/// deeply-nested supplier payloads without re-implementing the safe readers.
Object? readKey(dynamic source, String key) => _get(source, key);

Object? digPath(dynamic source, List<Object> path) => _dig(source, path);

/// Deep-copies a decoded JSON value into a `Map<String, dynamic>`.
///
/// Supplier responses come back as `Map<dynamic, dynamic>` in places, which
/// `jsonEncode` accepts but typed field access does not — normalising once here
/// keeps every raw payload safe to re-send in a booking request.
Map<String, dynamic> asJsonMap(dynamic value) {
  if (value is Map) {
    return <String, dynamic>{
      for (final e in value.entries) asString(e.key): e.value,
    };
  }
  return <String, dynamic>{};
}

// ---------------------------------------------------------------------------
// Destination (hotels/city-regions, hotels/static-hotels/search)
// ---------------------------------------------------------------------------

/// What kind of thing the user picked in the destination field. The hotel
/// search payload is shaped differently for a city/region than for a specific
/// hotel, so the distinction has to survive into the request builder.
enum DestinationKind { city, region, hotel }

class HoneymoonDestination {
  const HoneymoonDestination({
    required this.id,
    required this.displayName,
    this.city = '',
    this.country = '',
    this.kind = DestinationKind.city,
    this.searchRegionType = '',
    this.searchRegionName = '',
    this.hotelId = '',
    this.regionSubtitle = '',
    this.cityRegionId = '',
    this.starRating = 0,
  });

  final String id;
  final String displayName;

  /// For a place: TripJack's region id (`cityRegionId`), which is what the
  /// search payload's `searchCriteria.city` expects — not the city's name.
  final String city;
  final String country;
  final DestinationKind kind;
  final String searchRegionType;
  final String searchRegionName;

  /// TripJack hotel id, only set when [kind] is [DestinationKind.hotel].
  final String hotelId;

  /// The qualifier line the supplier sends ("MAHARASHTRA, INDIA"), already
  /// stripped of the place name. Wins over the derived [subtitle].
  final String regionSubtitle;

  /// Region id of the city a hotel suggestion sits in.
  final String cityRegionId;

  /// Star rating a hotel suggestion carries, for the suggestion row.
  final double starRating;

  bool get isHotel => kind == DestinationKind.hotel;

  /// One row of `GET hotels/suggestions` — the single ranked list of places
  /// and properties the web's `HotelSearchForm` uses.
  ///
  /// Mirrors `normalizeHotelSuggestion`: the region *id* becomes [city]
  /// (`city || cityId || regionId || searchRegionId || cityRegionId || id`),
  /// the region type becomes the search type, and a `type: hotel` row becomes
  /// a HOTEL search on that property.
  factory HoneymoonDestination.fromSuggestion(dynamic json) {
    final isHotel = asString(_get(json, 'type')).toLowerCase() == 'hotel';
    final regionType = isHotel
        ? 'HOTEL'
        : firstNonEmpty([
            _get(json, 'searchType'),
            _get(json, 'searchRegionType'),
            _get(json, 'regionType'),
          ], fallback: 'CITY').toUpperCase();

    final regionId = firstNonEmpty([
      _get(json, 'city'),
      _get(json, 'cityId'),
      _get(json, 'regionId'),
      _get(json, 'searchRegionId'),
      _get(json, 'cityRegionId'),
      if (!isHotel) _get(json, 'id'),
    ]);

    final name = firstNonEmpty([
      _get(json, 'name'),
      _get(json, 'displayName'),
      _get(json, 'label'),
      _get(json, 'searchRegionName'),
      _get(json, 'cityName'),
    ]);

    final hid = isHotel
        ? firstNonEmpty([
            _get(json, 'hid'),
            _get(json, 'tjHotelId'),
            _get(json, 'id'),
            _dig(json, ['raw', 'tjHotelId']),
          ])
        : '';

    final fullRegionName = firstNonEmpty([
      _get(json, 'fullRegionName'),
      _dig(json, ['raw', 'fullRegionName']),
      _get(json, 'subtitle'),
    ]);

    // TripJack's fullRegionName repeats the place as its first segment
    // ("MUMBAI, MAHARASHTRA, INDIA"); the row title already shows it.
    final segments = fullRegionName
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isNotEmpty &&
        segments.first.toLowerCase() == name.toLowerCase()) {
      segments.removeAt(0);
    }

    final country = firstNonEmpty([
      _get(json, 'countryName'),
      _get(json, 'country'),
      segments.isNotEmpty ? segments.last : null,
    ]);

    return HoneymoonDestination(
      id: isHotel ? hid : firstNonEmpty([regionId, name]),
      displayName: name,
      city: regionId,
      country: country,
      kind: isHotel
          ? DestinationKind.hotel
          : regionType == 'CITY'
          ? DestinationKind.city
          : DestinationKind.region,
      searchRegionType: regionType,
      searchRegionName: name,
      hotelId: hid,
      regionSubtitle: segments.join(', '),
      cityRegionId: asString(_get(json, 'cityRegionId')),
      starRating: asDouble(_get(json, 'starRating')),
    );
  }

  /// Round-trips a picked destination through a saved booking draft.
  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'city': city,
    'country': country,
    'kind': kind.name,
    'searchRegionType': searchRegionType,
    'searchRegionName': searchRegionName,
    'hotelId': hotelId,
    'regionSubtitle': regionSubtitle,
    'cityRegionId': cityRegionId,
    'starRating': starRating,
  };

  factory HoneymoonDestination.fromJson(dynamic json) => HoneymoonDestination(
    id: asString(_get(json, 'id')),
    displayName: asString(_get(json, 'displayName')),
    city: asString(_get(json, 'city')),
    country: asString(_get(json, 'country')),
    kind:
        DestinationKind.values
            .where((k) => k.name == asString(_get(json, 'kind')))
            .firstOrNull ??
        DestinationKind.city,
    searchRegionType: asString(_get(json, 'searchRegionType')),
    searchRegionName: asString(_get(json, 'searchRegionName')),
    hotelId: asString(_get(json, 'hotelId')),
    regionSubtitle: asString(_get(json, 'regionSubtitle')),
    cityRegionId: asString(_get(json, 'cityRegionId')),
    starRating: asDouble(_get(json, 'starRating')),
  );

  /// Display title — a MULTI_CITY_VICINITY row shares its city's name, so
  /// TripJack labels it "AND VICINITY". Display only; payloads keep
  /// [displayName].
  String get title => searchRegionType.toUpperCase() == 'MULTI_CITY_VICINITY'
      ? '$displayName AND VICINITY'
      : displayName;

  /// A city-region suggestion from `GET hotels/city-regions`.
  factory HoneymoonDestination.fromCityRegion(dynamic json) {
    final name = firstNonEmpty([
      _get(json, 'displayName'),
      _get(json, 'name'),
      _get(json, 'regionName'),
      _get(json, 'cityName'),
      _get(json, 'label'),
    ]);
    final city = firstNonEmpty([
      _get(json, 'cityName'),
      _get(json, 'city'),
      name,
    ]);
    final regionType = firstNonEmpty([
      _get(json, 'searchRegionType'),
      _get(json, 'regionType'),
      _get(json, 'type'),
    ]);

    return HoneymoonDestination(
      id: firstNonEmpty([
        _get(json, 'id'),
        _get(json, 'regionId'),
        _get(json, 'cityRegionId'),
      ]),
      displayName: name,
      city: city,
      country: firstNonEmpty([
        _get(json, 'countryName'),
        _get(json, 'country'),
      ]),
      kind: regionType.toUpperCase() == 'CITY'
          ? DestinationKind.city
          : DestinationKind.region,
      searchRegionType: regionType.isEmpty ? 'CITY' : regionType,
      searchRegionName: firstNonEmpty([
        _get(json, 'searchRegionName'),
        _get(json, 'regionName'),
        name,
      ]),
    );
  }

  /// A specific property from `GET hotels/static-hotels/search`.
  factory HoneymoonDestination.fromStaticHotel(dynamic json) {
    final name = firstNonEmpty([
      _get(json, 'name'),
      _get(json, 'hotelName'),
      _get(json, 'displayName'),
    ]);
    final hid = firstNonEmpty([
      _get(json, 'id'),
      _get(json, 'hid'),
      _get(json, 'tjid'),
      _get(json, 'hotelId'),
    ]);

    return HoneymoonDestination(
      id: hid,
      displayName: name,
      city: firstNonEmpty([
        _get(json, 'cityName'),
        _get(json, 'city'),
        _dig(json, ['address', 'city']),
      ]),
      country: firstNonEmpty([
        _get(json, 'countryName'),
        _get(json, 'country'),
        _dig(json, ['address', 'country']),
      ]),
      kind: DestinationKind.hotel,
      searchRegionType: 'HOTEL',
      searchRegionName: name,
      hotelId: hid,
    );
  }

  /// Secondary line shown under the name in the suggestion list.
  String get subtitle {
    if (regionSubtitle.isNotEmpty) return regionSubtitle;
    final parts = <String>[
      if (city.isNotEmpty && city != displayName) city,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }
}

// ---------------------------------------------------------------------------
// Room occupancy
// ---------------------------------------------------------------------------

class RoomOccupancy {
  RoomOccupancy({this.adults = 2, List<int>? childAges})
    : childAges = List<int>.from(childAges ?? const []);

  int adults;
  final List<int> childAges;

  int get children => childAges.length;

  /// Exactly the `roomInfo` element the hotel search payload expects.
  Map<String, dynamic> toRoomInfo() => {
    'numberOfAdults': adults,
    'numberOfChild': children,
    'childAge': childAges,
  };

  RoomOccupancy copy() => RoomOccupancy(adults: adults, childAges: childAges);
}

// ---------------------------------------------------------------------------
// Hotel search query
// ---------------------------------------------------------------------------

/// Everything the traveller chose on the hotel search form.
///
/// The web keeps the whole `hotels/search` payload in router state and every
/// later call (paging, detail, review) is built from it. This is that state:
/// one object handed from the form to results to detail to booking, so no
/// screen has to re-assemble it from loose parameters — and so options like
/// nationality or the GST claim survive to the detail call.
class HotelSearchQuery {
  HotelSearchQuery({
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required List<RoomOccupancy> rooms,
    this.ratings = const [],
    this.nationality = '106',
    this.countryOfResidence = '106',
    this.countryName = 'INDIA',
    this.gstApplied = false,
    String? correlationId,
  }) : rooms = List.unmodifiable(rooms.map((r) => r.copy())),
       correlationId = correlationId ?? newCorrelationId();

  final HoneymoonDestination destination;
  final DateTime checkIn;
  final DateTime checkOut;

  /// Copied on construction: the form keeps editing its own list, and a search
  /// already run must not change underneath the results page.
  final List<RoomOccupancy> rooms;

  /// Star ratings pre-selected on the form (`"5"`, `"4"`, … `"0"` = unrated).
  final List<String> ratings;

  /// TripJack country ids (`106` = India).
  final String nationality;
  final String countryOfResidence;

  /// Upper-cased country the destination search is scoped to (`INDIA`).
  final String countryName;

  /// "I have a GST number and want to claim it" — changes the rates quoted.
  final bool gstApplied;

  /// Shared by every call that belongs to this search, as on the web.
  final String correlationId;

  int get nights {
    final diff = checkOut.difference(checkIn).inDays;
    return diff > 0 ? diff : 0;
  }

  int get adults => rooms.fold(0, (sum, r) => sum + r.adults);
  int get children => rooms.fold(0, (sum, r) => sum + r.children);
  int get guests => adults + children;

  /// A draft keeps the search so the page can be rebuilt after sign-in —
  /// the web's `saveBookingDraft({searchPayload})`. The correlation id is not
  /// kept: a restored booking starts a fresh supplier conversation.
  Map<String, dynamic> toJson() => {
    'destination': destination.toJson(),
    'checkIn': checkIn.toIso8601String(),
    'checkOut': checkOut.toIso8601String(),
    'rooms': rooms.map((r) => r.toRoomInfo()).toList(),
    'ratings': ratings,
    'nationality': nationality,
    'countryOfResidence': countryOfResidence,
    'countryName': countryName,
    'gstApplied': gstApplied,
  };

  /// Null when the saved shape is unusable.
  static HotelSearchQuery? fromJson(dynamic json) {
    final checkIn = DateTime.tryParse(asString(_get(json, 'checkIn')));
    final checkOut = DateTime.tryParse(asString(_get(json, 'checkOut')));
    final rooms = asList(_get(json, 'rooms'))
        .map(
          (r) => RoomOccupancy(
            adults: asInt(_get(r, 'numberOfAdults'), fallback: 1),
            childAges: asList(
              _get(r, 'childAge'),
            ).map((a) => asInt(a)).toList(),
          ),
        )
        .toList();
    if (checkIn == null || checkOut == null || rooms.isEmpty) return null;
    return HotelSearchQuery(
      destination: HoneymoonDestination.fromJson(_get(json, 'destination')),
      checkIn: checkIn,
      checkOut: checkOut,
      rooms: rooms,
      ratings: asList(_get(json, 'ratings')).map(asString).toList(),
      nationality: asString(_get(json, 'nationality'), fallback: '106'),
      countryOfResidence: asString(
        _get(json, 'countryOfResidence'),
        fallback: '106',
      ),
      countryName: asString(_get(json, 'countryName'), fallback: 'INDIA'),
      gstApplied: _get(json, 'gstApplied') == true,
    );
  }

  /// Same format as the web's `createCorrelationId` fallback.
  static String newCorrelationId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final salt = (now * 7919 % 2176782336).toRadixString(36).padLeft(6, '0');
    return 'corr-$now-$salt';
  }
}

// ---------------------------------------------------------------------------
// Hotel result (POST hotels/search)
// ---------------------------------------------------------------------------

class HotelResult {
  const HotelResult({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.address = '',
    this.city = '',
    this.starRating = 0,
    this.reviewScore = 0,
    this.reviewCount = 0,
    this.price = 0,
    this.currency = 'INR',
    this.facilities = const [],
    this.optionId = '',
    this.propertyType = '',
    this.mealBasis = '',
    this.isRefundable = false,
    this.reviewLabel = '',
    this.images = const [],
    this.supplierName = '',
    this.available = true,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String address;
  final String city;
  final double starRating;
  final double reviewScore;
  final int reviewCount;
  final double price;
  final String currency;
  final List<String> facilities;

  /// Needed by `hotels/detail` when the caller drills into a property.
  final String optionId;

  /// "Hotel", "Resort", "Apartment"… — the Property Type filter groups on this.
  final String propertyType;

  /// Board basis on the cheapest option ("Room Only", "Breakfast"…). The Meal
  /// Type filter groups on this.
  final String mealBasis;

  /// Whether the cheapest option can be cancelled for a refund. Drives the
  /// Free Cancellation filter and the card's badge.
  final bool isRefundable;

  /// The supplier's own wording for [reviewScore] — "Excellent", "Very good".
  final String reviewLabel;

  /// Card gallery, cover photo first, capped at ten like the web's cards.
  final List<String> images;

  /// Sent back to `hotels/detail` as `userIntent.supplierName`.
  final String supplierName;

  /// False when the property had no rates for the dates and came back as
  /// static content only.
  final bool available;

  bool get hasPrice => price > 0;

  factory HotelResult.fromJson(dynamic json) {
    // TripJack nests the property under different keys depending on which
    // listing endpoint produced it.
    final hotel = _get(json, 'hotel') ?? _get(json, 'staticContent') ?? json;

    final id = firstNonEmpty([
      _get(json, 'id'),
      _get(json, 'hid'),
      _get(json, 'tjid'),
      _get(hotel, 'id'),
      _get(hotel, 'hid'),
    ]);

    // BUG FIX: only the first image was read, from `{url}` entries, so the
    // cover photo was whatever sat at index 0. The web's `getHotelImages`
    // leads with `heroImage`, then the entry flagged `isHero`, then the rest,
    // deduped and capped at ten — for some properties the hero is entry 47.
    final gallery = asList(
      _get(hotel, 'images') ?? _get(json, 'images') ?? _get(hotel, 'gallery'),
    );
    String urlOf(dynamic entry) => entry is String
        ? entry
        : firstNonEmpty([
            _get(entry, 'url'),
            _get(entry, 'imageUrl'),
            _get(entry, 'path'),
            _get(entry, 'src'),
            _dig(entry, ['links', 'Standard', 'href']),
          ]);
    final images = <String>[];
    for (final entry in [
      _get(hotel, 'heroImage') ?? _get(json, 'heroImage'),
      ...gallery.where((g) => _get(g, 'isHero') == true),
      ...gallery,
      ...asList(_get(hotel, 'img')),
      _get(hotel, 'image'),
    ]) {
      final url = urlOf(entry);
      if (url.isEmpty || images.contains(url)) continue;
      images.add(url);
      if (images.length >= 10) break;
    }
    final image = images.isEmpty ? '' : images.first;

    // Board basis and refundability live on the cheapest rate/option, which
    // TripJack exposes under `rate[0]` on some responses and `options[0]` on
    // others. Same fallback chain the web client walks.
    final rates = asList(_get(json, 'rate') ?? _get(hotel, 'rate'));
    final rate = rates.isEmpty ? null : rates.first;
    final opts = asList(_get(json, 'options') ?? _get(json, 'ops'));
    final option = opts.isEmpty ? null : opts.first;

    // BUG FIX: the live listing carries its price as `minPrice`,
    // `rate[0].totalPrice` and `options[0].pricing.totalPrice` — none of which
    // were read, so every card showed "Tap to see live pricing". Same order
    // as the web's `getPriceInfo`.
    final price = asDouble(
      _get(json, 'minPrice') ??
          _get(rate, 'totalPrice') ??
          _dig(rate, ['price', 'totalPrice']) ??
          _dig(option, ['pricing', 'totalPrice']) ??
          _get(option, 'totalPrice') ??
          _get(option, 'tp') ??
          _get(json, 'price'),
    );

    // BUG FIX: the v3 option names its id `optionId`, not `id`, so this came
    // back empty and `hotels/detail` was asked about no option at all.
    final optionId = firstNonEmpty([
      _get(rate, 'optionId'),
      _get(option, 'optionId'),
      _get(option, 'id'),
      _get(json, 'optionId'),
      _get(json, 'oid'),
    ]);

    // Replaced by the price/optionId chains above.
    // double price = asDouble(
    //   _get(json, 'price') ??
    //       _dig(json, ['totalPrice', 'amount']) ??
    //       _dig(json, ['fare', 'totalFare']),
    // );
    // if (price == 0) {
    //   final options = asList(_get(json, 'options') ?? _get(json, 'ops'));
    //   if (options.isNotEmpty) {
    //     price = asDouble(
    //       _get(options.first, 'totalPrice') ??
    //           _get(options.first, 'tp') ??
    //           _dig(options.first, ['price', 'total']),
    //     );
    //   }
    // }
    //
    // String optionId = firstNonEmpty([
    //   _get(json, 'optionId'),
    //   _get(json, 'oid'),
    // ]);
    // if (optionId.isEmpty) {
    //   final options = asList(_get(json, 'options') ?? _get(json, 'ops'));
    //   if (options.isNotEmpty) {
    //     optionId = firstNonEmpty([
    //       _get(options.first, 'id'),
    //       _get(options.first, 'oid'),
    //     ]);
    //   }
    // }

    final mealBasis = firstNonEmpty([
      _get(rate, 'mealbasis'),
      _get(rate, 'mealBasis'),
      _get(option, 'mealBasis'),
      _get(hotel, 'mealBasis'),
    ], fallback: 'Room Only');

    final refundable =
        _dig(rate, ['cancellation', 'isRefundable']) ??
        _dig(option, ['cancellation', 'isRefundable']) ??
        _dig(hotel, ['cancellation', 'isRefundable']);

    // `userRating.score` is out of 100; the portal divides by 20 to show it on
    // the familiar 5-point scale.
    final userScore = _dig(hotel, ['userRating', 'score']);
    final reviewScore = userScore != null
        ? asDouble(userScore) / 20
        : asDouble(
            _dig(hotel, ['reviews', 0, 'rating']) ?? _get(hotel, 'reviewScore'),
          );

    // TripJack's own amenity groups (`tja[].am[]`) are richer than the flat
    // facilities list, so they win when present.
    final amenities = <String>[];
    final seen = <String>{};
    void addAmenity(dynamic item) {
      final name = (item is String ? item : asString(_get(item, 'name')))
          .trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) return;
      amenities.add(name);
    }

    for (final group in asList(_get(hotel, 'tja'))) {
      for (final item in asList(_get(group, 'am'))) {
        addAmenity(item);
      }
    }
    if (amenities.isEmpty) {
      // BUG FIX: `amenities`/`facilities` arrive keyed by index
      // (`{"0": {...}}`), not as lists, so `asList` found nothing and cards
      // had no amenity chips. Maps are flattened as the web's `toAmenityList`
      // does.
      for (final key in ['amenities', 'facilities', 'fac']) {
        final value = _get(hotel, key);
        for (final item in value is Map ? value.values : asList(value)) {
          addAmenity(item);
        }
      }
    }

    // The v3 listing's address is `{line_1, city, statename, …}`. The web card
    // prints just the city; the old keys (`adr`, `line1`) never matched and
    // `_get(hotel, 'address')` stringified the whole map.
    final address = _get(hotel, 'address') ?? _get(hotel, 'ad');

    return HotelResult(
      id: id,
      name: firstNonEmpty([
        _get(hotel, 'name'),
        _get(json, 'name'),
        _get(hotel, 'hotelName'),
      ], fallback: 'Hotel'),
      imageUrl: image,
      images: images,
      address: firstNonEmpty([
        _get(address, 'line_1'),
        _get(address, 'adr'),
        _get(address, 'line1'),
        if (address is String) address,
      ]),
      city: _titleCase(
        firstNonEmpty([
          _dig(address, ['city', 'name']),
          _get(address, 'city'),
          _get(address, 'ctn'),
          _get(hotel, 'cityName'),
        ]),
      ),
      starRating: asDouble(_get(hotel, 'rt') ?? _get(hotel, 'starRating')),
      reviewScore: reviewScore,
      reviewCount: asInt(
        _dig(hotel, ['userRating', 'rc']) ??
            _dig(hotel, ['reviews', 0, 'count']) ??
            _get(hotel, 'reviewCount'),
      ),
      reviewLabel: asString(_dig(hotel, ['userRating', 'label'])),
      price: price,
      currency: firstNonEmpty([
        _get(rate, 'currency'),
        _get(json, 'currency'),
      ], fallback: 'INR'),
      facilities: amenities,
      optionId: optionId,
      propertyType: firstNonEmpty([
        _get(hotel, 'propertyType'),
        _get(hotel, 'categoryName'),
      ]),
      mealBasis: mealBasis,
      isRefundable: refundable == true,
      supplierName: firstNonEmpty([
        _get(rate, 'supplierName'),
        _get(json, 'supplierName'),
      ]),
      available: _get(json, 'available') != false,
    );
  }

  /// Enough of the card to rebuild the detail page from a saved draft. The
  /// keys are ones [HotelResult.fromJson] reads back.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'images': images,
    'heroImage': imageUrl,
    'address': {'line_1': address, 'city': city},
    'starRating': starRating,
    'userRating': {
      'score': reviewScore * 20,
      'rc': reviewCount,
      'label': reviewLabel,
    },
    'minPrice': price,
    'currency': currency,
    'facilities': facilities,
    'propertyType': propertyType,
    'mealBasis': mealBasis,
    'cancellation': {'isRefundable': isRefundable},
    'rate': [
      {'optionId': optionId, 'supplierName': supplierName},
    ],
    'available': available,
  };

  /// "BHAVANI NAGAR" → "Bhavani Nagar"; mixed case is left alone.
  static String _titleCase(String value) {
    if (value.isEmpty || value != value.toUpperCase()) return value;
    return value.toLowerCase().replaceAllMapped(
      RegExp(r'\b[a-z]'),
      (m) => m.group(0)!.toUpperCase(),
    );
  }
}

/// Envelope returned by `POST hotels/search`.
class HotelSearchResult {
  const HotelSearchResult({
    required this.hotels,
    this.searchId = '',
    this.lastHotelId = '',
    this.totalCount = 0,
    this.serverHasMore = false,
    this.allUnavailable = false,
    this.totalProperties = 0,
    this.hotelCount,
    this.correlationId = '',
  });

  final List<HotelResult> hotels;
  final String searchId;

  /// Cursor for the next page; empty when there is no more data.
  final String lastHotelId;
  final int totalCount;

  /// The server's own `hasMore`. Only the server knows: a page can hold zero
  /// bookable hotels and still have hundreds of candidates left to sweep.
  final bool serverHasMore;

  /// Every property came back without rates for these dates — the cards are
  /// for reference only.
  final bool allUnavailable;

  /// TripJack's own count for the destination ("Showing 1897 hotels").
  final int totalProperties;

  /// Bookable hotels in this sweep; null when the server did not say.
  final int? hotelCount;

  final String correlationId;

  // BUG FIX: a cursor alone was treated as "more to come", but the backend
  // sends `lastHotelId` even on the final sweep, so paging never stopped. The
  // web requires both (`Boolean(nextLastHotelId) && extractHasMore(response)`).
  bool get hasMore => lastHotelId.isNotEmpty && serverHasMore;
  // bool get hasMore => lastHotelId.isNotEmpty;

  /// The headline count, preferring TripJack's destination total.
  int get displayCount =>
      totalProperties > 0 ? totalProperties : (hotelCount ?? hotels.length);

  factory HotelSearchResult.fromJson(dynamic json) {
    // The list has appeared under several keys across TripJack revisions.
    final raw =
        _get(json, 'hotels') ??
        _dig(json, ['data', 'hotels']) ??
        _get(json, 'searchResult') ??
        _dig(json, ['data', 'searchResult']) ??
        _get(json, 'results') ??
        _get(json, 'data');

    return HotelSearchResult(
      hotels: asList(raw).map(HotelResult.fromJson).toList(),
      searchId: firstNonEmpty([
        _get(json, 'searchId'),
        _dig(json, ['data', 'searchId']),
      ]),
      lastHotelId: firstNonEmpty([
        _get(json, 'lastHotelId'),
        _dig(json, ['pagination', 'lastHotelId']),
        _dig(json, ['data', 'lastHotelId']),
        _dig(json, ['data', 'pagination', 'lastHotelId']),
      ]),
      totalCount: asInt(
        _get(json, 'totalCount') ?? _dig(json, ['pagination', 'totalCount']),
      ),
      serverHasMore:
          (_get(json, 'hasMore') ??
              _dig(json, ['data', 'hasMore']) ??
              _dig(json, ['pagination', 'hasMore'])) ==
          true,
      allUnavailable:
          (_get(json, 'allUnavailable') ??
              _dig(json, ['data', 'allUnavailable'])) ==
          true,
      totalProperties: asInt(
        _get(json, 'totalProperties') ??
            _dig(json, ['data', 'totalProperties']),
      ),
      hotelCount:
          (_get(json, 'hotelCount') ?? _dig(json, ['data', 'hotelCount']))
              is num
          ? asInt(
              _get(json, 'hotelCount') ?? _dig(json, ['data', 'hotelCount']),
            )
          : null,
      correlationId: asString(_get(json, 'correlationId')),
    );
  }
}

// ---------------------------------------------------------------------------
// Flight result (POST /tj/fms/search)
// ---------------------------------------------------------------------------

class FlightResult {
  const FlightResult({
    required this.id,
    this.airline = '',
    this.airlineCode = '',
    this.flightNumber = '',
    this.fromCode = '',
    this.toCode = '',
    this.departure,
    this.arrival,
    this.durationMinutes = 0,
    this.stops = 0,
    this.price = 0,
    this.cabinClass = '',
    this.fareType = '',
    this.raw = const <String, dynamic>{},
  });

  /// TripJack's `totalPriceList[0].id` — the priceId `POST /tj/fms/review`
  /// takes to re-price this exact fare and open a booking session.
  final String id;
  final String airline;
  final String airlineCode;
  final String flightNumber;
  final String fromCode;
  final String toCode;
  final DateTime? departure;
  final DateTime? arrival;
  final int durationMinutes;
  final int stops;
  final double price;
  final String cabinClass;

  /// The supplier's `fareIdentifier` for the chosen fare — PUBLISHED, SME,
  /// FLEXI_PLUS, SPECIAL_RETURN…
  final String fareType;

  /// True when this fare is only sold as a matched onward+return pair, so it
  /// cannot be combined with a leg the traveller picked independently.
  bool get isReturnCoupledFare => fareType.toUpperCase() == 'SPECIAL_RETURN';

  /// The untouched `tripInfos` entry. The booking payload is built from the
  /// supplier's own structure (`sI`, `totalPriceList`), so it has to survive
  /// the search screen rather than being flattened away.
  final Map<String, dynamic> raw;

  /// Every segment on this trip, in order.
  List<dynamic> get segments => asList(readKey(raw, 'sI'));

  /// Chooses the fare a traveller can book on its own.
  ///
  /// A trip carries several fares and `totalPriceList[0]` is frequently a
  /// SPECIAL_RETURN one — a discounted round trip that is only valid when
  /// *both* legs come from that same pairing. Sending it alongside a leg the
  /// traveller picked independently is rejected outright:
  ///
  ///     1080 — All Segments Must be selected if Special Return fare.
  ///
  /// Preferring PUBLISHED (and otherwise anything not return-coupled) is what
  /// makes picking the two legs separately a valid combination at all.
  static dynamic pickBookableFare(List<dynamic> fares) {
    if (fares.isEmpty) return null;

    for (final f in fares) {
      if (asString(_get(f, 'fareIdentifier')).toUpperCase() == 'PUBLISHED') {
        return f;
      }
    }
    for (final f in fares) {
      if (asString(_get(f, 'fareIdentifier')).toUpperCase() !=
          'SPECIAL_RETURN') {
        return f;
      }
    }
    // Only return-coupled fares exist for this trip. It is still shown, and
    // the supplier's own message explains the refusal if it is combined.
    return fares.first;
  }

  /// The fare that [id] refers to.
  Map<String, dynamic> get selectedFare {
    final fares = asList(readKey(raw, 'totalPriceList'));
    if (fares.isEmpty) return const <String, dynamic>{};
    for (final f in fares) {
      if (asString(readKey(f, 'id')) == id) return asJsonMap(f);
    }
    return asJsonMap(fares.first);
  }

  /// A copy of this trip carrying only [fares].
  ///
  /// Fare-level filters (fare type, cancellation, baggage, price) narrow a
  /// trip's `totalPriceList` rather than dropping it, so the card must re-read
  /// its bookable fare from what survived — otherwise `id` still points at a
  /// fare the user just filtered out.
  FlightResult withFares(List<dynamic> fares) {
    if (fares.isEmpty) return this;
    return FlightResult.fromTripJack({...raw, 'totalPriceList': fares});
  }

  /// Every fare this trip is sold at, in the supplier's order — the options
  /// the web lists under each card.
  List<dynamic> get fares => asList(readKey(raw, 'totalPriceList'));

  /// This trip with [fareId] as the chosen fare, when the trip still carries
  /// it; otherwise the trip unchanged.
  ///
  /// The web keeps the chosen fare per card and sends *that* fare's priceId to
  /// review. Before this existed the app always booked the one fare
  /// [pickBookableFare] chose, so a traveller could never pick a refundable
  /// or a baggage fare over the cheapest one.
  FlightResult withSelectedFare(String fareId) {
    if (fareId.isEmpty || fareId == id) return this;
    for (final f in fares) {
      if (asString(_get(f, 'id')) != fareId) continue;
      return FlightResult(
        id: fareId,
        airline: airline,
        airlineCode: airlineCode,
        flightNumber: flightNumber,
        fromCode: fromCode,
        toCode: toCode,
        departure: departure,
        arrival: arrival,
        durationMinutes: durationMinutes,
        stops: stops,
        price: asDouble(_dig(f, ['fd', 'ADULT', 'fC', 'TF'])),
        cabinClass: asString(_dig(f, ['fd', 'ADULT', 'cc'])),
        fareType: asString(_get(f, 'fareIdentifier')),
        raw: raw,
      );
    }
    return this;
  }

  /// Stable identity for a trip across sorting, filtering and fare changes:
  /// every flight number on it plus the first departure — the web's
  /// `getFlightKey`.
  String get tripKey {
    final numbers = [
      for (final s in segments)
        '${asString(_dig(s, ['fD', 'aI', 'code']))}${asString(_dig(s, ['fD', 'fN']))}',
    ].join('-');
    final first = segments.isEmpty ? null : segments.first;
    return '$numbers-$fromCode-$toCode-${asString(_get(first, 'dt'))}';
  }

  String get durationLabel {
    if (durationMinutes <= 0) return '';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  String get stopsLabel => stops == 0
      ? 'Non-stop'
      : stops == 1
      ? '1 stop'
      : '$stops stops';

  /// TripJack shape: `sI` segment list, `totalPriceList` fares.
  factory FlightResult.fromTripJack(dynamic json) {
    final segments = asList(_get(json, 'sI'));
    if (segments.isEmpty) return const FlightResult(id: '');

    final first = segments.first;
    final last = segments.last;
    final fd = _get(first, 'fD');

    final fares = asList(_get(json, 'totalPriceList'));
    final fare = pickBookableFare(fares);
    final id = asString(_get(fare, 'id'));
    final price = asDouble(_dig(fare, ['fd', 'ADULT', 'fC', 'TF']));
    final fareType = asString(_get(fare, 'fareIdentifier'));

    // BUG FIX: only the flying time was summed, so a connecting trip read
    // hours shorter than it is and "Fastest" favoured long layovers. The web's
    // `getTripDurationMinutes` adds each segment's connection time (`cT`) too.
    int totalDuration = 0;
    for (final s in segments) {
      totalDuration += asInt(_get(s, 'duration')) + asInt(_get(s, 'cT'));
    }

    return FlightResult(
      id: id,
      cabinClass: asString(_dig(fare, ['fd', 'ADULT', 'cc'])),
      fareType: fareType,
      raw: asJsonMap(json),
      airline: asString(_dig(fd, ['aI', 'name'])),
      airlineCode: asString(_dig(fd, ['aI', 'code'])),
      flightNumber: asString(_get(fd, 'fN')),
      fromCode: asString(_dig(first, ['da', 'code'])),
      toCode: asString(_dig(last, ['aa', 'code'])),
      departure: DateTime.tryParse(asString(_get(first, 'dt'))),
      arrival: DateTime.tryParse(asString(_get(last, 'at'))),
      durationMinutes: totalDuration,
      stops: segments.length - 1,
      price: price,
    );
  }
}

/// An airport/city from `GET /tj/meta/locations`.
class FlightLocation {
  const FlightLocation({
    required this.code,
    required this.name,
    this.city = '',
    this.country = '',
  });

  final String code;
  final String name;
  final String city;
  final String country;

  String get subtitle {
    final parts = <String>[
      if (city.isNotEmpty) city,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }

  /// Round-trips through [FlightLocation.fromJson], so a remembered search
  /// restores the airport exactly as it was picked.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'code': code,
    'name': name,
    'city': city,
    'country': country,
  };

  factory FlightLocation.fromJson(dynamic json) {
    return FlightLocation(
      code: firstNonEmpty([
        _get(json, 'code'),
        _get(json, 'iata'),
        _get(json, 'airportCode'),
      ]),
      name: firstNonEmpty([
        _get(json, 'name'),
        _get(json, 'airportName'),
        _get(json, 'displayName'),
      ]),
      city: firstNonEmpty([_get(json, 'cityName'), _get(json, 'city')]),
      country: firstNonEmpty([
        _get(json, 'countryName'),
        _get(json, 'country'),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Insurance plan (POST /tripsafe/search)
// ---------------------------------------------------------------------------

/// One benefit line on an insurance product.
class InsuranceBenefit {
  const InsuranceBenefit({
    required this.name,
    this.category = '',
    this.coverage = '',
    this.description = '',
    this.type = '',
    this.visibility = '',
  });

  final String name;
  final String category;

  /// Sum insured, as the insurer words it ("USD 50,000").
  final String coverage;
  final String description;

  /// "INSURANCE" or "ASSISTANCE" — the two families are shown separately.
  final String type;

  /// "BANNER" / "QUOTATION" benefits are the ones the insurer wants surfaced.
  final String visibility;

  bool get isAssistance => type.toUpperCase().contains('ASSISTANCE');
  bool get isCoverage => type.toUpperCase().contains('INSURANCE');
  bool get isHighlighted {
    final v = visibility.toUpperCase();
    return v == 'BANNER' || v == 'QUOTATION';
  }

  factory InsuranceBenefit.fromJson(dynamic json) => InsuranceBenefit(
    name: asString(_get(json, 'name')),
    category: firstNonEmpty([
      _get(json, 'ic'),
      _get(json, 'type'),
    ], fallback: 'Other'),
    coverage: asString(_get(json, 'sumins')),
    description: asString(_get(json, 'dsc')),
    type: asString(_get(json, 'type')),
    visibility: asString(_get(json, 'bv')),
  );
}

/// A bookable insurance product.
///
/// The insurer's search response is three levels deep — `isr.iinfo.pli[]` are
/// *plans*, each holding `pi[]` *products*, and the fare sits in a fourth
/// structure keyed by traveller count. A product is only bookable with both
/// its plan id and its own id, so both travel together here.
class InsurancePlan {
  const InsurancePlan({
    required this.planId,
    required this.productId,
    required this.name,
    this.insurer = '',
    this.coverageAmount = '',
    this.regionName = '',
    this.price = 0,
    this.currency = 'INR',
    this.travellerCount = 1,
    this.partners = const [],
    this.benefits = const [],
    this.raw = const <String, dynamic>{},
  });

  /// `plid` — identifies the plan the product belongs to.
  final String planId;

  /// `pid` — identifies the product itself.
  final String productId;

  final String name;
  final String insurer;

  /// Sum insured as the insurer words it, e.g. "USD 100,000".
  final String coverageAmount;
  final String regionName;

  /// Total premium for the whole party, not per traveller.
  final double price;
  final String currency;
  final int travellerCount;

  /// Assistance partners bundled with the policy.
  final List<String> partners;
  final List<InsuranceBenefit> benefits;

  final Map<String, dynamic> raw;

  bool get isBookable => planId.isNotEmpty && productId.isNotEmpty && price > 0;

  /// A readable insurer name — the payload carries a code.
  String get insurerLabel {
    const labels = {'ABHI': 'Aditya Birla Health Insurance'};
    final code = insurer.toUpperCase();
    if (labels.containsKey(code)) return labels[code]!;
    return insurer.isEmpty ? 'Insurance partner' : '$insurer Insurance';
  }

  /// The handful of benefits worth putting on the card.
  List<String> get highlights => benefits
      .where((b) => b.isHighlighted)
      .map((b) => b.name)
      .take(4)
      .toList();

  List<String> get coverageTags {
    final banner = benefits
        .where((b) => b.isHighlighted && b.isCoverage)
        .map((b) => b.name)
        .toList();
    if (banner.isNotEmpty) return banner.take(3).toList();
    return benefits
        .where((b) => b.isCoverage)
        .map((b) => b.name)
        .take(3)
        .toList();
  }

  List<String> get assistanceTags {
    final banner = benefits
        .where((b) => b.isHighlighted && b.isAssistance)
        .map((b) => b.name)
        .toList();
    if (banner.isNotEmpty) return banner.take(3).toList();
    return benefits
        .where((b) => b.isAssistance)
        .map((b) => b.name)
        .take(3)
        .toList();
  }

  /// Every product across every plan in one search response.
  ///
  /// The response nests results under `isr.iinfo.pli`, sometimes behind an
  /// extra `data` envelope. Reading it as a flat `{ data: [...] }` list — as
  /// this used to — never matched, so insurance search always came back empty
  /// even when the insurer had returned plans.
  static List<InsurancePlan> fromSearchResponse(
    dynamic payload, {
    int fallbackTravellerCount = 1,
  }) {
    final raw = _get(payload, 'data') ?? payload;
    final root = _get(raw, 'data') ?? raw;

    final plans = asList(
      _dig(root, ['isr', 'iinfo', 'pli']) ?? _dig(raw, ['isr', 'iinfo', 'pli']),
    );

    final travellers = asList(
      _dig(root, ['isq', 'iti']) ?? _dig(raw, ['isq', 'iti']),
    );
    // The web prices for the party the response echoes back (`isq.iti`); when
    // a response carries no `isq`, the party searched for is used instead of
    // pricing for one person.
    final count = travellers.isEmpty
        ? (fallbackTravellerCount < 1 ? 1 : fallbackTravellerCount)
        : travellers.length;

    final out = <InsurancePlan>[];
    for (final plan in plans) {
      final planId = asString(_get(plan, 'plid'));
      for (final product in asList(_get(plan, 'pi'))) {
        final parsed = InsurancePlan._fromProduct(
          planId: planId,
          product: product,
          travellerCount: count,
        );
        if (parsed.name.isNotEmpty) out.add(parsed);
      }
    }
    return out;
  }

  factory InsurancePlan._fromProduct({
    required String planId,
    required dynamic product,
    required int travellerCount,
  }) {
    return InsurancePlan(
      planId: planId,
      productId: asString(_get(product, 'pid')),
      name: firstNonEmpty([
        _get(product, 'pi'),
        _get(product, 'pn'),
      ], fallback: 'Insurance plan'),
      insurer: asString(_get(product, 'ip')),
      coverageAmount: asString(_get(product, 'pn')),
      regionName: asString(_get(product, 'rname')),
      price: priceFor(product, travellerCount),
      travellerCount: travellerCount,
      partners: asList(
        _get(product, 'aps'),
      ).map((p) => asString(p)).where((p) => p.isNotEmpty).toList(),
      benefits: _dedupeBenefits(asList(_get(product, 'pbft'))),
      raw: asJsonMap(product),
    );
  }

  static List<InsuranceBenefit> _dedupeBenefits(List<dynamic> items) {
    final seen = <String>{};
    final out = <InsuranceBenefit>[];
    for (final item in items) {
      final benefit = InsuranceBenefit.fromJson(item);
      if (benefit.name.isEmpty || !seen.add(benefit.name)) continue;
      out.add(benefit);
    }
    return out;
  }

  /// Total premium for [travellerCount] people.
  ///
  /// Premiums live in `pfd.ppd.ppdf`, a map keyed by party size. Two shapes
  /// exist and they are priced differently:
  ///
  /// * every key quotes the same amount → that amount is *per traveller* and
  ///   has to be multiplied by the party size;
  /// * the keys differ → the highest key already quotes the whole party, so
  ///   multiplying again would charge several times over.
  ///
  /// When the block is missing entirely, the flat totals are used instead.
  static double priceFor(dynamic product, int travellerCount) {
    final info = _premiumFor(product, travellerCount);
    final perTraveller = asDouble(_get(info.fareComponents, 'TF'));

    if (perTraveller > 0) {
      return perTraveller * (info.isWholeParty ? 1 : travellerCount);
    }

    // No per-party block — fall back to the product's own totals.
    final fromTotal = asDouble(_dig(product, ['tfd', 'ifc', 'TF']));
    if (fromTotal > 0) return fromTotal;
    final fromTraveller = asDouble(
      _dig(product, ['iti', 0, 'fd', 'ifc', 'TF']),
    );
    if (fromTraveller > 0) return fromTraveller;
    return asDouble(_get(product, 'ptf'));
  }

  static ({Object? fareComponents, bool isWholeParty}) _premiumFor(
    dynamic product,
    int travellerCount,
  ) {
    final ppdf = _dig(product, ['pfd', 'ppd', 'ppdf']);
    if (ppdf is! Map || ppdf.isEmpty) {
      return (fareComponents: null, isWholeParty: false);
    }

    final keys = ppdf.keys.map((k) => asString(k)).toList()
      ..sort((a, b) => asInt(a).compareTo(asInt(b)));

    final firstTf = asDouble(_dig(ppdf[keys.first], [0, 'ifc', 'TF']));
    final allSame = keys.every(
      (k) => asDouble(_dig(ppdf[k], [0, 'ifc', 'TF'])) == firstTf,
    );

    if (allSame) {
      final entry = ppdf['$travellerCount'] ?? ppdf['1'];
      return (fareComponents: _dig(entry, [0, 'ifc']), isWholeParty: false);
    }

    return (
      fareComponents: _dig(ppdf[keys.last], [0, 'ifc']),
      isWholeParty: true,
    );
  }
}

// ---------------------------------------------------------------------------
// Cab quote (POST tripjack-cabs/quotes)
// ---------------------------------------------------------------------------

/// One bookable cab option.
///
/// The supplier nests these two levels deep — `quotesInfo` is a list of vehicle
/// *groups*, each holding a list of vendor *quotes* — and the fields the /book
/// endpoint validates against are split across both levels. Reading a group as
/// if it were a quote (as this model used to) found no fare at all, so every
/// option was discarded by the `price > 0` filter and transfers always came
/// back empty. [flatten] mirrors `flattenCabQuotes` in the web client.
class CabQuote {
  const CabQuote({
    required this.id,
    required this.vehicleName,
    this.category = '',
    this.vehicleType = '',
    this.imageUrl = '',
    this.seats = 0,
    this.luggage = 0,
    this.price = 0,
    this.netFare = 0,
    this.totalTax = 0,
    this.currency = 'INR',
    this.vendorId = '',
    this.quotationId = '',
    this.quoteChildId = '',
    this.paxCount = 0,
    this.luggageCount = 0,
    this.model = '',
    this.benefits = const [],
    this.policies = const <String, dynamic>{},
    this.label = '',
    this.similarType = '',
  });

  /// The group's own `label` ("Sedan") — the web card's title and part of
  /// the key its results are grouped by. Empty when the supplier sent none
  /// ([vehicleName] then falls back to model / type).
  final String label;

  /// The group's `similarType` ("Swift Dzire or similar").
  final String similarType;

  /// Stable identity for list keys — the supplier's quotation id.
  final String id;
  final String vehicleName;
  final String category;
  final String vehicleType;
  final String imageUrl;

  /// Seats and bags the *group* advertises, for the card.
  final int seats;
  final int luggage;

  /// Gross fare = net + tax. This is the bookable amount the supplier
  /// validates the payment against, and what the traveller sees.
  final double price;
  final double netFare;
  final double totalTax;
  final String currency;

  final String vendorId;
  final String quotationId;
  final String quoteChildId;

  /// Capacities carried on the *quote*, which is what /book echoes back.
  final int paxCount;
  final int luggageCount;
  final String model;

  final List<String> benefits;
  final Map<String, dynamic> policies;

  /// `quotationInfo` block of the booking payload.
  Map<String, dynamic> toQuotationInfo() => <String, dynamic>{
    'vehicleType': vehicleType,
    'vehicleCategory': category,
    'quoteId': quotationId,
    'childQuoteId': quoteChildId,
    'paxCount': paxCount,
    'luggageCount': luggageCount,
    'vendorId': vendorId,
  };

  /// `pricingInfo` block of the booking payload. Amounts go up as strings —
  /// the supplier rejects numbers here.
  Map<String, dynamic> toPricingInfo() => <String, dynamic>{
    'netAmount': _money(netFare),
    'addonsPrice': '0.00',
    'tjTaxAmount': _money(totalTax),
    'agentMarkup': 0,
    'agentMarkupSplitup': const {
      'onwardJourneyMarkup': 0,
      'returnJourneyMarkup': 0,
    },
    'grossAmount': _money(price),
    'tjManagementFee': '0.00',
  };

  static String _money(double v) => v.toStringAsFixed(2);

  /// Flattens `quotesInfo` groups into one list of bookable options, cheapest
  /// first — the group carries the vehicle, the quote carries the fare.
  static List<CabQuote> flatten(dynamic quotesInfo) {
    final out = <CabQuote>[];

    for (final group in asList(quotesInfo)) {
      final images = asList(readKey(group, 'vehicleImages'));
      final groupCategory = asString(readKey(group, 'vehicleCategory'));
      final similarType = asString(readKey(group, 'similarType'));

      for (final quote in asList(readKey(group, 'quotes'))) {
        final net = asDouble(digPath(quote, ['fareBreakup', 'totalFare']));
        final tax = asDouble(digPath(quote, ['fareBreakup', 'totalTax']));
        final quotationId = asString(readKey(quote, 'quotationId'));
        // Deliberately stricter than the web (`flattenCabQuotes` keeps every
        // quote): an unpriced quote would show as a ₹0 cab whose booking and
        // payment both fail, so it is dropped rather than offered as free.
        if (net + tax <= 0) continue;
        final paxCapacity = readKey(group, 'paxCapacity');
        final luggageCapacity = readKey(group, 'luggageCapacity');

        out.add(
          CabQuote(
            id: quotationId.isNotEmpty
                ? quotationId
                : '${asString(readKey(group, 'vehicleType'))}-${out.length}',
            vehicleName: firstNonEmpty([
              readKey(group, 'label'),
              readKey(quote, 'model'),
              similarType,
              groupCategory,
            ], fallback: 'Vehicle'),
            category: groupCategory,
            vehicleType: asString(readKey(group, 'vehicleType')),
            imageUrl: images.isEmpty ? '' : asString(images.first),
            // seats: asInt(readKey(group, 'paxCapacity')),
            // luggage: asInt(readKey(group, 'luggageCapacity')),
            // The web's `paxCapacity ?? paxCount`: the group's capacity, else
            // the quote's own count.
            seats: paxCapacity == null
                ? asInt(readKey(quote, 'paxCount'))
                : asInt(paxCapacity),
            luggage: luggageCapacity == null
                ? asInt(readKey(quote, 'luggageCount'))
                : asInt(luggageCapacity),
            label: asString(readKey(group, 'label')),
            similarType: similarType,
            netFare: net,
            totalTax: tax,
            price: net + tax,
            vendorId: asString(readKey(quote, 'vendorId')),
            quotationId: quotationId,
            quoteChildId: asString(readKey(quote, 'quoteChildId')),
            paxCount: asInt(readKey(quote, 'paxCount')),
            luggageCount: asInt(readKey(quote, 'luggageCount')),
            model: firstNonEmpty([readKey(quote, 'model'), similarType]),
            benefits: asList(readKey(quote, 'benefits'))
                .map((b) => b is String ? b : asString(readKey(b, 'name')))
                .where((b) => b.isNotEmpty)
                .toList(),
            policies: asJsonMap(readKey(quote, 'policies')),
          ),
        );
      }
    }

    // A stable sort, like the web's Array.prototype.sort: equal fares keep
    // the supplier's order.
    // out.sort((a, b) => a.price.compareTo(b.price));
    final indexed = [for (var i = 0; i < out.length; i++) (i, out[i])];
    indexed.sort((a, b) {
      final byFare = a.$2.price.compareTo(b.$2.price);
      return byFare != 0 ? byFare : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

/// Everything `POST tripjack-cabs/quotes` returns.
///
/// `journeyInfo` and `routeDetails` are not display data — the /book payload
/// echoes both back verbatim, so they have to travel with the quotes from the
/// search screen to the booking screen.
class CabQuoteResult {
  const CabQuoteResult({
    this.quotes = const [],
    this.journeyInfo = const <String, dynamic>{},
    this.routeDetails = const <String, dynamic>{},
  });

  final List<CabQuote> quotes;
  final Map<String, dynamic> journeyInfo;
  final Map<String, dynamic> routeDetails;

  bool get isAirportTransfer =>
      asString(readKey(journeyInfo, 'journeyType')).toUpperCase() ==
      'AIRPORT_TRANSFER';

  factory CabQuoteResult.fromJson(dynamic data) => CabQuoteResult(
    quotes: CabQuote.flatten(readKey(data, 'quotesInfo')),
    journeyInfo: asJsonMap(readKey(data, 'journeyInfo')),
    routeDetails: asJsonMap(readKey(data, 'routeDetails')),
  );
}

// ---------------------------------------------------------------------------
// Flight search result (POST /tj/fms/search)
// ---------------------------------------------------------------------------

/// Search results, still split by leg.
///
/// On a round trip the supplier prices the two directions separately and the
/// booking session needs one fare from each, so the split has to survive into
/// the UI rather than being flattened into a single list of cards.
class FlightSearchResult {
  const FlightSearchResult({this.onward = const [], this.inbound = const []});

  final List<FlightResult> onward;
  final List<FlightResult> inbound;

  /// True when the supplier actually returned a separate return leg. A round
  /// trip sold as a single combined fare comes back as `onward` alone, and is
  /// booked in one step like a one-way.
  bool get hasSeparateReturn => inbound.isNotEmpty;

  bool get isEmpty => onward.isEmpty && inbound.isEmpty;

  int get totalCount => onward.length + inbound.length;

  /// Cheapest first, which is how both lists are always presented.
  List<FlightResult> get sortedOnward =>
      List<FlightResult>.from(onward)
        ..sort((a, b) => a.price.compareTo(b.price));

  List<FlightResult> get sortedInbound =>
      List<FlightResult>.from(inbound)
        ..sort((a, b) => a.price.compareTo(b.price));
}

// ---------------------------------------------------------------------------
// Multi-city
// ---------------------------------------------------------------------------

/// One requested hop of a multi-city search.
class FlightLeg {
  const FlightLeg({required this.from, required this.to, required this.date});

  final FlightLocation from;
  final FlightLocation to;
  final DateTime date;

  String get routeLabel => '${from.code} → ${to.code}';

  Map<String, dynamic> toRouteInfo(String Function(DateTime) formatDate) =>
      <String, dynamic>{
        'fromCityOrAirport': {'code': from.code},
        'toCityOrAirport': {'code': to.code},
        'travelDate': formatDate(date),
      };
}

/// Multi-city results, kept bucketed by route.
///
/// TripJack answers a multi-city search in one of two shapes, and they mean
/// very different things:
///
///  * **Per-route** (typically domestic) — numeric keys `"0"`, `"1"`, … one
///    bucket per requested leg. Each entry is an independent itinerary with its
///    own priceId, so the traveller picks one flight per leg and the booking
///    session is opened with every chosen priceId.
///  * **COMBO** (typically international) — a single combined itinerary
///    covering every leg under one priceId. There is nothing to pick per leg:
///    choosing one option books the whole journey.
///
/// Collapsing these into one list would either lose the per-leg choice or make
/// a combined fare look like it only covers the first hop, so the distinction
/// is carried through to the UI.
class MultiCitySearchResult {
  const MultiCitySearchResult({this.routes = const {}, this.isCombo = false});

  /// Route index → the itineraries offered for it. For a COMBO response there
  /// is exactly one bucket, keyed 0, holding the combined itineraries.
  final Map<int, List<FlightResult>> routes;

  final bool isCombo;

  bool get isEmpty => routes.values.every((list) => list.isEmpty);

  /// Route indices that actually came back with options, in order. A leg the
  /// supplier could not serve simply has no bucket, and must not be treated as
  /// an outstanding selection.
  List<int> get bookableRoutes {
    final keys =
        routes.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => e.key)
            .toList()
          ..sort();
    return keys;
  }

  List<FlightResult> forRoute(int index) => routes[index] ?? const [];

  /// Buckets a `tj/fms/search` response whose query carried several
  /// `routeInfos`. [legCount] is how many hops were asked for, which is what
  /// tells a single-bucket `ONWARD` reply covering a whole multi-hop journey
  /// apart from a plain one-way.
  factory MultiCitySearchResult.fromJson(dynamic json, int legCount) {
    final tripInfos =
        _dig(json, ['searchResult', 'tripInfos']) ??
        _dig(json, ['data', 'searchResult', 'tripInfos']) ??
        _get(json, 'tripInfos');

    List<FlightResult> parse(dynamic entry) => asList(
      entry,
    ).map(FlightResult.fromTripJack).where((f) => f.id.isNotEmpty).toList();

    if (tripInfos is! Map) return const MultiCitySearchResult();

    // Per-route buckets keyed "0", "1", … — one per requested leg.
    final numeric = <int, List<FlightResult>>{};
    for (final entry in tripInfos.entries) {
      final index = int.tryParse(asString(entry.key));
      if (index == null) continue;
      numeric[index] = parse(entry.value);
    }
    if (numeric.isNotEmpty) return MultiCitySearchResult(routes: numeric);

    // One combined itinerary covering every leg under a single priceId.
    final combo = parse(_get(tripInfos, 'COMBO'));
    if (combo.isNotEmpty) {
      return MultiCitySearchResult(routes: {0: combo}, isCombo: true);
    }

    // Some responses fall back to the one-way key even for several legs. It
    // still carries the whole journey on one fare, so it behaves like a combo.
    final onward = parse(_get(tripInfos, 'ONWARD'));
    if (onward.isNotEmpty) {
      return MultiCitySearchResult(routes: {0: onward}, isCombo: legCount > 1);
    }

    return const MultiCitySearchResult();
  }
}
