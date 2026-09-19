/// One hotel booking in full — the web's `HotelBookingDetailsPage`.
///
/// Hotels get their own screen rather than the shared [TripDetailPage]
/// because the web's hotel page gates every action on the order status:
///
/// ```
/// cancel         SUCCESS / CONFIRMED / VOUCHERED / ON_HOLD / PAYMENT_SUCCESS,
///                and not already cancelling
/// confirm hold   a HOLD booking that is not PAID yet
/// receipt        PAID and confirmed
/// voucher        confirmed
/// ```
///
/// and it can pay for a held room (payment order → Razorpay →
/// `hotels/confirm-book`), which the shared screen has no notion of.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../models/hotel_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../booking/booking_widgets.dart';
import '../widgets/honeymoon_widgets.dart';
import '../widgets/hotel_widgets.dart';

class HotelBookingDetailPage extends StatefulWidget {
  const HotelBookingDetailPage({
    super.key,
    required this.api,
    required this.booking,
  });

  final HoneymoonApi api;

  /// The list row — shown at once, and the fallback when the detail lookup
  /// fails.
  final TravelBooking booking;

  @override
  State<HotelBookingDetailPage> createState() => _HotelBookingDetailPageState();
}

class _HotelBookingDetailPageState extends State<HotelBookingDetailPage> {
  HotelBookingStatus? _status;
  bool _loading = true;
  String? _error;
  String _notice = '';

  /// Set once a cancellation is submitted, so the button cannot be pressed
  /// twice while the supplier processes it.
  bool _cancellationRequested = false;

  /// `cancel`, `hold`, `receipt`, `voucher` — whichever action is running.
  String _busy = '';

  String get _bookingId => widget.booking.reference;

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
      final status = await widget.api.fetchHotelBookingStatus(_bookingId);
      if (!mounted) return;
      setState(() {
        _status = status;
        _loading = false;
      });
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      // A booking whose payment never completed has no supplier order yet;
      // the web explains that rather than showing the raw error.
      final pendingPayment = const {
        'PAYMENT_PENDING',
        'PENDING',
        'IN_PROGRESS',
      }.contains(widget.booking.status.toUpperCase());
      final noOrder = asString(
        readKey(e.data, 'error'),
      ).toLowerCase().contains('no order found');
      setState(() {
        _loading = false;
        _error = pendingPayment && e.statusCode == 400 && noOrder
            ? 'Payment is pending. Booking details will be available after '
                  'the payment completes.'
            : firstNonEmpty([readKey(e.data, 'error')], fallback: e.message);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = bookingErrorText(e);
      });
    }
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  String get _normalizedStatus => _status?.status.isNotEmpty == true
      ? _status!.status
      : widget.booking.status.toUpperCase();

  bool get _canCancel =>
      !_cancellationRequested &&
      (_status?.canCancel ??
          const {
            'SUCCESS',
            'CONFIRMED',
            'VOUCHERED',
            'ON_HOLD',
            'PAYMENT_SUCCESS',
          }.contains(_normalizedStatus));

  bool get _canConfirmHold {
    final s = _status;
    if (s != null) return s.canConfirmHold;
    final type = asString(readKey(widget.booking.raw, 'bookingType'));
    return type.toUpperCase() == 'HOLD' &&
        widget.booking.paymentStatus.toUpperCase() != 'PAID' &&
        const {
          'ON_HOLD',
          'IN_PROGRESS',
          'PENDING',
          'PAYMENT_PENDING',
        }.contains(_normalizedStatus);
  }

  bool get _canDownloadReceipt => _status?.canDownloadReceipt ?? false;
  bool get _canDownloadVoucher => _status?.canDownloadVoucher ?? false;

  Future<void> _download(String kind) async {
    if (_busy.isNotEmpty) return;
    setState(() => _busy = kind);
    try {
      final path = kind == 'voucher'
          ? await widget.api.downloadHotelVoucher(_bookingId)
          : await widget.api.downloadHotelReceipt(_bookingId);
      if (!mounted) return;
      final opened = await OpenFilex.open(path);
      if (!mounted) return;
      if (opened.type != ResultType.done) {
        AppSnackbar.success(context, 'Saved to your device as a PDF.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  /// The web's `handleConfirmHoldBooking`.
  Future<void> _confirmHold() async {
    if (_busy.isNotEmpty) return;
    final ok = await ConfirmPopup.show(
      context,
      title: 'Confirm this booking?',
      message:
          'You will pay now to confirm the held room. It is released if it is '
          'not paid before the deadline.',
      confirmLabel: 'Pay & confirm',
      cancelLabel: 'Not now',
      icon: Icons.lock_open_rounded,
    );
    if (!ok || !mounted) return;

    setState(() {
      _busy = 'hold';
      _notice = '';
    });
    try {
      final status = _status;
      final amount = status != null && status.total > 0
          ? status.total
          : widget.booking.amount;
      final paymentInfos = amount > 0
          ? [
              {'amount': amount},
            ]
          : const <Map<String, dynamic>>[];

      // The backend needs travellers and contact for the order; whatever the
      // detail carried is sent, and it falls back to the saved booking.
      final raw = status?.raw ?? const <String, dynamic>{};
      final order = await widget.api.createHotelPaymentOrder({
        'bookingId': _bookingId,
        'paymentInfos': paymentInfos,
        'roomTravellerInfo':
            readKey(raw, 'travellerInfo') ??
            readKey(raw, 'roomTravellerInfo') ??
            const [],
        'deliveryInfo': readKey(raw, 'deliveryInfo') ?? const {},
      });
      if (!mounted) return;

      final outcome = await RazorpayCheckout.open(
        context,
        order: order,
        title: 'HappyWedz Hotels',
        restrictMethodsInTestMode: true,
        allowRetry: true,
        description: order.description.isNotEmpty
            ? order.description
            : 'Hold booking confirmation',
        prefill: (
          name: '',
          email: status?.email ?? '',
          contact: status?.phone ?? '',
        ),
      );
      if (!mounted) return;

      switch (outcome) {
        case RazorpayDismissed():
          setState(() => _notice = 'Payment was cancelled.');
        case RazorpayFailure(:final message):
          setState(() => _notice = message);
        case RazorpaySuccess(:final result):
          final response = await widget.api.confirmHotelBooking({
            'bookingId': _bookingId,
            'paymentInfos': paymentInfos,
            ...result.toVerifyJson(),
          });
          if (!mounted) return;
          setState(
            () => _notice = asString(
              readKey(response, 'message'),
              fallback: 'Hold booking confirmed. Awaiting final status.',
            ),
          );
          await _load();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _notice = bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  /// The web's `handleCancelBooking`.
  Future<void> _cancel() async {
    if (_busy.isNotEmpty) return;
    final ok = await ConfirmPopup.show(
      context,
      title: 'Cancel this booking?',
      message:
          'Cancellation charges may apply as per the policy below. '
          'This cannot be undone.',
      confirmLabel: 'Cancel booking',
      cancelLabel: 'Keep it',
      icon: Icons.cancel_outlined,
      danger: true,
    );
    if (!ok || !mounted) return;

    setState(() {
      _busy = 'cancel';
      _notice = '';
    });
    try {
      final response = await widget.api.cancelHotelBooking(_bookingId);
      if (!mounted) return;
      setState(() {
        _cancellationRequested = true;
        _notice = asString(
          readKey(response, 'message'),
          fallback: 'Cancellation request submitted.',
        );
      });
      await _load();
    } on HoneymoonApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _notice = firstNonEmpty([
          readKey(e.data, 'error'),
        ], fallback: e.message),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _notice = bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  /// Title, subtitle and colour per status — the web's `getStatusTone`.
  ({String title, String subtitle, Color color}) get _tone {
    final s = _normalizedStatus;
    if (s == 'CANCELLATION_REQUESTED' || s == 'CANCELLATION_PENDING') {
      return (
        title: 'Cancellation pending',
        subtitle:
            'Your cancellation request is being processed. Check back for '
            'the final cancellation status.',
        color: AppColors.warning,
      );
    }
    if (s == 'CANCELLED') {
      return (
        title: 'Booking cancelled',
        subtitle: 'This booking has been cancelled.',
        color: AppColors.error,
      );
    }
    if (kHotelSuccessStatuses.contains(s)) {
      return (
        title: 'Booking confirmed',
        subtitle: 'Your booking is confirmed and payment is captured.',
        color: AppColors.successDark,
      );
    }
    if (s == 'PAYMENT_SUCCESS') {
      return (
        title: 'Payment success – pending voucher',
        subtitle: 'Payment is successful. Hotel confirmation is in progress.',
        color: AppColors.warning,
      );
    }
    if (s == 'ON_HOLD') {
      return (
        title: 'Booking on hold',
        subtitle:
            'This room is held and must be confirmed before the deadline.',
        color: AppColors.info,
      );
    }
    return (
      title: 'Booking status update',
      subtitle:
          'Your booking is being processed. Please refresh after some time.',
      color: AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final tone = _tone;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(title: 'Hotel booking', elevated: true),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: tone.color.withValues(alpha: 0.08),
                borderRadius: AppRadii.rLg,
                border: Border.all(color: tone.color.withValues(alpha: 0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tone.title,
                    style: AppText.sectionTitle.copyWith(color: tone.color),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(tone.subtitle, style: AppText.bodySm),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_notice.isNotEmpty) ...[
              InfoBanner(message: _notice),
              const SizedBox(height: AppSpacing.md),
            ],
            _referenceTile(),
            const SizedBox(height: AppSpacing.md),

            if (_loading)
              const AppCard(child: AppLoader(padding: EdgeInsets.zero))
            else if (_error != null)
              InfoBanner(
                tone: InfoTone.warning,
                message: _error!,
                action: PremiumButton.text(
                  label: 'Retry',
                  size: PremiumButtonSize.small,
                  onPressed: _load,
                ),
              )
            else if (status != null)
              ..._details(status),

            const SizedBox(height: AppSpacing.xl),
            ..._actions(),
          ],
        ),
      ),
    );
  }

  Widget _referenceTile() {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Booking ID', style: AppText.caption),
                SelectableText(_bookingId, style: AppText.sectionTitle),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy booking ID',
            icon: const Icon(Icons.copy_rounded, size: 19),
            color: AppColors.primary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: _bookingId));
              if (mounted) AppSnackbar.success(context, 'Booking ID copied');
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _details(HotelBookingStatus s) {
    final checkIn = DateTime.tryParse(s.checkIn) ?? widget.booking.travelDate;
    final checkOut = DateTime.tryParse(s.checkOut);
    final nights = s.nights;
    final hasFare = s.baseFare > 0 || s.taxes > 0 || s.total > 0;

    return [
      FormSection(
        title: s.hotelName.isNotEmpty ? s.hotelName : widget.booking.title,
        subtitle: s.address.isNotEmpty ? s.address : null,
        icon: Icons.hotel_rounded,
        children: [
          DetailRow(label: 'Status', value: s.statusLabel),
          if (checkIn != null)
            DetailRow(label: 'Check-in', value: formatTripDate(checkIn)),
          if (checkOut != null)
            DetailRow(label: 'Check-out', value: formatTripDate(checkOut)),
          if (nights > 0)
            DetailRow(
              label: 'Stay',
              value: '$nights night${nights == 1 ? '' : 's'}',
            ),
          if (s.roomName.isNotEmpty)
            DetailRow(label: 'Room', value: s.roomName),
          DetailRow(
            label: 'Rooms & guests',
            value:
                '${s.totalRooms} room${s.totalRooms == 1 ? '' : 's'} · '
                '${s.adults} adult${s.adults == 1 ? '' : 's'}'
                '${s.children > 0 ? ', ${s.children} child${s.children == 1 ? '' : 'ren'}' : ''}',
          ),
          for (final guest in s.guests) DetailRow(label: 'Guest', value: guest),
          if (s.createdOn.isNotEmpty)
            DetailRow(label: 'Booked on', value: s.createdOn),
          if (s.deadline.isNotEmpty && s.isHoldPendingPayment)
            DetailRow(
              label: 'Pay before',
              value: formatPolicyDateTime(s.deadline),
            ),
        ],
      ),
      if (s.email.isNotEmpty || s.phone.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Contact',
          icon: Icons.alternate_email_rounded,
          children: [
            if (s.email.isNotEmpty) DetailRow(label: 'Email', value: s.email),
            if (s.phone.isNotEmpty) DetailRow(label: 'Phone', value: s.phone),
          ],
        ),
      ],
      if (hasFare) ...[
        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Fare',
          icon: Icons.receipt_long_outlined,
          children: [
            if (s.baseFare > 0)
              DetailRow(
                label: 'Base fare',
                value: formatHotelFare(s.baseFare, currency: s.currency),
              ),
            if (s.taxes > 0)
              DetailRow(
                label: 'Taxes & fees',
                value: formatHotelFare(s.taxes, currency: s.currency),
              ),
            if (s.managementFee > 0)
              DetailRow(
                label: 'Management fee',
                value: formatHotelFare(s.managementFee, currency: s.currency),
              ),
            if (s.managementFeeTax > 0)
              DetailRow(
                label: 'Mgmt. fee tax',
                value: formatHotelFare(
                  s.managementFeeTax,
                  currency: s.currency,
                ),
              ),
            DetailRow(
              label: 'Total',
              value: formatHotelFare(
                s.total > 0 ? s.total : widget.booking.amount,
                currency: s.currency,
              ),
              valueStyle: AppText.priceSm,
            ),
          ],
        ),
      ],
      if (s.penalties.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        FormSection(
          title: 'Cancellation policy',
          icon: Icons.policy_outlined,
          children: [
            HotelPenaltyTable(penalties: s.penalties, currency: s.currency),
          ],
        ),
      ],
    ];
  }

  List<Widget> _actions() {
    final buttons = <Widget>[
      if (_canConfirmHold)
        PremiumButton(
          label: 'Pay & confirm booking',
          icon: Icons.lock_open_rounded,
          isLoading: _busy == 'hold',
          enabled: _busy.isEmpty,
          onPressed: _confirmHold,
        ),
      if (_canDownloadVoucher)
        PremiumButton.outlined(
          label: 'Download voucher',
          icon: Icons.picture_as_pdf_outlined,
          isLoading: _busy == 'voucher',
          enabled: _busy.isEmpty,
          onPressed: () => _download('voucher'),
        ),
      if (_canDownloadReceipt)
        PremiumButton.outlined(
          label: 'Download receipt',
          icon: Icons.receipt_long_outlined,
          isLoading: _busy == 'receipt',
          enabled: _busy.isEmpty,
          onPressed: () => _download('receipt'),
        ),
      if (_canCancel && !_loading)
        PremiumButton(
          label: 'Cancel booking',
          variant: PremiumButtonVariant.danger,
          icon: Icons.cancel_outlined,
          isLoading: _busy == 'cancel',
          enabled: _busy.isEmpty,
          onPressed: _cancel,
        ),
    ];
    return [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        buttons[i],
      ],
    ];
  }
}
