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
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/cab_models.dart';
import '../../models/flight_models.dart';
import '../../insurance_config.dart';
import '../../models/insurance_models.dart';
import '../../models/honeymoon_models.dart';
// import '../honeymoon_home_page.dart' show openInsuranceSearch;
import '../honeymoon_home_page.dart'
    show openHoneymoonService, openInsuranceSearch;
import '../widgets/flight_widgets.dart';
import '../widgets/honeymoon_widgets.dart';
import 'cab_booking_detail_page.dart';
import 'flight_booking_detail_page.dart';
import 'hotel_booking_detail_page.dart';
import 'insurance_booking_detail_page.dart';
import 'upcoming_flight_bookings.dart';
// No longer opened from here — see [_openDetail].
// import 'trip_detail_page.dart';

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
        : _products
              .indexOf(widget.initialProduct!)
              .clamp(0, _products.length - 1),
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

  /// Hotels only: the web's status filter on `hotels/all-bookings?status=`.
  static const _hotelStatuses = <(String, String)>[
    ('', 'All'),
    ('PENDING', 'Pending'),
    ('SUCCESS', 'Success'),
    ('ON_HOLD', 'On hold'),
    ('FAILED', 'Failed'),
    ('CANCELLED', 'Cancelled'),
    ('PAYMENT_PENDING', 'Payment pending'),
    ('PAYMENT_FAILED', 'Payment failed'),
    ('BOOK_FAILED_AFTER_PAYMENT', 'Failed after payment'),
  ];
  String _hotelStatus = '';

  /// Flights only: the web's status pills (`FlightPanel.jsx`), filtered
  /// client-side over the normalised status. Null is "All".
  FlightStatusKey? _flightFilter;

  /// Insurance only: the web's status pills (`InsurancePanel.jsx`). Null is
  /// "All".
  InsuranceStatusKey? _insuranceFilter;

  /// Cabs only: the web's status pills (`CabPanel.jsx`). Null is "All".
  CabStatusKey? _cabFilter;

  /// Order id of the row whose invoice is downloading.
  String _downloading = '';

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
        TravelProduct.hotel => widget.api.fetchHotelBookings(
          status: _hotelStatus,
        ),
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

    if (widget.product == TravelProduct.flight) {
      return Column(
        children: [
          _flightFilterBar(),
          Expanded(child: _buildList()),
        ],
      );
    }

    if (widget.product == TravelProduct.insurance) {
      return Column(
        children: [
          _insuranceFilterBar(),
          Expanded(child: _buildList()),
        ],
      );
    }

    if (widget.product == TravelProduct.cab) {
      return Column(
        children: [
          _cabFilterBar(),
          Expanded(child: _buildList()),
        ],
      );
    }

    if (widget.product == TravelProduct.hotel) {
      return Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                0,
              ),
              itemCount: _hotelStatuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, i) {
                final (value, label) = _hotelStatuses[i];
                return ChoiceChip(
                  label: Text(label),
                  selected: _hotelStatus == value,
                  selectedColor: AppColors.pinkSurface,
                  onSelected: (_) {
                    if (_hotelStatus == value) return;
                    setState(() => _hotelStatus = value);
                    _load();
                  },
                );
              },
            ),
          ),
          Expanded(child: _buildList()),
        ],
      );
    }
    return _buildList();
  }

  /// The rows on screen: every booking, or — on the flight tab — those in the
  /// chosen status.
  List<TravelBooking> get _visible {
    if (widget.product == TravelProduct.cab) {
      final filter = _cabFilter;
      if (filter == null) return _bookings;
      return [
        for (final b in _bookings)
          if (cabStatusOf(b.status).key == filter) b,
      ];
    }
    if (widget.product == TravelProduct.insurance) {
      final filter = _insuranceFilter;
      if (filter == null) return _bookings;
      return [
        for (final b in _bookings)
          if (insuranceStatusOf(b.status).key == filter) b,
      ];
    }
    final filter = _flightFilter;
    if (widget.product != TravelProduct.flight || filter == null) {
      return _bookings;
    }
    return [
      for (final b in _bookings)
        if (flightStatusOf(b.status).key == filter) b,
    ];
  }

  /// All · Confirmed · Pending · On Hold · Cancelled, always shown with their
  /// counts, plus any other state the rows actually carry — and the web's
  /// "Share with customer" for the upcoming ones.
  Widget _flightFilterBar() {
    final counts = <FlightStatusKey, int>{};
    for (final b in _bookings) {
      final key = flightStatusOf(b.status).key;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final keys = [
      ...kFlightStatusFilters,
      ...counts.keys.where((k) => !kFlightStatusFilters.contains(k)),
    ];
    String label(FlightStatusKey k) => switch (k) {
      FlightStatusKey.confirmed => 'Confirmed',
      FlightStatusKey.hold => 'On Hold',
      FlightStatusKey.pending => 'Pending',
      FlightStatusKey.cancelled => 'Cancelled',
      FlightStatusKey.failed => 'Failed',
      FlightStatusKey.unknown => 'Other',
    };
    final upcoming = _upcomingFlights;

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        children: [
          ChoiceChip(
            label: Text('All (${_bookings.length})'),
            selected: _flightFilter == null,
            selectedColor: AppColors.pinkSurface,
            onSelected: (_) => setState(() => _flightFilter = null),
          ),
          for (final k in keys) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text('${label(k)} (${counts[k] ?? 0})'),
              selected: _flightFilter == k,
              selectedColor: AppColors.pinkSurface,
              onSelected: (_) => setState(() => _flightFilter = k),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.sm),
            ActionChip(
              avatar: const Icon(
                Icons.share_rounded,
                size: 16,
                color: AppColors.successDark,
              ),
              label: const Text('Share with customer'),
              onPressed: () => _shareUpcoming(upcoming),
            ),
          ],
        ],
      ),
    );
  }

  /// All · Confirmed · Pending · Cancelled with counts, plus any other state
  /// the rows carry — `buildStatusFilters("travel", …)` for insurance.
  Widget _insuranceFilterBar() {
    final counts = <InsuranceStatusKey, int>{};
    for (final b in _bookings) {
      final key = insuranceStatusOf(b.status).key;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final keys = [
      ...kInsuranceStatusFilters,
      ...counts.keys.where((k) => !kInsuranceStatusFilters.contains(k)),
    ];
    String label(InsuranceStatusKey k) => switch (k) {
      InsuranceStatusKey.confirmed => 'Confirmed',
      InsuranceStatusKey.pending => 'Pending',
      InsuranceStatusKey.cancelled => 'Cancelled',
      InsuranceStatusKey.failed => 'Failed',
      InsuranceStatusKey.unknown => 'Other',
    };
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        children: [
          ChoiceChip(
            label: Text('All (${_bookings.length})'),
            selected: _insuranceFilter == null,
            selectedColor: AppColors.pinkSurface,
            onSelected: (_) => setState(() => _insuranceFilter = null),
          ),
          for (final k in keys) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text('${label(k)} (${counts[k] ?? 0})'),
              selected: _insuranceFilter == k,
              selectedColor: AppColors.pinkSurface,
              onSelected: (_) => setState(() => _insuranceFilter = k),
            ),
          ],
        ],
      ),
    );
  }

  /// All · Confirmed · Pending · Cancelled with counts, plus any other state
  /// the rows carry — `buildStatusFilters("travel", …)` for cabs.
  Widget _cabFilterBar() {
    final counts = <CabStatusKey, int>{};
    for (final b in _bookings) {
      final key = cabStatusOf(b.status).key;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    final keys = [
      ...kCabStatusFilters,
      ...counts.keys.where((k) => !kCabStatusFilters.contains(k)),
    ];
    String label(CabStatusKey k) => switch (k) {
      CabStatusKey.confirmed => 'Confirmed',
      CabStatusKey.pending => 'Pending',
      CabStatusKey.cancelled => 'Cancelled',
      CabStatusKey.failed => 'Failed',
      CabStatusKey.unknown => 'Other',
    };
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          0,
        ),
        children: [
          ChoiceChip(
            label: Text('All (${_bookings.length})'),
            selected: _cabFilter == null,
            selectedColor: AppColors.pinkSurface,
            onSelected: (_) => setState(() => _cabFilter = null),
          ),
          for (final k in keys) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              label: Text('${label(k)} (${counts[k] ?? 0})'),
              selected: _cabFilter == k,
              selectedColor: AppColors.pinkSurface,
              onSelected: (_) => setState(() => _cabFilter = k),
            ),
          ],
        ],
      ),
    );
  }

  /// The web card's rows and actions for a cab (`CabPanel.jsx`): Ref, From,
  /// To, Pickup, Passenger, Booked; View Details and the Invoice PDF.
  Widget _cabActions(TravelBooking b) {
    final raw = b.raw;
    final route = asString(readKey(raw, 'route'));
    final parts = route.split(' → ');
    final from = parts.isNotEmpty && parts.first.isNotEmpty ? parts.first : '—';
    final to = parts.length > 1 && parts[1].isNotEmpty ? parts[1] : '—';
    final invoiceId = asString(readKey(raw, 'id'));
    final orderId = asString(readKey(raw, 'orderId'));
    final booked = b.bookedOn;
    final pickup = b.travelDate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (b.reference.isNotEmpty)
          Text('Ref ${b.reference}', style: AppText.caption),
        Text('From: $from', style: AppText.caption),
        Text('To: $to', style: AppText.caption),
        Text(
          'Pickup: ${pickup == null ? '—' : formatCabDateTime(pickup)}',
          style: AppText.caption,
        ),
        Text(
          'Passenger: ${b.travellerSummary.isEmpty ? '—' : b.travellerSummary}',
          style: AppText.caption,
        ),
        if (booked != null)
          Text('Booked ${formatCabDateTime(booked)}', style: AppText.caption),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            PremiumButton.text(
              label: 'View Details',
              size: PremiumButtonSize.small,
              onPressed: invoiceId.isEmpty ? null : () => _openDetail(b),
            ),
            if (orderId.isNotEmpty)
              PremiumButton.text(
                label: _downloading == orderId ? 'Downloading…' : 'Invoice',
                size: PremiumButtonSize.small,
                onPressed: _downloading.isEmpty
                    ? () => _downloadCabInvoice(orderId, invoiceId)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadCabInvoice(String orderId, String invoiceNumber) async {
    setState(() => _downloading = orderId);
    try {
      final path = await widget.api.downloadCabInvoice(
        orderId,
        invoiceNumber: invoiceNumber,
      );
      await OpenFilex.open(path);
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Failed to download invoice');
    } finally {
      if (mounted) setState(() => _downloading = '');
    }
  }

  /// The web card's rows and actions for a policy: Valid dates, Paid on,
  /// View Policy, and the Policy PDF once confirmed.
  Widget _insuranceActions(TravelBooking b) {
    final start = b.travelDate;
    final end = DateTime.tryParse(asString(readKey(b.raw, 'end_date')));
    final paid = DateTime.tryParse(asString(readKey(b.raw, 'paid_at')));
    final confirmed =
        insuranceStatusOf(b.status).key == InsuranceStatusKey.confirmed;
    final insurer = asString(readKey(b.raw, 'insurer'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The web card's subtitle and "Policy" row.
        if (insurer.isNotEmpty)
          Text(insurerLabelFor(insurer), style: AppText.caption),
        Text(
          'Policy: ${b.reference.isEmpty ? '—' : b.reference}',
          style: AppText.caption,
        ),
        if (start != null || end != null)
          Text(
            'Valid: ${start == null ? '—' : formatTripDate(start)} – '
            '${end == null ? '—' : formatTripDate(end)}',
            style: AppText.caption,
          ),
        if (paid != null)
          Text('Paid ${formatTripDate(paid)}', style: AppText.caption),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            PremiumButton.text(
              label: 'View Policy',
              size: PremiumButtonSize.small,
              onPressed: b.reference.isEmpty ? null : () => _openDetail(b),
            ),
            if (confirmed && b.reference.isNotEmpty)
              PremiumButton.text(
                label: _downloading == b.reference
                    ? 'Downloading…'
                    : 'Policy PDF',
                size: PremiumButtonSize.small,
                onPressed: _downloading.isEmpty
                    ? () => _downloadPolicy(b)
                    : null,
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadPolicy(TravelBooking b) async {
    setState(() => _downloading = b.reference);
    try {
      final path = await widget.api.downloadInsurancePolicy(b.reference);
      await OpenFilex.open(path);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(
          context,
          'Could not download that policy. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = '');
    }
  }

  /// Travel date today or later, or none yet — "don't hide" — soonest first.
  List<TravelBooking> get _upcomingFlights {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final list = [
      for (final b in _bookings)
        if (b.travelDate == null || !b.travelDate!.isBefore(today)) b,
    ];
    list.sort((a, b) {
      if (a.travelDate == null && b.travelDate == null) return 0;
      if (a.travelDate == null) return 1;
      if (b.travelDate == null) return -1;
      return a.travelDate!.compareTo(b.travelDate!);
    });
    return list;
  }

  /// "Your upcoming flight bookings:" with up to ten lines, to WhatsApp —
  /// `UpcomingBookings.jsx` `shareWithCustomer`.
  Future<void> _shareUpcoming(List<TravelBooking> upcoming) =>
      shareUpcomingFlightBookings(context, upcoming);

  // Previous inline copy, now [shareUpcomingFlightBookings]:
  // Future<void> _shareUpcoming(List<TravelBooking> upcoming) async {
  //   final lines = upcoming
  //       .take(10)
  //       .map(
  //         (b) =>
  //             '• ${firstNonEmpty([readKey(b.raw, 'passenger_name')], fallback: 'Guest')} '
  //             '— ${b.reference} (${b.travelDate == null ? '—' : formatTripDate(b.travelDate)})',
  //       )
  //       .join('\n');
  //   final text = Uri.encodeComponent('Your upcoming flight bookings:\n$lines');
  //   final ok = await launchUrl(
  //     Uri.parse('https://wa.me/?text=$text'),
  //     mode: LaunchMode.externalApplication,
  //   );
  //   if (!ok && mounted) {
  //     AppSnackbar.error(context, 'WhatsApp is not available on this device.');
  //   }
  // }

  void _openDetail(TravelBooking booking) {
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: switch (booking.product) {
          // Hotels and flights have their own status-gated detail screens,
          // as on the web (`HotelBookingDetailsPage`, `BookingDetailPage`).
          TravelProduct.hotel => HotelBookingDetailPage(
            api: widget.api,
            booking: booking,
          ),
          TravelProduct.flight => FlightBookingDetailPage(
            api: widget.api,
            booking: booking,
          ),
          // The web's insurance details page, by the policy's booking id.
          TravelProduct.insurance => InsuranceBookingDetailPage(
            api: widget.api,
            bookingId: booking.reference,
          ),
          // The web's cab details page, by the invoice row's own id.
          TravelProduct.cab => CabBookingDetailPage(
            api: widget.api,
            invoiceId: asString(readKey(booking.raw, 'id')),
            orderId: asString(readKey(booking.raw, 'orderId')),
          ),
          // Every product now opens its own page (as each has its own on the
          // web), so the shared fallback is no longer reached:
          // _ => TripDetailPage(api: widget.api, booking: booking),
        },
        style: PageTransitionStyle.slideRight,
      ),
    ).then((_) {
      // A payment, release or cancellation there changes this list.
      if (mounted &&
          (booking.product == TravelProduct.flight ||
              booking.product == TravelProduct.insurance)) {
        _load();
      }
    });
  }

  Future<void> _downloadInvoice(TravelBooking b) async {
    setState(() => _downloading = b.reference);
    try {
      final path = await widget.api.downloadFlightInvoice(
        asString(readKey(b.raw, 'razorpay_order_id')),
        invoiceNumber: b.reference,
      );
      await OpenFilex.open(path);
    } on HoneymoonApiException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not download the invoice.');
      }
    } finally {
      if (mounted) setState(() => _downloading = '');
    }
  }

  /// The web card's actions for a flight: Pay & Confirm on a held fare,
  /// View Summary, the invoice when a payment exists, and Book Return.
  Widget _flightActions(TravelBooking b) {
    final status = flightStatusOf(b.status);
    final hasInvoice = asString(readKey(b.raw, 'razorpay_order_id')).isNotEmpty;
    final canReturn =
        asString(readKey(b.raw, 'from_iata')).isNotEmpty &&
        asString(readKey(b.raw, 'to_iata')).isNotEmpty &&
        status.key == FlightStatusKey.confirmed;

    return Wrap(
      spacing: AppSpacing.xs,
      children: [
        if (status.key == FlightStatusKey.hold)
          PremiumButton(
            label: 'Pay & Confirm',
            size: PremiumButtonSize.small,
            expanded: false,
            onPressed: () => _openDetail(b),
          ),
        PremiumButton.text(
          label: 'View Summary',
          size: PremiumButtonSize.small,
          onPressed: () => showFlightPassengerSummary(
            context,
            widget.api,
            b,
            onViewFull: () => _openDetail(b),
          ),
        ),
        if (hasInvoice)
          PremiumButton.text(
            label: _downloading == b.reference ? 'Downloading…' : 'Invoice',
            size: PremiumButtonSize.small,
            onPressed: _downloading.isEmpty ? () => _downloadInvoice(b) : null,
          ),
        if (canReturn)
          PremiumButton.text(
            label: '↩ Book Return',
            size: PremiumButtonSize.small,
            onPressed: () => openFlightReturnSearch(context, widget.api, b),
          ),
      ],
    );
  }

  Widget _buildList() {
    final visible = _visible;
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: AsyncView(
        isLoading: _loading,
        error: _error,
        isEmpty: visible.isEmpty,
        onRetry: _load,
        errorMessage: _error is HoneymoonApiException
            ? (_error as HoneymoonApiException).message
            : null,
        loading: Skeletons.listCards(),
        // empty: _EmptyTrips(product: widget.product),
        empty: _EmptyTrips(
          product: widget.product,
          insuranceFilter: widget.product == TravelProduct.insurance
              ? _insuranceFilter
              : null,
          cabFilter: widget.product == TravelProduct.cab ? _cabFilter : null,
        ),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, i) => FadeSlideIn(
            delay: AppMotion.staggerFor(i),
            child: TripCard(
              booking: visible[i],
              onTap: () => _openDetail(visible[i]),
              footer: switch (widget.product) {
                TravelProduct.flight => _flightActions(visible[i]),
                TravelProduct.insurance => _insuranceActions(visible[i]),
                TravelProduct.cab => _cabActions(visible[i]),
                _ => null,
              },
            ),
          ),
        ),
      ),
    );
  }
}

// Previous list item, kept for reference:
//           itemBuilder: (context, i) => FadeSlideIn(
//             delay: AppMotion.staggerFor(i),
//             child: TripCard(
//               booking: _bookings[i],
//               onTap: () => Navigator.push(
//                 context,
//                 AnimatedPageRoute(
//                   // Hotels have their own status-gated detail screen, as on
//                   // the web (`HotelBookingDetailsPage`).
//                   page: widget.product == TravelProduct.hotel
//                       ? HotelBookingDetailPage(
//                           api: widget.api,
//                           booking: _bookings[i],
//                         )
//                       : TripDetailPage(api: widget.api, booking: _bookings[i]),
//                   style: PageTransitionStyle.slideRight,
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// ---------------------------------------------------------------------------

/// One booking, as a card. Everything a traveller scans for — where, when,
/// and is it actually confirmed — without opening it.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.booking, this.onTap, this.footer});

  final TravelBooking booking;
  final VoidCallback? onTap;

  /// Product-specific actions under the card (flights: Pay & Confirm, View
  /// Summary, Invoice, Book Return).
  final Widget? footer;

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
              // Flights use the web dashboard's vocabulary ("Seat Held" for an
              // on_hold fare, …).
              if (booking.product == TravelProduct.flight)
                FlightStatusPill(status: flightStatusOf(booking.status))
              else if (booking.product == TravelProduct.insurance)
                _InsuranceStatusPill(status: insuranceStatusOf(booking.status))
              else if (booking.product == TravelProduct.cab)
                _CabStatusPill(status: cabStatusOf(booking.status))
              else
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
                    // Flights print paise, as the web's dashboard does.
                    booking.product == TravelProduct.flight
                        ? formatFlightFare(booking.amount)
                        : formatPrice(booking.amount),
                    style: AppText.priceSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'View details',
                  style: AppText.labelSm.copyWith(color: AppColors.primary),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.sm),
            footer!,
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
  // const _EmptyTrips({required this.product});
  // const _EmptyTrips({required this.product, this.insuranceFilter});
  const _EmptyTrips({
    required this.product,
    this.insuranceFilter,
    this.cabFilter,
  });

  final TravelProduct product;

  /// The cab status pill in use, for the web's "No pending cab bookings…".
  final CabStatusKey? cabFilter;

  /// The insurance status pill in use, so the empty text names it as the
  /// web's does ("No cancelled insurance bookings at the moment.").
  final InsuranceStatusKey? insuranceFilter;

  @override
  Widget build(BuildContext context) {
    // The web's insurance panel: its own title, a message naming the active
    // status pill, and an "Explore Travel Insurance" way back to the search.
    // The web's cab panel: "No Cab Bookings Found" and a "Book a Cab" way
    // back to the search.
    if (product == TravelProduct.cab) {
      final filter = cabFilter;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.huge),
          EmptyState(
            title: 'No Cab Bookings Found',
            message: filter == null
                ? "You haven't booked any cabs yet."
                : 'No ${filter.name} cab bookings at the moment.',
            icon: Icons.local_taxi_outlined,
            actionLabel: 'Book a Cab',
            onAction: () =>
                openHoneymoonService(context, HoneymoonService.carRental),
          ),
        ],
      );
    }
    if (product == TravelProduct.insurance) {
      final filter = insuranceFilter;
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SizedBox(height: AppSpacing.huge),
          EmptyState(
            title: 'No Insurance Bookings Found',
            message: filter == null
                ? "You haven't bought travel insurance yet."
                : 'No ${filter.name} insurance bookings at the moment.',
            icon: Icons.shield_outlined,
            actionLabel: 'Explore Travel Insurance',
            onAction: () => openInsuranceSearch(context),
          ),
        ],
      );
    }
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
            TravelProduct.cab => 'Airport transfers you book will appear here.',
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

/// The web dashboard's insurance pill ("Policy Issued", "Pending", …).
class _InsuranceStatusPill extends StatelessWidget {
  const _InsuranceStatusPill({required this.status});

  final InsuranceStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.key) {
      InsuranceStatusKey.confirmed => AppColors.successDark,
      InsuranceStatusKey.pending => AppColors.warning,
      InsuranceStatusKey.cancelled ||
      InsuranceStatusKey.failed => AppColors.error,
      InsuranceStatusKey.unknown => AppColors.textSecondary,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// The web dashboard's cab pill: the provider's status, title-cased
/// (`normalizeStatus(…, "cab")`), coloured by its bucket.
class _CabStatusPill extends StatelessWidget {
  const _CabStatusPill({required this.status});

  final CabStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.key) {
      CabStatusKey.confirmed => AppColors.successDark,
      CabStatusKey.pending => AppColors.warning,
      CabStatusKey.cancelled || CabStatusKey.failed => AppColors.error,
      CabStatusKey.unknown => AppColors.textSecondary,
    };
    return Container(
      constraints: const BoxConstraints(maxWidth: 120),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadii.rPill,
      ),
      child: Text(
        status.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
