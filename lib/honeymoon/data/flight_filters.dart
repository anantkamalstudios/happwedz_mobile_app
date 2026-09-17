/// Facet derivation and filtering for TripJack flight results.
///
/// A direct port of the web client's `src/utils/flightFilters.js`, so the app
/// narrows a result set by exactly the same rules the website does. Everything
/// works off the raw `tripInfos` entry each [FlightResult] keeps in `raw` — no
/// extra API call is needed to populate the filter sheet.
///
/// Two of these filters are fare-level rather than trip-level: a single flight
/// routinely carries both Standard and NDC fares, and baggage allowance varies
/// per fare family. Those narrow a trip's `totalPriceList` and only drop the
/// trip when nothing survives.
///
/// Airport and terminal facets are keyed `DEP|CODE` / `ARR|CODE|Terminal 2` so
/// the sheet can group them by direction the way the portal does, and so a
/// chosen departure terminal never rejects a trip on its arrival terminal.
///
/// One deliberate difference from the web: the website lists separate
/// `departure_return_time` / `arrival_return_time` keys because it renders both
/// legs side by side. The app picks the outbound and the return in two steps,
/// so a single time selection always applies to the leg currently on screen.
library;

import '../models/honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const String kDep = 'DEP';
const String kArr = 'ARR';

/// The four departure/arrival bands the portal offers.
const List<String> kTimeSlots = ['00-06', '06-12', '12-18', '18-24'];

const Map<String, String> kTimeSlotLabels = {
  '00-06': 'Before 6 AM',
  '06-12': '6 AM - 12 PM',
  '12-18': '12 PM - 6 PM',
  '18-24': 'After 6 PM',
};

const List<({String value, String label})> kFareTypes = [
  (value: 'STANDARD', label: 'Standard'),
  (value: 'NDC', label: 'NDC'),
];

const List<({String value, String label})> kCancellationTypes = [
  (value: 'REFUNDABLE', label: 'Refundable'),
  (value: 'NON_REFUNDABLE', label: 'Non-Refundable'),
];

/// NDC fare families are prefixed `NDC_` (e.g. `NDC_Value`).
bool isNdcFare(String? fareIdentifier) =>
    RegExp(r'^NDC_', caseSensitive: false).hasMatch(fareIdentifier ?? '');

/// Airline logo, served from TripJack's own CDN — the same source the portal
/// uses, so it covers every carrier their search can return.
String airlineLogoUrl(String code) =>
    'https://static.tripjack.com/img/airlineLogo/v1/${code.toUpperCase()}.png';

// ---------------------------------------------------------------------------
// Passenger counts
// ---------------------------------------------------------------------------

/// Pax counts in the shape the fare helpers expect.
class PaxCounts {
  const PaxCounts({this.adults = 1, this.children = 0, this.infants = 0});

  final int adults;
  final int children;
  final int infants;

  static const PaxCounts singleAdult = PaxCounts();

  /// Keyed the way TripJack's `fd` block is.
  Map<String, int> get asMap => {
    'ADULT': adults,
    'CHILD': children,
    'INFANT': infants,
  };
}

// ---------------------------------------------------------------------------
// Trip accessors
// ---------------------------------------------------------------------------

List<dynamic> _segs(Map<String, dynamic> trip) => asList(readKey(trip, 'sI'));

dynamic _firstSeg(Map<String, dynamic> trip) {
  final s = _segs(trip);
  return s.isEmpty ? null : s.first;
}

dynamic _lastSeg(Map<String, dynamic> trip) {
  final s = _segs(trip);
  return s.isEmpty ? null : s.last;
}

List<dynamic> _fares(Map<String, dynamic> trip) =>
    asList(readKey(trip, 'totalPriceList'));

/// `rT == 1` marks a refundable fare.
String fareCancellationType(dynamic fare) =>
    asInt(readKey(readKey(readKey(fare, 'fd'), 'ADULT'), 'rT')) == 1
    ? 'REFUNDABLE'
    : 'NON_REFUNDABLE';

double _amountFor(dynamic fare, String paxType) {
  final fc = readKey(readKey(readKey(fare, 'fd'), paxType), 'fC');
  final tf = readKey(fc, 'TF');
  if (tf != null) return asDouble(tf);
  final nf = readKey(fc, 'NF');
  if (nf != null) return asDouble(nf);
  return double.nan;
}

/// One adult's share of a fare — the raw per-passenger amount TripJack quotes.
double _adultFarePrice(dynamic fare) {
  final v = _amountFor(fare, 'ADULT');
  return v.isNaN ? 0 : v;
}

/// What this fare costs for the whole party.
///
/// `fd` is keyed by passenger type and every amount is per passenger, so a fare
/// read straight off `fd.ADULT` prices the trip for one adult no matter who is
/// actually travelling. A type missing from the fare block falls back to the
/// adult amount, exactly as the web helper does.
double farePrice(dynamic fare, [PaxCounts pax = PaxCounts.singleAdult]) {
  var total = 0.0;
  pax.asMap.forEach((type, count) {
    if (count <= 0) return;
    final amount = _amountFor(fare, type);
    total += (amount.isNaN ? _adultFarePrice(fare) : amount) * count;
  });
  return total;
}

String _fareCheckinBaggage(dynamic fare) => asString(
  readKey(readKey(readKey(readKey(fare, 'fd'), 'ADULT'), 'bI'), 'iB'),
);

/// "0 Kg" / "0 Piece" means the fare carries no checked bag.
bool fareHasCheckinBaggage(dynamic fare) {
  final allowance = _fareCheckinBaggage(fare).trim();
  if (allowance.isEmpty) return false;
  return !RegExp(
    r'^0\s*(kg|kilogram|piece)',
    caseSensitive: false,
  ).hasMatch(allowance);
}

/// Cheapest fare on a trip, used for price filtering and "from" labels.
double tripBestPrice(
  Map<String, dynamic> trip, [
  PaxCounts pax = PaxCounts.singleAdult,
]) {
  final prices = _fares(
    trip,
  ).map((f) => farePrice(f, pax)).where((n) => n > 0).toList();
  if (prices.isEmpty) return 0;
  return prices.reduce((a, b) => a < b ? a : b);
}

/// Total journey time including connections, in minutes.
int tripDuration(Map<String, dynamic> trip) => _segs(trip).fold<int>(
  0,
  (n, s) => n + asInt(readKey(s, 'duration')) + asInt(readKey(s, 'cT')),
);

/// Longest single connection on the trip, in minutes.
int tripMaxLayover(Map<String, dynamic> trip) {
  final segs = _segs(trip);
  if (segs.length < 2) return 0;
  final layovers = segs
      .sublist(0, segs.length - 1)
      .map((s) => asInt(readKey(s, 'cT')))
      .toList();
  return layovers.reduce((a, b) => a > b ? a : b);
}

int tripStops(Map<String, dynamic> trip) {
  final n = _segs(trip).length;
  return n <= 1 ? 0 : n - 1;
}

/// The Stops rail caps at "3+", so anything above 3 folds into that bucket.
int stopsBucket(Map<String, dynamic> trip) {
  final s = tripStops(trip);
  return s > 3 ? 3 : s;
}

String stopLabel(int v) =>
    v == 0 ? 'Non-stop' : (v >= 3 ? '3+ Stops' : '$v Stop');

/// Origin and final destination — this is where nearby airports show up.
List<String> tripEndpointAirports(Map<String, dynamic> trip) => {
  asString(readKey(readKey(_firstSeg(trip), 'da'), 'code')),
  asString(readKey(readKey(_lastSeg(trip), 'aa'), 'code')),
}.where((c) => c.isNotEmpty).toList();

List<String> tripLayoverAirports(Map<String, dynamic> trip) {
  final segs = _segs(trip);
  if (segs.length < 2) return const [];
  return segs
      .sublist(0, segs.length - 1)
      .map((s) => asString(readKey(readKey(s, 'aa'), 'code')))
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();
}

String? _tripAirlineCode(Map<String, dynamic> trip) {
  final code = asString(
    readKey(readKey(readKey(_firstSeg(trip), 'fD'), 'aI'), 'code'),
  );
  return code.isEmpty ? null : code;
}

/// `DEP|BOM` / `ARR|PNQ` — direction-qualified so groups can't cross-match.
String airportKey(String direction, String code) => '$direction|$code';

/// `DEP|BOM|Terminal 2`
String terminalKey(String direction, String code, String terminal) =>
    '$direction|$code|$terminal';

({String direction, String code, String terminal}) parseFacetKey(String key) {
  final parts = key.split('|');
  return (
    direction: parts.isNotEmpty ? parts[0] : '',
    code: parts.length > 1 ? parts[1] : '',
    terminal: parts.length > 2 ? parts[2] : '',
  );
}

// ---------------------------------------------------------------------------
// Time helpers
// ---------------------------------------------------------------------------

int? _minutesOfDay(dynamic value) {
  final parsed = DateTime.tryParse(asString(value));
  if (parsed == null) return null;
  return parsed.hour * 60 + parsed.minute;
}

int? hhmmToMinutes(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  if (h == null || m == null) return null;
  return h * 60 + m;
}

String slotForHour(int hour) {
  if (hour < 6) return '00-06';
  if (hour < 12) return '06-12';
  if (hour < 18) return '12-18';
  return '18-24';
}

bool _matchesSlots(dynamic dateValue, Set<String> slots) {
  if (slots.isEmpty) return true;
  final mins = _minutesOfDay(dateValue);
  if (mins == null) return true;
  return slots.contains(slotForHour(mins ~/ 60));
}

/// Inclusive window; a window that wraps past midnight spans it.
bool _matchesWindow(dynamic dateValue, String? from, String? to) {
  final start = hhmmToMinutes(from);
  final end = hhmmToMinutes(to);
  if (start == null && end == null) return true;
  final mins = _minutesOfDay(dateValue);
  if (mins == null) return true;
  if (start != null && end != null) {
    return start <= end
        ? mins >= start && mins <= end
        : mins >= start || mins <= end;
  }
  if (start != null) return mins >= start;
  return mins <= end!;
}

/// Normalise "6E-123", "6e 123" and "123" to a comparable form.
String _normaliseFlightNo(String value) =>
    value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

bool _matchesFlightNumbers(Map<String, dynamic> trip, List<String> terms) {
  final wanted = terms
      .map(_normaliseFlightNo)
      .where((t) => t.isNotEmpty)
      .toList();
  if (wanted.isEmpty) return true;

  final have = <String>[];
  for (final s in _segs(trip)) {
    final fd = readKey(s, 'fD');
    final code = asString(readKey(readKey(fd, 'aI'), 'code'));
    final num = asString(readKey(fd, 'fN'));
    have
      ..add(_normaliseFlightNo('$code$num'))
      ..add(_normaliseFlightNo(num));
  }
  // Substring match so the list narrows as you type: "SG", "SG-25" and "252"
  // all reach SG-252. Requiring a whole flight number would mean the filter
  // shows nothing until the very last character is entered.
  return wanted.any((w) => have.any((h) => h.contains(w)));
}

/// minutes -> "3h 50m", for the duration sliders.
String formatFilterMinutes(int mins) {
  final m = mins < 0 ? 0 : mins;
  return '${m ~/ 60}h ${(m % 60).toString().padLeft(2, '0')}m';
}

/// "14:30" options at 30-minute steps, for the timeframe pickers.
final List<String> kTimeOptions = List.generate(48, (i) {
  final h = (i ~/ 2).toString().padLeft(2, '0');
  final m = i.isEven ? '00' : '30';
  return '$h:$m';
});

// ---------------------------------------------------------------------------
// Facets
// ---------------------------------------------------------------------------

/// One selectable row in the filter sheet.
class FacetItem {
  const FacetItem({
    required this.value,
    required this.label,
    this.count = 0,
    this.minPrice,
    this.code = '',
    this.name = '',
    this.city = '',
  });

  final String value;
  final String label;
  final int count;

  /// Cheapest trip carrying this facet, shown beside the row like the portal.
  final double? minPrice;

  final String code;
  final String name;
  final String city;
}

/// A one-tap shortcut in the "Popular filters" rail.
class PopularFilter {
  const PopularFilter({
    required this.key,
    required this.value,
    required this.label,
  });

  /// Matches a [FlightFilters] field name: `stops`, `departureTime`, `airlines`.
  final String key;
  final String value;
  final String label;
}

class _Bucket {
  _Bucket({this.code = '', this.name = '', this.city = '', this.terminal = ''});

  int count = 0;
  double? minPrice;
  String code;
  String name;
  String city;
  String terminal;
}

/// Everything the filter sheet needs to describe a result set.
class FlightFacets {
  const FlightFacets({
    required this.stops,
    required this.airlines,
    required this.departureSlots,
    required this.arrivalSlots,
    required this.departureAirports,
    required this.arrivalAirports,
    required this.departureTerminals,
    required this.arrivalTerminals,
    required this.layoverAirports,
    required this.fareTypes,
    required this.cancellationTypes,
    required this.baggageCount,
    required this.priceMin,
    required this.priceMax,
    required this.durationMin,
    required this.durationMax,
    required this.layoverMin,
    required this.layoverMax,
    required this.popular,
  });

  final List<FacetItem> stops;
  final List<FacetItem> airlines;
  final List<FacetItem> departureSlots;
  final List<FacetItem> arrivalSlots;
  final List<FacetItem> departureAirports;
  final List<FacetItem> arrivalAirports;
  final List<FacetItem> departureTerminals;
  final List<FacetItem> arrivalTerminals;
  final List<FacetItem> layoverAirports;
  final List<FacetItem> fareTypes;
  final List<FacetItem> cancellationTypes;
  final int baggageCount;
  final double priceMin;
  final double priceMax;
  final int durationMin;
  final int durationMax;
  final int layoverMin;
  final int layoverMax;
  final List<PopularFilter> popular;

  bool get hasPriceBand => priceMax > priceMin;
  bool get hasDurationBand => durationMax > durationMin;
  bool get hasLayoverBand => layoverMax > layoverMin && layoverMax > 0;
}

/// Build every facet from the full (unfiltered) result set, so counts stay
/// stable as the user narrows down rather than collapsing to zero.
FlightFacets? deriveFacets(
  List<FlightResult> flights, [
  PaxCounts pax = PaxCounts.singleAdult,
]) {
  if (flights.isEmpty) return null;

  final stops = <String, _Bucket>{};
  final airlines = <String, _Bucket>{};
  final departure = <String, _Bucket>{};
  final arrival = <String, _Bucket>{};
  final depAirports = <String, _Bucket>{};
  final arrAirports = <String, _Bucket>{};
  final depTerminals = <String, _Bucket>{};
  final arrTerminals = <String, _Bucket>{};
  final layovers = <String, _Bucket>{};
  final cancellation = <String, _Bucket>{};
  final fareTypeCounts = <String, int>{'STANDARD': 0, 'NDC': 0};

  var baggageCount = 0;
  double? priceMin;
  var priceMax = 0.0;
  int? durationMin;
  var durationMax = 0;
  int? layoverMin;
  var layoverMax = 0;

  void bump(
    Map<String, _Bucket> map,
    String? key,
    double price, {
    String code = '',
    String name = '',
    String city = '',
    String terminal = '',
  }) {
    if (key == null || key.isEmpty) return;
    final entry = map.putIfAbsent(
      key,
      () => _Bucket(code: code, name: name, city: city, terminal: terminal),
    );
    entry.count += 1;
    if (price > 0) {
      final current = entry.minPrice;
      entry.minPrice = current == null || price < current ? price : current;
    }
  }

  for (final flight in flights) {
    final trip = flight.raw;
    final price = tripBestPrice(trip, pax);
    if (price > 0) {
      priceMin = priceMin == null || price < priceMin ? price : priceMin;
      if (price > priceMax) priceMax = price;
    }

    bump(stops, '${stopsBucket(trip)}', price);

    final airlineInfo = readKey(readKey(_firstSeg(trip), 'fD'), 'aI');
    final airlineCode = asString(readKey(airlineInfo, 'code'));
    if (airlineCode.isNotEmpty) {
      bump(
        airlines,
        airlineCode,
        price,
        code: airlineCode,
        name: asString(readKey(airlineInfo, 'name'), fallback: airlineCode),
      );
    }

    final from = _firstSeg(trip);
    final to = _lastSeg(trip);

    final depMins = _minutesOfDay(readKey(from, 'dt'));
    if (depMins != null) bump(departure, slotForHour(depMins ~/ 60), price);
    final arrMins = _minutesOfDay(readKey(to, 'at'));
    if (arrMins != null) bump(arrival, slotForHour(arrMins ~/ 60), price);

    final da = readKey(from, 'da');
    final daCode = asString(readKey(da, 'code'));
    if (daCode.isNotEmpty) {
      bump(
        depAirports,
        airportKey(kDep, daCode),
        price,
        code: daCode,
        name: asString(readKey(da, 'name')),
        city: asString(readKey(da, 'city')),
      );
      final daTerminal = asString(readKey(da, 'terminal'));
      if (daTerminal.isNotEmpty) {
        bump(
          depTerminals,
          terminalKey(kDep, daCode, daTerminal),
          price,
          code: daCode,
          terminal: daTerminal,
        );
      }
    }

    final aa = readKey(to, 'aa');
    final aaCode = asString(readKey(aa, 'code'));
    if (aaCode.isNotEmpty) {
      bump(
        arrAirports,
        airportKey(kArr, aaCode),
        price,
        code: aaCode,
        name: asString(readKey(aa, 'name')),
        city: asString(readKey(aa, 'city')),
      );
      final aaTerminal = asString(readKey(aa, 'terminal'));
      if (aaTerminal.isNotEmpty) {
        bump(
          arrTerminals,
          terminalKey(kArr, aaCode, aaTerminal),
          price,
          code: aaCode,
          terminal: aaTerminal,
        );
      }
    }

    final segs = _segs(trip);
    if (segs.length > 1) {
      for (final seg in segs.sublist(0, segs.length - 1)) {
        final stop = readKey(seg, 'aa');
        final stopCode = asString(readKey(stop, 'code'));
        if (stopCode.isNotEmpty) {
          bump(
            layovers,
            stopCode,
            price,
            code: stopCode,
            name: asString(readKey(stop, 'name')),
          );
        }
      }
    }

    var hasBaggageFare = false;
    for (final fare in _fares(trip)) {
      final identifier = asString(readKey(fare, 'fareIdentifier'));
      if (isNdcFare(identifier)) {
        fareTypeCounts['NDC'] = (fareTypeCounts['NDC'] ?? 0) + 1;
      } else {
        fareTypeCounts['STANDARD'] = (fareTypeCounts['STANDARD'] ?? 0) + 1;
      }
      bump(cancellation, fareCancellationType(fare), farePrice(fare, pax));
      if (fareHasCheckinBaggage(fare)) hasBaggageFare = true;
    }
    if (hasBaggageFare) baggageCount += 1;

    final dur = tripDuration(trip);
    if (dur > 0) {
      durationMin = durationMin == null || dur < durationMin ? dur : durationMin;
      if (dur > durationMax) durationMax = dur;
    }
    final lay = tripMaxLayover(trip);
    if (lay > 0) {
      layoverMin = layoverMin == null || lay < layoverMin ? lay : layoverMin;
      if (lay > layoverMax) layoverMax = lay;
    }
  }

  List<FacetItem> toList(
    Map<String, _Bucket> map, {
    bool byCount = false,
    String Function(String value, _Bucket b)? label,
  }) {
    final list = map.entries
        .map(
          (e) => FacetItem(
            value: e.key,
            label: label?.call(e.key, e.value) ?? e.key,
            count: e.value.count,
            minPrice: e.value.minPrice,
            code: e.value.code,
            name: e.value.name,
            city: e.value.city,
          ),
        )
        .toList();
    if (byCount) {
      list.sort((a, b) => b.count.compareTo(a.count));
    } else {
      list.sort((a, b) => a.value.compareTo(b.value));
    }
    return list;
  }

  final stopList = toList(
    stops,
    label: (v, _) => stopLabel(int.tryParse(v) ?? 0),
  );
  final airlineList = toList(airlines, byCount: true, label: (v, b) => b.name);
  final departureList = toList(
    departure,
    label: (v, _) => kTimeSlotLabels[v] ?? v,
  );

  // The rail leads with the busiest stop bucket, then the two busiest departure
  // bands, then the three biggest carriers — the same shape as the portal.
  final popular = <PopularFilter>[
    ...(List<FacetItem>.from(stopList)
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(1)
        .map(
          (s) =>
              PopularFilter(key: 'stops', value: s.value, label: s.label),
        ),
    ...(List<FacetItem>.from(departureList)
          ..sort((a, b) => b.count.compareTo(a.count)))
        .take(2)
        .map(
          (s) => PopularFilter(
            key: 'departureTime',
            value: s.value,
            label: 'Departs ${s.label}',
          ),
        ),
    ...airlineList
        .take(3)
        .map(
          (a) => PopularFilter(
            key: 'airlines',
            value: a.value,
            label: a.name.isEmpty ? a.value : a.name,
          ),
        ),
  ];

  return FlightFacets(
    stops: stopList,
    airlines: airlineList,
    departureSlots: departureList,
    arrivalSlots: toList(arrival, label: (v, _) => kTimeSlotLabels[v] ?? v),
    departureAirports: toList(
      depAirports,
      byCount: true,
      label: (v, b) => b.city.isEmpty ? b.code : '${b.city} (${b.code})',
    ),
    arrivalAirports: toList(
      arrAirports,
      byCount: true,
      label: (v, b) => b.city.isEmpty ? b.code : '${b.city} (${b.code})',
    ),
    departureTerminals: toList(
      depTerminals,
      byCount: true,
      label: (v, b) => '${b.code} · ${b.terminal}',
    ),
    arrivalTerminals: toList(
      arrTerminals,
      byCount: true,
      label: (v, b) => '${b.code} · ${b.terminal}',
    ),
    layoverAirports: toList(
      layovers,
      byCount: true,
      label: (v, b) => b.name.isEmpty ? b.code : '${b.name} (${b.code})',
    ),
    fareTypes: [
      for (final t in kFareTypes)
        if ((fareTypeCounts[t.value] ?? 0) > 0)
          FacetItem(
            value: t.value,
            label: t.label,
            count: fareTypeCounts[t.value] ?? 0,
          ),
    ],
    cancellationTypes: [
      for (final c in kCancellationTypes)
        if ((cancellation[c.value]?.count ?? 0) > 0)
          FacetItem(
            value: c.value,
            label: c.label,
            count: cancellation[c.value]?.count ?? 0,
          ),
    ],
    baggageCount: baggageCount,
    priceMin: (priceMin ?? 0).floorToDouble(),
    priceMax: priceMax.ceilToDouble(),
    durationMin: durationMin ?? 0,
    durationMax: durationMax,
    layoverMin: layoverMin ?? 0,
    layoverMax: layoverMax,
    popular: popular,
  );
}

// ---------------------------------------------------------------------------
// Filter state
// ---------------------------------------------------------------------------

/// Immutable selection state for the flight filter sheet.
class FlightFilters {
  const FlightFilters({
    this.stops = const {},
    this.airlines = const {},
    this.fareTypes = const {},
    this.cancellationTypes = const {},
    this.terminals = const {},
    this.airports = const {},
    this.layoverAirports = const {},
    this.departureTime = const {},
    this.arrivalTime = const {},
    this.flightNumbers = const [],
    this.departureFrom,
    this.departureTo,
    this.arrivalFrom,
    this.arrivalTo,
    this.baggageOnly = false,
    this.hideNearbyAirports = false,
    this.priceMin,
    this.priceMax,
    this.durationMax,
    this.layoverMax,
  });

  final Set<int> stops;
  final Set<String> airlines;
  final Set<String> fareTypes;
  final Set<String> cancellationTypes;
  final Set<String> terminals;
  final Set<String> airports;
  final Set<String> layoverAirports;
  final Set<String> departureTime;
  final Set<String> arrivalTime;

  /// Free-text entries ("123", "6E-123") rather than picked facets.
  final List<String> flightNumbers;

  /// Exact windows from "Specific timeframe" — "HH:MM" or null.
  final String? departureFrom;
  final String? departureTo;
  final String? arrivalFrom;
  final String? arrivalTo;

  final bool baggageOnly;
  final bool hideNearbyAirports;
  final double? priceMin;
  final double? priceMax;
  final int? durationMax;
  final int? layoverMax;

  static const FlightFilters empty = FlightFilters();

  bool get isEmpty => activeCount == 0;

  /// Mirrors the web's `countActiveFilters` so the badge reads the same.
  int get activeCount =>
      stops.length +
      airlines.length +
      fareTypes.length +
      cancellationTypes.length +
      terminals.length +
      airports.length +
      layoverAirports.length +
      departureTime.length +
      arrivalTime.length +
      flightNumbers.where((f) => f.trim().isNotEmpty).length +
      (baggageOnly ? 1 : 0) +
      (hideNearbyAirports ? 1 : 0) +
      (priceMin != null || priceMax != null ? 1 : 0) +
      (durationMax != null ? 1 : 0) +
      (layoverMax != null ? 1 : 0) +
      (departureFrom != null || departureTo != null ? 1 : 0) +
      (arrivalFrom != null || arrivalTo != null ? 1 : 0);

  FlightFilters copyWith({
    Set<int>? stops,
    Set<String>? airlines,
    Set<String>? fareTypes,
    Set<String>? cancellationTypes,
    Set<String>? terminals,
    Set<String>? airports,
    Set<String>? layoverAirports,
    Set<String>? departureTime,
    Set<String>? arrivalTime,
    List<String>? flightNumbers,
    bool? baggageOnly,
    bool? hideNearbyAirports,
    // Nullable fields need an explicit "clear this" signal, since passing null
    // is how copyWith says "leave it alone".
    Object? departureFrom = _unset,
    Object? departureTo = _unset,
    Object? arrivalFrom = _unset,
    Object? arrivalTo = _unset,
    Object? priceMin = _unset,
    Object? priceMax = _unset,
    Object? durationMax = _unset,
    Object? layoverMax = _unset,
  }) {
    return FlightFilters(
      stops: stops ?? this.stops,
      airlines: airlines ?? this.airlines,
      fareTypes: fareTypes ?? this.fareTypes,
      cancellationTypes: cancellationTypes ?? this.cancellationTypes,
      terminals: terminals ?? this.terminals,
      airports: airports ?? this.airports,
      layoverAirports: layoverAirports ?? this.layoverAirports,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      flightNumbers: flightNumbers ?? this.flightNumbers,
      baggageOnly: baggageOnly ?? this.baggageOnly,
      hideNearbyAirports: hideNearbyAirports ?? this.hideNearbyAirports,
      departureFrom: departureFrom == _unset
          ? this.departureFrom
          : departureFrom as String?,
      departureTo: departureTo == _unset
          ? this.departureTo
          : departureTo as String?,
      arrivalFrom: arrivalFrom == _unset
          ? this.arrivalFrom
          : arrivalFrom as String?,
      arrivalTo: arrivalTo == _unset ? this.arrivalTo : arrivalTo as String?,
      priceMin: priceMin == _unset ? this.priceMin : priceMin as double?,
      priceMax: priceMax == _unset ? this.priceMax : priceMax as double?,
      durationMax: durationMax == _unset
          ? this.durationMax
          : durationMax as int?,
      layoverMax: layoverMax == _unset ? this.layoverMax : layoverMax as int?,
    );
  }

  /// Toggle helper for the set-valued groups.
  FlightFilters toggle(String group, Object value) {
    Set<T> flip<T>(Set<T> current, T v) {
      final next = Set<T>.from(current);
      if (!next.remove(v)) next.add(v);
      return next;
    }

    switch (group) {
      case 'stops':
        return copyWith(stops: flip(stops, value as int));
      case 'airlines':
        return copyWith(airlines: flip(airlines, value as String));
      case 'fareTypes':
        return copyWith(fareTypes: flip(fareTypes, value as String));
      case 'cancellationTypes':
        return copyWith(
          cancellationTypes: flip(cancellationTypes, value as String),
        );
      case 'terminals':
        return copyWith(terminals: flip(terminals, value as String));
      case 'airports':
        return copyWith(airports: flip(airports, value as String));
      case 'layoverAirports':
        return copyWith(
          layoverAirports: flip(layoverAirports, value as String),
        );
      case 'departureTime':
        return copyWith(departureTime: flip(departureTime, value as String));
      case 'arrivalTime':
        return copyWith(arrivalTime: flip(arrivalTime, value as String));
      default:
        return this;
    }
  }

  bool isSelected(String group, Object value) => switch (group) {
    'stops' => stops.contains(value),
    'airlines' => airlines.contains(value),
    'fareTypes' => fareTypes.contains(value),
    'cancellationTypes' => cancellationTypes.contains(value),
    'terminals' => terminals.contains(value),
    'airports' => airports.contains(value),
    'layoverAirports' => layoverAirports.contains(value),
    'departureTime' => departureTime.contains(value),
    'arrivalTime' => arrivalTime.contains(value),
    _ => false,
  };

  /// Clear one section without disturbing the rest — powers the CLEAR links.
  FlightFilters clearGroup(String group) => switch (group) {
    'stops' => copyWith(stops: const {}),
    'airlines' => copyWith(airlines: const {}),
    'fareTypes' => copyWith(fareTypes: const {}),
    'cancellationTypes' => copyWith(cancellationTypes: const {}),
    'terminals' => copyWith(terminals: const {}),
    'airports' => copyWith(airports: const {}),
    'layoverAirports' => copyWith(layoverAirports: const {}),
    'departureTime' => copyWith(departureTime: const {}),
    'arrivalTime' => copyWith(arrivalTime: const {}),
    'flightNumbers' => copyWith(flightNumbers: const []),
    'price' => copyWith(priceMin: null, priceMax: null),
    'durationMax' => copyWith(durationMax: null),
    'layoverMax' => copyWith(layoverMax: null),
    'timeframe' => copyWith(
      departureFrom: null,
      departureTo: null,
      arrivalFrom: null,
      arrivalTo: null,
    ),
    _ => this,
  };
}

const Object _unset = Object();

// ---------------------------------------------------------------------------
// Filtering
// ---------------------------------------------------------------------------

/// Apply the sheet's selections to a list of trips.
///
/// Fare-level filters narrow each trip's `totalPriceList`, so a trip is dropped
/// only when no fare on it survives.
List<FlightResult> filterFlights(
  List<FlightResult> flights,
  FlightFilters filters, {
  String? searchFrom,
  String? searchTo,
  PaxCounts pax = PaxCounts.singleAdult,
}) {
  final searchedCodes = [searchFrom, searchTo]
      .whereType<String>()
      .where((c) => c.isNotEmpty)
      .map((c) => c.toUpperCase())
      .toList();

  // Direction-qualified selections only constrain their own direction, so a
  // chosen departure terminal never rejects a trip on its arrival terminal.
  final wantedDepAirports = filters.airports
      .where((k) => k.startsWith('$kDep|'))
      .toSet();
  final wantedArrAirports = filters.airports
      .where((k) => k.startsWith('$kArr|'))
      .toSet();
  final wantedDepTerminals = filters.terminals
      .where((k) => k.startsWith('$kDep|'))
      .toSet();
  final wantedArrTerminals = filters.terminals
      .where((k) => k.startsWith('$kArr|'))
      .toSet();

  final out = <FlightResult>[];

  for (final flight in flights) {
    final trip = flight.raw;
    final segs = _segs(trip);
    if (segs.isEmpty) continue;

    final from = segs.first;
    final to = segs.last;

    if (filters.stops.isNotEmpty && !filters.stops.contains(stopsBucket(trip))) {
      continue;
    }
    if (filters.airlines.isNotEmpty &&
        !filters.airlines.contains(_tripAirlineCode(trip))) {
      continue;
    }
    if (!_matchesSlots(readKey(from, 'dt'), filters.departureTime)) continue;
    if (!_matchesSlots(readKey(to, 'at'), filters.arrivalTime)) continue;
    if (!_matchesWindow(
      readKey(from, 'dt'),
      filters.departureFrom,
      filters.departureTo,
    )) {
      continue;
    }
    if (!_matchesWindow(
      readKey(to, 'at'),
      filters.arrivalFrom,
      filters.arrivalTo,
    )) {
      continue;
    }
    if (!_matchesFlightNumbers(trip, filters.flightNumbers)) continue;

    final daCode = asString(readKey(readKey(from, 'da'), 'code'));
    final aaCode = asString(readKey(readKey(to, 'aa'), 'code'));

    if (wantedDepAirports.isNotEmpty &&
        !wantedDepAirports.contains(airportKey(kDep, daCode))) {
      continue;
    }
    if (wantedArrAirports.isNotEmpty &&
        !wantedArrAirports.contains(airportKey(kArr, aaCode))) {
      continue;
    }
    if (wantedDepTerminals.isNotEmpty) {
      final t = asString(readKey(readKey(from, 'da'), 'terminal'));
      if (!wantedDepTerminals.contains(terminalKey(kDep, daCode, t))) continue;
    }
    if (wantedArrTerminals.isNotEmpty) {
      final t = asString(readKey(readKey(to, 'aa'), 'terminal'));
      if (!wantedArrTerminals.contains(terminalKey(kArr, aaCode, t))) continue;
    }
    if (filters.layoverAirports.isNotEmpty) {
      final l = tripLayoverAirports(trip);
      if (!filters.layoverAirports.any(l.contains)) continue;
    }
    if (filters.hideNearbyAirports && searchedCodes.isNotEmpty) {
      if (tripEndpointAirports(
        trip,
      ).any((code) => !searchedCodes.contains(code))) {
        continue;
      }
    }
    if (filters.durationMax != null &&
        tripDuration(trip) > filters.durationMax!) {
      continue;
    }
    if (filters.layoverMax != null &&
        segs.length > 1 &&
        tripMaxLayover(trip) > filters.layoverMax!) {
      continue;
    }

    // Fare-level narrowing.
    var fares = _fares(trip);
    final total = fares.length;

    if (filters.fareTypes.isNotEmpty) {
      fares = fares
          .where(
            (f) => filters.fareTypes.contains(
              isNdcFare(asString(readKey(f, 'fareIdentifier')))
                  ? 'NDC'
                  : 'STANDARD',
            ),
          )
          .toList();
    }
    if (filters.cancellationTypes.isNotEmpty) {
      fares = fares
          .where((f) => filters.cancellationTypes.contains(
                fareCancellationType(f),
              ))
          .toList();
    }
    if (filters.baggageOnly) {
      fares = fares.where(fareHasCheckinBaggage).toList();
    }
    if (filters.priceMin != null) {
      fares = fares.where((f) => farePrice(f, pax) >= filters.priceMin!).toList();
    }
    if (filters.priceMax != null) {
      fares = fares.where((f) => farePrice(f, pax) <= filters.priceMax!).toList();
    }
    if (fares.isEmpty) continue;

    out.add(
      fares.length == total
          ? flight
          : flight.withFares(fares),
    );
  }

  return out;
}

// ---------------------------------------------------------------------------
// Sorting
// ---------------------------------------------------------------------------

/// The four orders the web results screen offers.
enum FlightSort { price, duration, departure, arrival }

extension FlightSortLabel on FlightSort {
  String get label => switch (this) {
    FlightSort.price => 'Price (lowest first)',
    FlightSort.duration => 'Duration (shortest first)',
    FlightSort.departure => 'Departure (earliest first)',
    FlightSort.arrival => 'Arrival (earliest first)',
  };

  String get shortLabel => switch (this) {
    FlightSort.price => 'Price',
    FlightSort.duration => 'Duration',
    FlightSort.departure => 'Departure',
    FlightSort.arrival => 'Arrival',
  };
}

List<FlightResult> sortFlights(
  List<FlightResult> flights,
  FlightSort sort, [
  PaxCounts pax = PaxCounts.singleAdult,
]) {
  final list = List<FlightResult>.from(flights);
  int byTime(dynamic a, dynamic b) {
    final da = DateTime.tryParse(asString(a));
    final db = DateTime.tryParse(asString(b));
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  switch (sort) {
    case FlightSort.price:
      list.sort(
        (a, b) =>
            tripBestPrice(a.raw, pax).compareTo(tripBestPrice(b.raw, pax)),
      );
    case FlightSort.duration:
      list.sort((a, b) => tripDuration(a.raw).compareTo(tripDuration(b.raw)));
    case FlightSort.departure:
      list.sort(
        (a, b) =>
            byTime(readKey(_firstSeg(a.raw), 'dt'), readKey(_firstSeg(b.raw), 'dt')),
      );
    case FlightSort.arrival:
      list.sort(
        (a, b) =>
            byTime(readKey(_lastSeg(a.raw), 'at'), readKey(_lastSeg(b.raw), 'at')),
      );
  }
  return list;
}

// ---------------------------------------------------------------------------
// Applied-filter chips
// ---------------------------------------------------------------------------

/// One removable entry in the "Applied filters" rail.
class AppliedFilterChip {
  const AppliedFilterChip({
    required this.group,
    required this.value,
    required this.label,
  });

  final String group;
  final Object value;
  final String label;
}

String _facetLabel(List<FacetItem>? list, String value, String fallback) =>
    list?.where((i) => i.value == value).firstOrNull?.label ?? fallback;

/// Flatten the active filters into removable chips, in the order the sheet
/// presents them.
List<AppliedFilterChip> describeFilters(FlightFilters f, FlightFacets? meta) {
  final chips = <AppliedFilterChip>[];

  for (final v in f.stops) {
    chips.add(
      AppliedFilterChip(group: 'stops', value: v, label: 'Stops: ${stopLabel(v)}'),
    );
  }
  for (final v in f.airlines) {
    final name = meta?.airlines
        .where((a) => a.value == v)
        .firstOrNull
        ?.name;
    chips.add(
      AppliedFilterChip(
        group: 'airlines',
        value: v,
        label: (name == null || name.isEmpty) ? v : name,
      ),
    );
  }
  for (final v in f.fareTypes) {
    chips.add(
      AppliedFilterChip(
        group: 'fareTypes',
        value: v,
        label: 'Fare: ${_facetLabel(meta?.fareTypes, v, v)}',
      ),
    );
  }
  for (final v in f.cancellationTypes) {
    chips.add(
      AppliedFilterChip(
        group: 'cancellationTypes',
        value: v,
        label: _facetLabel(meta?.cancellationTypes, v, v),
      ),
    );
  }
  for (final v in f.terminals) {
    final parsed = parseFacetKey(v);
    chips.add(
      AppliedFilterChip(
        group: 'terminals',
        value: v,
        label: 'Terminal: ${parsed.code} ${parsed.terminal}',
      ),
    );
  }
  for (final v in f.airports) {
    chips.add(
      AppliedFilterChip(
        group: 'airports',
        value: v,
        label: 'Airport: ${parseFacetKey(v).code}',
      ),
    );
  }
  for (final v in f.layoverAirports) {
    chips.add(
      AppliedFilterChip(group: 'layoverAirports', value: v, label: 'Via $v'),
    );
  }
  for (final v in f.departureTime) {
    chips.add(
      AppliedFilterChip(
        group: 'departureTime',
        value: v,
        label: 'Departs ${kTimeSlotLabels[v] ?? v}',
      ),
    );
  }
  for (final v in f.arrivalTime) {
    chips.add(
      AppliedFilterChip(
        group: 'arrivalTime',
        value: v,
        label: 'Arrives ${kTimeSlotLabels[v] ?? v}',
      ),
    );
  }
  for (final v in f.flightNumbers.where((n) => n.trim().isNotEmpty)) {
    chips.add(
      AppliedFilterChip(group: 'flightNumbers', value: v, label: 'Flight $v'),
    );
  }
  if (f.departureFrom != null || f.departureTo != null) {
    chips.add(
      AppliedFilterChip(
        group: 'timeframeDeparture',
        value: 'departure',
        label: 'Departs ${f.departureFrom ?? '…'} – ${f.departureTo ?? '…'}',
      ),
    );
  }
  if (f.arrivalFrom != null || f.arrivalTo != null) {
    chips.add(
      AppliedFilterChip(
        group: 'timeframeArrival',
        value: 'arrival',
        label: 'Arrives ${f.arrivalFrom ?? '…'} – ${f.arrivalTo ?? '…'}',
      ),
    );
  }
  if (f.baggageOnly) {
    chips.add(
      const AppliedFilterChip(
        group: 'baggageOnly',
        value: true,
        label: 'Check-in baggage',
      ),
    );
  }
  if (f.hideNearbyAirports) {
    chips.add(
      const AppliedFilterChip(
        group: 'hideNearbyAirports',
        value: true,
        label: 'Exact airports only',
      ),
    );
  }
  if (f.priceMin != null || f.priceMax != null) {
    final lo = f.priceMin != null ? '₹${f.priceMin!.round()}' : '₹0';
    final hi = f.priceMax != null ? '₹${f.priceMax!.round()}' : 'any';
    chips.add(
      AppliedFilterChip(group: 'price', value: 'range', label: '$lo – $hi'),
    );
  }
  if (f.durationMax != null) {
    chips.add(
      AppliedFilterChip(
        group: 'durationMax',
        value: 'max',
        label: 'Under ${formatFilterMinutes(f.durationMax!)}',
      ),
    );
  }
  if (f.layoverMax != null) {
    chips.add(
      AppliedFilterChip(
        group: 'layoverMax',
        value: 'max',
        label: 'Layover under ${formatFilterMinutes(f.layoverMax!)}',
      ),
    );
  }
  return chips;
}

/// Remove exactly one chip, leaving every other selection intact.
FlightFilters removeChip(FlightFilters f, AppliedFilterChip chip) {
  switch (chip.group) {
    case 'price':
      return f.copyWith(priceMin: null, priceMax: null);
    case 'timeframeDeparture':
      return f.copyWith(departureFrom: null, departureTo: null);
    case 'timeframeArrival':
      return f.copyWith(arrivalFrom: null, arrivalTo: null);
    case 'flightNumbers':
      return f.copyWith(
        flightNumbers: f.flightNumbers.where((v) => v != chip.value).toList(),
      );
    case 'baggageOnly':
      return f.copyWith(baggageOnly: false);
    case 'hideNearbyAirports':
      return f.copyWith(hideNearbyAirports: false);
    case 'durationMax':
      return f.copyWith(durationMax: null);
    case 'layoverMax':
      return f.copyWith(layoverMax: null);
    default:
      return f.toggle(chip.group, chip.value);
  }
}

// ---------------------------------------------------------------------------
// Reconciliation
// ---------------------------------------------------------------------------

/// Drop selections the new result set cannot satisfy.
///
/// Filters survive a leg change on purpose, but a value that made sense on the
/// outbound can be impossible on the return — keep `stops: {0}` active when the
/// return has no non-stop and the list empties with no explanation.
FlightFilters reconcileFilters(FlightFilters f, FlightFacets? facets) {
  if (facets == null) return f;

  Set<String> allowed(List<FacetItem> list) => list.map((i) => i.value).toSet();

  Set<T> keep<T>(Set<T> selected, Set<String> valid) =>
      selected.where((v) => valid.contains(v.toString())).toSet();

  var next = f.copyWith(
    stops: keep(f.stops, allowed(facets.stops)),
    airlines: keep(f.airlines, allowed(facets.airlines)),
    fareTypes: keep(f.fareTypes, allowed(facets.fareTypes)),
    cancellationTypes: keep(
      f.cancellationTypes,
      allowed(facets.cancellationTypes),
    ),
    terminals: keep(
      f.terminals,
      {...allowed(facets.departureTerminals), ...allowed(facets.arrivalTerminals)},
    ),
    airports: keep(
      f.airports,
      {...allowed(facets.departureAirports), ...allowed(facets.arrivalAirports)},
    ),
    layoverAirports: keep(
      f.layoverAirports,
      allowed(facets.layoverAirports),
    ),
    departureTime: keep(f.departureTime, allowed(facets.departureSlots)),
    arrivalTime: keep(f.arrivalTime, allowed(facets.arrivalSlots)),
  );

  // A cap below the new floor (or a floor above the new ceiling) excludes
  // everything — release it rather than showing an empty list.
  if (next.priceMax != null && next.priceMax! < facets.priceMin) {
    next = next.copyWith(priceMax: null);
  }
  if (next.priceMin != null && next.priceMin! > facets.priceMax) {
    next = next.copyWith(priceMin: null);
  }
  if (next.durationMax != null && next.durationMax! < facets.durationMin) {
    next = next.copyWith(durationMax: null);
  }
  if (next.layoverMax != null &&
      facets.layoverMin > 0 &&
      next.layoverMax! < facets.layoverMin) {
    next = next.copyWith(layoverMax: null);
  }

  return next;
}
