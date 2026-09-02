/// Hotel detail — room options and pricing from `POST hotels/detail`, with
/// descriptive content from `POST hotels/static-content`.
library;

import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../data/honeymoon_api.dart';
import '../models/honeymoon_models.dart';
import 'booking/hotel_booking_page.dart';
import 'widgets/honeymoon_widgets.dart';

class HotelDetailPage extends StatefulWidget {
  const HotelDetailPage({
    super.key,
    required this.api,
    required this.hotel,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    this.searchId = '',
  });

  final HoneymoonApi api;
  final HotelResult hotel;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final String searchId;

  @override
  State<HotelDetailPage> createState() => _HotelDetailPageState();
}

class _HotelDetailPageState extends State<HotelDetailPage> {
  bool _loading = true;
  Object? _error;

  List<String> _images = const [];
  String _description = '';
  List<String> _amenities = const [];
  List<HotelRoomOption> _rooms = const [];

  /// The untouched `hotels/detail` response. The review call is keyed on ids
  /// that live only here, so it has to outlive the parse into view models.
  Map<String, dynamic> _detail = const <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Pricing and descriptive content come from two different endpoints.
      // A failure of the descriptive one must not block the page.
      final detail = await widget.api.fetchHotelDetail(
        hotelId: widget.hotel.id,
        searchId: widget.searchId,
        optionId: widget.hotel.optionId,
      );

      Map<String, dynamic> staticContent = const {};
      try {
        staticContent = await widget.api.fetchHotelStaticContent(
          hotelId: widget.hotel.id,
        );
      } on HoneymoonApiException {
        // Non-fatal — the page still works with search-result data.
      }

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _images = _extractImages(detail, staticContent);
        _description = _extractDescription(staticContent, detail);
        _amenities = _extractAmenities(staticContent, detail);
        _rooms = _extractRooms(detail);
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

  // --- extraction (tolerant of the several shapes TripJack returns) --------

  List<String> _extractImages(Map detail, Map staticContent) {
    final out = <String>[];
    if (widget.hotel.imageUrl.isNotEmpty) out.add(widget.hotel.imageUrl);

    for (final source in [staticContent, detail]) {
      final candidates = [
        source['images'],
        (source['hotel'] is Map) ? (source['hotel'] as Map)['images'] : null,
        (source['data'] is Map) ? (source['data'] as Map)['images'] : null,
      ];
      for (final c in candidates) {
        for (final item in asList(c)) {
          final url = item is String
              ? item
              : firstNonEmpty([
                  item is Map ? item['url'] : null,
                  item is Map ? item['imageUrl'] : null,
                  item is Map ? item['src'] : null,
                ]);
          if (url.isNotEmpty && !out.contains(url)) out.add(url);
        }
      }
    }
    return out;
  }

  String _extractDescription(Map staticContent, Map detail) {
    for (final source in [staticContent, detail]) {
      final value = firstNonEmpty([
        source['description'],
        (source['hotel'] is Map)
            ? (source['hotel'] as Map)['description']
            : null,
        (source['data'] is Map) ? (source['data'] as Map)['description'] : null,
      ]);
      if (value.isNotEmpty) {
        // Some records carry HTML; strip tags rather than render markup here.
        return value.replaceAll(RegExp(r'<[^>]*>'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      }
    }
    return '';
  }

  List<String> _extractAmenities(Map staticContent, Map detail) {
    if (widget.hotel.facilities.isNotEmpty) return widget.hotel.facilities;
    for (final source in [staticContent, detail]) {
      for (final key in ['facilities', 'amenities', 'fac']) {
        final list = asList(source[key]);
        if (list.isNotEmpty) {
          return list
              .map((f) => f is String ? f : asString(f is Map ? f['name'] : null))
              .where((f) => f.isNotEmpty)
              .toList();
        }
      }
    }
    return const [];
  }

  List<HotelRoomOption> _extractRooms(Map detail) {
    final candidates = [
      detail['options'],
      detail['ops'],
      detail['rooms'],
      (detail['data'] is Map) ? (detail['data'] as Map)['options'] : null,
      (detail['hotel'] is Map) ? (detail['hotel'] as Map)['options'] : null,
    ];

    for (final c in candidates) {
      final list = asList(c);
      if (list.isEmpty) continue;
      return list
          .map(HotelRoomOption.fromJson)
          .where((r) => r.name.isNotEmpty)
          .toList();
    }
    return const [];
  }

  /// Rooms the supplier gave us enough information to book, cheapest first.
  List<HotelRoomOption> get _bookableRooms {
    final list = _rooms.where((r) => r.isBookable).toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return list;
  }

  void _startBooking(HotelRoomOption room) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: HotelBookingPage(
          api: widget.api,
          hotel: widget.hotel,
          room: room,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          nights: widget.nights,
          searchId: widget.searchId,
          detail: _detail,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
  }

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
      bottomNavigationBar: _loading || _error != null ? null : _buildBottomBar(),
    );
  }

  Widget _buildContent() {
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
              Text(widget.hotel.name, style: AppText.display.copyWith(fontSize: 22)),
              if (widget.hotel.address.isNotEmpty ||
                  widget.hotel.city.isNotEmpty) ...[
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
                    Expanded(
                      child: Text(
                        widget.hotel.address.isNotEmpty
                            ? widget.hotel.address
                            : widget.hotel.city,
                        style: AppText.bodySm,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (widget.hotel.starRating > 0)
                    MetaChip(
                      icon: Icons.star_rounded,
                      label:
                          '${widget.hotel.starRating.toStringAsFixed(0)}-star',
                    ),
                  if (widget.hotel.reviewScore > 0)
                    MetaChip(
                      icon: Icons.thumb_up_rounded,
                      label: widget.hotel.reviewCount > 0
                          ? '${widget.hotel.reviewScore.toStringAsFixed(1)} (${widget.hotel.reviewCount})'
                          : widget.hotel.reviewScore.toStringAsFixed(1),
                    ),
                  MetaChip(
                    icon: Icons.nights_stay_rounded,
                    label:
                        '${widget.nights} night${widget.nights == 1 ? '' : 's'}',
                  ),
                ],
              ),

              if (_description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(
                  title: 'About this stay',
                  accent: true,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(_description, style: AppText.body),
              ],

              if (_amenities.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(
                  title: 'Amenities',
                  accent: true,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final a in _amenities.take(16)) MetaChip(label: a),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),
              const SectionHeader(
                title: 'Room options',
                accent: true,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: AppSpacing.md),
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
              else
                for (var i = 0; i < _rooms.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == _rooms.length - 1 ? 0 : AppSpacing.md,
                    ),
                    child: FadeSlideIn(
                      delay: AppMotion.staggerFor(i),
                      child: _RoomCard(
                        room: _rooms[i],
                        onSelect: _rooms[i].isBookable
                            ? () => _startBooking(_rooms[i])
                            : null,
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
              itemBuilder: (context, i) => NetworkImageWidget(
                url: _images[i],
                fit: BoxFit.cover,
                memCacheWidth: 1080,
                scrim: true,
              ),
            ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Align(
                alignment: Alignment.topLeft,
                child: AppBackButton(
                  color: Colors.white,
                  background: Colors.black.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),

          if (_images.length > 1)
            Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: AppRadii.rPill,
                ),
                child: Text(
                  '${_images.length} photos',
                  style: AppText.caption.copyWith(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final cheapest = _rooms.isEmpty
        ? widget.hotel.price
        : _rooms.map((r) => r.price).where((p) => p > 0).fold<double>(
            widget.hotel.price,
            (min, p) => min == 0 || p < min ? p : min,
          );

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
              child: cheapest > 0
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Starting from', style: AppText.caption),
                        Text(formatPrice(cheapest), style: AppText.price),
                      ],
                    )
                  : Text('Live pricing at checkout', style: AppText.bodySm),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: PremiumButton(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward_rounded,
                enabled: _bookableRooms.isNotEmpty,
                onPressed: _bookableRooms.isEmpty
                    ? null
                    : () => _startBooking(_bookableRooms.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One bookable room option from `hotels/detail`.
///
/// The display fields are only half of what this carries: [optionId] and
/// [raw] are what the review call needs to price this exact room, and without
/// them a room can be shown but never booked.
class HotelRoomOption {
  const HotelRoomOption({
    required this.name,
    this.optionId = '',
    this.mealPlan = '',
    this.cancellation = '',
    this.price = 0,
    this.refundable,
    this.raw = const <String, dynamic>{},
  });

  final String name;

  /// `option.id` — identifies this room+rate to the supplier.
  final String optionId;

  final String mealPlan;
  final String cancellation;
  final double price;
  final bool? refundable;
  final Map<String, dynamic> raw;

  bool get isBookable => optionId.isNotEmpty;

  factory HotelRoomOption.fromJson(dynamic json) {
    final rooms = asList(json is Map ? json['roomInfo'] ?? json['rooms'] : null);
    final firstRoom = rooms.isNotEmpty ? rooms.first : null;

    String read(String key) => asString(
      (json is Map ? json[key] : null) ??
          (firstRoom is Map ? firstRoom[key] : null),
    );

    final name = firstNonEmpty([
      read('roomTypeName'),
      read('rt'),
      read('name'),
      read('roomType'),
    ], fallback: 'Room');

    double price = asDouble(
      (json is Map ? (json['totalPrice'] ?? json['tp']) : null),
    );
    if (price == 0 && json is Map && json['fare'] is Map) {
      price = asDouble((json['fare'] as Map)['totalFare']);
    }

    final refundableRaw = json is Map ? (json['isRefundable'] ?? json['ref']) : null;

    return HotelRoomOption(
      name: name,
      optionId: firstNonEmpty([
        json is Map ? json['id'] : null,
        json is Map ? json['optionId'] : null,
        json is Map ? json['oid'] : null,
      ]),
      raw: asJsonMap(json),
      mealPlan: firstNonEmpty([read('mealPlan'), read('mb'), read('board')]),
      cancellation: firstNonEmpty([
        read('cancellationPolicy'),
        read('cnp'),
      ]),
      price: price,
      refundable: refundableRaw is bool ? refundableRaw : null,
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onSelect});

  final HotelRoomOption room;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(room.name, style: AppText.cardTitle),
          if (room.mealPlan.isNotEmpty || room.refundable != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                if (room.mealPlan.isNotEmpty)
                  MetaChip(
                    icon: Icons.restaurant_rounded,
                    label: room.mealPlan,
                  ),
                if (room.refundable != null)
                  MetaChip(
                    icon: room.refundable!
                        ? Icons.check_circle_outline_rounded
                        : Icons.block_rounded,
                    label: room.refundable! ? 'Refundable' : 'Non-refundable',
                  ),
              ],
            ),
          ],
          if (room.cancellation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              room.cancellation,
              style: AppText.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: room.price > 0
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total for your stay', style: AppText.caption),
                          Text(
                            formatPrice(room.price),
                            style: AppText.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      )
                    : Text('Priced at checkout', style: AppText.bodySm),
              ),
              const SizedBox(width: AppSpacing.md),
              PremiumButton(
                label: 'Select',
                size: PremiumButtonSize.small,
                expanded: false,
                enabled: onSelect != null,
                onPressed: onSelect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}