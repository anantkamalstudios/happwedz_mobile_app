/// The airport-transfer booking funnel.
///
/// Cabs are the shortest of the four flows — one lead passenger, no seat map,
/// no fare rules — so it stays a single scroll with a sticky pay bar rather
/// than a stepper.
///
/// ```
/// book (payment pending)  →  pay  →  verify + settle  →  confirmed
/// ```
///
/// The booking is created *before* the payment, so a lost verification does
/// not lose the booking: [_checkStatus] reconciles against the supplier and
/// either confirms it or lets the traveller pay again.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../widgets/honeymoon_widgets.dart';
import '../bookings/my_trips_page.dart';
import 'booking_confirmation_page.dart';
import 'booking_widgets.dart';

class CabBookingPage extends StatefulWidget {
  const CabBookingPage({
    super.key,
    required this.api,
    required this.quote,
    required this.result,
    required this.pickupLabel,
    required this.dropLabel,
    required this.pickupAt,
  });

  final HoneymoonApi api;
  final CabQuote quote;

  /// The whole quotes response — `journeyInfo` and `routeDetails` are echoed
  /// back verbatim in the booking payload.
  final CabQuoteResult result;

  final String pickupLabel;
  final String dropLabel;
  final DateTime pickupAt;

  @override
  State<CabBookingPage> createState() => _CabBookingPageState();
}

class _CabBookingPageState extends State<CabBookingPage> {
  final _passenger = CabPassengerInput();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _flightNumber = TextEditingController();
  final _request = TextEditingController();

  final Map<String, String> _errors = {};
  final Map<String, GlobalKey> _anchors = {};

  bool _submitting = false;
  String? _stage;
  String? _error;

  /// Set once the supplier has a booking. Kept so a failed payment can be
  /// retried, or reconciled, against the booking that already exists.
  String? _bookingId;

  /// Shown after a payment whose result we never saw — the money may have
  /// left the traveller's account even though we got no confirmation.
  bool _canReconcile = false;

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _email,
      _phone,
      _flightNumber,
      _request,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey _anchorFor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  FareBreakdown get _fare => FareBreakdown(
    lines: [
      FareLine('Base fare', widget.quote.netFare, detail: widget.quote.vehicleName),
      if (widget.quote.totalTax > 0)
        FareLine('Taxes & fees', widget.quote.totalTax),
    ],
    total: widget.quote.price,
  );

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  bool _validate() {
    final errors = <String, String>{};

    if (_firstName.text.trim().isEmpty) {
      errors['firstName'] = 'First name is required';
    }
    if (_lastName.text.trim().isEmpty) {
      errors['lastName'] = 'Last name is required';
    }
    final email = _email.text.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address';
    }
    final phone = _phone.text.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(phone)) {
      errors['phone'] = 'Enter a valid phone number';
    }

    setState(() {
      _errors
        ..clear()
        ..addAll(errors);
    });

    if (errors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _anchors[errors.keys.first]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: AppMotion.normal,
            curve: AppMotion.standard,
            alignment: 0.2,
          );
        }
      });
      return false;
    }

    _passenger
      ..firstName = _firstName.text.trim()
      ..lastName = _lastName.text.trim()
      ..email = email
      ..phone = _phone.text.trim()
      ..flightNumber = _flightNumber.text.trim()
      ..serviceRequest = _request.text.trim();
    return true;
  }

  // -------------------------------------------------------------------------
  // Booking + payment
  // -------------------------------------------------------------------------

  Map<String, dynamic> get _bookingPayload => <String, dynamic>{
    'journeyInfo': widget.result.journeyInfo,
    // The quotes response calls this `routeDetails`; the booking endpoint
    // expects the singular. Renaming it here is not a typo.
    'routeDetail': widget.result.routeDetails,
    'addons': const <dynamic>[],
    'quotationInfo': widget.quote.toQuotationInfo(),
    'pricingInfo': widget.quote.toPricingInfo(),
    'passengerDetail': _passenger.toJson(),
    'serviceRequest': _passenger.serviceRequest,
    'consent': 'yes',
    'agentEmail': _passenger.email,
    'agentPhone': _passenger.phone,
    'vendorId': widget.quote.vendorId,
  };

  Future<void> _bookAndPay() async {
    if (_submitting) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
      _canReconcile = false;
    });

    try {
      // Reuse an existing booking when the traveller is retrying a payment —
      // creating a second one would double-book the same car.
      var bookingId = _bookingId;
      if (bookingId == null) {
        setState(() => _stage = 'Reserving your cab…');
        final booking = await widget.api.createCabBooking(_bookingPayload);
        bookingId = asString(readKey(booking, 'id'));
        if (!mounted) return;
        setState(() => _bookingId = bookingId);
      }

      setState(() => _stage = 'Starting secure payment…');
      final order = await widget.api.createCabPaymentOrder(
        bookingId: bookingId,
        // The traveller pays what the page shows; the supplier is settled at
        // the quoted gross. Sending the same figure for both is rejected once
        // a service charge is applied.
        amount: _fare.total,
        supplierAmount: widget.quote.price,
      );
      if (!mounted) return;

      setState(() => _stage = null);
      final outcome = await RazorpayCheckout.open(
        context,
        order: order,
        title: 'HappyWedz Cabs',
        description: '${widget.quote.vehicleName} · $bookingId',
        prefill: (
          name: '${_passenger.firstName} ${_passenger.lastName}'.trim(),
          email: _passenger.email,
          contact: _passenger.phone,
        ),
      );
      if (!mounted) return;

      switch (outcome) {
        case RazorpayDismissed():
          setState(
            () => _error = 'The payment was cancelled before it completed.',
          );
        case RazorpayFailure(:final message):
          setState(() => _error = message);
        case RazorpaySuccess(:final result):
          setState(() => _stage = 'Confirming your cab…');
          final confirmed = await widget.api.verifyCabPayment({
            ...result.toVerifyJson(),
            'bookingId': bookingId,
          });
          if (!mounted) return;
          _goToConfirmation(confirmed);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = bookingErrorText(e);
        // The signature may have been valid and settlement failed afterwards,
        // in which case the backend refunds — but the traveller cannot know
        // that from here, so offer the reconciliation instead of a dead end.
        _canReconcile = _bookingId != null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _stage = null;
        });
      }
    }
  }

  /// Reconciles against the supplier when a payment result was lost — a
  /// dropped connection after the charge, most often.
  Future<void> _checkStatus() async {
    final bookingId = _bookingId;
    if (bookingId == null || _submitting) return;

    setState(() {
      _submitting = true;
      _stage = 'Checking payment status…';
    });

    try {
      final bookings = await widget.api.fetchCabBookings([bookingId]);
      if (!mounted) return;

      final booking = bookings.isEmpty ? null : bookings.first;
      if (booking != null &&
          booking.paymentStatus.toUpperCase() == 'SUCCESS') {
        _goToConfirmation(
          BookingOutcome(
            product: TravelProduct.cab,
            reference: booking.reference,
            status: booking.status,
            amountPaid: booking.amount,
          ),
        );
        return;
      }

      setState(() {
        _canReconcile = false;
        _error =
            'That payment has not been confirmed. You can safely try paying '
            'again — you will not be charged twice for the same booking.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = bookingErrorText(e));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _stage = null;
        });
      }
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
                  initialProduct: TravelProduct.cab,
                ),
              ),
            );
          },
          summaryTitle: widget.quote.vehicleName,
          summarySubtitle: '${widget.pickupLabel} → ${widget.dropLabel}',
          details: [
            DetailRow(
              label: 'Pick-up',
              value: formatTripDateTime(widget.pickupAt),
              icon: Icons.schedule_rounded,
            ),
            DetailRow(
              label: 'From',
              value: widget.pickupLabel,
              icon: Icons.trip_origin_rounded,
            ),
            DetailRow(
              label: 'To',
              value: widget.dropLabel,
              icon: Icons.place_outlined,
            ),
            DetailRow(
              label: 'Passenger',
              value: '${_passenger.firstName} ${_passenger.lastName}'.trim(),
              icon: Icons.person_outline_rounded,
            ),
          ],
          nextSteps: const [
            (
              title: 'Voucher on its way',
              body: 'Your booking voucher is emailed right after the payment.',
            ),
            (
              title: 'Cab and driver details',
              body:
                  'We share the vehicle and driver details about 6 hours '
                  'before your pick-up.',
            ),
            (
              title: 'On-time pick-up',
              body:
                  'Your cab arrives at the pick-up point at the scheduled '
                  'time. Enjoy the ride.',
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isAirport = widget.result.isAirportTransfer;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppTopBar(title: 'Confirm your transfer', elevated: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          if (_error != null) ...[
            InfoBanner(
              tone: InfoTone.error,
              icon: Icons.error_outline_rounded,
              message: _error!,
              action: _canReconcile
                  ? PremiumButton.text(
                      label: 'Check status',
                      size: PremiumButtonSize.small,
                      onPressed: _submitting ? null : _checkStatus,
                    )
                  : null,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _JourneyCard(
            pickupLabel: widget.pickupLabel,
            dropLabel: widget.dropLabel,
            pickupAt: widget.pickupAt,
          ),
          const SizedBox(height: AppSpacing.md),

          _VehicleCard(quote: widget.quote),
          const SizedBox(height: AppSpacing.md),

          FormSection(
            title: 'Lead passenger',
            subtitle: 'The driver will look for this name',
            icon: Icons.person_outline_rounded,
            children: [
              KeyedSubtree(
                key: _anchorFor('firstName'),
                child: AppTextField(
                  controller: _firstName,
                  label: 'First name',
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['firstName'],
                  autofillHints: const [AutofillHints.givenName],
                  onChanged: (_) => _clear('firstName'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('lastName'),
                child: AppTextField(
                  controller: _lastName,
                  label: 'Last name',
                  required: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['lastName'],
                  autofillHints: const [AutofillHints.familyName],
                  onChanged: (_) => _clear('lastName'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('email'),
                child: AppTextField(
                  controller: _email,
                  label: 'Email address',
                  required: true,
                  hint: 'you@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['email'],
                  autofillHints: const [AutofillHints.email],
                  onChanged: (_) => _clear('email'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('phone'),
                child: AppTextField(
                  controller: _phone,
                  label: 'Mobile number',
                  required: true,
                  helperText: 'The driver calls this number on the day',
                  keyboardType: TextInputType.phone,
                  maxLength: 15,
                  errorText: _errors['phone'],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                  ],
                  autofillHints: const [AutofillHints.telephoneNumber],
                  onChanged: (_) => _clear('phone'),
                ),
              ),
              if (isAirport) ...[
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _flightNumber,
                  label: 'Flight number',
                  hint: 'e.g. 6E 2134',
                  helperText:
                      'Optional — lets the driver track your flight and wait '
                      'if it is delayed',
                  textCapitalization: TextCapitalization.characters,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          FormSection(
            title: 'Anything we should know?',
            subtitle: 'Optional',
            icon: Icons.chat_bubble_outline_rounded,
            children: [
              AppTextField(
                controller: _request,
                hint: 'Child seat, extra luggage, a different pick-up point…',
                maxLines: 3,
                minLines: 2,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),

          if (widget.quote.benefits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            FormSection(
              title: 'Included',
              icon: Icons.verified_outlined,
              children: [
                for (final benefit in widget.quote.benefits)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_outline_rounded,
                            size: 16,
                            color: AppColors.successDark,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(child: Text(benefit, style: AppText.bodySm)),
                      ],
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          if (_stage != null) ...[
            InfoBanner(
              icon: Icons.autorenew_rounded,
              message: _stage!,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const TermsNotice(product: 'transfer'),
        ],
      ),
      bottomNavigationBar: BookingActionBar(
        fare: _fare,
        priceLabel: 'Total payable',
        actionLabel: 'Pay & confirm',
        isLoading: _submitting,
        onAction: _bookAndPay,
        onShowBreakdown: () => showFareBreakdownSheet(
          context,
          _fare,
          title: 'Fare breakdown',
          footnote:
              'Tolls, parking and any waiting time beyond the included '
              'allowance are payable to the driver.',
        ),
      ),
    );
  }

  void _clear(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }
}

// ---------------------------------------------------------------------------

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({
    required this.pickupLabel,
    required this.dropLabel,
    required this.pickupAt,
  });

  final String pickupLabel;
  final String dropLabel;
  final DateTime pickupAt;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  formatTripDateTime(pickupAt),
                  style: AppText.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // A vertical timeline reads better than two columns when addresses
          // are long enough to wrap, which they usually are.
          _Stop(
            icon: Icons.trip_origin_rounded,
            label: 'Pick-up',
            value: pickupLabel,
            showConnector: true,
          ),
          _Stop(
            icon: Icons.place_rounded,
            label: 'Drop-off',
            value: dropLabel,
            showConnector: false,
          ),
        ],
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.icon,
    required this.label,
    required this.value,
    required this.showConnector,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 3),
                    color: AppColors.divider,
                  ),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? AppSpacing.lg : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppText.caption),
                  const SizedBox(height: 2),
                  Text(value, style: AppText.bodyStrong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.quote});

  final CabQuote quote;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          if (quote.imageUrl.isNotEmpty)
            NetworkImageWidget(
              url: quote.imageUrl,
              width: 76,
              height: 58,
              radius: AppRadii.md,
              memCacheWidth: 230,
            )
          else
            Container(
              width: 76,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.pinkSurface,
                borderRadius: AppRadii.rMd,
              ),
              child: const Icon(
                Icons.directions_car_filled_rounded,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  quote.vehicleName,
                  style: AppText.cardTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (quote.category.isNotEmpty)
                      MetaChip(label: quote.category),
                    if (quote.seats > 0)
                      MetaChip(
                        icon: Icons.event_seat_rounded,
                        label: '${quote.seats} seats',
                      ),
                    if (quote.luggage > 0)
                      MetaChip(
                        icon: Icons.luggage_rounded,
                        label: '${quote.luggage} bags',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
