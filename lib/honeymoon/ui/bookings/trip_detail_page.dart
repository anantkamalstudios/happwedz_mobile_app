/// One booking in full, plus the actions that can still be taken on it.
///
/// The list row is built from a summary payload; this screen fetches the
/// supplier's own detail record, which is where passenger names, PNRs, room
/// details and policy travellers actually live. The summary is shown
/// immediately and the detail fills in behind it, so the screen is never
/// blank while it loads.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../booking/booking_widgets.dart';
import '../widgets/honeymoon_widgets.dart';

class TripDetailPage extends StatefulWidget {
  const TripDetailPage({super.key, required this.api, required this.booking});

  final HoneymoonApi api;
  final TravelBooking booking;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  Map<String, dynamic> _detail = const {};
  bool _loading = true;

  /// A detail lookup that fails is not fatal — the summary already on screen
  /// carries the reference, the date and the status.
  String? _detailError;

  bool _busy = false;

  late TravelBooking _booking = widget.booking;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loading = true;
      _detailError = null;
    });
    try {
      final detail = await switch (_booking.product) {
        TravelProduct.flight => widget.api.fetchFlightBookingDetails(
          _booking.reference,
        ),
        TravelProduct.hotel => widget.api.fetchHotelBookingDetails(
          _booking.reference,
        ),
        TravelProduct.insurance => widget.api.fetchInsuranceBookingDetails(
          _booking.reference,
        ),
        TravelProduct.cab => Future.value(const <String, dynamic>{}),
      };
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _detailError = bookingErrorText(e);
      });
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  bool get _canCancel =>
      !_booking.isCancelled &&
      _booking.reference.isNotEmpty &&
      (_booking.product == TravelProduct.flight ||
          _booking.product == TravelProduct.hotel);

  bool get _canEmailTicket =>
      _booking.product == TravelProduct.flight &&
      !_booking.isCancelled &&
      _booking.reference.isNotEmpty;

  /// Shows what cancelling would actually cost before asking to confirm it —
  /// a refund quote is the one thing a traveller needs at this moment.
  Future<void> _cancel() async {
    if (_busy) return;
    setState(() => _busy = true);

    try {
      String? refundLine;
      if (_booking.product == TravelProduct.flight) {
        final charges = await widget.api.fetchFlightCancelCharges(
          _booking.reference,
        );
        final refund = asDouble(
          readKey(charges, 'refundAmount') ??
              readKey(charges, 'totalRefund') ??
              digPath(charges, ['data', 'refundAmount']),
        );
        final fee = asDouble(
          readKey(charges, 'cancellationCharge') ??
              readKey(charges, 'totalCharge'),
        );
        if (refund > 0 || fee > 0) {
          refundLine =
              'Cancellation charge ${formatPrice(fee)} · '
              'estimated refund ${formatPrice(refund)}.';
        }
      }
      if (!mounted) return;

      final confirmed = await ConfirmPopup.show(
        context,
        title: 'Cancel this booking?',
        message: [
          refundLine ??
              'Refunds depend on the fare rules and can take a few days to '
                  'reach your account.',
          'This cannot be undone.',
        ].join('\n\n'),
        confirmLabel: 'Cancel booking',
        cancelLabel: 'Keep it',
        icon: Icons.cancel_outlined,
        danger: true,
      );
      if (!confirmed || !mounted) return;

      setState(() => _busy = true);
      if (_booking.product == TravelProduct.flight) {
        await widget.api.cancelFlightBooking(_booking.reference);
      } else {
        await widget.api.cancelHotelBooking(_booking.reference);
      }
      if (!mounted) return;

      setState(() {
        _booking = TravelBooking(
          product: _booking.product,
          reference: _booking.reference,
          title: _booking.title,
          subtitle: _booking.subtitle,
          travelDate: _booking.travelDate,
          bookedOn: _booking.bookedOn,
          status: 'CANCELLED',
          paymentStatus: _booking.paymentStatus,
          amount: _booking.amount,
          travellerSummary: _booking.travellerSummary,
          raw: _booking.raw,
        );
      });
      AppSnackbar.success(
        context,
        'Your booking has been cancelled. Any refund follows the fare rules.',
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _emailTicket() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.api.emailFlightTicket(_booking.reference);
      if (!mounted) return;
      AppSnackbar.success(context, 'Your ticket is on its way by email.');
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: _booking.product.label, elevated: true),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadDetail,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _Header(booking: _booking),
            const SizedBox(height: AppSpacing.lg),

            if (_booking.reference.isNotEmpty) ...[
              _ReferenceTile(reference: _booking.reference),
              const SizedBox(height: AppSpacing.md),
            ],

            FormSection(
              title: 'Booking summary',
              icon: Icons.receipt_long_outlined,
              children: [
                if (_booking.travelDate != null)
                  DetailRow(
                    label: _booking.product == TravelProduct.hotel
                        ? 'Check-in'
                        : _booking.product == TravelProduct.insurance
                        ? 'Cover from'
                        : 'Travel date',
                    value: formatTripDate(_booking.travelDate),
                  ),
                if (_booking.bookedOn != null)
                  DetailRow(
                    label: 'Booked on',
                    value: formatTripDate(_booking.bookedOn),
                  ),
                if (_booking.travellerSummary.isNotEmpty)
                  DetailRow(
                    label: _booking.product == TravelProduct.hotel
                        ? 'Stay'
                        : 'Travellers',
                    value: _booking.travellerSummary,
                  ),
                if (_booking.paymentStatus.isNotEmpty)
                  DetailRow(
                    label: 'Payment',
                    value: _booking.paymentStatus,
                  ),
                if (_booking.amount > 0)
                  DetailRow(
                    label: 'Amount',
                    value: formatPrice(_booking.amount),
                    valueStyle: AppText.priceSm,
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            if (_loading)
              const AppCard(child: AppLoader(padding: EdgeInsets.zero))
            else if (_detailError != null)
              InfoBanner(
                tone: InfoTone.warning,
                message:
                    'We could not load the full details right now. '
                    '$_detailError',
                action: PremiumButton.text(
                  label: 'Retry',
                  size: PremiumButtonSize.small,
                  onPressed: _loadDetail,
                ),
              )
            else
              ..._detailSections(),

            const SizedBox(height: AppSpacing.xl),
            if (_canEmailTicket) ...[
              PremiumButton.outlined(
                label: 'Email me the ticket',
                icon: Icons.mail_outline_rounded,
                isLoading: _busy,
                onPressed: _emailTicket,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_canCancel)
              PremiumButton(
                label: 'Cancel booking',
                variant: PremiumButtonVariant.danger,
                icon: Icons.cancel_outlined,
                isLoading: _busy,
                onPressed: _cancel,
              ),
          ],
        ),
      ),
    );
  }

  /// The supplier-specific part, built from whichever detail payload came
  /// back. Each returns an empty list when the payload has nothing to show,
  /// so a sparse record degrades to the summary rather than to empty headings.
  List<Widget> _detailSections() => switch (_booking.product) {
    TravelProduct.flight => _flightSections(),
    TravelProduct.hotel => _hotelSections(),
    TravelProduct.insurance => _insuranceSections(),
    TravelProduct.cab => const [],
  };

  List<Widget> _flightSections() {
    final travellers = asList(
      readKey(_detail, 'travellerInfos') ?? readKey(_detail, 'travellerInfo'),
    );
    final trips = asList(
      digPath(_detail, ['itemInfos', 'AIR', 'tripInfos']) ??
          readKey(_detail, 'tripInfos'),
    );

    return [
      if (trips.isNotEmpty) ...[
        FormSection(
          title: 'Itinerary',
          icon: Icons.flight_rounded,
          children: [
            for (final trip in trips)
              for (final segment in asList(readKey(trip, 'sI')))
                _SegmentRow(segment: segment),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
      if (travellers.isNotEmpty)
        FormSection(
          title: 'Passengers',
          icon: Icons.people_outline_rounded,
          children: [
            for (final t in travellers)
              DetailRow(
                label: asString(readKey(t, 'pt'), fallback: 'Passenger'),
                value: [
                  asString(readKey(t, 'ti')),
                  asString(readKey(t, 'fN')),
                  asString(readKey(t, 'lN')),
                  if (asString(readKey(t, 'pnrDetails')).isNotEmpty)
                    '· PNR ${asString(readKey(t, 'pnrDetails'))}',
                ].where((s) => s.isNotEmpty).join(' '),
              ),
          ],
        ),
    ];
  }

  List<Widget> _hotelSections() {
    final hotel =
        readKey(_detail, 'hotelInfo') ?? digPath(_detail, ['itemInfos', 'HOTEL']);
    final guests = asList(
      digPath(hotel, ['roomTravellerInfo', 0, 'travellerInfo']),
    );
    final address = asString(readKey(hotel, 'ad') ?? readKey(hotel, 'address'));

    return [
      if (address.isNotEmpty || guests.isNotEmpty)
        FormSection(
          title: 'Stay details',
          icon: Icons.hotel_rounded,
          children: [
            if (address.isNotEmpty)
              DetailRow(label: 'Address', value: address),
            for (final g in guests)
              DetailRow(
                label: 'Guest',
                value: [
                  asString(readKey(g, 'ti')),
                  asString(readKey(g, 'fN')),
                  asString(readKey(g, 'lN')),
                ].where((s) => s.isNotEmpty).join(' '),
              ),
          ],
        ),
    ];
  }

  List<Widget> _insuranceSections() {
    final insurance = digPath(_detail, ['itemInfos', 'INSURANCE']);
    final product = digPath(insurance, ['iinfo', 'pli', 0, 'pi', 0]);
    final travellers = asList(
      readKey(product, 'iti') ?? digPath(insurance, ['isq', 'iti']),
    );

    return [
      if (travellers.isNotEmpty)
        FormSection(
          title: 'Insured travellers',
          icon: Icons.people_outline_rounded,
          children: [
            for (final t in travellers)
              DetailRow(
                label: 'Traveller',
                value: [
                  asString(readKey(t, 'fn')),
                  asString(readKey(t, 'ln')),
                  if (asInt(readKey(t, 'age')) > 0)
                    '· ${asInt(readKey(t, 'age'))} yrs',
                  if (asString(readKey(t, 'policyId')).isNotEmpty)
                    '· ${asString(readKey(t, 'policyId'))}',
                ].where((s) => s.isNotEmpty).join(' '),
              ),
          ],
        ),
    ];
  }
}

// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final TravelBooking booking;

  @override
  Widget build(BuildContext context) {
    final (icon, tint, label) = booking.isCancelled
        ? (Icons.cancel_rounded, AppColors.error, 'Cancelled')
        : booking.isConfirmed
        ? (Icons.check_circle_rounded, AppColors.successDark, 'Confirmed')
        : (Icons.schedule_rounded, AppColors.warning, 'Processing');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppText.bodyStrong.copyWith(color: tint),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(booking.title, style: AppText.sectionTitle),
          if (booking.subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(booking.subtitle, style: AppText.cardSubtitle),
          ],
        ],
      ),
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Booking reference', style: AppText.caption),
                const SizedBox(height: 2),
                SelectableText(
                  reference,
                  style: AppText.bodyStrong.copyWith(letterSpacing: 0.3),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy reference',
            icon: const Icon(Icons.copy_rounded, size: 18),
            color: AppColors.primary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reference));
              if (context.mounted) {
                AppSnackbar.success(context, 'Reference copied');
              }
            },
          ),
        ],
      ),
    );
  }
}

/// One flight segment on a booked itinerary.
class _SegmentRow extends StatelessWidget {
  const _SegmentRow({required this.segment});

  final dynamic segment;

  String _time(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final from = asString(digPath(segment, ['da', 'code']));
    final to = asString(digPath(segment, ['aa', 'code']));
    final departure = asString(readKey(segment, 'dt'));
    final airline = asString(digPath(segment, ['fD', 'aI', 'name']));
    final number =
        '${asString(digPath(segment, ['fD', 'aI', 'code']))} '
                '${asString(digPath(segment, ['fD', 'fN']))}'
            .trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.flight_takeoff_rounded,
              size: 15,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$from → $to', style: AppText.bodyStrong),
                const SizedBox(height: 2),
                Text(
                  [
                    if (departure.isNotEmpty)
                      formatTripDate(DateTime.tryParse(departure)),
                    if (_time(departure).isNotEmpty) _time(departure),
                    if (airline.isNotEmpty) airline,
                    if (number.isNotEmpty) number,
                  ].where((s) => s.isNotEmpty).join(' · '),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
