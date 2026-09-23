/// Multi-city flight results — one flight chosen per leg, booked together.
///
/// TripJack answers a multi-city search in two shapes and they behave very
/// differently (see [MultiCitySearchResult]):
///
///  * **Per-route** — a bucket per leg, each with its own priceId. The screen
///    shows a leg selector, remembers the choice for every leg, and only
///    unlocks Continue once each served leg has one.
///  * **COMBO** — one combined itinerary covering the whole journey on a single
///    priceId. There is nothing to choose per leg, so the screen collapses to a
///    plain list and picking an option books everything.
///
/// The web renders the legs as side-by-side columns, which does not fit a
/// phone. A leg selector with a running total is the mobile equivalent: the
/// traveller still sees what is chosen and what is outstanding without losing
/// the per-leg structure.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../main.dart' show requireAuthentication;
import '../data/flight_filters.dart';
import '../data/honeymoon_api.dart';
import '../models/booking_models.dart';
import '../models/honeymoon_models.dart';
import 'booking/booking_widgets.dart';
import 'booking/flight_booking_page.dart';
import 'widgets/flight_filter_sheet.dart';
import 'widgets/flight_widgets.dart';
import 'widgets/honeymoon_widgets.dart';
import '../models/flight_models.dart';

class MultiCityResultsPage extends StatefulWidget {
  const MultiCityResultsPage({
    super.key,
    required this.api,
    required this.legs,
    required this.results,
    required this.adults,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
    this.paxType = 'REGULAR',
  });

  final HoneymoonApi api;

  /// The legs as requested, which name the buckets in [results].
  final List<FlightLeg> legs;
  final MultiCitySearchResult results;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;

  /// The fare type searched for — decides whether a document id is asked for
  /// on the traveller step.
  final String paxType;

  @override
  State<MultiCityResultsPage> createState() => _MultiCityResultsPageState();
}

class _MultiCityResultsPageState extends State<MultiCityResultsPage> {
  /// Route index → the itinerary chosen for it.
  final Map<int, FlightResult> _selected = {};

  int _activeRoute = 0;

  /// Filters and sort are per leg: each bucket is its own result set with its
  /// own carriers and price band, exactly as on the single-leg screen.
  final Map<int, FlightFilters> _filters = {};
  final Map<int, FlightSort> _sorts = {};

  bool _submitting = false;

  /// Fare rules for the details sheet, fetched once per fare.
  late final FareRuleLoader _rules = FareRuleLoader(widget.api);

  @override
  void initState() {
    super.initState();
    _activeRoute = widget.results.bookableRoutes.firstOrNull ?? 0;
  }

  PaxCounts get _pax => PaxCounts(
    adults: widget.adults,
    children: widget.children,
    infants: widget.infants,
  );

  bool get _isCombo => widget.results.isCombo;

  List<int> get _routes => widget.results.bookableRoutes;

  FlightFilters _filterFor(int route) => _filters[route] ?? FlightFilters.empty;

  FlightSort _sortFor(int route) => _sorts[route] ?? FlightSort.price;

  List<FlightResult> _sourceFor(int route) => widget.results.forRoute(route);

  List<FlightResult> _visibleFor(int route) => sortFlights(
    filterFlights(_sourceFor(route), _filterFor(route), pax: _pax),
    _sortFor(route),
    _pax,
  );

  /// A leg's own from/to, used for headings and for "hide nearby airports".
  FlightLeg? _legFor(int route) =>
      route < widget.legs.length ? widget.legs[route] : null;

  // -------------------------------------------------------------------------
  // Selection
  // -------------------------------------------------------------------------

  /// The nearest earlier leg that has a flight chosen.
  FlightResult? _previousChoice(int route) {
    for (final r in _routes.reversed) {
      if (r < route && _selected[r] != null) return _selected[r];
    }
    return null;
  }

  /// The nearest later leg that has a flight chosen.
  FlightResult? _nextChoice(int route) {
    for (final r in _routes) {
      if (r > route && _selected[r] != null) return _selected[r];
    }
    return null;
  }

  /// Why [flight] cannot be picked on [route] given the other legs already
  /// chosen, or null. Combined (COMBO) fares cover every leg themselves.
  String? _unavailableReason(int route, FlightResult flight) {
    if (_isCombo) return null;
    final previous = _previousChoice(route);
    if (previous != null) {
      final reason = tripOverlapReason(previous, flight);
      if (reason != null) return reason;
    }
    final next = _nextChoice(route);
    if (next != null && tripOverlapReason(flight, next) != null) {
      return 'Lands after your next flight leaves — change that flight first';
    }
    return null;
  }

  /// Tapping the already-selected itinerary clears it, matching the website.
  ///
  /// A flight that leaves before the previous leg lands is refused here,
  /// before review, with the reason on the card — the supplier would refuse
  /// the pair anyway (errCode 1019).
  void _toggle(int route, FlightResult flight) {
    if (_selected[route]?.id != flight.id) {
      final reason = _unavailableReason(route, flight);
      if (reason != null) {
        AppSnackbar.info(context, reason);
        return;
      }
    }
    setState(() {
      if (_selected[route]?.id == flight.id) {
        _selected.remove(route);
      } else {
        _selected[route] = flight;
      }
    });

    // Moving straight to the next unchosen leg is the whole job on this
    // screen; making the traveller find it themselves is needless friction.
    final next = _routes.where((r) => !_selected.containsKey(r)).firstOrNull;
    if (next != null && next != route) {
      setState(() => _activeRoute = next);
    }
  }

  bool get _canContinue =>
      _routes.isNotEmpty && _routes.every(_selected.containsKey);

  /// Total across the chosen itineraries, de-duplicated by priceId.
  ///
  /// A COMBO fare repeats one priceId across every route, so summing per route
  /// would multiply the price of the journey by the number of legs.
  double get _total {
    final seen = <String, double>{};
    // BUG FIX: this summed each trip's *cheapest* fare, while the booking
    // reviews the fare in `flight.id` — so the bar could show less than the
    // traveller was then charged. The web prices the booked fare.
    for (final flight in _selected.values) {
      seen.putIfAbsent(flight.id, () => farePrice(flight.selectedFare, _pax));
    }
    return seen.values.fold<double>(0, (sum, p) => sum + p);
  }

  Future<void> _openFilterSheet() async {
    final route = _activeRoute;
    final facets = deriveFacets(_sourceFor(route), _pax);
    if (facets == null) return;

    final leg = _legFor(route);
    final result = await showFlightFilterSheet(
      context,
      facets: facets,
      current: _filterFor(route),
      flights: _sourceFor(route),
      pax: _pax,
      searchFrom: leg?.from.code,
      searchTo: leg?.to.code,
    );
    if (result != null && mounted) {
      setState(() => _filters[route] = result);
    }
  }

  Future<void> _openSortSheet() async {
    final route = _activeRoute;
    await AppBottomSheet.show(
      context,
      title: 'Sort by',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in FlightSort.values)
            Pressable(
              onTap: () {
                Navigator.pop(context);
                setState(() => _sorts[route] = option);
              },
              borderRadius: AppRadii.rMd,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.md,
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: option == _sortFor(route)
                            ? AppText.bodyStrong.copyWith(
                                color: AppColors.primary,
                              )
                            : AppText.body,
                      ),
                    ),
                    if (option == _sortFor(route))
                      const Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Booking
  // -------------------------------------------------------------------------

  /// Chosen itineraries in route order, de-duplicated.
  ///
  /// The booking session is opened with one priceId per leg; a COMBO fare
  /// contributes a single entry covering the whole journey.
  List<FlightResult> get _bookableLegs {
    final legs = <FlightResult>[];
    for (final route in _routes) {
      final flight = _selected[route];
      if (flight == null) continue;
      if (legs.any((l) => l.id == flight.id)) continue;
      legs.add(flight);
    }
    return legs;
  }

  /// Reviews every chosen priceId, then opens the booking flow on that
  /// session — `MultiCityResults.jsx` `handleBook`, which reviews here and
  /// shows the supplier's own reason when the review is refused.
  Future<void> _continue() async {
    if (!_canContinue || _submitting) return;
    final legs = _bookableLegs;
    if (legs.isEmpty) return;

    // Same as the one-way/round-trip Book: sign in first, then continue.
    if (!await requireAuthentication(
      context,
      reason: 'Sign in to book these flights.',
    )) {
      return;
    }
    if (!mounted) return;

    setState(() => _submitting = true);
    try {
      final review = await widget.api.reviewFlight([
        for (final leg in legs) leg.id,
      ]);
      if (!mounted) return;
      await Navigator.push(
        context,
        AnimatedPageRoute(
          page: FlightBookingPage.multiCity(
            api: widget.api,
            trip: FlightTripContext.multiCity(
              legs: widget.legs,
              adults: widget.adults,
              children: widget.children,
              infants: widget.infants,
              cabinClass: widget.cabinClass,
              paxType: widget.paxType,
            ),
            legs: legs,
            initialReview: review,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      if (isTripGapError(e.data)) {
        await _explainTripGap(e.message);
      } else {
        AppSnackbar.error(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Failed to validate flight prices. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final route = _activeRoute;
    final visible = _visibleFor(route);
    final filters = _filterFor(route);
    final chips = describeFilters(
      filters,
      deriveFacets(_sourceFor(route), _pax),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Multi-city',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.legs.map((l) => l.from.code).join(' → ')} '
              '→ ${widget.legs.last.to.code}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: widget.results.isEmpty
          ? EmptyState(
              title: 'No flights found',
              message:
                  'This combination of cities and dates has no availability. '
                  'Try shifting a date or using a nearby airport.',
              icon: Icons.flight_takeoff_rounded,
            )
          : Column(
              children: [
                if (!_isCombo) _legSelector(),
                if (_isCombo) _comboNotice(),
                ?_gapHint(route),

                if (_sourceFor(route).isNotEmpty) ...[
                  _toolbar(visible.length, filters),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppliedFiltersRail(
                        chips: chips,
                        onRemove: (chip) => setState(
                          () => _filters[route] = removeChip(filters, chip),
                        ),
                        onClearAll: () => setState(
                          () => _filters[route] = FlightFilters.empty,
                        ),
                      ),
                    ),
                ],

                Expanded(child: _list(route, visible, filters)),
                if (_selected.isNotEmpty) _summaryBar(),
              ],
            ),
    );
  }

  Widget _list(int route, List<FlightResult> visible, FlightFilters filters) {
    if (visible.isEmpty) {
      final source = _sourceFor(route);
      // Either the supplier served nothing for this leg, or the traveller's own
      // filters excluded it. Only the second is recoverable in place.
      if (source.isEmpty) {
        return EmptyState(
          title: 'No flights for this leg',
          message:
              'Nothing is available on this route for the date you chose. '
              'Go back and try a different date.',
          icon: Icons.flight_takeoff_rounded,
        );
      }
      return EmptyState(
        title: 'No flights match your filters',
        message:
            'Clear a filter or two to see the ${source.length} option'
            '${source.length == 1 ? '' : 's'} on this leg.',
        icon: Icons.filter_alt_off_rounded,
        actionLabel: 'Clear filters',
        onAction: () => setState(() => _filters[route] = FlightFilters.empty),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, i) {
        final flight = visible[i];
        return FadeSlideIn(
          delay: AppMotion.staggerFor(i),
          child: _MultiCityFlightCard(
            flight: flight,
            pax: _pax,
            selected: _selected[route]?.id == flight.id,
            combo: _isCombo,
            unavailableReason: _selected[route]?.id == flight.id
                ? null
                : _unavailableReason(route, flight),
            onTap: () => _toggle(route, flight),
            onDetails: () => showFlightDetailsSheet(
              context,
              flight: flight,
              pax: _pax,
              rules: _rules,
            ),
          ),
        );
      },
    );
  }

  /// errCode 1019: the chosen legs are too close together. Says so plainly
  /// and moves to the later leg of the tightest pair, where a later flight
  /// fixes it.
  Future<void> _explainTripGap(String supplierMessage) async {
    int? target;
    Duration? tightest;
    for (var i = 1; i < _routes.length; i++) {
      final a = _selected[_routes[i - 1]];
      final b = _selected[_routes[i]];
      if (a?.arrival == null || b?.departure == null) continue;
      final gap = b!.departure!.difference(a!.arrival!);
      if (tightest == null || gap < tightest) {
        tightest = gap;
        target = _routes[i];
      }
    }

    await ConfirmPopup.show(
      context,
      title: 'These flights are too close together',
      message:
          '$supplierMessage\n\nThe airline needs more time between your '
          'flights. Pick a later flight for the next leg, or an earlier one '
          'for the leg before it.',
      confirmLabel: 'Change flight',
      cancelLabel: 'Close',
      icon: Icons.schedule_rounded,
    );
    if (!mounted || target == null) return;
    setState(() => _activeRoute = target!);
  }

  /// "Your previous flight lands at …" above a leg's list, so the traveller
  /// picks a flight that leaves after it.
  Widget? _gapHint(int route) {
    if (_isCombo) return null;
    final previous = _previousChoice(route);
    final landed = previous?.arrival;
    if (previous == null || landed == null) return null;
    final hh = landed.hour.toString().padLeft(2, '0');
    final mm = landed.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: InfoBanner(
        icon: Icons.schedule_rounded,
        message:
            'Your previous flight lands at ${previous.toCode} $hh:$mm on '
            '${formatTripDate(landed)}. Pick a flight that leaves after that — '
            'airlines need time between trips.',
      ),
    );
  }

  /// Horizontal leg picker, showing what is chosen and what is still open.
  Widget _legSelector() {
    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        itemCount: _routes.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final route = _routes[i];
          final leg = _legFor(route);
          final chosen = _selected[route];
          final active = route == _activeRoute;

          return Pressable(
            onTap: () => setState(() => _activeRoute = route),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        chosen != null
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 14,
                        color: chosen != null
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        leg?.routeLabel ?? 'Flight ${route + 1}',
                        style: AppText.labelSm.copyWith(
                          color: active
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chosen != null
                        ? '${chosen.airlineCode} · '
                              '${formatFlightFare(farePrice(chosen.selectedFare, _pax))}'
                        : leg == null
                        ? 'Choose a flight'
                        : formatTripDate(leg.date),
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _comboNotice() => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      0,
    ),
    child: InfoBanner(
      icon: Icons.all_inclusive_rounded,
      message:
          'These fares cover all ${widget.legs.length} flights together. '
          'Choosing one books the whole journey.',
    ),
  );

  Widget _toolbar(int count, FlightFilters filters) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$count option${count == 1 ? '' : 's'}',
              style: AppText.labelSm,
            ),
          ),
          _ToolbarButton(
            icon: Icons.swap_vert_rounded,
            label: _sortFor(_activeRoute).shortLabel,
            active: true,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolbarButton(
            icon: Icons.tune_rounded,
            label: filters.activeCount > 0
                ? 'Filters (${filters.activeCount})'
                : 'Filters',
            active: filters.activeCount > 0,
            onTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  /// Running total and the way forward, pinned above the safe area.
  Widget _summaryBar() {
    final outstanding = _routes.where((r) => !_selected.containsKey(r)).length;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _canContinue
                        ? 'Total for ${widget.adults + widget.children + widget.infants} '
                              'traveller'
                              '${widget.adults + widget.children + widget.infants == 1 ? '' : 's'}'
                        : '$outstanding flight${outstanding == 1 ? '' : 's'} left to choose',
                    style: AppText.caption,
                  ),
                  Text(formatFlightFare(_total), style: AppText.price),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            PremiumButton(
              label: 'Continue',
              size: PremiumButtonSize.small,
              expanded: false,
              isLoading: _submitting,
              onPressed: _canContinue ? _continue : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// A selectable itinerary. Unlike the single-leg card this one is a toggle, so
/// it has to show its selected state rather than acting immediately.
class _MultiCityFlightCard extends StatelessWidget {
  const _MultiCityFlightCard({
    required this.flight,
    required this.pax,
    required this.selected,
    required this.combo,
    required this.onTap,
    required this.onDetails,
    this.unavailableReason,
  });

  /// The web's "View Details +" — segments, baggage, fare and rules.
  final VoidCallback onDetails;

  /// Set when this flight clashes with a leg already chosen; the card is
  /// dimmed and says why.
  final String? unavailableReason;

  final FlightResult flight;
  final PaxCounts pax;
  final bool selected;

  /// A combined fare covers every leg, so its stop count describes the whole
  /// journey and would read as a very long connection otherwise.
  final bool combo;
  final VoidCallback onTap;

  String _time(DateTime? d) {
    if (d == null) return '--:--';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // BUG FIX: showed the trip's cheapest fare while the booking reviews the
    // fare in `flight.id`; the web prices that fare (`totalPriceList[0]`).
    final total = farePrice(flight.selectedFare, pax);
    final fare = flight.selectedFare;
    final seatsLeft = fareSeatsLeft(fare);

    final card = AppCard(
      onTap: onTap,
      // A selected itinerary keeps a highlighted outline, since the card is a
      // toggle rather than an immediate action.
      border: selected
          ? Border.all(color: AppColors.primary, width: 1.5)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (flight.airlineCode.isNotEmpty) ...[
                AirlineLogo(code: flight.airlineCode),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  flight.airline.isNotEmpty
                      ? flight.airline
                      : flight.airlineCode,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? AppColors.primary : AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(flight.departure), style: AppText.sectionTitle),
                  Text(flight.fromCode, style: AppText.caption),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      Text(
                        flight.durationLabel,
                        style: AppText.caption,
                        maxLines: 1,
                      ),
                      const Divider(height: AppSpacing.sm),
                      Text(
                        combo ? 'All flights' : flight.stopsLabel,
                        style: AppText.caption,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(flight.arrival), style: AppText.sectionTitle),
                  Text(flight.toCode, style: AppText.caption),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          // Fare type, "Economy, Refundable" and seats left, with the web's
          // "View Details +".
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MetaChip(
                label: fareDisplayLabel(
                  asString(readKey(fare, 'fareIdentifier')),
                ),
              ),
              Text(
                '${farePrefixText(fare)}, '
                '${fareIsRefundable(fare) ? 'Refundable' : 'Non-Refundable'}',
                style: AppText.caption,
              ),
              if (seatsLeft != null)
                Text(
                  'Seats left: $seatsLeft',
                  style: AppText.caption.copyWith(
                    color: seatsLeft <= 5
                        ? AppColors.error
                        : AppColors.textSecondary,
                  ),
                ),
              GestureDetector(
                onTap: onDetails,
                child: Text(
                  'View Details +',
                  style: AppText.labelSm.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: total > 0
                    ? Text(formatFlightFare(total), style: AppText.price)
                    : Text('Price on review', style: AppText.bodySm),
              ),
              Text(
                selected ? 'Selected' : 'Tap to select',
                style: AppText.labelSm.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
    final reason = unavailableReason;
    if (reason == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: 0.45, child: card),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Row(
            children: [
              const Icon(Icons.block_rounded, size: 14, color: AppColors.error),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  reason,
                  style: AppText.caption.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
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
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.pinkSurface : AppColors.surface,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: active ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppText.buttonSm.copyWith(
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
