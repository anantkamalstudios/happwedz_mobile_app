/// Flight results building blocks shared by the one-way, round-trip and
/// multi-city screens — each a port of one web component:
///
///  * [FareRulesPanel]            ← `components/FareRulesPanel.jsx`
///  * [showFlightDetailsSheet]    ← `components/FlightDetailsPanel.jsx`
///  * [showFareCompareSheet]      ← `components/FareCompare.jsx`
///  * [FareDateStrip]             ← `components/FareDateStrip.jsx`
///  * [showFlightShareSheet]      ← `components/ShareBy.jsx`
///  * [SpecialReturnStrip]        ← the round-trip "Return Special" tiles
///  * [FlightFareOptionTile]      ← a fare row on a results card
///
/// The web lays these out as inline drawers under a card; on a phone they are
/// bottom sheets, but the content, labels and fallbacks are the web's.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../data/flight_filters.dart';
import '../../data/honeymoon_api.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import 'honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

/// `₹6,835.52` — the web prints every flight amount with paise
/// (`toLocaleString('en-IN', { minimumFractionDigits: 2 })`).
String formatFlightFare(double amount) {
  final negative = amount < 0;
  final fixed = amount.abs().toStringAsFixed(2);
  final whole = fixed.split('.').first;
  final paise = fixed.split('.').last;
  final grouped = formatPrice(double.parse(whole), symbol: '');
  return '${negative ? '-' : ''}₹$grouped.$paise';
}

const List<String> _weekdays = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];
const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Aug 28, Fri, 08:15".
String flightStamp(DateTime? d) {
  if (d == null) return '';
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${_months[d.month - 1]} ${d.day}, ${_weekdays[d.weekday - 1]}, $hh:$mm';
}

/// "Fri, Aug 28th 2026".
String flightLongDate(DateTime? d) {
  if (d == null) return '';
  final n = d.day;
  final ord = n % 10 == 1 && n != 11
      ? 'st'
      : n % 10 == 2 && n != 12
      ? 'nd'
      : n % 10 == 3 && n != 13
      ? 'rd'
      : 'th';
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} $n$ord ${d.year}';
}

/// "Aug 27, 2026 5:11 PM" — the web's created-on / booking-time stamp
/// (`createdStamp` in `BookingConfirmation.jsx`, `bookingStamp` in
/// `TicketDocument.jsx`). Null prints the current time, as the web does.
String flightBookingStamp(DateTime? value) {
  final d = value ?? DateTime.now();
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '${_months[d.month - 1]} ${d.day}, ${d.year} $h:'
      '${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
}

/// "2h 05m".
String flightMinutes(int minutes) =>
    '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

const Map<String, String> _paxLabel = {
  'ADULT': 'Adult',
  'CHILD': 'Child',
  'INFANT': 'Infant',
};

Map<String, int> _paxEntries(PaxCounts pax) => {
  'ADULT': pax.adults,
  'CHILD': pax.children,
  'INFANT': pax.infants,
};

// ---------------------------------------------------------------------------
// Fare-rule loading
// ---------------------------------------------------------------------------

/// Fetches each fare's rules once per results screen.
///
/// The web makes every priceId a one-shot for the same reason: the backend's
/// shared rate limiter allows 30 requests a minute, and re-asking on every
/// open of a drawer would trip it. A failed fetch is forgotten so the next
/// open can retry, as on the web.
class FareRuleLoader {
  FareRuleLoader(this.api, {this.flowType = 'SEARCH'});

  final HoneymoonApi api;
  final String flowType;
  final Map<String, Future<FareRuleSet>> _cache = {};

  Future<FareRuleSet> load(String id) {
    return _cache.putIfAbsent(id, () {
      final future = api.fetchFareRules(id, flowType);
      future.catchError((Object _) {
        _cache.remove(id);
        return const FareRuleSet();
      });
      return future;
    });
  }
}

// ---------------------------------------------------------------------------
// Fare rules panel
// ---------------------------------------------------------------------------

/// Route tabs, a tab per fee type, and each band's time frame against its
/// charge and policy — or the airline's free-text "Detailed Rules".
class FareRulesPanel extends StatefulWidget {
  const FareRulesPanel({super.key, required this.rules});

  final FareRuleSet rules;

  @override
  State<FareRulesPanel> createState() => _FareRulesPanelState();
}

class _FareRulesPanelState extends State<FareRulesPanel> {
  int _route = 0;
  String? _type;
  bool _detailed = false;

  @override
  Widget build(BuildContext context) {
    final routes = widget.rules.routes;
    if (routes.isEmpty) {
      return Text('No fare rules available.', style: AppText.bodySm);
    }

    final route = routes[_route.clamp(0, routes.length - 1)];
    final available = [
      for (final t in kFareRuleTypes)
        if (route.slabsOf(t.key).isNotEmpty) t,
    ];
    final activeType = available.any((t) => t.key == _type)
        ? _type!
        : (available.isEmpty ? null : available.first.key);
    final slabs = activeType == null
        ? const <FareRuleSlab>[]
        : route.slabsOf(activeType);
    final misc = route.miscLines;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (routes.length > 1) ...[
          _ChipRow(
            labels: [for (final r in routes) r.key],
            selected: _route,
            onSelect: (i) => setState(() {
              _route = i;
              _detailed = false;
            }),
          ),
          const SizedBox(height: AppSpacing.sm),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(route.key, style: AppText.labelSm),
          ),

        if (misc.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton.text(
              label: _detailed ? 'Fee table' : 'Detailed Rules',
              size: PremiumButtonSize.small,
              onPressed: () => setState(() => _detailed = !_detailed),
            ),
          ),

        if (_detailed && misc.isNotEmpty)
          for (final line in misc)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(line, style: AppText.bodySm),
            )
        else if (available.isEmpty)
          Text(
            misc.isEmpty
                ? 'No fee bands were returned for this fare.'
                : 'This airline publishes its rules as text — see Detailed '
                      'Rules.',
            style: AppText.bodySm,
          )
        else ...[
          Text(
            '* To view charges, tap a fee type below.',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ChipRow(
            labels: [
              for (final t in available)
                t.note == null ? t.label : '${t.label} ${t.note}',
            ],
            selected: available.indexWhere((t) => t.key == activeType),
            onSelect: (i) => setState(() => _type = available[i].key),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Time frame\n(from first departure)',
                  style: AppText.caption,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(flex: 3, child: Text('Charge', style: AppText.caption)),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          for (final slab in slabs) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(slab.timeFrame, style: AppText.bodySm),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (slab.hasFee)
                        Text(
                          '${formatFlightFare(slab.amount ?? 0)}'
                          '${slab.additionalFee != null ? ' + ${formatFlightFare(slab.additionalFee!)}' : ''}',
                          style: AppText.bodyStrong,
                        ),
                      for (final line in slab.policyLines)
                        Text(line, style: AppText.caption),
                      if (!slab.hasFee && slab.policyLines.isEmpty)
                        Text('As per airline policy.', style: AppText.caption),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg, color: AppColors.divider),
          ],
        ],
        const SizedBox(height: AppSpacing.sm),
        const FareRuleNotes(),
      ],
    );
  }
}

/// The four notes the web prints under every rules table.
class FareRuleNotes extends StatelessWidget {
  const FareRuleNotes({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final note in kFareRuleNotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text('• $note', style: AppText.caption),
          ),
      ],
    );
  }
}

/// Rules that load on first build, with the web's loading and failure copy.
class FareRulesLoaderView extends StatelessWidget {
  const FareRulesLoaderView({super.key, required this.future});

  final Future<FareRuleSet> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FareRuleSet>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Row(
              children: [
                const AppLoader(size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text('Loading fare rules…', style: AppText.bodySm),
              ],
            ),
          );
        }
        if (snap.hasError) {
          return Text(
            'Fare rules unavailable. Please contact support.',
            style: AppText.bodySm,
          );
        }
        return FareRulesPanel(rules: snap.data ?? const FareRuleSet());
      },
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: AppSpacing.sm),
            _Pill(
              label: labels[i],
              active: i == selected,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.pinkSurface : AppColors.surface,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppText.buttonSm.copyWith(
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flight details — FlightDetailsPanel.jsx
// ---------------------------------------------------------------------------

/// Flight Details / Fare Details / Fare Rules for one trip at one fare.
///
/// Fare rules are the only tab that costs a request, so — as on the web — they
/// load when that tab is first opened.
Future<void> showFlightDetailsSheet(
  BuildContext context, {
  required FlightResult flight,
  required PaxCounts pax,
  required FareRuleLoader rules,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: '${flight.fromCode} → ${flight.toCode}',
    child: _FlightDetailsBody(flight: flight, pax: pax, rules: rules),
  );
}

class _FlightDetailsBody extends StatefulWidget {
  const _FlightDetailsBody({
    required this.flight,
    required this.pax,
    required this.rules,
  });

  final FlightResult flight;
  final PaxCounts pax;
  final FareRuleLoader rules;

  @override
  State<_FlightDetailsBody> createState() => _FlightDetailsBodyState();
}

class _FlightDetailsBodyState extends State<_FlightDetailsBody> {
  int _tab = 0;
  Future<FareRuleSet>? _rules;

  dynamic get _fare => widget.flight.selectedFare;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ChipRow(
          labels: const ['Flight Details', 'Fare Details', 'Fare Rules'],
          selected: _tab,
          onSelect: (i) => setState(() {
            _tab = i;
            if (i == 2 && widget.flight.id.isNotEmpty) {
              _rules ??= widget.rules.load(widget.flight.id);
            }
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        switch (_tab) {
          0 => _flightTab(),
          1 => _fareTab(),
          _ =>
            _rules == null
                ? Text(
                    'Fare rules unavailable. Please contact support.',
                    style: AppText.bodySm,
                  )
                : FareRulesLoaderView(future: _rules!),
        },
      ],
    );
  }

  Widget _flightTab() {
    final segs = widget.flight.segments;
    final adult = digPath(_fare, ['fd', 'ADULT']);
    final paxTypes = _paxEntries(widget.pax).entries.where((e) => e.value > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${asString(digPath(segs.firstOrNull, ['da', 'city']), fallback: widget.flight.fromCode)}'
          ' → '
          '${asString(digPath(segs.lastOrNull, ['aa', 'city']), fallback: widget.flight.toCode)}',
          style: AppText.cardTitle,
        ),
        Text(flightLongDate(widget.flight.departure), style: AppText.caption),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < segs.length; i++) ...[
          _SegmentBlock(
            segment: segs[i],
            cabin: asString(readKey(adult, 'cc'), fallback: 'ECONOMY'),
            seatsLeft: fareSeatsLeft(_fare),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Baggage information', style: AppText.labelSm),
          const SizedBox(height: AppSpacing.xs),
          _BaggageTable(
            rows: [
              for (final e in paxTypes)
                (
                  type: _paxLabel[e.key]!,
                  checkIn: fareCheckinBaggage(_fare, e.key),
                  cabin: fareCabinBaggage(_fare, e.key),
                ),
            ],
          ),
          if (i < segs.length - 1)
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.blush,
                borderRadius: AppRadii.rMd,
              ),
              child: Text(
                'Require to change plane'
                '${asInt(readKey(segs[i], 'cT')) > 0 ? ' · Layover time ${flightMinutes(asInt(readKey(segs[i], 'cT')))}' : ''}',
                style: AppText.labelSm.copyWith(color: AppColors.primaryDeep),
              ),
            )
          else
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  Widget _fareTab() {
    final rows = <Widget>[];
    double total = 0;
    for (final e in _paxEntries(widget.pax).entries) {
      if (e.value <= 0) continue;
      final fd = digPath(_fare, ['fd', e.key]);
      if (fd == null) continue;
      final base = asDouble(digPath(fd, ['fC', 'BF']));
      final taxes = asDouble(digPath(fd, ['fC', 'TAF']));
      total += asDouble(digPath(fd, ['fC', 'TF'])) * e.value;
      final cb = asString(readKey(fd, 'cB'));
      rows.addAll([
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'Fare details for ${_paxLabel[e.key]}${cb.isEmpty ? '' : ' (CB: $cb)'}',
            style: AppText.labelSm,
          ),
        ),
        _fareRow('Base price', base, e.value),
        _fareRow('Taxes and fees', taxes, e.value),
        const Divider(height: AppSpacing.lg, color: AppColors.divider),
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...rows,
        Row(
          children: [
            Expanded(child: Text('Total', style: AppText.bodyStrong)),
            Text(formatFlightFare(total), style: AppText.bodyStrong),
          ],
        ),
      ],
    );
  }

  Widget _fareRow(String label, double each, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(label, style: AppText.bodySm)),
          Expanded(
            flex: 3,
            child: Text(
              '${formatFlightFare(each)} x $count',
              style: AppText.caption,
            ),
          ),
          Text(formatFlightFare(each * count), style: AppText.bodySm),
        ],
      ),
    );
  }
}

class _SegmentBlock extends StatelessWidget {
  const _SegmentBlock({
    required this.segment,
    required this.cabin,
    required this.seatsLeft,
  });

  final dynamic segment;
  final String cabin;
  final int? seatsLeft;

  @override
  Widget build(BuildContext context) {
    final code = asString(digPath(segment, ['fD', 'aI', 'code']));
    final number = asString(digPath(segment, ['fD', 'fN']));
    final aircraft = asString(digPath(segment, ['fD', 'eT']));
    final duration = asInt(readKey(segment, 'duration'));

    Widget point(String key, String timeKey) {
      final place = readKey(segment, key);
      final terminal = asString(readKey(place, 'terminal'));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            flightStamp(DateTime.tryParse(asString(readKey(segment, timeKey)))),
            style: AppText.bodyStrong,
          ),
          Text(
            [
              asString(readKey(place, 'city')),
              asString(readKey(place, 'country')),
            ].where((s) => s.isNotEmpty).join(', '),
            style: AppText.bodySm,
          ),
          Text(asString(readKey(place, 'name')), style: AppText.caption),
          if (terminal.isNotEmpty) Text(terminal, style: AppText.caption),
        ],
      );
    }

    return AppCard.outlined(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (code.isNotEmpty) ...[
                AirlineLogo(code: code),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$code-$number${aircraft.isEmpty ? '' : '  ✈ $aircraft'}',
                      style: AppText.bodyStrong,
                    ),
                    Text(
                      [
                        cabin.replaceAll('_', ' '),
                        if (seatsLeft != null) '$seatsLeft seat(s) left',
                      ].join(' · '),
                      style: AppText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          point('da', 'dt'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_downward_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Non-Stop${duration > 0 ? ' · ${flightMinutes(duration)}' : ''}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          point('aa', 'at'),
        ],
      ),
    );
  }
}

class _BaggageTable extends StatelessWidget {
  const _BaggageTable({required this.rows});

  final List<({String type, String checkIn, String cabin})> rows;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
      children: [
        for (final c in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Text(c, style: head ? AppText.caption : AppText.bodySm),
          ),
      ],
    );

    return Table(
      children: [
        row(const ['Pax type', 'Check in', 'Cabin'], head: true),
        for (final r in rows)
          row([
            r.type,
            r.checkIn.isEmpty ? 'NA' : r.checkIn,
            r.cabin.isEmpty ? 'NA' : r.cabin,
          ]),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Fare compare — FareCompare.jsx
// ---------------------------------------------------------------------------

/// What the traveller did in the compare sheet: picked a fare, and whether to
/// book it straight away.
typedef FareCompareChoice = ({String fareId, bool book});

/// Every fare on a trip side by side: price, baggage, cancellation and date
/// change fees, seat charge and meals.
///
/// Cancellation and date-change fees are not in the search response; each
/// fare's rules are fetched once when the sheet opens, as the web's drawer
/// does.
Future<FareCompareChoice?> showFareCompareSheet(
  BuildContext context, {
  required FlightResult flight,
  required PaxCounts pax,
  required FareRuleLoader rules,
}) {
  return AppBottomSheet.show<FareCompareChoice>(
    context,
    title: 'Compare fares',
    child: _FareCompareBody(flight: flight, pax: pax, rules: rules),
  );
}

class _FareCompareBody extends StatefulWidget {
  const _FareCompareBody({
    required this.flight,
    required this.pax,
    required this.rules,
  });

  final FlightResult flight;
  final PaxCounts pax;
  final FareRuleLoader rules;

  @override
  State<_FareCompareBody> createState() => _FareCompareBodyState();
}

class _FareCompareBodyState extends State<_FareCompareBody> {
  late String _selected = widget.flight.id;
  late final Map<String, Future<FareRuleSet>> _rules = {
    for (final f in widget.flight.fares)
      if (asString(readKey(f, 'id')).isNotEmpty)
        asString(readKey(f, 'id')): widget.rules.load(
          asString(readKey(f, 'id')),
        ),
  };

  @override
  Widget build(BuildContext context) {
    final fares = widget.flight.fares;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Services (per pax)', style: AppText.caption),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 430,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: fares.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final fare = fares[i];
              final id = asString(readKey(fare, 'id'));
              return SizedBox(
                width: 236,
                child: _FareCompareCard(
                  fare: fare,
                  pax: widget.pax,
                  selected: id == _selected,
                  rules: _rules[id],
                  onSelect: () => setState(() => _selected = id),
                  onBook: () =>
                      Navigator.pop(context, (fareId: id, book: true)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const FareRuleNotes(),
        const SizedBox(height: AppSpacing.lg),
        PremiumButton(
          label: 'Use selected fare',
          onPressed: () =>
              Navigator.pop(context, (fareId: _selected, book: false)),
        ),
      ],
    );
  }
}

class _FareCompareCard extends StatelessWidget {
  const _FareCompareCard({
    required this.fare,
    required this.pax,
    required this.selected,
    required this.rules,
    required this.onSelect,
    required this.onBook,
  });

  final dynamic fare;
  final PaxCounts pax;
  final bool selected;
  final Future<FareRuleSet>? rules;
  final VoidCallback onSelect;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final checkIn = fareCheckinBaggage(fare);
    final cabin = fareCabinBaggage(fare);

    Widget line(IconData icon, String label, Widget value) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: Text(label, style: AppText.caption)),
            ],
          ),
          const SizedBox(height: 2),
          value,
        ],
      ),
    );

    return AppCard(
      elevated: false,
      shadow: const [],
      padding: const EdgeInsets.all(AppSpacing.md),
      border: Border.all(
        color: selected ? AppColors.primary : AppColors.divider,
        width: selected ? 1.5 : 1,
      ),
      onTap: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  fareDisplayLabel(asString(readKey(fare, 'fareIdentifier'))),
                  style: AppText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(formatFlightFare(farePrice(fare, pax)), style: AppText.price),
          const Divider(height: AppSpacing.lg, color: AppColors.divider),
          line(
            Icons.work_outline_rounded,
            'Baggage (Adult, age 12+)',
            Text(
              'Check-in: ${checkIn.isEmpty ? 'NA' : checkIn}\n'
              'Cabin: ${cabin.isEmpty ? 'NA' : cabin}',
              style: AppText.bodySm,
            ),
          ),
          Expanded(
            child: FutureBuilder<FareRuleSet>(
              future: rules,
              builder: (context, snap) {
                final loading =
                    rules != null &&
                    snap.connectionState != ConnectionState.done;
                final failed = rules == null || snap.hasError;
                final data = snap.data ?? const FareRuleSet();

                Widget policy(String type, String keyword) {
                  if (loading) {
                    return Text('Loading…', style: AppText.caption);
                  }
                  if (failed) {
                    return Text('Unavailable', style: AppText.caption);
                  }
                  final slab = data.slabsOf(type).firstOrNull;
                  final fee = slab != null && slab.hasFee
                      ? '${formatFlightFare(slab.amount ?? 0)}'
                            '${slab.additionalFee != null ? ' + ${formatFlightFare(slab.additionalFee!)}' : ''}'
                      : null;
                  final info = (slab?.cleanPolicy ?? '').isNotEmpty
                      ? slab!.cleanPolicy
                      : data.miscMatching(keyword);
                  if (fee == null && info.isEmpty) {
                    return Text('NA', style: AppText.caption);
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (fee != null) Text(fee, style: AppText.bodyStrong),
                      if (info.isNotEmpty)
                        Text(
                          info,
                          style: AppText.caption,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  );
                }

                final cancelWindow = data.windowOf('CANCELLATION');
                final changeWindow = data.windowOf('DATECHANGE');
                final seat = data.slabsOf('SEAT_CHARGEABLE').firstOrNull;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(
                        Icons.event_busy_rounded,
                        'Cancellation fee'
                        '${cancelWindow.isEmpty ? '' : ' · $cancelWindow'}',
                        policy('CANCELLATION', 'cancel|refund'),
                      ),
                      line(
                        Icons.event_repeat_rounded,
                        'Date change fee'
                        '${changeWindow.isEmpty ? '' : ' · $changeWindow'}',
                        policy('DATECHANGE', 'change|reissue|re-issue'),
                      ),
                      line(
                        Icons.event_seat_outlined,
                        'Seat charge',
                        Text(
                          loading
                              ? 'Loading…'
                              : (seat?.cleanPolicy ?? '').isNotEmpty
                              ? seat!.cleanPolicy
                              : 'NA',
                          style: AppText.bodySm,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      line(
                        Icons.restaurant_rounded,
                        'Meals',
                        Text(
                          fareMealIncluded(fare) ? 'Included' : 'Chargeable',
                          style: AppText.bodySm,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          PremiumButton(
            label: 'Book now',
            size: PremiumButtonSize.small,
            onPressed: onBook,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date strip — FareDateStrip.jsx
// ---------------------------------------------------------------------------

/// Seven days around the searched date. Picking one re-runs the search for
/// that day — the strip itself shows no prices, exactly as on the web, which
/// would otherwise cost an extra search per day.
class FareDateStrip extends StatefulWidget {
  const FareDateStrip({
    super.key,
    required this.selected,
    required this.onPick,
    this.pending,
    this.visibleDays = 7,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  /// The day currently being re-searched, shown as "Loading…".
  final DateTime? pending;
  final int visibleDays;

  @override
  State<FareDateStrip> createState() => _FareDateStripState();
}

class _FareDateStripState extends State<FareDateStrip> {
  int _offset = 0;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = _day(now);
    final anchor = _day(widget.selected);

    // Centred on the searched day but never opening on a past one — the API
    // rejects past travel dates.
    var start = anchor.add(Duration(days: _offset - widget.visibleDays ~/ 2));
    if (start.isBefore(today)) start = today;
    final days = [
      for (var i = 0; i < widget.visibleDays; i++) start.add(Duration(days: i)),
    ];
    final canGoBack = start.isAfter(today);

    return SizedBox(
      height: 58,
      child: Row(
        children: [
          IconButton(
            onPressed: canGoBack
                ? () => setState(() => _offset -= widget.visibleDays)
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
            tooltip: 'Earlier dates',
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) {
                final day = days[i];
                final isSelected = day == anchor;
                final isPending =
                    widget.pending != null && _day(widget.pending!) == day;
                return Pressable(
                  onTap: isPending || isSelected
                      ? null
                      : () => widget.onPick(day),
                  borderRadius: AppRadii.rMd,
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.pinkSurface
                          : AppColors.surface,
                      borderRadius: AppRadii.rMd,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${_weekdays[day.weekday - 1]}, '
                          '${_months[day.month - 1]} ${day.day}',
                          style: AppText.labelSm.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          isPending ? 'Loading…' : 'Fetch Fare',
                          style: AppText.caption,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _offset += widget.visibleDays),
            icon: const Icon(Icons.chevron_right_rounded),
            tooltip: 'Later dates',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Share — ShareBy.jsx
// ---------------------------------------------------------------------------

/// "Flights BOM → DEL on 2026-10-01 — 34 options", the web's share summary.
String flightShareSummary({
  required String from,
  required String to,
  DateTime? date,
  int resultCount = 0,
}) =>
    'Flights $from → $to'
    '${date == null ? '' : ' on ${apiDateString(date)}'}'
    '${resultCount > 0 ? ' — $resultCount option${resultCount > 1 ? 's' : ''}' : ''}';

/// `yyyy-MM-dd`, as the web's summary prints the search date.
String apiDateString(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// WhatsApp, email or copy — the web's three "Share By" buttons. The web adds
/// its page URL; results on the app are not addressable, so the summary is
/// shared on its own.
Future<void> showFlightShareSheet(BuildContext context, String summary) {
  Future<void> open(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.error(context, 'No app is available to share this.');
    }
  }

  return AppBottomSheet.show<void>(
    context,
    title: 'Share by',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(summary, style: AppText.bodySm),
        const SizedBox(height: AppSpacing.lg),
        _ShareRow(
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          onTap: () => open(
            Uri.parse('https://wa.me/?text=${Uri.encodeComponent(summary)}'),
          ),
        ),
        _ShareRow(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          onTap: () => open(
            Uri.parse(
              'mailto:?subject=${Uri.encodeComponent(summary)}'
              '&body=${Uri.encodeComponent(summary)}',
            ),
          ),
        ),
        Builder(
          builder: (sheetContext) => _ShareRow(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: summary));
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              AppSnackbar.success(context, 'Copied to clipboard.');
            },
          ),
        ),
      ],
    ),
  );
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppText.body),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Return Special tiles
// ---------------------------------------------------------------------------

/// One tile per airline with a valid SPECIAL_RETURN pair, cheapest first.
/// Tapping a tile keeps both legs to that airline's special fares and picks
/// its cheapest pair; tapping it again clears it.
class SpecialReturnStrip extends StatelessWidget {
  const SpecialReturnStrip({
    super.key,
    required this.options,
    required this.selectedCode,
    required this.onPick,
  });

  final List<SpecialReturnOption> options;
  final String? selectedCode;
  final ValueChanged<SpecialReturnOption> onPick;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Text('Return Special', style: AppText.labelSm),
        ),
        SizedBox(
          height: 62,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            itemCount: options.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final o = options[i];
              final active = o.code == selectedCode;
              return Pressable(
                onTap: () => onPick(o),
                borderRadius: AppRadii.rMd,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.pinkSurface : AppColors.surface,
                    borderRadius: AppRadii.rMd,
                    border: Border.all(
                      color: active ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    children: [
                      AirlineLogo(code: o.code, size: 24),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(o.name, style: AppText.labelSm),
                          Text(
                            formatFlightFare(o.price),
                            style: AppText.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// One fare on a results card
// ---------------------------------------------------------------------------

/// Radio, price for the party, fare badge, check-in baggage, cabin / free meal
/// and refundability — a fare row on the web's results card.
class FlightFareOptionTile extends StatelessWidget {
  const FlightFareOptionTile({
    super.key,
    required this.fare,
    required this.pax,
    required this.selected,
    required this.onTap,
  });

  final dynamic fare;
  final PaxCounts pax;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final identifier = asString(readKey(fare, 'fareIdentifier'));
    final refundable = fareIsRefundable(fare);
    final checkIn = fareCheckinBaggage(fare);
    final cabinBag = fareCabinBaggage(fare);

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rMd,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.blush : AppColors.surface,
          borderRadius: AppRadii.rMd,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatFlightFare(farePrice(fare, pax)),
                    style: AppText.bodyStrong,
                  ),
                  const SizedBox(height: 2),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _FareBadge(identifier: identifier),
                      if (checkIn.isNotEmpty)
                        Tooltip(
                          message:
                              'Check-in $checkIn'
                              '${cabinBag.isEmpty ? '' : ' · Cabin $cabinBag'}',
                          child: MetaChip(
                            label: checkIn,
                            icon: Icons.work_outline_rounded,
                          ),
                        ),
                      Text.rich(
                        TextSpan(
                          style: AppText.caption,
                          children: [
                            TextSpan(text: '${farePrefixText(fare)}, '),
                            TextSpan(
                              text: refundable
                                  ? 'Refundable'
                                  : 'Non-Refundable',
                              style: AppText.caption.copyWith(
                                color: refundable
                                    ? AppColors.successDark
                                    : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FareBadge extends StatelessWidget {
  const _FareBadge({required this.identifier});

  final String identifier;

  @override
  Widget build(BuildContext context) {
    final upper = identifier.toUpperCase();
    final color = isNdcFare(identifier)
        ? AppColors.info
        : switch (upper) {
            'SPECIAL_RETURN' => AppColors.primaryDeep,
            'SME' || 'CORPORATE' => AppColors.info,
            'PROMO' => AppColors.warning,
            'FLEXI' => AppColors.successDark,
            _ => AppColors.successDark,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: AppRadii.rSm,
      ),
      child: Text(
        fareDisplayLabel(identifier),
        style: AppText.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Itinerary — FlightSegments.jsx
// ---------------------------------------------------------------------------

/// "01/08/2014" — the review table's date format.
String flightShortDate(DateTime? d) {
  if (d == null) return '';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// "(Adult) Check-in : 15 Kg, Cabin : 7 Kg", or empty when the fare lists
/// neither allowance.
String flightBaggageLine(dynamic fare) {
  final checkIn = fareCheckinBaggage(fare);
  final cabin = fareCabinBaggage(fare);
  if (checkIn.isEmpty && cabin.isEmpty) return '';
  return '(Adult) Check-in : ${checkIn.isEmpty ? 'NA' : checkIn}, '
      'Cabin : ${cabin.isEmpty ? 'NA' : cabin}';
}

/// One leg as the web's itinerary and review steps draw it: the route strip
/// with the journey time, then every segment — airline, flight number and
/// aircraft, both airports with city, country and terminal, the segment
/// time, cabin and refundability, the fare badge and baggage, and the
/// connection between segments.
///
/// [trip] is a `tripInfos` entry, preferably from the review response, which
/// carries the fare actually priced.
class FlightItineraryCard extends StatelessWidget {
  const FlightItineraryCard({
    super.key,
    required this.trip,
    required this.fare,
    this.title,
  });

  final Map<String, dynamic> trip;
  final dynamic fare;

  /// "Departure", "Return", "Flight 2 · DEL → GOI" …
  final String? title;

  @override
  Widget build(BuildContext context) {
    final segs = asList(readKey(trip, 'sI'));
    if (segs.isEmpty) return const SizedBox.shrink();

    final journey = segs.fold<int>(
      0,
      (n, s) => n + asInt(readKey(s, 'duration')) + asInt(readKey(s, 'cT')),
    );
    final firstCity = asString(
      digPath(segs.first, ['da', 'city']),
      fallback: asString(digPath(segs.first, ['da', 'code'])),
    );
    final lastCity = asString(
      digPath(segs.last, ['aa', 'city']),
      fallback: asString(digPath(segs.last, ['aa', 'code'])),
    );
    final cabin = asString(digPath(fare, ['fd', 'ADULT', 'cc']));
    final refundable = fareIsRefundable(fare) ? 'Refundable' : 'Non-Refundable';
    final identifier = asString(readKey(fare, 'fareIdentifier'));
    final bags = flightBaggageLine(fare);
    final firstDeparture = DateTime.tryParse(
      asString(readKey(segs.first, 'dt')),
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) Text(title!, style: AppText.overline),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$firstCity → $lastCity',
                        style: AppText.cardTitle,
                      ),
                    ),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(flightMinutes(journey), style: AppText.caption),
                  ],
                ),
                Text(
                  'on ${flightLongDate(firstDeparture)}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < segs.length; i++) ...[
                  _ItinerarySegment(
                    segment: segs[i],
                    cabin: cabin,
                    refundable: refundable,
                  ),
                  if (i < segs.length - 1)
                    _LayoverNote(minutes: asInt(readKey(segs[i], 'cT'))),
                ],
                if (identifier.isNotEmpty || bags.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (identifier.isNotEmpty)
                        _FareBadge(identifier: identifier),
                      if (bags.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.work_outline_rounded,
                              size: 13,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(child: Text(bags, style: AppText.caption)),
                          ],
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LayoverNote extends StatelessWidget {
  const _LayoverNote({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: AppRadii.rMd,
      ),
      child: Text(
        minutes > 0
            ? 'Require to change Plane · Layover Time - ${flightMinutes(minutes)}'
            : 'Require to change Plane',
        style: AppText.labelSm.copyWith(color: AppColors.primaryDeep),
      ),
    );
  }
}

class _ItinerarySegment extends StatelessWidget {
  const _ItinerarySegment({
    required this.segment,
    required this.cabin,
    required this.refundable,
  });

  final dynamic segment;
  final String cabin;
  final String refundable;

  Widget _point(String key, String timeKey, {required bool end}) {
    final place = readKey(segment, key);
    final terminal = asString(readKey(place, 'terminal'));
    final align = end ? TextAlign.end : TextAlign.start;
    return Column(
      crossAxisAlignment: end
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          flightStamp(DateTime.tryParse(asString(readKey(segment, timeKey)))),
          style: AppText.bodyStrong,
          textAlign: align,
        ),
        Text(
          [
            asString(readKey(place, 'city')),
            asString(readKey(place, 'country')),
          ].where((s) => s.isNotEmpty).join(', '),
          style: AppText.bodySm,
          textAlign: align,
        ),
        Text(
          asString(readKey(place, 'name')),
          style: AppText.caption,
          textAlign: align,
        ),
        if (terminal.isNotEmpty)
          Text(terminal, style: AppText.caption, textAlign: align),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = asString(digPath(segment, ['fD', 'aI', 'code']));
    final name = asString(digPath(segment, ['fD', 'aI', 'name']));
    final number = asString(digPath(segment, ['fD', 'fN']));
    final aircraft = asString(digPath(segment, ['fD', 'eT']));
    final duration = asInt(readKey(segment, 'duration'));
    final cabinText = cabin.isEmpty
        ? ''
        : '${cabin[0]}${cabin.substring(1).toLowerCase()}, ';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (code.isNotEmpty) ...[
              AirlineLogo(code: code, size: 26),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name.isEmpty ? code : name, style: AppText.bodyStrong),
                  Text(
                    aircraft.isEmpty
                        ? '$code-$number'
                        : '$code-$number  ✈-$aircraft',
                    style: AppText.caption,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(flightMinutes(duration), style: AppText.labelSm),
                Text('$cabinText$refundable', style: AppText.caption),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _point('da', 'dt', end: false)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Column(
                children: [
                  Text('Non-Stop', style: AppText.caption),
                  const Icon(
                    Icons.arrow_right_alt_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
            Expanded(child: _point('aa', 'at', end: true)),
          ],
        ),
      ],
    );
  }
}
