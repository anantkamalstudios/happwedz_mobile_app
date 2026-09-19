/// The flight booking funnel.
///
/// ```
/// review (re-price, open session)
///   └─ 1 Trip        itinerary + what the fare includes
///      2 Travellers  passenger, contact, GST, emergency
///      3 Review      confirm → hold or pay → confirm screen
/// ```
///
/// The web client renders these as three sections of one long two-column page
/// with a fare rail on the right. On a phone each step is its own scroll view,
/// the rail becomes the sticky bottom bar, and the fare session countdown
/// moves into the app bar where it cannot collide with the form.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/addon_models.dart';
import '../../models/booking_models.dart';
import '../../models/flight_models.dart';
import '../../models/honeymoon_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../widgets/flight_widgets.dart';
import '../widgets/honeymoon_widgets.dart';
// import '../bookings/my_trips_page.dart'; // only the commented-out hand-off used it
// import 'booking_confirmation_page.dart'; // only the commented-out hand-off used it
import 'booking_widgets.dart';
import 'flight_addon_step.dart';
import 'flight_confirmation_page.dart';
import 'flight_traveller_step.dart';

class FlightBookingPage extends StatefulWidget {
  const FlightBookingPage({
    super.key,
    required this.api,
    required this.trip,
    required this.outbound,
    this.inbound,
    this.extraLegs = const [],
    this.initialReview,
  });

  /// Multi-city entry point: every chosen leg, in route order.
  ///
  /// A combined (COMBO) fare covers the whole journey on one priceId, so it
  /// arrives as a single leg and books exactly like a one-way.
  factory FlightBookingPage.multiCity({
    Key? key,
    required HoneymoonApi api,
    required FlightTripContext trip,
    required List<FlightResult> legs,
    FlightReview? initialReview,
  }) => FlightBookingPage(
    key: key,
    api: api,
    trip: trip,
    outbound: legs.first,
    inbound: legs.length > 1 ? legs[1] : null,
    extraLegs: legs.length > 2 ? legs.sublist(2) : const [],
    initialReview: initialReview,
  );

  final HoneymoonApi api;
  final FlightTripContext trip;
  final FlightResult outbound;

  /// The return leg on a round trip, or the second hop of a multi-city
  /// itinerary. Every leg is priced in one session.
  final FlightResult? inbound;

  /// Third and later hops of a multi-city itinerary.
  final List<FlightResult> extraLegs;

  /// The review the results screen already ran for these legs.
  ///
  /// The web reviews on the results page (`reviewAndGo`) so it can catch a
  /// gone fare there and refresh the list, and hands the response to the
  /// booking page as `reviewData`. Passing it on here means the session it
  /// opened is used instead of a second review opening another one.
  final FlightReview? initialReview;

  /// Every leg the session must price, in route order.
  List<FlightResult> get legs => [
    outbound,
    if (inbound != null) inbound!,
    ...extraLegs,
  ];

  @override
  State<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends State<FlightBookingPage> {
  static const _steps = ['Trip', 'Travellers', 'Add-ons', 'Review'];

  // --- Session -------------------------------------------------------------

  FlightReview? _review;
  bool _loadingReview = true;
  Object? _reviewError;
  bool _sessionExpired = false;

  // --- Wizard --------------------------------------------------------------

  int _step = 0;

  late List<TravellerInput> _travellers = widget.trip.buildTravellerForms();
  final ContactDetails _contact = ContactDetails();
  final EmergencyContact _emergency = EmergencyContact();
  GstDetails? _gst;

  /// "Add notes (Optional)" on the traveller step — sent as `remarks`.
  String _agentNote = '';

  /// Set when a re-price moved the fare; shown until dismissed, as the web's
  /// price-change alert above the steps.
  ({double before, double after})? _priceChange;

  /// Seats, meals and baggage picked on the add-on step. Held here rather
  /// than in the step so it survives stepping back and forth.
  final FlightAddOns _addOns = FlightAddOns();

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    final reviewed = widget.initialReview;
    if (reviewed != null && reviewed.isUsable) {
      _review = reviewed;
      _loadingReview = false;
    } else {
      _openSession();
    }
  }

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  /// One priceId per leg, de-duplicated.
  ///
  /// A COMBO multi-city fare repeats the same priceId across routes, and
  /// sending it twice is rejected, so identical ids collapse to one.
  List<String> get _priceIds {
    final ids = <String>[];
    for (final leg in widget.legs) {
      if (leg.id.isNotEmpty && !ids.contains(leg.id)) ids.add(leg.id);
    }
    return ids;
  }

  /// Re-prices the chosen fare and opens a booking session.
  ///
  /// This is also the recovery path when the session lapses: the same call
  /// produces a fresh `bookingId`, so a traveller who took too long does not
  /// have to search again.
  Future<void> _openSession({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loadingReview = true;
        _reviewError = null;
      });
    }

    try {
      final review = await widget.api.reviewFlight(_priceIds);
      if (!mounted) return;

      final previousTotal = _review?.totalFare ?? 0;
      setState(() {
        _review = review;
        _loadingReview = false;
        _sessionExpired = false;
        // Passenger requirements are fare-specific and may have changed with
        // the re-price, so the forms are rebuilt only if the party changed.
        if (_travellers.length != widget.trip.travellerCount) {
          _travellers = widget.trip.buildTravellerForms();
        }
      });

      // Re-pricing exists precisely because the fare can move. Saying so is
      // more honest than swapping the number the traveller already agreed to.
      final newTotal = review.totalFare;
      if (previousTotal > 0 &&
          newTotal > 0 &&
          (newTotal - previousTotal).abs() >= 1 &&
          mounted) {
        setState(() => _priceChange = (before: previousTotal, after: newTotal));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = e;
      });
    }
  }

  /// Minutes since the session was priced, for the expiry copy — the web's
  /// `elapsedMinutes`.
  int get _elapsedMinutes {
    final c = _review?.conditions;
    final started = c?.sessionStartedAt;
    if (started == null) return ((c?.sessionSeconds ?? 0) / 60).round();
    final minutes = DateTime.now().difference(started).inMinutes;
    return minutes < 1 ? 1 : minutes;
  }

  /// The web's `SessionExpiredModal`: Continue re-prices the same priceIds on
  /// a fresh session and restarts from the itinerary with any price change
  /// called out; Back returns to the flight list. When re-pricing fails the
  /// dialog says the fare is gone and only offers the way back.
  Future<void> _onSessionExpired() async {
    if (_sessionExpired || !mounted) return;
    setState(() => _sessionExpired = true);

    final continued = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SessionExpiredDialog(
        elapsedMinutes: _elapsedMinutes,
        onContinue: _reprice,
      ),
    );

    if (!mounted) return;
    // `pop`, not `maybePop`: the page intercepts back presses to step
    // backwards, and this has to leave for the flight list.
    if (continued != true) Navigator.of(context).pop();
  }

  /// `handleSessionContinue`: a fresh review of the same priceIds.
  Future<bool> _reprice() async {
    final before = _review?.totalFare ?? 0;
    try {
      final review = await widget.api.reviewFlight(_priceIds);
      if (!mounted) return false;
      final after = review.totalFare;
      setState(() {
        _review = review;
        _sessionExpired = false;
        _step = 0;
        _submitError = null;
        if (before > 0 && after > 0 && (after - before).abs() >= 1) {
          _priceChange = (before: before, after: after);
        }
      });
      return true;
    } catch (e) {
      debugPrint('[FlightBooking] re-price after expiry failed: $e');
      return false;
    }
  }

  // Previous expiry handler, kept for reference:
  //   Future<void> _onSessionExpired() async {
  //     if (_sessionExpired || !mounted) return;
  //     setState(() => _sessionExpired = true);
  //
  //     final refresh = await ConfirmPopup.show(
  //       context,
  //       title: 'Your fare has expired',
  //       message:
  //           'Airlines only hold a quoted price for a few minutes. We can check '
  //           'the current price for the same flight.',
  //       confirmLabel: 'Check price',
  //       cancelLabel: 'Go back',
  //       icon: Icons.timer_off_rounded,
  //     );
  //
  //     if (!mounted) return;
  //     if (refresh) {
  //       await _openSession();
  //       if (mounted && _reviewError == null) setState(() => _step = 0);
  //     } else if (mounted) {
  //       Navigator.of(context).maybePop();
  //     }
  //   }

  // -------------------------------------------------------------------------
  // Fare
  // -------------------------------------------------------------------------

  /// The fares the session actually priced, onward first.
  ///
  /// The review response wins over the search result: reading the search's
  /// `totalPriceList[0]` showed the cheapest fare on the card no matter which
  /// one the traveller picked.
  List<dynamic> get _fares {
    final review = _review;
    final fromReview = <dynamic>[];
    if (review != null) {
      for (final trip in review.trips) {
        final list = asList(readKey(trip, 'totalPriceList'));
        if (list.isNotEmpty) fromReview.add(list.first);
      }
    }
    if (fromReview.isNotEmpty) return fromReview;

    return <dynamic>[for (final leg in widget.legs) leg.selectedFare];
  }

  FareBreakdown get _fare => FareBreakdown.forFlight(
    fares: _fares,
    paxCounts: widget.trip.paxCounts,
    supplierTotal: _review?.totalFare ?? 0,
    addOns: _addOns.breakdown,
  );

  // -------------------------------------------------------------------------
  // Booking
  // -------------------------------------------------------------------------

  /// The supplier booking payload, shared by the hold and pay paths.
  Map<String, dynamic> _bookingPayload(FlightReview review) {
    final conditions = review.conditions;

    return <String, dynamic>{
      'bookingId': review.bookingId,
      // The supplier validates this against its own session quote, so it
      // carries the fare and nothing else.
      'paymentInfos': [
        {'amount': review.supplierPayableAmount + _addOns.total},
      ],
      'travellerInfo': [
        for (final (index, t) in _travellers.indexed)
          {
            ...t.toJson(
              passportRequired: conditions.passportRequired,
              docIdApplicable: conditions.docIdApplicable,
            ),
            // Seats/meals/bags ride along on the traveller they belong to.
            ..._addOns.ssrForTraveller(
              index,
              sellableSegments: _baggageSellableSegments(review),
            ),
          },
      ],
      'deliveryInfo': {
        'emails': [_contact.email.trim()],
        'contacts': [_contact.dialled],
      },
      // The traveller's optional note, as the web sends it.
      if (_agentNote.trim().isNotEmpty) 'remarks': _agentNote.trim(),
      if (_gst != null) 'gstInfo': _gst!.toJson(_contact.dialled),
      if (conditions.emergencyContactRequired)
        'contactInfo': {
          'emails': [_emergency.email.trim()],
          'contacts': [
            '${_contact.countryCode.replaceFirst('+', '')}'
                '${_emergency.mobile.trim()}',
          ],
          'ecn': _emergency.name.trim(),
        },
    };
  }

  /// "ADULT-1", "CHILD-1" … in booking order, matching the web's add-on
  /// passenger tabs.
  List<String> get _passengerLabels {
    final seen = <PaxType, int>{};
    return [
      for (final t in _travellers)
        () {
          final n = (seen[t.type] = (seen[t.type] ?? 0) + 1);
          return '${t.type.name.toUpperCase()}-$n';
        }(),
    ];
  }

  /// Legs the supplier prices excess baggage on. Bags chosen against any
  /// other leg are dropped: on a connecting journey the bag is checked
  /// through, and buying against a later leg is rejected with error 1129.
  Set<String> _baggageSellableSegments(FlightReview review) => {
    for (final segment in AddOnSegment.fromReview(review.raw))
      if (segment.baggageSellable) segment.id,
  };

  /// The envelope our own payment endpoints take around that payload.
  Map<String, dynamic> _paymentPayload(FlightReview review) {
    final segments = widget.outbound.segments;
    final first = segments.isEmpty ? null : segments.first;
    final last = segments.isEmpty ? null : segments.last;

    return <String, dynamic>{
      'provider': 'tripjack',
      'offer_id': review.bookingId,
      // The web sends `returnTrip ? 'round' : 'oneway'`, and a multi-city
      // booking reaches it with its second hop as the return trip — so the
      // backend only ever sees these two values. 'multicity' was never sent
      // by the web and is not a value the endpoint is known to accept.
      'trip_type': widget.inbound != null ? 'round' : 'oneway',
      'from': asString(digPath(first, ['da', 'code'])),
      'to': asString(digPath(last, ['aa', 'code'])),
      'departure': asString(readKey(first, 'dt')),
      'arrival': asString(readKey(last, 'at')),
      'flight_no':
          '${asString(digPath(first, ['fD', 'aI', 'code']))}-'
          '${asString(digPath(first, ['fD', 'fN']))}',
      'airline': asString(digPath(first, ['fD', 'aI', 'name'])),
      // `fare.fd.ADULT.cc` of the priced fare, else ECONOMY — the web's rule.
      'cabin_class': firstNonEmpty([
        digPath(_fares.firstOrNull, ['fd', 'ADULT', 'cc']),
      ], fallback: 'ECONOMY'),
      'price': _fare.total,
      'passengers': [
        for (final t in _travellers)
          t.toJson(
            passportRequired: review.conditions.passportRequired,
            docIdApplicable: review.conditions.docIdApplicable,
          ),
      ],
      'contact': {'email': _contact.email.trim(), 'phone': _contact.dialled},
      'booking_payload': _bookingPayload(review),
    };
  }

  Future<void> _hold() async {
    final review = _review;
    if (review == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final outcome = await widget.api.holdFlight(_paymentPayload(review));
      if (!mounted) return;
      _goToConfirmation(outcome);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pay() async {
    final review = _review;
    if (review == null || _submitting) return;

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final payload = _paymentPayload(review);
      final order = await widget.api.createFlightPaymentOrder(payload);
      if (!mounted) return;

      final lead = _travellers.isEmpty ? null : _travellers.first;
      final outcome = await RazorpayCheckout.open(
        context,
        order: order,
        title: 'HappyWedz',
        description: 'Flight Booking Payment',
        // Test keys only: a Razorpay test account caps UPI and wallets far
        // below a flight fare ("Amount exceeds maximum amount allowed"), so
        // they are hidden there. Live keys see every method.
        restrictMethodsInTestMode: true,
        prefill: (
          name: lead?.fullName ?? '',
          email: _contact.email.trim(),
          contact: _contact.dialled,
        ),
      );
      if (!mounted) return;

      switch (outcome) {
        case RazorpayDismissed():
          setState(() => _submitError = null);
        case RazorpayFailure(:final message):
          setState(() => _submitError = message);
        case RazorpaySuccess(:final result):
          // Past this point the traveller has been charged, so a failure here
          // is reported as "paid, not yet confirmed" rather than as a plain
          // error — the money is real either way.
          final BookingOutcome booking;
          try {
            booking = await widget.api.verifyAndBookFlight({
              ...result.toVerifyJson(),
              'booking_payload': payload['booking_payload'],
            });
          } catch (error) {
            // Charged but not ticketed: the payment id is what support needs,
            // so it is always part of the message — the web's wording. Any
            // failure here, not only an API refusal, lands in this branch:
            // the money has moved either way.
            if (!mounted) return;
            final e = error is HoneymoonApiException ? error : null;
            final serverMessage = asString(readKey(e?.data, 'message'));
            setState(
              () => _submitError = e?.statusCode == null
                  ? 'Payment was received but booking confirmation failed. '
                        'Please contact support with payment ID: '
                        '${result.paymentId}'
                  : '${serverMessage.isEmpty ? 'Payment succeeded but verification failed.' : serverMessage} '
                        '(Payment ID: ${result.paymentId})',
            );
            return;
          }
          if (!mounted) return;
          _goToConfirmation(booking);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = bookingErrorText(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Hands over to the flight confirmation — the web's
  /// `BookingConfirmation.jsx`: PNR wait, ticket actions, and for a blocked
  /// fare the deadline, UnHold and Proceed to pay.
  void _goToConfirmation(BookingOutcome outcome) {
    final review = _review;
    final payload = review == null
        ? const <String, dynamic>{}
        : _paymentPayload(review);
    final lead = _travellers.isEmpty ? null : _travellers.first;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => FlightConfirmationPage(
          api: widget.api,
          outcome: outcome,
          trip: widget.trip,
          legs: review == null
              ? [
                  for (final leg in widget.legs)
                    (trip: leg.raw, fare: leg.selectedFare),
                ]
              : _pricedLegs(review, widget.legs),
          travellers: _travellers,
          addOns: _addOns,
          fare: _fare,
          contact: _contact,
          gst: _gst,
          agentNote: _agentNote,
          // The same fields the web's `payConfirm` sends for a held fare.
          held: (
            orderId: outcome.reference,
            amount: _fare.total,
            tripType: asString(payload['trip_type']),
            from: asString(payload['from']),
            to: asString(payload['to']),
            departure: asString(payload['departure']),
            arrival: asString(payload['arrival']),
            flightNo: asString(payload['flight_no']),
            airline: asString(payload['airline']),
            cabinClass: asString(payload['cabin_class']),
            email: _contact.email.trim(),
            phone: _contact.dialled,
            passengerName: lead?.fullName ?? '',
          ),
        ),
      ),
    );
  }

  // Previous hand-off to the shared confirmation screen, kept for reference:
  // void _goToConfirmation(BookingOutcome outcome) {
  //   // Captured before the replace: this State's context is gone by the time
  //   // the confirmation screen's actions fire.
  //   final navigator = Navigator.of(context);
  //
  //   navigator.pushReplacement(
  //     MaterialPageRoute(
  //       builder: (_) => BookingConfirmationPage(
  //         outcome: outcome,
  //         onViewBookings: () {
  //           // Unwind the checkout first so "back" from My trips lands where
  //           // the traveller started, not inside a spent booking form.
  //           navigator.popUntil((route) => route.isFirst);
  //           navigator.push(
  //             MaterialPageRoute(
  //               builder: (_) =>
  //                   const MyTripsPage(initialProduct: TravelProduct.flight),
  //             ),
  //           );
  //         },
  //         summaryTitle:
  //             '${widget.trip.from.code} → ${widget.trip.to.code}'
  //             '${widget.trip.isRoundTrip ? ' · Round trip' : ''}',
  //         summarySubtitle: widget.trip.travellerSummary,
  //         details: [
  //           DetailRow(
  //             label: 'Departure',
  //             value: formatTripDate(widget.trip.departure),
  //             icon: Icons.flight_takeoff_rounded,
  //           ),
  //           if (widget.trip.returnDate != null)
  //             DetailRow(
  //               label: 'Return',
  //               value: formatTripDate(widget.trip.returnDate),
  //               icon: Icons.flight_land_rounded,
  //             ),
  //           DetailRow(
  //             label: 'Lead traveller',
  //             value: _travellers.isEmpty ? '' : _travellers.first.fullName,
  //             icon: Icons.person_outline_rounded,
  //           ),
  //           DetailRow(
  //             label: 'Ticket sent to',
  //             value: _contact.email.trim(),
  //             icon: Icons.mail_outline_rounded,
  //           ),
  //         ],
  //         nextSteps: outcome.onHold
  //             ? const [
  //                 (
  //                   title: 'Complete the payment',
  //                   body:
  //                       'Your seats are blocked but not ticketed. Pay before '
  //                       'the airline deadline to confirm them.',
  //                 ),
  //                 (
  //                   title: 'Ticket on confirmation',
  //                   body:
  //                       'Your e-ticket and PNR are emailed the moment the '
  //                       'payment goes through.',
  //                 ),
  //               ]
  //             : const [
  //                 (
  //                   title: 'E-ticket on its way',
  //                   body:
  //                       'Your ticket and PNR are emailed to the address on '
  //                       'the booking.',
  //                 ),
  //                 (
  //                   title: 'Web check-in',
  //                   body:
  //                       'Most airlines open check-in 48 hours before '
  //                       'departure.',
  //                 ),
  //                 (
  //                   title: 'At the airport',
  //                   body:
  //                       'Carry the ID used to book. International trips need '
  //                       'the passport on the booking.',
  //                 ),
  //               ],
  //       ),
  //     ),
  //   );
  // }

  // -------------------------------------------------------------------------
  // Navigation between steps
  // -------------------------------------------------------------------------

  final GlobalKey<FlightTravellerStepState> _travellerStepKey =
      GlobalKey<FlightTravellerStepState>();

  void _continue() {
    if (_step == 0) {
      setState(() => _step = 1);
      return;
    }
    if (_step == 1) {
      final form = _travellerStepKey.currentState;
      if (form == null || !form.validateAndCommit()) {
        AppSnackbar.error(
          context,
          'Please complete the highlighted traveller details.',
        );
        return;
      }
      setState(() {
        _gst = form.gstIfEnabled;
        _agentNote = form.note;
        _step = 2;
        _submitError = null;
      });
      return;
    }
    if (_step == 2) {
      setState(() => _step = 3);
      return;
    }
    _pay();
  }

  /// Back means "previous step" until there is no previous step, and only
  /// then "leave the booking".
  Future<void> _handleBack() async {
    if (_step > 0) {
      setState(() => _step -= 1);
      return;
    }
    final leave = await _confirmLeave();
    if (!leave || !mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> _confirmLeave() async {
    // Nothing typed yet — no reason to interrupt.
    if (_step == 0) return true;
    return ConfirmPopup.show(
      context,
      title: 'Leave this booking?',
      message: 'The details you have entered will not be saved.',
      confirmLabel: 'Leave',
      cancelLabel: 'Stay',
      icon: Icons.exit_to_app_rounded,
      danger: true,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final review = _review;
    final expiresAt = review?.conditions.expiresAt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppTopBar(
          elevated: true,
          onBack: _handleBack,
          titleWidget: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.trip.from.code} → ${widget.trip.to.code}',
                style: AppText.cardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.trip.travellerSummary,
                style: AppText.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          actions: [
            if (expiresAt != null && !_sessionExpired && review != null)
              SessionCountdown(
                expiresAt: expiresAt,
                onExpire: _onSessionExpired,
              ),
          ],
          bottom: review == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(BookingStepBar.height),
                  child: BookingStepBar(
                    steps: _steps,
                    currentStep: _step,
                    onStepTapped: (i) => setState(() => _step = i),
                  ),
                ),
        ),
        body: AsyncView(
          isLoading: _loadingReview,
          error: _reviewError,
          onRetry: _openSession,
          errorTitle: 'We could not confirm that fare',
          errorMessage: _reviewError == null
              ? null
              : bookingErrorText(_reviewError),
          loading: const _ReviewingFare(),
          child: review == null ? const SizedBox.shrink() : _body(review),
        ),
        bottomNavigationBar: review == null || _loadingReview
            ? null
            : BookingActionBar(
                fare: _fare,
                amountFormatter: formatFlightFare,
                priceLabel: _step == 3 ? 'Total payable' : 'From',
                actionLabel: switch (_step) {
                  0 => 'Add travellers',
                  1 => 'Add-ons',
                  2 => 'Review booking',
                  _ => 'Proceed to pay',
                },
                isLoading: _submitting,
                onAction: _continue,
                onShowBreakdown: () => showFareBreakdownSheet(
                  context,
                  _fare,
                  amountFormatter: formatFlightFare,
                  footnote:
                      'Fares are held only briefly and can change until the '
                      'booking is confirmed.',
                ),
                secondaryLabel: _step == 3 && review.conditions.blockAllowed
                    ? 'Block'
                    : null,
                onSecondary: _hold,
              ),
      ),
    );
  }

  Widget _body(FlightReview review) {
    final change = _priceChange;
    final steps = AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      child: switch (_step) {
        0 => _ItineraryStep(
          key: const ValueKey('step-trip'),
          api: widget.api,
          trip: widget.trip,
          legs: widget.legs,
          review: review,
        ),
        1 => FlightTravellerStep(
          key: _travellerStepKey,
          api: widget.api,
          trip: widget.trip,
          conditions: review.conditions,
          travellers: _travellers,
          contact: _contact,
          emergency: _emergency,
          initialGst: _gst,
          initialNote: _agentNote,
        ),
        2 => FlightAddOnStep(
          key: const ValueKey('step-addons'),
          api: widget.api,
          review: review,
          passengerLabels: _passengerLabels,
          addOns: _addOns,
          onChanged: () => setState(() {}),
        ),
        _ => _ReviewStep(
          key: const ValueKey('step-review'),
          trip: widget.trip,
          legs: widget.legs,
          review: review,
          travellers: _travellers,
          addOns: _addOns,
          contact: _contact,
          gst: _gst,
          errorMessage: _submitError,
          canHold: review.conditions.blockAllowed,
        ),
      },
    );
    if (change == null) return steps;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.price_change_outlined,
            message:
                'The fare changed from ${formatFlightFare(change.before)} to '
                '${formatFlightFare(change.after)} when the price was '
                'refreshed.',
            action: PremiumButton.text(
              label: 'Dismiss',
              size: PremiumButtonSize.small,
              onPressed: () => setState(() => _priceChange = null),
            ),
          ),
        ),
        Expanded(child: steps),
      ],
    );
  }
}

/// The wait while the fare is re-priced — named, because "loading" tells the
/// traveller nothing about why a price they already saw is being checked.
class _ReviewingFare extends StatelessWidget {
  const _ReviewingFare();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(padding: EdgeInsets.zero),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Checking the latest price',
              style: AppText.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Airlines re-quote fares at the moment of booking.',
              style: AppText.bodySm,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// One leg of the itinerary, laid out for a phone: times on the outside,
/// duration in the middle, segments listed below rather than side by side.
class FlightLegCard extends StatelessWidget {
  const FlightLegCard({
    super.key,
    required this.title,
    required this.date,
    required this.flight,
  });

  final String title;
  final DateTime? date;
  final FlightResult flight;

  String _time(DateTime? d) => d == null
      ? '--:--'
      : '${d.hour.toString().padLeft(2, '0')}:'
            '${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppText.overline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (date != null)
                Flexible(
                  child: Text(
                    formatTripDate(date),
                    style: AppText.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(flight.departure), style: AppText.sectionTitle),
                  Text(flight.fromCode, style: AppText.caption),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Column(
                    children: [
                      Text(
                        flight.durationLabel,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      const Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                          Icon(
                            Icons.flight_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.divider,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        flight.stopsLabel,
                        style: AppText.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_time(flight.arrival), style: AppText.sectionTitle),
                  Text(flight.toCode, style: AppText.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MetaChip(
                icon: Icons.airlines_rounded,
                label: flight.airline.isNotEmpty
                    ? flight.airline
                    : flight.airlineCode,
              ),
              if (flight.flightNumber.isNotEmpty)
                MetaChip(
                  label: '${flight.airlineCode} ${flight.flightNumber}'.trim(),
                ),
              if (flight.cabinClass.isNotEmpty)
                MetaChip(label: _titleCase(flight.cabinClass)),
            ],
          ),
        ],
      ),
    );
  }

  static String _titleCase(String value) => value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((w) => w.isNotEmpty)
      .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

// ---------------------------------------------------------------------------
// Step 1 — itinerary (FlightItinerary.jsx)
// ---------------------------------------------------------------------------

/// A leg as the session priced it: the review's own `tripInfos` entry and the
/// fare on it, falling back to the search result when the review omits it.
typedef _PricedLeg = ({Map<String, dynamic> trip, dynamic fare});

List<_PricedLeg> _pricedLegs(FlightReview review, List<FlightResult> legs) {
  if (review.trips.isNotEmpty) {
    return [
      for (final trip in review.trips)
        (trip: trip, fare: asList(readKey(trip, 'totalPriceList')).firstOrNull),
    ];
  }
  return [for (final leg in legs) (trip: leg.raw, fare: leg.selectedFare)];
}

/// Segment `id` → "BOM-DEL", the label the review uses for each add-on.
Map<String, String> _segmentRoutes(List<_PricedLeg> legs) => {
  for (final leg in legs)
    for (final s in asList(readKey(leg.trip, 'sI')))
      asString(readKey(s, 'id')):
          '${asString(digPath(s, ['da', 'code']))}-'
          '${asString(digPath(s, ['aa', 'code']))}',
};

class _ItineraryStep extends StatefulWidget {
  const _ItineraryStep({
    super.key,
    required this.api,
    required this.trip,
    required this.legs,
    required this.review,
  });

  final HoneymoonApi api;
  final FlightTripContext trip;
  final List<FlightResult> legs;
  final FlightReview review;

  @override
  State<_ItineraryStep> createState() => _ItineraryStepState();
}

class _ItineraryStepState extends State<_ItineraryStep> {
  bool _rulesOpen = false;

  /// Fetched on first open with the session's bookingId (`flowType: REVIEW`),
  /// as the web's "Fare Rules +" does.
  Future<FareRuleSet>? _rules;

  @override
  void didUpdateWidget(covariant _ItineraryStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A re-priced session has a new bookingId, and the rules follow it.
    if (oldWidget.review.bookingId != widget.review.bookingId) _rules = null;
  }

  void _toggleRules() {
    setState(() {
      _rulesOpen = !_rulesOpen;
      if (_rulesOpen && widget.review.bookingId.isNotEmpty) {
        _rules ??= widget.api.fetchFareRules(widget.review.bookingId, 'REVIEW');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final legs = _pricedLegs(widget.review, widget.legs);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        Text('Flight Details', style: AppText.sectionTitle),
        const SizedBox(height: AppSpacing.md),
        for (var i = 0; i < legs.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          FlightItineraryCard(
            title: widget.trip.legTitle(i, legs.length),
            trip: legs[i].trip,
            fare: legs[i].fare,
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _toggleRules,
                borderRadius: AppRadii.rLg,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.gavel_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text('Fare Rules', style: AppText.cardTitle),
                      ),
                      Icon(
                        _rulesOpen ? Icons.remove_rounded : Icons.add_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (_rulesOpen)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: _rules == null
                      ? Text(
                          'Fare rules unavailable. Please contact support.',
                          style: AppText.bodySm,
                        )
                      : FareRulesLoaderView(future: _rules!),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        if (widget.review.conditions.passportRequired) ...[
          const InfoBanner(
            icon: Icons.badge_outlined,
            message:
                'This is an international itinerary — passport details are '
                'needed for every traveller on the next step.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const InfoBanner(
          tone: InfoTone.warning,
          icon: Icons.timer_outlined,
          message:
              'This price is held for a short time only. Complete the booking '
              'before the timer runs out to keep it.',
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 — review (BookingReview.jsx)
// ---------------------------------------------------------------------------

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.trip,
    required this.legs,
    required this.review,
    required this.travellers,
    required this.addOns,
    required this.contact,
    required this.gst,
    required this.errorMessage,
    required this.canHold,
  });

  final FlightTripContext trip;
  final List<FlightResult> legs;
  final FlightReview review;
  final List<TravellerInput> travellers;
  final FlightAddOns addOns;
  final ContactDetails contact;
  final GstDetails? gst;
  final String? errorMessage;
  final bool canHold;

  @override
  Widget build(BuildContext context) {
    final priced = _pricedLegs(review, legs);
    final routes = _segmentRoutes(priced);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (errorMessage != null) ...[
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: errorMessage!,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        for (var i = 0; i < priced.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.md),
          FlightItineraryCard(
            title: trip.legTitle(i, priced.length),
            trip: priced[i].trip,
            fare: priced[i].fare,
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // The web lays passengers out as a table — name, age and passport,
        // seat, and meal & baggage per leg. A table cannot survive a 320 px
        // viewport, so each traveller becomes its own block with the same
        // columns stacked.
        FormSection(
          title: 'Passenger Details',
          subtitle: '(${travellers.length})',
          icon: Icons.people_outline_rounded,
          children: [
            for (var i = 0; i < travellers.length; i++) ...[
              if (i > 0) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: AppSpacing.md),
              ],
              _TravellerReviewRow(
                index: i,
                traveller: travellers[i],
                seats: addOns.seats[i] ?? const {},
                meals: addOns.meals[i] ?? const {},
                baggage: addOns.baggage[i] ?? const {},
                routes: routes,
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Contact Details',
          subtitle: 'Where we send your ticket',
          icon: Icons.alternate_email_rounded,
          children: [
            DetailRow(label: 'Email', value: contact.email.trim()),
            DetailRow(
              label: 'Mobile',
              value: '${contact.countryCode} ${contact.mobile.trim()}',
            ),
          ],
        ),

        if (gst != null) ...[
          const SizedBox(height: AppSpacing.md),
          FormSection(
            title: 'GST Details',
            icon: Icons.receipt_long_outlined,
            children: [
              DetailRow(label: 'Company', value: gst!.companyName),
              DetailRow(label: 'GST Number', value: gst!.gstNumber),
              DetailRow(label: 'Email', value: gst!.companyEmail),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        if (canHold) ...[
          const InfoBanner(
            icon: Icons.lock_clock_rounded,
            message:
                'This fare can be blocked without paying. A blocked booking is '
                'not ticketed until you pay, and the airline releases it if '
                'you miss the deadline.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _FlightTermsNotice(),
      ],
    );
  }
}

/// "By proceeding, I acknowledge and agree to the Terms of Use and Privacy
/// Policy." — linked to the site's terms page, as on the web.
class _FlightTermsNotice extends StatelessWidget {
  const _FlightTermsNotice();

  static final Uri _terms = Uri.parse('https://www.happywedz.com/terms');

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'By proceeding, I acknowledge and agree to the ',
          style: AppText.caption,
        ),
        GestureDetector(
          onTap: () => launchUrl(_terms, mode: LaunchMode.externalApplication),
          child: Text(
            'Terms of Use and Privacy Policy.',
            style: AppText.caption.copyWith(
              color: AppColors.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}

class _TravellerReviewRow extends StatelessWidget {
  const _TravellerReviewRow({
    required this.index,
    required this.traveller,
    required this.seats,
    required this.meals,
    required this.baggage,
    required this.routes,
  });

  final int index;
  final TravellerInput traveller;
  final Map<String, SeatChoice> seats;
  final Map<String, Map<String, SsrChoice>> meals;
  final Map<String, Map<String, SsrChoice>> baggage;
  final Map<String, String> routes;

  /// `[(route, text)]` for one kind — "BOM-DEL : Veg Meal".
  List<(String, String)> _choices(Map<String, Map<String, SsrChoice>> bySeg) {
    return [
      for (final entry in bySeg.entries)
        if (entry.value.values.any((c) => c.qty > 0))
          (
            routes[entry.key] ?? entry.key,
            entry.value.values
                .where((c) => c.qty > 0)
                .map(
                  (c) => c.qty > 1
                      ? '${c.desc.isEmpty ? c.code : c.desc} × ${c.qty}'
                      : (c.desc.isEmpty ? c.code : c.desc),
                )
                .join(', '),
          ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final seatLines = [
      for (final entry in seats.entries)
        '${routes[entry.key] ?? entry.key} : ${entry.value.code}',
    ];
    final bagLines = _choices(baggage);
    final mealLines = _choices(meals);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: AppColors.blush,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '${index + 1}',
            style: AppText.labelSm.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Mr JOHN DOE (A)" — the portal marks each traveller with
              // their type initial after the name.
              Text(
                '${traveller.title} ${traveller.fullName} '
                '(${traveller.type.initial})',
                style: AppText.bodyStrong,
              ),
              if (traveller.dob != null)
                Text(flightShortDate(traveller.dob), style: AppText.caption),
              if (traveller.passportNumber.trim().isNotEmpty)
                Text(
                  traveller.passportNumber.trim().toUpperCase(),
                  style: AppText.caption,
                ),
              const SizedBox(height: AppSpacing.sm),
              Text('Seat Booking', style: AppText.labelSm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  if (seatLines.isEmpty)
                    const MetaChip(label: 'NA')
                  else
                    for (final line in seatLines) MetaChip(label: line),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Meal & Baggage Preference', style: AppText.labelSm),
              if (bagLines.isEmpty && mealLines.isEmpty)
                Text('—', style: AppText.caption),
              for (final (route, text) in bagLines)
                _ssrLine(Icons.work_outline_rounded, route, text),
              for (final (route, text) in mealLines)
                _ssrLine(Icons.restaurant_rounded, route, text),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ssrLine(IconData icon, String route, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppText.caption,
                children: [
                  TextSpan(
                    text: '$route : ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Session expired — SessionExpiredModal.jsx
// ---------------------------------------------------------------------------

/// "CONFIRM TO PROCEED": re-price and carry on, or go back to the list. When
/// re-pricing fails the only honest option left is a new search, so Continue
/// disappears and the copy says why.
class _SessionExpiredDialog extends StatefulWidget {
  const _SessionExpiredDialog({
    required this.elapsedMinutes,
    required this.onContinue,
  });

  final int elapsedMinutes;

  /// Re-prices the session; resolves false when that failed.
  final Future<bool> Function() onContinue;

  @override
  State<_SessionExpiredDialog> createState() => _SessionExpiredDialogState();
}

class _SessionExpiredDialogState extends State<_SessionExpiredDialog> {
  bool _busy = false;
  bool _failed = false;

  Future<void> _continue() async {
    setState(() => _busy = true);
    final ok = await widget.onContinue();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('CONFIRM TO PROCEED'),
        content: Text(
          _failed
              ? 'This fare is no longer available at the quoted price. Search '
                    'again to see live fares for your dates.'
              : 'It has been over ${widget.elapsedMinutes} minutes since the '
                    'price was last updated. Tap Continue to view the latest '
                    'price and availability.',
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context, false),
            child: const Text('BACK TO FLIGHT LIST'),
          ),
          if (!_failed)
            FilledButton(
              onPressed: _busy ? null : _continue,
              child: Text(_busy ? 'CHECKING…' : 'CONTINUE'),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Previous itinerary and review steps, kept for reference.
//
// Replaced to match FlightItinerary.jsx / BookingReview.jsx: the itinerary
// showed one summary line per leg with no segments, airports, terminals,
// baggage or fare rules, and the review showed no seat, meal or baggage per
// traveller.
// ---------------------------------------------------------------------------

// // ---------------------------------------------------------------------------
// // Step 1 — itinerary
// // ---------------------------------------------------------------------------
//
// class _ItineraryStep extends StatelessWidget {
//   const _ItineraryStep({
//     super.key,
//     required this.trip,
//     required this.legs,
//     required this.review,
//   });
//
//   final FlightTripContext trip;
//   final List<FlightResult> legs;
//   final FlightReview review;
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.lg,
//         AppSpacing.lg,
//         AppSpacing.lg,
//         AppSpacing.xxxl,
//       ),
//       children: [
//         for (var i = 0; i < legs.length; i++) ...[
//           if (i > 0) const SizedBox(height: AppSpacing.md),
//           FlightLegCard(
//             title: trip.legTitle(i, legs.length),
//             date: trip.legDate(i),
//             flight: legs[i],
//           ),
//         ],
//         const SizedBox(height: AppSpacing.lg),
//         if (review.conditions.passportRequired)
//           const InfoBanner(
//             icon: Icons.badge_outlined,
//             message:
//                 'This is an international itinerary — passport details are '
//                 'needed for every traveller on the next step.',
//           ),
//         if (review.conditions.passportRequired)
//           const SizedBox(height: AppSpacing.md),
//         const InfoBanner(
//           tone: InfoTone.warning,
//           icon: Icons.timer_outlined,
//           message:
//               'This price is held for a short time only. Complete the booking '
//               'before the timer runs out to keep it.',
//         ),
//       ],
//     );
//   }
// }

// // ---------------------------------------------------------------------------
// // Step 3 — review
// // ---------------------------------------------------------------------------
//
// class _ReviewStep extends StatelessWidget {
//   const _ReviewStep({
//     super.key,
//     required this.trip,
//     required this.legs,
//     required this.travellers,
//     required this.contact,
//     required this.gst,
//     required this.errorMessage,
//     required this.canHold,
//   });
//
//   final FlightTripContext trip;
//   final List<FlightResult> legs;
//   final List<TravellerInput> travellers;
//   final ContactDetails contact;
//   final GstDetails? gst;
//   final String? errorMessage;
//   final bool canHold;
//
//   @override
//   Widget build(BuildContext context) {
//     return ListView(
//       padding: const EdgeInsets.fromLTRB(
//         AppSpacing.lg,
//         AppSpacing.lg,
//         AppSpacing.lg,
//         AppSpacing.xxxl,
//       ),
//       children: [
//         if (errorMessage != null) ...[
//           InfoBanner(
//             tone: InfoTone.error,
//             icon: Icons.error_outline_rounded,
//             message: errorMessage!,
//           ),
//           const SizedBox(height: AppSpacing.lg),
//         ],
//
//         for (var i = 0; i < legs.length; i++) ...[
//           if (i > 0) const SizedBox(height: AppSpacing.md),
//           FlightLegCard(
//             title: trip.legTitle(i, legs.length),
//             date: trip.legDate(i),
//             flight: legs[i],
//           ),
//         ],
//         const SizedBox(height: AppSpacing.md),
//
//         // The web renders travellers as a table. A table cannot survive a
//         // 320 px viewport, so each traveller becomes its own row block.
//         FormSection(
//           title: 'Travellers',
//           subtitle: '${travellers.length} on this booking',
//           icon: Icons.people_outline_rounded,
//           children: [
//             for (var i = 0; i < travellers.length; i++) ...[
//               if (i > 0) ...[
//                 const SizedBox(height: AppSpacing.md),
//                 const Divider(height: 1, color: AppColors.divider),
//                 const SizedBox(height: AppSpacing.md),
//               ],
//               _TravellerReviewRow(
//                 index: i,
//                 label: trip.labelFor(i),
//                 traveller: travellers[i],
//               ),
//             ],
//           ],
//         ),
//         const SizedBox(height: AppSpacing.md),
//
//         FormSection(
//           title: 'Contact details',
//           subtitle: 'Where we send your ticket',
//           icon: Icons.alternate_email_rounded,
//           children: [
//             DetailRow(label: 'Email', value: contact.email.trim()),
//             DetailRow(
//               label: 'Mobile',
//               value: '${contact.countryCode} ${contact.mobile.trim()}',
//             ),
//           ],
//         ),
//
//         if (gst != null) ...[
//           const SizedBox(height: AppSpacing.md),
//           FormSection(
//             title: 'GST details',
//             icon: Icons.receipt_long_outlined,
//             children: [
//               DetailRow(label: 'Company', value: gst!.companyName),
//               DetailRow(label: 'GST number', value: gst!.gstNumber),
//               DetailRow(label: 'Email', value: gst!.companyEmail),
//             ],
//           ),
//         ],
//
//         const SizedBox(height: AppSpacing.lg),
//         if (canHold) ...[
//           const InfoBanner(
//             icon: Icons.lock_clock_rounded,
//             message:
//                 'This fare can be held without paying. A held booking is not '
//                 'ticketed until you pay, and the airline releases it if you '
//                 'miss the deadline.',
//           ),
//           const SizedBox(height: AppSpacing.md),
//         ],
//         const TermsNotice(product: 'airline'),
//       ],
//     );
//   }
// }
//
// class _TravellerReviewRow extends StatelessWidget {
//   const _TravellerReviewRow({
//     required this.index,
//     required this.label,
//     required this.traveller,
//   });
//
//   final int index;
//   final String label;
//   final TravellerInput traveller;
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           width: 26,
//           height: 26,
//           decoration: const BoxDecoration(
//             color: AppColors.blush,
//             shape: BoxShape.circle,
//           ),
//           alignment: Alignment.center,
//           child: Text(
//             '${index + 1}',
//             style: AppText.labelSm.copyWith(
//               color: AppColors.primary,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ),
//         const SizedBox(width: AppSpacing.md),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 '${traveller.title} ${traveller.fullName}',
//                 style: AppText.bodyStrong,
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 [
//                   label,
//                   if (traveller.dob != null) formatTripDate(traveller.dob),
//                   if (traveller.passportNumber.trim().isNotEmpty)
//                     traveller.passportNumber.trim().toUpperCase(),
//                 ].join(' · '),
//                 style: AppText.caption,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
