/// Flight search form + results, backed by `GET /tj/meta/locations` and
/// `POST /tj/fms/search`.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/honeymoon_models.dart';
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
      final flights = await widget.api.searchFlights(
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
            from: _from!,
            to: _to!,
            departure: _departure!,
            returnDate: _roundTrip ? _returnDate : null,
            flights: flights,
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

class FlightResultsPage extends StatelessWidget {
  const FlightResultsPage({
    super.key,
    required this.from,
    required this.to,
    required this.departure,
    required this.flights,
    this.returnDate,
  });

  final FlightLocation from;
  final FlightLocation to;
  final DateTime departure;
  final DateTime? returnDate;
  final List<FlightResult> flights;

  @override
  Widget build(BuildContext context) {
    final sorted = List<FlightResult>.from(flights)
      ..sort((a, b) => a.price.compareTo(b.price));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${from.code} → ${to.code}',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              returnDate == null
                  ? formatTripDate(departure)
                  : '${formatTripDate(departure)} – ${formatTripDate(returnDate)}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: sorted.isEmpty
          ? const EmptyState(
              title: 'No flights found',
              message: 'Try different dates or nearby airports.',
              icon: Icons.flight_takeoff_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) => FadeSlideIn(
                delay: AppMotion.staggerFor(i),
                child: _FlightCard(flight: sorted[i]),
              ),
            ),
    );
  }
}

class _FlightCard extends StatelessWidget {
  const _FlightCard({required this.flight});

  final FlightResult flight;

  String _time(DateTime? d) {
    if (d == null) return '--:--';
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  flight.airline.isNotEmpty ? flight.airline : flight.airlineCode,
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
                        Text(flight.durationLabel, style: AppText.caption),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.textTertiary,
                          ),
                          const Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          const Icon(
                            Icons.flight_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          const Icon(
                            Icons.circle,
                            size: 6,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(flight.stopsLabel, style: AppText.caption),
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

          if (flight.price > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(formatPrice(flight.price), style: AppText.price),
                ),
                PremiumButton(
                  label: 'Select',
                  size: PremiumButtonSize.small,
                  onPressed: () => AppSnackbar.info(
                    context,
                    'Flight checkout is not connected in the app yet.',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}