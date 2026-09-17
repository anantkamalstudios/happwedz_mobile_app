/// "Flight Add On" — seats, meals and baggage, chosen per passenger per leg.
///
/// A port of the web's `components/FlightAddOn.jsx`. The web lays the deck out
/// nose-left with rows running across the page; a phone has no room for that,
/// so the deck here scrolls horizontally with the same nose/aisle/tail
/// structure and the same price-band colouring.
///
/// Whether each kind is offered at all comes from the fare's own conditions
/// (`fsc.issi` / `ismi` / `isbi`), exactly as on the web — a fare that forbids
/// seat selection simply has no seat block.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/addon_models.dart';
import '../../models/booking_models.dart';
import 'booking_widgets.dart';

class FlightAddOnStep extends StatefulWidget {
  const FlightAddOnStep({
    super.key,
    required this.api,
    required this.review,
    required this.passengerLabels,
    required this.addOns,
    required this.onChanged,
  });

  final HoneymoonApi api;
  final FlightReview review;

  /// "ADULT-1", "CHILD-1" … in booking order.
  final List<String> passengerLabels;

  final FlightAddOns addOns;
  final VoidCallback onChanged;

  @override
  State<FlightAddOnStep> createState() => _FlightAddOnStepState();
}

class _FlightAddOnStepState extends State<FlightAddOnStep> {
  late final List<AddOnSegment> _segments;
  late final List<AddOnSegment> _bagSegments;

  SeatMapResult? _seatMap;
  bool _loadingSeats = false;

  int _activePax = 0;
  String _seatSegment = '';
  String _mealSegment = '';
  String _bagSegment = '';

  /// Which legend bands are highlighted. Empty means "show all".
  final Set<int> _bandFilter = {};

  bool get _allowSeat => widget.review.conditions.seatSelectable;
  bool get _allowMeal => widget.review.conditions.mealSelectable;
  bool get _allowBaggage => widget.review.conditions.baggageSelectable;

  int get _paxCount =>
      widget.passengerLabels.isEmpty ? 1 : widget.passengerLabels.length;

  @override
  void initState() {
    super.initState();
    _segments = AddOnSegment.fromReview(widget.review.raw);
    _bagSegments = _segments.where((s) => s.baggageSellable).toList();
    _seatSegment = _segments.isEmpty ? '' : _segments.first.id;
    _mealSegment = _seatSegment;
    _bagSegment = _bagSegments.isEmpty ? '' : _bagSegments.first.id;
    if (_allowSeat) _loadSeatMap();
  }

  Future<void> _loadSeatMap() async {
    final bookingId = widget.review.bookingId;
    if (bookingId.isEmpty) return;
    setState(() => _loadingSeats = true);
    final result = await widget.api.fetchSeatMap(bookingId);
    if (!mounted) return;
    setState(() {
      _seatMap = result;
      _loadingSeats = false;
    });
  }

  void _mutate(void Function() change) {
    setState(change);
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    if (_segments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: InfoBanner(
          icon: Icons.info_outline_rounded,
          message: 'No add-ons are available for this itinerary.',
        ),
      );
    }

    if (!_allowSeat && !_allowMeal && !_allowBaggage) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: InfoBanner(
          icon: Icons.info_outline_rounded,
          message:
              'This fare does not allow seats, meals or extra baggage to be '
              'bought in advance.',
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (_paxCount > 1) ...[
          _PassengerTabs(
            labels: widget.passengerLabels,
            active: _activePax,
            onPick: (i) => setState(() => _activePax = i),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (_allowSeat) _seatBlock(),
        if (_allowMeal) _mealBlock(),
        if (_allowBaggage && _bagSegments.isNotEmpty) _baggageBlock(),
        const SizedBox(height: AppSpacing.md),
        _totalsCard(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Seats
  // -------------------------------------------------------------------------

  Widget _seatBlock() {
    final deck = _seatMap?.bySegment[_seatSegment];
    final bands = deck?.priceBands ?? const <PriceBand>[];

    return _AddOnBlock(
      icon: Icons.airline_seat_recline_normal_rounded,
      title: 'SELECT SEAT',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SegmentTabs(
            segments: _segments,
            active: _seatSegment,
            countFor: (id) => widget.addOns.seatCountLabel(id, _paxCount),
            onPick: (id) => setState(() {
              _seatSegment = id;
              _bandFilter.clear();
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loadingSeats)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2.4)),
            )
          else if (_seatMap?.error != null)
            _muted(_seatMap!.error!)
          else if (deck == null)
            _muted('Seat selection is not available for this leg.')
          else ...[
            _seatLegend(bands),
            const SizedBox(height: AppSpacing.md),
            _SeatDeck(
              deck: deck,
              bands: bands,
              bandFilter: _bandFilter,
              selectedCode: widget.addOns.seatFor(_activePax, _seatSegment)?.code,
              isTakenByOther: (seatNo) =>
                  widget.addOns.isTakenByOther(_activePax, _seatSegment, seatNo),
              onPick: (seat) => _mutate(
                () => widget.addOns.toggleSeat(_activePax, _seatSegment, seat),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Total Seat Fee: ${money(widget.addOns.seatTotal)}',
              style: AppText.bodyStrong,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Conditions apply. We will try our best to accommodate your seat '
              'preferences, however due to operational considerations we cannot '
              'guarantee this selection. The seat map shown may not be an exact '
              'replica of the flight layout.',
              style: AppText.caption.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _seatLegend(List<PriceBand> bands) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (var i = 0; i < bands.length; i++)
          _LegendChip(
            colour: _bandColour(i),
            label: _bandLabel(bands[i]),
            selected: _bandFilter.contains(i),
            onTap: () => setState(() {
              if (!_bandFilter.remove(i)) _bandFilter.add(i);
            }),
          ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Meals and baggage
  // -------------------------------------------------------------------------

  Widget _mealBlock() {
    final segment = _segmentById(_segments, _mealSegment);
    return _ssrBlock(
      kind: SsrKind.meal,
      icon: Icons.restaurant_rounded,
      title: 'SELECT MEAL',
      segments: _segments,
      active: _mealSegment,
      onPick: (id) => setState(() => _mealSegment = id),
      options: segment?.meals ?? const [],
      total: widget.addOns.mealTotal,
      totalLabel: 'Total Meal Fee',
      emptyLabel: 'meal',
    );
  }

  Widget _baggageBlock() {
    final segment = _segmentById(_bagSegments, _bagSegment);
    return _ssrBlock(
      kind: SsrKind.baggage,
      icon: Icons.luggage_rounded,
      title: 'SELECT BAGGAGE',
      segments: _bagSegments,
      active: _bagSegment,
      onPick: (id) => setState(() => _bagSegment = id),
      options: segment?.baggage ?? const [],
      total: widget.addOns.baggageTotal,
      totalLabel: 'Total Baggage Fee',
      emptyLabel: 'baggage',
      // Only shown when some legs were filtered out as non-sellable.
      note: _segments.length > _bagSegments.length
          ? 'Your bag is checked through to the final destination, so extra '
                'baggage is bought once and covers the whole journey.'
          : null,
    );
  }

  Widget _ssrBlock({
    required SsrKind kind,
    required IconData icon,
    required String title,
    required List<AddOnSegment> segments,
    required String active,
    required ValueChanged<String> onPick,
    required List<SsrOption> options,
    required double total,
    required String totalLabel,
    required String emptyLabel,
    String? note,
  }) {
    return _AddOnBlock(
      icon: icon,
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (note != null) ...[
            InfoBanner(icon: Icons.info_outline_rounded, message: note),
            const SizedBox(height: AppSpacing.md),
          ],
          _SegmentTabs(
            segments: segments,
            active: active,
            countFor: (id) =>
                widget.addOns.ssrCountLabel(kind, id, _paxCount),
            onPick: onPick,
          ),
          const SizedBox(height: AppSpacing.md),
          if (options.isEmpty)
            _muted('No $emptyLabel options on this leg.')
          else
            for (final option in options)
              _SsrTile(
                option: option,
                qty: widget.addOns.ssrQty(kind, _activePax, active, option.code),
                onChanged: (qty) => _mutate(
                  () => widget.addOns.setSsrQty(
                    kind,
                    _activePax,
                    active,
                    option,
                    qty,
                  ),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          Text('$totalLabel: ${money(total)}', style: AppText.bodyStrong),
        ],
      ),
    );
  }

  Widget _totalsCard() {
    final breakdown = widget.addOns.breakdown;
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          for (final entry in breakdown.entries)
            FareRow(line: FareLine(entry.key, entry.value)),
          const Divider(height: AppSpacing.lg),
          FareRow(line: FareLine('Add-ons total', widget.addOns.total)),
        ],
      ),
    );
  }

  AddOnSegment? _segmentById(List<AddOnSegment> list, String id) {
    for (final segment in list) {
      if (segment.id == id) return segment;
    }
    return list.isEmpty ? null : list.first;
  }

  Widget _muted(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(
      text,
      style: AppText.bodySm.copyWith(color: AppColors.textTertiary),
    ),
  );
}

// =============================================================
// Pieces
// =============================================================

String money(double amount) => '₹${amount.toStringAsFixed(2)}';

String _bandLabel(PriceBand band) {
  if (band.max == 0) return money(0);
  if (band.min == band.max) return money(band.min);
  return '${money(band.min)} – ${money(band.max)}';
}

/// Band colours, free first. Deliberately not the brand pink: pink is the
/// "your seat" state, so the bands have to read as something else.
const List<Color> _bandColours = [
  Color(0xFFD7F5DF),
  Color(0xFFDCEBFB),
  Color(0xFFE0DEF7),
  Color(0xFFFBEBCF),
  Color(0xFFF8D8E4),
];

Color _bandColour(int index) =>
    _bandColours[index < 0 ? 0 : index % _bandColours.length];

int _bandOf(double amount, List<PriceBand> bands) {
  for (var i = 0; i < bands.length; i++) {
    if (bands[i].contains(amount)) return i;
  }
  return 0;
}

class _AddOnBlock extends StatelessWidget {
  const _AddOnBlock({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              color: AppColors.blush,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _PassengerTabs extends StatelessWidget {
  const _PassengerTabs({
    required this.labels,
    required this.active,
    required this.onPick,
  });

  final List<String> labels;
  final int active;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) => _Chip(
          label: labels[i],
          selected: i == active,
          onTap: () => onPick(i),
        ),
      ),
    );
  }
}

class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs({
    required this.segments,
    required this.active,
    required this.countFor,
    required this.onPick,
  });

  final List<AddOnSegment> segments;
  final String active;
  final String Function(String) countFor;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: segments.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final segment = segments[i];
          final selected = segment.id == active;
          return Pressable(
            onTap: () => onPick(segment.id),
            borderRadius: AppRadii.rMd,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.blush : AppColors.surface,
                borderRadius: AppRadii.rMd,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    segment.label,
                    style: AppText.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? AppColors.primaryDeep
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    countFor(segment.id),
                    style: AppText.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({
    required this.colour,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color colour;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

/// The deck, drawn nose-left like the web: seat letters run down the page and
/// row numbers across it, with the aisle as a gap in the middle.
class _SeatDeck extends StatelessWidget {
  const _SeatDeck({
    required this.deck,
    required this.bands,
    required this.bandFilter,
    required this.selectedCode,
    required this.isTakenByOther,
    required this.onPick,
  });

  final SegmentSeatMap deck;
  final List<PriceBand> bands;
  final Set<int> bandFilter;
  final String? selectedCode;
  final bool Function(String seatNo) isTakenByOther;
  final ValueChanged<SeatCell> onPick;

  @override
  Widget build(BuildContext context) {
    final used = deck.usedColumns;
    final aisle = deck.aisleColumn;
    // Rendered nose-left, so the highest column letter sits at the top.
    final display = used.reversed.toList();
    final rows = [for (var r = 1; r <= deck.rows; r++) r];

    List<Widget> rowsFor(Iterable<int> columns) => [
      for (final column in columns)
        _SeatRow(
          label: deck.letterFor(column),
          children: [
            for (final row in rows)
              _seatCell(deck.at(row, column)),
          ],
        ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadii.rMd,
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rowsFor(display.where((c) => aisle == null || c > aisle)),
            // The aisle: row numbers, no seats.
            _SeatRow(
              label: '',
              children: [
                for (final row in rows)
                  SizedBox(
                    width: 34,
                    height: 20,
                    child: Center(
                      child: Text(
                        '$row',
                        style: AppText.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            ...rowsFor(display.where((c) => aisle != null && c < aisle)),
          ],
        ),
      ),
    );
  }

  Widget _seatCell(SeatCell? seat) {
    if (seat == null) return const SizedBox(width: 34, height: 30);

    final mine = seat.seatNo == selectedCode;
    final taken = isTakenByOther(seat.seatNo);
    final disabled = seat.isBooked || taken;
    final band = _bandOf(seat.amount, bands);
    final dimmed = bandFilter.isNotEmpty && !bandFilter.contains(band);

    final Color background;
    if (mine) {
      background = AppColors.primary;
    } else if (disabled) {
      background = AppColors.shimmerBase;
    } else {
      background = _bandColour(band);
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: Tooltip(
          message:
              '${seat.seatNo} · ${seat.amount > 0 ? money(seat.amount) : 'Free'}'
              '${seat.isLegroom ? ' · Extra legroom' : ''}',
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: disabled ? null : () => onPick(seat),
              child: SizedBox(
                width: 30,
                height: 26,
                child: Center(
                  child: Text(
                    seat.seatNo,
                    style: AppText.caption.copyWith(
                      fontSize: 9,
                      color: mine
                          ? AppColors.textOnPrimary
                          : disabled
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontWeight: mine ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatRow extends StatelessWidget {
  const _SeatRow({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(
            label,
            style: AppText.caption.copyWith(color: AppColors.textTertiary),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// One meal or baggage option with a − 0 + stepper.
///
/// The supplier accepts at most one of each per passenger per leg, so the
/// stepper caps at 1 — the same limit the web enforces.
class _SsrTile extends StatelessWidget {
  const _SsrTile({
    required this.option,
    required this.qty,
    required this.onChanged,
  });

  final SsrOption option;
  final int qty;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadii.rMd,
        border: Border.all(
          color: qty > 0 ? AppColors.primary : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.desc.isEmpty ? option.code : option.desc,
                  style: AppText.bodySm,
                ),
                const SizedBox(height: 2),
                Text(
                  option.isFree ? 'FREE' : money(option.amount),
                  style: AppText.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: option.isFree
                        ? AppColors.successDark
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          _StepperButton(
            icon: Icons.remove_rounded,
            enabled: qty > 0,
            onTap: () => onChanged(qty - 1),
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$qty',
              textAlign: TextAlign.center,
              style: AppText.bodyStrong,
            ),
          ),
          _StepperButton(
            icon: Icons.add_rounded,
            enabled: qty < 1,
            onTap: () => onChanged(qty + 1),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: enabled ? onTap : null,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.primary : AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}
