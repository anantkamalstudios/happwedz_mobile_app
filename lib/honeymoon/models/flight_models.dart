/// Flight-specific models that sit between a search and a booking session:
/// the search itself (so it can be re-run, remembered and modified), the fare
/// rules behind a fare, and the small readers the results cards share.
///
/// Mirrors, in order:
///  * `components/FlightSearchForm.jsx` — the search parameters and the
///    "Recent Searches" entries it saves;
///  * `components/FareRulesPanel.jsx` / `FareCompare.jsx` — the `farerule`
///    response and how its slabs are read;
///  * `FlightSearchResults.jsx` — the per-fare readers (label, refundability,
///    baggage, meal, seats left, next-day arrival) and the stale-fare check.
library;

import 'booking_models.dart' show apiDate;
import 'honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Search query
// ---------------------------------------------------------------------------

/// The web's three trip types, spelled as it stores them.
abstract final class FlightTripKind {
  static const String oneWay = 'oneway';
  static const String round = 'round';
  static const String multiCity = 'multicity';
}

/// Everything a flight search was made with.
///
/// The web keeps this as `searchParams` and hands it to the results page, the
/// date strip, the stale-fare refresh and "Recent Searches" alike. Keeping one
/// object for it here means a re-run search is built the same way as the
/// first one, rather than from a second copy of the form's fields.
class FlightSearchQuery {
  const FlightSearchQuery({
    this.tripType = FlightTripKind.round,
    this.from,
    this.to,
    this.departure,
    this.returnDate,
    this.legs = const [],
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
    this.paxType = 'REGULAR',
    this.preferredAirlines = const [],
    this.directOnly = false,
  });

  final String tripType;
  final FlightLocation? from;
  final FlightLocation? to;
  final DateTime? departure;
  final DateTime? returnDate;

  /// Multi-city hops; empty for one-way and round trips.
  final List<FlightLeg> legs;

  final int adults;
  final int children;
  final int infants;

  /// Supplier spelling — `ECONOMY`, `PREMIUM_ECONOMY`, `BUSINESS`, `FIRST`.
  final String cabinClass;

  /// `REGULAR`, `STUDENT` or `SENIOR_CITIZEN`.
  final String paxType;

  final List<String> preferredAirlines;
  final bool directOnly;

  bool get isRoundTrip => tripType == FlightTripKind.round;
  bool get isMultiCity => tripType == FlightTripKind.multiCity;

  int get travellerCount => adults + children + infants;

  /// Complete enough to be searched again without the form.
  bool get isRunnable {
    if (isMultiCity) return legs.length >= 2;
    if (from == null || to == null || departure == null) return false;
    return !isRoundTrip || returnDate != null;
  }

  /// `from-to-departure-return` — the web's de-duplication key for
  /// "Recent Searches".
  String get recentKey =>
      '${from?.code ?? ''}-${to?.code ?? ''}-'
      '${departure == null ? '' : apiDate(departure!)}-'
      '${returnDate == null ? '' : apiDate(returnDate!)}';

  FlightSearchQuery copyWith({
    String? tripType,
    FlightLocation? from,
    FlightLocation? to,
    DateTime? departure,
    Object? returnDate = _unset,
    List<FlightLeg>? legs,
    int? adults,
    int? children,
    int? infants,
    String? cabinClass,
    String? paxType,
    List<String>? preferredAirlines,
    bool? directOnly,
  }) {
    return FlightSearchQuery(
      tripType: tripType ?? this.tripType,
      from: from ?? this.from,
      to: to ?? this.to,
      departure: departure ?? this.departure,
      returnDate: returnDate == _unset
          ? this.returnDate
          : returnDate as DateTime?,
      legs: legs ?? this.legs,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      infants: infants ?? this.infants,
      cabinClass: cabinClass ?? this.cabinClass,
      paxType: paxType ?? this.paxType,
      preferredAirlines: preferredAirlines ?? this.preferredAirlines,
      directOnly: directOnly ?? this.directOnly,
    );
  }

  /// The shape the web stores under `hw_flightRecentSearches`, plus the
  /// airport names so a restored entry reads the same as the original.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'tripType': tripType,
    'from': from?.code,
    'to': to?.code,
    'fromText': from?.name,
    'toText': to?.name,
    'fromPlace': from?.toJson(),
    'toPlace': to?.toJson(),
    'departureDate': departure == null ? null : apiDate(departure!),
    'returnDate': returnDate == null ? null : apiDate(returnDate!),
    'legs': [
      for (final leg in legs)
        {
          'from': leg.from.toJson(),
          'to': leg.to.toJson(),
          'date': apiDate(leg.date),
        },
    ],
    'adults': adults,
    'children': children,
    'infants': infants,
    'cabinClass': cabinClass,
    'paxType': paxType,
    'preferredAirline': preferredAirlines,
    'directFlight': directOnly,
    'ts': DateTime.now().millisecondsSinceEpoch,
  };

  factory FlightSearchQuery.fromJson(dynamic json) {
    FlightLocation? place(String placeKey, String codeKey, String textKey) {
      final stored = readKey(json, placeKey);
      if (stored is Map) {
        final location = FlightLocation.fromJson(stored);
        if (location.code.isNotEmpty) return location;
      }
      final code = asString(readKey(json, codeKey));
      if (code.isEmpty) return null;
      return FlightLocation(
        code: code,
        name: asString(readKey(json, textKey), fallback: code),
      );
    }

    final legs = <FlightLeg>[];
    for (final raw in asList(readKey(json, 'legs'))) {
      final from = FlightLocation.fromJson(readKey(raw, 'from'));
      final to = FlightLocation.fromJson(readKey(raw, 'to'));
      final date = DateTime.tryParse(asString(readKey(raw, 'date')));
      if (from.code.isEmpty || to.code.isEmpty || date == null) continue;
      legs.add(FlightLeg(from: from, to: to, date: date));
    }

    return FlightSearchQuery(
      tripType: asString(
        readKey(json, 'tripType'),
        fallback: FlightTripKind.oneWay,
      ),
      from: place('fromPlace', 'from', 'fromText'),
      to: place('toPlace', 'to', 'toText'),
      departure: DateTime.tryParse(asString(readKey(json, 'departureDate'))),
      returnDate: DateTime.tryParse(asString(readKey(json, 'returnDate'))),
      legs: legs,
      adults: asInt(readKey(json, 'adults'), fallback: 1),
      children: asInt(readKey(json, 'children')),
      infants: asInt(readKey(json, 'infants')),
      cabinClass: asString(
        readKey(json, 'cabinClass'),
        fallback: 'ECONOMY',
      ).toUpperCase().replaceAll(RegExp(r'\s+'), '_'),
      paxType: asString(readKey(json, 'paxType'), fallback: 'REGULAR'),
      preferredAirlines: [
        for (final code in asList(readKey(json, 'preferredAirline')))
          if (asString(code).isNotEmpty) asString(code),
      ],
      directOnly: readKey(json, 'directFlight') == true,
    );
  }
}

const Object _unset = Object();

// ---------------------------------------------------------------------------
// Fare readers — FlightSearchResults.jsx
// ---------------------------------------------------------------------------

Object? _adult(dynamic fare) => digPath(fare, ['fd', 'ADULT']);

/// "Published", "NDC Value", "SME", "Flexi Plus" — the web's `getFareLabel`.
///
/// TripJack ships dozens of `fareIdentifier`s. NDC fares keep their marker so
/// "NDC_Value" and the separate "VALUE" fare do not both read "Value", and
/// short all-caps acronyms are left alone.
String fareDisplayLabel(String? fareIdentifier) {
  final id = fareIdentifier ?? '';
  if (id.isEmpty) return 'Published';
  String titleCase(String s) => s
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
  if (RegExp(r'^NDC_', caseSensitive: false).hasMatch(id)) {
    return 'NDC ${titleCase(id.replaceFirst(RegExp(r'^NDC_', caseSensitive: false), ''))}';
  }
  if (RegExp(r'^[A-Z]{2,4}$').hasMatch(id)) return id;
  return titleCase(id);
}

/// `fd.ADULT.rT === 1` is the only refundable marker the web trusts.
bool fareIsRefundable(dynamic fare) => asInt(readKey(_adult(fare), 'rT')) == 1;

/// Cabin as the supplier prints it — "ECONOMY", "PREMIUM_ECONOMY".
String fareCabin(dynamic fare) =>
    asString(readKey(_adult(fare), 'cc'), fallback: 'Economy');

/// `mI` — a meal is included with this fare.
bool fareMealIncluded(dynamic fare) => readKey(_adult(fare), 'mI') == true;

/// Check-in allowance (`bI.iB`) for [paxType], e.g. "15 Kilograms".
String fareCheckinBaggage(dynamic fare, [String paxType = 'ADULT']) =>
    asString(digPath(fare, ['fd', paxType, 'bI', 'iB']));

/// Cabin allowance (`bI.cB`) for [paxType], e.g. "7 Kg".
String fareCabinBaggage(dynamic fare, [String paxType = 'ADULT']) =>
    asString(digPath(fare, ['fd', paxType, 'bI', 'cB']));

/// Seats left at this fare (`sR`), or null when the supplier did not say.
int? fareSeatsLeft(dynamic fare) {
  final value = readKey(_adult(fare), 'sR');
  return value == null ? null : asInt(value);
}

/// "Economy, Free Meal" — everything the web prints before the refundability.
String farePrefixText(dynamic fare) {
  final cabin = fareCabin(fare)
      .replaceAll('_', ' ')
      .toLowerCase()
      .replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
  return [cabin, if (fareMealIncluded(fare)) 'Free Meal'].join(', ');
}

/// How many calendar days after departure the journey lands — the web's
/// `getArrivalDayOffset`.
///
/// Only meaningful for one continuous journey: a combined multi-city itinerary
/// can hold legs weeks apart, so any gap over a day between segments means a
/// stopover rather than a layover, and nothing is reported.
int arrivalDayOffset(Map<String, dynamic> trip) {
  final segs = asList(readKey(trip, 'sI'));
  if (segs.isEmpty || !segs.any((s) => readKey(s, 'iand') == true)) return 0;
  for (var i = 1; i < segs.length; i++) {
    final dep = DateTime.tryParse(asString(readKey(segs[i], 'dt')));
    final prevArr = DateTime.tryParse(asString(readKey(segs[i - 1], 'at')));
    if (dep == null || prevArr == null) return 0;
    if (dep.difference(prevArr).inMilliseconds > 86400000) return 0;
  }
  final first = DateTime.tryParse(asString(readKey(segs.first, 'dt')));
  final last = DateTime.tryParse(asString(readKey(segs.last, 'at')));
  if (first == null || last == null) return 0;
  final diff = DateTime(
    last.year,
    last.month,
    last.day,
  ).difference(DateTime(first.year, first.month, first.day)).inDays;
  return diff > 0 ? diff : 0;
}

/// Whether a failed review means the whole result set is out of date.
///
/// TripJack answers a review against a fare that has gone with errCode 1000,
/// "Requested flight is no longer available". The web treats that — or any
/// message about availability, a changed price or expiry — as a signal to
/// re-run the search rather than leave the traveller on a dead error.
bool isStaleFarePayload(dynamic payload) {
  final errors = [
    ...asList(readKey(payload, 'errors')),
    ...asList(digPath(payload, ['status', 'errors'])),
  ];
  if (errors.any((e) => asString(readKey(e, 'errCode')) == '1000')) {
    return true;
  }
  final text = [
    asString(digPath(payload, ['status', 'message'])),
    asString(readKey(payload, 'message')),
    for (final e in errors) asString(readKey(e, 'message')),
  ].join(' ');
  return RegExp(
    r'no longer available|not available|price.*chang|expired',
    caseSensitive: false,
  ).hasMatch(text);
}

/// TripJack errCode 1019 — "Minimum time between two consecutive trips does
/// not satisfy the criteria": the legs chosen sit too close together (the
/// next one leaves too soon after the previous one lands). The supplier does
/// not publish the minimum, so the app only learns it from this answer.
bool isTripGapError(dynamic payload) {
  final errors = [
    ...asList(readKey(payload, 'errors')),
    ...asList(digPath(payload, ['status', 'errors'])),
  ];
  if (errors.any((e) => asString(readKey(e, 'errCode')) == '1019')) {
    return true;
  }
  final text = [
    for (final e in errors) asString(readKey(e, 'message')),
  ].join(' ');
  return RegExp(
    'minimum time between two consecutive trips',
    caseSensitive: false,
  ).hasMatch(text);
}

/// Why [next] cannot follow [previous], or null when it can.
///
/// Only flights that leave the same airport the previous one lands at are
/// compared: segment times are local to their airport, so across two cities
/// the clock readings are not comparable. A departure before the landing is
/// certain to be refused; anything later is left to the supplier, which
/// answers 1019 when the gap is still too short.
String? tripOverlapReason(FlightResult previous, FlightResult next) {
  final landed = previous.arrival;
  final leaves = next.departure;
  if (landed == null || leaves == null) return null;
  if (previous.toCode.isEmpty || previous.toCode != next.fromCode) return null;
  if (leaves.isAfter(landed)) return null;
  final hh = landed.hour.toString().padLeft(2, '0');
  final mm = landed.minute.toString().padLeft(2, '0');
  return 'Leaves before your previous flight lands (${previous.toCode} '
      '$hh:$mm, ${landed.day}/${landed.month})';
}

// ---------------------------------------------------------------------------
// Fare rules — POST /tj/fms/farerule
// ---------------------------------------------------------------------------

/// The four fee types the web's rules panel shows, in its order.
const List<({String key, String label, String? note})> kFareRuleTypes = [
  (key: 'CANCELLATION', label: 'Cancellation Fee', note: null),
  (key: 'DATECHANGE', label: 'Date Change Fee', note: null),
  (key: 'NO_SHOW', label: 'No Show Fee', note: '(Post departure)'),
  (key: 'SEAT_CHARGEABLE', label: 'Seat Chargeable Fee', note: null),
];

/// The notes the web prints under every fare-rule table.
const List<String> kFareRuleNotes = [
  'The airline fee is indicative, which will depend upon the time of '
      'cancellation / re-issue as per the airline fare rules.',
  'Mentioned fees are Per Pax Per Sector',
  'Apart from airline charges, GST + RAF + applicable charges if any, will '
      'be charged.',
  'For more clarity, Please check Detailed Rules',
];

/// Splits a `policyInfo` string on its `__nls__` separators and strips the
/// other `__x__` markers.
List<String> farePolicyLines(String text) => text
    .split(RegExp('__nls__', caseSensitive: false))
    .map(
      (line) => line
          .replaceAll(RegExp(r'__[a-z]+__', caseSensitive: false), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim(),
    )
    .where((line) => line.isNotEmpty)
    .toList();

String _cleanPolicy(String text) => text
    .replaceAll(RegExp(r'__[a-z]+__', caseSensitive: false), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// `4 hrs` / `365 days` — `st`/`et` are hours before departure.
String fareRuleHours(num hours) =>
    hours >= 24 ? '${(hours / 24).round()} days' : '${hours.round()} hrs';

/// One fee band of one fee type.
class FareRuleSlab {
  const FareRuleSlab({
    this.startHours = 0,
    this.endHours = 0,
    this.amount,
    this.additionalFee,
    this.policyInfo = '',
  });

  final num startHours;
  final num endHours;
  final double? amount;
  final double? additionalFee;
  final String policyInfo;

  /// "4 hrs to 365 days".
  String get timeFrame =>
      '${fareRuleHours(startHours)} to ${fareRuleHours(endHours)}';

  List<String> get policyLines => farePolicyLines(policyInfo);

  String get cleanPolicy => _cleanPolicy(policyInfo);

  bool get hasFee => amount != null || additionalFee != null;

  factory FareRuleSlab.fromJson(dynamic json) {
    double? money(String key) {
      final value = readKey(json, key);
      return value == null ? null : asDouble(value);
    }

    return FareRuleSlab(
      startHours: asDouble(readKey(json, 'st')),
      endHours: asDouble(readKey(json, 'et')),
      amount: money('amount'),
      additionalFee: money('additionalFee'),
      policyInfo: asString(readKey(json, 'policyInfo')),
    );
  }
}

/// The rules for one route key ("BOM-DEL").
class FareRuleRoute {
  const FareRuleRoute({
    required this.key,
    this.slabs = const {},
    this.miscInfo = const [],
  });

  final String key;

  /// Fee type (`CANCELLATION`, `DATECHANGE`, …) → its bands.
  final Map<String, List<FareRuleSlab>> slabs;

  /// Free-text rules, returned instead of (or as well as) the bands for some
  /// airlines and flow types.
  final List<String> miscInfo;

  List<FareRuleSlab> slabsOf(String type) => slabs[type] ?? const [];

  List<String> get miscLines => [
    for (final line in miscInfo) ...farePolicyLines(line),
  ];
}

/// A parsed `farerule` response.
class FareRuleSet {
  const FareRuleSet({this.routes = const []});

  final List<FareRuleRoute> routes;

  bool get isEmpty => routes.isEmpty;

  /// Every route's bands for one fee type, flattened — fees are per pax per
  /// sector, which is how the web's compare drawer reads them.
  List<FareRuleSlab> slabsOf(String type) => [
    for (final route in routes) ...route.slabsOf(type),
  ];

  /// "4 hrs to 365 days" across every band of [type], or empty.
  String windowOf(String type) {
    final slabs = slabsOf(type);
    if (slabs.isEmpty) return '';
    final start = slabs
        .map((s) => s.startHours)
        .reduce((a, b) => a < b ? a : b);
    final end = slabs.map((s) => s.endHours).reduce((a, b) => a > b ? a : b);
    return '${fareRuleHours(start)} to ${fareRuleHours(end)}';
  }

  /// The free-text rules matching [keyword] (a regex), joined — the web's
  /// fallback when a fare has no structured bands for a fee type.
  String miscMatching(String keyword) {
    final pattern = RegExp(keyword, caseSensitive: false);
    return [
      for (final route in routes)
        for (final line in route.miscInfo)
          if (_cleanPolicy(line).isNotEmpty &&
              pattern.hasMatch(_cleanPolicy(line)))
            _cleanPolicy(line),
    ].join(' ');
  }

  /// The API returns `fareRule`; older notes used `farerule`. Both are read,
  /// at the root or under `data`.
  factory FareRuleSet.fromJson(dynamic json) {
    final rules =
        readKey(json, 'fareRule') ??
        readKey(json, 'farerule') ??
        digPath(json, ['data', 'fareRule']) ??
        digPath(json, ['data', 'farerule']);
    if (rules is! Map) return const FareRuleSet();

    final routes = <FareRuleRoute>[];
    for (final entry in rules.entries) {
      final tfr = readKey(entry.value, 'tfr');
      final slabs = <String, List<FareRuleSlab>>{};
      if (tfr is Map) {
        for (final type in tfr.entries) {
          final raw = type.value;
          final list = raw is List ? raw : (raw == null ? const [] : [raw]);
          slabs[asString(type.key)] = list.map(FareRuleSlab.fromJson).toList();
        }
      }
      routes.add(
        FareRuleRoute(
          key: asString(entry.key),
          slabs: slabs,
          miscInfo: [
            for (final line in asList(readKey(entry.value, 'miscInfo')))
              asString(line),
          ],
        ),
      );
    }
    return FareRuleSet(routes: routes);
  }
}

/// A leg as the booking session priced it: its `tripInfos` entry and the
/// fare on it.
typedef PricedLeg = ({Map<String, dynamic> trip, dynamic fare});

// ---------------------------------------------------------------------------
// After booking — booking-details, booking-record, cancellation, status
// ---------------------------------------------------------------------------

/// Flight booking status as the web's dashboard shows it
/// (`utils/bookingStatus.js`, source `flight`): one vocabulary for
/// `my-bookings` rows (`on_hold`, `confirmed`) and TripJack's order status
/// (`ON_HOLD`, `SUCCESS`).
enum FlightStatusKey { confirmed, hold, pending, cancelled, failed, unknown }

typedef FlightStatus = ({FlightStatusKey key, String label, String raw});

FlightStatus flightStatusOf(String raw) {
  final value = raw.trim().toUpperCase();
  final key = switch (value) {
    'CONFIRMED' || 'SUCCESS' || 'TICKETED' => FlightStatusKey.confirmed,
    'ON_HOLD' || 'HOLD' => FlightStatusKey.hold,
    'PENDING' || 'IN_PROGRESS' || '' => FlightStatusKey.pending,
    'CANCELLED' || 'CANCELED' => FlightStatusKey.cancelled,
    'FAILED' || 'ABORTED' => FlightStatusKey.failed,
    _ => FlightStatusKey.unknown,
  };
  final label = value == 'ON_HOLD'
      ? 'Seat Held'
      : switch (key) {
          FlightStatusKey.confirmed => 'Confirmed',
          FlightStatusKey.hold => 'On Hold',
          FlightStatusKey.pending => 'Pending',
          FlightStatusKey.cancelled => 'Cancelled',
          FlightStatusKey.failed => 'Failed',
          FlightStatusKey.unknown =>
            value
                .toLowerCase()
                .split(RegExp(r'[\s_-]+'))
                .where((w) => w.isNotEmpty)
                .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
                .join(' '),
        };
  return (key: key, label: label, raw: value);
}

/// The filter pills the web's flight panel always shows, in order.
const List<FlightStatusKey> kFlightStatusFilters = [
  FlightStatusKey.confirmed,
  FlightStatusKey.pending,
  FlightStatusKey.hold,
  FlightStatusKey.cancelled,
];

/// `{route: code}` maps (`pnrDetails`, `ticketNumberDetails`, `gdsPnrs`).
Map<String, String> _stringMap(dynamic value) {
  if (value is! Map) return const {};
  return {
    for (final e in value.entries)
      if (asString(e.value).isNotEmpty) asString(e.key): asString(e.value),
  };
}

/// One traveller on a booked itinerary (`itemInfos.AIR.travellerInfos[]`).
class BookedTraveller {
  const BookedTraveller(this.raw);

  final Map<String, dynamic> raw;

  String get title => asString(readKey(raw, 'ti'));
  String get firstName => asString(readKey(raw, 'fN'));
  String get lastName => asString(readKey(raw, 'lN'));
  String get paxType => asString(readKey(raw, 'pt'), fallback: 'ADULT');
  String get dob => asString(readKey(raw, 'dob'));
  String get passport => asString(readKey(raw, 'pNum'));
  String get documentId => asString(readKey(raw, 'di'));
  String get pan => asString(readKey(raw, 'pan'));
  String get frequentFlyer => asString(readKey(raw, 'fFNumber'));

  /// Route → airline PNR, e.g. `{"BOM-DEL": "Y8CGHW"}`.
  Map<String, String> get pnrs => _stringMap(readKey(raw, 'pnrDetails'));
  Map<String, String> get ticketNumbers =>
      _stringMap(readKey(raw, 'ticketNumberDetails'));
  Map<String, String> get gdsPnrs => _stringMap(readKey(raw, 'gdsPnrs'));

  String get initial => paxType.isEmpty ? 'A' : paxType[0];

  String get displayName =>
      '$title $firstName $lastName'.trim().replaceAll(RegExp(r'\s+'), ' ');
}

/// A `POST /tj/oms/booking-details` answer — the web's `adaptBookingDetails`.
///
/// Booking-details leaves `totalPriceList` empty and hangs a flat `fd` off
/// each traveller instead, so the fare is rebuilt per passenger type from
/// the travellers, one fare per type.
class FlightBookingDetails {
  const FlightBookingDetails(this.raw);

  final Map<String, dynamic> raw;

  Object? get _air => digPath(raw, ['itemInfos', 'AIR']);

  bool get hasItinerary => _air != null;

  Map<String, dynamic> get order => asJsonMap(readKey(raw, 'order'));

  /// `tripInfos` comes back as a list here and as an ONWARD/RETURN map
  /// elsewhere.
  List<Map<String, dynamic>> get trips {
    final ti = readKey(_air, 'tripInfos');
    if (ti is List) return ti.map(asJsonMap).toList();
    if (ti is Map) {
      return [
        for (final v in ti.values)
          for (final t in asList(v)) asJsonMap(t),
      ];
    }
    return const [];
  }

  List<BookedTraveller> get travellers => [
    for (final t in asList(readKey(_air, 'travellerInfos')))
      BookedTraveller(asJsonMap(t)),
  ];

  /// `{fd: {ADULT: …, CHILD: …}}` rebuilt from the travellers.
  Map<String, dynamic>? get fare {
    final fd = <String, dynamic>{};
    for (final t in travellers) {
      final type = t.paxType;
      final own = readKey(t.raw, 'fd');
      if (!fd.containsKey(type) && own != null) fd[type] = own;
    }
    return fd.isEmpty ? null : {'fd': fd};
  }

  String get status => firstNonEmpty([
    readKey(order, 'status'),
    digPath(raw, ['status', 'status']),
  ]).toUpperCase();

  String get bookingId => asString(readKey(order, 'bookingId'));
  bool get isOnHold => status == 'ON_HOLD';
  DateTime? get createdOn =>
      DateTime.tryParse(asString(readKey(order, 'createdOn')));
  double get amount => asDouble(readKey(order, 'amount'));
  String get orderNote => asString(readKey(order, 'orderNote'));

  List<String> get emails => [
    for (final e in asList(digPath(order, ['deliveryInfo', 'emails'])))
      if (asString(e).isNotEmpty) asString(e),
  ];
  List<String> get contacts => [
    for (final c in asList(digPath(order, ['deliveryInfo', 'contacts'])))
      if (asString(c).isNotEmpty) asString(c),
  ];

  /// `totalPriceInfo.totalFareDetail.fC` (or its short spelling `fc`).
  Map<String, dynamic> get fareComponents {
    final tpi =
        readKey(_air, 'totalPriceInfo') ?? readKey(raw, 'totalPriceInfo');
    return asJsonMap(
      readKey(tpi, 'fc') ?? digPath(tpi, ['totalFareDetail', 'fC']),
    );
  }

  /// TripJack's flex fee (`afC.TAF.FTC`).
  double get flexFee {
    final tpi =
        readKey(_air, 'totalPriceInfo') ?? readKey(raw, 'totalPriceInfo');
    final afc = readKey(tpi, 'afc') ?? digPath(tpi, ['totalFareDetail', 'afC']);
    return asDouble(digPath(afc, ['TAF', 'FTC']) ?? readKey(afc, 'FTC'));
  }

  /// The fare family, from the first trip.
  String get fareIdentifier => asString(
    digPath(trips.firstOrNull, ['totalPriceList', 0, 'fareIdentifier']),
  );

  /// True once the airline has issued a PNR for at least one traveller.
  static bool hasPnrs(List<BookedTraveller> travellers) =>
      travellers.any((t) => t.pnrs.isNotEmpty);

  /// A booking sits at PENDING until the airline answers with a PNR; that is
  /// the signal to keep polling on (`isAwaitingPnr`).
  bool get isAwaitingPnr {
    if (!hasItinerary) return false;
    if (status == 'PENDING') return true;
    return !hasPnrs(travellers);
  }
}

/// `GET /tj/booking-record/:orderId` — our own record: booking date, the
/// Razorpay payment, the contact, and any amendment raised.
class FlightBookingRecord {
  const FlightBookingRecord(this.raw);

  final Map<String, dynamic> raw;

  bool get isUsable {
    final s = readKey(raw, 'status');
    return s == true || readKey(raw, 'booking') != null;
  }

  Map<String, dynamic> get booking => asJsonMap(readKey(raw, 'booking'));
  Map<String, dynamic>? get payment {
    final p = readKey(raw, 'payment');
    return p is Map ? asJsonMap(p) : null;
  }

  Map<String, dynamic> get contact => asJsonMap(readKey(raw, 'contact'));
  List<Map<String, dynamic>> get passengers =>
      asList(readKey(raw, 'passengers')).map(asJsonMap).toList();

  String get amendmentId => asString(readKey(raw, 'amendment_id'));
  String get amendmentStatus => asString(readKey(raw, 'amendment_status'));

  DateTime? get bookedAt =>
      DateTime.tryParse(asString(readKey(booking, 'booked_at')));
  String get bookingStatus => asString(readKey(booking, 'booking_status'));
  double get price => asDouble(readKey(booking, 'price'));
}

/// `POST /tj/oms/cancel-charges` — a refund preview; cancels nothing.
class FlightCancelQuote {
  const FlightCancelQuote(this.raw);

  final Map<String, dynamic> raw;

  /// `false` means the supplier has no preview for this booking (e.g. error
  /// 2563) — cancelling still works, only without a refund figure.
  bool get available => readKey(raw, 'available') != false;
  String get message => asString(readKey(raw, 'message'));
  double? get amendmentCharges => _money('amendment_charges');
  double? get refundAmount => _money('refund_amount');
  double? get totalFare => _money('total_fare');

  /// 2512 — a previous amendment is still in progress; a hard stop.
  bool get amendmentInProgress =>
      asString(readKey(raw, 'err_code')) == '2512' ||
      message.toLowerCase().contains('amendment in progress');

  double? _money(String key) {
    final v = readKey(raw, key);
    return v == null ? null : asDouble(v);
  }
}

/// `POST /tj/oms/amendment/poll` — where a cancellation request stands.
class FlightAmendment {
  const FlightAmendment(this.raw);

  final Map<String, dynamic> raw;

  String get amendmentId => asString(readKey(raw, 'amendmentId'));
  String get status => asString(readKey(raw, 'amendmentStatus'));
  String get remarks => asString(readKey(raw, 'remarks'));
  double? get charges => _money('amendmentCharges');
  double? get refundableAmount => _money('refundableAmount');
  double? get totalFare => _money('totalFare');

  double? _money(String key) {
    final v = readKey(raw, key);
    return v == null ? null : asDouble(v);
  }
}

/// The web's cancellation reasons, grouped as its modal shows them. The id is
/// what is sent as `remarks`.
const List<({String group, List<({String id, String desc})> items})>
kFlightCancelReasons = [
  (
    group: 'Normal Cancellations',
    items: [
      (
        id: 'Travel Plan is Cancelled (Normal Cancellation)',
        desc:
            'Change in travel plans. Airline charges will apply as per standard '
            'airline cancellation policy.',
      ),
      (
        id: 'Airline confirmed, refund already processed (offline)',
        desc:
            'You have already cancelled your booking offline by directly '
            'contacting airline - Tripjack to credit the refund.',
      ),
    ],
  ),
  (
    group: 'Full Refund Cancellations',
    items: [
      (
        id: 'Flight cancelled by the airline, process full refund',
        desc:
            'Airline cancelled the flight, eligible for full refund as per '
            'airline policy.',
      ),
      (
        id: 'Airline changed the flight timing, process full refund',
        desc:
            'Eligible for full refund as per Airline Policy. (e.g., 10AM → '
            '6PM).',
      ),
      (id: 'Process full refund under DGCA airline policy', desc: ''),
      (
        id: 'Airline confirmed, full refund already processed',
        desc: 'Airline has confirmed and processed full refund to Tripjack.',
      ),
    ],
  ),
  (
    group: 'Void Booking',
    items: [(id: 'Void this booking, process full refund', desc: '')],
  ),
  (
    group: 'No Show Booking',
    items: [
      (
        id: 'Passenger(s) was no-show for the flight',
        desc:
            "Raise amendment after 24 hours of the flight's departure time. "
            'Requests made earlier may not be processed.',
      ),
    ],
  ),
  (
    group: 'Other Reason',
    items: [
      (
        id: 'Passenger is medically unfit for travel',
        desc:
            'Cancel due to illness or medical emergency, attach medical '
            'proof/Death Certificate. (As per airline approval).',
      ),
      (
        id: 'Unable to travel due to personal loss or bereavement',
        desc:
            'Family bereavement or serious personal emergency; supporting '
            'proof required.',
      ),
      (
        id: 'Refund under airline empowerment policy',
        desc:
            'Airline has approved refund beyond standard rules. Dependent on '
            'Airline Policy.',
      ),
    ],
  ),
];

/// The static guidance printed under every booking (`IMPORTANT_INFO`).
const List<String> kFlightImportantInfo = [
  'You should carry a print-out of your booking and present for check-in.',
  'Date & Time is calculated based on the local time of city/destination.',
  'Use the Reference Number for all Correspondence with us.',
  'Use the Airline PNR for all Correspondence directly with the Airline',
  'For departure terminal please check with airline first.',
  'Please CheckIn atleast 2 hours prior to the departure for domestic flight '
      'and 3 hours prior to the departure of international flight.',
  'For rescheduling/cancellation within 4 hours of departure time contact the '
      'airline directly',
];

/// Conditions of carriage, only for carriers we hold a real link for
/// (`CARRIER_TERMS`).
const Map<String, String> kCarrierTerms = {
  'QP': 'https://www.akasaair.com/quick-links/conditions-of-carriage',
  '6E': 'https://www.goindigo.in/information/conditions-of-carriage.html',
  'AI': 'https://www.airindia.com/in/en/legal/conditions-of-carriage.html',
  'SG': 'https://www.spicejet.com/ConditionsOfCarriage.aspx',
  'UK': 'https://www.airvistara.com/in/en/legal/conditions-of-carriage',
};

/// The agency block printed on the ticket (`TicketDocument.jsx` `AGENCY`).
const ({String name, String email, String phone, String address})
kTicketAgency = (
  name: 'Happy Wedz',
  email: 'support@happywedz.com',
  phone: '7770005377',
  address:
      'Happy Wedz Head Office, In premises of Nahata Lawns & Banquets, '
      'Wadgaon Budruk, Pune, Maharashtra 411041 India',
);

const List<String> kDangerousGoods = [
  'Lighters',
  'Flammable Liquids',
  'Toxic',
  'Bleach',
  'Explosives',
  'Infectious Substances',
  'Pepper Spray',
  'RadioActive Materials',
  'Flammable Gas',
  'Corrosive',
];

const List<String> kHandBaggageOnly = ['Power Banks', 'Lithium Batteries'];
