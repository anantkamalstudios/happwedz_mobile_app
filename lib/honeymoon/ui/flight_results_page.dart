/// Flight search form + results, backed by `GET /tj/meta/locations` and
/// `POST /tj/fms/search`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/booking_models.dart';
import '../models/honeymoon_models.dart';
import 'booking/flight_booking_page.dart';
import 'widgets/honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Search form (rendered inside the honeymoon search card)
// ---------------------------------------------------------------------------

class FlightSearchForm extends StatefulWidget {
  const FlightSearchForm({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<FlightSearchForm> createState() => _FlightSearchFormState();
}

class _FlightSearchFormState extends State<FlightSearchForm> {
  FlightLocation? _from;
  FlightLocation? _to;
  DateTime? _departure;
  DateTime? _returnDate;
  int _adults = HoneymoonConfig.defaultAdults;
  bool _roundTrip = true;

  bool _submitting = false;
  String? _routeError;
  String? _dateError;

  Future<void> _pickLocation({required bool isOrigin}) async {
    final picked = await AppBottomSheet.show<FlightLocation>(
      context,
      title: isOrigin ? 'Flying from' : 'Flying to',
      child: _LocationSearchSheet(api: widget.api),
    );
    if (picked == null) return;
    setState(() {
      if (isOrigin) {
        _from = picked;
      } else {
        _to = picked;
      }
      _routeError = null;
    });
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_roundTrip) {
      final range = await showDateRangePicker(
        context: context,
        firstDate: today,
        lastDate: today.add(
          const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
        ),
        initialDateRange: _departure != null && _returnDate != null
            ? DateTimeRange(start: _departure!, end: _returnDate!)
            : null,
        helpText: 'Select travel dates',
      );
      if (range == null) return;
      setState(() {
        _departure = range.start;
        _returnDate = range.end;
        _dateError = null;
      });
    } else {
      final picked = await showDatePicker(
        context: context,
        initialDate: _departure ?? today,
        firstDate: today,
        lastDate: today.add(
          const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
        ),
        helpText: 'Select departure date',
      );
      if (picked == null) return;
      setState(() {
        _departure = picked;
        _returnDate = null;
        _dateError = null;
      });
    }
  }

  bool _validate() {
    setState(() {
      if (_from == null || _to == null) {
        _routeError = 'Choose where you are flying from and to';
      } else if (_from!.code == _to!.code) {
        _routeError = 'Origin and destination must be different';
      } else {
        _routeError = null;
      }

      _dateError = _departure == null
          ? 'Select your departure date'
          : (_roundTrip && _returnDate == null
                ? 'Select your return date'
                : null);
    });
    return _routeError == null && _dateError == null;
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final results = await widget.api.searchFlights(
        fromCode: _from!.code,
        toCode: _to!.code,
        departure: _departure!,
        returnDate: _roundTrip ? _returnDate : null,
        adults: _adults,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: FlightResultsPage(
            api: widget.api,
            from: _from!,
            to: _to!,
            departure: _departure!,
            returnDate: _roundTrip ? _returnDate : null,
            results: results,
            adults: _adults,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trip type
        Row(
          children: [
            for (final round in [true, false])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Pressable(
                  onTap: () => setState(() {
                    _roundTrip = round;
                    if (!round) _returnDate = null;
                  }),
                  borderRadius: AppRadii.rPill,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _roundTrip == round
                          ? AppColors.pinkSurface
                          : AppColors.surface,
                      borderRadius: AppRadii.rPill,
                      border: Border.all(
                        color: _roundTrip == round
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    child: Text(
                      round ? 'Round trip' : 'One way',
                      style: AppText.buttonSm.copyWith(
                        color: _roundTrip == round
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('From'),
        TapField(
          icon: Icons.flight_takeoff_rounded,
          value: _from == null ? '' : '${_from!.code} · ${_from!.name}',
          placeholder: 'Select departure city',
          onTap: () => _pickLocation(isOrigin: true),
        ),
        const SizedBox(height: AppSpacing.md),

        const FieldLabel('To'),
        TapField(
          icon: Icons.flight_land_rounded,
          value: _to == null ? '' : '${_to!.code} · ${_to!.name}',
          placeholder: 'Select destination city',
          onTap: () => _pickLocation(isOrigin: false),
          errorText: _routeError,
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Travel dates'),
        TapField(
          icon: Icons.calendar_today_rounded,
          value: _departure == null
              ? ''
              : _roundTrip && _returnDate != null
              ? '${formatTripDate(_departure)} – ${formatTripDate(_returnDate)}'
              : formatTripDate(_departure),
          placeholder: 'Add dates',
          onTap: _pickDates,
          errorText: _dateError,
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Travellers'),
        AppCard.outlined(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: CounterRow(
            title: 'Adults',
            subtitle: 'Age 12+',
            value: _adults,
            min: HoneymoonConfig.minTravellers,
            max: HoneymoonConfig.maxTravellers,
            onChanged: (v) => setState(() => _adults = v),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: 'Search Flights',
          icon: Icons.search_rounded,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }
}

/// Debounced airport lookup presented in a bottom sheet.
class _LocationSearchSheet extends StatefulWidget {
  const _LocationSearchSheet({required this.api});

  final HoneymoonApi api;

  @override
  State<_LocationSearchSheet> createState() => _LocationSearchSheetState();
}

class _LocationSearchSheetState extends State<_LocationSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<FlightLocation> _results = const [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final results = await widget.api.searchFlightLocations(value);
        if (!mounted) return;
        setState(() {
          _results = results;
          _loading = false;
        });
      } on HoneymoonApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _results = const [];
          _error = e.message;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _controller,
          hint: 'City or airport',
          prefixIcon: Icons.search_rounded,
          autofocus: true,
          onChanged: _onChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 280,
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const AppLoader();

    if ((_error ?? '').isNotEmpty) {
      return ErrorState(
        compact: true,
        title: "Couldn't load airports",
        message: _error,
        padding: EdgeInsets.zero,
      );
    }

    if (_results.isEmpty) {
      return EmptyState(
        compact: true,
        title: _controller.text.trim().length < 2
            ? 'Search for a city'
            : 'No airports found',
        message: _controller.text.trim().length < 2
            ? 'Type at least two letters to see airports.'
            : 'Try a different city or airport name.',
        icon: Icons.flight_rounded,
        padding: EdgeInsets.zero,
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final l = _results[i];
        return Pressable(
          onTap: () => Navigator.pop(context, l),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSurface,
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Text(
                    l.code,
                    style: AppText.labelSm.copyWith(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.name,
                        style: AppText.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (l.subtitle.isNotEmpty)
                        Text(
                          l.subtitle,
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

/// Search results, and the selection that leads into the booking funnel.
///
/// A round trip is picked one leg at a time. Showing both directions at once
/// needs two side-by-side columns, which does not fit a phone; picking the
/// outbound first and then the return is the pattern travellers already know
/// from every mobile flight app, and it also matches how the supplier prices
/// the two legs — separately.
class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({
    super.key,
    required this.api,
    required this.from,
    required this.to,
    required this.departure,
    required this.results,
    required this.adults,
    this.returnDate,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
  });

  final HoneymoonApi api;
  final FlightLocation from;
  final FlightLocation to;
  final DateTime departure;
  final DateTime? returnDate;
  final FlightSearchResult results;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  /// Set once the outbound has been chosen on a round trip; the list then
  /// switches to the return leg.
  FlightResult? _outbound;

  bool get _twoStep => widget.results.hasSeparateReturn;

  bool get _pickingReturn => _twoStep && _outbound != null;

  FlightTripContext get _trip => FlightTripContext(
    from: widget.from,
    to: widget.to,
    departure: widget.departure,
    returnDate: widget.returnDate,
    adults: widget.adults,
    children: widget.children,
    infants: widget.infants,
    cabinClass: widget.cabinClass,
  );

  List<FlightResult> get _visible => _pickingReturn
      ? widget.results.sortedInbound
      : widget.results.sortedOnward;

  void _select(FlightResult flight) {
    if (_twoStep && _outbound == null) {
      setState(() => _outbound = flight);
      return;
    }
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: FlightBookingPage(
          api: widget.api,
          trip: _trip,
          outbound: _outbound ?? flight,
          inbound: _outbound == null ? null : flight,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;

    return PopScope(
      // On a round trip, back from the return list means "pick a different
      // outbound", not "abandon the search".
      canPop: !_pickingReturn,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _outbound = null);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          elevated: true,
          onBack: _pickingReturn
              ? () => setState(() => _outbound = null)
              : null,
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _pickingReturn
                    ? '${widget.to.code} → ${widget.from.code}'
                    : '${widget.from.code} → ${widget.to.code}',
                style: AppText.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _pickingReturn
                    ? 'Return · ${formatTripDate(widget.returnDate)}'
                    : _twoStep
                    ? 'Departure · ${formatTripDate(widget.departure)}'
                    : widget.returnDate == null
                    ? formatTripDate(widget.departure)
                    : '${formatTripDate(widget.departure)} – '
                          '${formatTripDate(widget.returnDate)}',
                style: AppText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (_twoStep)
              _LegProgress(
                pickingReturn: _pickingReturn,
                outbound: _outbound,
                onChangeOutbound: () => setState(() => _outbound = null),
              ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      title: _pickingReturn
                          ? 'No return flights found'
                          : 'No flights found',
                      message:
                          'Try different dates or a nearby airport — this '
                          'route may not have flights on the day you chose.',
                      icon: Icons.flight_takeoff_rounded,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.lg,
                        AppSpacing.xxxl,
                      ),
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, i) => FadeSlideIn(
                        delay: AppMotion.staggerFor(i),
                        child: _FlightCard(
                          flight: list[i],
                          actionLabel: _twoStep && _outbound == null
                              ? 'Choose'
                              : 'Select',
                          onSelect: () => _select(list[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "outbound chosen, now pick a return" strip. Doubles as the way back to
/// change the outbound without losing the search.
class _LegProgress extends StatelessWidget {
  const _LegProgress({
    required this.pickingReturn,
    required this.outbound,
    required this.onChangeOutbound,
  });

  final bool pickingReturn;
  final FlightResult? outbound;
  final VoidCallback onChangeOutbound;

  @override
  Widget build(BuildContext context) {
    if (!pickingReturn || outbound == null) {
      return Container(
        width: double.infinity,
        color: AppColors.blush,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'Step 1 of 2 — choose your departure flight',
          style: AppText.labelSm.copyWith(color: AppColors.primaryDeep),
        ),
      );
    }

    final f = outbound!;
    return Container(
      width: double.infinity,
      color: AppColors.blush,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.successDark,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Departure selected',
                  style: AppText.labelSm.copyWith(color: AppColors.primaryDeep),
                ),
                Text(
                  '${f.airline.isNotEmpty ? f.airline : f.airlineCode} · '
                  '${f.fromCode} → ${f.toCode}',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PremiumButton.text(
            label: 'Change',
            size: PremiumButtonSize.small,
            onPressed: onChangeOutbound,
          ),
        ],
      ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({
    required this.flight,
    required this.onSelect,
    this.actionLabel = 'Select',
  });

  final FlightResult flight;
  final VoidCallback onSelect;
  final String actionLabel;

  String _time(DateTime? d) {
    if (d == null) return '--:--';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
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
              if (flight.flightNumber.isNotEmpty)
                MetaChip(
                  label: '${flight.airlineCode} ${flight.flightNumber}'.trim(),
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
                    horizontal: AppSpacing.md,
                  ),
                  child: Column(
                    children: [
                      if (flight.durationLabel.isNotEmpty)
                        Text(
                          flight.durationLabel,
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 3),
                      const Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.textTertiary,
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          Icon(
                            Icons.flight_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        flight.stopsLabel,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.divider),
          ),
          Row(
            children: [
              Expanded(
                child: flight.price > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('per adult', style: AppText.caption),
                          Text(
                            formatPrice(flight.price),
                            style: AppText.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text('Price on review', style: AppText.bodySm),
              ),
              const SizedBox(width: AppSpacing.md),
              PremiumButton(
                label: actionLabel,
                size: PremiumButtonSize.small,
                expanded: false,
                onPressed: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
