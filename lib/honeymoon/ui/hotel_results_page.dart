/// Hotel results for a honeymoon search, from `POST hotels/search`.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../models/honeymoon_models.dart';
import 'hotel_detail_page.dart';
import 'widgets/honeymoon_widgets.dart';

/// Sort values accepted by the search endpoint's `sortOrder` field.
enum HotelSort { popularity, priceLowToHigh, priceHighToLow, rating }

extension on HotelSort {
  String get label => switch (this) {
    HotelSort.popularity => 'Recommended',
    HotelSort.priceLowToHigh => 'Price: low to high',
    HotelSort.priceHighToLow => 'Price: high to low',
    HotelSort.rating => 'Rating',
  };

  String get apiValue => switch (this) {
    HotelSort.popularity => 'popularity',
    HotelSort.priceLowToHigh => 'priceAsc',
    HotelSort.priceHighToLow => 'priceDesc',
    HotelSort.rating => 'rating',
  };
}

class HotelResultsPage extends StatefulWidget {
  const HotelResultsPage({
    super.key,
    required this.api,
    required this.destination,
    required this.checkIn,
    required this.checkOut,
    required this.rooms,
    required this.initialResult,
  });

  final HoneymoonApi api;
  final HoneymoonDestination destination;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<RoomOccupancy> rooms;
  final HotelSearchResult initialResult;

  @override
  State<HotelResultsPage> createState() => _HotelResultsPageState();
}

class _HotelResultsPageState extends State<HotelResultsPage> {
  final ScrollController _scrollController = ScrollController();

  late HotelSearchResult _result = widget.initialResult;
  late List<HotelResult> _hotels = List.of(widget.initialResult.hotels);

  HotelSort _sort = HotelSort.popularity;
  Set<int> _ratings = {};

  bool _loading = false;
  bool _loadingMore = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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

  int get _nights => widget.checkOut.difference(widget.checkIn).inDays;

  /// Re-runs the search from page one — used by sort, filters and retry.
  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.searchHotels(
        destination: widget.destination,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        rooms: widget.rooms,
        ratings: _ratings.toList()..sort(),
        sortOrder: _sort.apiValue,
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _hotels = List.of(result.hotels);
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
        destination: widget.destination,
        checkIn: widget.checkIn,
        checkOut: widget.checkOut,
        rooms: widget.rooms,
        ratings: _ratings.toList()..sort(),
        sortOrder: _sort.apiValue,
        lastHotelId: _result.lastHotelId,
        searchId: _result.searchId,
      );
      if (!mounted) return;
      setState(() {
        _hotels.addAll(next.hotels);
        _result = next;
        _loadingMore = false;
      });
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
    final draft = Set<int>.from(_ratings);

    await AppBottomSheet.show(
      context,
      title: 'Filters',
      child: StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Star rating', style: AppText.formLabel),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final star in [5, 4, 3, 2, 1])
                    Pressable(
                      onTap: () => setSheetState(() {
                        if (!draft.remove(star)) draft.add(star);
                      }),
                      borderRadius: AppRadii.rPill,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: draft.contains(star)
                              ? AppColors.pinkSurface
                              : AppColors.surface,
                          borderRadius: AppRadii.rPill,
                          border: Border.all(
                            color: draft.contains(star)
                                ? AppColors.primary
                                : AppColors.divider,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: AppColors.warning,
                            ),
                            const SizedBox(width: AppSpacing.xxs),
                            Text('$star', style: AppText.labelSm),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: PremiumButton.outlined(
                      label: 'Reset',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        if (_ratings.isNotEmpty) {
                          setState(() => _ratings = {});
                          _reload();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumButton(
                      label: 'Apply',
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        setState(() => _ratings = draft);
                        _reload();
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
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
              widget.destination.displayName,
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(widget.checkIn)} – ${formatTripDate(widget.checkOut)}'
              ' · $_nights night${_nights == 1 ? '' : 's'}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildToolbar(),
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
                  : '${_hotels.length} stay${_hotels.length == 1 ? '' : 's'}',
              style: AppText.labelSm,
            ),
          ),
          _ToolbarButton(
            icon: Icons.swap_vert_rounded,
            label: 'Sort',
            active: _sort != HotelSort.popularity,
            onTap: _openSortSheet,
          ),
          const SizedBox(width: AppSpacing.sm),
          _ToolbarButton(
            icon: Icons.tune_rounded,
            label: 'Filters',
            active: _ratings.isNotEmpty,
            onTap: _openFilterSheet,
          ),
        ],
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

    if (_hotels.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.08),
            EmptyState(
              title: 'No stays found',
              message: 'Try changing your destination, dates or filters.',
              icon: Icons.hotel_outlined,
              actionLabel: _ratings.isEmpty ? null : 'Clear filters',
              onAction: _ratings.isEmpty
                  ? null
                  : () {
                      setState(() => _ratings = {});
                      _reload();
                    },
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
        itemCount: _hotels.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, i) {
          if (i >= _hotels.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: AppLoader(),
            );
          }
          return FadeSlideIn(
            delay: AppMotion.staggerFor(i),
            child: HotelCard(
              hotel: _hotels[i],
              nights: _nights,
              onTap: () => Navigator.push(
                context,
                AnimatedPageRoute(
                  page: HotelDetailPage(
                    api: widget.api,
                    hotel: _hotels[i],
                    searchId: _result.searchId,
                    checkIn: widget.checkIn,
                    checkOut: widget.checkOut,
                    nights: _nights,
                  ),
                  style: PageTransitionStyle.slideRight,
                ),
              ),
            ),
          );
        },
      ),
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
  });

  final HotelResult hotel;
  final int nights;
  final VoidCallback onTap;

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
              NetworkImageWidget(
                url: hotel.imageUrl,
                aspectRatio: 16 / 9,
                width: double.infinity,
                memCacheWidth: 720,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                scrim: true,
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
                  right: AppSpacing.sm,
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
                      hotel.reviewCount > 0
                          ? '${hotel.reviewScore.toStringAsFixed(1)} · ${hotel.reviewCount}'
                          : hotel.reviewScore.toStringAsFixed(1),
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
                        child: Text(
                          hotel.address.isNotEmpty ? hotel.address : hotel.city,
                          style: AppText.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (hotel.facilities.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final f in hotel.facilities.take(3))
                        MetaChip(label: f),
                    ],
                  ),
                ],

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
                              'Tap to see live pricing',
                              style: AppText.caption,
                            ),
                    ),
                    PremiumButton(
                      label: 'View',
                      size: PremiumButtonSize.small,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: onTap,
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