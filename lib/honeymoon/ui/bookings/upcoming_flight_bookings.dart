/// "Upcoming Bookings" under the Flights search — the web's
/// `components/UpcomingBookings.jsx`, which `HeroPage.jsx` renders beneath
/// `FlightSearchForm` on the Flights tab.
///
/// ```
/// list      GET /tj/my-bookings → travel date today or later (or none yet),
///           soonest first, five per page; collapsible
/// row       order id (opens the booking) + ON HOLD badge, passenger, travel
///           date, View Summary
/// held      Pay & Confirm (create_order is_hold_confirm → Razorpay →
///           verify_and_book), Release (release-hold)
/// else      ↩ Book Return (the search, reversed)
/// share     "Your upcoming flight bookings:" to WhatsApp
/// ```
///
/// The web's second tab, "Recent Searches", is the list under the search
/// form itself on the app ([FlightSearchForm]), so it is not repeated here.
/// Signed out, the section simply does not appear — the web shows nothing on
/// a 401 either.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../authservice.dart';
import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import '../booking/flight_hold_payment.dart';
import '../widgets/honeymoon_widgets.dart';
import 'flight_booking_detail_page.dart';

class UpcomingFlightBookings extends StatefulWidget {
  const UpcomingFlightBookings({super.key, required this.api});

  final HoneymoonApi api;

  @override
  State<UpcomingFlightBookings> createState() => _UpcomingFlightBookingsState();
}

class _UpcomingFlightBookingsState extends State<UpcomingFlightBookings> {
  static const int _pageSize = 5;

  List<TravelBooking> _bookings = const [];
  bool _loading = true;
  String? _error;
  bool _collapsed = false;
  int _page = 1;

  /// Order id of the row whose payment or release is running.
  String _busy = '';

  @override
  void initState() {
    super.initState();
    // Reload when a guest signs in from a booking flow on top of this page.
    AuthSession.instance.addListener(_onAuthChanged);
    _load();
  }

  @override
  void dispose() {
    AuthSession.instance.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    setState(() => _loading = true);
    _load();
  }

  Future<void> _load() async {
    if (!AuthSession.instance.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    try {
      final rows = await widget.api.fetchFlightBookings();
      if (!mounted) return;
      setState(() {
        _bookings = rows;
        _loading = false;
        _error = null;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // 401 → not signed in: nothing to show rather than an error wall.
        _error = e.statusCode == 401 ? null : 'Could not load your bookings.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your bookings.';
      });
    }
  }

  /// Travel date today or later — or no usable date yet, which is not hidden —
  /// soonest first, undated last.
  List<TravelBooking> get _upcoming {
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

  void _openDetail(TravelBooking b) {
    if (b.reference.isEmpty) return;
    Navigator.push(
      context,
      AnimatedPageRoute(
        page: FlightBookingDetailPage(api: widget.api, booking: b),
        style: PageTransitionStyle.slideRight,
      ),
    ).then((_) {
      if (mounted) _load();
    });
  }

  Future<void> _payConfirm(TravelBooking b) async {
    setState(() => _busy = b.reference);
    final result = await payHeldFlight(
      context,
      api: widget.api,
      held: heldFlightFromRow(b),
    );
    if (!mounted) return;
    setState(() => _busy = '');
    if (result.paid) {
      AppSnackbar.success(
        context,
        'Payment received — your booking is confirmed.',
      );
      // Refresh so the booking flips to confirmed.
      await _load();
    } else if (result.error != null) {
      AppSnackbar.error(context, result.error!);
    }
  }

  Future<void> _release(TravelBooking b) async {
    final ok = await ConfirmPopup.show(
      context,
      title: 'Release this held seat?',
      message: 'This cannot be undone.',
      confirmLabel: 'Release',
      cancelLabel: 'Keep it',
      icon: Icons.lock_open_rounded,
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = b.reference);
    try {
      await widget.api.releaseHeldFlight(b.reference);
      if (mounted) await _load();
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.message.isEmpty ? 'Could not release the hold.' : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _share(List<TravelBooking> upcoming) =>
      shareUpcomingFlightBookings(context, upcoming);

  // Previous inline copy, now [shareUpcomingFlightBookings]:
  // Future<void> _share(List<TravelBooking> upcoming) async {
  //   final lines = upcoming
  //       .take(10)
  //       .map(
  //         (b) =>
  //             '• ${firstNonEmpty([readKey(b.raw, 'passenger_name')], fallback: 'Guest')} '
  //             '— ${b.reference} '
  //             '(${b.travelDate == null ? '—' : formatTripDate(b.travelDate)})',
  //       )
  //       .join('\n');
  //   final ok = await launchUrl(
  //     Uri.parse(
  //       'https://wa.me/?text='
  //       '${Uri.encodeComponent('Your upcoming flight bookings:\n$lines')}',
  //     ),
  //     mode: LaunchMode.externalApplication,
  //   );
  //   if (!ok && mounted) {
  //     AppSnackbar.error(context, 'WhatsApp is not available on this device.');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    if (!AuthSession.instance.isAuthenticated) return const SizedBox.shrink();

    final upcoming = _upcoming;
    final totalPages = (upcoming.length / _pageSize).ceil().clamp(1, 1 << 30);
    final page = _page.clamp(1, totalPages);
    final rows = upcoming.skip((page - 1) * _pageSize).take(_pageSize).toList();

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
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _collapsed = !_collapsed),
                  child: Row(
                    children: [
                      Text('Upcoming Bookings', style: AppText.sectionTitle),
                      Icon(
                        _collapsed
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_up_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              if (upcoming.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _share(upcoming),
                  icon: const Icon(
                    Icons.share_rounded,
                    size: 16,
                    color: AppColors.successDark,
                  ),
                  label: const Text('Share'),
                ),
            ],
          ),
          if (!_collapsed) ...[
            const SizedBox(height: AppSpacing.sm),
            if (_loading)
              Text('Loading your bookings…', style: AppText.bodySm)
            else if (_error != null)
              Text(_error!, style: AppText.bodySm)
            else if (upcoming.isEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.flight_rounded,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'No upcoming bookings yet. Search and book a flight to '
                      'see it here.',
                      style: AppText.bodySm,
                    ),
                  ),
                ],
              )
            else ...[
              for (final b in rows) ...[
                _row(b),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (totalPages > 1)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: page <= 1
                          ? null
                          : () => setState(() => _page = page - 1),
                      child: const Text('‹ Prev'),
                    ),
                    Text('$page', style: AppText.labelSm),
                    TextButton(
                      onPressed: page >= totalPages
                          ? null
                          : () => setState(() => _page = page + 1),
                      child: const Text('Next ›'),
                    ),
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _row(TravelBooking b) {
    final held = flightStatusOf(b.status).key == FlightStatusKey.hold;
    final busy = _busy == b.reference;
    final canReturn =
        asString(readKey(b.raw, 'from_iata')).isNotEmpty &&
        asString(readKey(b.raw, 'to_iata')).isNotEmpty;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _openDetail(b),
                  child: Text(
                    b.reference.isEmpty ? '—' : b.reference,
                    style: AppText.bodyStrong.copyWith(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              if (held)
                FlightStatusPill(status: flightStatusOf('ON_HOLD'))
              else
                FlightStatusPill(status: flightStatusOf(b.status)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              firstNonEmpty([readKey(b.raw, 'passenger_name')], fallback: '—'),
              if (b.title.isNotEmpty) b.title,
              b.travelDate == null ? '—' : formatTripDate(b.travelDate),
            ].join(' · '),
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              if (held) ...[
                PremiumButton(
                  label: busy ? 'Processing…' : 'Pay & Confirm',
                  size: PremiumButtonSize.small,
                  expanded: false,
                  onPressed: _busy.isEmpty ? () => _payConfirm(b) : null,
                ),
                PremiumButton.text(
                  label: 'Release',
                  size: PremiumButtonSize.small,
                  onPressed: _busy.isEmpty ? () => _release(b) : null,
                ),
              ] else if (canReturn)
                PremiumButton.text(
                  label: '↩ Book Return',
                  size: PremiumButtonSize.small,
                  onPressed: () =>
                      openFlightReturnSearch(context, widget.api, b),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "SHARE WITH CUSTOMER": the first ten upcoming bookings as
/// "• name — order id (date)" lines, to WhatsApp — `UpcomingBookings.jsx`
/// `shareWithCustomer`. Used here and by My Trips.
Future<void> shareUpcomingFlightBookings(
  BuildContext context,
  List<TravelBooking> upcoming,
) async {
  final lines = upcoming
      .take(10)
      .map(
        (b) =>
            '• ${firstNonEmpty([readKey(b.raw, 'passenger_name')], fallback: 'Guest')} '
            '— ${b.reference} '
            '(${b.travelDate == null ? '—' : formatTripDate(b.travelDate)})',
      )
      .join('\n');
  final ok = await launchUrl(
    Uri.parse(
      'https://wa.me/?text='
      '${Uri.encodeComponent('Your upcoming flight bookings:\n$lines')}',
    ),
    mode: LaunchMode.externalApplication,
  );
  if (!ok && context.mounted) {
    AppSnackbar.error(context, 'WhatsApp is not available on this device.');
  }
}
