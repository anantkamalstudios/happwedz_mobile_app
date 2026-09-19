/// Where a hotel booking ends up once it has left the form — the web's
/// `TripJackBookingStatus` modal plus the `pollTripjackBookingStatus` loop
/// behind it.
///
/// A paid booking is not a confirmed one: TripJack confirms the hotel
/// asynchronously, so after payment the web polls `hotels/booking-details`
/// every 15 s for the first 20 checks, then every 60 s, up to 60 checks, until
/// `bookingStatusMeta` reports a terminal success or failure. This screen does
/// the same, and carries every action the web offers from that modal:
/// refresh, receipt, voucher, paying for a held room, and going back to fix
/// the traveller details.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../models/hotel_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../bookings/my_trips_page.dart';
import '../widgets/honeymoon_widgets.dart';
import '../widgets/hotel_widgets.dart';
import 'booking_widgets.dart';

/// The web's `bookingStatusState.phase` values that reach this screen.
enum HotelBookingPhase {
  /// Waiting on TripJack's final word.
  polling,

  /// Confirmed — or, after a hold, held.
  success,

  /// TripJack reported a terminal failure.
  failed,

  /// TripJack refused the request outright.
  denied,

  /// Polling ran out, or the verify call timed out, with the payment taken.
  timeout,

  /// The payment for this booking was already captured on an earlier try.
  alreadyPaid,
}

/// Why the status screen was closed: the traveller wants to correct the
/// guest details and resubmit — without paying again when [paymentCaptured].
class HotelBookingRetry {
  const HotelBookingRetry({required this.paymentCaptured});

  final bool paymentCaptured;
}

class HotelBookingStatusPage extends StatefulWidget {
  const HotelBookingStatusPage({
    super.key,
    required this.api,
    required this.bookingId,
    required this.hotelName,
    required this.roomName,
    required this.query,
    this.initialPhase = HotelBookingPhase.polling,
    this.initialMessage = '',
    this.initialStatus,
    this.errorCode = '',
    this.amount = 0,
    this.paymentCaptured = false,
    this.fromHold = false,
    this.holdPaymentPayload,
    this.prefill,
  });

  final HoneymoonApi api;
  final String bookingId;
  final String hotelName;
  final String roomName;
  final HotelSearchQuery query;

  final HotelBookingPhase initialPhase;
  final String initialMessage;

  /// Whatever the last booking call already told us (hold answer, verify
  /// answer's `bookingDetails`), shown until the first poll lands.
  final HotelBookingStatus? initialStatus;
  final String errorCode;

  /// The reviewed payable amount, shown until the order carries its own.
  final double amount;

  final bool paymentCaptured;

  /// Opened straight after `hotels/hold` — nothing to poll yet, and the room
  /// can be paid for from here.
  final bool fromHold;

  /// The payment-order payload for paying a held room (the booking payload
  /// *with* `paymentInfos`), as the web's `handlePayHoldBooking` sends.
  final Map<String, dynamic>? holdPaymentPayload;

  final RazorpayPrefill? prefill;

  @override
  State<HotelBookingStatusPage> createState() => _HotelBookingStatusPageState();
}

class _HotelBookingStatusPageState extends State<HotelBookingStatusPage> {
  static const int _maxAttempts = 60;
  static const int _fastAttempts = 20;
  static const Duration _fastInterval = Duration(seconds: 15);
  static const Duration _slowInterval = Duration(seconds: 60);

  late HotelBookingPhase _phase = widget.initialPhase;
  late String _message = widget.initialMessage;
  late HotelBookingStatus _status =
      widget.initialStatus ?? HotelBookingStatus(bookingId: widget.bookingId);
  late String _errorCode = widget.errorCode;
  late bool _paymentCaptured = widget.paymentCaptured;

  int _attempts = 0;
  bool _polling = false;

  /// Bumped to cancel a running poll — a refresh or leaving the screen must
  /// stop the old loop, exactly as the web's `bookingPollSessionRef` does.
  int _pollSession = 0;

  String _documentLoading = '';

  @override
  void initState() {
    super.initState();
    if (_phase == HotelBookingPhase.polling ||
        _phase == HotelBookingPhase.alreadyPaid) {
      _poll();
    }
  }

  @override
  void dispose() {
    _pollSession++;
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Polling
  // -------------------------------------------------------------------------

  Future<void> _poll() async {
    final session = ++_pollSession;
    setState(() => _polling = true);

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      if (!mounted || session != _pollSession) return;
      if (attempt > 1) {
        await Future<void>.delayed(
          attempt <= _fastAttempts ? _fastInterval : _slowInterval,
        );
        if (!mounted || session != _pollSession) return;
      }

      try {
        final status = await widget.api.fetchHotelBookingStatus(
          widget.bookingId,
        );
        if (!mounted || session != _pollSession) return;

        // Terminal flags come from the backend's `bookingStatusMeta`; when an
        // older response lacks them the raw status decides.
        final success =
            status.isSuccessTerminal ||
            (!status.isFailureTerminal && status.isConfirmed);
        final failure =
            status.isFailureTerminal ||
            kHotelFailureStatuses.contains(status.status);

        setState(() {
          _status = status;
          _attempts = attempt;
          if (success) {
            _phase = HotelBookingPhase.success;
            _message = 'Booking confirmed successfully.';
          } else if (failure) {
            _phase = HotelBookingPhase.failed;
            _message =
                'The hotel could not confirm this booking. Please review the '
                'details and try again.';
          } else {
            _phase = HotelBookingPhase.polling;
            _message =
                status.rawStatus == 'PAYMENT_SUCCESS' ||
                    status.status == 'PAYMENT_SUCCESS'
                ? 'Your payment is successful. We are waiting for the final '
                      'confirmation from the hotel.'
                : 'Your booking is still being processed.';
          }
        });
        if (success || failure) break;
      } on HoneymoonApiException catch (e) {
        if (!mounted || session != _pollSession) return;
        final denied =
            asString(readKey(e.data, 'source')).toUpperCase() == 'TRIPJACK' &&
            digPath(e.data, ['status', 'success']) == false;
        if (denied) {
          setState(() {
            _phase = HotelBookingPhase.denied;
            _attempts = 0;
            _message =
                'The booking request was declined: '
                '${firstNonEmpty([readKey(e.data, 'error')], fallback: 'access denied')}';
            _errorCode = asString(digPath(e.data, ['errors', 0, 'errCode']));
          });
          break;
        }
        setState(() {
          _attempts = attempt;
          _message = 'We are waiting for the next status update.';
        });
      } catch (_) {
        if (!mounted || session != _pollSession) return;
        setState(() => _attempts = attempt);
      }
    }

    if (!mounted || session != _pollSession) return;
    setState(() {
      _polling = false;
      if (_phase == HotelBookingPhase.polling ||
          _phase == HotelBookingPhase.alreadyPaid) {
        _phase = HotelBookingPhase.timeout;
        _message = _status.rawStatus == 'PAYMENT_SUCCESS'
            ? 'Payment is successful and the booking is awaiting final hotel '
                  'confirmation. Please refresh the status after some time.'
            : 'Your booking is still processing. Please refresh the status '
                  'after some time.';
      }
    });
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  bool get _isHoldPending =>
      _status.isHoldPendingPayment ||
      (widget.fromHold &&
          !_status.isPaid &&
          const {
            'ON_HOLD',
            'IN_PROGRESS',
            'PENDING',
            'PAYMENT_PENDING',
            '',
          }.contains(_status.status));

  bool get _isConfirmed => _status.isConfirmed && !_isHoldPending;

  bool get _canFixAndRetry => const {
    HotelBookingPhase.failed,
    HotelBookingPhase.denied,
    HotelBookingPhase.alreadyPaid,
  }.contains(_phase);

  Future<void> _download(String kind) async {
    if (_documentLoading.isNotEmpty) return;
    setState(() => _documentLoading = kind);
    try {
      final path = kind == 'voucher'
          ? await widget.api.downloadHotelVoucher(widget.bookingId)
          : await widget.api.downloadHotelReceipt(widget.bookingId);
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
      if (mounted) setState(() => _documentLoading = '');
    }
  }

  /// Pays for a held room: payment order → Razorpay → `hotels/confirm-book`
  /// → poll. The web's `handlePayHoldBooking`.
  Future<void> _payHold() async {
    final payload = widget.holdPaymentPayload;
    if (payload == null || _documentLoading.isNotEmpty) return;
    setState(() => _documentLoading = 'hold');

    try {
      final order = await widget.api.createHotelPaymentOrder(payload);
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
        prefill: widget.prefill ?? (name: '', email: '', contact: ''),
      );
      if (!mounted) return;

      switch (outcome) {
        case RazorpayDismissed():
          AppSnackbar.error(context, 'Payment was cancelled.');
        case RazorpayFailure(:final message):
          AppSnackbar.error(context, message);
        case RazorpaySuccess(:final result):
          // The order can quote its own display amount; the reviewed amount
          // is the fallback, as on the web.
          final amount = asDouble(
            readKey(order.raw, 'displayAmount') ??
                readKey(order.raw, 'amountDisplay') ??
                digPath(payload, ['paymentInfos', 0, 'amount']),
          );
          final response = await widget.api.confirmHotelBooking({
            'bookingId': widget.bookingId,
            'paymentInfos': amount > 0
                ? [
                    {'amount': amount},
                  ]
                : (payload['paymentInfos'] ?? const []),
            ...result.toVerifyJson(),
          });
          if (!mounted) return;
          final orderStatus = hotelOrderStatusOf(response);
          setState(() {
            _paymentCaptured = true;
            _phase = HotelBookingPhase.polling;
            _message = kHotelSuccessStatuses.contains(orderStatus)
                ? 'The hotel confirmed this booking.'
                : 'Payment completed. Waiting for the final hotel confirmation.';
          });
          await _poll();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, bookingErrorText(e));
      setState(() {
        _phase = HotelBookingPhase.failed;
        _message = bookingErrorText(e);
      });
    } finally {
      if (mounted) setState(() => _documentLoading = '');
    }
  }

  void _leave() => Navigator.of(context).popUntil((route) => route.isFirst);

  void _viewTrips() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute(
        // BUG FIX: unwinding to the first route disposes the honeymoon home
        // page, which closes the shared API client — passing `widget.api`
        // here gave My trips a closed client ("Client is already closed").
        // Like the flight and cab flows, My trips now owns a fresh one.
        // builder: (_) =>
        //     MyTripsPage(api: widget.api, initialProduct: TravelProduct.hotel),
        builder: (_) => const MyTripsPage(initialProduct: TravelProduct.hotel),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        // With a fixable failure "back" means back to the form; otherwise
        // the checkout is spent and back unwinds it.
        if (_canFixAndRetry) {
          Navigator.pop(
            context,
            HotelBookingRetry(paymentCaptured: _paymentCaptured),
          );
        } else {
          _leave();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: _phase == HotelBookingPhase.denied
              ? 'Booking request declined'
              : 'Booking status',
          showBack: false,
          actions: [
            IconButton(
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded),
              onPressed: _leave,
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _poll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                _buildHero(),
                const SizedBox(height: AppSpacing.lg),
                if (_paymentCaptured &&
                    _phase != HotelBookingPhase.success) ...[
                  const InfoBanner(
                    tone: InfoTone.warning,
                    icon: Icons.payments_outlined,
                    message:
                        'Your payment has been received. Do not pay again — '
                        'if the booking cannot be confirmed, retrying uses the '
                        'payment already made.',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _ReferenceCard(reference: widget.bookingId),
                const SizedBox(height: AppSpacing.lg),
                _buildSummary(),
                const SizedBox(height: AppSpacing.xl),
                ..._buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero() {
    final (icon, tint, headline) = switch (_phase) {
      HotelBookingPhase.success when _isHoldPending => (
        Icons.lock_clock_rounded,
        AppColors.info,
        'Your room is on hold',
      ),
      HotelBookingPhase.success => (
        Icons.check_circle_rounded,
        AppColors.successDark,
        'Booking confirmed',
      ),
      HotelBookingPhase.polling || HotelBookingPhase.alreadyPaid => (
        Icons.schedule_rounded,
        AppColors.info,
        'Confirming with the hotel',
      ),
      HotelBookingPhase.timeout => (
        Icons.hourglass_bottom_rounded,
        AppColors.warning,
        'Still being confirmed',
      ),
      HotelBookingPhase.denied => (
        Icons.block_rounded,
        AppColors.error,
        'Booking request declined',
      ),
      HotelBookingPhase.failed => (
        Icons.error_outline_rounded,
        AppColors.error,
        'Booking failed',
      ),
    };

    final message = _phase == HotelBookingPhase.success && _isHoldPending
        ? (_message.isNotEmpty
              ? _message
              : 'Pay before the deadline to confirm it.')
        : _message;

    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 40, color: tint),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(headline, style: AppText.displaySm, textAlign: TextAlign.center),
        if (message.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(message, style: AppText.bodySm, textAlign: TextAlign.center),
        ],
        if (_polling) ...[
          const SizedBox(height: AppSpacing.md),
          const AppLoader(size: 22, padding: EdgeInsets.zero),
          if (_attempts > 0) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Checked $_attempts of $_maxAttempts times',
              style: AppText.caption,
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildSummary() {
    final checkIn = DateTime.tryParse(_status.checkIn) ?? widget.query.checkIn;
    final checkOut =
        DateTime.tryParse(_status.checkOut) ?? widget.query.checkOut;
    final amount = _status.total > 0 ? _status.total : widget.amount;
    final statusCode = _status.status;

    final statusLabel = switch (_phase) {
      HotelBookingPhase.denied => 'Failed',
      HotelBookingPhase.alreadyPaid => 'Already paid – syncing status',
      _ => hotelStatusLabel(statusCode, userStatus: _status.userStatus),
    };
    final statusColor =
        kHotelSuccessStatuses.contains(statusCode) || statusCode == 'ON_HOLD'
        ? AppColors.successDark
        : kHotelFailureStatuses.contains(statusCode) ||
              _phase == HotelBookingPhase.denied ||
              _phase == HotelBookingPhase.failed
        ? AppColors.error
        : AppColors.warning;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _status.hotelName.isNotEmpty ? _status.hotelName : widget.hotelName,
            style: AppText.sectionTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            _status.roomName.isNotEmpty ? _status.roomName : widget.roomName,
            style: AppText.cardSubtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.lg),
          DetailRow(
            label: 'Status',
            value: statusLabel,
            valueStyle: AppText.bodyStrong.copyWith(color: statusColor),
          ),
          DetailRow(
            label: 'Check-in',
            value: formatTripDate(checkIn),
            icon: Icons.login_rounded,
          ),
          DetailRow(
            label: 'Check-out',
            value: formatTripDate(checkOut),
            icon: Icons.logout_rounded,
          ),
          if (amount > 0)
            DetailRow(
              label: 'Amount',
              value: formatHotelFare(amount, currency: _status.currency),
              valueStyle: AppText.priceSm,
            ),
          if (_isHoldPending && _status.deadline.isNotEmpty)
            DetailRow(
              label: 'Pay before',
              value: formatPolicyDateTime(_status.deadline),
            ),
          if (_status.createdOn.isNotEmpty)
            DetailRow(label: 'Created on', value: _status.createdOn),
          if (_status.email.isNotEmpty)
            DetailRow(label: 'Contact email', value: _status.email),
          if (_status.phone.isNotEmpty)
            DetailRow(label: 'Contact phone', value: _status.phone),
          if (_errorCode.isNotEmpty)
            DetailRow(label: 'Error code', value: _errorCode),
        ],
      ),
    );
  }

  List<Widget> _buildActions() {
    final busy = _documentLoading.isNotEmpty;
    final buttons = <Widget>[
      if (_canFixAndRetry)
        PremiumButton(
          label: 'Fix details & retry',
          icon: Icons.edit_outlined,
          onPressed: () => Navigator.pop(
            context,
            HotelBookingRetry(paymentCaptured: _paymentCaptured),
          ),
        ),
      if (_isHoldPending && widget.holdPaymentPayload != null)
        PremiumButton(
          label: 'Pay & confirm booking',
          icon: Icons.lock_open_rounded,
          isLoading: _documentLoading == 'hold',
          enabled: !busy,
          onPressed: _payHold,
        ),
      if (_isConfirmed) ...[
        PremiumButton.outlined(
          label: 'Download voucher',
          icon: Icons.picture_as_pdf_outlined,
          isLoading: _documentLoading == 'voucher',
          enabled: !busy,
          onPressed: () => _download('voucher'),
        ),
        PremiumButton.outlined(
          label: 'Download receipt',
          icon: Icons.receipt_long_outlined,
          isLoading: _documentLoading == 'receipt',
          enabled: !busy,
          onPressed: () => _download('receipt'),
        ),
      ],
      if (_phase != HotelBookingPhase.success || _isHoldPending)
        PremiumButton.outlined(
          label: _polling ? 'Checking status…' : 'Refresh status',
          icon: Icons.refresh_rounded,
          enabled: !_polling,
          onPressed: _poll,
        ),
      PremiumButton.outlined(
        label: 'View my trips',
        icon: Icons.confirmation_number_outlined,
        onPressed: _viewTrips,
      ),
      PremiumButton.text(label: 'Done', onPressed: _leave),
    ];

    return [
      for (var i = 0; i < buttons.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.md),
        buttons[i],
      ],
    ];
  }
}

/// The booking id, large and copyable — the one string support will ask for.
class _ReferenceCard extends StatelessWidget {
  const _ReferenceCard({required this.reference});

  final String reference;

  @override
  Widget build(BuildContext context) {
    if (reference.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Booking ID', style: AppText.caption),
                const SizedBox(height: AppSpacing.xxs),
                SelectableText(
                  reference,
                  style: AppText.sectionTitle.copyWith(letterSpacing: 0.4),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy booking ID',
            icon: const Icon(Icons.copy_rounded, size: 19),
            color: AppColors.primary,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: reference));
              if (context.mounted) {
                AppSnackbar.success(context, 'Booking ID copied');
              }
            },
          ),
        ],
      ),
    );
  }
}
