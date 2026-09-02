/// "My trips" — everything the traveller has booked through Honeymoon.
///
/// The four products live behind four different endpoints with four unrelated
/// response shapes, so they are normalised into [TravelBooking] and shown as
/// one list per product behind a [TabBar]. A tab whose endpoint fails shows
/// its own error and retry: one supplier being down must not blank out the
/// other three.
///
/// AUDIT FIX: cabs used to be treated as unsupported here on the belief that
/// no "list my cab bookings" endpoint exists — only a lookup by id
/// (`fetchCabBookings`). That was based on `cabApi.js` alone; the web
/// client's booking dashboard actually lists cabs via a separate endpoint,
/// `tripjack-cabs/invoices` (`fetchCabInvoices`), called directly and never
/// routed through `cabApi.js`. See MIGRATION_NOTES.md.
library;

import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../widgets/honeymoon_widgets.dart';
import 'trip_detail_page.dart';

class MyTripsPage extends StatefulWidget {
  const MyTripsPage({super.key, this.api, this.initialProduct});

  /// Supplied when opened from inside the module so the client is shared.
  final HoneymoonApi? api;

  /// Which tab to land on — set after a booking so the traveller sees the one
  /// they just made.
  final TravelProduct? initialProduct;

  @override
  State<MyTripsPage> createState() => _MyTripsPageState();
}

class _MyTripsPageState extends State<MyTripsPage>
    with SingleTickerProviderStateMixin {
  static const _products = [
    TravelProduct.flight,
    TravelProduct.hotel,
    TravelProduct.insurance,
    TravelProduct.cab,
  ];

  late final HoneymoonApi _api = widget.api ?? HoneymoonApi();
  late final bool _ownsApi = widget.api == null;

  late final TabController _tabs = TabController(
    length: _products.length,
    vsync: this,
    initialIndex: widget.initialProduct == null
        ? 0
        : _products.indexOf(widget.initialProduct!).clamp(
            0,
            _products.length - 1,
          ),
  );

  @override
  void dispose() {
    _tabs.dispose();
    if (_ownsApi) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        title: 'My trips',
        elevated: true,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: AppText.label,
          unselectedLabelStyle: AppText.label,
          tabs: [for (final p in _products) Tab(text: p.pluralLabel)],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          for (final product in _products)
            _BookingsTab(key: ValueKey(product), api: _api, product: product),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _BookingsTab extends StatefulWidget {
  const _BookingsTab({super.key, required this.api, required this.product});

  final HoneymoonApi api;
  final TravelProduct product;

  @override
  State<_BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<_BookingsTab>
    with AutomaticKeepAliveClientMixin {
  List<TravelBooking> _bookings = const [];
  bool _loading = true;
  Object? _error;

  @override
  bool get wantKeepAlive => true;

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
      final bookings = await switch (widget.product) {
        TravelProduct.flight => widget.api.fetchFlightBookings(),
        TravelProduct.hotel => widget.api.fetchHotelBookings(),
        TravelProduct.insurance => widget.api.fetchInsuranceBookings(),
        TravelProduct.cab => widget.api.fetchCabInvoices(),
      };
      if (!mounted) return;

      // Upcoming trips first, then the most recent past ones — the order a
      // traveller actually needs them in.
      bookings.sort((a, b) {
        if (a.isUpcoming != b.isUpcoming) return a.isUpcoming ? -1 : 1;
        final aDate = a.travelDate ?? a.bookedOn;
        final bDate = b.travelDate ?? b.bookedOn;
        if (aDate == null || bDate == null) return 0;
        return a.isUpcoming ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });

      setState(() {
        _bookings = bookings;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: AsyncView(
        isLoading: _loading,
        error: _error,
        isEmpty: _bookings.isEmpty,
        onRetry: _load,
        errorMessage: _error is HoneymoonApiException
            ? (_error as HoneymoonApiException).message
            : null,
        loading: Skeletons.listCards(),
        empty: _EmptyTrips(product: widget.product),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          itemCount: _bookings.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => FadeSlideIn(
            delay: AppMotion.staggerFor(i),
            child: TripCard(
              booking: _bookings[i],
              onTap: () => Navigator.push(
                context,
                AnimatedPageRoute(
                  page: TripDetailPage(
                    api: widget.api,
                    booking: _bookings[i],
                  ),
                  style: PageTransitionStyle.slideRight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// One booking, as a card. Everything a traveller scans for — where, when,
/// and is it actually confirmed — without opening it.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.booking, this.onTap});

  final TravelBooking booking;
  final VoidCallback? onTap;

  IconData get _icon => switch (booking.product) {
    TravelProduct.flight => Icons.flight_takeoff_rounded,
    TravelProduct.hotel => Icons.hotel_rounded,
    TravelProduct.cab => Icons.local_taxi_rounded,
    TravelProduct.insurance => Icons.shield_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: booking.isCancelled
                      ? AppColors.divider
                      : AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _icon,
                  size: 19,
                  color: booking.isCancelled
                      ? AppColors.textTertiary
                      : AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      booking.title,
                      style: AppText.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (booking.subtitle.isNotEmpty)
                      Text(
                        booking.subtitle,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatusPill(booking: booking),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),

          // Wrap, not Row: a long reference plus a date plus an amount cannot
          // share one line at 320 px, and wrapping beats truncating any of it.
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (booking.travelDate != null)
                _Meta(
                  icon: Icons.event_rounded,
                  label: formatTripDate(booking.travelDate),
                ),
              if (booking.travellerSummary.isNotEmpty)
                _Meta(
                  icon: Icons.person_outline_rounded,
                  label: booking.travellerSummary,
                ),
              if (booking.reference.isNotEmpty)
                _Meta(
                  icon: Icons.confirmation_number_outlined,
                  label: booking.reference,
                ),
            ],
          ),

          if (booking.amount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatPrice(booking.amount),
                    style: AppText.priceSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('View details', style: AppText.labelSm.copyWith(
                  color: AppColors.primary,
                )),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.booking});

  final TravelBooking booking;

  @override
  Widget build(BuildContext context) {
    final (label, color) = booking.isCancelled
        ? ('Cancelled', AppColors.error)
        : booking.isConfirmed
        ? ('Confirmed', AppColors.successDark)
        : (
            booking.status.isEmpty ? 'Pending' : _titleCase(booking.status),
            AppColors.warning,
          );

    return Container(
      constraints: const BoxConstraints(maxWidth: 104),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static String _titleCase(String value) {
    final cleaned = value.replaceAll('_', ' ').toLowerCase().trim();
    if (cleaned.isEmpty) return 'Pending';
    return '${cleaned[0].toUpperCase()}${cleaned.substring(1)}';
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 220),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyTrips extends StatelessWidget {
  const _EmptyTrips({required this.product});

  final TravelProduct product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.huge),
        EmptyState(
          title: 'No ${product.pluralLabel.toLowerCase()} yet',
          message: switch (product) {
            TravelProduct.flight =>
              'Flights you book for your honeymoon will appear here with '
                  'your PNR and e-ticket.',
            TravelProduct.hotel =>
              'Stays you book will appear here with your voucher and '
                  'check-in details.',
            TravelProduct.insurance =>
              'Policies you buy will appear here with your certificate.',
            TravelProduct.cab =>
              'Airport transfers you book will appear here.',
          },
          icon: switch (product) {
            TravelProduct.flight => Icons.flight_takeoff_rounded,
            TravelProduct.hotel => Icons.hotel_rounded,
            TravelProduct.cab => Icons.local_taxi_rounded,
            TravelProduct.insurance => Icons.shield_outlined,
          },
        ),
      ],
    );
  }
}

/// Cabs have no list endpoint, so rather than an empty list that reads as
/// "your booking is gone", this says what is actually true and how to find it.
// AUDIT FIX: unreachable since `tripjack-cabs/invoices` was confirmed to be
// a real, live listing endpoint (see the doc comment at the top of this
// file) — cabs now load through the same path as the other three products.
// Kept rather than deleted in case that endpoint is ever pulled again.
// class _CabLookupNotice extends StatelessWidget {
//   const _CabLookupNotice();
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       padding: const EdgeInsets.all(AppSpacing.lg),
//       children: [
//         const SizedBox(height: AppSpacing.xxxl),
//         const EmptyState(
//           title: 'Transfers are looked up by reference',
//           message:
//               'Our transfer partner does not provide a list of past bookings. '
//               'Your booking reference and voucher are in the confirmation '
//               'email sent when you booked.',
//           icon: Icons.local_taxi_rounded,
//         ),
//       ],
//     );
//   }
// }
