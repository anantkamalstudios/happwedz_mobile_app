/// Hotel detail — room options and pricing from `POST hotels/detail`, with
/// descriptive content from `POST hotels/static-content`.
///
/// Mirrors the web's `HotelbedsDetailsPage`: gallery, about, stay times and
/// important information, amenities, location, then the rooms grouped by
/// room type with their rates, refundability, fare breakup and cancellation
/// slabs, filterable by refundable / breakfast / PAN-optional / meal plan.
library;

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../data/hotel_draft_store.dart';
import '../models/honeymoon_models.dart';
import '../models/hotel_models.dart';
import 'booking/hotel_booking_page.dart';
import 'hotel_results_page.dart';
import 'widgets/honeymoon_widgets.dart';
import 'widgets/hotel_widgets.dart';

// Kept importable from here: the room option model moved to hotel_models.dart.
export '../models/hotel_models.dart' show HotelRoomOption;

class HotelDetailPage extends StatefulWidget {
  const HotelDetailPage({
    super.key,
    required this.api,
    required this.hotel,
    required this.query,
    this.searchId = '',
    this.restoreDraft,
    this.onNewSearch,
  });

  final HoneymoonApi api;
  final HotelResult hotel;

  /// The search this hotel came from — dates, rooms, nationality, …
  final HotelSearchQuery query;
  final String searchId;

  /// A booking parked before a sign-in. Once the rooms load, its option is
  /// re-reviewed and the form restored — the web's restore-check effect.
  final HotelBookingDraft? restoreDraft;

  /// A new search run from this page's search bar. The web sends it to the
  /// results page (`HotelSearchBarEditable`); the results page that opened
  /// this one supplies the handler.
  final void Function(HotelSearchQuery query, HotelSearchResult result)?
  onNewSearch;

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  bool _loading = true;
  Object? _error;

  /// The untouched `hotels/detail` response. The review call is keyed on ids
  /// that live only here, so it has to outlive the parse into view models.
  Map<String, dynamic> _detail = const <String, dynamic>{};
  HotelStaticContent _static = HotelStaticContent.empty;
  List<HotelRoomOption> _rooms = const [];
  List<String> _images = const [];

  // Room filters — the web's `filterState` plus the room search box.
  final TextEditingController _roomSearch = TextEditingController();
  String _roomQuery = '';
  bool _refundableOnly = false;
  bool _breakfastOnly = false;
  bool _panOptionalOnly = false;
  String _mealPlan = '';

  String _selectedOptionId = '';

  /// Same device-local store the results page hearts use.
  static const _favouritesKey = 'happywedz.hotelFavourites';
  bool _favourite = false;

  final GlobalKey _roomsKey = GlobalKey();

  HotelSearchQuery get _query => widget.query;
  int get _nights => _query.nights;

  @override
  void initState() {
    super.initState();
    _load();
    _loadFavourite();
  }

  @override
  void dispose() {
    _roomSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // Static content is keyed only by the hotel id, so it runs alongside the
    // pricing call; its failure must not block the page.
    final staticFuture = widget.api
        .fetchHotelStaticContent(
          hotelId: widget.hotel.id,
          searchId: widget.searchId,
        )
        .then<HotelStaticContent?>((v) => v)
        .catchError((Object _) => null);

    try {
      final detail = await widget.api.fetchHotelDetail(
        hotel: widget.hotel,
        query: _query,
        searchId: widget.searchId,
      );
      final statics = await staticFuture ?? HotelStaticContent.empty;

      // Web order: static gallery first, then the listing's, then any the
      // detail itself carried.
      final images = <String>[];
      for (final url in [
        ...statics.images,
        ...widget.hotel.images,
        if (widget.hotel.imageUrl.isNotEmpty) widget.hotel.imageUrl,
      ]) {
        if (url.isNotEmpty && !images.contains(url)) images.add(url);
      }

      final rooms =
          HotelRoomOption.listFromDetail(
              detail,
            ).map((r) => r.withStatic(statics, fallbackImages: images)).toList()
            ..sort(_byPrice);

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _static = statics;
        _images = images;
        _rooms = rooms;
        _selectedOptionId = rooms.isEmpty ? '' : rooms.first.optionId;
        _loading = false;
      });
      _restoreParkedBooking();
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  bool _restoreChecked = false;

  /// Runs once, when the rooms are on screen. The draft supplies only the
  /// option to ask about and what the traveller typed; the booking page's
  /// review fetches a fresh bookingId, fare and policy.
  Future<void> _restoreParkedBooking() async {
    final draft = widget.restoreDraft;
    if (draft == null || _restoreChecked) return;
    _restoreChecked = true;

    // Consumed on the way in: a draft must never be replayable.
    await HotelDraftStore.clear();
    if (!mounted) return;

    final room = _rooms.where((r) => r.optionId == draft.optionId).firstOrNull;
    if (room == null) {
      AppSnackbar.error(
        context,
        'That room is no longer listed. Please pick a room again.',
      );
      return;
    }
    _startBooking(room, restoreDraft: draft);
  }

  static int _byPrice(HotelRoomOption a, HotelRoomOption b) {
    if (a.price <= 0 && b.price <= 0) return 0;
    if (a.price <= 0) return 1;
    if (b.price <= 0) return -1;
    return a.price.compareTo(b.price);
  }

  Future<void> _loadFavourite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_favouritesKey) ?? const [];
      if (!mounted) return;
      setState(() => _favourite = saved.contains(widget.hotel.id));
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    setState(() => _favourite = !_favourite);
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = (prefs.getStringList(_favouritesKey) ?? const []).toSet();
      _favourite ? saved.add(widget.hotel.id) : saved.remove(widget.hotel.id);
      await prefs.setStringList(_favouritesKey, saved.toList());
    } catch (_) {}
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(
        text: 'Check out ${widget.hotel.name} on HappyWedz',
        subject: widget.hotel.name,
      ),
    );
  }

  /// The web's `HotelSearchBarEditable`: a new search from this page goes to
  /// the results. When this page was opened from results, that page takes
  /// it in place; otherwise (e.g. a restored booking) results open fresh.
  void _editSearch() => showHotelSearchSheet(
    context,
    api: widget.api,
    initial: _query,
    onSearch: (query, result) {
      final onNewSearch = widget.onNewSearch;
      if (onNewSearch != null) {
        onNewSearch(query, result);
        return;
      }
      Navigator.pushReplacement(
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
    },
  );

  // --- rooms ----------------------------------------------------------------

  List<String> get _mealPlans {
    final plans = <String>[];
    for (final r in _rooms) {
      if (r.mealPlan.isNotEmpty && !plans.contains(r.mealPlan)) {
        plans.add(r.mealPlan);
      }
    }
    return plans;
  }

  List<HotelRoomOption> get _filteredRooms {
    final q = _roomQuery.trim().toLowerCase();
    return _rooms.where((r) {
      if (q.isNotEmpty && !r.name.toLowerCase().contains(q)) return false;
      if (_refundableOnly && r.refundable != true) return false;
      if (_breakfastOnly && !r.includesBreakfast) return false;
      if (_panOptionalOnly && r.panRequired) return false;
      if (_mealPlan.isNotEmpty && r.mealPlan != _mealPlan) return false;
      return true;
    }).toList();
  }

  /// Room types in cheapest-first order, each with its rates — the web's
  /// `RoomTypesSection` grouping.
  List<(String, List<HotelRoomOption>)> get _groups {
    final order = <String>[];
    final byName = <String, List<HotelRoomOption>>{};
    for (final r in _filteredRooms) {
      final key = r.name;
      if (!byName.containsKey(key)) order.add(key);
      byName.putIfAbsent(key, () => []).add(r);
    }
    return [for (final name in order) (name, byName[name]!)];
  }

  HotelRoomOption? get _selected =>
      _rooms.where((r) => r.optionId == _selectedOptionId).firstOrNull ??
      (_rooms.isEmpty ? null : _rooms.first);

  int get _activeRoomFilters =>
      (_refundableOnly ? 1 : 0) +
      (_breakfastOnly ? 1 : 0) +
      (_panOptionalOnly ? 1 : 0) +
      (_mealPlan.isNotEmpty ? 1 : 0) +
      (_roomQuery.trim().isNotEmpty ? 1 : 0);

  void _clearRoomFilters() {
    _roomSearch.clear();
    setState(() {
      _roomQuery = '';
      _refundableOnly = false;
      _breakfastOnly = false;
      _panOptionalOnly = false;
      _mealPlan = '';
    });
  }

  void _startBooking(HotelRoomOption room, {HotelBookingDraft? restoreDraft}) {
    setState(() => _selectedOptionId = room.optionId);
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: HotelBookingPage(
          api: widget.api,
          hotel: widget.hotel,
          room: room,
          query: _query,
          searchId: widget.searchId,
          detail: _detail,
          staticContent: _static,
          restoreDraft: restoreDraft,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

  // --- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? SafeArea(child: Skeletons.detail(heroHeight: 260))
          : _error != null
          ? SafeArea(
              child: Column(
                children: [
                  const AppTopBar(title: 'Hotel'),
                  Expanded(
                    child: ErrorState(
                      title: AppErrorMessage.genericTitle,
                      message: _error is HoneymoonApiException
                          ? (_error as HoneymoonApiException).message
                          : AppErrorMessage.genericBody,
                      onRetry: _load,
                    ),
                  ),
                ],
              ),
            )
          : _buildContent(),
      bottomNavigationBar: _loading || _error != null
          ? null
          : _buildBottomBar(),
    );
  }

  String get _address {
    final parts = <String>[
      if (_static.address.isNotEmpty) _static.address,
      if (_static.city.isNotEmpty) _static.city,
      if (_static.postalCode.isNotEmpty) _static.postalCode,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    return [
      widget.hotel.address,
      widget.hotel.city,
    ].where((s) => s.isNotEmpty).join(', ');
  }

  double get _stars =>
      _static.starRating > 0 ? _static.starRating : widget.hotel.starRating;

  Widget _buildContent() {
    final groups = _groups;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHero()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              HotelSearchSummaryBar(query: _query, onEdit: _editSearch),
              const SizedBox(height: AppSpacing.lg),
              Text(
                widget.hotel.name,
                style: AppText.display.copyWith(fontSize: 22),
              ),
              if (_address.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 15,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(child: Text(_address, style: AppText.bodySm)),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (_stars > 0)
                    MetaChip(
                      icon: Icons.star_rounded,
                      label: '${_stars.toStringAsFixed(0)}-star',
                    ),
                  if (widget.hotel.reviewScore > 0)
                    MetaChip(
                      icon: Icons.thumb_up_rounded,
                      label: widget.hotel.reviewCount > 0
                          ? '${widget.hotel.reviewScore.toStringAsFixed(1)} (${widget.hotel.reviewCount})'
                          : widget.hotel.reviewScore.toStringAsFixed(1),
                    ),
                  if ((_static.propertyType.isNotEmpty
                          ? _static.propertyType
                          : widget.hotel.propertyType)
                      .isNotEmpty)
                    MetaChip(
                      icon: Icons.apartment_rounded,
                      label: _static.propertyType.isNotEmpty
                          ? _static.propertyType
                          : widget.hotel.propertyType,
                    ),
                  MetaChip(
                    icon: Icons.nights_stay_rounded,
                    label: '$_nights night${_nights == 1 ? '' : 's'}',
                  ),
                  MetaChip(
                    icon: Icons.person_outline_rounded,
                    label:
                        '${_query.rooms.length} room${_query.rooms.length == 1 ? '' : 's'}'
                        ' · ${_query.guests} guest${_query.guests == 1 ? '' : 's'}',
                  ),
                ],
              ),

              ..._aboutSection(),
              ..._stayTimesSection(),
              ..._amenitiesSection(),
              ..._locationSection(),

              const SizedBox(height: AppSpacing.xxl),
              KeyedSubtree(
                key: _roomsKey,
                child: const SectionHeader(
                  title: 'Choose your room',
                  accent: true,
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (_rooms.isNotEmpty) ...[
                _buildRoomFilters(),
                const SizedBox(height: AppSpacing.md),
              ],
              if (_rooms.isEmpty)
                AppCard.outlined(
                  child: EmptyState(
                    compact: true,
                    title: 'No rooms available',
                    message:
                        'This property has no rooms for the selected dates. '
                        'Try changing your dates.',
                    icon: Icons.meeting_room_outlined,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                )
              else if (groups.isEmpty)
                AppCard.outlined(
                  child: EmptyState(
                    compact: true,
                    title: 'No rooms match these filters',
                    message:
                        'Clear a filter to see all ${_rooms.length} rates.',
                    icon: Icons.filter_alt_off_rounded,
                    actionLabel: 'Clear filters',
                    onAction: _clearRoomFilters,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                )
              else
                for (var i = 0; i < groups.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == groups.length - 1 ? 0 : AppSpacing.md,
                    ),
                    child: FadeSlideIn(
                      delay: AppMotion.staggerFor(i),
                      child: _RoomTypeCard(
                        name: groups[i].$1,
                        rates: groups[i].$2,
                        nights: _nights,
                        selectedOptionId: _selectedOptionId,
                        checkIn: _query.checkIn,
                        onSelect: _startBooking,
                      ),
                    ),
                  ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHero() {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_images.isEmpty)
            NetworkImageWidget(
              url: widget.hotel.imageUrl,
              fit: BoxFit.cover,
              scrim: true,
            )
          else
            PageView.builder(
              itemCount: _images.length,
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openGallery(i),
                child: NetworkImageWidget(
                  url: _images[i],
                  fit: BoxFit.cover,
                  memCacheWidth: 1080,
                  scrim: true,
                ),
              ),
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBackButton(
                    color: Colors.white,
                    background: Colors.black.withValues(alpha: 0.4),
                  ),
                  const Spacer(),
                  _HeroAction(icon: Icons.share_rounded, onTap: _share),
                  const SizedBox(width: AppSpacing.sm),
                  FavoriteButton(
                    isFavorite: _favourite,
                    onTap: _toggleFavourite,
                  ),
                ],
              ),
            ),
          ),
          if (_images.length > 1)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Pressable(
                onTap: () => _openGallery(0),
                borderRadius: AppRadii.rPill,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: AppRadii.rPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.photo_library_outlined,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_images.length} photos',
                        style: AppText.caption.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openGallery(int index) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: _HotelGalleryPage(
          title: widget.hotel.name,
          images: _images,
          initialIndex: index,
        ),
        style: PageTransitionStyle.fade,
      ),
    );
  }

  List<Widget> _aboutSection() {
    final about = _static.aboutText;
    if (about.isEmpty && _static.headline.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.xxl),
      SectionHeader(
        title: 'About this stay',
        accent: true,
        padding: EdgeInsets.zero,
        actionLabel: _static.aboutSections.length > 1 ? 'View more' : null,
        onAction: _static.aboutSections.length > 1 ? _openAboutSheet : null,
      ),
      const SizedBox(height: AppSpacing.sm),
      if (_static.headline.isNotEmpty) ...[
        Text(_static.headline, style: AppText.bodyStrong),
        const SizedBox(height: AppSpacing.xs),
      ],
      if (about.isNotEmpty)
        Text(
          about,
          style: AppText.body,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
    ];
  }

  void _openAboutSheet() {
    AppBottomSheet.show<void>(
      context,
      title: 'About ${widget.hotel.name}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final section in _static.aboutSections) ...[
            Text(section.title, style: AppText.cardTitle),
            const SizedBox(height: AppSpacing.xs),
            Text(section.body, style: AppText.bodySm),
            const SizedBox(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }

  List<Widget> _stayTimesSection() {
    final hasTimes = _static.hasStayTimes;
    final hasInfo = _static.hasImportantInfo || _static.phone.isNotEmpty;
    if (!hasTimes && !hasInfo) return const [];

    String range(String from, String till) =>
        [from, till].where((s) => s.isNotEmpty).join(' – ');

    return [
      const SizedBox(height: AppSpacing.xxl),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasTimes)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Stat(
                      label: 'Check-in from',
                      value: range(_static.checkInFrom, _static.checkInTill),
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      label: 'Check-out until',
                      value: range(_static.checkOutFrom, _static.checkOutTill),
                    ),
                  ),
                ],
              ),
            if (_static.minCheckInAge.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Minimum check-in age: ${_static.minCheckInAge}',
                style: AppText.caption,
              ),
            ],
            if (hasInfo) ...[
              const SizedBox(height: AppSpacing.md),
              PremiumButton.text(
                label: 'Important information',
                icon: Icons.info_outline_rounded,
                size: PremiumButtonSize.small,
                onPressed: _openImportantInfo,
              ),
            ],
          ],
        ),
      ),
    ];
  }

  /// The web's `HotelImportantInfoModal`: property facts, then the three
  /// policy blocks.
  void _openImportantInfo() {
    final facts = <(String, String)>[
      ('Property type', _static.propertyType),
      ('Phone', _static.phone),
      ('Chain', _static.chain),
      ('Brand', _static.brand),
      if (_static.minCheckInAge.isNotEmpty)
        ('Min. check-in age', _static.minCheckInAge),
    ].where((f) => f.$2.isNotEmpty).toList();

    Widget block(String title, List<HotelPolicyNote> notes) => notes.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppText.cardTitle),
                const SizedBox(height: AppSpacing.sm),
                HotelPolicyNotes(notes: notes),
              ],
            ),
          );

    AppBottomSheet.show<void>(
      context,
      title: 'Important information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (facts.isNotEmpty) ...[
            for (final (label, value) in facts)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(label, style: AppText.caption),
                    ),
                    Expanded(child: Text(value, style: AppText.bodyStrong)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          block('Special instructions', _static.specialInstructions),
          block('Know before you go', _static.knowBeforeYouGo),
          block('Fees', _static.mandatoryFees),
        ],
      ),
    );
  }

  List<Widget> _amenitiesSection() {
    final amenities = _static.amenities.isNotEmpty
        ? _static.amenities
        : widget.hotel.facilities;
    if (amenities.isEmpty) return const [];
    return [
      const SizedBox(height: AppSpacing.xxl),
      SectionHeader(
        title: 'Amenities',
        accent: true,
        padding: EdgeInsets.zero,
        actionLabel: amenities.length > 12 || _static.amenityGroups.isNotEmpty
            ? 'View all'
            : null,
        onAction: () => _openAmenities(amenities),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [for (final a in amenities.take(12)) MetaChip(label: a)],
      ),
    ];
  }

  void _openAmenities(List<String> flat) {
    final groups = _static.amenityGroups.isNotEmpty
        ? _static.amenityGroups
        : [(title: 'Hotel amenities', items: flat)];
    AppBottomSheet.show<void>(
      context,
      title: 'Hotel amenities',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final group in groups) ...[
            Text(group.title, style: AppText.cardTitle),
            const SizedBox(height: AppSpacing.sm),
            for (final item in group.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: AppColors.successDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(item, style: AppText.bodySm)),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  List<Widget> _locationSection() {
    if (_address.isEmpty && _static.latitude == null) return const [];
    return [
      const SizedBox(height: AppSpacing.xxl),
      const SectionHeader(
        title: 'Location',
        accent: true,
        padding: EdgeInsets.zero,
      ),
      const SizedBox(height: AppSpacing.sm),
      // The embedded map the web's detail model builds (`mapInfo.mapSrc`),
      // centred on the coordinates when the static content has them.
      HotelMapPreview(target: _mapTarget, onOpen: _openMap),
      const SizedBox(height: AppSpacing.sm),
      AppCard(
        child: Row(
          children: [
            const Icon(Icons.map_outlined, color: AppColors.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _address.isNotEmpty ? _address : widget.hotel.name,
                style: AppText.bodySm,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            PremiumButton.text(
              label: 'Open map',
              size: PremiumButtonSize.small,
              onPressed: _openMap,
            ),
          ],
        ),
      ),
    ];
  }

  /// Coordinates when the static content has them, the address otherwise —
  /// the web builds its map link the same way.
  String get _mapTarget => _static.latitude != null && _static.longitude != null
      ? '${_static.latitude},${_static.longitude}'
      : (_address.isNotEmpty ? _address : widget.hotel.name);

  Future<void> _openMap() async {
    final uri = Uri.parse(
      'https://www.google.com/maps?q=${Uri.encodeComponent(_mapTarget)}',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) AppSnackbar.error(context, 'Could not open maps.');
  }

  Widget _buildRoomFilters() {
    final plans = _mealPlans;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppTextField(
          controller: _roomSearch,
          hint: 'Search by room type or category',
          prefixIcon: Icons.search_rounded,
          onChanged: (v) => setState(() => _roomQuery = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterToggle(
                label: 'Refundable',
                selected: _refundableOnly,
                onTap: () => setState(() => _refundableOnly = !_refundableOnly),
              ),
              _FilterToggle(
                label: 'Breakfast included',
                selected: _breakfastOnly,
                onTap: () => setState(() => _breakfastOnly = !_breakfastOnly),
              ),
              _FilterToggle(
                label: 'PAN optional',
                selected: _panOptionalOnly,
                onTap: () =>
                    setState(() => _panOptionalOnly = !_panOptionalOnly),
              ),
              if (plans.length > 1)
                _FilterToggle(
                  label: _mealPlan.isEmpty ? 'Meal plan' : _mealPlan,
                  selected: _mealPlan.isNotEmpty,
                  trailing: Icons.arrow_drop_down_rounded,
                  onTap: () async {
                    final picked = await AppBottomSheet.show<String>(
                      context,
                      title: 'Meal plan',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final plan in ['', ...plans])
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(plan.isEmpty ? 'All' : plan),
                              trailing: plan == _mealPlan
                                  ? const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppColors.primary,
                                    )
                                  : null,
                              onTap: () => Navigator.pop(context, plan),
                            ),
                        ],
                      ),
                    );
                    if (picked != null) setState(() => _mealPlan = picked);
                  },
                ),
              if (_activeRoomFilters > 0)
                PremiumButton.text(
                  label: 'Clear',
                  size: PremiumButtonSize.small,
                  onPressed: _clearRoomFilters,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final selected = _selected;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: selected != null && selected.price > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected.name,
                          style: AppText.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(formatPrice(selected.price), style: AppText.price),
                      ],
                    )
                  : Text('Live pricing at checkout', style: AppText.bodySm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PremiumButton(
                label: selected == null ? 'No rooms' : 'Book now',
                trailingIcon: Icons.arrow_forward_rounded,
                enabled: selected?.isBookable ?? false,
                onPressed: selected == null || !selected.isBookable
                    ? null
                    : () => _startBooking(selected),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Room type card
// ---------------------------------------------------------------------------

/// One room type and every rate sold for it — the web's `RoomTypeGroup`.
class _RoomTypeCard extends StatefulWidget {
  const _RoomTypeCard({
    required this.name,
    required this.rates,
    required this.nights,
    required this.selectedOptionId,
    required this.checkIn,
    required this.onSelect,
  });

  final String name;
  final List<HotelRoomOption> rates;
  final int nights;
  final String selectedOptionId;
  final DateTime checkIn;
  final ValueChanged<HotelRoomOption> onSelect;

  @override
  State<_RoomTypeCard> createState() => _RoomTypeCardState();
}

class _RoomTypeCardState extends State<_RoomTypeCard> {
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lead = widget.rates.first;
    final images = lead.images;
    final amenities = lead.amenities;

    return AppCard.outlined(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (images.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadii.lg),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (i) => setState(() => _imageIndex = i),
                      itemBuilder: (context, i) => NetworkImageWidget(
                        url: images[i],
                        fit: BoxFit.cover,
                        memCacheWidth: 720,
                      ),
                    ),
                    if (images.length > 1)
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: AppRadii.rPill,
                          ),
                          child: Text(
                            '${_imageIndex + 1} / ${images.length}',
                            style: AppText.caption.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.name, style: AppText.cardTitle),
                if (lead.bedSummary.isNotEmpty ||
                    lead.guestSummary.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (lead.bedSummary.isNotEmpty)
                        MetaChip(
                          icon: Icons.bed_outlined,
                          label: lead.bedSummary,
                        ),
                      if (lead.guestSummary.isNotEmpty)
                        MetaChip(
                          icon: Icons.person_outline_rounded,
                          label: lead.guestSummary,
                        ),
                    ],
                  ),
                ],
                if (amenities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  for (final a in amenities.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: AppColors.successDark,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              a,
                              style: AppText.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (amenities.length > 4)
                    PremiumButton.text(
                      label: 'View more amenities',
                      size: PremiumButtonSize.small,
                      onPressed: () => _openRoomAmenities(amenities),
                    ),
                ],
                const SizedBox(height: AppSpacing.sm),
                for (var i = 0; i < widget.rates.length; i++) ...[
                  const Divider(
                    height: AppSpacing.lg,
                    color: AppColors.divider,
                  ),
                  _RateTile(
                    rate: widget.rates[i],
                    nights: widget.nights,
                    selected:
                        widget.rates[i].optionId == widget.selectedOptionId,
                    onPolicy: () => showHotelCancellationSheet(
                      context,
                      option: widget.rates[i],
                      checkIn: widget.checkIn,
                    ),
                    onFareInfo: () => showHotelFareInfoSheet(
                      context,
                      option: widget.rates[i],
                    ),
                    onSelect: widget.rates[i].isBookable
                        ? () => widget.onSelect(widget.rates[i])
                        : null,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRoomAmenities(List<String> amenities) {
    AppBottomSheet.show<void>(
      context,
      title: widget.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Room amenities', style: AppText.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          for (final a in amenities)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(a, style: AppText.bodySm)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// One rate of a room type: meal plan, refundability, compliance and price.
class _RateTile extends StatelessWidget {
  const _RateTile({
    required this.rate,
    required this.nights,
    required this.selected,
    required this.onPolicy,
    required this.onFareInfo,
    required this.onSelect,
  });

  final HotelRoomOption rate;
  final int nights;
  final bool selected;
  final VoidCallback onPolicy;
  final VoidCallback onFareInfo;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final nightly = nights > 1 && rate.price > 0 ? rate.price / nights : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            MetaChip(icon: Icons.restaurant_rounded, label: rate.mealPlan),
            if (rate.refundable != null)
              MetaChip(
                icon: rate.refundable!
                    ? Icons.check_circle_outline_rounded
                    : Icons.block_rounded,
                label: rate.cancellationLabel,
              ),
            MetaChip(
              icon: Icons.badge_outlined,
              label: rate.panRequired ? 'PAN required' : 'PAN not required',
            ),
            if (rate.passportRequired)
              const MetaChip(
                icon: Icons.book_outlined,
                label: 'Passport required',
              ),
          ],
        ),
        if (rate.cancellation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            rate.cancellation,
            style: AppText.caption.copyWith(
              color: rate.refundable == true
                  ? AppColors.successDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
        PremiumButton.text(
          label: 'Cancellation policy',
          size: PremiumButtonSize.small,
          onPressed: onPolicy,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: rate.price > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nightly > 0)
                          Text(
                            '${formatPrice(nightly)} / night',
                            style: AppText.caption,
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                formatPrice(rate.price),
                                style: AppText.price,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Fare breakup',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              onPressed: onFareInfo,
                            ),
                          ],
                        ),
                        Text('Total for your stay', style: AppText.caption),
                      ],
                    )
                  : Text('Priced at checkout', style: AppText.bodySm),
            ),
            const SizedBox(width: AppSpacing.md),
            PremiumButton(
              label: selected ? 'Book now' : 'Select',
              size: PremiumButtonSize.small,
              expanded: false,
              enabled: onSelect != null,
              onPressed: onSelect,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterToggle extends StatelessWidget {
  const _FilterToggle({
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Pressable(
        onTap: onTap,
        borderRadius: AppRadii.rPill,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.pinkSurface : AppColors.surface,
            borderRadius: AppRadii.rPill,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: AppText.buttonSm.copyWith(
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              if (trailing != null)
                Icon(
                  trailing,
                  size: 16,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: Colors.white),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value, style: AppText.bodyStrong),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Gallery
// ---------------------------------------------------------------------------

/// Full-screen photos with a thumbnail strip — the web's gallery modal.
class _HotelGalleryPage extends StatefulWidget {
  const _HotelGalleryPage({
    required this.title,
    required this.images,
    required this.initialIndex,
  });

  final String title;
  final List<String> images;
  final int initialIndex;

  @override
  State<_HotelGalleryPage> createState() => _HotelGalleryPageState();
}

class _HotelGalleryPageState extends State<_HotelGalleryPage> {
  late final PageController _pages = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          '${_index + 1} / ${widget.images.length}',
          style: AppText.body.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pages,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => InteractiveViewer(
                child: NetworkImageWidget(
                  url: widget.images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(AppSpacing.sm),
              itemCount: widget.images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _pages.jumpToPage(i),
                child: Opacity(
                  opacity: i == _index ? 1 : 0.5,
                  child: NetworkImageWidget(
                    url: widget.images[i],
                    width: 72,
                    height: 56,
                    radius: AppRadii.sm,
                    memCacheWidth: 200,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Superseded
// ---------------------------------------------------------------------------
//
// The previous page parsed `hotels/detail` and `hotels/static-content` itself,
// reading keys neither response has (top-level `images`/`description`,
// `totalPrice`/`tp`/`mb`/`cnp` on v3 options), so rooms showed price 0 and no
// static content ever appeared. Parsing now lives in `models/hotel_models.dart`
// (`HotelRoomOption`, `HotelStaticContent`); the old code is kept below.
//
// Old extraction helpers (were methods of _HotelDetailPageState):
//   // --- extraction (tolerant of the several shapes TripJack returns) --------
//
//   List<String> _extractImages(Map detail, Map staticContent) {
//     final out = <String>[];
//     if (widget.hotel.imageUrl.isNotEmpty) out.add(widget.hotel.imageUrl);
//
//     for (final source in [staticContent, detail]) {
//       final candidates = [
//         source['images'],
//         (source['hotel'] is Map) ? (source['hotel'] as Map)['images'] : null,
//         (source['data'] is Map) ? (source['data'] as Map)['images'] : null,
//       ];
//       for (final c in candidates) {
//         for (final item in asList(c)) {
//           final url = item is String
//               ? item
//               : firstNonEmpty([
//                   item is Map ? item['url'] : null,
//                   item is Map ? item['imageUrl'] : null,
//                   item is Map ? item['src'] : null,
//                 ]);
//           if (url.isNotEmpty && !out.contains(url)) out.add(url);
//         }
//       }
//     }
//     return out;
//   }
//
//   String _extractDescription(Map staticContent, Map detail) {
//     for (final source in [staticContent, detail]) {
//       final value = firstNonEmpty([
//         source['description'],
//         (source['hotel'] is Map)
//             ? (source['hotel'] as Map)['description']
//             : null,
//         (source['data'] is Map) ? (source['data'] as Map)['description'] : null,
//       ]);
//       if (value.isNotEmpty) {
//         // Some records carry HTML; strip tags rather than render markup here.
//         return value
//             .replaceAll(RegExp(r'<[^>]*>'), ' ')
//             .replaceAll(RegExp(r'\s+'), ' ')
//             .trim();
//       }
//     }
//     return '';
//   }
//
//   List<String> _extractAmenities(Map staticContent, Map detail) {
//     if (widget.hotel.facilities.isNotEmpty) return widget.hotel.facilities;
//     for (final source in [staticContent, detail]) {
//       for (final key in ['facilities', 'amenities', 'fac']) {
//         final list = asList(source[key]);
//         if (list.isNotEmpty) {
//           return list
//               .map(
//                 (f) => f is String ? f : asString(f is Map ? f['name'] : null),
//               )
//               .where((f) => f.isNotEmpty)
//               .toList();
//         }
//       }
//     }
//     return const [];
//   }
//
//   List<HotelRoomOption> _extractRooms(Map detail) {
//     final candidates = [
//       detail['options'],
//       detail['ops'],
//       detail['rooms'],
//       (detail['data'] is Map) ? (detail['data'] as Map)['options'] : null,
//       (detail['hotel'] is Map) ? (detail['hotel'] as Map)['options'] : null,
//     ];
//
//     for (final c in candidates) {
//       final list = asList(c);
//       if (list.isEmpty) continue;
//       return list
//           .map(HotelRoomOption.fromJson)
//           .where((r) => r.name.isNotEmpty)
//           .toList();
//     }
//     return const [];
//   }
//
//
// Old room model and card:
// /// One bookable room option from `hotels/detail`.
// ///
// /// The display fields are only half of what this carries: [optionId] and
// /// [raw] are what the review call needs to price this exact room, and without
// /// them a room can be shown but never booked.
// class HotelRoomOption {
//   const HotelRoomOption({
//     required this.name,
//     this.optionId = '',
//     this.mealPlan = '',
//     this.cancellation = '',
//     this.price = 0,
//     this.refundable,
//     this.raw = const <String, dynamic>{},
//   });
//
//   final String name;
//
//   /// `option.id` — identifies this room+rate to the supplier.
//   final String optionId;
//
//   final String mealPlan;
//   final String cancellation;
//   final double price;
//   final bool? refundable;
//   final Map<String, dynamic> raw;
//
//   bool get isBookable => optionId.isNotEmpty;
//
//   factory HotelRoomOption.fromJson(dynamic json) {
//     final rooms = asList(
//       json is Map ? json['roomInfo'] ?? json['rooms'] : null,
//     );
//     final firstRoom = rooms.isNotEmpty ? rooms.first : null;
//
//     String read(String key) => asString(
//       (json is Map ? json[key] : null) ??
//           (firstRoom is Map ? firstRoom[key] : null),
//     );
//
//     final name = firstNonEmpty([
//       read('roomTypeName'),
//       read('rt'),
//       read('name'),
//       read('roomType'),
//     ], fallback: 'Room');
//
//     double price = asDouble(
//       (json is Map ? (json['totalPrice'] ?? json['tp']) : null),
//     );
//     if (price == 0 && json is Map && json['fare'] is Map) {
//       price = asDouble((json['fare'] as Map)['totalFare']);
//     }
//
//     final refundableRaw = json is Map
//         ? (json['isRefundable'] ?? json['ref'])
//         : null;
//
//     return HotelRoomOption(
//       name: name,
//       optionId: firstNonEmpty([
//         json is Map ? json['id'] : null,
//         json is Map ? json['optionId'] : null,
//         json is Map ? json['oid'] : null,
//       ]),
//       raw: asJsonMap(json),
//       mealPlan: firstNonEmpty([read('mealPlan'), read('mb'), read('board')]),
//       cancellation: firstNonEmpty([read('cancellationPolicy'), read('cnp')]),
//       price: price,
//       refundable: refundableRaw is bool ? refundableRaw : null,
//     );
//   }
// }
//
// class _RoomCard extends StatelessWidget {
//   const _RoomCard({required this.room, required this.onSelect});
//
//   final HotelRoomOption room;
//   final VoidCallback? onSelect;
//
//   @override
//   Widget build(BuildContext context) {
//     return AppCard.outlined(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(room.name, style: AppText.cardTitle),
//           if (room.mealPlan.isNotEmpty || room.refundable != null) ...[
//             const SizedBox(height: AppSpacing.sm),
//             Wrap(
//               spacing: AppSpacing.sm,
//               runSpacing: AppSpacing.xs,
//               children: [
//                 if (room.mealPlan.isNotEmpty)
//                   MetaChip(
//                     icon: Icons.restaurant_rounded,
//                     label: room.mealPlan,
//                   ),
//                 if (room.refundable != null)
//                   MetaChip(
//                     icon: room.refundable!
//                         ? Icons.check_circle_outline_rounded
//                         : Icons.block_rounded,
//                     label: room.refundable! ? 'Refundable' : 'Non-refundable',
//                   ),
//               ],
//             ),
//           ],
//           if (room.cancellation.isNotEmpty) ...[
//             const SizedBox(height: AppSpacing.sm),
//             Text(
//               room.cancellation,
//               style: AppText.caption,
//               maxLines: 3,
//               overflow: TextOverflow.ellipsis,
//             ),
//           ],
//           const SizedBox(height: AppSpacing.md),
//           Row(
//             children: [
//               Expanded(
//                 child: room.price > 0
//                     ? Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Text('Total for your stay', style: AppText.caption),
//                           Text(
//                             formatPrice(room.price),
//                             style: AppText.price,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ],
//                       )
//                     : Text('Priced at checkout', style: AppText.bodySm),
//               ),
//               const SizedBox(width: AppSpacing.md),
//               PremiumButton(
//                 label: 'Select',
//                 size: PremiumButtonSize.small,
//                 expanded: false,
//                 enabled: onSelect != null,
//                 onPressed: onSelect,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
