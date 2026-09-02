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
  bool get isReturnCoupledFare =>
      fareType.toUpperCase() == 'SPECIAL_RETURN';

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

    int totalDuration = 0;
    for (final s in segments) {
      totalDuration += asInt(_get(s, 'duration'));
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

  bool get isBookable =>
      planId.isNotEmpty && productId.isNotEmpty && price > 0;

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
    return benefits.where((b) => b.isCoverage).map((b) => b.name).take(3).toList();
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
  static List<InsurancePlan> fromSearchResponse(dynamic payload) {
    final raw = _get(payload, 'data') ?? payload;
    final root = _get(raw, 'data') ?? raw;

    final plans = asList(
      _dig(root, ['isr', 'iinfo', 'pli']) ?? _dig(raw, ['isr', 'iinfo', 'pli']),
    );

    final travellers = asList(
      _dig(root, ['isq', 'iti']) ?? _dig(raw, ['isq', 'iti']),
    );
    final count = travellers.isEmpty ? 1 : travellers.length;

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
      partners: asList(_get(product, 'aps'))
          .map((p) => asString(p))
          .where((p) => p.isNotEmpty)
          .toList(),
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
      return (
        fareComponents: _dig(entry, [0, 'ifc']),
        isWholeParty: false,
      );
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
  });

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
        if (net + tax <= 0) continue;

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
            seats: asInt(readKey(group, 'paxCapacity')),
            luggage: asInt(readKey(group, 'luggageCapacity')),
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

    out.sort((a, b) => a.price.compareTo(b.price));
    return out;
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
      List<FlightResult>.from(onward)..sort((a, b) => a.price.compareTo(b.price));

  List<FlightResult> get sortedInbound =>
      List<FlightResult>.from(inbound)..sort((a, b) => a.price.compareTo(b.price));
}
