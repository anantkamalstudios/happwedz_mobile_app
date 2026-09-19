/// Car rental (TripJack cabs) — search form and results, backed by:
///   POST tripjack-cabs/search-locations  (Google Places autocomplete)
///   POST tripjack-cabs/lat-long          (place id → coordinates)
///   POST tripjack-cabs/quotes            (vehicle quotes)
///
/// Mirrors `CarRentalSearchForm.jsx`, `CabLocationField.jsx`,
/// `CabDateTimeField.jsx`, `CabPaxField.jsx` and `CabSearchResults.jsx`:
///
/// ```
/// form     Airport Transfers | Outstation | Local
///          From ⇄ To (pick a suggestion) · pickup (≥ 2 h out)
///          · return (optional → round trip, ≥ 30 min after pickup)
///          · passengers 1–10, bags 0–10
/// results  POST quotes → skeleton → supplier error / "No cabs available" /
///          one card per vehicle class (cheapest; siblings behind Compare),
///          fare breakdown, policies, Book Cab; Edit search re-runs in place
/// ```
library;

import 'dart:async';

import 'package:flutter/cupertino.dart'
    show CupertinoDatePicker, CupertinoDatePickerMode;
import 'package:flutter/material.dart';

import '../../authservice.dart';
import '../../core/core.dart';
import '../data/cab_draft_store.dart';
import '../data/honeymoon_api.dart';
import '../models/cab_models.dart';
import '../models/honeymoon_models.dart';
import 'booking/booking_widgets.dart' show InfoBanner, InfoTone;
import 'booking/cab_booking_page.dart';
import 'widgets/cab_policy_sheet.dart';
import 'widgets/honeymoon_widgets.dart';

// ---------------------------------------------------------------------------
// Search form
// ---------------------------------------------------------------------------

/// The car-rental search card. On the landing page it opens the results; in
/// the results page's "Edit search" sheet ([onSearch] set) it hands the new
/// query back instead, like the web's editable bar and Update Search.
class CabSearchForm extends StatefulWidget {
  const CabSearchForm({
    super.key,
    required this.api,
    this.initial,
    this.onSearch,
    this.submitLabel = 'Search Cabs',
  });

  final HoneymoonApi api;

  /// The search to edit, when the form is reopened from the results.
  final CabSearchQuery? initial;
  final ValueChanged<CabSearchQuery>? onSearch;
  final String submitLabel;

  @override
  State<CabSearchForm> createState() => _CabSearchFormState();
}

class _CabSearchFormState extends State<CabSearchForm> {
  CabJourneyType _journeyType = CabJourneyType.airportTransfer;

  /// Resolved location nodes (`buildCabLocationNode`); null until a
  /// suggestion is picked, which the web requires.
  Map<String, dynamic>? _origin;
  Map<String, dynamic>? _destination;

  DateTime? _pickupAt;
  DateTime? _returnAt;
  int _passengers = CabLimits.minPassengers;
  int _bags = CabLimits.defaultBags;

  String? _error;

  @override
  void initState() {
    super.initState();
    final q = widget.initial;
    if (q != null) {
      _journeyType = q.journeyType;
      _origin = q.origin;
      _destination = q.destination;
      _pickupAt = q.pickupAt;
      _returnAt = q.returnAt;
      _passengers = q.passengers;
      _bags = q.bags;
    }
  }

  String _label(Map<String, dynamic>? node) =>
      node == null ? '' : asString(readKey(node, 'displayAddress'));

  Future<void> _pickPlace({required bool isOrigin}) async {
    final picked = await AppBottomSheet.show<Map<String, dynamic>>(
      context,
      title: isOrigin ? 'Where from?' : 'Where to?',
      child: _PlaceSearchSheet(api: widget.api),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isOrigin) {
        _origin = picked;
      } else {
        _destination = picked;
      }
      _error = null;
    });
  }

  /// Swap pick-up and drop-off, as the portal's ⇄ does.
  void _swap() => setState(() {
    final from = _origin;
    _origin = _destination;
    _destination = from;
  });

  Future<void> _pickPickup() async {
    final today = DateTime.now();
    final picked = await AppBottomSheet.show<DateTime>(
      context,
      title: 'Pick-up date and time',
      child: _CabDateTimeSheet(
        initial:
            _pickupAt ??
            DateTime(
              today.year,
              today.month,
              today.day,
              CabLimits.defaultPickupHour,
            ),
        firstDate: DateTime(today.year, today.month, today.day),
        validate: (at) => cabPickupProblem(at),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _pickupAt = picked;
      _error = null;
    });
  }

  Future<void> _pickReturn() async {
    final pickup = _pickupAt;
    final today = DateTime.now();
    final base = pickup ?? today;
    final picked = await AppBottomSheet.show<DateTime>(
      context,
      title: 'Return date and time',
      child: _CabDateTimeSheet(
        initial:
            _returnAt ??
            DateTime(
              base.year,
              base.month,
              base.day,
              CabLimits.defaultReturnHour,
            ),
        firstDate: DateTime(base.year, base.month, base.day),
        validate: (at) => cabReturnProblem(pickup, at),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _returnAt = picked;
      _error = null;
    });
  }

  /// `handleSearch`'s checks, in its order and with its messages.
  String? _problem() {
    if (_origin == null) {
      return 'Please select a pick-up location from the suggestions.';
    }
    if (_destination == null) {
      return 'Please select a drop-off location from the suggestions.';
    }
    final pickup = _pickupAt;
    if (pickup == null) return 'Please select a pick-up date.';
    // Re-run the picker's own rules: changing the pickup after a return was
    // applied can leave a pair that was valid when set and is not now.
    final pickupProblem = cabPickupProblem(pickup);
    if (pickupProblem != null) return pickupProblem;
    final ret = _returnAt;
    if (ret != null) return cabReturnProblem(pickup, ret);
    return null;
  }

  Future<void> _search() async {
    FocusScope.of(context).unfocus();
    final problem = _problem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final query = CabSearchQuery(
      journeyType: _journeyType,
      origin: _origin!,
      destination: _destination!,
      pickupAt: _pickupAt!,
      returnAt: _returnAt,
      passengers: _passengers,
      bags: _bags,
    );
    setState(() => _error = null);

    final onSearch = widget.onSearch;
    if (onSearch != null) {
      onSearch(query);
      return;
    }
    await Navigator.push(
      context,
      AnimatedPageRoute(
        page: CabResultsPage(api: widget.api, query: query),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickupAt;
    final ret = _returnAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The portal's radio group: mutually exclusive, and each reshapes
        // the search.
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final type in CabJourneyType.values)
              ChoiceChip(
                label: Text(type.label),
                selected: _journeyType == type,
                selectedColor: AppColors.pinkSurface,
                onSelected: (_) => setState(() => _journeyType = type),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Pick-up and drop-off read as one route control with the swap
        // between them.
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const FieldLabel('From'),
                  TapField(
                    icon: Icons.local_taxi_rounded,
                    value: _label(_origin),
                    placeholder: 'Where from?',
                    onTap: () => _pickPlace(isOrigin: true),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const FieldLabel('To'),
                  TapField(
                    icon: Icons.place_rounded,
                    value: _label(_destination),
                    placeholder: 'Where to?',
                    onTap: () => _pickPlace(isOrigin: false),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            IconButton.filledTonal(
              tooltip: 'Swap pick-up and drop-off',
              onPressed: _swap,
              icon: const Icon(Icons.swap_vert_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        const FieldLabel('Pick-up date and time'),
        TapField(
          icon: Icons.event_rounded,
          value: pickup == null ? '' : formatCabDateTime(pickup),
          placeholder: 'Pick-up date and time',
          onTap: _pickPickup,
        ),
        const SizedBox(height: AppSpacing.md),

        const FieldLabel('Return (optional)'),
        Row(
          children: [
            Expanded(
              child: TapField(
                icon: Icons.event_repeat_rounded,
                value: ret == null ? '' : formatCabDateTime(ret),
                placeholder: 'Select return date and time',
                onTap: _pickReturn,
              ),
            ),
            if (ret != null)
              IconButton(
                tooltip: 'Clear return',
                onPressed: () => setState(() => _returnAt = null),
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        CounterRow(
          title: 'Passengers',
          subtitle: 'Up to ${CabLimits.maxPassengers}',
          value: _passengers,
          min: CabLimits.minPassengers,
          max: CabLimits.maxPassengers,
          onChanged: (v) => setState(() => _passengers = v),
        ),
        const SizedBox(height: AppSpacing.md),
        CounterRow(
          title: 'Bags',
          subtitle: 'Up to ${CabLimits.maxBags}',
          value: _bags,
          min: CabLimits.minBags,
          max: CabLimits.maxBags,
          onChanged: (v) => setState(() => _bags = v),
        ),

        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _error!,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: widget.submitLabel,
          icon: Icons.search_rounded,
          onPressed: _search,
        ),
      ],
    );
  }
}

/// `CabLocationField`: Places autocomplete from two characters (debounced
/// 350 ms), then the pick resolved to coordinates — the node the quotes call
/// needs. Pops the node.
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

  /// Guards against an older, slower lookup overwriting a newer one — the
  /// web aborts the previous request for the same reason.
  int _generation = 0;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final generation = ++_generation;
    if (value.trim().length < CabLimits.minLocationQuery) {
      setState(() {
        _results = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final places = await widget.api.searchCabLocations(value);
        if (!mounted || generation != _generation) return;
        setState(() {
          _results = places;
          _loading = false;
        });
      } on HoneymoonApiException catch (e) {
        if (!mounted || generation != _generation) return;
        setState(() {
          _loading = false;
          _results = const [];
          _error = e.message;
        });
      }
    });
  }

  Future<void> _select(Map<String, dynamic> place) async {
    // `originPlace.value || originPlace.id`, as the web resolves it.
    final placeId = firstNonEmpty([place['value'], place['id']]);
    final label = firstNonEmpty([
      place['displayLabel'],
      place['name'],
    ], fallback: 'Selected location');

    if (placeId.isEmpty) {
      AppSnackbar.error(
        context,
        'Could not resolve the selected locations. Please try again.',
      );
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
          'Could not resolve the selected locations. Please try again.',
        );
        return;
      }

      Navigator.pop(context, node);
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
        SizedBox(height: 300, child: _buildBody()),
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

    if (_loading) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppLoader(),
          SizedBox(height: AppSpacing.md),
          Text('Searching…'),
        ],
      );
    }

    if ((_error ?? '').isNotEmpty) {
      return ErrorState(
        compact: true,
        title: "Couldn't search locations",
        message: _error,
        padding: EdgeInsets.zero,
      );
    }

    final typed = _controller.text.trim().length >= CabLimits.minLocationQuery;
    if (_results.isEmpty) {
      return EmptyState(
        compact: true,
        title: typed ? 'No locations found' : 'Search for a place',
        message: typed
            ? 'Try a different address or landmark.'
            : 'Type at least two letters.',
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
        final full = asString(place['displayLabel']);
        final head = asString(place['name']);
        // The web shows the name bold and the rest of the label under it.
        final title = head.isNotEmpty ? head : full;
        var rest = '';
        if (head.isNotEmpty && full.startsWith(head)) {
          rest = full
              .substring(head.length)
              .replaceFirst(RegExp(r'^[,\s]+'), '');
        } else if (full != head) {
          rest = full;
        }

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title.isEmpty ? 'Location' : title,
                        style: AppText.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (rest.isNotEmpty)
                        Text(
                          rest,
                          style: AppText.caption,
                          maxLines: 2,
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

/// `CabDateTimeField`'s popover: a month grid, and the moment a day is
/// picked it moves straight to the time step. The rule for this field is
/// checked live — the message shows while the clock is turned, and Apply
/// stays disabled until it clears. Pops the chosen date-time.
class _CabDateTimeSheet extends StatefulWidget {
  const _CabDateTimeSheet({
    required this.initial,
    required this.firstDate,
    required this.validate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final String? Function(DateTime at) validate;

  @override
  State<_CabDateTimeSheet> createState() => _CabDateTimeSheetState();
}

class _CabDateTimeSheetState extends State<_CabDateTimeSheet> {
  late DateTime _date = DateTime(
    widget.initial.year,
    widget.initial.month,
    widget.initial.day,
  );
  late int _hour = widget.initial.hour;
  late int _minute = widget.initial.minute;
  bool _timeStep = false;

  DateTime get _draft =>
      DateTime(_date.year, _date.month, _date.day, _hour, _minute);

  @override
  Widget build(BuildContext context) {
    final first = widget.firstDate;
    final initialDate = _date.isBefore(first) ? first : _date;

    if (!_timeStep) {
      return SizedBox(
        height: 340,
        child: CalendarDatePicker(
          initialDate: initialDate,
          firstDate: first,
          lastDate: first.add(const Duration(days: 365)),
          onDateChanged: (d) => setState(() {
            _date = d;
            _timeStep = true;
          }),
        ),
      );
    }

    final problem = widget.validate(_draft);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.event_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                formatCabDateTime(_date, withTime: false),
                style: AppText.bodyStrong,
              ),
            ),
            PremiumButton.text(
              label: 'Edit date',
              size: PremiumButtonSize.small,
              onPressed: () => setState(() => _timeStep = false),
            ),
          ],
        ),
        SizedBox(
          height: 180,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            use24hFormat: false,
            initialDateTime: _draft,
            onDateTimeChanged: (t) => setState(() {
              _hour = t.hour;
              _minute = t.minute;
            }),
          ),
        ),
        if (problem != null) ...[
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.cancel_outlined,
            message: problem,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: PremiumButton.outlined(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PremiumButton(
                label: 'Apply',
                onPressed: problem == null
                    ? () => Navigator.pop(context, _draft)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Results
// ---------------------------------------------------------------------------

/// The portal's standing "Why book with us?" panel.
const List<({IconData icon, String title, String sub})> _kWhyBookCabs = [
  (
    icon: Icons.bolt_rounded,
    title: 'Instant confirmation',
    sub: 'Get booking confirmed instantly',
  ),
  (
    icon: Icons.credit_card_rounded,
    title: 'All-Inclusive Pricing',
    sub: 'No hidden charges or surprises',
  ),
  (
    icon: Icons.headset_mic_rounded,
    title: '24/7 Customer Support',
    sub: 'Round the clock assistance',
  ),
  (
    icon: Icons.verified_user_rounded,
    title: 'Reliable Rides',
    sub: 'Verified Drivers and Clean Vehicles',
  ),
];

/// `CabSearchResults.jsx`: loads the quotes for [query] on its own page (with
/// skeletons), groups them one card per vehicle class, and lets the search
/// be edited in place.
///
/// [resume] reopens a parked booking: once the quotes are in, the same
/// vehicle class from the same vendor goes straight to the booking page with
/// what was typed.
class CabResultsPage extends StatefulWidget {
  const CabResultsPage({
    super.key,
    required this.api,
    required this.query,
    this.resume,
  });

  final HoneymoonApi api;
  final CabSearchQuery query;
  final CabBookingDraft? resume;

  @override
  State<CabResultsPage> createState() => _CabResultsPageState();
}

class _CabResultsPageState extends State<CabResultsPage> {
  late CabSearchQuery _query = widget.query;
  CabQuoteResult? _result;
  bool _loading = true;
  String? _error;
  CabBookingDraft? _resume;

  /// Bumped per search so a slow, superseded response is ignored.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _resume = widget.resume;
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.api.searchCabQuotes(_query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _result = result;
        _loading = false;
      });
      _resumeIfParked(result);
    } on HoneymoonApiException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        // A supplier failure (HTTP 200 with status:false) carries its own
        // message; anything else gets the web's generic line.
        _error = e.statusCode == null && !e.isTimeout && e.message.isNotEmpty
            ? e.message
            : "We couldn't load cab options for this route. Please try again.";
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error =
            "We couldn't load cab options for this route. Please try again.";
      });
    }
  }

  /// A cab class is one card; its quotes cheapest first, the classes by
  /// their cheapest — the web's `groups`.
  List<List<CabQuote>> get _groups {
    final byClass = <String, List<CabQuote>>{};
    for (final q in _result?.quotes ?? const <CabQuote>[]) {
      byClass.putIfAbsent(cabClassKey(q), () => <CabQuote>[]).add(q);
    }
    final groups = byClass.values
        .map(
          (list) =>
              List<CabQuote>.from(list)
                ..sort((a, b) => a.price.compareTo(b.price)),
        )
        .toList();
    groups.sort((a, b) => a.first.price.compareTo(b.first.price));
    return groups;
  }

  Future<void> _editSearch() async {
    final next = await AppBottomSheet.show<CabSearchQuery>(
      context,
      title: 'Modify search',
      child: CabSearchForm(
        api: widget.api,
        initial: _query,
        submitLabel: 'Update Search',
        onSearch: (q) => Navigator.pop(context, q),
      ),
    );
    if (next == null || !mounted) return;
    setState(() {
      _query = next;
      _resume = null;
    });
    _load();
  }

  void _resumeIfParked(CabQuoteResult result) {
    final draft = _resume;
    if (draft == null) return;
    _resume = null;
    CabQuote? match;
    for (final q in result.quotes) {
      if (cabQuoteIdentity(q) == draft.quoteIdentity) {
        match = q;
        break;
      }
    }
    CabDraftStore.clear();
    if (match == null) {
      AppSnackbar.error(
        context,
        'That cab is no longer offered for this trip. Please pick another.',
      );
      return;
    }
    final quote = match;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openBooking(quote, draft: draft);
    });
  }

  /// Booking is login-gated, as on the web. A lapsed session parks the
  /// choice first; `AuthGate` then takes the traveller to sign in, and the
  /// honeymoon screen offers the booking back afterwards.
  Future<void> _select(CabQuote quote) async {
    if (!await AuthSession.instance.refresh()) {
      await CabDraftStore.save(
        CabBookingDraft(
          query: _query,
          quoteIdentity: cabQuoteIdentity(quote),
          vehicleLabel: quote.vehicleName,
          savedAt: DateTime.now(),
        ),
      );
      return;
    }
    if (!mounted) return;
    _openBooking(quote);
  }

  void _openBooking(CabQuote quote, {CabBookingDraft? draft}) {
    final result = _result;
    if (result == null) return;
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: CabBookingPage(
          api: widget.api,
          quote: quote,
          result: result,
          query: _query,
          restore: draft,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query;
    final pax = q.passengers;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${q.originLabel} → ${q.destinationLabel}',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatCabDateTime(q.pickupAt)}'
              '${q.returnAt == null ? '' : ' · Return ${formatCabDateTime(q.returnAt!)}'}'
              ' · $pax Pax, ${q.bags} Bag${q.bags == 1 ? '' : 's'}',
              style: AppText.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Modify search',
            onPressed: _editSearch,
            icon: const Icon(Icons.edit_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Finding the best cabs for your route...',
                    style: AppText.caption,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: Skeletons.listCards(height: 150)),
        ],
      );
    }

    final error = _error;
    if (error != null) {
      return ErrorState(
        title: "Couldn't load cabs",
        message: error,
        onRetry: _load,
      );
    }

    final groups = _groups;
    if (groups.isEmpty) {
      return EmptyState(
        title: 'No cabs available for this route.',
        message: 'Try a different pick-up time or nearby location.',
        icon: Icons.local_taxi_outlined,
        actionLabel: 'Modify search',
        onAction: _editSearch,
      );
    }

    final route = _result?.routeDetails;
    final from = firstNonEmpty([
      digPath(route, ['origin', 'city']),
      _query.originLabel,
    ]);
    final to = firstNonEmpty([
      digPath(route, ['destination', 'city']),
      _query.destinationLabel,
    ]);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text.rich(
            TextSpan(
              style: AppText.bodySm,
              children: [
                TextSpan(
                  text:
                      'Showing ${groups.length} cab'
                      '${groups.length > 1 ? 's' : ''} from ',
                ),
                TextSpan(text: from, style: AppText.bodyStrong),
                const TextSpan(text: ' to '),
                TextSpan(text: to, style: AppText.bodyStrong),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < groups.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              delay: AppMotion.staggerFor(i),
              child: _CabClassCard(
                quotes: groups[i],
                isRoundTrip: _query.isRoundTrip,
                onSelect: _select,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const _WhyBookCabs(),
        ],
      ),
    );
  }
}

class _WhyBookCabs extends StatelessWidget {
  const _WhyBookCabs();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Why book with us?', style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.md),
          for (final item in _kWhyBookCabs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Row(
                children: [
                  Icon(item.icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item.title, style: AppText.bodyStrong),
                        Text(item.sub, style: AppText.caption),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One vehicle class: its cheapest quote on the face of the card, with any
/// sibling quotes revealed by Compare.
class _CabClassCard extends StatefulWidget {
  const _CabClassCard({
    required this.quotes,
    required this.isRoundTrip,
    required this.onSelect,
  });

  /// Cheapest first; never empty.
  final List<CabQuote> quotes;
  final bool isRoundTrip;
  final ValueChanged<CabQuote> onSelect;

  @override
  State<_CabClassCard> createState() => _CabClassCardState();
}

class _CabClassCardState extends State<_CabClassCard> {
  bool _comparing = false;

  @override
  Widget build(BuildContext context) {
    final cheapest = widget.quotes.first;
    final hasSiblings = widget.quotes.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CabCard(
          quote: cheapest,
          isRoundTrip: widget.isRoundTrip,
          onSelect: () => widget.onSelect(cheapest),
          onPolicies: () => showCabPolicySheet(context, cheapest),
          // Only offered when this class has another quote to compare.
          onCompare: hasSiblings
              ? () => setState(() => _comparing = !_comparing)
              : null,
          comparing: _comparing,
        ),
        AnimatedCrossFade(
          duration: AppMotion.fast,
          crossFadeState: _comparing && hasSiblings
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          firstChild: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: CabCompareTable(
              quotes: widget.quotes,
              onSelect: widget.onSelect,
              onPolicies: (q) => showCabPolicySheet(context, q),
            ),
          ),
          secondChild: const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// The web's quote card: image, class name, model, seats and bags, View
/// policies; the price (tap for the breakdown), "Inc. GST", Book Cab and
/// Compare.
class _CabCard extends StatelessWidget {
  const _CabCard({
    required this.quote,
    required this.isRoundTrip,
    required this.onSelect,
    required this.onPolicies,
    this.onCompare,
    this.comparing = false,
  });

  final CabQuote quote;
  final bool isRoundTrip;
  final VoidCallback onSelect;
  final VoidCallback onPolicies;

  /// Null when this class has only one quote, so there is nothing to compare.
  final VoidCallback? onCompare;
  final bool comparing;

  @override
  Widget build(BuildContext context) {
    final title = quote.label.isNotEmpty ? quote.label : quote.vehicleType;
    final model = quote.model.isNotEmpty ? quote.model : quote.similarType;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CabImage(quote: quote),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title.isEmpty ? quote.vehicleName : title,
                      style: AppText.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (model.isNotEmpty)
                      Text(
                        model,
                        style: AppText.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        MetaChip(
                          icon: Icons.people_alt_rounded,
                          label: '${quote.seats > 0 ? quote.seats : '-'} seats',
                        ),
                        MetaChip(
                          icon: Icons.luggage_rounded,
                          label:
                              '${quote.luggage > 0 ? quote.luggage : '-'} bags',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Pressable(
                  onTap: () => showCabFareSheet(
                    context,
                    quote,
                    isRoundTrip: isRoundTrip,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // A six-figure fare at large text must shrink, not
                          // push "Book Cab" off the card.
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                formatPrice(quote.price),
                                style: AppText.price,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxs),
                          const Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      Text('Inc. GST', style: AppText.caption),
                    ],
                  ),
                ),
              ),
              PremiumButton(
                label: 'Book Cab',
                size: PremiumButtonSize.small,
                expanded: false,
                onPressed: onSelect,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          const Divider(height: 1, color: AppColors.divider),
          // Wraps rather than overflows on a narrow phone at large text.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PremiumButton.text(
                label: 'View policies',
                size: PremiumButtonSize.small,
                onPressed: onPolicies,
              ),
              if (onCompare != null)
                PremiumButton.text(
                  label: comparing ? 'Hide compare' : 'Compare',
                  icon: comparing
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: PremiumButtonSize.small,
                  onPressed: onCompare,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CabImage extends StatelessWidget {
  const _CabImage({required this.quote});

  final CabQuote quote;

  @override
  Widget build(BuildContext context) {
    if (quote.imageUrl.isNotEmpty) {
      return NetworkImageWidget(
        url: quote.imageUrl,
        width: 84,
        height: 64,
        radius: AppRadii.md,
        memCacheWidth: 250,
      );
    }
    return Container(
      width: 84,
      height: 64,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.pinkSurface,
        borderRadius: AppRadii.rMd,
      ),
      child: Text(
        quote.vehicleType.isEmpty ? 'CAB' : quote.vehicleType,
        style: AppText.labelSm.copyWith(color: AppColors.primary),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The card's fare popover: Base Fare / Taxes / Total one way; on a round
/// trip the gross split evenly into Forward and Return Trip, as the portal
/// splits it (and as the booking echoes the onward leg at exactly half).
Future<void> showCabFareSheet(
  BuildContext context,
  CabQuote quote, {
  required bool isRoundTrip,
}) {
  Widget row(String label, double value, {bool strong = false}) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: strong ? AppText.bodyStrong : AppText.body),
        ),
        Text(
          formatPrice(value),
          style: strong ? AppText.bodyStrong : AppText.body,
        ),
      ],
    ),
  );

  final half = quote.price / 2;
  return AppBottomSheet.show<void>(
    context,
    title: 'Fare details',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isRoundTrip) ...[
          row('Forward Trip', half),
          row('Return Trip', half),
        ] else ...[
          row('Base Fare', quote.netFare),
          row('Taxes', quote.totalTax),
        ],
        const Divider(height: AppSpacing.lg, color: AppColors.divider),
        row('Total Fare', quote.price, strong: true),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Previous implementation, kept for reference (replaced to match the web:
// journey types, return trips, passengers/bags, timing rules, results that
// load on their own page, and the login gate).
// ---------------------------------------------------------------------------
// /// Airport transfers / car rental, backed by:
// ///   POST tripjack-cabs/search-locations  (Google Places autocomplete)
// ///   POST tripjack-cabs/lat-long          (place id → coordinates)
// ///   POST tripjack-cabs/quotes            (vehicle quotes)
// library;
//
// import 'dart:async';
//
// import 'package:flutter/material.dart';
//
// import '../../core/core.dart';
// import '../data/honeymoon_api.dart';
// import '../honeymoon_config.dart';
// import '../models/honeymoon_models.dart';
// import 'booking/cab_booking_page.dart';
// import 'widgets/cab_policy_sheet.dart';
// import 'widgets/honeymoon_widgets.dart';
//
// /// A place the user picked, plus the coordinates the quotes call needs.
// class _CabPlace {
//   const _CabPlace({required this.label, required this.node});
//
//   final String label;
//   final Map<String, dynamic> node;
// }
//
// // ---------------------------------------------------------------------------
// // Search form
// // ---------------------------------------------------------------------------
//
// class CabSearchForm extends StatefulWidget {
//   const CabSearchForm({super.key, required this.api});
//
//   final HoneymoonApi api;
//
//   @override
//   State<CabSearchForm> createState() => _CabSearchFormState();
// }
//
// class _CabSearchFormState extends State<CabSearchForm> {
//   _CabPlace? _pickup;
//   _CabPlace? _drop;
//   DateTime? _pickupDate;
//   TimeOfDay? _pickupTime;
//
//   bool _submitting = false;
//   String? _placeError;
//   String? _dateError;
//
//   Future<void> _pickPlace({required bool isPickup}) async {
//     final picked = await AppBottomSheet.show<_CabPlace>(
//       context,
//       title: isPickup ? 'Pick-up location' : 'Drop-off location',
//       child: _PlaceSearchSheet(api: widget.api),
//     );
//     if (picked == null) return;
//     setState(() {
//       if (isPickup) {
//         _pickup = picked;
//       } else {
//         _drop = picked;
//       }
//       _placeError = null;
//     });
//   }
//
//   Future<void> _pickDateTime() async {
//     final now = DateTime.now();
//     final date = await showDatePicker(
//       context: context,
//       initialDate: _pickupDate ?? now,
//       firstDate: DateTime(now.year, now.month, now.day),
//       lastDate: now.add(
//         const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
//       ),
//       helpText: 'Select pick-up date',
//     );
//     if (date == null || !mounted) return;
//
//     final time = await showTimePicker(
//       context: context,
//       initialTime: _pickupTime ?? const TimeOfDay(hour: 10, minute: 0),
//       helpText: 'Select pick-up time',
//     );
//     if (!mounted) return;
//
//     setState(() {
//       _pickupDate = date;
//       _pickupTime = time ?? _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
//       _dateError = null;
//     });
//   }
//
//   DateTime? get _pickupAt {
//     if (_pickupDate == null) return null;
//     final t = _pickupTime ?? const TimeOfDay(hour: 10, minute: 0);
//     return DateTime(
//       _pickupDate!.year,
//       _pickupDate!.month,
//       _pickupDate!.day,
//       t.hour,
//       t.minute,
//     );
//   }
//
//   bool _validate() {
//     setState(() {
//       _placeError = (_pickup == null || _drop == null)
//           ? 'Choose both a pick-up and drop-off location'
//           : null;
//       _dateError = _pickupDate == null ? 'Select when you need the car' : null;
//     });
//     return _placeError == null && _dateError == null;
//   }
//
//   Future<void> _search() async {
//     if (_submitting) return;
//     FocusScope.of(context).unfocus();
//     if (!_validate()) return;
//
//     setState(() => _submitting = true);
//     try {
//       final result = await widget.api.fetchCabQuotes(
//         origin: _pickup!.node,
//         destination: _drop!.node,
//         pickupAt: _pickupAt!,
//       );
//
//       if (!mounted) return;
//       Navigator.push(
//         context,
//         AnimatedPageRoute(
//           page: CabResultsPage(
//             api: widget.api,
//             pickupLabel: _pickup!.label,
//             dropLabel: _drop!.label,
//             pickupAt: _pickupAt!,
//             result: result,
//           ),
//           style: PageTransitionStyle.slideRight,
//         ),
//       );
//     } on HoneymoonApiException catch (e) {
//       if (!mounted) return;
//       AppSnackbar.error(context, e.message);
//     } finally {
//       if (mounted) setState(() => _submitting = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final at = _pickupAt;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const FieldLabel('Pick-up'),
//         TapField(
//           icon: Icons.trip_origin_rounded,
//           value: _pickup?.label ?? '',
//           placeholder: 'Airport, hotel or address',
//           onTap: () => _pickPlace(isPickup: true),
//         ),
//         const SizedBox(height: AppSpacing.md),
//
//         const FieldLabel('Drop-off'),
//         TapField(
//           icon: Icons.place_rounded,
//           value: _drop?.label ?? '',
//           placeholder: 'Airport, hotel or address',
//           onTap: () => _pickPlace(isPickup: false),
//           errorText: _placeError,
//         ),
//         const SizedBox(height: AppSpacing.lg),
//
//         const FieldLabel('Pick-up date & time'),
//         TapField(
//           icon: Icons.schedule_rounded,
//           value: at == null
//               ? ''
//               : '${formatTripDate(at)} · '
//                     '${at.hour.toString().padLeft(2, '0')}:'
//                     '${at.minute.toString().padLeft(2, '0')}',
//           placeholder: 'When do you need the car?',
//           onTap: _pickDateTime,
//           errorText: _dateError,
//         ),
//
//         const SizedBox(height: AppSpacing.xl),
//         PremiumButton(
//           label: 'Find Transfers',
//           icon: Icons.directions_car_filled_outlined,
//           isLoading: _submitting,
//           onPressed: _search,
//         ),
//       ],
//     );
//   }
// }
//
// /// Two-step picker: Places autocomplete, then resolve to coordinates.
// class _PlaceSearchSheet extends StatefulWidget {
//   const _PlaceSearchSheet({required this.api});
//
//   final HoneymoonApi api;
//
//   @override
//   State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
// }
//
// class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
//   final TextEditingController _controller = TextEditingController();
//   Timer? _debounce;
//
//   List<Map<String, dynamic>> _results = const [];
//   bool _loading = false;
//   bool _resolving = false;
//   String? _error;
//
//   @override
//   void dispose() {
//     _debounce?.cancel();
//     _controller.dispose();
//     super.dispose();
//   }
//
//   void _onChanged(String value) {
//     _debounce?.cancel();
//     if (value.trim().length < 3) {
//       setState(() {
//         _results = const [];
//         _error = null;
//       });
//       return;
//     }
//     _debounce = Timer(const Duration(milliseconds: 380), () async {
//       setState(() {
//         _loading = true;
//         _error = null;
//       });
//       try {
//         final places = await widget.api.searchCabLocations(value);
//         if (!mounted) return;
//         setState(() {
//           _results = places;
//           _loading = false;
//         });
//       } on HoneymoonApiException catch (e) {
//         if (!mounted) return;
//         setState(() {
//           _loading = false;
//           _results = const [];
//           _error = e.message;
//         });
//       }
//     });
//   }
//
//   Future<void> _select(Map<String, dynamic> place) async {
//     final placeId = asString(place['id'] ?? place['value']);
//     final label = firstNonEmpty([
//       place['displayLabel'],
//       place['name'],
//     ], fallback: 'Selected location');
//
//     if (placeId.isEmpty) {
//       AppSnackbar.error(context, "We couldn't resolve that location.");
//       return;
//     }
//
//     setState(() => _resolving = true);
//     try {
//       final details = await widget.api.fetchCabPlaceDetails(placeId);
//       if (!mounted) return;
//
//       final node = HoneymoonApi.buildCabLocationNode(
//         displayAddress: label,
//         details: details,
//       );
//
//       // Quotes need coordinates; without them the request is pointless.
//       if (asString(node['lat']).isEmpty || asString(node['long']).isEmpty) {
//         setState(() => _resolving = false);
//         AppSnackbar.error(
//           context,
//           "We couldn't pin that location. Please pick another.",
//         );
//         return;
//       }
//
//       Navigator.pop(context, _CabPlace(label: label, node: node));
//     } on HoneymoonApiException catch (e) {
//       if (!mounted) return;
//       setState(() => _resolving = false);
//       AppSnackbar.error(context, e.message);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         AppTextField(
//           controller: _controller,
//           hint: 'Airport, hotel or address',
//           prefixIcon: Icons.search_rounded,
//           autofocus: true,
//           enabled: !_resolving,
//           onChanged: _onChanged,
//         ),
//         const SizedBox(height: AppSpacing.md),
//         SizedBox(height: 280, child: _buildBody()),
//       ],
//     );
//   }
//
//   Widget _buildBody() {
//     if (_resolving) {
//       return const Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           AppLoader(),
//           SizedBox(height: AppSpacing.md),
//           Text('Pinning that location…'),
//         ],
//       );
//     }
//
//     if (_loading) return const AppLoader();
//
//     if ((_error ?? '').isNotEmpty) {
//       return ErrorState(
//         compact: true,
//         title: "Couldn't search locations",
//         message: _error,
//         padding: EdgeInsets.zero,
//       );
//     }
//
//     if (_results.isEmpty) {
//       return EmptyState(
//         compact: true,
//         title: _controller.text.trim().length < 3
//             ? 'Search for a place'
//             : 'No places found',
//         message: _controller.text.trim().length < 3
//             ? 'Type at least three letters.'
//             : 'Try a different address or landmark.',
//         icon: Icons.place_outlined,
//         padding: EdgeInsets.zero,
//       );
//     }
//
//     return ListView.separated(
//       itemCount: _results.length,
//       separatorBuilder: (_, _) =>
//           const Divider(height: 1, color: AppColors.divider),
//       itemBuilder: (context, i) {
//         final place = _results[i];
//         final label = firstNonEmpty([
//           place['displayLabel'],
//           place['name'],
//         ], fallback: 'Location');
//
//         return Pressable(
//           onTap: () => _select(place),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.place_outlined,
//                   size: 18,
//                   color: AppColors.primary,
//                 ),
//                 const SizedBox(width: AppSpacing.md),
//                 Expanded(
//                   child: Text(
//                     label,
//                     style: AppText.body,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
// }
//
// // ---------------------------------------------------------------------------
// // Results
// // ---------------------------------------------------------------------------
//
// class CabResultsPage extends StatelessWidget {
//   const CabResultsPage({
//     super.key,
//     required this.api,
//     required this.pickupLabel,
//     required this.dropLabel,
//     required this.pickupAt,
//     required this.result,
//   });
//
//   final HoneymoonApi api;
//   final String pickupLabel;
//   final String dropLabel;
//   final DateTime pickupAt;
//
//   /// The whole quotes response: booking echoes its journey and route blocks
//   /// straight back, so the options cannot be separated from their context.
//   final CabQuoteResult result;
//
//   /// The quotes API groups options by vehicle class (`quotesInfo[].quotes[]`)
//   /// and our flattener spreads them into one entry each — which turns a class
//   /// offered by two vendors into two near-identical cards. Regrouped here so
//   /// each class gets a single card carrying its cheapest quote, with the rest
//   /// behind Compare, exactly as the portal presents them.
//   List<List<CabQuote>> get _groups {
//     final byClass = <String, List<CabQuote>>{};
//     for (final q in result.quotes) {
//       final key = '${q.vehicleType}|${q.category}|${q.vehicleName}';
//       byClass.putIfAbsent(key, () => <CabQuote>[]).add(q);
//     }
//     final groups = byClass.values
//         .map((list) => List<CabQuote>.from(list)
//           ..sort((a, b) => a.price.compareTo(b.price)))
//         .toList();
//     groups.sort((a, b) => a.first.price.compareTo(b.first.price));
//     return groups;
//   }
//
//   void _openBooking(BuildContext context, CabQuote quote) {
//     Navigator.push(
//       context,
//       AnimatedPageRoute(
//         page: CabBookingPage(
//           api: api,
//           quote: quote,
//           result: result,
//           pickupLabel: pickupLabel,
//           dropLabel: dropLabel,
//           pickupAt: pickupAt,
//         ),
//         style: PageTransitionStyle.slideRight,
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final groups = _groups;
//
//     return Scaffold(
//       backgroundColor: AppColors.background,
//       appBar: AppTopBar(
//         elevated: true,
//         titleWidget: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Transfers',
//               style: AppText.cardTitle,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//             Text(
//               '$pickupLabel → $dropLabel',
//               style: AppText.caption,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//         ),
//       ),
//       body: groups.isEmpty
//           ? const EmptyState(
//               title: 'No vehicles available',
//               message: 'Try a different pick-up time or nearby location.',
//               icon: Icons.directions_car_filled_outlined,
//             )
//           : ListView.separated(
//               padding: const EdgeInsets.fromLTRB(
//                 AppSpacing.lg,
//                 AppSpacing.lg,
//                 AppSpacing.lg,
//                 AppSpacing.xxxl,
//               ),
//               itemCount: groups.length,
//               separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
//               itemBuilder: (context, i) => FadeSlideIn(
//                 delay: AppMotion.staggerFor(i),
//                 child: _CabClassCard(
//                   quotes: groups[i],
//                   onSelect: (quote) => _openBooking(context, quote),
//                 ),
//               ),
//             ),
//     );
//   }
// }
//
// /// One vehicle class: its cheapest quote on the face of the card, with any
// /// sibling quotes revealed by Compare.
// class _CabClassCard extends StatefulWidget {
//   const _CabClassCard({required this.quotes, required this.onSelect});
//
//   /// Cheapest first; never empty.
//   final List<CabQuote> quotes;
//   final ValueChanged<CabQuote> onSelect;
//
//   @override
//   State<_CabClassCard> createState() => _CabClassCardState();
// }
//
// class _CabClassCardState extends State<_CabClassCard> {
//   bool _comparing = false;
//
//   @override
//   Widget build(BuildContext context) {
//     final cheapest = widget.quotes.first;
//     final hasSiblings = widget.quotes.length > 1;
//
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         _CabCard(
//           quote: cheapest,
//           onSelect: () => widget.onSelect(cheapest),
//           onPolicies: () => showCabPolicySheet(context, cheapest),
//           // Compare is offered only when this class actually has another quote
//           // to compare against, matching the portal.
//           onCompare: hasSiblings
//               ? () => setState(() => _comparing = !_comparing)
//               : null,
//           comparing: _comparing,
//           optionCount: widget.quotes.length,
//         ),
//         AnimatedCrossFade(
//           duration: AppMotion.fast,
//           crossFadeState: _comparing && hasSiblings
//               ? CrossFadeState.showFirst
//               : CrossFadeState.showSecond,
//           firstChild: Padding(
//             padding: const EdgeInsets.only(top: AppSpacing.sm),
//             child: CabCompareTable(
//               quotes: widget.quotes,
//               onSelect: widget.onSelect,
//               onPolicies: (q) => showCabPolicySheet(context, q),
//             ),
//           ),
//           secondChild: const SizedBox(width: double.infinity),
//         ),
//       ],
//     );
//   }
// }
//
// class _CabCard extends StatelessWidget {
//   const _CabCard({
//     required this.quote,
//     required this.onSelect,
//     required this.onPolicies,
//     this.onCompare,
//     this.comparing = false,
//     this.optionCount = 1,
//   });
//
//   final CabQuote quote;
//   final VoidCallback onSelect;
//   final VoidCallback onPolicies;
//
//   /// Null when this class has only one quote, so there is nothing to compare.
//   final VoidCallback? onCompare;
//   final bool comparing;
//   final int optionCount;
//
//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _mainRow(),
//           const SizedBox(height: AppSpacing.sm),
//           const Divider(height: 1, color: AppColors.divider),
//           const SizedBox(height: AppSpacing.xs),
//           Row(
//             children: [
//               PremiumButton.text(
//                 label: 'View policies',
//                 size: PremiumButtonSize.small,
//                 onPressed: onPolicies,
//               ),
//               const Spacer(),
//               if (onCompare != null)
//                 PremiumButton.text(
//                   label: comparing
//                       ? 'Hide options'
//                       : 'Compare $optionCount options',
//                   size: PremiumButtonSize.small,
//                   onPressed: onCompare,
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _mainRow() {
//     return Row(
//       children: [
//           if (quote.imageUrl.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(right: AppSpacing.md),
//               child: NetworkImageWidget(
//                 url: quote.imageUrl,
//                 width: 72,
//                 height: 56,
//                 radius: AppRadii.md,
//                 memCacheWidth: 220,
//               ),
//             )
//           else
//             Container(
//               width: 72,
//               height: 56,
//               margin: const EdgeInsets.only(right: AppSpacing.md),
//               decoration: BoxDecoration(
//                 color: AppColors.pinkSurface,
//                 borderRadius: AppRadii.rMd,
//               ),
//               child: const Icon(
//                 Icons.directions_car_filled_rounded,
//                 color: AppColors.primary,
//               ),
//             ),
//
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   quote.vehicleName,
//                   style: AppText.cardTitle,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//                 if (quote.category.isNotEmpty || quote.seats > 0) ...[
//                   const SizedBox(height: AppSpacing.xxs),
//                   Wrap(
//                     spacing: AppSpacing.xs,
//                     runSpacing: AppSpacing.xs,
//                     children: [
//                       if (quote.category.isNotEmpty)
//                         MetaChip(label: quote.category),
//                       if (quote.seats > 0)
//                         MetaChip(
//                           icon: Icons.event_seat_rounded,
//                           label: '${quote.seats} seats',
//                         ),
//                     ],
//                   ),
//                 ],
//                 const SizedBox(height: AppSpacing.sm),
//                 Text(formatPrice(quote.price), style: AppText.price),
//               ],
//             ),
//           ),
//
//         PremiumButton(
//           label: 'Select',
//           size: PremiumButtonSize.small,
//           expanded: false,
//           onPressed: onSelect,
//         ),
//       ],
//     );
//   }
// }
