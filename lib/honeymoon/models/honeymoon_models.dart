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
  });

  final String id;
  final String displayName;
  final String city;
  final String country;
  final DestinationKind kind;
  final String searchRegionType;
  final String searchRegionName;

  /// TripJack hotel id, only set when [kind] is [DestinationKind.hotel].
  final String hotelId;

  bool get isHotel => kind == DestinationKind.hotel;

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

    // Images arrive as a list of strings or of {url}/{imageUrl} maps.
    String image = '';
    final images = asList(
      _get(hotel, 'images') ?? _get(json, 'images') ?? _get(hotel, 'gallery'),
    );
    if (images.isNotEmpty) {
      final first = images.first;
      image = first is String
          ? first
          : firstNonEmpty([
              _get(first, 'url'),
              _get(first, 'imageUrl'),
              _get(first, 'src'),
            ]);
    }
    if (image.isEmpty) {
      image = firstNonEmpty([
        _get(hotel, 'heroImage'),
        _get(hotel, 'image'),
        _get(json, 'heroImage'),
      ]);
    }

    // Price lives under a few different option shapes.
    double price = asDouble(
      _get(json, 'price') ??
          _dig(json, ['totalPrice', 'amount']) ??
          _dig(json, ['fare', 'totalFare']),
    );
    if (price == 0) {
      final options = asList(_get(json, 'options') ?? _get(json, 'ops'));
      if (options.isNotEmpty) {
        price = asDouble(
          _get(options.first, 'totalPrice') ??
              _get(options.first, 'tp') ??
              _dig(options.first, ['price', 'total']),
        );
      }
    }

    String optionId = firstNonEmpty([
      _get(json, 'optionId'),
      _get(json, 'oid'),
    ]);
    if (optionId.isEmpty) {
      final options = asList(_get(json, 'options') ?? _get(json, 'ops'));
      if (options.isNotEmpty) {
        optionId = firstNonEmpty([
          _get(options.first, 'id'),
          _get(options.first, 'oid'),
        ]);
      }
    }

    return HotelResult(
      id: id,
      name: firstNonEmpty([
        _get(hotel, 'name'),
        _get(json, 'name'),
        _get(hotel, 'hotelName'),
      ], fallback: 'Hotel'),
      imageUrl: image,
      address: firstNonEmpty([
        _dig(hotel, ['address', 'adr']),
        _dig(hotel, ['address', 'line1']),
        _get(hotel, 'address'),
      ]),
      city: firstNonEmpty([
        _dig(hotel, ['address', 'city', 'name']),
        _dig(hotel, ['address', 'city']),
        _get(hotel, 'cityName'),
      ]),
      starRating: asDouble(_get(hotel, 'rt') ?? _get(hotel, 'starRating')),
      reviewScore: asDouble(
        _dig(hotel, ['reviews', 0, 'rating']) ?? _get(hotel, 'reviewScore'),
      ),
      reviewCount: asInt(
        _dig(hotel, ['reviews', 0, 'count']) ?? _get(hotel, 'reviewCount'),
      ),
      price: price,
      currency: firstNonEmpty([_get(json, 'currency')], fallback: 'INR'),
      facilities: asList(
        _get(hotel, 'facilities') ?? _get(hotel, 'fac'),
      ).map((f) => f is String ? f : asString(_get(f, 'name'))).where((f) => f.isNotEmpty).toList(),
      optionId: optionId,
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
  });

  final List<HotelResult> hotels;
  final String searchId;

  /// Cursor for the next page; empty when there is no more data.
  final String lastHotelId;
  final int totalCount;

  bool get hasMore => lastHotelId.isNotEmpty;

  factory HotelSearchResult.fromJson(dynamic json) {
    // The list has appeared under several keys across TripJack revisions.
    final raw = _get(json, 'hotels') ??
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
      ]),
      totalCount: asInt(
        _get(json, 'totalCount') ?? _dig(json, ['pagination', 'totalCount']),
      ),
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
  });

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
    double price = 0;
    String id = '';
    if (fares.isNotEmpty) {
      final fare = fares.first;
      id = asString(_get(fare, 'id'));
      price = asDouble(_dig(fare, ['fd', 'ADULT', 'fC', 'TF']));
    }

    int totalDuration = 0;
    for (final s in segments) {
      totalDuration += asInt(_get(s, 'duration'));
    }

    return FlightResult(
      id: id,
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
      city: firstNonEmpty([
        _get(json, 'cityName'),
        _get(json, 'city'),
      ]),
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

class InsurancePlan {
  const InsurancePlan({
    required this.id,
    required this.name,
    this.insurer = '',
    this.price = 0,
    this.currency = 'INR',
    this.coverage = const [],
  });

  final String id;
  final String name;
  final String insurer;
  final double price;
  final String currency;
  final List<String> coverage;

  factory InsurancePlan.fromJson(dynamic json) {
    final products = asList(_get(json, 'pi'));
    double price = asDouble(_get(json, 'price') ?? _get(json, 'tp'));
    String id = firstNonEmpty([_get(json, 'id'), _get(json, 'pid')]);
    if (products.isNotEmpty) {
      final p = products.first;
      if (price == 0) {
        price = asDouble(_get(p, 'tp') ?? _dig(p, ['fare', 'total']));
      }
      if (id.isEmpty) id = asString(_get(p, 'pid'));
    }

    return InsurancePlan(
      id: id,
      name: firstNonEmpty([
        _get(json, 'name'),
        _get(json, 'pn'),
        _get(json, 'planName'),
      ], fallback: 'Travel plan'),
      insurer: firstNonEmpty([
        _get(json, 'insurer'),
        _get(json, 'ins'),
        _get(json, 'insurerName'),
      ]),
      price: price,
      currency: firstNonEmpty([_get(json, 'currency')], fallback: 'INR'),
      coverage: asList(_get(json, 'coverage') ?? _get(json, 'benefits'))
          .map((c) => c is String ? c : asString(_get(c, 'name')))
          .where((c) => c.isNotEmpty)
          .toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Cab quote (POST tripjack-cabs/quotes)
// ---------------------------------------------------------------------------

class CabQuote {
  const CabQuote({
    required this.id,
    required this.vehicleName,
    this.category = '',
    this.imageUrl = '',
    this.seats = 0,
    this.price = 0,
    this.currency = 'INR',
  });

  final String id;
  final String vehicleName;
  final String category;
  final String imageUrl;
  final int seats;
  final double price;
  final String currency;

  factory CabQuote.fromJson(dynamic json) {
    return CabQuote(
      id: firstNonEmpty([
        _get(json, 'id'),
        _get(json, 'quoteId'),
        _get(json, 'qid'),
      ]),
      vehicleName: firstNonEmpty([
        _get(json, 'vehicleName'),
        _dig(json, ['vehicle', 'name']),
        _get(json, 'cabType'),
        _get(json, 'name'),
      ], fallback: 'Vehicle'),
      category: firstNonEmpty([
        _get(json, 'category'),
        _dig(json, ['vehicle', 'category']),
        _get(json, 'segment'),
      ]),
      imageUrl: firstNonEmpty([
        _get(json, 'imageUrl'),
        _dig(json, ['vehicle', 'image']),
        _get(json, 'image'),
      ]),
      seats: asInt(
        _get(json, 'seats') ?? _dig(json, ['vehicle', 'seatingCapacity']),
      ),
      price: asDouble(
        _get(json, 'totalFare') ??
            _get(json, 'price') ??
            _dig(json, ['fare', 'totalFare']),
      ),
      currency: firstNonEmpty([_get(json, 'currency')], fallback: 'INR'),
    );
  }
}