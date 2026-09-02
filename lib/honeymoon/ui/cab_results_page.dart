/// Airport transfers / car rental, backed by:
///   POST tripjack-cabs/search-locations  (Google Places autocomplete)
///   POST tripjack-cabs/lat-long          (place id → coordinates)
///   POST tripjack-cabs/quotes            (vehicle quotes)
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../honeymoon_config.dart';
import '../models/honeymoon_models.dart';
import 'booking/cab_booking_page.dart';
import 'widgets/honeymoon_widgets.dart';

/// A place the user picked, plus the coordinates the quotes call needs.
class _CabPlace {
  const _CabPlace({required this.label, required this.node});

  final String label;
  final Map<String, dynamic> node;
}

// ---------------------------------------------------------------------------
// Search form
// ---------------------------------------------------------------------------

class CabSearchForm extends StatefulWidget {
  const CabSearchForm({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<CabSearchForm> createState() => _CabSearchFormState();
}

class _CabSearchFormState extends State<CabSearchForm> {
  _CabPlace? _pickup;
  _CabPlace? _drop;
  DateTime? _pickupDate;
  TimeOfDay? _pickupTime;

  bool _submitting = false;
  String? _placeError;
  String? _dateError;

  Future<void> _pickPlace({required bool isPickup}) async {
    final picked = await AppBottomSheet.show<_CabPlace>(
      context,
      title: isPickup ? 'Pick-up location' : 'Drop-off location',
      child: _PlaceSearchSheet(api: widget.api),
    );
    if (picked == null) return;
    setState(() {
      if (isPickup) {
        _pickup = picked;
      } else {
        _drop = picked;
      }
      _placeError = null;
    });
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _pickupDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(
        const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
      ),
      helpText: 'Select pick-up date',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: _pickupTime ?? const TimeOfDay(hour: 10, minute: 0),
      helpText: 'Select pick-up time',
    );
    if (!mounted) return;

    setState(() {
      _pickupDate = date;
      _pickupTime = time ?? _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
      _dateError = null;
    });
  }

  DateTime? get _pickupAt {
    if (_pickupDate == null) return null;
    final t = _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
    return DateTime(
      _pickupDate!.year,
      _pickupDate!.month,
      _pickupDate!.day,
      t.hour,
      t.minute,
    );
  }

  bool _validate() {
    setState(() {
      _placeError = (_pickup == null || _drop == null)
          ? 'Choose both a pick-up and drop-off location'
          : null;
      _dateError = _pickupDate == null ? 'Select when you need the car' : null;
    });
    return _placeError == null && _dateError == null;
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      final result = await widget.api.fetchCabQuotes(
        origin: _pickup!.node,
        destination: _drop!.node,
        pickupAt: _pickupAt!,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: CabResultsPage(
            api: widget.api,
            pickupLabel: _pickup!.label,
            dropLabel: _drop!.label,
            pickupAt: _pickupAt!,
            result: result,
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
    final at = _pickupAt;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Pick-up'),
        TapField(
          icon: Icons.trip_origin_rounded,
          value: _pickup?.label ?? '',
          placeholder: 'Airport, hotel or address',
          onTap: () => _pickPlace(isPickup: true),
        ),
        const SizedBox(height: AppSpacing.md),

        const FieldLabel('Drop-off'),
        TapField(
          icon: Icons.place_rounded,
          value: _drop?.label ?? '',
          placeholder: 'Airport, hotel or address',
          onTap: () => _pickPlace(isPickup: false),
          errorText: _placeError,
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Pick-up date & time'),
        TapField(
          icon: Icons.schedule_rounded,
          value: at == null
              ? ''
              : '${formatTripDate(at)} · '
                    '${at.hour.toString().padLeft(2, '0')}:'
                    '${at.minute.toString().padLeft(2, '0')}',
          placeholder: 'When do you need the car?',
          onTap: _pickDateTime,
          errorText: _dateError,
        ),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: 'Find Transfers',
          icon: Icons.directions_car_filled_outlined,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }
}

/// Two-step picker: Places autocomplete, then resolve to coordinates.
class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet({required this.api});

  final HoneymoonApi api;

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _results = const [];
  bool _loading = false;
  bool _resolving = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _results = const [];
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 380), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final places = await widget.api.searchCabLocations(value);
        if (!mounted) return;
        setState(() {
          _results = places;
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

  Future<void> _select(Map<String, dynamic> place) async {
    final placeId = asString(place['id'] ?? place['value']);
    final label = firstNonEmpty([
      place['displayLabel'],
      place['name'],
    ], fallback: 'Selected location');

    if (placeId.isEmpty) {
      AppSnackbar.error(context, "We couldn't resolve that location.");
      return;
    }

    setState(() => _resolving = true);
    try {
      final details = await widget.api.fetchCabPlaceDetails(placeId);
      if (!mounted) return;

      final node = HoneymoonApi.buildCabLocationNode(
        displayAddress: label,
        details: details,
      );

      // Quotes need coordinates; without them the request is pointless.
      if (asString(node['lat']).isEmpty || asString(node['long']).isEmpty) {
        setState(() => _resolving = false);
        AppSnackbar.error(
          context,
          "We couldn't pin that location. Please pick another.",
        );
        return;
      }

      Navigator.pop(context, _CabPlace(label: label, node: node));
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() => _resolving = false);
      AppSnackbar.error(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _controller,
          hint: 'Airport, hotel or address',
          prefixIcon: Icons.search_rounded,
          autofocus: true,
          enabled: !_resolving,
          onChanged: _onChanged,
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(height: 280, child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_resolving) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoader(),
          SizedBox(height: AppSpacing.md),
          Text('Pinning that location…'),
        ],
      );
    }

    if (_loading) return const AppLoader();

    if ((_error ?? '').isNotEmpty) {
      return ErrorState(
        compact: true,
        title: "Couldn't search locations",
        message: _error,
        padding: EdgeInsets.zero,
      );
    }

    if (_results.isEmpty) {
      return EmptyState(
        compact: true,
        title: _controller.text.trim().length < 3
            ? 'Search for a place'
            : 'No places found',
        message: _controller.text.trim().length < 3
            ? 'Type at least three letters.'
            : 'Try a different address or landmark.',
        icon: Icons.place_outlined,
        padding: EdgeInsets.zero,
      );
    }

    return ListView.separated(
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final place = _results[i];
        final label = firstNonEmpty([
          place['displayLabel'],
          place['name'],
        ], fallback: 'Location');

        return Pressable(
          onTap: () => _select(place),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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

class CabResultsPage extends StatelessWidget {
  const CabResultsPage({
    super.key,
    required this.api,
    required this.pickupLabel,
    required this.dropLabel,
    required this.pickupAt,
    required this.result,
  });

  final HoneymoonApi api;
  final String pickupLabel;
  final String dropLabel;
  final DateTime pickupAt;

  /// The whole quotes response: booking echoes its journey and route blocks
  /// straight back, so the options cannot be separated from their context.
  final CabQuoteResult result;

  @override
  Widget build(BuildContext context) {
    // Already cheapest-first out of the model, but sorting here keeps the
    // ordering guaranteed at the point it is rendered.
    final sorted = List<CabQuote>.from(result.quotes)
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
              'Transfers',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$pickupLabel → $dropLabel',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: sorted.isEmpty
          ? const EmptyState(
              title: 'No vehicles available',
              message: 'Try a different pick-up time or nearby location.',
              icon: Icons.directions_car_filled_outlined,
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
                child: _CabCard(
                  quote: sorted[i],
                  onSelect: () => Navigator.push(
                    context,
                    AnimatedPageRoute(
                      page: CabBookingPage(
                        api: api,
                        quote: sorted[i],
                        result: result,
                        pickupLabel: pickupLabel,
                        dropLabel: dropLabel,
                        pickupAt: pickupAt,
                      ),
                      style: PageTransitionStyle.slideRight,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _CabCard extends StatelessWidget {
  const _CabCard({required this.quote, required this.onSelect});

  final CabQuote quote;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          if (quote.imageUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: NetworkImageWidget(
                url: quote.imageUrl,
                width: 72,
                height: 56,
                radius: AppRadii.md,
                memCacheWidth: 220,
              ),
            )
          else
            Container(
              width: 72,
              height: 56,
              margin: const EdgeInsets.only(right: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.pinkSurface,
                borderRadius: AppRadii.rMd,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
              ),
            ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quote.vehicleName,
                  style: AppText.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (quote.category.isNotEmpty || quote.seats > 0) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (quote.category.isNotEmpty)
                        MetaChip(label: quote.category),
                      if (quote.seats > 0)
                        MetaChip(
                          icon: Icons.event_seat_rounded,
                          label: '${quote.seats} seats',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Text(formatPrice(quote.price), style: AppText.price),
              ],
            ),
          ),

          PremiumButton(
            label: 'Select',
            size: PremiumButtonSize.small,
            expanded: false,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }
}