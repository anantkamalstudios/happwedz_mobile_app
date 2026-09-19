import 'package:flutter/foundation.dart';

import 'honeymoon_models.dart'
    show asJsonMap, asList, asString, digPath, readKey;

/// Flight add-ons: seats, meals and baggage, chosen per passenger per segment.
///
/// A port of the web's `components/FlightAddOn.jsx`. The shapes below mirror
/// its selection object exactly, because [FlightAddOns.ssrForTraveller] has to
/// produce the same `ssrSeatInfos` / `ssrMealInfos` / `ssrBaggageInfos` arrays
/// the supplier expects.

// =============================================================
// SEAT MAP
// =============================================================

/// One seat on one segment's map.
@immutable
class SeatCell {
  const SeatCell({
    required this.seatNo,
    required this.row,
    required this.column,
    required this.amount,
    required this.isBooked,
    required this.isLegroom,
  });

  final String seatNo;
  final int row;
  final int column;
  final double amount;
  final bool isBooked;
  final bool isLegroom;

  static SeatCell? fromJson(dynamic json) {
    final seatNo = asString(readKey(json, 'seatNo'));
    final row = _toInt(digPath(json, ['seatPosition', 'row']));
    final column = _toInt(digPath(json, ['seatPosition', 'column']));
    if (seatNo.isEmpty || row == null || column == null) return null;
    return SeatCell(
      seatNo: seatNo,
      row: row,
      column: column,
      amount: _toDouble(readKey(json, 'amount')) ?? 0,
      isBooked: readKey(json, 'isBooked') == true,
      isLegroom: readKey(json, 'isLegroom') == true,
    );
  }

  /// The letter part of the seat number — the deck's row label.
  String get letter => seatNo.replaceFirst(RegExp(r'^[0-9]+'), '');
}

/// One segment's deck: its grid size and every seat on it.
@immutable
class SegmentSeatMap {
  const SegmentSeatMap({
    required this.rows,
    required this.columns,
    required this.seats,
  });

  final int rows;
  final int columns;
  final List<SeatCell> seats;

  static SegmentSeatMap? fromJson(dynamic json) {
    final seats = asList(
      readKey(json, 'sInfo'),
    ).map(SeatCell.fromJson).whereType<SeatCell>().toList();
    if (seats.isEmpty) return null;
    return SegmentSeatMap(
      rows: _toInt(digPath(json, ['sData', 'row'])) ?? 0,
      columns: _toInt(digPath(json, ['sData', 'column'])) ?? 0,
      seats: seats,
    );
  }

  SeatCell? at(int row, int column) {
    for (final seat in seats) {
      if (seat.row == row && seat.column == column) return seat;
    }
    return null;
  }

  /// Columns the data actually uses. The one missing index is the aisle.
  List<int> get usedColumns =>
      (seats.map((s) => s.column).toSet().toList()..sort());

  /// The gap in the column run — where the aisle is drawn.
  int? get aisleColumn {
    final used = usedColumns;
    for (var c = 1; c <= columns; c++) {
      if (!used.contains(c)) return c;
    }
    return null;
  }

  String letterFor(int column) {
    for (final seat in seats) {
      if (seat.column == column) return seat.letter;
    }
    return '';
  }

  /// Legend bands for this deck's prices.
  ///
  /// Free seats always stand alone; the rest are split into up to four groups
  /// so "extra legroom" separates from "front row" without hardcoding
  /// thresholds that vary per aircraft.
  List<PriceBand> get priceBands {
    final distinct =
        seats.map((s) => s.amount).where((a) => a > 0).toSet().toList()..sort();

    final bands = <PriceBand>[const PriceBand(0, 0)];
    final groups = distinct.length < 4 ? distinct.length : 4;
    for (var i = 0; i < groups; i++) {
      final start = (i * distinct.length) ~/ groups;
      final end = ((i + 1) * distinct.length) ~/ groups;
      if (end > start) {
        bands.add(PriceBand(distinct[start], distinct[end - 1]));
      }
    }
    return bands;
  }
}

@immutable
class PriceBand {
  const PriceBand(this.min, this.max);

  final double min;
  final double max;

  bool contains(double amount) => amount >= min && amount <= max;
}

/// Result of a seat-map lookup: the per-segment decks, or why there are none.
@immutable
class SeatMapResult {
  const SeatMapResult({this.bySegment = const {}, this.error});

  final Map<String, SegmentSeatMap> bySegment;
  final String? error;

  bool get isEmpty => bySegment.isEmpty;

  factory SeatMapResult.fromJson(Map<String, dynamic> json) {
    final bySegment = <String, SegmentSeatMap>{};
    json.forEach((segmentId, value) {
      final deck = SegmentSeatMap.fromJson(value);
      if (deck != null) bySegment[segmentId] = deck;
    });
    return SeatMapResult(bySegment: bySegment);
  }
}

// =============================================================
// SEGMENTS AND SSR MENUS
// =============================================================

/// One leg a passenger can buy add-ons for, with its SSR menus.
@immutable
class AddOnSegment {
  const AddOnSegment({
    required this.id,
    required this.from,
    required this.to,
    required this.meals,
    required this.baggage,
  });

  final String id;
  final String from;
  final String to;
  final List<SsrOption> meals;
  final List<SsrOption> baggage;

  /// On a connecting journey the bag is checked through, so the supplier
  /// prices excess baggage on the first leg only and returns `amount: null`
  /// on the rest. Buying against one of those legs is rejected with error
  /// 1129 ("Baggage not allowed for connecting segment"). A null amount on a
  /// MEAL just means it is free, so this test is baggage-only.
  bool get baggageSellable => baggage.any((b) => b.hasAmount);

  String get label => '$from → $to';

  /// Every leg in a priced itinerary, in order.
  static List<AddOnSegment> fromReview(dynamic reviewJson) {
    final tripInfos = readKey(reviewJson, 'tripInfos');
    final trips = tripInfos is List
        ? tripInfos
        : asJsonMap(tripInfos).values.expand(asList).toList();

    return [
      for (final trip in trips)
        for (final segment in asList(readKey(trip, 'sI')))
          AddOnSegment(
            id: asString(readKey(segment, 'id')),
            from: asString(digPath(segment, ['da', 'code'])),
            to: asString(digPath(segment, ['aa', 'code'])),
            meals: SsrOption.listFrom(digPath(segment, ['ssrInfo', 'MEAL'])),
            baggage: SsrOption.listFrom(
              digPath(segment, ['ssrInfo', 'BAGGAGE']),
            ),
          ),
    ];
  }
}

/// One purchasable meal or baggage item.
@immutable
class SsrOption {
  const SsrOption({
    required this.code,
    required this.desc,
    required this.amount,
    required this.hasAmount,
  });

  final String code;
  final String desc;
  final double amount;

  /// Whether the supplier priced this at all — see [AddOnSegment.baggageSellable].
  final bool hasAmount;

  bool get isFree => amount <= 0;

  static List<SsrOption> listFrom(dynamic json) => asList(json)
      .map((item) {
        final code = asString(readKey(item, 'code'));
        if (code.isEmpty) return null;
        final raw = readKey(item, 'amount');
        return SsrOption(
          code: code,
          desc: asString(readKey(item, 'desc')),
          amount: _toDouble(raw) ?? 0,
          hasAmount: raw != null,
        );
      })
      .whereType<SsrOption>()
      .toList();
}

// =============================================================
// SELECTION STATE
// =============================================================

/// A seat a passenger holds on one leg.
@immutable
class SeatChoice {
  const SeatChoice({required this.code, required this.amount});

  final String code;
  final double amount;
}

/// A meal or bag a passenger bought on one leg.
@immutable
class SsrChoice {
  const SsrChoice({
    required this.code,
    required this.desc,
    required this.amount,
    required this.qty,
  });

  final String code;
  final String desc;
  final double amount;
  final int qty;

  double get total => amount * qty;
}

/// Everything chosen in the add-on step.
///
/// Keyed passenger index → segment id. Keeping the segment in the key is what
/// stops a seat picked on the second leg from replacing the first.
class FlightAddOns {
  FlightAddOns({
    Map<int, Map<String, SeatChoice>>? seats,
    Map<int, Map<String, Map<String, SsrChoice>>>? meals,
    Map<int, Map<String, Map<String, SsrChoice>>>? baggage,
  }) : seats = seats ?? {},
       meals = meals ?? {},
       baggage = baggage ?? {};

  final Map<int, Map<String, SeatChoice>> seats;
  final Map<int, Map<String, Map<String, SsrChoice>>> meals;
  final Map<int, Map<String, Map<String, SsrChoice>>> baggage;

  bool get isEmpty =>
      total == 0 && seats.isEmpty && meals.isEmpty && baggage.isEmpty;

  SeatChoice? seatFor(int pax, String segmentId) => seats[pax]?[segmentId];

  /// The single choice this passenger has made on this leg, if any.
  SsrChoice? ssrChosen(SsrKind kind, int pax, String segmentId) {
    final bySeg = _mapFor(kind)[pax]?[segmentId];
    if (bySeg == null) return null;
    for (final choice in bySeg.values) {
      if (choice.qty > 0) return choice;
    }
    return null;
  }

  Map<int, Map<String, Map<String, SsrChoice>>> _mapFor(SsrKind kind) =>
      kind == SsrKind.meal ? meals : baggage;

  /// Toggles a seat for [pax] on [segmentId]. Picking the seat they already
  /// hold clears it; a seat held by another passenger is ignored.
  void toggleSeat(int pax, String segmentId, SeatCell seat) {
    if (seat.isBooked || isTakenByOther(pax, segmentId, seat.seatNo)) return;
    final forPax = seats[pax] ?? {};
    if (forPax[segmentId]?.code == seat.seatNo) {
      forPax.remove(segmentId);
    } else {
      forPax[segmentId] = SeatChoice(code: seat.seatNo, amount: seat.amount);
    }
    seats[pax] = forPax;
  }

  bool isTakenByOther(int pax, String segmentId, String seatNo) {
    for (final entry in seats.entries) {
      if (entry.key == pax) continue;
      if (entry.value[segmentId]?.code == seatNo) return true;
    }
    return false;
  }

  /// Sets the quantity of one meal or bag. Replacing the selection rather
  /// than appending keeps it to one per leg, as the web does.
  void setSsrQty(
    SsrKind kind,
    int pax,
    String segmentId,
    SsrOption item,
    int qty,
  ) {
    final map = _mapFor(kind);
    final forPax = map[pax] ?? {};
    final forSeg = qty > 0
        ? <String, SsrChoice>{}
        : {...(forSeg0(forPax, segmentId))};
    if (qty > 0) {
      forSeg[item.code] = SsrChoice(
        code: item.code,
        desc: item.desc,
        amount: item.amount,
        qty: 1,
      );
    } else {
      forSeg.remove(item.code);
    }
    forPax[segmentId] = forSeg;
    map[pax] = forPax;
  }

  static Map<String, SsrChoice> forSeg0(
    Map<String, Map<String, SsrChoice>> forPax,
    String segmentId,
  ) => forPax[segmentId] ?? {};

  int ssrQty(SsrKind kind, int pax, String segmentId, String code) =>
      _mapFor(kind)[pax]?[segmentId]?[code]?.qty ?? 0;

  // ---------------------------------------------------------------------
  // Totals
  // ---------------------------------------------------------------------

  double get seatTotal => seats.values.fold(
    0,
    (sum, bySeg) => sum + bySeg.values.fold(0.0, (m, s) => m + s.amount),
  );

  double _ssrTotal(SsrKind kind) => _mapFor(kind).values.fold(
    0,
    (sum, bySeg) =>
        sum +
        bySeg.values.fold(
          0.0,
          (m, byCode) => m + byCode.values.fold(0.0, (k, i) => k + i.total),
        ),
  );

  double get mealTotal => _ssrTotal(SsrKind.meal);

  double get baggageTotal => _ssrTotal(SsrKind.baggage);

  /// Grand total of every add-on across all passengers.
  double get total => seatTotal + mealTotal + baggageTotal;

  /// Per-kind totals for the fare summary, zero-value kinds dropped.
  Map<String, double> get breakdown => {
    if (seatTotal > 0) 'Seat': seatTotal,
    if (mealTotal > 0) 'Meal': mealTotal,
    if (baggageTotal > 0) 'Baggage': baggageTotal,
  };

  /// How many passengers have chosen on this leg, over the total — the
  /// "1/1" badge on a segment tab.
  String seatCountLabel(String segmentId, int paxCount) {
    final total = paxCount < 1 ? 1 : paxCount;
    var done = 0;
    for (var i = 0; i < total; i++) {
      if (seatFor(i, segmentId) != null) done++;
    }
    return '$done/$total';
  }

  String ssrCountLabel(SsrKind kind, String segmentId, int paxCount) {
    final total = paxCount < 1 ? 1 : paxCount;
    var done = 0;
    for (var i = 0; i < total; i++) {
      if (ssrChosen(kind, i, segmentId) != null) done++;
    }
    return '$done/$total';
  }

  // ---------------------------------------------------------------------
  // Supplier payload
  // ---------------------------------------------------------------------

  /// The `ssr*Infos` fields to merge into one traveller's booking entry.
  ///
  /// [sellableSegments] drops bags bought against a connecting leg the
  /// supplier will not sell them on — see [AddOnSegment.baggageSellable].
  Map<String, dynamic> ssrForTraveller(
    int paxIndex, {
    Set<String>? sellableSegments,
  }) {
    final seatInfos = [
      for (final entry in (seats[paxIndex] ?? {}).entries)
        {'key': entry.key, 'code': entry.value.code},
    ];

    // A quantity of N is N separate SSR entries — the supplier has no qty
    // field.
    List<Map<String, String>> expand(SsrKind kind) => [
      for (final bySeg in (_mapFor(kind)[paxIndex] ?? {}).entries)
        for (final choice in bySeg.value.values)
          for (var i = 0; i < choice.qty; i++)
            {'key': bySeg.key, 'code': choice.code},
    ];

    final mealInfos = expand(SsrKind.meal);
    final bagInfos = expand(SsrKind.baggage)
        .where(
          (b) =>
              sellableSegments == null || sellableSegments.contains(b['key']),
        )
        .toList();

    return {
      if (seatInfos.isNotEmpty) 'ssrSeatInfos': seatInfos,
      if (mealInfos.isNotEmpty) 'ssrMealInfos': mealInfos,
      if (bagInfos.isNotEmpty) 'ssrBaggageInfos': bagInfos,
    };
  }
}

enum SsrKind { meal, baggage }

int? _toInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

double? _toDouble(Object? value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
