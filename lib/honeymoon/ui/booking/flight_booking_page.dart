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

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../widgets/honeymoon_widgets.dart';
import '../bookings/my_trips_page.dart';
import 'booking_confirmation_page.dart';
import 'booking_widgets.dart';
import 'flight_traveller_step.dart';

class FlightBookingPage extends StatefulWidget {
  const FlightBookingPage({
    super.key,
    required this.api,
    required this.trip,
    required this.outbound,
    this.inbound,
  });

  final HoneymoonApi api;
  final FlightTripContext trip;
  final FlightResult outbound;

  /// The return leg on a round trip. Both legs are priced in one session.
  final FlightResult? inbound;

  @override
  State<FlightBookingPage> createState() => _FlightBookingPageState();
}

class _FlightBookingPageState extends State<FlightBookingPage> {
  static const _steps = ['Trip', 'Travellers', 'Review'];

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

  bool _submitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _openSession();
  }

  // -------------------------------------------------------------------------
  // Session
  // -------------------------------------------------------------------------

  List<String> get _priceIds => [
    widget.outbound.id,
    if (widget.inbound != null) widget.inbound!.id,
  ].where((id) => id.isNotEmpty).toList();

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
        AppSnackbar.info(
          context,
          'The fare changed to ${formatPrice(newTotal)} when we re-checked it.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = e;
      });
    }
  }

  Future<void> _onSessionExpired() async {
    if (_sessionExpired || !mounted) return;
    setState(() => _sessionExpired = true);

    final refresh = await ConfirmPopup.show(
      context,
      title: 'Your fare has expired',
      message:
          'Airlines only hold a quoted price for a few minutes. We can check '
          'the current price for the same flight.',
      confirmLabel: 'Check price',
      cancelLabel: 'Go back',
      icon: Icons.timer_off_rounded,
    );

    if (!mounted) return;
    if (refresh) {
      await _openSession();
      if (mounted && _reviewError == null) setState(() => _step = 0);
    } else if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

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

    return <dynamic>[
      widget.outbound.selectedFare,
      if (widget.inbound != null) widget.inbound!.selectedFare,
    ];
  }

  FareBreakdown get _fare => FareBreakdown.forFlight(
    fares: _fares,
    paxCounts: widget.trip.paxCounts,
    supplierTotal: _review?.totalFare ?? 0,
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
        {'amount': review.supplierPayableAmount},
      ],
      'travellerInfo': [
        for (final t in _travellers)
          t.toJson(
            passportRequired: conditions.passportRequired,
            docIdApplicable: conditions.docIdApplicable,
          ),
      ],
      'deliveryInfo': {
        'emails': [_contact.email.trim()],
        'contacts': [_contact.dialled],
      },
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

  /// The envelope our own payment endpoints take around that payload.
  Map<String, dynamic> _paymentPayload(FlightReview review) {
    final segments = widget.outbound.segments;
    final first = segments.isEmpty ? null : segments.first;
    final last = segments.isEmpty ? null : segments.last;

    return <String, dynamic>{
      'provider': 'tripjack',
      'offer_id': review.bookingId,
      'trip_type': widget.inbound != null ? 'round' : 'oneway',
      'from': asString(digPath(first, ['da', 'code'])),
      'to': asString(digPath(last, ['aa', 'code'])),
      'departure': asString(readKey(first, 'dt')),
      'arrival': asString(readKey(last, 'at')),
      'flight_no':
          '${asString(digPath(first, ['fD', 'aI', 'code']))}-'
          '${asString(digPath(first, ['fD', 'fN']))}',
      'airline': asString(digPath(first, ['fD', 'aI', 'name'])),
      'cabin_class': widget.outbound.cabinClass.isEmpty
          ? widget.trip.cabinClass
          : widget.outbound.cabinClass,
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
        title: 'HappyWedz Flights',
        description:
            '${widget.trip.from.code} → ${widget.trip.to.code} flight booking',
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
          final booking = await widget.api.verifyAndBookFlight({
            ...result.toVerifyJson(),
            'booking_payload': payload['booking_payload'],
          });
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

  void _goToConfirmation(BookingOutcome outcome) {
    // Captured before the replace: this State's context is gone by the time
    // the confirmation screen's actions fire.
    final navigator = Navigator.of(context);

    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => BookingConfirmationPage(
          outcome: outcome,
          onViewBookings: () {
            // Unwind the checkout first so "back" from My trips lands where
            // the traveller started, not inside a spent booking form.
            navigator.popUntil((route) => route.isFirst);
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const MyTripsPage(
                  initialProduct: TravelProduct.flight,
                ),
              ),
            );
          },
          summaryTitle:
              '${widget.trip.from.code} → ${widget.trip.to.code}'
              '${widget.trip.isRoundTrip ? ' · Round trip' : ''}',
          summarySubtitle: widget.trip.travellerSummary,
          details: [
            DetailRow(
              label: 'Departure',
              value: formatTripDate(widget.trip.departure),
              icon: Icons.flight_takeoff_rounded,
            ),
            if (widget.trip.returnDate != null)
              DetailRow(
                label: 'Return',
                value: formatTripDate(widget.trip.returnDate),
                icon: Icons.flight_land_rounded,
              ),
            DetailRow(
              label: 'Lead traveller',
              value: _travellers.isEmpty ? '' : _travellers.first.fullName,
              icon: Icons.person_outline_rounded,
            ),
            DetailRow(
              label: 'Ticket sent to',
              value: _contact.email.trim(),
              icon: Icons.mail_outline_rounded,
            ),
          ],
          nextSteps: outcome.onHold
              ? const [
                  (
                    title: 'Complete the payment',
                    body:
                        'Your seats are blocked but not ticketed. Pay before '
                        'the airline deadline to confirm them.',
                  ),
                  (
                    title: 'Ticket on confirmation',
                    body:
                        'Your e-ticket and PNR are emailed the moment the '
                        'payment goes through.',
                  ),
                ]
              : const [
                  (
                    title: 'E-ticket on its way',
                    body:
                        'Your ticket and PNR are emailed to the address on '
                        'the booking.',
                  ),
                  (
                    title: 'Web check-in',
                    body:
                        'Most airlines open check-in 48 hours before '
                        'departure.',
                  ),
                  (
                    title: 'At the airport',
                    body:
                        'Carry the ID used to book. International trips need '
                        'the passport on the booking.',
                  ),
                ],
        ),
      ),
    );
  }

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
        _step = 2;
        _submitError = null;
      });
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
          child: review == null
              ? const SizedBox.shrink()
              : _body(review),
        ),
        bottomNavigationBar: review == null || _loadingReview
            ? null
            : BookingActionBar(
                fare: _fare,
                priceLabel: _step == 2 ? 'Total payable' : 'From',
                actionLabel: switch (_step) {
                  0 => 'Add travellers',
                  1 => 'Review booking',
                  _ => 'Pay securely',
                },
                isLoading: _submitting,
                onAction: _continue,
                onShowBreakdown: () => showFareBreakdownSheet(
                  context,
                  _fare,
                  footnote:
                      'Fares are held only briefly and can change until the '
                      'booking is confirmed.',
                ),
                secondaryLabel:
                    _step == 2 && review.conditions.blockAllowed
                    ? 'Hold this fare'
                    : null,
                onSecondary: _hold,
              ),
      ),
    );
  }

  Widget _body(FlightReview review) {
    return AnimatedSwitcher(
      duration: AppMotion.normal,
      switchInCurve: AppMotion.standard,
      child: switch (_step) {
        0 => _ItineraryStep(
          key: const ValueKey('step-trip'),
          trip: widget.trip,
          outbound: widget.outbound,
          inbound: widget.inbound,
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
        ),
        _ => _ReviewStep(
          key: const ValueKey('step-review'),
          trip: widget.trip,
          outbound: widget.outbound,
          inbound: widget.inbound,
          travellers: _travellers,
          contact: _contact,
          gst: _gst,
          errorMessage: _submitError,
          canHold: review.conditions.blockAllowed,
        ),
      },
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

// ---------------------------------------------------------------------------
// Step 1 — itinerary
// ---------------------------------------------------------------------------

class _ItineraryStep extends StatelessWidget {
  const _ItineraryStep({
    super.key,
    required this.trip,
    required this.outbound,
    required this.inbound,
    required this.review,
  });

  final FlightTripContext trip;
  final FlightResult outbound;
  final FlightResult? inbound;
  final FlightReview review;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        FlightLegCard(
          title: 'Departure',
          date: trip.departure,
          flight: outbound,
        ),
        if (inbound != null) ...[
          const SizedBox(height: AppSpacing.md),
          FlightLegCard(
            title: 'Return',
            date: trip.returnDate,
            flight: inbound!,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (review.conditions.passportRequired)
          const InfoBanner(
            icon: Icons.badge_outlined,
            message:
                'This is an international itinerary — passport details are '
                'needed for every traveller on the next step.',
          ),
        if (review.conditions.passportRequired)
          const SizedBox(height: AppSpacing.md),
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
// Step 3 — review
// ---------------------------------------------------------------------------

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    super.key,
    required this.trip,
    required this.outbound,
    required this.inbound,
    required this.travellers,
    required this.contact,
    required this.gst,
    required this.errorMessage,
    required this.canHold,
  });

  final FlightTripContext trip;
  final FlightResult outbound;
  final FlightResult? inbound;
  final List<TravellerInput> travellers;
  final ContactDetails contact;
  final GstDetails? gst;
  final String? errorMessage;
  final bool canHold;

  @override
  Widget build(BuildContext context) {
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

        FlightLegCard(
          title: 'Departure',
          date: trip.departure,
          flight: outbound,
        ),
        if (inbound != null) ...[
          const SizedBox(height: AppSpacing.md),
          FlightLegCard(
            title: 'Return',
            date: trip.returnDate,
            flight: inbound!,
          ),
        ],
        const SizedBox(height: AppSpacing.md),

        // The web renders travellers as a table. A table cannot survive a
        // 320 px viewport, so each traveller becomes its own row block.
        FormSection(
          title: 'Travellers',
          subtitle: '${travellers.length} on this booking',
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
                label: trip.labelFor(i),
                traveller: travellers[i],
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Contact details',
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
            title: 'GST details',
            icon: Icons.receipt_long_outlined,
            children: [
              DetailRow(label: 'Company', value: gst!.companyName),
              DetailRow(label: 'GST number', value: gst!.gstNumber),
              DetailRow(label: 'Email', value: gst!.companyEmail),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        if (canHold) ...[
          const InfoBanner(
            icon: Icons.lock_clock_rounded,
            message:
                'This fare can be held without paying. A held booking is not '
                'ticketed until you pay, and the airline releases it if you '
                'miss the deadline.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const TermsNotice(product: 'airline'),
      ],
    );
  }
}

class _TravellerReviewRow extends StatelessWidget {
  const _TravellerReviewRow({
    required this.index,
    required this.label,
    required this.traveller,
  });

  final int index;
  final String label;
  final TravellerInput traveller;

  @override
  Widget build(BuildContext context) {
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
              Text(
                '${traveller.title} ${traveller.fullName}',
                style: AppText.bodyStrong,
              ),
              const SizedBox(height: 2),
              Text(
                [
                  label,
                  if (traveller.dob != null) formatTripDate(traveller.dob),
                  if (traveller.passportNumber.trim().isNotEmpty)
                    traveller.passportNumber.trim().toUpperCase(),
                ].join(' · '),
                style: AppText.caption,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
