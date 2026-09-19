/// Hotel results for a honeymoon search, from `POST hotels/search`.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../data/hotel_filters.dart';
import '../models/honeymoon_models.dart';
import 'hotel_detail_page.dart';
import 'widgets/hotel_filter_sheet.dart';
import 'widgets/hotel_widgets.dart';
import 'widgets/honeymoon_widgets.dart';

/// Sort values accepted by the search endpoint's `sortOrder` field.
enum HotelSort { popularity, priceLowToHigh, priceHighToLow, rating }

extension HotelSortLabel on HotelSort {
  String get label => switch (this) {
    HotelSort.popularity => 'Most popular',
    HotelSort.priceLowToHigh => 'Price (lowest first)',
    HotelSort.priceHighToLow => 'Price (highest first)',
    HotelSort.rating => 'Star rating (high to low)',
  };

  String get shortLabel => switch (this) {
    HotelSort.popularity => 'Popular',
    HotelSort.priceLowToHigh => 'Price ↑',
    HotelSort.priceHighToLow => 'Price ↓',
    HotelSort.rating => 'Rating',
  };

  /// The literal strings the backend's `mapSortOrderToAPI` accepts. These are
  /// snake_case on the wire even though the web's own select uses camelCase
  /// values — sending `priceAsc` is silently treated as "popularity".
  String get apiValue => switch (this) {
    HotelSort.popularity => 'popularity',
    HotelSort.priceLowToHigh => 'price_asc',
    HotelSort.priceHighToLow => 'price_desc',
    HotelSort.rating => 'rating',
  };
}

class HotelResultsPage extends StatefulWidget {
  const HotelResultsPage({
    super.key,
    required this.api,
    required this.query,
    required this.initialResult,
  });

  final HoneymoonApi api;

  /// Everything chosen on the search form — reused for every page, re-sort
  /// and detail call so none of it is lost on the way.
  final HotelSearchQuery query;
  final HotelSearchResult initialResult;

  @override
  State<HotelResultsPage> createState() => _HotelResultsPageState();
}

class _HotelResultsPageState extends State<HotelResultsPage> {
  final ScrollController _scrollController = ScrollController();

  late HotelSearchResult _result = widget.initialResult;
  late List<HotelResult> _hotels = List.of(widget.initialResult.hotels);

  /// The search on screen. Starts as the one passed in and is replaced when
  /// the traveller modifies it here — the web re-searches in place on its
  /// results page rather than navigating away.
  late HotelSearchQuery _query = widget.query;

  HotelSort _sort = HotelSort.popularity;

  /// Hotel-name search over the loaded list — the web's "Search by hotel
  /// name" box, debounced by 250 ms as there.
  final TextEditingController _nameController = TextEditingController();
  Timer? _nameDebounce;
  String _nameQuery = '';

  /// Saved hotels. The listing API has no notion of favourites (it always
  /// returns `userFavourite: false`) and there is no favourites endpoint, so
  /// — like the web, which keeps them in localStorage — they live on the
  /// device, under the same key.
  static const _favouritesKey = 'happywedz.hotelFavourites';
  Set<String> _favourites = <String>{};
  bool _favouritesOnly = false;

  /// Filtering is a client concern, applied over everything loaded so far —
  /// what the website does, and it keeps ticking a checkbox instant instead
  /// of costing a round trip. The sort is sent to the server *and* applied
  /// locally (see [_visible]), again as the website does.
  HotelFilters _filters = HotelFilters.empty;

  List<HotelFacetGroup> get _facets => buildHotelFacets(_hotels);

  // List<HotelResult> get _visible => filterHotels(_hotels, _filters);

  /// Facet filters, then the name search and favourites, then the sort — the
  /// same pipeline as the web's `visibleHotels`. Sorting happens here too:
  /// TripJack's listing ignores the sort parameter, so the web orders the
  /// loaded results itself (`sortHotels`).
  List<HotelResult> get _visible {
    var list = filterHotels(_hotels, _filters);
    final name = _nameQuery.trim().toLowerCase();
    if (name.isNotEmpty) {
      list = list.where((h) => h.name.toLowerCase().contains(name)).toList();
    }
    if (_favouritesOnly) {
      list = list.where((h) => _favourites.contains(h.id)).toList();
    }
    return _sorted(list);
  }

  /// Hotels without a price sink to the bottom of both price sorts instead
  /// of counting as zero and leading "lowest first".
  List<HotelResult> _sorted(List<HotelResult> hotels) {
    int byPrice(HotelResult a, HotelResult b, {required bool ascending}) {
      if (!a.hasPrice && !b.hasPrice) return 0;
      if (!a.hasPrice) return 1;
      if (!b.hasPrice) return -1;
      return ascending
          ? a.price.compareTo(b.price)
          : b.price.compareTo(a.price);
    }

    final list = List.of(hotels);
    switch (_sort) {
      case HotelSort.priceLowToHigh:
        list.sort((a, b) => byPrice(a, b, ascending: true));
      case HotelSort.priceHighToLow:
        list.sort((a, b) => byPrice(a, b, ascending: false));
      case HotelSort.rating:
        list.sort((a, b) {
          final byStars = b.starRating.compareTo(a.starRating);
          return byStars != 0 ? byStars : byPrice(a, b, ascending: true);
        });
      case HotelSort.popularity:
        // No ranking signal from the supplier: keep the order it sent.
        break;
    }
    return list;
  }

  bool get _hasActiveFilters =>
      _filters.activeCount > 0 ||
      _nameQuery.trim().isNotEmpty ||
      _favouritesOnly;

  /// TripJack's own destination count while nothing is filtered — steady as
  /// more pages load — and the number of matches once something is.
  int _countShown() =>
      _hasActiveFilters ? _visible.length : _result.displayCount;

  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFavourites();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _nameDebounce?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadFavourites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_favouritesKey) ?? const [];
      if (!mounted) return;
      setState(() => _favourites = saved.toSet());
    } catch (_) {
      // Blocked storage: favourites still work for this session.
    }
  }

  Future<void> _toggleFavourite(HotelResult hotel) async {
    setState(() {
      _favourites = Set.of(_favourites);
      if (!_favourites.remove(hotel.id)) _favourites.add(hotel.id);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favouritesKey, _favourites.toList());
    } catch (_) {
      // Kept in memory for this session.
    }
  }

  void _onNameChanged(String value) {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(
      const Duration(milliseconds: 250),
      () => setState(() => _nameQuery = value),
    );
  }

  void _clearAllFilters() {
    _nameDebounce?.cancel();
    _nameController.clear();
    setState(() {
      _filters = HotelFilters.empty;
      _nameQuery = '';
      _favouritesOnly = false;
    });
  }

  /// A modified search from the summary bar (or from a detail page opened
  /// from here): swap the list in place, keeping filters that still apply —
  /// the web's `onSearch` + `sanitizeAppliedFilters`.
  void _applyNewSearch(HotelSearchQuery query, HotelSearchResult result) {
    setState(() {
      _query = query;
      _result = result;
      _hotels = List.of(result.hotels);
      _filters = _filters.reconcile(buildHotelFacets(_hotels));
      _error = null;
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _editSearch() => showHotelSearchSheet(
    context,
    api: widget.api,
    initial: _query,
    onSearch: _applyNewSearch,
  );

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320 &&
        !_loadingMore &&
        !_loading &&
        _result.hasMore) {
      _loadMore();
    }
  }

  int get _nights => _query.nights;

  /// Re-runs the search from page one — used by sort and by retry.
  ///
  /// Filters deliberately do not come through here: they are applied to the
  /// loaded list, so changing one costs nothing and never re-orders the
  /// results underneath the user.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.searchHotels(
        _query,
        sortOrder: _sort.apiValue,
        // The web re-runs page one with the search it already has.
        searchId: _result.searchId,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _hotels = List.of(result.hotels);
        // A fresh result set may not offer every option the old one did.
        _filters = _filters.reconcile(buildHotelFacets(_hotels));
        _loading = false;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final next = await widget.api.searchHotels(
        _query,
        sortOrder: _sort.apiValue,
        lastHotelId: _result.lastHotelId,
        searchId: _result.searchId,
      );
      if (!mounted) return;
      setState(() {
        // BUG FIX: sweeps overlap — a hotel already on screen can come back
        // on the next page — and plain `addAll` showed it twice. Merged by
        // id with the newer copy winning, as the web's `mergeHotels` does.
        // _hotels.addAll(next.hotels);
        for (final hotel in next.hotels) {
          final at = _hotels.indexWhere((h) => h.id == hotel.id);
          if (at >= 0) {
            _hotels[at] = hotel;
          } else {
            _hotels.add(hotel);
          }
        }
        _result = next;
        _loadingMore = false;
      });

      // Filtering happens after paging, so a narrow filter can leave too few
      // cards to scroll — and with nothing to scroll, the infinite loader never
      // fires again and the user is stranded on a near-empty list while more
      // matches sit unfetched. Keep pulling pages until there is enough on
      // screen to scroll for the rest.
      if (mounted &&
          _hasActiveFilters &&
          _result.hasMore &&
          _visible.length < 8) {
        await _loadMore();
      }
    } on HoneymoonApiException {
      // A failed page-append should not destroy results already on screen.
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _openSortSheet() async {
    await AppBottomSheet.show(
      context,
      title: 'Sort by',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final option in HotelSort.values)
            Pressable(
              onTap: () {
                Navigator.pop(context);
                if (option != _sort) {
                  setState(() => _sort = option);
                  _reload();
                }
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

  Future<void> _openFilterSheet() async {
    final facets = _facets;
    if (facets.isEmpty) return;

    final result = await showHotelFilterSheet(
      context,
      facets: facets,
      current: _filters,
      hotels: _hotels,
    );
    if (result != null && mounted) setState(() => _filters = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _query.destination.displayName,
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(_query.checkIn)} – '
              '${formatTripDate(_query.checkOut)}'
              ' · $_nights night${_nights == 1 ? '' : 's'}'
              ' · ${_query.guests} guest${_query.guests == 1 ? '' : 's'}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: HotelSearchSummaryBar(query: _query, onEdit: _editSearch),
          ),
          _buildToolbar(),
          _buildSearchRow(),
          _buildChipsRail(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _loading
                  ? 'Searching…'
                  : _result.allUnavailable
                  ? 'No rooms on these dates'
                  : '${_countShown()} stay${_countShown() == 1 ? '' : 's'}',
              style: AppText.labelSm,
            ),
          ),
          _ToolbarButton(
            icon: Icons.swap_vert_rounded,
            label: _sort.shortLabel,
            active: true,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolbarButton(
            icon: Icons.tune_rounded,
            label: _filters.activeCount > 0
                ? 'Filters (${_filters.activeCount})'
                : 'Filters',
            active: _filters.activeCount > 0,
            onTap: _openFilterSheet,
          ),
        ],
      ),
    );
  }

  /// Hotel-name search and the favourites toggle — the web's sidebar
  /// "Search by hotel name" box and "View favourites" button.
  Widget _buildSearchRow() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppTextField(
              controller: _nameController,
              hint: 'Search by hotel name',
              prefixIcon: Icons.search_rounded,
              suffixIcon: _nameController.text.isEmpty
                  ? null
                  : Icons.close_rounded,
              onSuffixTap: () {
                _nameController.clear();
                _onNameChanged('');
              },
              textInputAction: TextInputAction.search,
              onChanged: _onNameChanged,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolbarButton(
            icon: _favouritesOnly
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: 'Saved',
            active: _favouritesOnly,
            onTap: () => setState(() => _favouritesOnly = !_favouritesOnly),
          ),
        ],
      ),
    );
  }

  /// Removable chips for whatever is currently applied, so a filter can be
  /// undone without reopening the sheet.
  Widget _buildChipsRail() {
    final chips = describeHotelFilters(_filters, _facets);
    if (chips.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: HotelAppliedFiltersRail(
        chips: chips,
        onRemove: (chip) =>
            setState(() => _filters = removeHotelChip(_filters, chip)),
        onClearAll: () => setState(() => _filters = HotelFilters.empty),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Skeletons.listCards(count: 4, height: 260),
      );
    }

    if (_error != null && _hotels.isEmpty) {
      return ErrorState(
        title: AppErrorMessage.genericTitle,
        message: _error is HoneymoonApiException
            ? (_error as HoneymoonApiException).message
            : AppErrorMessage.genericBody,
        onRetry: _reload,
      );
    }

    final visible = _visible;

    if (visible.isEmpty) {
      // Two different dead ends: the search itself came back empty, or the
      // user's own filters excluded every loaded stay. Only the second one is
      // recoverable without changing the search.
      final filtered = _hotels.isNotEmpty && _hasActiveFilters;
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            EmptyState(
              title: filtered
                  ? 'No stays match your filters'
                  : 'No stays found',
              message: filtered
                  ? 'Clear a filter or two to see the ${_hotels.length} '
                        'stay${_hotels.length == 1 ? '' : 's'} we found.'
                  : 'Try changing your destination or dates.',
              icon: filtered
                  ? Icons.filter_alt_off_rounded
                  : Icons.hotel_outlined,
              actionLabel: filtered ? 'Clear filters' : null,
              onAction: filtered ? _clearAllFilters : null,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _reload,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        // One header slot: the section title, and the notice when every
        // property came back without rates.
        itemCount: visible.length + 1 + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) return _buildListHeader();
          final i = index - 1;
          if (i >= visible.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: AppLoader(),
            );
          }
          return FadeSlideIn(
            delay: AppMotion.staggerFor(i),
            child: HotelCard(
              hotel: visible[i],
              nights: _nights,
              isFavourite: _favourites.contains(visible[i].id),
              onToggleFavourite: () => _toggleFavourite(visible[i]),
              onTap: () async {
                await Navigator.push(
                  context,
                  AnimatedPageRoute(
                    page: HotelDetailPage(
                      api: widget.api,
                      hotel: visible[i],
                      query: _query,
                      searchId: _result.searchId,
                      // A search modified on the detail page lands back
                      // here, as the web routes it to /hotels.
                      onNewSearch: (query, result) {
                        final resultsRoute = ModalRoute.of(this.context);
                        Navigator.of(
                          this.context,
                        ).popUntil((route) => route == resultsRoute);
                        _applyNewSearch(query, result);
                      },
                    ),
                    style: PageTransitionStyle.slideRight,
                  ),
                );
                // A heart set on the detail page shows here too.
                if (mounted) _loadFavourites();
              },
            ),
          );
        },
      ),
    );
  }

  /// "Popular in Goa", or "Property searched" when the search was for one
  /// named hotel — TripJack's wording — plus the no-rates notice.
  Widget _buildListHeader() {
    final destination = _query.destination;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          destination.isHotel
              ? 'Property searched'
              : 'Popular in ${destination.displayName}',
          style: AppText.sectionTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (_result.allUnavailable) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.08),
              borderRadius: AppRadii.rMd,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.event_busy_rounded,
                  size: 17,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'None of these properties have rooms for your dates. '
                    'Try different dates, or a nearby destination.',
                    style: AppText.bodySm,
                  ),
                ),
              ],
            ),
          ),
        ],
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

/// Result card. Every element is conditional — a field the API omitted is
/// hidden rather than rendered as a placeholder.
class HotelCard extends StatelessWidget {
  const HotelCard({
    super.key,
    required this.hotel,
    required this.nights,
    required this.onTap,
    this.isFavourite = false,
    this.onToggleFavourite,
  });

  final HotelResult hotel;
  final int nights;
  final VoidCallback onTap;
  final bool isFavourite;
  final VoidCallback? onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              // The web card swipes through up to ten photos with a
              // "1 / 10" counter; a single photo stays a plain image.
              // NetworkImageWidget(
              //   url: hotel.imageUrl,
              //   aspectRatio: 16 / 9,
              //   width: double.infinity,
              //   memCacheWidth: 720,
              //   borderRadius: const BorderRadius.vertical(
              //     top: Radius.circular(AppRadii.lg),
              //   ),
              //   scrim: true,
              // ),
              _CardGallery(
                images: hotel.images.isNotEmpty
                    ? hotel.images
                    : [hotel.imageUrl],
              ),
              if (onToggleFavourite != null)
                Positioned(
                  right: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: FavoriteButton(
                    isFavorite: isFavourite,
                    onTap: onToggleFavourite,
                  ),
                ),
              if (hotel.starRating > 0)
                Positioned(
                  left: AppSpacing.sm,
                  top: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 12,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${hotel.starRating.toStringAsFixed(0)}-star',
                          style: AppText.caption.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              if (hotel.reviewScore > 0)
                Positioned(
                  left: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successDark,
                      borderRadius: AppRadii.rSm,
                    ),
                    child: Text(
                      [
                        hotel.reviewScore.toStringAsFixed(1),
                        // The supplier's own wording ("Excellent") reads better
                        // than a bare number, so it leads when present.
                        if (hotel.reviewLabel.isNotEmpty) hotel.reviewLabel,
                        if (hotel.reviewCount > 0) '${hotel.reviewCount}',
                      ].join(' · '),
                      style: AppText.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hotel.name,
                  style: AppText.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hotel.address.isNotEmpty || hotel.city.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 13,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        // The web card prints just the city under the name.
                        child: Text(
                          hotel.city.isNotEmpty ? hotel.city : hotel.address,
                          style: AppText.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                // Board basis and refundability are what actually separate two
                // otherwise identical listings, so they lead the chip row.
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (hotel.isRefundable)
                      const MetaChip(
                        label: 'Free cancellation',
                        icon: Icons.verified_rounded,
                      ),
                    if (hotel.mealBasis.isNotEmpty)
                      MetaChip(
                        label: hotel.mealBasis,
                        icon: Icons.restaurant_rounded,
                      ),
                    for (final f in hotel.facilities.take(2))
                      MetaChip(label: f),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: hotel.hasPrice
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Starting from', style: AppText.caption),
                                Text(
                                  formatPrice(hotel.price),
                                  style: AppText.price,
                                ),
                                if (nights > 0)
                                  Text(
                                    'for $nights night${nights == 1 ? '' : 's'}',
                                    style: AppText.caption,
                                  ),
                              ],
                            )
                          : Text(
                              hotel.available
                                  ? 'Tap to see live pricing'
                                  : 'No rooms for your dates',
                              style: AppText.caption,
                            ),
                    ),
                    PremiumButton(
                      label: 'View',
                      size: PremiumButtonSize.small,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: onTap,
                      // BUG FIX: PremiumButton defaults to expanded (fills
                      // available width via SizedBox(width: infinity)), which
                      // is only safe with bounded width from a parent — as a
                      // plain Row child it gets unbounded width, throwing
                      // "BoxConstraints forces an infinite width" and taking
                      // the whole card (and the ListView around it) down with
                      // it. See the widget's own doc comment on `expanded`.
                      expanded: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Swipeable card photos with a "1 / 10" counter.
class _CardGallery extends StatefulWidget {
  const _CardGallery({required this.images});

  final List<String> images;

  @override
  State<_CardGallery> createState() => _CardGalleryState();
}

class _CardGalleryState extends State<_CardGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.vertical(top: Radius.circular(AppRadii.lg));
    final images = widget.images.where((u) => u.isNotEmpty).toList();

    if (images.length <= 1) {
      return NetworkImageWidget(
        url: images.isEmpty ? '' : images.first,
        aspectRatio: 16 / 9,
        width: double.infinity,
        memCacheWidth: 720,
        borderRadius: radius,
        scrim: true,
      );
    }

    return ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => NetworkImageWidget(
                url: images[i],
                fit: BoxFit.cover,
                memCacheWidth: 720,
                scrim: true,
              ),
            ),
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
                  '${_index + 1} / ${images.length}',
                  style: AppText.caption.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
