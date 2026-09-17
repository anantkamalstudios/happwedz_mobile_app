
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/config/api_config.dart';
import '../core/core.dart';
import 'booking_status.dart';
import 'bookings_api.dart';

/// My Bookings.
///
/// Three categories, matching the web dashboard's Booking tab — Wedding
/// Services (vendor quotation requests), Honeymoon Travel, and Shop Orders —
/// with Travel splitting into Hotels / Flights / Cabs / Insurance.
///
/// Shop orders come from the store backend, a separate service on its own
/// MongoDB. They arrive already reshaped into the same row vocabulary as
/// everything else, which is why they slot in as one more category rather
/// than needing a parallel structure.
///
/// All six lists load together with the screen, because the category tabs and
/// the travel rail count them. Panels are presentational: they filter and
/// render the rows handed to them, so switching sub-tabs is instant.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

enum _Category { services, travel, shop }

const List<({_Category key, String label})> _categories = [
  (key: _Category.services, label: 'Wedding Services'),
  (key: _Category.travel, label: 'Honeymoon Travel'),
  (key: _Category.shop, label: 'Shop Orders'),
];

const List<({BookingSource source, String label, IconData icon})> _travelTabs = [
  (source: BookingSource.hotels, label: 'Hotels', icon: Icons.hotel_rounded),
  (source: BookingSource.flights, label: 'Flights', icon: Icons.flight_rounded),
  (source: BookingSource.cabs, label: 'Cabs', icon: Icons.local_taxi_rounded),
  (
    source: BookingSource.insurance,
    label: 'Insurance',
    icon: Icons.shield_rounded,
  ),
];

const List<BookingSource> _travelSources = [
  BookingSource.hotels,
  BookingSource.flights,
  BookingSource.cabs,
  BookingSource.insurance,
];

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final BookingsController _data = BookingsController();

  /// Coming back to Travel lands where you left it, not always on Hotels.
  int _travelIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _categories.length, vsync: this)
      ..addListener(() => setState(() {}));
    _data
      ..addListener(_onData)
      ..loadAll();
  }

  void _onData() {
    if (!mounted) return;
    if (_data.signedOut) {
      _data.removeListener(_onData);
      Navigator.pushNamed(context, '/customer-login');
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _data
      ..removeListener(_onData)
      ..dispose();
    _tabs.dispose();
    super.dispose();
  }

  /// Badge for one category tab: travel sums its four lists, the others
  /// forward their single list's count. Null while anything is unresolved.
  int? _countFor(_Category category) => switch (category) {
    _Category.services => _data.slice(BookingSource.quotations).count,
    _Category.travel => _data.totalOf(_travelSources),
    _Category.shop => _data.slice(BookingSource.orders).count,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildAppBar(context),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.textOnPrimary,
                unselectedLabelColor: Colors.white70,
                indicatorColor: AppColors.textOnPrimary,
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 3,
                labelStyle: AppText.button,
                unselectedLabelStyle: AppText.bodyStrong,
                dividerColor: Colors.transparent,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (final category in _categories)
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(category.label),
                          _CategoryBadge(count: _countFor(category.key)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _WeddingServicesPanel(data: _data),
                      _TravelSection(
                        data: _data,
                        index: _travelIndex,
                        onIndexChanged: (i) => setState(() => _travelIndex = i),
                      ),
                      _ShopPanel(data: _data),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const AppBackButton(color: AppColors.textOnPrimary),
          Expanded(
            child: Text(
              'My Bookings',
              textAlign: TextAlign.center,
              style: AppText.pageTitle.copyWith(color: AppColors.textOnPrimary),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

/// Count chip on a category tab. Renders nothing until the list resolves, so
/// a still-loading or failed category never claims a number.
class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    if (count == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(left: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppText.caption.copyWith(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// =============================================================
// TRAVEL SECTION — four sub-tabs over the shared card
// =============================================================

class _TravelSection extends StatelessWidget {
  const _TravelSection({
    required this.data,
    required this.index,
    required this.onIndexChanged,
  });

  final BookingsController data;
  final int index;
  final ValueChanged<int> onIndexChanged;

  @override
  Widget build(BuildContext context) {
    final active = _travelTabs[index];

    return Column(
      children: [
        // The web uses a left rail here; on a phone that width is better spent
        // on the cards, so the same four choices run as a scrolling chip row.
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            itemCount: _travelTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, i) {
              final tab = _travelTabs[i];
              final selected = i == index;
              final count = data.slice(tab.source).count;

              return Pressable(
                onTap: () => onIndexChanged(i),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.blush,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tab.icon,
                        size: 15,
                        color: selected
                            ? AppColors.textOnPrimary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        count == null ? tab.label : '${tab.label} ($count)',
                        style: AppText.caption.copyWith(
                          color: selected
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: switch (active.source) {
            BookingSource.hotels => _HotelPanel(data: data),
            BookingSource.flights => _FlightPanel(data: data),
            BookingSource.cabs => _CabPanel(data: data),
            _ => _InsurancePanel(data: data),
          },
        ),
      ],
    );
  }
}

// =============================================================
// PANEL CHROME — status pills, and the shimmer → error → empty → list body
// =============================================================

/// One panel's frame: the status filter row, then whatever state the list is
/// in. Every panel is this widget plus a card builder.
class _Panel extends StatefulWidget {
  const _Panel({
    required this.data,
    required this.source,
    required this.filterSet,
    required this.statusOf,
    required this.cardBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final BookingsController data;
  final BookingSource source;
  final FilterSet filterSet;
  final BookingStatus Function(dynamic) statusOf;
  final Widget Function(dynamic row, BookingStatus status) cardBuilder;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;

  @override
  State<_Panel> createState() => _PanelState();
}

class _PanelState extends State<_Panel> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final slice = widget.data.slice(widget.source);
    Future<void> retry() => widget.data.load(widget.source);

    if (slice.loading) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Skeletons.listCards(count: 3, height: 220),
      );
    }

    if (slice.error != null) {
      return ErrorState(error: slice.error, onRetry: retry);
    }

    final rows = slice.rows;
    final filters = buildStatusFilters(
      widget.filterSet,
      rows,
      (row) => widget.statusOf(row).key,
    );
    final visible = _filter == 'all'
        ? rows
        : rows.where((r) => widget.statusOf(r).key == _filter).toList();

    return Column(
      children: [
        if (rows.isNotEmpty)
          _StatusPills(
            filters: filters,
            active: _filter,
            onChanged: (key) => setState(() => _filter = key),
          ),
        Expanded(
          child: visible.isEmpty
              ? RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: retry,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.06,
                      ),
                      EmptyState(
                        icon: widget.emptyIcon,
                        title: rows.isEmpty
                            ? widget.emptyTitle
                            : 'Nothing to show',
                        message: rows.isEmpty
                            ? widget.emptyMessage
                            : 'No ${_filter.toLowerCase()} bookings at the moment.',
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: retry,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                    ),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final row = visible[index];
                      return FadeSlideIn(
                        delay: AppMotion.staggerFor(index),
                        child: widget.cardBuilder(row, widget.statusOf(row)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

/// Horizontal status filter row. Pills stay put at zero so the row does not
/// reflow as data loads.
class _StatusPills extends StatelessWidget {
  const _StatusPills({
    required this.filters,
    required this.active,
    required this.onChanged,
  });

  final List<StatusFilter> filters;
  final String active;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final selected = filter.key == active;

          return Pressable(
            onTap: () => onChanged(filter.key),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.divider,
                ),
              ),
              child: Text(
                '${filter.label} (${filter.count})',
                style: AppText.caption.copyWith(
                  color: selected
                      ? AppColors.textOnPrimary
                      : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================
// TRAVEL CARD — one shell for hotels, flights, cabs and insurance
// =============================================================

/// The travel equivalent of [BookingCard]: type chip and status pill on top,
/// title, detail rows, price. Only `rows` differs per booking type, which is
/// what lets the four travel lists scan as one.
class _TravelCard extends StatelessWidget {
  const _TravelCard({
    required this.typeIcon,
    required this.typeLabel,
    required this.status,
    required this.title,
    this.subtitle,
    this.rows = const [],
    this.price,
  });

  final IconData typeIcon;
  final String typeLabel;
  final BookingStatus status;
  final String title;
  final String? subtitle;
  final List<({String label, String value})> rows;
  final String? price;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(typeIcon, size: 14, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                typeLabel.toUpperCase(),
                style: AppText.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              _StatusPill(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppText.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              subtitle!,
              style: AppText.bodySm.copyWith(color: AppColors.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (rows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.sm),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 92,
                      child: Text(
                        row.label,
                        style: AppText.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.value,
                        style: AppText.bodySm.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (price != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              price!,
              style: AppText.sectionTitle.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final BookingStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.tone.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.tone.icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            status.label,
            style: AppText.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================
// FORMAT HELPERS — ported from the web's panels/format.js
// =============================================================

/// `₹1,24,600.00` — falls back to a dash rather than printing `₹NaN`.
String _money(Object? value, [Object? currency]) {
  final amount = double.tryParse(value?.toString() ?? '');
  if (amount == null) return '—';
  final code = currency?.toString().isNotEmpty == true
      ? currency.toString()
      : 'INR';
  try {
    return NumberFormat.simpleCurrency(locale: 'en_IN', name: code)
        .format(amount);
  } catch (_) {
    return '₹ ${NumberFormat('#,##,##0.00', 'en_IN').format(amount)}';
  }
}

String _day(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : DateFormat('d MMM yyyy').format(parsed);
}

String _dayTime(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return '—';
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : DateFormat('d MMM yyyy, h:mm a').format(parsed);
}

/// Whole nights between two dates, or null when either is unusable.
int? _nightsBetween(Object? from, Object? to) {
  final start = DateTime.tryParse(from?.toString() ?? '');
  final end = DateTime.tryParse(to?.toString() ?? '');
  if (start == null || end == null) return null;
  final nights = end.difference(start).inDays;
  return nights > 0 ? nights : null;
}

String _text(Object? value, [String fallback = '—']) {
  final raw = value?.toString().trim();
  return raw == null || raw.isEmpty ? fallback : raw;
}

// =============================================================
// PANELS
// =============================================================

class _WeddingServicesPanel extends StatelessWidget {
  const _WeddingServicesPanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.quotations,
      filterSet: FilterSet.quotation,
      statusOf: (row) => normalizeStatus(row['status'], StatusSource.quotation),
      emptyIcon: Icons.event_note_outlined,
      emptyTitle: 'No service bookings found',
      emptyMessage:
          "You haven't requested pricing from any vendor yet. Browse vendors "
          'to send your first request.',
      cardBuilder: (row, status) => BookingCard(
        imageUrl:
            row['vendor']?['cover_photo'] ??
            '${ApiConfig.baseUrl}/images/no-image.jpg',
        vendorName: row['vendor']?['businessName'] ?? 'Vendor',
        serviceName: row['vendor']?['category'] ?? 'Service',
        price: '${row['quote']?['price'] ?? 'N/A'}',
        bookingDate: row['eventDate'] ?? '',
        address: row['vendor']?['address'] ?? 'No address provided',
        rating: double.tryParse(row['vendor']?['rating'].toString() ?? '0') ?? 0,
        reviewCount: row['vendor']?['reviewCount'] ?? 0,
      ),
    );
  }
}

class _HotelPanel extends StatelessWidget {
  const _HotelPanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.hotels,
      filterSet: FilterSet.travel,
      statusOf: (row) => normalizeStatus(row['status'], StatusSource.hotel),
      emptyIcon: Icons.hotel_outlined,
      emptyTitle: 'No hotel bookings found',
      emptyMessage: "You haven't booked a hotel through HappyWedz yet.",
      cardBuilder: (row, status) {
        final nights = _nightsBetween(row['checkIn'], row['checkOut']);
        return _TravelCard(
          typeIcon: Icons.hotel_rounded,
          typeLabel: 'Hotel',
          status: status,
          title: _text(row['hotelName'], 'Booked Hotel'),
          subtitle: 'Booking ID ${_text(row['bookingId'])}',
          rows: [
            (
              label: 'Stay',
              value:
                  '${_day(row['checkIn'])} – ${_day(row['checkOut'])}'
                  '${nights == null ? '' : ' · $nights night${nights > 1 ? 's' : ''}'}',
            ),
            (label: 'Payment', value: _text(row['paymentStatus'], 'PENDING')),
            (label: 'Booked', value: _day(row['createdAt'])),
          ],
          price: _money(row['amount'], row['currency']),
        );
      },
    );
  }
}

class _FlightPanel extends StatelessWidget {
  const _FlightPanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.flights,
      filterSet: FilterSet.travel,
      statusOf: (row) =>
          normalizeStatus(row['booking_status'], StatusSource.flight),
      emptyIcon: Icons.flight_outlined,
      emptyTitle: 'No flight bookings found',
      emptyMessage: "You haven't booked a flight through HappyWedz yet.",
      cardBuilder: (row, status) {
        final from = _text(row['from_iata'], '');
        final to = _text(row['to_iata'], '');
        final route = from.isEmpty || to.isEmpty ? 'Flight Booking' : '$from → $to';
        return _TravelCard(
          typeIcon: Icons.flight_rounded,
          typeLabel: 'Flight',
          status: status,
          title: route,
          subtitle: [
            _text(row['airline'], ''),
            _text(row['flight_no'], ''),
          ].where((s) => s.isNotEmpty).join(' · '),
          rows: [
            (label: 'Depart', value: _dayTime(row['departure'])),
            (label: 'Arrive', value: _dayTime(row['arrival'])),
            (
              label: 'PNR / Ref',
              value: _text(row['pnr'] ?? row['order_id']),
            ),
            (label: 'Cabin', value: _text(row['cabin_class'])),
            (label: 'Booked', value: _day(row['booked_at'] ?? row['createdAt'])),
          ],
          price: _money(row['price']),
        );
      },
    );
  }
}

class _CabPanel extends StatelessWidget {
  const _CabPanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.cabs,
      filterSet: FilterSet.travel,
      statusOf: (row) => normalizeStatus(row['bookingStatus'], StatusSource.cab),
      emptyIcon: Icons.local_taxi_outlined,
      emptyTitle: 'No cab bookings found',
      emptyMessage: "You haven't booked a cab through HappyWedz yet.",
      cardBuilder: (row, status) => _TravelCard(
        typeIcon: Icons.local_taxi_rounded,
        typeLabel: 'Cab',
        status: status,
        title: _text(row['route'], 'Cab Booking #${_text(row['id'], '')}'),
        subtitle: row['tripjackBookingId'] == null
            ? null
            : 'Ref ${row['tripjackBookingId']}',
        rows: [
          (label: 'From', value: _text(row['pickupLocation'])),
          (label: 'To', value: _text(row['dropoffLocation'])),
          (label: 'Pickup', value: _dayTime(row['pickupAt'])),
          (label: 'Passenger', value: _text(row['passengerName'])),
          (label: 'Booked', value: _day(row['createdAt'])),
        ],
        price: _money(row['amount'], row['currency']),
      ),
    );
  }
}

class _InsurancePanel extends StatelessWidget {
  const _InsurancePanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.insurance,
      filterSet: FilterSet.travel,
      statusOf: (row) =>
          normalizeStatus(row['booking_status'], StatusSource.insurance),
      emptyIcon: Icons.shield_outlined,
      emptyTitle: 'No insurance bookings found',
      emptyMessage: "You haven't bought travel insurance through HappyWedz yet.",
      cardBuilder: (row, status) {
        final travellers = row['traveller_count'];
        return _TravelCard(
          typeIcon: Icons.shield_rounded,
          typeLabel: 'Insurance',
          status: status,
          title: _text(row['plan_label'], 'Insurance Plan'),
          subtitle: _text(row['insurer'], ''),
          rows: [
            (label: 'Cover', value: _money(row['coverage_amount'])),
            (label: 'Region', value: _text(row['region_name'])),
            (
              label: 'Valid',
              value: '${_day(row['start_date'])} – ${_day(row['end_date'])}',
            ),
            (
              label: 'Travellers',
              value: travellers == null ? '—' : '$travellers',
            ),
            (label: 'Policy', value: _text(row['tripjack_booking_id'])),
          ],
          price: _money(row['amount'], row['currency']),
        );
      },
    );
  }
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({required this.data});

  final BookingsController data;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      data: data,
      source: BookingSource.orders,
      filterSet: FilterSet.shop,
      statusOf: (row) => normalizeStatus(row['status'], StatusSource.shop),
      emptyIcon: Icons.shopping_bag_outlined,
      emptyTitle: 'No shop orders found',
      emptyMessage:
          "You haven't ordered anything from the HappyWedz store yet.",
      cardBuilder: (row, status) => _ShopOrderCard(order: row),
    );
  }
}

// =============================================================
// SHOP ORDER STATUS
// =============================================================

/// The store's `Order.status` enum is exactly Pending / Processing /
/// Delivered / Cancel (not "Cancelled") — the other spellings are matched
/// too so a later widening of that enum still lands somewhere sensible.
class _ShopStatus {
  const _ShopStatus(this.label, this.color);
  final String label;
  final Color color;
}

_ShopStatus _shopStatusFor(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase() ?? '';
  switch (value) {
    case 'PENDING':
      return const _ShopStatus('Pending', AppColors.warning);
    case 'PROCESSING':
      return const _ShopStatus('Processing', AppColors.info);
    case 'DELIVERED':
      return const _ShopStatus('Delivered', AppColors.success);
    case 'CANCEL':
    case 'CANCELLED':
    case 'CANCELED':
      return const _ShopStatus('Cancelled', AppColors.error);
    default:
      return _ShopStatus(
        value.isEmpty ? 'Unknown' : value,
        AppColors.textTertiary,
      );
  }
}

// =============================================================
// SHOP ORDER CARD
// =============================================================

class _ShopOrderCard extends StatefulWidget {
  const _ShopOrderCard({required this.order});

  final dynamic order;

  @override
  State<_ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends State<_ShopOrderCard> {
  static const String _storeUrl = 'https://store.happywedz.com';

  bool _expanded = false;

  String get _formattedPlacedAt {
    final placedAt = widget.order["placedAt"]?.toString();
    if (placedAt == null || placedAt.isEmpty) return 'Date not set';
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(placedAt));
    } catch (_) {
      return placedAt;
    }
  }

  /// "Rose Gold Garland +2 more" — names the thing the person actually
  /// recognises, then says how much else is in the box.
  String _itemSummary(List<dynamic> items) {
    if (items.isEmpty) return 'No items';
    final first = items.first;
    final rest = items.length - 1;
    final title = first["title"]?.toString() ?? 'Item';
    return rest > 0 ? '$title +$rest more' : title;
  }

  Future<void> _openStore() async {
    final uri = Uri.parse(_storeUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open store: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = (order["items"] as List<dynamic>?) ?? [];
    final itemCount = order["itemCount"] ?? items.length;
    final status = _shopStatusFor(order["status"]);
    final discount = num.tryParse('${order["discount"] ?? 0}') ?? 0;
    final firstImage = items.isNotEmpty
        ? items.first["image"]?.toString()
        : null;

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: AppRadii.rSm,
                child: firstImage != null && firstImage.isNotEmpty
                    ? NetworkImageWidget(
                        url: firstImage,
                        height: 64,
                        width: 64,
                      )
                    : Container(
                        height: 64,
                        width: 64,
                        color: AppColors.pinkSurface,
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: AppColors.primary,
                        ),
                      ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order["invoice"] != null
                          ? 'Order #${order["invoice"]}'
                          : 'Shop Order',
                      style: AppText.sectionTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      _itemSummary(items),
                      style: AppText.cardSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: status.color.withValues(alpha: 0.12),
                  borderRadius: AppRadii.rPill,
                  border: Border.all(color: status.color.withValues(alpha: 0.35)),
                ),
                child: Text(
                  status.label,
                  style: AppText.caption.copyWith(
                    color: status.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            text: '$itemCount item${itemCount == 1 ? "" : "s"}',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.payments_outlined,
            text: order["paymentMethod"]?.toString() ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.local_shipping_outlined,
            text: order["shipTo"]?.toString() ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(icon: Icons.calendar_today_rounded, text: _formattedPlacedAt),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pinkSurface,
                  borderRadius: AppRadii.rSm,
                ),
                child: Text(
                  '₹${order["total"] ?? "—"}',
                  style: AppText.price,
                ),
              ),
              if (discount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '₹$discount off',
                  style: AppText.caption.copyWith(color: AppColors.successDark),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (items.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  icon: Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                  ),
                  label: Text(_expanded ? 'Hide Items' : 'View Items'),
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openStore,
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Visit Store'),
              ),
            ],
          ),
          if (_expanded)
            Column(
              children: items.map((item) {
                final title = item["title"]?.toString() ?? 'Item';
                final quantity = item["quantity"] ?? 1;
                final price = item["price"] ?? 0;
                final lineTotal = item["lineTotal"] ?? 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$title  ·  $quantity × ₹$price',
                          style: AppText.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('₹$lineTotal', style: AppText.bodyStrong),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// =============================================================
// BOOKING CARD
// =============================================================

class BookingCard extends StatelessWidget {
  final String imageUrl;
  final String vendorName;
  final String serviceName;

  /// Bare amount — the ₹ symbol is added at render time.
  final String price;
  final String bookingDate;
  final String address;
  final double rating;
  final int reviewCount;

  const BookingCard({
    super.key,
    required this.imageUrl,
    required this.vendorName,
    required this.serviceName,
    required this.price,
    required this.bookingDate,
    required this.address,
    required this.rating,
    required this.reviewCount,
  });

  /// Formats the ISO event date for display, falling back to the raw string.
  String get _formattedDate {
    if (bookingDate.isEmpty) return 'Date not set';
    try {
      return DateFormat('EEE, d MMM yyyy').format(DateTime.parse(bookingDate));
    } catch (_) {
      return bookingDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image with rating overlay
          Stack(
            children: [
              NetworkImageWidget(
                url: imageUrl,
                height: 190,
                width: double.infinity,
                memCacheWidth: 900,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadii.lg),
                ),
                scrim: true,
              ),
              if (rating > 0)
                Positioned(
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: AppRadii.rPill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${rating.toStringAsFixed(1)} ($reviewCount)',
                          style: AppText.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serviceName,
                  style: AppText.sectionTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  vendorName,
                  style: AppText.cardSubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.md),

                // Price chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.pinkSurface,
                    borderRadius: AppRadii.rSm,
                  ),
                  child: Text('₹$price', style: AppText.price),
                ),

                const SizedBox(height: AppSpacing.md),

                _InfoRow(
                  icon: Icons.calendar_today_rounded,
                  text: _formattedDate,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoRow(icon: Icons.location_on_rounded, text: address),

                const SizedBox(height: AppSpacing.lg),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: AppRadii.rMd,
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: AppColors.successDark,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Service Booked',
                        style: AppText.button.copyWith(
                          color: AppColors.successDark,
                        ),
                      ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textTertiary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: AppText.body)),
      ],
    );
  }
}