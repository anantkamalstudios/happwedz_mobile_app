/// Flight search form + results, backed by `GET /tj/meta/locations` and
/// `POST /tj/fms/search`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../main.dart' show requireAuthentication;
import '../data/flight_filters.dart';
import '../data/flight_search_store.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/booking_models.dart';
import '../models/flight_models.dart';
import '../models/honeymoon_models.dart';
import 'booking/booking_widgets.dart' show InfoBanner, InfoTone;
import 'booking/flight_booking_page.dart';
import 'multi_city_results_page.dart';
import 'widgets/flight_filter_sheet.dart';
import 'widgets/flight_widgets.dart';
import 'widgets/honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Search form (rendered inside the honeymoon search card)
// ---------------------------------------------------------------------------

/// The three shapes of journey the supplier prices.
enum TripType { oneWay, round, multiCity }

extension TripTypeLabel on TripType {
  String get label => switch (this) {
    TripType.oneWay => 'One way',
    TripType.round => 'Round trip',
    TripType.multiCity => 'Multi-city',
  };
}

/// The supplier accepts between two and five hops on a multi-city search.
const int kMinMultiCityLegs = 2;
const int kMaxMultiCityLegs = 5;

/// A multi-city hop while it is still being filled in.
class _LegDraft {
  FlightLocation? from;
  FlightLocation? to;
  DateTime? date;
}

class FlightSearchForm extends StatefulWidget {
  const FlightSearchForm({
    super.key,
    required this.api,
    this.initialQuery,
    this.replaceResults = false,
  });

  final HoneymoonApi api;

  /// Fills the form in, e.g. from the results screen's "Modify search". When
  /// null the form restores what it held last in this session, as the web's
  /// `hw_flightSearchForm` does.
  final FlightSearchQuery? initialQuery;

  /// Set by "Modify search": the form sits in a sheet over the results, and
  /// the new results replace that screen instead of stacking on top of it.
  final bool replaceResults;

  @override
  State<FlightSearchForm> createState() => _FlightSearchFormState();
}

class _FlightSearchFormState extends State<FlightSearchForm> {
  FlightLocation? _from;
  FlightLocation? _to;
  DateTime? _departure;
  DateTime? _returnDate;
  // BUG FIX: started on the module-wide default of two adults; the web's
  // flight form starts on one.
  int _adults = FlightPaxLimits.defaultAdults;
  int _children = 0;
  int _infants = 0;
  CabinClass _cabin = CabinClass.economy;
  FareType _fareType = FareType.regular;
  List<String> _preferredAirlines = const [];
  bool _directOnly = false;
  TripType _tripType = TripType.round;

  /// Multi-city hops. Kept as a partially-filled draft so a half-built leg
  /// survives while the traveller fills in the rest.
  final List<_LegDraft> _legs = [_LegDraft(), _LegDraft()];

  bool _submitting = false;
  String? _routeError;
  String? _dateError;

  /// The web's "Recent Searches" — last six one-way / round-trip searches.
  List<FlightSearchQuery> _recent = const [];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery ?? FlightSearchStore.lastForm;
    if (initial != null) _apply(initial);
    if (!widget.replaceResults) _loadRecent();
  }

  @override
  void dispose() {
    // The web snapshots the form on every change so coming back from the
    // results finds it filled in; saving on the way out does the same here.
    if (!widget.replaceResults) FlightSearchStore.lastForm = _toQuery();
    super.dispose();
  }

  Future<void> _loadRecent() async {
    final recent = await FlightSearchStore.loadRecent();
    if (mounted) setState(() => _recent = recent);
  }

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Loads [q] into the fields. Dates already in the past are dropped — the
  /// supplier rejects them — so the traveller is asked for a new one.
  void _apply(FlightSearchQuery q) {
    final today = _today();
    DateTime? upcoming(DateTime? d) =>
        d == null || d.isBefore(today) ? null : d;

    _tripType = switch (q.tripType) {
      FlightTripKind.oneWay => TripType.oneWay,
      FlightTripKind.multiCity => TripType.multiCity,
      _ => TripType.round,
    };
    _from = q.from;
    _to = q.to;
    _departure = upcoming(q.departure);
    _returnDate = _tripType == TripType.round && _departure != null
        ? upcoming(q.returnDate)
        : null;
    _adults = q.adults < FlightPaxLimits.minAdults
        ? FlightPaxLimits.minAdults
        : q.adults;
    _children = q.children < 0 ? 0 : q.children;
    _infants = q.infants > _adults ? _adults : q.infants;
    _cabin = CabinClass.values.firstWhere(
      (c) => c.apiValue == q.cabinClass,
      orElse: () => CabinClass.economy,
    );
    _fareType = FareType.values.firstWhere(
      (f) => f.apiValue == q.paxType,
      orElse: () => FareType.regular,
    );
    _preferredAirlines = List<String>.from(q.preferredAirlines);
    _directOnly = q.directOnly;
    _legs
      ..clear()
      ..addAll([
        for (final leg in q.legs)
          _LegDraft()
            ..from = leg.from
            ..to = leg.to
            ..date = upcoming(leg.date),
      ]);
    _ensureLegs();
    _routeError = null;
    _dateError = null;
  }

  /// The form as a [FlightSearchQuery] — what is searched, remembered and
  /// handed to the results screen.
  FlightSearchQuery _toQuery() => FlightSearchQuery(
    tripType: switch (_tripType) {
      TripType.oneWay => FlightTripKind.oneWay,
      TripType.round => FlightTripKind.round,
      TripType.multiCity => FlightTripKind.multiCity,
    },
    from: _from,
    to: _to,
    departure: _departure,
    returnDate: _roundTrip ? _returnDate : null,
    legs: [
      for (final d in _legs)
        if (d.from != null && d.to != null && d.date != null)
          FlightLeg(from: d.from!, to: d.to!, date: d.date!),
    ],
    adults: _adults,
    children: _children,
    infants: _infants,
    cabinClass: _cabin.apiValue,
    paxType: _fareType.apiValue,
    preferredAirlines: _preferredAirlines,
    directOnly: _directOnly,
  );

  /// "Search again" on a recent search: fill the form and run it. A search
  /// whose date has passed is filled in but not run, with the date flagged.
  void _runRecent(FlightSearchQuery q) {
    if (_submitting) return;
    setState(() => _apply(q));
    if (_departure == null) {
      setState(
        () => _dateError = 'That date has passed — pick a new departure date',
      );
      return;
    }
    _search();
  }

  /// Opens results, or — from "Modify search" — closes the sheet and swaps
  /// them for the current results screen.
  void _openResults(Widget page) {
    final navigator = Navigator.of(context);
    final route = AnimatedPageRoute(
      page: page,
      style: PageTransitionStyle.slideRight,
    );
    if (widget.replaceResults) {
      navigator.pop();
      navigator.pushReplacement(route);
    } else {
      navigator.push(route);
    }
  }

  bool get _roundTrip => _tripType == TripType.round;
  bool get _isMultiCity => _tripType == TripType.multiCity;

  /// Multi-city always needs at least two hops to mean anything.
  void _ensureLegs() {
    while (_legs.length < kMinMultiCityLegs) {
      _legs.add(_LegDraft());
    }
  }

  Future<void> _pickLegPlace(int index, {required bool isOrigin}) async {
    final picked = await AppBottomSheet.show<FlightLocation>(
      context,
      title: isOrigin ? 'Flying from' : 'Flying to',
      child: _LocationSearchSheet(api: widget.api),
    );
    if (picked == null) return;
    setState(() {
      if (isOrigin) {
        _legs[index].from = picked;
      } else {
        _legs[index].to = picked;
      }
      _routeError = null;
    });
  }

  Future<void> _pickLegDate(int index) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // A hop can never depart before the one before it, so the picker refuses
    // those dates outright rather than failing validation afterwards.
    final previous = index > 0 ? _legs[index - 1].date : null;
    final first = previous != null && previous.isAfter(today)
        ? previous
        : today;

    final picked = await showDatePicker(
      context: context,
      initialDate: _legs[index].date ?? first,
      firstDate: first,
      lastDate: today.add(
        const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
      ),
      helpText: 'Select date for flight ${index + 1}',
    );
    if (picked == null) return;

    setState(() {
      _legs[index].date = picked;
      // Later hops that now sit before this one are cleared rather than left
      // silently invalid.
      for (var i = index + 1; i < _legs.length; i++) {
        final later = _legs[i].date;
        if (later != null && later.isBefore(picked)) _legs[i].date = null;
      }
      _dateError = null;
    });
  }

  int get _travellerCount => _adults + _children + _infants;

  /// Adults, children, infants and cabin in one sheet, as the website's
  /// "Passengers & Class" dropdown presents them.
  Future<void> _openTravellerSheet() async {
    await AppBottomSheet.show(
      context,
      title: 'Travellers & class',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          void update(VoidCallback change) {
            setSheetState(change);
            setState(() {});
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // BUG FIX: adults and children were capped at twelve between
              // them and infants not counted at all, so a party of eleven
              // plus infants got through. The web caps everyone — infants
              // included — at nine, and an infant needs an adult's lap.
              CounterRow(
                title: 'Adults',
                subtitle: 'Age 12+',
                value: _adults,
                min: FlightPaxLimits.minAdults,
                max: FlightPaxLimits.maxTotal - _children - _infants,
                onChanged: (v) => update(() {
                  _adults = v;
                  if (_infants > _adults) _infants = _adults;
                }),
              ),
              const SizedBox(height: AppSpacing.sm),
              CounterRow(
                title: 'Children',
                subtitle: 'Age 2-12',
                value: _children,
                min: 0,
                max: FlightPaxLimits.maxTotal - _adults - _infants,
                onChanged: (v) => update(() => _children = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              CounterRow(
                title: 'Infants',
                subtitle: 'Age 0-2',
                value: _infants,
                // An infant travels on an adult's lap, so there can never be
                // more infants than adults on the booking.
                min: 0,
                max: [
                  _adults,
                  FlightPaxLimits.maxTotal - _adults - _children,
                ].reduce((a, b) => a < b ? a : b),
                onChanged: (v) => update(() => _infants = v),
              ),

              // Previous counters, kept for reference:
              // CounterRow(
              // title: 'Adults',
              // subtitle: 'Age 12+',
              // value: _adults,
              // min: HoneymoonConfig.minTravellers,
              // max: HoneymoonConfig.maxTravellers,
              // onChanged: (v) => update(() => _adults = v),
              // ),
              // const SizedBox(height: AppSpacing.sm),
              // CounterRow(
              // title: 'Children',
              // subtitle: 'Age 2-12',
              // value: _children,
              // min: 0,
              // max: HoneymoonConfig.maxTravellers - _adults,
              // onChanged: (v) => update(() => _children = v),
              // ),
              // const SizedBox(height: AppSpacing.sm),
              // CounterRow(
              // title: 'Infants',
              // subtitle: 'Age 0-2',
              // value: _infants,
              // // An infant travels on an adult's lap, so there can never be
              // // more infants than adults on the booking.
              // min: 0,
              // max: _adults,
              // onChanged: (v) => update(() => _infants = v),
              // ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: AppSpacing.md),

              Text('Cabin class', style: AppText.formLabel),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final cabin in CabinClass.values)
                    Pressable(
                      onTap: () => update(() => _cabin = cabin),
                      borderRadius: AppRadii.rPill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: _cabin == cabin
                              ? AppColors.pinkSurface
                              : AppColors.surface,
                          borderRadius: AppRadii.rPill,
                          border: Border.all(
                            color: _cabin == cabin
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Text(
                          cabin.label,
                          style: AppText.buttonSm.copyWith(
                            color: _cabin == cabin
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              PremiumButton(
                label: 'Done',
                onPressed: () => Navigator.pop(sheetContext),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Multi-select airline picker, capped at the supplier's limit of ten.
  Future<void> _openAirlineSheet() async {
    final draft = List<String>.from(_preferredAirlines);

    final result = await AppBottomSheet.show<List<String>>(
      context,
      title: 'Preferred airline',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Results are limited to the airlines you pick. Leave empty to '
                'see every carrier.',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              for (final airline in kPreferredAirlines)
                Pressable(
                  onTap: () => setSheetState(() {
                    if (!draft.remove(airline.code) &&
                        draft.length < kMaxPreferredAirlines) {
                      draft.add(airline.code);
                    }
                  }),
                  borderRadius: AppRadii.rMd,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: draft.contains(airline.code),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            activeColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.divider,
                              width: 1.5,
                            ),
                            onChanged: (_) => setSheetState(() {
                              if (!draft.remove(airline.code) &&
                                  draft.length < kMaxPreferredAirlines) {
                                draft.add(airline.code);
                              }
                            }),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AirlineLogo(code: airline.code, size: 20),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(airline.name, style: AppText.body),
                        ),
                        Text(airline.code, style: AppText.caption),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Any airline',
                      onPressed: () => Navigator.pop(sheetContext, <String>[]),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Apply',
                      onPressed: () => Navigator.pop(sheetContext, draft),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    if (result != null && mounted) {
      setState(() => _preferredAirlines = result);
    }
  }

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
    if (_isMultiCity) return _validateMultiCity();

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

  bool _validateMultiCity() {
    String? routeError;
    String? dateError;

    for (var i = 0; i < _legs.length; i++) {
      final leg = _legs[i];
      if (leg.from == null || leg.to == null) {
        routeError ??= 'Complete flight ${i + 1} — pick both cities';
      } else if (leg.from!.code == leg.to!.code) {
        routeError ??=
            'Flight ${i + 1} must go somewhere different from where it starts';
      }
      if (leg.date == null) {
        dateError ??= 'Pick a date for flight ${i + 1}';
      }
    }

    // The supplier rejects a journey that travels backwards in time, so it is
    // caught here with the offending hop named rather than as a 400.
    if (routeError == null && dateError == null) {
      for (var i = 1; i < _legs.length; i++) {
        final previous = _legs[i - 1].date!;
        if (_legs[i].date!.isBefore(previous)) {
          dateError =
              'Flight ${i + 1} departs before flight $i. Dates must move '
              'forwards.';
          break;
        }
      }
    }

    setState(() {
      _routeError = routeError;
      _dateError = dateError;
    });
    return routeError == null && dateError == null;
  }

  Future<void> _searchMultiCity() async {
    final legs = [
      for (final draft in _legs)
        FlightLeg(from: draft.from!, to: draft.to!, date: draft.date!),
    ];

    final results = await widget.api.searchMultiCityFlights(
      legs: legs,
      adults: _adults,
      children: _children,
      infants: _infants,
      cabinClass: _cabin.apiValue,
      paxType: _fareType.apiValue,
      preferredAirlines: _preferredAirlines,
    );

    if (!mounted) return;
    _openResults(
      MultiCityResultsPage(
        api: widget.api,
        legs: legs,
        results: results,
        adults: _adults,
        children: _children,
        infants: _infants,
        cabinClass: _cabin.apiValue,
        paxType: _fareType.apiValue,
      ),
    );
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    final query = _toQuery();
    FlightSearchStore.lastForm = query;

    setState(() => _submitting = true);
    try {
      if (_isMultiCity) {
        await _searchMultiCity();
        return;
      }

      // Saved before the search runs, as the web's `saveRecentSearch` is.
      unawaited(FlightSearchStore.saveRecent(query));
      final results = await runFlightSearch(widget.api, query);

      if (!mounted) return;
      _openResults(
        FlightResultsPage(api: widget.api, query: query, results: results),
      );
      if (!widget.replaceResults) unawaited(_loadRecent());
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// One block per hop, plus the controls to add or drop one.
  ///
  /// Each hop is a card rather than a row of fields: three tappable values side
  /// by side do not fit a phone at a legible size, and stacking them without a
  /// container makes it impossible to tell which date belongs to which flight.
  List<Widget> _multiCityFields() {
    return [
      for (var i = 0; i < _legs.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        AppCard.outlined(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Flight ${i + 1}', style: AppText.formLabel),
                  ),
                  if (_legs.length > kMinMultiCityLegs)
                    PremiumButton.text(
                      label: 'Remove',
                      size: PremiumButtonSize.small,
                      onPressed: () => setState(() {
                        _legs.removeAt(i);
                        _routeError = null;
                        _dateError = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              TapField(
                icon: Icons.flight_takeoff_rounded,
                value: _legs[i].from == null
                    ? ''
                    : '${_legs[i].from!.code} · ${_legs[i].from!.name}',
                placeholder: 'From',
                onTap: () => _pickLegPlace(i, isOrigin: true),
              ),
              const SizedBox(height: AppSpacing.sm),
              TapField(
                icon: Icons.flight_land_rounded,
                value: _legs[i].to == null
                    ? ''
                    : '${_legs[i].to!.code} · ${_legs[i].to!.name}',
                placeholder: 'To',
                onTap: () => _pickLegPlace(i, isOrigin: false),
              ),
              const SizedBox(height: AppSpacing.sm),
              TapField(
                icon: Icons.calendar_today_rounded,
                value: _legs[i].date == null
                    ? ''
                    : formatTripDate(_legs[i].date),
                placeholder: 'Travel date',
                onTap: () => _pickLegDate(i),
              ),
            ],
          ),
        ),
      ],

      if (_routeError != null || _dateError != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(_routeError ?? _dateError!, style: AppText.error),
      ],

      const SizedBox(height: AppSpacing.md),
      Row(
        children: [
          if (_legs.length < kMaxMultiCityLegs)
            PremiumButton.text(
              label: 'Add another flight',
              size: PremiumButtonSize.small,
              onPressed: () => setState(() => _legs.add(_LegDraft())),
            )
          else
            Text(
              'Up to $kMaxMultiCityLegs flights per search.',
              style: AppText.caption,
            ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trip type
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in TripType.values)
              Pressable(
                onTap: () => setState(() {
                  _tripType = type;
                  if (type != TripType.round) _returnDate = null;
                  if (type == TripType.multiCity) _ensureLegs();
                  _routeError = null;
                  _dateError = null;
                }),
                borderRadius: AppRadii.rPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: _tripType == type
                        ? AppColors.pinkSurface
                        : AppColors.surface,
                    borderRadius: AppRadii.rPill,
                    border: Border.all(
                      color: _tripType == type
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: AppText.buttonSm.copyWith(
                      color: _tripType == type
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        if (_isMultiCity)
          ..._multiCityFields()
        else ...[
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
        ],
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Travellers & class'),
        TapField(
          icon: Icons.people_alt_rounded,
          value:
              '$_travellerCount traveller'
              '${_travellerCount == 1 ? '' : 's'} · ${_cabin.label}',
          placeholder: 'Who is travelling?',
          onTap: _openTravellerSheet,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Student and senior fares are priced differently by the airline, so
        // they are part of the search rather than a filter over the results.
        const FieldLabel('Fare type'),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final type in FareType.values)
              Pressable(
                onTap: () => setState(() => _fareType = type),
                borderRadius: AppRadii.rPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: _fareType == type
                        ? AppColors.pinkSurface
                        : AppColors.surface,
                    borderRadius: AppRadii.rPill,
                    border: Border.all(
                      color: _fareType == type
                          ? AppColors.primary
                          : AppColors.divider,
                    ),
                  ),
                  child: Text(
                    type.label,
                    style: AppText.buttonSm.copyWith(
                      color: _fareType == type
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_fareType.note != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(_fareType.note!, style: AppText.caption),
        ],
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Preferred airline'),
        TapField(
          icon: Icons.airlines_rounded,
          value: _preferredAirlines.isEmpty
              ? ''
              : _preferredAirlines
                    .map(
                      (code) => kPreferredAirlines
                          .firstWhere(
                            (a) => a.code == code,
                            orElse: () => AirlineOption(code, code),
                          )
                          .name,
                    )
                    .join(', '),
          placeholder: 'Any airline',
          onTap: _openAirlineSheet,
        ),
        const SizedBox(height: AppSpacing.md),

        Pressable(
          onTap: () => setState(() => _directOnly = !_directOnly),
          borderRadius: AppRadii.rMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _directOnly,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    activeColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.divider,
                      width: 1.5,
                    ),
                    onChanged: (v) => setState(() => _directOnly = v ?? false),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('Non-stop flights only', style: AppText.body),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: _isMultiCity
              ? 'Search ${_legs.length} Flights'
              : 'Search Flights',
          icon: Icons.search_rounded,
          isLoading: _submitting,
          onPressed: _search,
        ),

        if (_recent.isNotEmpty && !widget.replaceResults) ...[
          const SizedBox(height: AppSpacing.xl),
          Text('Recent searches', style: AppText.formLabel),
          const SizedBox(height: AppSpacing.sm),
          for (final q in _recent)
            _RecentSearchRow(
              query: q,
              enabled: !_submitting,
              onSearch: () => _runRecent(q),
            ),
        ],
      ],
    );
  }
}

/// One "Recent Searches" entry: route, dates, party and cabin, and
/// "Search again".
class _RecentSearchRow extends StatelessWidget {
  const _RecentSearchRow({
    required this.query,
    required this.onSearch,
    this.enabled = true,
  });

  final FlightSearchQuery query;
  final VoidCallback onSearch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cabin = query.cabinClass
        .replaceAll('_', ' ')
        .toLowerCase()
        .replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());
    final dates = query.returnDate == null
        ? formatTripDate(query.departure)
        : '${formatTripDate(query.departure)} – '
              '${formatTripDate(query.returnDate)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          const Icon(
            Icons.history_rounded,
            size: 18,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${query.from?.code ?? ''} → ${query.to?.code ?? ''}',
                  style: AppText.bodyStrong,
                ),
                Text(
                  '$dates · ${query.travellerCount} pax · $cabin',
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          PremiumButton.text(
            label: 'Search again',
            size: PremiumButtonSize.small,
            onPressed: enabled ? onSearch : null,
          ),
        ],
      ),
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
        SizedBox(height: 280, child: _buildBody()),
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
/// Runs a one-way or round-trip search exactly as the form does, so the date
/// strip, a stale-fare refresh and "Search again" all build the same request.
Future<FlightSearchResult> runFlightSearch(
  HoneymoonApi api,
  FlightSearchQuery query,
) {
  return api.searchFlights(
    fromCode: query.from!.code,
    toCode: query.to!.code,
    departure: query.departure!,
    returnDate: query.isRoundTrip ? query.returnDate : null,
    adults: query.adults,
    children: query.children,
    infants: query.infants,
    cabinClass: query.cabinClass,
    directOnly: query.directOnly,
    paxType: query.paxType,
    preferredAirlines: query.preferredAirlines,
  );
}

class FlightResultsPage extends StatefulWidget {
  const FlightResultsPage({
    super.key,
    required this.api,
    required this.query,
    required this.results,
  });

  final HoneymoonApi api;

  /// The search these results answer. Kept whole — not just the route and
  /// dates — because the date strip and the stale-fare refresh re-run it with
  /// the same fare type, airlines and non-stop setting.
  final FlightSearchQuery query;
  final FlightSearchResult results;

  @override
  State<FlightResultsPage> createState() => _FlightResultsPageState();
}

class _FlightResultsPageState extends State<FlightResultsPage> {
  /// Replaced in place when the search is re-run from this screen.
  late FlightSearchQuery _query = widget.query;
  late FlightSearchResult _results = widget.results;

  /// Set once the outbound has been chosen on a round trip; the list then
  /// switches to the return leg.
  FlightResult? _outbound;

  /// Sorting and filtering are per-leg on purpose: the outbound and the return
  /// are separate result sets with separate facets, exactly as the website
  /// treats its two columns.
  FlightSort _sort = FlightSort.price;
  FlightFilters _filters = FlightFilters.empty;

  /// The fare picked on each card, by [FlightResult.tripKey]. A card with no
  /// entry uses its default fare.
  final Map<String, String> _fareChoice = {};

  late final FareRuleLoader _rules = FareRuleLoader(widget.api);

  late List<SpecialReturnOption> _specials = _deriveSpecials();

  /// Blocks the list while a fare is being reviewed or the search re-run.
  String? _busyLabel;

  /// The web's `staleNotice` — why the list just changed under the traveller.
  String? _notice;

  /// The day being re-searched from the date strip.
  DateTime? _pendingDate;

  bool get _busy => _busyLabel != null;

  FlightLocation get _from => _query.from!;
  FlightLocation get _to => _query.to!;

  bool get _twoStep => _results.hasSeparateReturn;

  bool get _pickingReturn => _twoStep && _outbound != null;

  PaxCounts get _pax => PaxCounts(
    adults: _query.adults,
    children: _query.children,
    infants: _query.infants,
  );

  /// The unfiltered set for the leg on screen. Facets are always derived from
  /// this, so option counts stay stable as the user narrows down instead of
  /// collapsing toward zero.
  List<FlightResult> get _source =>
      _pickingReturn ? _results.inbound : _results.onward;

  /// On the return leg the route is reversed, which matters to the
  /// "hide nearby airports" filter.
  String get _legFrom => _pickingReturn ? _to.code : _from.code;
  String get _legTo => _pickingReturn ? _from.code : _to.code;

  FlightFacets? get _facets => deriveFacets(_source, _pax);

  List<FlightResult> get _filtered => sortFlights(
    filterFlights(
      _source,
      _filters,
      searchFrom: _legFrom,
      searchTo: _legTo,
      pax: _pax,
    ),
    _sort,
    _pax,
  ).map(_withChoice).toList();

  /// [flight] at the fare picked on its card, when that fare survived the
  /// filters; otherwise at its default fare.
  FlightResult _withChoice(FlightResult flight) {
    final id = _fareChoice[flight.tripKey];
    return id == null ? flight : flight.withSelectedFare(id);
  }

  List<SpecialReturnOption> _deriveSpecials() => _results.hasSeparateReturn
      ? deriveSpecialReturn(_results.onward, _results.inbound, _pax)
      : const [];

  /// Switching legs keeps the user's intent but drops anything the new result
  /// set cannot satisfy — otherwise a `stops: {0}` carried over from an
  /// outbound with non-stops empties a return that has none.
  void _setOutbound(FlightResult? flight) {
    setState(() {
      _outbound = flight;
      _filters = reconcileFilters(_filters, deriveFacets(_source, _pax));
    });
  }

  Future<void> _openFilterSheet() async {
    final facets = _facets;
    if (facets == null) return;

    final result = await showFlightFilterSheet(
      context,
      facets: facets,
      current: _filters,
      flights: _source,
      pax: _pax,
      searchFrom: _legFrom,
      searchTo: _legTo,
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  Future<void> _openSortSheet() async {
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
                if (option != _sort) setState(() => _sort = option);
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
                        style: option == _sort
                            ? AppText.bodyStrong.copyWith(
                                color: AppColors.primary,
                              )
                            : AppText.body,
                      ),
                    ),
                    if (option == _sort)
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

  FlightTripContext get _trip => FlightTripContext(
    from: _from,
    to: _to,
    departure: _query.departure!,
    returnDate: _query.isRoundTrip ? _query.returnDate : null,
    adults: _query.adults,
    children: _query.children,
    infants: _query.infants,
    cabinClass: _query.cabinClass,
    paxType: _query.paxType,
  );

  // -------------------------------------------------------------------------
  // Choosing and booking
  // -------------------------------------------------------------------------

  void _pickFare(FlightResult flight, String fareId) {
    setState(() => _fareChoice[flight.tripKey] = fareId);
  }

  /// "Select" on a card. On a round trip the first pick is the outbound; the
  /// second completes the pair and goes to review.
  /// On the return leg: why [flight] cannot follow the chosen outbound.
  String? _returnUnavailable(FlightResult flight) {
    final outbound = _outbound;
    if (!_pickingReturn || outbound == null) return null;
    return tripOverlapReason(outbound, flight);
  }

  void _select(FlightResult flight) {
    if (_busy) return;
    final blocked = _returnUnavailable(flight);
    if (blocked != null) {
      AppSnackbar.info(context, blocked);
      return;
    }
    if (_twoStep && _outbound == null) {
      _setOutbound(flight);
      return;
    }
    _reviewAndGo([_outbound ?? flight, if (_outbound != null) flight]);
  }

  /// Reviews the chosen fares with the supplier, then opens the booking flow
  /// on the session that review opened — the web's `reviewAndGo`.
  ///
  /// A fare that has gone (errCode 1000, "no longer available", …) means every
  /// price on screen is stale, so the search is re-run rather than leaving the
  /// traveller on a dead error.
  Future<void> _reviewAndGo(List<FlightResult> legs) async {
    final priceIds = [
      for (final leg in legs)
        if (leg.id.isNotEmpty) leg.id,
    ];
    if (priceIds.isEmpty) {
      AppSnackbar.error(context, 'Unable to get flight pricing information.');
      return;
    }

    // Booking, saved travellers, hold and payment all need an account. Ask
    // now — on top of the results — so the traveller continues into the
    // booking flow right after signing in.
    if (!await requireAuthentication(
      context,
      reason: 'Sign in to book this flight.',
    )) {
      return;
    }
    if (!mounted) return;

    setState(() {
      _busyLabel = 'Checking the latest fare…';
      _notice = null;
    });
    try {
      final review = await widget.api.reviewFlight(priceIds);
      if (!mounted) return;
      setState(() => _busyLabel = null);
      await Navigator.push(
        context,
        AnimatedPageRoute(
          page: FlightBookingPage(
            api: widget.api,
            trip: _trip,
            outbound: legs.first,
            inbound: legs.length > 1 ? legs[1] : null,
            initialReview: review,
          ),
          style: PageTransitionStyle.slideRight,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() => _busyLabel = null);
      if (isStaleFarePayload(e.data)) {
        await _refreshStaleResults();
      } else if (isTripGapError(e.data)) {
        // errCode 1019: the return leaves too soon after the outbound lands.
        await ConfirmPopup.show(
          context,
          title: 'These flights are too close together',
          message:
              '${e.message}\n\nThe airline needs more time between your '
              'outbound and return. Pick a later return, or change the '
              'outbound.',
          confirmLabel: 'Choose another',
          cancelLabel: 'Close',
          icon: Icons.schedule_rounded,
        );
      } else {
        AppSnackbar.error(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _busyLabel = null);
      AppSnackbar.error(
        context,
        'Failed to proceed with booking. Please try again.',
      );
    }
  }

  Future<void> _refreshStaleResults() async {
    setState(() => _notice = 'These fares have expired. Refreshing prices…');
    try {
      await _rerun(_query, label: 'Refreshing prices…');
      if (!mounted) return;
      setState(
        () => _notice =
            'Prices were out of date, so the list has been refreshed. Please '
            'pick your flight again.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _notice =
            'These fares have expired and prices could not be refreshed. '
            'Please search again.',
      );
    }
  }

  /// Re-runs the search and replaces the results in place, keeping the
  /// filters and dropping any selection the new set cannot satisfy. Shared by
  /// the date strip and the stale-fare path, as on the web.
  Future<void> _rerun(FlightSearchQuery next, {required String label}) async {
    setState(() => _busyLabel = label);
    try {
      final results = await runFlightSearch(widget.api, next);
      if (!mounted) return;
      setState(() {
        _query = next;
        _results = results;
        _outbound = null;
        _fareChoice.clear();
        _specials = _deriveSpecials();
        final offered = {for (final o in _specials) o.code};
        _filters =
            reconcileFilters(
              _filters,
              deriveFacets(_results.onward, _pax),
            ).copyWith(
              specialReturn: _filters.specialReturn
                  .where(offered.contains)
                  .toSet(),
            );
      });
    } finally {
      if (mounted) setState(() => _busyLabel = null);
    }
  }

  Future<void> _pickDate(DateTime day) async {
    if (_busy) return;
    setState(() => _pendingDate = day);
    try {
      await _rerun(
        _query.copyWith(departure: day),
        label: 'Loading fares for ${formatTripDate(day)}…',
      );
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Could not load fares for that date. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _pendingDate = null);
    }
  }

  /// A "Return Special" tile: one airline at a time, its cheapest valid pair
  /// picked on both legs. Tapping the active tile clears it.
  void _pickSpecialReturn(SpecialReturnOption option) {
    final isOn = _filters.specialReturn.contains(option.code);
    if (isOn) {
      setState(() {
        _filters = _filters.copyWith(specialReturn: const {});
        _outbound = null;
      });
      return;
    }

    FlightResult? tripWith(List<FlightResult> list, String fareId) {
      for (final t in list) {
        if (t.fares.any((f) => asString(readKey(f, 'id')) == fareId)) {
          return t;
        }
      }
      return null;
    }

    final out = tripWith(_results.onward, option.outFareId);
    final ret = tripWith(_results.inbound, option.returnFareId);
    setState(() {
      _filters = _filters.copyWith(specialReturn: {option.code});
      if (ret != null) _fareChoice[ret.tripKey] = option.returnFareId;
      if (out != null) {
        _fareChoice[out.tripKey] = option.outFareId;
        _outbound = out.withSelectedFare(option.outFareId);
      }
    });
    if (out != null) {
      AppSnackbar.info(
        context,
        '${option.name} Return Special selected — now confirm the return '
        'flight.',
      );
    }
  }

  Future<void> _openModifySearch() async {
    await AppBottomSheet.show<void>(
      context,
      title: 'Modify search',
      child: FlightSearchForm(
        api: widget.api,
        initialQuery: _query,
        replaceResults: true,
      ),
    );
  }

  void _share() {
    final list = _filtered;
    showFlightShareSheet(
      context,
      flightShareSummary(
        from: _legFrom,
        to: _legTo,
        date: _pickingReturn ? _query.returnDate : _query.departure,
        resultCount: list.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final facets = _facets;
    final chips = describeFilters(_filters, facets);
    final showDateStrip = !_query.isRoundTrip && _query.departure != null;
    final showSpecials = _twoStep && !_pickingReturn && _specials.isNotEmpty;

    return PopScope(
      // On a round trip, back from the return list means "pick a different
      // outbound", not "abandon the search". Nothing leaves mid-review.
      canPop: !_pickingReturn && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _setOutbound(null);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          elevated: true,
          onBack: _pickingReturn ? () => _setOutbound(null) : null,
          actions: [
            IconButton(
              tooltip: 'Share',
              onPressed: _busy ? null : _share,
              icon: const Icon(Icons.share_outlined),
            ),
            IconButton(
              tooltip: 'Modify search',
              onPressed: _busy ? null : _openModifySearch,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _pickingReturn
                    ? '${_to.code} → ${_from.code}'
                    : '${_from.code} → ${_to.code}',
                style: AppText.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _pickingReturn
                    ? 'Return · ${formatTripDate(_query.returnDate)}'
                    : _twoStep
                    ? 'Departure · ${formatTripDate(_query.departure)}'
                    : !_query.isRoundTrip
                    ? formatTripDate(_query.departure)
                    : '${formatTripDate(_query.departure)} – '
                          '${formatTripDate(_query.returnDate)}',
                style: AppText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                if (_twoStep)
                  _LegProgress(
                    pickingReturn: _pickingReturn,
                    outbound: _outbound,
                    onChangeOutbound: () => _setOutbound(null),
                  ),
                if (showDateStrip)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: FareDateStrip(
                      selected: _query.departure!,
                      pending: _pendingDate,
                      onPick: _pickDate,
                    ),
                  ),
                if (_notice != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      0,
                    ),
                    child: InfoBanner(
                      message: _notice!,
                      tone: InfoTone.warning,
                      icon: Icons.update_rounded,
                      action: PremiumButton.text(
                        label: 'Dismiss',
                        size: PremiumButtonSize.small,
                        onPressed: () => setState(() => _notice = null),
                      ),
                    ),
                  ),
                if (showSpecials)
                  SpecialReturnStrip(
                    options: _specials,
                    selectedCode: _filters.specialReturn.firstOrNull,
                    onPick: _pickSpecialReturn,
                  ),
                if (_source.isNotEmpty) ...[
                  _QuickPicks(
                    flights: _source,
                    pax: _pax,
                    sort: _sort,
                    onSort: (s) => setState(() => _sort = s),
                  ),
                  _Toolbar(
                    count: list.length,
                    sortLabel: _sort.shortLabel,
                    filtersActive: _filters.activeCount,
                    onSort: _openSortSheet,
                    onFilter: facets == null ? null : _openFilterSheet,
                  ),
                  if (chips.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppliedFiltersRail(
                        chips: chips,
                        onRemove: (chip) => setState(
                          () => _filters = removeChip(_filters, chip),
                        ),
                        onClearAll: () =>
                            setState(() => _filters = FlightFilters.empty),
                      ),
                    ),
                ],
                Expanded(
                  child: list.isEmpty
                      // Two different dead ends: the supplier returned nothing
                      // for this route, or the user's own filters excluded
                      // everything. Only the second one is recoverable in place.
                      ? _filters.isEmpty
                            ? EmptyState(
                                title: _pickingReturn
                                    ? 'No return flights found'
                                    : 'No flights found',
                                message:
                                    'Try different dates or a nearby airport '
                                    '— this route may not have flights on the '
                                    'day you chose.',
                                icon: Icons.flight_takeoff_rounded,
                                actionLabel: 'Modify search',
                                onAction: _openModifySearch,
                              )
                            : EmptyState(
                                title: 'No flights match your filters',
                                message:
                                    'Clear a filter or two to see the '
                                    '${_source.length} flight'
                                    '${_source.length == 1 ? '' : 's'} on '
                                    'this route.',
                                icon: Icons.filter_alt_off_rounded,
                                actionLabel: 'Clear filters',
                                onAction: () => setState(
                                  () => _filters = FlightFilters.empty,
                                ),
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
                          itemBuilder: (context, i) {
                            final flight = list[i];
                            return FadeSlideIn(
                              delay: AppMotion.staggerFor(i),
                              child: _FlightCard(
                                key: ValueKey('$i-${flight.tripKey}'),
                                flight: flight,
                                pax: _pax,
                                actionLabel: _twoStep && _outbound == null
                                    ? 'Choose'
                                    : 'Book',
                                unavailableReason: _returnUnavailable(flight),
                                onPickFare: (id) => _pickFare(flight, id),
                                onSelect: () => _select(flight),
                                onDetails: () => showFlightDetailsSheet(
                                  context,
                                  flight: flight,
                                  pax: _pax,
                                  rules: _rules,
                                ),
                                onCompare: () async {
                                  final choice = await showFareCompareSheet(
                                    context,
                                    flight: flight,
                                    pax: _pax,
                                    rules: _rules,
                                  );
                                  if (choice == null || !mounted) return;
                                  _pickFare(flight, choice.fareId);
                                  if (choice.book) {
                                    _select(
                                      flight.withSelectedFare(choice.fareId),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            if (_busy)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.white.withValues(alpha: 0.72),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const AppLoader(),
                        const SizedBox(height: AppSpacing.md),
                        Text(_busyLabel!, style: AppText.bodyStrong),
                      ],
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

/// "Cheapest" and "Fastest" tiles, which the website offers above each results
/// column. Each doubles as a sort shortcut and as a preview of what that order
/// puts on top, so the traveller can see the trade-off before committing.
class _QuickPicks extends StatelessWidget {
  const _QuickPicks({
    required this.flights,
    required this.pax,
    required this.sort,
    required this.onSort,
  });

  final List<FlightResult> flights;
  final PaxCounts pax;
  final FlightSort sort;
  final ValueChanged<FlightSort> onSort;

  @override
  Widget build(BuildContext context) {
    if (flights.length < 2) return const SizedBox.shrink();

    final cheapest = sortFlights(flights, FlightSort.price, pax).firstOrNull;
    final fastest = sortFlights(flights, FlightSort.duration, pax).firstOrNull;
    if (cheapest == null || fastest == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: _QuickPickTile(
              icon: Icons.currency_rupee_rounded,
              title: 'Cheapest',
              flight: cheapest,
              pax: pax,
              active: sort == FlightSort.price,
              onTap: () => onSort(FlightSort.price),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _QuickPickTile(
              icon: Icons.bolt_rounded,
              title: 'Fastest',
              flight: fastest,
              pax: pax,
              active: sort == FlightSort.duration,
              onTap: () => onSort(FlightSort.duration),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickPickTile extends StatelessWidget {
  const _QuickPickTile({
    required this.icon,
    required this.title,
    required this.flight,
    required this.pax,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final FlightResult flight;
  final PaxCounts pax;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
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
            Icon(
              icon,
              size: 16,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppText.labelSm.copyWith(
                      color: active ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${formatFlightFare(tripBestPrice(flight.raw, pax))}'
                    '${flight.durationLabel.isEmpty ? '' : ' · ${flight.durationLabel}'}',
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
  }
}

/// Result count on the left, sort and filter entry points on the right.
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.count,
    required this.sortLabel,
    required this.filtersActive,
    required this.onSort,
    required this.onFilter,
  });

  final int count;
  final String sortLabel;
  final int filtersActive;
  final VoidCallback onSort;

  /// Null while there is nothing to build facets from.
  final VoidCallback? onFilter;

  @override
  Widget build(BuildContext context) {
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
              '$count flight${count == 1 ? '' : 's'}',
              style: AppText.labelSm,
            ),
          ),
          _ResultsToolbarButton(
            icon: Icons.swap_vert_rounded,
            label: sortLabel,
            active: true,
            onTap: onSort,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ResultsToolbarButton(
            icon: Icons.tune_rounded,
            label: filtersActive > 0 ? 'Filters ($filtersActive)' : 'Filters',
            active: filtersActive > 0,
            onTap: onFilter,
          ),
        ],
      ),
    );
  }
}

class _ResultsToolbarButton extends StatelessWidget {
  const _ResultsToolbarButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final tint = !enabled
        ? AppColors.textSecondary.withValues(alpha: 0.4)
        : active
        ? AppColors.primary
        : AppColors.textSecondary;

    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: active && enabled ? AppColors.pinkSurface : AppColors.surface,
          borderRadius: AppRadii.rPill,
          border: Border.all(
            color: active && enabled ? AppColors.primary : AppColors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: tint),
            const SizedBox(width: AppSpacing.xs),
            Text(label, style: AppText.buttonSm.copyWith(color: tint)),
          ],
        ),
      ),
    );
  }
}

/// One trip on the results list, with every fare it is sold at.
///
/// The web's card: airline and flight numbers, "View Details", seats left,
/// the route, two fare options with "+N more fares", "Compare" when there is
/// more than one fare, the next-day arrival notice, and BOOK.
class _FlightCard extends StatefulWidget {
  const _FlightCard({
    super.key,
    required this.flight,
    required this.pax,
    required this.onPickFare,
    required this.onSelect,
    required this.onDetails,
    required this.onCompare,
    this.actionLabel = 'Book',
    this.unavailableReason,
  });

  /// Set on a return that leaves before the outbound lands; the card is
  /// dimmed and says why.
  final String? unavailableReason;

  /// Already carries the traveller's chosen fare as its [FlightResult.id].
  final FlightResult flight;

  /// Needed to price the trip for the whole party, not just one adult.
  final PaxCounts pax;
  final ValueChanged<String> onPickFare;
  final VoidCallback onSelect;
  final VoidCallback onDetails;
  final VoidCallback onCompare;
  final String actionLabel;

  @override
  State<_FlightCard> createState() => _FlightCardState();
}

class _FlightCardState extends State<_FlightCard> {
  /// The web folds everything after the second fare behind "+N more fares".
  static const int _visibleFares = 2;

  bool _expanded = false;

  String _time(DateTime? d) {
    if (d == null) return '--:--';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _date(DateTime? d) {
    if (d == null) return '';
    const months = [
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
    return '${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    final flight = widget.flight;
    final fares = flight.fares;
    final visible = _expanded ? fares : fares.take(_visibleFares).toList();
    final seatsLeft = fareSeatsLeft(flight.selectedFare);
    final dayOffset = arrivalDayOffset(flight.raw);
    final numbers = [
      for (final s in flight.segments)
        '${asString(digPath(s, ['fD', 'aI', 'code']))}-'
            '${asString(digPath(s, ['fD', 'fN']))}',
    ].join(', ');

    final card = AppCard(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flight.airline.isNotEmpty
                          ? flight.airline
                          : flight.airlineCode,
                      style: AppText.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (numbers.isNotEmpty)
                      Text(
                        numbers,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (seatsLeft != null)
                Text(
                  'Seats left: $seatsLeft',
                  style: AppText.caption.copyWith(
                    color: seatsLeft <= 5
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontWeight: seatsLeft <= 5 ? FontWeight.w600 : null,
                  ),
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
                  Text(
                    '${flight.fromCode} · ${_date(flight.departure)}',
                    style: AppText.caption,
                  ),
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
                  Text(
                    '${flight.toCode} · ${_date(flight.arrival)}',
                    style: AppText.caption,
                  ),
                ],
              ),
            ],
          ),

          if (dayOffset > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.flight_land_rounded,
                  size: 13,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Flight arrives after $dayOffset day${dayOffset > 1 ? 's' : ''}',
                  style: AppText.caption.copyWith(color: AppColors.warning),
                ),
              ],
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Divider(height: 1, color: AppColors.divider),
          ),

          if (fares.isEmpty)
            Text('Price on review', style: AppText.bodySm)
          else
            for (final fare in visible)
              FlightFareOptionTile(
                fare: fare,
                pax: widget.pax,
                selected: asString(readKey(fare, 'id')) == flight.id,
                onTap: () => widget.onPickFare(asString(readKey(fare, 'id'))),
              ),
          if (fares.length > _visibleFares)
            PremiumButton.text(
              label: _expanded
                  ? 'Show less'
                  : '+${fares.length - _visibleFares} more fares',
              size: PremiumButtonSize.small,
              onPressed: () => setState(() => _expanded = !_expanded),
            ),

          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              PremiumButton.text(
                label: 'View details',
                size: PremiumButtonSize.small,
                onPressed: widget.onDetails,
              ),
              if (fares.length > 1)
                PremiumButton.text(
                  label: 'Compare',
                  size: PremiumButtonSize.small,
                  onPressed: widget.onCompare,
                ),
              const Spacer(),
              PremiumButton(
                label: widget.actionLabel,
                size: PremiumButtonSize.small,
                expanded: false,
                onPressed: widget.onSelect,
              ),
            ],
          ),
        ],
      ),
    );
    final reason = widget.unavailableReason;
    if (reason == null) return card;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(opacity: 0.45, child: IgnorePointer(child: card)),
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

// ---------------------------------------------------------------------------
// Previous results screen and card, kept for reference.
//
// Replaced to match FlightSearchResults.jsx: the card offered one fare chosen
// automatically, there were no fare details, rules or comparison, the fare was
// only reviewed on the booking screen (so a gone fare could not refresh the
// list), and there was no date strip, share, modify search or Return Special.
// ---------------------------------------------------------------------------

// class FlightResultsPage extends StatefulWidget {
//   const FlightResultsPage({
//     super.key,
//     required this.api,
//     required this.from,
//     required this.to,
//     required this.departure,
//     required this.results,
//     required this.adults,
//     this.returnDate,
//     this.children = 0,
//     this.infants = 0,
//     this.cabinClass = 'ECONOMY',
//   });
//
//   final HoneymoonApi api;
//   final FlightLocation from;
//   final FlightLocation to;
//   final DateTime departure;
//   final DateTime? returnDate;
//   final FlightSearchResult results;
//   final int adults;
//   final int children;
//   final int infants;
//   final String cabinClass;
//
//   @override
//   State<FlightResultsPage> createState() => _FlightResultsPageState();
// }
//
// class _FlightResultsPageState extends State<FlightResultsPage> {
//   /// Set once the outbound has been chosen on a round trip; the list then
//   /// switches to the return leg.
//   FlightResult? _outbound;
//
//   /// Sorting and filtering are per-leg on purpose: the outbound and the return
//   /// are separate result sets with separate facets, exactly as the website
//   /// treats its two columns.
//   FlightSort _sort = FlightSort.price;
//   FlightFilters _filters = FlightFilters.empty;
//
//   bool get _twoStep => widget.results.hasSeparateReturn;
//
//   bool get _pickingReturn => _twoStep && _outbound != null;
//
//   PaxCounts get _pax => PaxCounts(
//     adults: widget.adults,
//     children: widget.children,
//     infants: widget.infants,
//   );
//
//   /// The unfiltered set for the leg on screen. Facets are always derived from
//   /// this, so option counts stay stable as the user narrows down instead of
//   /// collapsing toward zero.
//   List<FlightResult> get _source =>
//       _pickingReturn ? widget.results.inbound : widget.results.onward;
//
//   /// On the return leg the route is reversed, which matters to the
//   /// "hide nearby airports" filter.
//   String get _legFrom =>
//       _pickingReturn ? widget.to.code : widget.from.code;
//   String get _legTo => _pickingReturn ? widget.from.code : widget.to.code;
//
//   FlightFacets? get _facets => deriveFacets(_source, _pax);
//
//   List<FlightResult> get _filtered => sortFlights(
//     filterFlights(
//       _source,
//       _filters,
//       searchFrom: _legFrom,
//       searchTo: _legTo,
//       pax: _pax,
//     ),
//     _sort,
//     _pax,
//   );
//
//   /// Switching legs keeps the user's intent but drops anything the new result
//   /// set cannot satisfy — otherwise a `stops: {0}` carried over from an
//   /// outbound with non-stops empties a return that has none.
//   void _setOutbound(FlightResult? flight) {
//     setState(() {
//       _outbound = flight;
//       _filters = reconcileFilters(_filters, deriveFacets(_source, _pax));
//     });
//   }
//
//   Future<void> _openFilterSheet() async {
//     final facets = _facets;
//     if (facets == null) return;
//
//     final result = await showFlightFilterSheet(
//       context,
//       facets: facets,
//       current: _filters,
//       flights: _source,
//       pax: _pax,
//       searchFrom: _legFrom,
//       searchTo: _legTo,
//     );
//     if (result != null && mounted) setState(() => _filters = result);
//   }
//
//   Future<void> _openSortSheet() async {
//     await AppBottomSheet.show(
//       context,
//       title: 'Sort by',
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           for (final option in FlightSort.values)
//             Pressable(
//               onTap: () {
//                 Navigator.pop(context);
//                 if (option != _sort) setState(() => _sort = option);
//               },
//               borderRadius: AppRadii.rMd,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   vertical: AppSpacing.md,
//                   horizontal: AppSpacing.sm,
//                 ),
//                 child: Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         option.label,
//                         style: option == _sort
//                             ? AppText.bodyStrong.copyWith(
//                                 color: AppColors.primary,
//                               )
//                             : AppText.body,
//                       ),
//                     ),
//                     if (option == _sort)
//                       const Icon(
//                         Icons.check_rounded,
//                         size: 20,
//                         color: AppColors.primary,
//                       ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   FlightTripContext get _trip => FlightTripContext(
//     from: widget.from,
//     to: widget.to,
//     departure: widget.departure,
//     returnDate: widget.returnDate,
//     adults: widget.adults,
//     children: widget.children,
//     infants: widget.infants,
//     cabinClass: widget.cabinClass,
//   );
//
//   void _select(FlightResult flight) {
//     if (_twoStep && _outbound == null) {
//       _setOutbound(flight);
//       return;
//     }
//     Navigator.push(
//       context,
//       AnimatedPageRoute(
//         page: FlightBookingPage(
//           api: widget.api,
//           trip: _trip,
//           outbound: _outbound ?? flight,
//           inbound: _outbound == null ? null : flight,
//         ),
//         style: PageTransitionStyle.slideRight,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final list = _filtered;
//     final facets = _facets;
//     final chips = describeFilters(_filters, facets);
//
//     return PopScope(
//       // On a round trip, back from the return list means "pick a different
//       // outbound", not "abandon the search".
//       canPop: !_pickingReturn,
//       onPopInvokedWithResult: (didPop, _) {
//         if (!didPop) _setOutbound(null);
//       },
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: AppTopBar(
//           elevated: true,
//           onBack: _pickingReturn ? () => _setOutbound(null) : null,
//           titleWidget: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 _pickingReturn
//                     ? '${widget.to.code} → ${widget.from.code}'
//                     : '${widget.from.code} → ${widget.to.code}',
//                 style: AppText.cardTitle,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//               Text(
//                 _pickingReturn
//                     ? 'Return · ${formatTripDate(widget.returnDate)}'
//                     : _twoStep
//                     ? 'Departure · ${formatTripDate(widget.departure)}'
//                     : widget.returnDate == null
//                     ? formatTripDate(widget.departure)
//                     : '${formatTripDate(widget.departure)} – '
//                           '${formatTripDate(widget.returnDate)}',
//                 style: AppText.caption,
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//         body: Column(
//           children: [
//             if (_twoStep)
//               _LegProgress(
//                 pickingReturn: _pickingReturn,
//                 outbound: _outbound,
//                 onChangeOutbound: () => _setOutbound(null),
//               ),
//
//             if (_source.isNotEmpty) ...[
//               _QuickPicks(
//                 flights: _source,
//                 pax: _pax,
//                 sort: _sort,
//                 onSort: (s) => setState(() => _sort = s),
//               ),
//               _Toolbar(
//                 count: list.length,
//                 sortLabel: _sort.shortLabel,
//                 filtersActive: _filters.activeCount,
//                 onSort: _openSortSheet,
//                 onFilter: facets == null ? null : _openFilterSheet,
//               ),
//               if (chips.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: AppSpacing.sm),
//                   child: AppliedFiltersRail(
//                     chips: chips,
//                     onRemove: (chip) =>
//                         setState(() => _filters = removeChip(_filters, chip)),
//                     onClearAll: () =>
//                         setState(() => _filters = FlightFilters.empty),
//                   ),
//                 ),
//             ],
//
//             Expanded(
//               child: list.isEmpty
//                   // Two different dead ends: the supplier returned nothing for
//                   // this route, or the user's own filters excluded everything.
//                   // Only the second one is recoverable in place.
//                   ? _filters.isEmpty
//                         ? EmptyState(
//                             title: _pickingReturn
//                                 ? 'No return flights found'
//                                 : 'No flights found',
//                             message:
//                                 'Try different dates or a nearby airport — this '
//                                 'route may not have flights on the day you chose.',
//                             icon: Icons.flight_takeoff_rounded,
//                           )
//                         : EmptyState(
//                             title: 'No flights match your filters',
//                             message:
//                                 'Clear a filter or two to see the '
//                                 '${_source.length} flight'
//                                 '${_source.length == 1 ? '' : 's'} on this route.',
//                             icon: Icons.filter_alt_off_rounded,
//                             actionLabel: 'Clear filters',
//                             onAction: () =>
//                                 setState(() => _filters = FlightFilters.empty),
//                           )
//                   : ListView.separated(
//                       padding: const EdgeInsets.fromLTRB(
//                         AppSpacing.lg,
//                         AppSpacing.lg,
//                         AppSpacing.lg,
//                         AppSpacing.xxxl,
//                       ),
//                       itemCount: list.length,
//                       separatorBuilder: (_, _) =>
//                           const SizedBox(height: AppSpacing.md),
//                       itemBuilder: (context, i) => FadeSlideIn(
//                         delay: AppMotion.staggerFor(i),
//                         child: _FlightCard(
//                           flight: list[i],
//                           pax: _pax,
//                           actionLabel: _twoStep && _outbound == null
//                               ? 'Choose'
//                               : 'Select',
//                           onSelect: () => _select(list[i]),
//                         ),
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _FlightCard extends StatelessWidget {
//   const _FlightCard({
//     required this.flight,
//     required this.pax,
//     required this.onSelect,
//     this.actionLabel = 'Select',
//   });
//
//   final FlightResult flight;
//
//   /// Needed to price the trip for the whole party, not just one adult.
//   final PaxCounts pax;
//   final VoidCallback onSelect;
//   final String actionLabel;
//
//   String _time(DateTime? d) {
//     if (d == null) return '--:--';
//     final h = d.hour.toString().padLeft(2, '0');
//     final m = d.minute.toString().padLeft(2, '0');
//     return '$h:$m';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       onTap: onSelect,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               if (flight.airlineCode.isNotEmpty) ...[
//                 AirlineLogo(code: flight.airlineCode),
//                 const SizedBox(width: AppSpacing.sm),
//               ],
//               Expanded(
//                 child: Text(
//                   flight.airline.isNotEmpty
//                       ? flight.airline
//                       : flight.airlineCode,
//                   style: AppText.cardTitle,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               if (flight.flightNumber.isNotEmpty)
//                 MetaChip(
//                   label: '${flight.airlineCode} ${flight.flightNumber}'.trim(),
//                 ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//
//           Row(
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(_time(flight.departure), style: AppText.sectionTitle),
//                   Text(flight.fromCode, style: AppText.caption),
//                 ],
//               ),
//               Expanded(
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: AppSpacing.md,
//                   ),
//                   child: Column(
//                     children: [
//                       if (flight.durationLabel.isNotEmpty)
//                         Text(
//                           flight.durationLabel,
//                           style: AppText.caption,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       const SizedBox(height: 3),
//                       const Row(
//                         children: [
//                           Icon(
//                             Icons.circle,
//                             size: 6,
//                             color: AppColors.textTertiary,
//                           ),
//                           Expanded(
//                             child: Divider(
//                               color: AppColors.divider,
//                               thickness: 1,
//                             ),
//                           ),
//                           Icon(
//                             Icons.flight_rounded,
//                             size: 14,
//                             color: AppColors.primary,
//                           ),
//                           Expanded(
//                             child: Divider(
//                               color: AppColors.divider,
//                               thickness: 1,
//                             ),
//                           ),
//                           Icon(
//                             Icons.circle,
//                             size: 6,
//                             color: AppColors.textTertiary,
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 3),
//                       Text(
//                         flight.stopsLabel,
//                         style: AppText.caption,
//                         maxLines: 1,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.end,
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(_time(flight.arrival), style: AppText.sectionTitle),
//                   Text(flight.toCode, style: AppText.caption),
//                 ],
//               ),
//             ],
//           ),
//
//           const Padding(
//             padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
//             child: Divider(height: 1, color: AppColors.divider),
//           ),
//           Row(
//             children: [
//               Expanded(
//                 child: Builder(
//                   builder: (context) {
//                     // The card leads with what the party actually pays, which
//                     // is the figure the review step and the website both show.
//                     // Leading with the per-adult fare instead meant a couple
//                     // saw half the real price right up to checkout.
//                     final total = tripBestPrice(flight.raw, pax);
//                     if (total <= 0) {
//                       return Text('Price on review', style: AppText.bodySm);
//                     }
//                     final travellers =
//                         pax.adults + pax.children + pax.infants;
//                     return Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Text(
//                           travellers > 1
//                               ? 'for $travellers travellers'
//                               : 'per adult',
//                           style: AppText.caption,
//                         ),
//                         Text(
//                           formatPrice(total),
//                           style: AppText.price,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                         if (travellers > 1 && flight.price > 0)
//                           Text(
//                             '${formatPrice(flight.price)} per adult',
//                             style: AppText.caption,
//                           ),
//                       ],
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               PremiumButton(
//                 label: actionLabel,
//                 size: PremiumButtonSize.small,
//                 expanded: false,
//                 onPressed: onSelect,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
