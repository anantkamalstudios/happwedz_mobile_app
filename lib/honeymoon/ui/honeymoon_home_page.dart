/// Honeymoon landing: hero, service tabs and the search card.
///
/// The page owns search state only. Every network call goes through
/// [HoneymoonApi]; no HTTP or JSON parsing happens in this file.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../authservice.dart';
import '../../core/core.dart';
import '../../main.dart' show requireAuthentication;
import '../data/honeymoon_api.dart';
import '../data/cab_draft_store.dart';
import '../data/hotel_draft_store.dart';
import '../honeymoon_config.dart';
import '../models/booking_models.dart';
import '../models/cab_models.dart';
import '../models/honeymoon_models.dart';
import 'cab_results_page.dart';
import 'flight_results_page.dart';
import 'hotel_detail_page.dart';
import 'hotel_results_page.dart';
import 'insurance_results_page.dart';
import 'bookings/hotel_booking_detail_page.dart';
import 'bookings/my_trips_page.dart';
import 'bookings/upcoming_flight_bookings.dart';
import 'widgets/honeymoon_widgets.dart';

/// Back to the Honeymoon landing on the Insurance tab — the web's
/// "Book another plan" / "Explore Travel Insurance" (`/honeymoon/insurance`).
/// Clears the booking screens above so Back does not return to them.
void openInsuranceSearch(BuildContext context) =>
    openHoneymoonService(context, HoneymoonService.insurance);

/// Back to the Honeymoon landing on [service]'s tab — the web's
/// `/honeymoon?tab=…` links ("Book another cab" → `tab=car-rental`).
void openHoneymoonService(BuildContext context, HoneymoonService service) {
  Navigator.of(context).pushAndRemoveUntil(
    AnimatedPageRoute(
      page: HoneymoonHomePage(initialService: service),
      style: PageTransitionStyle.slideRight,
    ),
    (route) => route.isFirst,
  );
}

class HoneymoonHomePage extends StatefulWidget {
  // const HoneymoonHomePage({super.key});
  const HoneymoonHomePage({
    super.key,
    this.initialService = HoneymoonService.hotels,
  });

  /// The tab the landing opens on; Hotels unless a flow sends you back to
  /// one (e.g. insurance's "Book another plan").
  final HoneymoonService initialService;

  @override
  State<HoneymoonHomePage> createState() => _HoneymoonHomePageState();
}

class _HoneymoonHomePageState extends State<HoneymoonHomePage> {
  final HoneymoonApi _api = HoneymoonApi();
  // HoneymoonService _service = HoneymoonService.hotels;
  late HoneymoonService _service = widget.initialService;

  @override
  void dispose() {
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: HoneymoonHero(
              onOpenTrips: () async {
                // My Trips lists the account's bookings.
                if (!await requireAuthentication(
                  context,
                  reason: 'Sign in to see your trips.',
                )) {
                  return;
                }
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: MyTripsPage(api: _api),
                    style: PageTransitionStyle.slideRight,
                  ),
                );
              },
              child: HoneymoonServiceTabs(
                selected: _service,
                onSelected: (s) => setState(() => _service = s),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -14),
              child: AnimatedSize(
                duration: AppMotion.normal,
                curve: AppMotion.standard,
                alignment: Alignment.topCenter,
                child: HoneymoonSearchCard(
                  child: AnimatedSwitcher(
                    duration: AppMotion.normal,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(
                        sizeFactor: anim,
                        // Grow downward from the top edge, so swapping tabs
                        // never makes the card jump under the tab strip.
                        // alignment: Alignment.topCenter,
                        axisAlignment: -1.0,
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(_service),
                      child: switch (_service) {
                        HoneymoonService.hotels => HotelSearchForm(api: _api),
                        HoneymoonService.flights => FlightSearchForm(api: _api),
                        HoneymoonService.insurance => InsuranceSearchForm(
                          api: _api,
                        ),
                        HoneymoonService.carRental => CabSearchForm(api: _api),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),

          // A booking parked when the session expired, offered back.
          if (_service == HoneymoonService.hotels)
            SliverToBoxAdapter(child: _ResumeHotelBooking(api: _api)),
          // …and a cab chosen before the session ran out (the web's
          // `kind: "cab"` draft).
          if (_service == HoneymoonService.carRental)
            SliverToBoxAdapter(child: _ResumeCabBooking(api: _api)),

          // The web's hero lists the last few stays under the Hotels tab.
          if (_service == HoneymoonService.hotels)
            SliverToBoxAdapter(child: _RecentHotelBookings(api: _api)),

          // …and "Upcoming Bookings" under the Flights search
          // (`HeroPage.jsx` → `UpcomingBookings.jsx`).
          if (_service == HoneymoonService.flights)
            SliverToBoxAdapter(child: UpcomingFlightBookings(api: _api)),

          const SliverToBoxAdapter(child: _WhyBookWithUs()),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxxl)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Parked booking
// ---------------------------------------------------------------------------

/// "Continue your booking" — the app's half of the web's login round-trip.
///
/// On the web the login page sends the traveller straight back to the hotel
/// page, which restores the draft. In the app a lapsed session drops the
/// whole stack at `AuthGate`, so the draft is offered here instead: Continue
/// reopens the hotel, re-reviews the parked room and refills the form.
class _ResumeHotelBooking extends StatefulWidget {
  const _ResumeHotelBooking({required this.api});

  final HoneymoonApi api;

  @override
  State<_ResumeHotelBooking> createState() => _ResumeHotelBookingState();
}

class _ResumeHotelBookingState extends State<_ResumeHotelBooking> {
  HotelBookingDraft? _draft;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await HotelDraftStore.read();
    if (!mounted) return;
    setState(() => _draft = draft);
  }

  Future<void> _continue(HotelBookingDraft draft) async {
    await Navigator.push(
      context,
      AnimatedPageRoute(
        page: HotelDetailPage(
          api: widget.api,
          hotel: draft.hotel,
          query: draft.query,
          searchId: draft.searchId,
          restoreDraft: draft,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
    // The detail page consumes the draft; re-read so the card goes away.
    if (mounted) _load();
  }

  Future<void> _discard() async {
    await HotelDraftStore.clear();
    if (mounted) setState(() => _draft = null);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (draft == null) return const SizedBox.shrink();
    final guests = draft.query.guests;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Continue your booking',
                    style: AppText.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              draft.hotel.name,
              style: AppText.bodyStrong,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(draft.query.checkIn)} – '
              '${formatTripDate(draft.query.checkOut)} · '
              '$guests guest${guests == 1 ? '' : 's'}',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'You stopped before payment. Your details are saved — '
              'the price is checked again when you continue.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PremiumButton.outlined(
                    label: 'Discard',
                    size: PremiumButtonSize.small,
                    onPressed: _discard,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PremiumButton(
                    label: 'Continue',
                    size: PremiumButtonSize.small,
                    onPressed: () => _continue(draft),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// "Continue your booking" for a parked cab: Continue searches again with
/// the same trip and reopens the same vehicle class from the same vendor,
/// at today's price, with what was typed refilled.
class _ResumeCabBooking extends StatefulWidget {
  const _ResumeCabBooking({required this.api});

  final HoneymoonApi api;

  @override
  State<_ResumeCabBooking> createState() => _ResumeCabBookingState();
}

class _ResumeCabBookingState extends State<_ResumeCabBooking> {
  CabBookingDraft? _draft;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final draft = await CabDraftStore.read();
    if (!mounted) return;
    setState(() => _draft = draft);
  }

  Future<void> _continue(CabBookingDraft draft) async {
    await Navigator.push(
      context,
      AnimatedPageRoute(
        page: CabResultsPage(
          api: widget.api,
          query: draft.query,
          resume: draft,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
    // The results page consumes the draft; re-read so the card goes away.
    if (mounted) _load();
  }

  Future<void> _discard() async {
    await CabDraftStore.clear();
    if (mounted) setState(() => _draft = null);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (draft == null) return const SizedBox.shrink();
    final q = draft.query;
    // A pickup that is now too close cannot be booked; say so up front.
    final stale = cabPickupProblem(q.pickupAt);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Continue your booking',
                    style: AppText.cardTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              draft.vehicleLabel.isEmpty ? 'Cab' : draft.vehicleLabel,
              style: AppText.bodyStrong,
            ),
            Text(
              '${q.originLabel} → ${q.destinationLabel}',
              style: AppText.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(formatCabDateTime(q.pickupAt), style: AppText.caption),
            const SizedBox(height: AppSpacing.xs),
            Text(
              stale ??
                  'You stopped before payment. Your details are saved '
                      '— the price is checked again when you continue.',
              style: AppText.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PremiumButton.outlined(
                    label: 'Discard',
                    size: PremiumButtonSize.small,
                    onPressed: _discard,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: PremiumButton(
                    label: 'Continue',
                    size: PremiumButtonSize.small,
                    onPressed: stale == null ? () => _continue(draft) : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent stays
// ---------------------------------------------------------------------------

/// `POST hotels/recent-bookings {limit: 3}`. Only for a signed-in traveller;
/// a failure or an empty history hides the block rather than showing an
/// error on the landing page, which is what the web does.
class _RecentHotelBookings extends StatefulWidget {
  const _RecentHotelBookings({required this.api});

  final HoneymoonApi api;

  @override
  State<_RecentHotelBookings> createState() => _RecentHotelBookingsState();
}

class _RecentHotelBookingsState extends State<_RecentHotelBookings> {
  List<TravelBooking> _bookings = const [];

  @override
  void initState() {
    super.initState();
    // Reload when a guest signs in from a booking flow on top of this page.
    AuthSession.instance.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!AuthSession.instance.isAuthenticated) return;
    try {
      final bookings = await widget.api.fetchRecentHotelBookings(limit: 3);
      if (!mounted) return;
      setState(() => _bookings = bookings);
    } catch (_) {
      // Not worth an error on the landing page.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bookings.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SectionHeader(
            title: 'Your recent stays',
            accent: true,
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: AppSpacing.md),
          for (final booking in _bookings) ...[
            TripCard(
              booking: booking,
              onTap: () => Navigator.push(
                context,
                AnimatedPageRoute(
                  page: HotelBookingDetailPage(
                    api: widget.api,
                    booking: booking,
                  ),
                  style: PageTransitionStyle.slideRight,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hotels
// ---------------------------------------------------------------------------

class HotelSearchForm extends StatefulWidget {
  const HotelSearchForm({
    super.key,
    required this.api,
    this.initialQuery,
    this.onSearch,
    this.submitLabel = 'Search Honeymoon Stays',
  });

  final HoneymoonApi api;

  /// Pre-fills every field from a search already run — the web renders the
  /// same form, prefilled, on the results and detail pages.
  final HotelSearchQuery? initialQuery;

  /// When set, a search is handed back instead of opening a new results
  /// page, so the results page can re-search in place (the web's `onSearch`).
  final void Function(HotelSearchQuery query, HotelSearchResult result)?
  onSearch;

  final String submitLabel;

  @override
  State<HotelSearchForm> createState() => _HotelSearchFormState();
}

class _HotelSearchFormState extends State<HotelSearchForm> {
  final TextEditingController _destinationController = TextEditingController();

  HoneymoonDestination? _destination;
  DateTime? _checkIn;
  DateTime? _checkOut;
  final List<RoomOccupancy> _rooms = [
    RoomOccupancy(adults: HoneymoonConfig.defaultAdults),
  ];

  bool _submitting = false;
  String? _destinationError;
  String? _dateError;

  // "More options" — the web's second row: star ratings, nationality,
  // country of residence, the country suggestions are scoped to, GST claim.
  bool _showMoreOptions = false;
  final List<String> _ratings = [];
  String _nationality = HoneymoonConfig.defaultNationality;
  String _residence = HoneymoonConfig.defaultCountryOfResidence;
  String _searchCountry = 'INDIA';
  List<({String code, String name})> _countries = const [
    (code: 'INDIA', name: 'India'),
  ];
  bool _gstClaim = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery;
    if (initial != null) {
      _destination = initial.destination;
      _destinationController.text = initial.destination.displayName;
      _checkIn = initial.checkIn;
      _checkOut = initial.checkOut;
      _rooms
        ..clear()
        ..addAll(initial.rooms.map((r) => r.copy()));
      _ratings.addAll(initial.ratings);
      _nationality = initial.nationality;
      _residence = initial.countryOfResidence;
      _searchCountry = initial.countryName;
      _gstClaim = initial.gstApplied;
      _showMoreOptions =
          initial.ratings.isNotEmpty ||
          initial.gstApplied ||
          initial.nationality != HoneymoonConfig.defaultNationality ||
          initial.countryOfResidence !=
              HoneymoonConfig.defaultCountryOfResidence;
    }
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    final countries = await widget.api.fetchHotelCountryOptions();
    if (!mounted) return;
    setState(() => _countries = countries);
  }

  static String _countryName(String code) =>
      kHotelNationalities.where((c) => c.code == code).firstOrNull?.name ??
      HoneymoonConfig.defaultCountryName;

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  int get _travellerCount =>
      _rooms.fold(0, (sum, r) => sum + r.adults + r.children);

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final range = await showDateRangePicker(
      context: context,
      // Start date can never be in the past.
      firstDate: today,
      lastDate: today.add(
        const Duration(days: HoneymoonConfig.maxBookingDaysAhead),
      ),
      initialDateRange: _checkIn != null && _checkOut != null
          ? DateTimeRange(start: _checkIn!, end: _checkOut!)
          : null,
      helpText: 'Select your travel dates',
      saveText: 'Done',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (range == null) return;
    setState(() {
      _checkIn = range.start;
      _checkOut = range.end;
      _dateError = null;
    });
  }

  Future<void> _openTravellerSheet() async {
    await AppBottomSheet.show(
      context,
      title: 'Rooms & travellers',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < _rooms.length; i++) ...[
                if (i > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppSpacing.md),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Text('Room ${i + 1}', style: AppText.sectionTitle),
                    ),
                    if (_rooms.length > 1)
                      PremiumButton.text(
                        label: 'Remove',
                        size: PremiumButtonSize.small,
                        onPressed: () {
                          setSheetState(() => _rooms.removeAt(i));
                          setState(() {});
                        },
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                // BUG FIX: limits and age bands now match the web's picker
                // (adults 18+, max 8; children 0–9, max 4; up to 9 rooms).
                // Every child was silently sent as eight years old — the
                // supplier prices children by age, so each one now has an age.
                CounterRow(
                  title: 'Adults',
                  subtitle: 'Ages 18+',
                  value: _rooms[i].adults,
                  min: 1,
                  max: HotelOccupancyLimits.maxAdultsPerRoom,
                  onChanged: (v) {
                    setSheetState(() => _rooms[i].adults = v);
                    setState(() {});
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                CounterRow(
                  title: 'Children',
                  subtitle: 'Ages 0–9',
                  value: _rooms[i].children,
                  max: HotelOccupancyLimits.maxChildrenPerRoom,
                  onChanged: (v) {
                    setSheetState(() {
                      final ages = _rooms[i].childAges;
                      if (v > ages.length) {
                        ages.add(HotelOccupancyLimits.minChildAge);
                      } else if (ages.isNotEmpty) {
                        ages.removeLast();
                      }
                    });
                    setState(() {});
                  },
                ),
                if (_rooms[i].children > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text('Age of each child', style: AppText.caption),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      for (var c = 0; c < _rooms[i].childAges.length; c++)
                        _ChildAgeChip(
                          label: 'Child ${c + 1}',
                          age: _rooms[i].childAges[c],
                          onTap: () async {
                            final picked = await _pickChildAge(
                              _rooms[i].childAges[c],
                            );
                            if (picked == null) return;
                            setSheetState(
                              () => _rooms[i].childAges[c] = picked,
                            );
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ],

              const SizedBox(height: AppSpacing.lg),
              if (_rooms.length < HotelOccupancyLimits.maxRooms)
                PremiumButton.outlined(
                  label: 'Add another room',
                  icon: Icons.add_rounded,
                  size: PremiumButtonSize.medium,
                  onPressed: () {
                    // An added room starts at one adult, as on the web.
                    setSheetState(() => _rooms.add(RoomOccupancy(adults: 1)));
                    setState(() {});
                  },
                ),
              const SizedBox(height: AppSpacing.md),
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

  Future<int?> _pickChildAge(int current) => showModalBottomSheet<int>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Age of child', style: AppText.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (
                  var age = HotelOccupancyLimits.minChildAge;
                  age <= HotelOccupancyLimits.maxChildAge;
                  age++
                )
                  ChoiceChip(
                    label: Text('$age'),
                    selected: age == current,
                    selectedColor: AppColors.pinkSurface,
                    onSelected: (_) => Navigator.pop(sheetContext, age),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _pickNationality({required bool residence}) async {
    final current = residence ? _residence : _nationality;
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      builder: (sheetContext) => _CountryPickerSheet(
        title: residence ? 'Country of residence' : 'Nationality',
        options: [
          for (final c in kHotelNationalities) (code: c.code, name: c.name),
        ],
        selected: current,
      ),
    );
    if (picked == null) return;
    setState(() => residence ? _residence = picked : _nationality = picked);
  }

  Future<void> _pickSearchCountry() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
      builder: (sheetContext) => _CountryPickerSheet(
        title: 'Search in country',
        options: _countries,
        selected: _searchCountry,
      ),
    );
    if (picked == null || picked == _searchCountry) return;
    // Suggestions are scoped to the country, so a destination picked under
    // the old one no longer belongs to this search.
    setState(() {
      _searchCountry = picked;
      _destination = null;
      _destinationController.clear();
    });
  }

  bool _validate() {
    setState(() {
      _destinationError = _destination == null
          ? 'Choose where you would like to go'
          : null;
      _dateError = (_checkIn == null || _checkOut == null)
          ? 'Select your travel dates'
          : (!_checkOut!.isAfter(_checkIn!)
                ? 'Check-out must be after check-in'
                : null);
    });
    return _destinationError == null && _dateError == null;
  }

  Future<void> _search() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() => _submitting = true);
    try {
      // One query object carries every choice made here through results,
      // detail and booking — the web keeps its search payload the same way.
      final query = HotelSearchQuery(
        destination: _destination!,
        checkIn: _checkIn!,
        checkOut: _checkOut!,
        rooms: _rooms,
        ratings: List.of(_ratings),
        nationality: _nationality,
        countryOfResidence: _residence,
        countryName: _searchCountry,
        gstApplied: _gstClaim,
      );
      final result = await widget.api.searchHotels(query);

      if (!mounted) return;
      final onSearch = widget.onSearch;
      if (onSearch != null) {
        onSearch(query, result);
        return;
      }
      Navigator.push(
        context,
        AnimatedPageRoute(
          page: HotelResultsPage(
            api: widget.api,
            query: query,
            initialResult: result,
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

  /// The web's "More options" row, collapsed by default so the card stays
  /// short: star rating, nationality, residence, search country, GST claim.
  Widget _buildMoreOptions() {
    final active =
        _ratings.length +
        (_nationality != HoneymoonConfig.defaultNationality ? 1 : 0) +
        (_residence != HoneymoonConfig.defaultCountryOfResidence ? 1 : 0) +
        (_searchCountry != 'INDIA' ? 1 : 0) +
        (_gstClaim ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Pressable(
          onTap: () => setState(() => _showMoreOptions = !_showMoreOptions),
          borderRadius: AppRadii.rSm,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.tune_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    active > 0 ? 'More options ($active)' : 'More options',
                    style: AppText.label.copyWith(color: AppColors.primary),
                  ),
                ),
                Icon(
                  _showMoreOptions
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.normal,
          curve: AppMotion.standard,
          alignment: Alignment.topCenter,
          child: !_showMoreOptions
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const FieldLabel('Star rating'),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          for (final option in kHotelRatingOptions)
                            FilterChip(
                              label: Text(option.label),
                              selected: _ratings.contains(option.value),
                              selectedColor: AppColors.pinkSurface,
                              checkmarkColor: AppColors.primary,
                              onSelected: (on) => setState(
                                () => on
                                    ? _ratings.add(option.value)
                                    : _ratings.remove(option.value),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const FieldLabel('Nationality'),
                      TapField(
                        icon: Icons.flag_outlined,
                        value: _countryName(_nationality),
                        onTap: () => _pickNationality(residence: false),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const FieldLabel('Country of residence'),
                      TapField(
                        icon: Icons.home_outlined,
                        value: _countryName(_residence),
                        onTap: () => _pickNationality(residence: true),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const FieldLabel('Search in country'),
                      TapField(
                        icon: Icons.public_rounded,
                        value:
                            _countries
                                .where((c) => c.code == _searchCountry)
                                .firstOrNull
                                ?.name ??
                            'India',
                        onTap: _pickSearchCountry,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CheckboxListTile(
                        value: _gstClaim,
                        onChanged: (v) =>
                            setState(() => _gstClaim = v ?? false),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: AppColors.primary,
                        dense: true,
                        title: Text(
                          'I have a GST number and want to claim GST',
                          style: AppText.bodySm,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const FieldLabel('Destination'),
        DestinationField(
          api: widget.api,
          controller: _destinationController,
          selected: _destination,
          errorText: _destinationError,
          country: _searchCountry,
          onSelected: (d) => setState(() {
            _destination = d;
            _destinationError = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Dates side by side, but they wrap on very narrow screens.
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 320;
            final checkIn = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel('Check-in'),
                TapField(
                  icon: Icons.calendar_today_rounded,
                  value: formatTripDate(_checkIn),
                  placeholder: 'Add date',
                  onTap: _pickDates,
                ),
              ],
            );
            final checkOut = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const FieldLabel('Check-out'),
                TapField(
                  icon: Icons.event_available_rounded,
                  value: formatTripDate(_checkOut),
                  placeholder: 'Add date',
                  onTap: _pickDates,
                ),
              ],
            );

            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  checkIn,
                  const SizedBox(height: AppSpacing.md),
                  checkOut,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: checkIn),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: checkOut),
              ],
            );
          },
        ),
        if ((_dateError ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs, left: 2),
            child: Text(_dateError!, style: AppText.error),
          ),

        const SizedBox(height: AppSpacing.lg),
        const FieldLabel('Travellers'),
        TapField(
          icon: Icons.favorite_rounded,
          value:
              '$_travellerCount Traveller${_travellerCount == 1 ? '' : 's'}'
              ' · ${_rooms.length} Room${_rooms.length == 1 ? '' : 's'}',
          onTap: _openTravellerSheet,
        ),

        const SizedBox(height: AppSpacing.md),
        _buildMoreOptions(),

        const SizedBox(height: AppSpacing.xl),
        PremiumButton(
          label: widget.submitLabel,
          icon: Icons.search_rounded,
          isLoading: _submitting,
          onPressed: _search,
        ),
      ],
    );
  }
}

class _ChildAgeChip extends StatelessWidget {
  const _ChildAgeChip({
    required this.label,
    required this.age,
    required this.onTap,
  });

  final String label;
  final int age;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.rPill,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: AppRadii.rPill,
          border: Border.all(color: AppColors.pinkSurfaceStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label · $age yr${age == 1 ? '' : 's'}',
              style: AppText.labelSm,
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable country list — the web's `CountryDropdown`. Pops the chosen
/// code.
class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<({String code, String name})> options;
  final String selected;

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final filtered = widget.options
        .where((c) => c.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: AppText.sectionTitle),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                hint: 'Search country',
                prefixIcon: Icons.search_rounded,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (context, i) {
                  final c = filtered[i];
                  final selected = c.code == widget.selected;
                  return ListTile(
                    title: Text(
                      c.name,
                      style: selected ? AppText.bodyStrong : AppText.body,
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.primary,
                            size: 20,
                          )
                        : null,
                    onTap: () => Navigator.pop(context, c.code),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Destination autocomplete
// ---------------------------------------------------------------------------

/// Debounced destination picker backed by `hotels/suggestions` — the single
/// ranked list of places and properties the web's `HotelSearchForm` uses.
/// There is no honeymoon-destination catalogue endpoint, so suggestions come
/// from the live hotel geography.
class DestinationField extends StatefulWidget {
  const DestinationField({
    super.key,
    required this.api,
    required this.controller,
    required this.onSelected,
    this.selected,
    this.errorText,
    this.country = 'INDIA',
  });

  final HoneymoonApi api;
  final TextEditingController controller;
  final ValueChanged<HoneymoonDestination> onSelected;
  final HoneymoonDestination? selected;
  final String? errorText;

  /// Upper-cased country the suggestions are scoped to (`selectedCountry`).
  final String country;

  @override
  State<DestinationField> createState() => _DestinationFieldState();
}

class _DestinationFieldState extends State<DestinationField> {
  Timer? _debounce;
  List<HoneymoonDestination> _results = const [];
  bool _loading = false;
  bool _open = false;
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() {
        _results = const [];
        _open = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 320), () => _lookup(value));
  }

  Future<void> _lookup(String keyword) async {
    setState(() {
      _loading = true;
      _open = true;
      _error = null;
    });

    try {
      // BUG FIX: the two-call lookup below returned places without their
      // region *id* (it filled `city` with the name), so the search payload
      // sent "GOA" where the supplier expects `699356`. The web replaced it
      // with one `hotels/suggestions` call, ranked by the backend.
      // final results = await Future.wait([
      //   widget.api.searchCityRegions(keyword),
      //   widget.api.searchStaticHotels(keyword),
      // ]);
      final results = await widget.api.suggestHotels(
        keyword,
        country: widget.country,
      );

      if (!mounted) return;
      // A slower, older lookup must not overwrite a newer one.
      if (widget.controller.text.trim() != keyword.trim()) return;
      setState(() {
        // _results = [...results[0], ...results[1]].take(24).toList();
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: widget.controller,
          hint: 'Search destination, city',
          // prefixIcon: Icons.place_outlined,
          // A tight leading icon: `prefixIcon` sits in Flutter's default
          // 48px slot, which left a wide gap before the text.
          prefix: const Padding(
            padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.xs),
            child: Icon(
              Icons.place_outlined,
              size: 20,
              color: AppColors.textTertiary,
            ),
          ),
          suffixIcon: widget.controller.text.isEmpty
              ? null
              : Icons.close_rounded,
          onSuffixTap: () {
            widget.controller.clear();
            setState(() {
              _results = const [];
              _open = false;
            });
          },
          errorText: widget.errorText,
          textInputAction: TextInputAction.search,
          onChanged: _onChanged,
        ),

        if (_open)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.rMd,
              border: Border.all(color: AppColors.divider),
              boxShadow: AppColors.shadowSm,
            ),
            child: _buildSuggestions(),
          ),
      ],
    );
  }

  Widget _buildSuggestions() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: AppLoader(size: 22),
      );
    }

    if ((_error ?? '').isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(_error!, style: AppText.bodySm)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No destinations matched that search.',
          style: AppText.bodySm,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: AppColors.divider),
      itemBuilder: (context, i) {
        final d = _results[i];
        return Pressable(
          onTap: () {
            widget.controller.text = d.displayName;
            setState(() => _open = false);
            FocusScope.of(context).unfocus();
            widget.onSelected(d);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  d.isHotel ? Icons.hotel_rounded : Icons.location_city_rounded,
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
                        d.title,
                        style: AppText.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (d.subtitle.isNotEmpty)
                        Text(
                          d.subtitle,
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                // The web tags each row with what it is: HOTEL, CITY, …
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      d.isHotel
                          ? 'Hotel'
                          : d.searchRegionType
                                .replaceAll('_', ' ')
                                .toLowerCase(),
                      style: AppText.caption,
                    ),
                    if (d.isHotel && d.starRating > 0)
                      Text(
                        '${d.starRating.toStringAsFixed(0)}★',
                        style: AppText.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                  ],
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
// Trust strip
// ---------------------------------------------------------------------------

class _WhyBookWithUs extends StatelessWidget {
  const _WhyBookWithUs();

  static const _items = [
    (Icons.verified_rounded, 'Handpicked stays', 'Curated romantic properties'),
    (
      Icons.support_agent_rounded,
      'Real support',
      'Help before and during travel',
    ),
    (Icons.lock_rounded, 'Secure booking', 'Protected payments end to end'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Why book with HappyWedz', accent: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _items.length - 1 ? 0 : AppSpacing.md,
                    ),
                    child: FadeSlideIn(
                      delay: AppMotion.staggerFor(i),
                      child: AppCard.outlined(
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: AppColors.pinkSurface,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _items[i].$1,
                                size: 19,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(_items[i].$2, style: AppText.cardTitle),
                                  Text(
                                    _items[i].$3,
                                    style: AppText.cardSubtitle,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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
