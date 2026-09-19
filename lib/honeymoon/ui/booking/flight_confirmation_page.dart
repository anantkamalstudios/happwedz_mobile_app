/// The end of the flight funnel — the web's `BookingConfirmation.jsx`.
///
/// What it does that the shared confirmation screen cannot:
///
///  * waits for the airline PNR on this screen — `booking-details` every 9 s,
///    giving up after 3 minutes with a support message — and shows each
///    traveller's PNR and ticket number per route as they land;
///  * for a blocked (held) fare: the hold deadline, "UnHold" (release) and
///    "Proceed to pay", which tickets the held PNR;
///  * "More options": Download as PDF, Print Tickets (with the web's print
///    dialog), Email Ticket, and the way to My Bookings;
///  * the itinerary, the passenger table with seat / meal / baggage per leg,
///    the fare summary, and the important-information list with the
///    carrier's conditions of carriage.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/addon_models.dart';
import '../../models/booking_models.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import '../bookings/my_trips_page.dart';
import '../widgets/flight_ticket.dart';
import '../widgets/flight_widgets.dart';
import 'booking_widgets.dart';
import 'flight_hold_payment.dart';

enum _PnrWait { idle, waiting, gaveUp }

class FlightConfirmationPage extends StatefulWidget {
  const FlightConfirmationPage({
    super.key,
    required this.api,
    required this.outcome,
    required this.trip,
    required this.legs,
    required this.travellers,
    required this.addOns,
    required this.fare,
    required this.contact,
    required this.held,
    this.gst,
    this.agentNote = '',
  });

  final HoneymoonApi api;
  final BookingOutcome outcome;
  final FlightTripContext trip;
  final List<PricedLeg> legs;
  final List<TravellerInput> travellers;
  final FlightAddOns addOns;
  final FareBreakdown fare;
  final ContactDetails contact;
  final GstDetails? gst;
  final String agentNote;

  /// What "Proceed to pay" sends for a held fare.
  final HeldFlight held;

  @override
  State<FlightConfirmationPage> createState() => _FlightConfirmationPageState();
}

class _FlightConfirmationPageState extends State<FlightConfirmationPage> {
  static const _pollEvery = Duration(seconds: 9);
  static const _giveUpAfter = Duration(minutes: 3);

  late bool _onHold = widget.outcome.onHold;
  bool _released = false;
  String _actionError = '';

  /// `release`, `pay`, `email`, `pdf`, `print` — whichever action is running.
  String _busy = '';

  /// Travellers as booking-details last returned them — where PNRs land.
  late List<BookedTraveller> _paxInfos = _initialPaxInfos();
  _PnrWait _pnrWait = _PnrWait.idle;
  Timer? _pollTimer;
  DateTime? _pollStarted;

  String get _bookingRef => widget.outcome.reference;

  Map<String, dynamic> get _raw => widget.outcome.raw;

  @override
  void initState() {
    super.initState();
    _startPnrWait(initial: true);
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  /// `travellers` is what the book and hold endpoints send; the two raw shapes
  /// are the same data as persisted — the paid path stores booking-details
  /// directly, the hold path nests it under `details`.
  List<BookedTraveller> _initialPaxInfos() {
    final list = asList(readKey(_raw, 'travellers')).isNotEmpty
        ? asList(readKey(_raw, 'travellers'))
        : asList(
            digPath(_raw, ['raw_order', 'itemInfos', 'AIR', 'travellerInfos']),
          ).isNotEmpty
        ? asList(
            digPath(_raw, ['raw_order', 'itemInfos', 'AIR', 'travellerInfos']),
          )
        : asList(
            digPath(_raw, [
              'raw_order',
              'details',
              'itemInfos',
              'AIR',
              'travellerInfos',
            ]),
          );
    return [for (final t in list) BookedTraveller(asJsonMap(t))];
  }

  // -------------------------------------------------------------------------
  // PNR wait
  // -------------------------------------------------------------------------

  /// A held or freshly booked itinerary sits at PENDING until the airline
  /// issues a PNR. One call per 9 s stays well inside the backend's 30 a
  /// minute, and the wait stops the moment a PNR lands.
  void _startPnrWait({bool initial = false}) {
    if (_bookingRef.isEmpty || FlightBookingDetails.hasPnrs(_paxInfos)) return;
    _pollTimer?.cancel();
    _pollStarted = DateTime.now();
    if (initial) {
      _pnrWait = _PnrWait.waiting;
    } else {
      setState(() => _pnrWait = _PnrWait.waiting);
    }
    _pollTimer = Timer(_pollEvery, _pollOnce);
  }

  Future<void> _pollOnce() async {
    if (!mounted) return;
    try {
      final details = await widget.api.fetchFlightBooking(_bookingRef);
      if (!mounted) return;
      if (details.travellers.isNotEmpty) {
        setState(() => _paxInfos = details.travellers);
      }
      if (!details.isAwaitingPnr) {
        setState(() => _pnrWait = _PnrWait.idle);
        return;
      }
    } catch (_) {
      // A blip must not end the wait; the elapsed check still bounds it.
    }
    if (!mounted) return;
    if (DateTime.now().difference(_pollStarted!) > _giveUpAfter) {
      setState(() => _pnrWait = _PnrWait.gaveUp);
      return;
    }
    _pollTimer = Timer(_pollEvery, _pollOnce);
  }

  // -------------------------------------------------------------------------
  // Actions
  // -------------------------------------------------------------------------

  Future<void> _unhold() async {
    final ok = await ConfirmPopup.show(
      context,
      title: 'Release this held seat?',
      message: 'This cannot be undone.',
      confirmLabel: 'UnHold',
      cancelLabel: 'Keep it',
      icon: Icons.lock_open_rounded,
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      _busy = 'release';
      _actionError = '';
    });
    try {
      await widget.api.releaseHeldFlight(_bookingRef);
      if (!mounted) return;
      _pollTimer?.cancel();
      setState(() {
        _released = true;
        _pnrWait = _PnrWait.idle;
      });
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        setState(
          () => _actionError = e.message.isEmpty
              ? 'Could not release this hold. Please contact support.'
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  /// "Proceed to pay" on a held fare — tickets the held PNR.
  Future<void> _payHeld() async {
    setState(() {
      _busy = 'pay';
      _actionError = '';
    });
    final result = await payHeldFlight(
      context,
      api: widget.api,
      held: widget.held,
    );
    if (!mounted) return;
    setState(() {
      _busy = '';
      if (result.paid) {
        _onHold = false;
      } else if (result.error != null) {
        _actionError = result.error!;
      }
    });
    if (result.paid) {
      AppSnackbar.success(
        context,
        'Payment received — ticketing your booking.',
      );
      _startPnrWait();
    }
  }

  Future<void> _emailTicket() async {
    setState(() {
      _busy = 'email';
      _actionError = '';
    });
    try {
      await widget.api.emailFlightTicket(_bookingRef);
      if (mounted) AppSnackbar.success(context, 'Ticket sent to your email.');
    } on HoneymoonApiException catch (e) {
      if (mounted) {
        setState(
          () => _actionError = e.message.isEmpty
              ? 'Could not send the ticket. Please try again.'
              : e.message,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _downloadPdf() async {
    setState(() => _busy = 'pdf');
    try {
      await shareFlightTicket(_ticketData());
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not create the ticket PDF.');
      }
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _printTickets() async {
    final data = _ticketData();
    final options = await showPrintTicketSheet(context, data);
    if (options == null || !mounted) return;
    setState(() => _busy = 'print');
    try {
      await printFlightTicket(data, options);
    } catch (e) {
      if (mounted) AppSnackbar.error(context, 'Could not open printing.');
    } finally {
      if (mounted) setState(() => _busy = '');
    }
  }

  Future<void> _openMoreOptions() async {
    Widget row(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      String? note,
    }) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          icon,
          color: onTap == null ? AppColors.textTertiary : AppColors.primary,
        ),
        title: Text(label),
        subtitle: note == null ? null : Text(note, style: AppText.caption),
        enabled: onTap != null,
        onTap: onTap == null
            ? null
            : () {
                Navigator.pop(context);
                onTap();
              },
      );
    }

    await AppBottomSheet.show<void>(
      context,
      title: 'More options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          row(Icons.picture_as_pdf_outlined, 'Download as PDF', _downloadPdf),
          row(Icons.print_outlined, 'Print Tickets', _printTickets),
          row(
            Icons.mail_outline_rounded,
            'Email Ticket',
            _bookingRef.isEmpty ? null : _emailTicket,
          ),
          // Not wired on the web either: each needs a provider with
          // registered templates.
          row(
            Icons.sms_outlined,
            'SMS Ticket',
            null,
            note: 'Needs an SMS provider with DLT-registered templates',
          ),
          row(
            Icons.chat_outlined,
            'WhatsApp Me',
            null,
            note: 'Needs the WhatsApp Business API with approved templates',
          ),
          row(Icons.list_alt_rounded, 'Go to My Bookings', _goToMyBookings),
        ],
      ),
    );
  }

  void _goToMyBookings() {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const MyTripsPage(initialProduct: TravelProduct.flight),
      ),
    );
  }

  void _bookAnother() =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  // -------------------------------------------------------------------------
  // Data
  // -------------------------------------------------------------------------

  Map<String, String> get _segRoutes => {
    for (final leg in widget.legs)
      for (final s in asList(readKey(leg.trip, 'sI')))
        asString(readKey(s, 'id')):
            '${asString(digPath(s, ['da', 'code']))}-'
            '${asString(digPath(s, ['aa', 'code']))}',
  };

  /// Route → "Seat - 6F", "Veg Meal", "15 Kg" for passenger [i] — seats
  /// first, then meals and baggage, as the web lists them.
  Map<String, List<String>> _prefsFor(int i, {bool seatFirst = true}) {
    final routes = _segRoutes;
    final byRoute = <String, List<String>>{};
    void push(String segId, String text) {
      if (text.isEmpty) return;
      (byRoute[routes[segId] ?? segId] ??= []).add(text);
    }

    void seats() {
      for (final e in (widget.addOns.seats[i] ?? {}).entries) {
        push(e.key, seatFirst ? 'Seat - ${e.value.code}' : e.value.code);
      }
    }

    void ssr(Map<int, Map<String, Map<String, SsrChoice>>> kind) {
      for (final e in (kind[i] ?? {}).entries) {
        push(
          e.key,
          e.value.values
              .where((c) => c.qty > 0)
              .map(
                (c) => c.qty > 1
                    ? '${c.desc.isEmpty ? c.code : c.desc} × ${c.qty}'
                    : (c.desc.isEmpty ? c.code : c.desc),
              )
              .join(', '),
        );
      }
    }

    if (seatFirst) {
      seats();
      ssr(widget.addOns.meals);
      ssr(widget.addOns.baggage);
    } else {
      ssr(widget.addOns.baggage);
      ssr(widget.addOns.meals);
      seats();
    }
    return byRoute;
  }

  /// The booked traveller behind form row [i]: matched on name, else by
  /// position.
  BookedTraveller? _infoFor(int i) {
    final t = widget.travellers[i];
    for (final p in _paxInfos) {
      if (p.firstName.toUpperCase() == t.firstName.toUpperCase() &&
          p.lastName.toUpperCase() == t.lastName.toUpperCase()) {
        return p;
      }
    }
    return i < _paxInfos.length ? _paxInfos[i] : null;
  }

  FlightTicketData _ticketData() => FlightTicketData(
    bookingId: _bookingRef.isEmpty ? '—' : _bookingRef,
    createdAt: _createdAt,
    onHold: _onHold && !_released,
    legs: widget.legs,
    passengers: [
      for (final t in widget.travellers)
        (
          title: t.title,
          firstName: t.firstName,
          lastName: t.lastName,
          paxType: t.type.code,
          dob: t.dob == null ? '' : apiDate(t.dob!),
          passport: t.passportNumber,
          frequentFlyer: t.frequentFlyerNumber,
        ),
    ],
    paxInfos: _paxInfos,
    preferences: {
      for (var i = 0; i < widget.travellers.length; i++)
        i: _prefsFor(i, seatFirst: false),
    },
    addOnTotal: widget.addOns.total,
    contactEmail: firstNonEmpty([
      readKey(_raw, 'contact_email'),
      widget.contact.email,
    ]),
    contactPhone: firstNonEmpty([
      readKey(_raw, 'contact_phone'),
      '${widget.contact.countryCode} ${widget.contact.mobile}',
    ]),
    gstCompany: widget.gst?.companyName ?? '',
    gstNumber: widget.gst?.gstNumber ?? '',
    gstAddress: widget.gst?.address ?? '',
    agentNote: widget.agentNote,
  );

  DateTime? get _createdAt =>
      DateTime.tryParse(asString(readKey(_raw, 'created_at')));

  /// The web reads `deadline` off the hold response.
  DateTime? get _deadline => DateTime.tryParse(
    firstNonEmpty([readKey(_raw, 'deadline'), readKey(_raw, 'hold_deadline')]),
  );

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final heldNow = _onHold && !_released;
    final statusWord = _released
        ? 'Released'
        : heldNow
        ? 'On Hold'
        : 'Confirmed';

    return PopScope(
      // A finished booking must not be left by swiping back into a spent
      // checkout — the explicit actions below are the ways out.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _bookAnother();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          title: 'Booking $statusWord',
          showBack: false,
          actions: [
            IconButton(
              tooltip: 'More options',
              onPressed: _busy.isEmpty ? _openMoreOptions : null,
              icon: const Icon(Icons.more_vert_rounded),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _bookAnother,
              icon: const Icon(Icons.close_rounded),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxxl,
          ),
          children: [
            _statusBand(statusWord, heldNow),
            const SizedBox(height: AppSpacing.md),
            _optionsRow(),
            const SizedBox(height: AppSpacing.lg),

            for (var i = 0; i < widget.legs.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.md),
              FlightItineraryCard(
                title: widget.trip.legTitle(i, widget.legs.length),
                trip: widget.legs[i].trip,
                fare: widget.legs[i].fare,
              ),
            ],
            const SizedBox(height: AppSpacing.md),

            FormSection(
              title: 'Passenger Details',
              subtitle: '(${widget.travellers.length})',
              icon: Icons.people_outline_rounded,
              children: [
                for (var i = 0; i < widget.travellers.length; i++) ...[
                  if (i > 0)
                    const Divider(
                      height: AppSpacing.xl,
                      color: AppColors.divider,
                    ),
                  _passengerRow(i),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            if (!widget.fare.isEmpty)
              FormSection(
                title: 'Fare Summary',
                icon: Icons.receipt_outlined,
                children: [
                  for (final line in widget.fare.lines) ...[
                    FareRow(line: line, formatter: formatFlightFare),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const Divider(height: 1, color: AppColors.divider),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Amount to Pay', style: AppText.bodyStrong),
                      ),
                      Text(
                        formatFlightFare(widget.fare.total),
                        style: AppText.price,
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: AppSpacing.md),
            _importantInfo(),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: PremiumButton.outlined(
                    label: 'Go to My Bookings',
                    size: PremiumButtonSize.medium,
                    onPressed: _goToMyBookings,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumButton.outlined(
                    label: 'Book Another Flight',
                    size: PremiumButtonSize.medium,
                    onPressed: _bookAnother,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBand(String statusWord, bool heldNow) {
    final color = _released
        ? AppColors.textSecondary
        : heldNow
        ? AppColors.warning
        : AppColors.successDark;
    final deadline = _deadline;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _released
                    ? Icons.lock_open_rounded
                    : heldNow
                    ? Icons.hourglass_top_rounded
                    : Icons.check_circle_rounded,
                color: color,
                size: 38,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        style: AppText.sectionTitle,
                        children: [
                          const TextSpan(text: 'Booking '),
                          TextSpan(
                            text: statusWord,
                            style: TextStyle(color: color),
                          ),
                        ],
                      ),
                    ),
                    Text(_createdStamp(_createdAt), style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Text('Booking ID  ', style: AppText.caption),
              Expanded(
                child: SelectableText(
                  _bookingRef.isEmpty ? '—' : _bookingRef,
                  style: AppText.bodyStrong,
                ),
              ),
              if (_bookingRef.isNotEmpty)
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _bookingRef));
                    AppSnackbar.info(context, 'Booking ID copied.');
                  },
                ),
            ],
          ),
          if (heldNow) ...[
            Text(
              'ⓘ Price might change as per airline rules',
              style: AppText.caption.copyWith(color: AppColors.warning),
            ),
            const SizedBox(height: AppSpacing.xs),
            if (deadline == null)
              Text(
                "We didn't receive any hold time limit. Kindly check with "
                'operations team.',
                style: AppText.caption.copyWith(color: AppColors.error),
              )
            else
              Text(
                'Pay before ${_createdStamp(deadline)} to confirm.',
                style: AppText.bodyStrong,
              ),
          ],
          if (_actionError.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            InfoBanner(
              tone: InfoTone.error,
              icon: Icons.error_outline_rounded,
              message: _actionError,
            ),
          ],
          if (heldNow) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: PremiumButton.outlined(
                    label: _busy == 'release' ? 'Releasing…' : 'UnHold',
                    size: PremiumButtonSize.medium,
                    onPressed: _busy.isEmpty ? _unhold : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: PremiumButton(
                    label: 'Proceed to pay',
                    size: PremiumButtonSize.medium,
                    isLoading: _busy == 'pay',
                    onPressed: _busy.isEmpty ? _payHeld : null,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _optionsRow() {
    Widget chip(IconData icon, String label, String key, VoidCallback onTap) {
      final running = _busy == key;
      return ActionChip(
        avatar: running
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

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children: [
        chip(
          Icons.picture_as_pdf_outlined,
          'Download PDF',
          'pdf',
          _downloadPdf,
        ),
        chip(Icons.print_outlined, 'Print', 'print', _printTickets),
        if (_bookingRef.isNotEmpty)
          chip(
            Icons.mail_outline_rounded,
            'Email Ticket',
            'email',
            _emailTicket,
          ),
      ],
    );
  }

  Widget _passengerRow(int i) {
    final t = widget.travellers[i];
    final info = _infoFor(i);
    final pnrs = info?.pnrs ?? const <String, String>{};
    final tickets = info?.ticketNumbers ?? const <String, String>{};
    final prefs = _prefsFor(i);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${i + 1}. ${t.title} ${t.fullName} (${t.type.initial})',
          style: AppText.bodyStrong,
        ),
        Text(
          [
            if (t.dob != null) flightShortDate(t.dob),
            if (t.passportNumber.isNotEmpty) t.passportNumber.toUpperCase(),
            if (t.frequentFlyerNumber.isNotEmpty) 'FF ${t.frequentFlyerNumber}',
          ].join(', '),
          style: AppText.caption,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text('PNR, Ticket No. & Status', style: AppText.labelSm),
        if (pnrs.isNotEmpty)
          for (final e in pnrs.entries)
            Text.rich(
              TextSpan(
                style: AppText.bodySm,
                children: [
                  TextSpan(
                    text: '${e.key}: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: e.value,
                    style: const TextStyle(
                      color: AppColors.successDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (tickets[e.key] != null)
                    TextSpan(text: '  ·  Ticket ${tickets[e.key]}'),
                ],
              ),
            )
        else if (_released)
          Text('—', style: AppText.caption)
        else if (_pnrWait == _PnrWait.gaveUp)
          Text(
            'Not issued yet — contact support with the booking ID.',
            style: AppText.caption.copyWith(color: AppColors.error),
          )
        else
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Awaiting airline PNR…', style: AppText.caption),
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
        Text('Meal, Baggage, Seat & Other Preference', style: AppText.labelSm),
        if (prefs.isEmpty)
          Text('NA', style: AppText.caption)
        else
          for (final e in prefs.entries)
            Text('${e.key}: ${e.value.join(', ')}', style: AppText.caption),
      ],
    );
  }

  Widget _importantInfo() {
    final firstSeg = asList(
      readKey(widget.legs.firstOrNull?.trip, 'sI'),
    ).firstOrNull;
    final code = asString(digPath(firstSeg, ['fD', 'aI', 'code']));
    final name = asString(digPath(firstSeg, ['fD', 'aI', 'name']));
    final link = kCarrierTerms[code];

    return FormSection(
      title: 'IMPORTANT INFORMATION',
      icon: Icons.info_outline_rounded,
      children: [
        for (final line in kFlightImportantInfo)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('• $line', style: AppText.bodySm),
          ),
        if (link != null)
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse(link),
              mode: LaunchMode.externalApplication,
            ),
            child: Text.rich(
              TextSpan(
                style: AppText.bodySm,
                children: [
                  TextSpan(
                    text:
                        '• Please read the Conditions of Carriage as directed '
                        'by $name: ',
                  ),
                  TextSpan(
                    text: link,
                    style: const TextStyle(
                      color: AppColors.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// The web's created-on stamp — shared with the ticket.
String _createdStamp(DateTime? value) => flightBookingStamp(value);

// Previous local copy, kept for reference:
// /// "Aug 27, 2026 5:11 PM" — the web's created-on stamp.
// String _createdStamp(DateTime? value) {
//   const months = [
//     'Jan',
//     'Feb',
//     'Mar',
//     'Apr',
//     'May',
//     'Jun',
//     'Jul',
//     'Aug',
//     'Sep',
//     'Oct',
//     'Nov',
//     'Dec',
//   ];
//   final d = value ?? DateTime.now();
//   final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
//   return '${months[d.month - 1]} ${d.day}, ${d.year} $h:'
//       '${d.minute.toString().padLeft(2, '0')} ${d.hour >= 12 ? 'PM' : 'AM'}';
// }
