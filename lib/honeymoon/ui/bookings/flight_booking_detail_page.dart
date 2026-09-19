/// One flight booking in full — the web's `BookingDetailPage.jsx`
/// (`/honeymoon/flights/my-booking/:orderId`) together with the dashboard's
/// `FlightBookingDetail.jsx` (`/user-dashboard/my-bookings/:orderId`).
///
/// ```
/// loads     booking-details + booking-record, side by side; an amendment
///           already raised is polled straight away
/// header    route, status, trip type · cabin
/// held      the hold banner, Pay & Confirm (tickets the held PNR), Release
/// sections  Cart Information · Booking Details (itinerary, passengers with
///           PNR / GDS PNR / ticket no., fare summary) · Payment Process ·
///           User Information · Fare Rules (BOOKING_DETAIL, on first open) ·
///           Cart Amendments (raise cancellation, cancel quotation, the
///           amendment's status)
/// actions   Email ticket · ticket PDF / print · invoice · book return
/// ```
///
/// Flights used to open the shared [TripDetailPage], which read travellers
/// from the wrong place, printed a PNR map as text, guessed the cancel-quote
/// keys, cancelled without a reason and marked the booking cancelled on the
/// spot.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import '../booking/booking_widgets.dart';
import '../booking/flight_hold_payment.dart';
import '../flight_results_page.dart';
import '../widgets/flight_ticket.dart';
import '../widgets/flight_widgets.dart';
import '../widgets/honeymoon_widgets.dart';
import 'flight_cancellation_page.dart';

class FlightBookingDetailPage extends StatefulWidget {
  const FlightBookingDetailPage({
    super.key,
    required this.api,
    required this.booking,
  });

  final HoneymoonApi api;

  /// The `my-bookings` row — shown at once, and the fallback when the
  /// supplier lookup fails.
  final TravelBooking booking;

  @override
  State<FlightBookingDetailPage> createState() =>
      _FlightBookingDetailPageState();
}

class _FlightBookingDetailPageState extends State<FlightBookingDetailPage> {
  FlightBookingDetails? _details;
  FlightBookingRecord? _record;
  bool _loading = true;
  String? _error;

  /// A status set here after an action (paid, released, cancelled) wins over
  /// the loaded one until the next reload.
  String? _statusOverride;
  bool _cancelRequested = false;

  // Fare rules — BOOKING_DETAIL, on first open.
  Future<FareRuleSet>? _rules;

  // "Get Cancel Quotation".
  FlightCancelQuote? _quote;
  bool _quoteLoading = false;
  String? _quoteError;
  String _amendInfo = '';

  // Amendment information.
  Map<String, dynamic>? _cancelResult;
  FlightAmendment? _amendment;
  bool _amendmentLoading = false;

  /// `pay`, `release`, `email`, `pdf`, `print`, `invoice`.
  String _busy = '';

  String get _orderId => widget.booking.reference;
  Map<String, dynamic> get _row => widget.booking.raw;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // -------------------------------------------------------------------------
  // Loading
  // -------------------------------------------------------------------------

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    Future<T?> settle<T>(Future<T> f) async {
      try {
        return await f;
      } catch (e) {
        debugPrint('[FlightBookingDetail] $e');
        return null;
      }
    }

    final results = await Future.wait([
      settle(widget.api.fetchFlightBooking(_orderId)),
      settle(widget.api.fetchFlightRecord(_orderId)),
    ]);
    if (!mounted) return;

    final details = results[0] as FlightBookingDetails?;
    final record = results[1] as FlightBookingRecord?;
    setState(() {
      _details = details?.hasItinerary == true ? details : null;
      _record = record != null && record.isUsable ? record : null;
      _statusOverride = null;
      _loading = false;
      if (details == null && record == null) {
        _error = 'Could not load this booking.';
      }
    });

    // A cancellation raised earlier: load where it stands.
    final previous = _record?.amendmentId ?? '';
    if (previous.isNotEmpty) {
      _cancelResult = {
        'amendment_id': previous,
        'amendment_status': _record!.amendmentStatus,
      };
      await _pollAmendment();
    }
  }

  Future<void> _pollAmendment() async {
    final id = asString(readKey(_cancelResult, 'amendment_id'));
    if (id.isEmpty) return;
    setState(() => _amendmentLoading = true);
    try {
      final amendment = await widget.api.pollFlightAmendment(id);
      if (mounted) setState(() => _amendment = amendment);
    } catch (_) {
      // The request itself still shows; only the live status is missing.
    } finally {
      if (mounted) setState(() => _amendmentLoading = false);
    }
  }

  // -------------------------------------------------------------------------
  // Derived
  // -------------------------------------------------------------------------

  String get _rawStatus => firstNonEmpty([
    _statusOverride,
    _details?.status,
    _record?.bookingStatus,
    widget.booking.status,
  ]);

  FlightStatus get _status => flightStatusOf(_rawStatus);

  bool get _isCancelled => _status.key == FlightStatusKey.cancelled;
  bool get _isOnHold => _status.key == FlightStatusKey.hold;

  String get _razorpayOrderId => firstNonEmpty([
    readKey(_row, 'razorpay_order_id'),
    readKey(_record?.payment, 'razorpay_order_id'),
  ]);

  List<PricedLeg> get _legs {
    final d = _details;
    if (d == null) return const [];
    final fare = d.fare;
    return [for (final t in d.trips) (trip: t, fare: fare)];
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _payAndConfirm() async {
    setState(() => _busy = 'pay');
    final result = await payHeldFlight(
      context,
      api: widget.api,
      held: heldFlightFromRow(widget.booking),
    );
    if (!mounted) return;
    setState(() => _busy = '');
    if (result.paid) {
      setState(() => _statusOverride = 'confirmed');
      AppSnackbar.success(
        context,
        'Payment received — your booking is confirmed.',
      );
      await _load();
    } else if (result.error != null) {
      AppSnackbar.error(context, result.error!);
    }
  }

  Future<void> _release() async {
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
    setState(() => _busy = 'release');
    try {
      await widget.api.releaseHeldFlight(_orderId);
      if (!mounted) return;
      AppSnackbar.success(context, 'The held seat has been released.');
      await _load();
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

  Future<void> _raiseCancellation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      AnimatedPageRoute(
        page: FlightCancellationPage(
          api: widget.api,
          orderId: _orderId,
          provider: asString(readKey(_row, 'provider'), fallback: 'tripjack'),
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _cancelResult = result;
      if (readKey(result, 'cancelled') == true) {
        _statusOverride = 'cancelled';
      } else {
        _cancelRequested = true;
      }
    });
    await _pollAmendment();
  }

  Future<void> _getQuote() async {
    setState(() {
      _quoteLoading = true;
      _quote = null;
      _quoteError = null;
    });
    try {
      final quote = await widget.api.fetchFlightCancelQuote(
        _orderId,
        provider: asString(readKey(_row, 'provider'), fallback: 'tripjack'),
      );
      if (mounted) setState(() => _quote = quote);
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        setState(
          () => _quoteError = firstNonEmpty([
            readKey(e.data, 'message'),
          ], fallback: 'Could not fetch charges.'),
        );
      }
    } finally {
      if (mounted) setState(() => _quoteLoading = false);
    }
  }

  Future<void> _emailTicket() async {
    setState(() => _busy = 'email');
    try {
      await widget.api.emailFlightTicket(_orderId);
      if (mounted) AppSnackbar.success(context, 'Ticket sent to your email.');
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        AppSnackbar.error(
          context,
          e.message.isEmpty ? 'Could not send the ticket.' : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  FlightTicketData _ticketData() {
    final d = _details!;
    return FlightTicketData(
      bookingId: _orderId,
      createdAt: d.createdOn ?? _record?.bookedAt,
      onHold: _isOnHold,
      legs: _legs,
      passengers: [
        for (final t in d.travellers)
          (
            title: t.title,
            firstName: t.firstName,
            lastName: t.lastName,
            paxType: t.paxType,
            dob: t.dob,
            passport: t.passport,
            frequentFlyer: t.frequentFlyer,
          ),
      ],
      paxInfos: d.travellers,
      contactEmail: firstNonEmpty([
        readKey(_record?.contact, 'email'),
        d.emails.firstOrNull,
        readKey(_row, 'contact_email'),
      ]),
      contactPhone: firstNonEmpty([
        readKey(_record?.contact, 'phone'),
        d.contacts.firstOrNull,
        readKey(_row, 'contact_phone'),
      ]),
    );
  }

  Future<void> _ticketPdf({required bool print}) async {
    if (_details == null) return;
    final data = _ticketData();
    TicketPrintOptions options = const TicketPrintOptions();
    if (print) {
      final chosen = await showPrintTicketSheet(context, data);
      if (chosen == null || !mounted) return;
      options = chosen;
    }
    setState(() => _busy = print ? 'print' : 'pdf');
    try {
      if (print) {
        await printFlightTicket(data, options);
      } else {
        await shareFlightTicket(data, options);
      }
    } catch (_) {
      if (mounted) AppSnackbar.error(context, 'Could not create the ticket.');
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _invoice() async {
    setState(() => _busy = 'invoice');
    try {
      final path = await widget.api.downloadFlightInvoice(
        _razorpayOrderId,
        invoiceNumber: _orderId,
      );
      await OpenFilex.open(path);
    } on HoneymoonApiException catch (e) {
      if (mounted) AppSnackbar.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not download the invoice.');
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  void _bookReturn() =>
      openFlightReturnSearch(context, widget.api, widget.booking);

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        title: widget.booking.title.isEmpty
            ? 'Flight booking'
            : widget.booking.title,
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : _error != null
          ? ErrorState(
              title: 'Could not load this booking',
              message: _error,
              onRetry: _load,
            )
          : RefreshIndicator(
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
                  _header(),
                  const SizedBox(height: AppSpacing.md),
                  ..._banners(),
                  _actions(),
                  const SizedBox(height: AppSpacing.md),
                  _cartInformation(),
                  _bookingDetails(),
                  _paymentProcess(),
                  _userInformation(),
                  _fareRules(),
                  _cartAmendments(),
                ],
              ),
            ),
    );
  }

  Widget _header() {
    final s = _status;
    final tripType = asString(readKey(_row, 'trip_type'));
    final cabin = asString(readKey(_row, 'cabin_class'));
    final isRound =
        tripType == 'round_trip' ||
        tripType == 'round' ||
        (_details?.trips.length ?? 0) > 1;

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.flight_rounded, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.booking.title, style: AppText.cardTitle),
                Text(
                  [
                    isRound ? 'Round Trip' : 'One Way',
                    if (cabin.isNotEmpty) cabin,
                  ].join(' · '),
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          FlightStatusPill(status: s),
        ],
      ),
    );
  }

  List<Widget> _banners() {
    final out = <Widget>[];
    void add(Widget w) => out
      ..add(w)
      ..add(const SizedBox(height: AppSpacing.md));

    if (_isCancelled) {
      add(
        const InfoBanner(
          tone: InfoTone.error,
          icon: Icons.block_rounded,
          message: 'This booking has been cancelled.',
        ),
      );
    } else if (_cancelRequested) {
      add(
        const InfoBanner(
          tone: InfoTone.success,
          icon: Icons.check_circle_outline_rounded,
          message:
              'Your cancellation request has been submitted and is being '
              'processed. The refund will be confirmed shortly.',
        ),
      );
    } else if (_isOnHold) {
      add(
        const InfoBanner(
          tone: InfoTone.warning,
          icon: Icons.schedule_rounded,
          message:
              'This fare is on hold. Pay before the deadline to confirm your '
              'ticket.',
        ),
      );
    }
    return out;
  }

  Widget _actions() {
    final canAct = !_isCancelled && !_cancelRequested;
    final hasTicket = _details != null && !_isCancelled;

    Widget chip(IconData icon, String label, String key, VoidCallback onTap) {
      return ActionChip(
        avatar: _busy == key
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 16, color: AppColors.primary),
        label: Text(label),
        onPressed: _busy.isEmpty ? onTap : null,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (canAct && _isOnHold) ...[
          Row(
            children: [
              Expanded(
                child: PremiumButton.outlined(
                  label: _busy == 'release' ? 'Releasing…' : 'Release',
                  size: PremiumButtonSize.medium,
                  onPressed: _busy.isEmpty ? _release : null,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: PremiumButton(
                  label: 'Pay & Confirm',
                  icon: Icons.credit_card_rounded,
                  size: PremiumButtonSize.medium,
                  isLoading: _busy == 'pay',
                  onPressed: _busy.isEmpty ? _payAndConfirm : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            if (hasTicket && !_isOnHold) ...[
              chip(
                Icons.mail_outline_rounded,
                'Email ticket',
                'email',
                _emailTicket,
              ),
              chip(
                Icons.picture_as_pdf_outlined,
                'Ticket PDF',
                'pdf',
                () => _ticketPdf(print: false),
              ),
              chip(
                Icons.print_outlined,
                'Print ticket',
                'print',
                () => _ticketPdf(print: true),
              ),
            ],
            if (_razorpayOrderId.isNotEmpty)
              chip(
                Icons.receipt_long_outlined,
                'Download invoice',
                'invoice',
                _invoice,
              ),
            if (asString(readKey(_row, 'from_iata')).isNotEmpty &&
                asString(readKey(_row, 'to_iata')).isNotEmpty &&
                !_isOnHold)
              chip(
                Icons.u_turn_left_rounded,
                'Book return',
                'return',
                _bookReturn,
              ),
            if (canAct)
              ActionChip(
                avatar: const Icon(
                  Icons.block_rounded,
                  size: 16,
                  color: AppColors.error,
                ),
                label: const Text('Cancel booking'),
                onPressed: _busy.isEmpty ? _raiseCancellation : null,
              ),
          ],
        ),
      ],
    );
  }

  // --- Cart Information -------------------------------------------------------

  Widget _cartInformation() {
    final d = _details;
    final r = _record;
    final amount = (d != null && readKey(d.order, 'amount') != null)
        ? d.amount
        : asDouble(
            readKey(r?.payment, 'amount') ?? r?.price ?? widget.booking.amount,
          );
    final emails = _emails;

    return _Section(
      title: 'Cart Information : $_orderId',
      trailing: FlightStatusPill(status: _status),
      children: [
        _Field('Booking Id', _orderId, copy: true),
        _Field('Amount', formatFlightFare(amount)),
        _Field('Status', _rawStatus.isEmpty ? '—' : _rawStatus),
        const _Field('Order Type', 'Air'),
        const _Field('Channel Type', 'API'),
        const _Field('Flow Type', 'Online'),
        _Field(
          'Booking Date',
          formatTripDateTime(r?.bookedAt ?? widget.booking.bookedOn),
        ),
        _Field('Contact Email', emails.firstOrNull ?? '—'),
        if ((d?.orderNote ?? '').isNotEmpty) _Field('Note', d!.orderNote),
      ],
    );
  }

  List<String> get _emails {
    final contactEmail = asString(readKey(_record?.contact, 'email'));
    if (contactEmail.isNotEmpty) return [contactEmail];
    final fromOrder = _details?.emails ?? const <String>[];
    if (fromOrder.isNotEmpty) return fromOrder;
    final fromRow = asString(readKey(_row, 'contact_email'));
    return fromRow.isEmpty ? const [] : [fromRow];
  }

  List<String> get _contacts {
    final phone = asString(readKey(_record?.contact, 'phone'));
    if (phone.isNotEmpty) return [phone];
    final fromOrder = _details?.contacts ?? const <String>[];
    if (fromOrder.isNotEmpty) return fromOrder;
    final fromRow = asString(readKey(_row, 'contact_phone'));
    return fromRow.isEmpty ? const [] : [fromRow];
  }

  // --- Booking Details --------------------------------------------------------

  Widget _bookingDetails() {
    final d = _details;
    final legs = _legs;
    final passengers = _record?.passengers ?? const <Map<String, dynamic>>[];
    final travellers = d?.travellers ?? const <BookedTraveller>[];
    final count = passengers.isNotEmpty ? passengers.length : travellers.length;
    final fc = d?.fareComponents ?? const <String, dynamic>{};
    final fareType = firstNonEmpty([
      d?.fareIdentifier,
      readKey(_record?.booking, 'fare_type'),
    ]);

    return _Section(
      title: 'Booking Details',
      children: [
        if (legs.isNotEmpty)
          for (var i = 0; i < legs.length; i++) ...[
            FlightItineraryCard(
              title: legs.length > 1 ? (i == 0 ? 'Departure' : 'Return') : null,
              trip: legs[i].trip,
              fare: legs[i].fare,
            ),
            const SizedBox(height: AppSpacing.md),
          ]
        else
          Text(
            [
              asString(readKey(_row, 'airline')),
              asString(readKey(_row, 'flight_no')),
              widget.booking.title,
              formatTripDateTime(widget.booking.travelDate),
            ].where((s) => s.isNotEmpty).join(' · '),
            style: AppText.bodySm,
          ),

        for (var i = 0; i < count; i++) ...[
          _passenger(
            i,
            i < passengers.length ? passengers[i] : const {},
            i < travellers.length ? travellers[i] : null,
            fareType,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        if (fc.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text('Fare Summary', style: AppText.labelSm),
          _Field('Base Fare', _money(fc['BF'])),
          _Field('Taxes', _money(fc['TAF'])),
          _Field('Net Fare', _money(fc['NF'])),
          _Field('Gross Fare', _money(fc['TF'])),
          _Field('Commission', _money(fc['NCM'] ?? 0)),
          _Field('TJ Flex Fee', formatFlightFare(d?.flexFee ?? 0)),
        ],
      ],
    );
  }

  static String _money(Object? v) =>
      v == null || asString(v).isEmpty ? '—' : formatFlightFare(asDouble(v));

  Widget _passenger(
    int i,
    Map<String, dynamic> record,
    BookedTraveller? t,
    String fareType,
  ) {
    String pick(
      String key,
      String alt,
      String Function(BookedTraveller)? fromT,
    ) => firstNonEmpty([
      readKey(record, key),
      readKey(record, alt),
      if (t != null && fromT != null) fromT(t),
    ]);

    final last = pick('lN', 'last_name', (t) => t.lastName);
    final first = pick('fN', 'first_name', (t) => t.firstName);
    final title = pick('ti', 'ti', (t) => t.title);
    final type = pick('pt', 'pt', (t) => t.paxType);
    String join(Map<String, String>? m) =>
        m == null || m.isEmpty ? '—' : m.values.join(', ');

    return AppCard.outlined(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${i + 1}. ${'$last/$first $title'.trim()}',
                  style: AppText.bodyStrong,
                ),
              ),
              Text(type.isEmpty ? 'ADULT' : type, style: AppText.caption),
            ],
          ),
          _Field(
            'DOB',
            firstNonEmpty([readKey(record, 'dob'), t?.dob], fallback: '—'),
          ),
          _Field('Fare Type', fareType.isEmpty ? '—' : fareType),
          _Field(
            'Airline PNR',
            t != null && t.pnrs.isNotEmpty
                ? t.pnrs.entries.map((e) => '${e.key}: ${e.value}').join(', ')
                : asString(readKey(_record?.booking, 'pnr'), fallback: '—'),
          ),
          _Field('GDS PNR', join(t?.gdsPnrs)),
          _Field('Ticket Number', join(t?.ticketNumbers)),
          _Field(
            'Document ID',
            firstNonEmpty([
              t?.documentId,
              readKey(record, 'di'),
            ], fallback: '—'),
          ),
          _Field(
            'PAN Number',
            firstNonEmpty([t?.pan, readKey(record, 'pan')], fallback: '—'),
          ),
        ],
      ),
    );
  }

  // --- Payment Process --------------------------------------------------------

  Widget _paymentProcess() {
    final pay = _record?.payment;
    if (pay == null) {
      return const _Section(
        title: 'Payment Process',
        children: [Text('No payment record found.')],
      );
    }
    final status = asString(readKey(pay, 'payment_status'));
    return _Section(
      title: 'Payment Process',
      children: [
        _Field(
          'Created On',
          formatTripDateTime(
            DateTime.tryParse(asString(readKey(pay, 'created_at'))),
          ),
        ),
        const _Field('Medium', 'Razorpay'),
        _Field('Booking Id', _orderId),
        _Field('Amount Paid', _money(readKey(pay, 'amount'))),
        _Field('Status', status.isEmpty ? '—' : status),
        _Field(
          'Payment Id',
          asString(readKey(pay, 'razorpay_payment_id'), fallback: '—'),
          copy: true,
        ),
        _Field(
          'Razorpay Order',
          asString(readKey(pay, 'razorpay_order_id'), fallback: '—'),
          copy: true,
        ),
      ],
    );
  }

  // --- User Information -------------------------------------------------------

  Widget _userInformation() {
    return _Section(
      title: 'User Information',
      children: [
        _Field("Contact's Email", _emails.isEmpty ? '—' : _emails.join(', ')),
        _Field('Pax Contact', _contacts.isEmpty ? '—' : _contacts.join(', ')),
      ],
    );
  }

  // --- Fare Rules -------------------------------------------------------------

  Widget _fareRules() {
    return _Section(
      title: 'Fare Rules',
      initiallyOpen: false,
      onFirstOpen: () => setState(
        () => _rules ??= widget.api.fetchFareRules(_orderId, 'BOOKING_DETAIL'),
      ),
      children: [
        if (_rules == null)
          Text('Loading fare rules…', style: AppText.bodySm)
        else
          FareRulesLoaderView(future: _rules!),
      ],
    );
  }

  // --- Cart Amendments --------------------------------------------------------

  Widget _cartAmendments() {
    final quote = _quote;
    final result = _cancelResult;
    final amendment = _amendment;
    final amendmentStatus = firstNonEmpty([
      amendment?.status,
      readKey(result, 'amendment_status'),
    ]);

    Widget card(
      String title,
      String desc,
      VoidCallback? onRaise, {
      Widget? extra,
    }) {
      return AppCard.outlined(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: AppText.bodyStrong),
            Text(desc, style: AppText.caption),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                PremiumButton.text(
                  label: 'Raise Request',
                  size: PremiumButtonSize.small,
                  onPressed: onRaise,
                ),
                ?extra,
              ],
            ),
          ],
        ),
      );
    }

    void notOnline(String what) => setState(
      () => _amendInfo =
          '$what is not available online via the API — please contact '
          'support to raise this request.',
    );

    return _Section(
      title: 'Cart Amendments',
      children: [
        card(
          'Cancellation',
          'Check cancellation charges and refund eligibility before proceeding.',
          !_isCancelled && !_cancelRequested && _busy.isEmpty
              ? _raiseCancellation
              : null,
          extra: PremiumButton.text(
            label: _quoteLoading ? 'Loading…' : 'Get Cancel Quotation',
            size: PremiumButtonSize.small,
            onPressed: _quoteLoading ? null : _getQuote,
          ),
        ),
        for (final (title, desc) in const [
          (
            'Reissue',
            'Modify your booking details or change flight dates easily.',
          ),
          (
            'Ancillary Services',
            'Add extra baggage, meals, seat selection, and more to enhance '
                'your journey.',
          ),
          (
            'Miscellaneous',
            'Manage additional services related to your booking effortlessly.',
          ),
          (
            'Fare Change',
            'Handle services regarding change of fare details while booking '
                'tickets.',
          ),
        ]) ...[
          const SizedBox(height: AppSpacing.sm),
          card(title, desc, () => notOnline(title)),
        ],

        if (quote != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Cancellation Quotation', style: AppText.labelSm),
          if (!quote.available)
            Text(
              quote.message.isEmpty
                  ? 'Charges not available — please contact support.'
                  : quote.message,
              style: AppText.bodySm,
            )
          else ...[
            _Field('Cancellation Charges', _money(quote.amendmentCharges)),
            _Field('Refund Amount', _money(quote.refundAmount)),
            _Field('Total Fare', _money(quote.totalFare)),
          ],
        ],
        if (_quoteError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _quoteError!,
          ),
        ],
        if (_amendInfo.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.support_agent_rounded,
            message: _amendInfo,
          ),
        ],

        if (result != null || _amendmentLoading) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text('Amendment Information', style: AppText.labelSm),
              ),
              if (!_amendmentLoading &&
                  asString(readKey(result, 'amendment_id')).isNotEmpty)
                TextButton.icon(
                  onPressed: _pollAmendment,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Refresh'),
                ),
            ],
          ),
          if (_amendmentLoading)
            Text('Loading amendment details…', style: AppText.bodySm)
          else ...[
            _Field(
              'Amendment Type',
              asString(readKey(result, 'amendment_id')).isNotEmpty
                  ? 'CANCELLATION'
                  : '—',
            ),
            _Field(
              'Amendment Id',
              firstNonEmpty([
                amendment?.amendmentId,
                readKey(result, 'amendment_id'),
              ], fallback: '—'),
              copy: true,
            ),
            _Field(
              'Remarks',
              firstNonEmpty([
                amendment?.remarks,
                readKey(result, 'remarks'),
              ], fallback: '—'),
            ),
            Row(
              children: [
                Expanded(child: Text('Status', style: AppText.caption)),
                if (amendmentStatus.isEmpty)
                  Text('—', style: AppText.bodySm)
                else
                  FlightStatusPill(status: flightStatusOf(amendmentStatus)),
              ],
            ),
            if (amendment?.charges != null)
              _Field('Amendment Charges', _money(amendment!.charges)),
            if (amendment?.refundableAmount != null)
              _Field('Refundable Amount', _money(amendment!.refundableAmount)),
            if (amendment?.totalFare != null)
              _Field('Total Fare', _money(amendment!.totalFare)),
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Building blocks
// ---------------------------------------------------------------------------

/// A collapsible section — the web's `Section`, which can fetch on its first
/// open.
class _Section extends StatefulWidget {
  const _Section({
    required this.title,
    required this.children,
    this.trailing,
    this.initiallyOpen = true,
    this.onFirstOpen,
  });

  final String title;
  final List<Widget> children;
  final Widget? trailing;
  final bool initiallyOpen;
  final VoidCallback? onFirstOpen;

  @override
  State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  late bool _open = widget.initiallyOpen;
  late bool _opened = widget.initiallyOpen;

  void _toggle() {
    setState(() => _open = !_open);
    if (_open && !_opened) {
      _opened = true;
      widget.onFirstOpen?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: _toggle,
              borderRadius: AppRadii.rLg,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(widget.title, style: AppText.cardTitle),
                    ),
                    ?widget.trailing,
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            if (_open)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Label on the left, value on the right; long-press to copy when [copy].
class _Field extends StatelessWidget {
  const _Field(this.label, this.value, {this.copy = false});

  final String label;
  final String value;
  final bool copy;

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 130, child: Text(label, style: AppText.caption)),
          Expanded(child: Text(value, style: AppText.bodySm)),
          if (copy && value.isNotEmpty && value != '—')
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                AppSnackbar.info(context, '$label copied.');
              },
              child: const Padding(
                padding: EdgeInsets.only(left: AppSpacing.xs),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
        ],
      ),
    );
    return text;
  }
}

/// A flight status as the web's dashboard colours it.
class FlightStatusPill extends StatelessWidget {
  const FlightStatusPill({super.key, required this.status});

  final FlightStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status.key) {
      FlightStatusKey.confirmed => AppColors.successDark,
      FlightStatusKey.hold => AppColors.info,
      FlightStatusKey.pending => AppColors.warning,
      FlightStatusKey.cancelled || FlightStatusKey.failed => AppColors.error,
      FlightStatusKey.unknown => AppColors.textSecondary,
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

// ---------------------------------------------------------------------------
// Shared with My Trips
// ---------------------------------------------------------------------------

/// "Book Return": the search form, filled in one-way from this booking's
/// arrival airport back to its origin — `UpcomingBookings.jsx` `bookReturn`.
void openFlightReturnSearch(
  BuildContext context,
  HoneymoonApi api,
  TravelBooking booking,
) {
  final from = asString(readKey(booking.raw, 'from_iata'));
  final to = asString(readKey(booking.raw, 'to_iata'));
  if (from.isEmpty || to.isEmpty) return;
  final query = FlightSearchQuery(
    tripType: FlightTripKind.oneWay,
    from: FlightLocation(code: to, name: to),
    to: FlightLocation(code: from, name: from),
  );
  Navigator.push(
    context,
    AnimatedPageRoute(
      page: Scaffold(
        backgroundColor: AppColors.background,
        appBar: const AppTopBar(title: 'Book return', elevated: true),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            AppCard(
              child: FlightSearchForm(api: api, initialQuery: query),
            ),
          ],
        ),
      ),
      style: PageTransitionStyle.slideRight,
    ),
  );
}

/// "View Summary" — the travellers on a booking with their PNRs, ticket
/// numbers and status (`PassengerSummaryModal.jsx`).
Future<void> showFlightPassengerSummary(
  BuildContext context,
  HoneymoonApi api,
  TravelBooking booking, {
  VoidCallback? onViewFull,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Passenger Details',
    child: FutureBuilder<FlightBookingDetails>(
      future: api.fetchFlightBooking(booking.reference),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: AppLoader()),
          );
        }
        if (snap.hasError || snap.data == null) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Could not load passenger details.',
              style: AppText.bodySm,
            ),
          );
        }
        final d = snap.data!;
        var travellers = d.travellers;
        // Names may only be on the row when booking-details has none.
        final fallbackName = asString(readKey(booking.raw, 'passenger_name'));
        final status = d.status.isEmpty ? 'CONFIRMED' : d.status;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (travellers.isEmpty)
              Text(
                fallbackName.isEmpty ? 'No passengers listed.' : fallbackName,
                style: AppText.bodyStrong,
              ),
            for (var i = 0; i < travellers.length; i++) ...[
              if (i > 0)
                const Divider(height: AppSpacing.lg, color: AppColors.divider),
              Text(
                '${i + 1}. ${travellers[i].displayName.toUpperCase()} '
                '(${travellers[i].initial})',
                style: AppText.bodyStrong,
              ),
              Text(
                [
                  travellers[i].dob.isEmpty ? '—' : travellers[i].dob,
                  if (travellers[i].passport.isNotEmpty) travellers[i].passport,
                ].join(', '),
                style: AppText.caption,
              ),
              if (travellers[i].pnrs.isEmpty)
                Text('No PNR', style: AppText.caption)
              else
                for (final e in travellers[i].pnrs.entries)
                  Text('${e.key}: ${e.value}', style: AppText.bodySm),
              for (final e in travellers[i].ticketNumbers.entries)
                Text('Ticket ${e.key}: ${e.value}', style: AppText.caption),
              const SizedBox(height: AppSpacing.xs),
              Align(
                alignment: Alignment.centerLeft,
                child: FlightStatusPill(status: flightStatusOf(status)),
              ),
            ],
            if (onViewFull != null) ...[
              const SizedBox(height: AppSpacing.lg),
              PremiumButton.text(
                label: 'View full booking →',
                onPressed: () {
                  Navigator.pop(context);
                  onViewFull();
                },
              ),
            ],
          ],
        );
      },
    ),
  );
}
