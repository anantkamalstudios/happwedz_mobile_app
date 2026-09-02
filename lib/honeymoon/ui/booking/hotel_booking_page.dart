/// The hotel booking funnel.
///
/// ```
/// review (final price + what the hotel requires)
///   └─ guest names + contact  →  pay  →  verify & book  →  confirmed
/// ```
///
/// The review step is not decoration: it is where the supplier tells us the
/// real payable amount and whether this property demands a PAN or a passport,
/// so the form below is built from its answer rather than from assumptions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core.dart';
import '../../data/honeymoon_api.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../hotel_detail_page.dart';
import '../widgets/honeymoon_widgets.dart';
import '../bookings/my_trips_page.dart';
import 'booking_confirmation_page.dart';
import 'booking_widgets.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({
    super.key,
    required this.api,
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
    required this.detail,
    this.searchId = '',
  });

  final HoneymoonApi api;
  final HotelResult hotel;
  final HotelRoomOption room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;
  final String searchId;

  /// The raw `hotels/detail` response the room came from — the review payload
  /// is keyed on ids that exist only there.
  final Map<String, dynamic> detail;

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  // --- Review --------------------------------------------------------------

  Map<String, dynamic> _review = const {};
  bool _loadingReview = true;
  Object? _reviewError;

  String get _bookingId => asString(readKey(_review, 'bookingId'));

  bool get _panRequired =>
      readKey(digPath(_review, ['bookingRequirements']), 'panRequired') == true;

  bool get _passportRequired =>
      readKey(digPath(_review, ['bookingRequirements']), 'passportRequired') ==
      true;

  /// What the supplier will actually charge. Several shapes carry it, and the
  /// booking is rejected if we send a different figure, so all of them are
  /// tried before falling back to the price the room card showed.
  double get _payableAmount {
    final candidates = <Object?>[
      digPath(_review, ['priceSummary', 'amount']),
      digPath(_review, ['selectedOption', 'pricing', 'totalPrice']),
      digPath(_review, ['selectedOption', 'totalPrice']),
      digPath(_review, ['selectedOption', 'tp']),
    ];
    for (final c in candidates) {
      final value = asDouble(c);
      if (value > 0) return value;
    }
    return widget.room.price;
  }

  // --- Form ----------------------------------------------------------------

  final _guest = HotelGuestInput(isLead: true);

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _pan = TextEditingController();
  final _passport = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  String _countryCode = '+91';

  final Map<String, String> _errors = {};
  final Map<String, GlobalKey> _anchors = {};

  bool _submitting = false;
  String? _stage;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _openReview();
  }

  @override
  void dispose() {
    for (final c in [
      _firstName,
      _lastName,
      _pan,
      _passport,
      _email,
      _mobile,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  GlobalKey _anchorFor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  // -------------------------------------------------------------------------
  // Review
  // -------------------------------------------------------------------------

  /// The supplier accepts two payload shapes here — a newer correlation-based
  /// one and a legacy search-based one — and which ids came back depends on
  /// how the detail was fetched. Both are sent; the backend uses whichever is
  /// complete.
  Map<String, dynamic> get _reviewPayload {
    final detail = widget.detail;
    final option = widget.room.raw;

    final correlationId = firstNonEmpty([
      readKey(detail, 'correlationId'),
      digPath(detail, ['data', 'correlationId']),
    ]);
    final detailRequestId = firstNonEmpty([
      readKey(detail, 'detailRequestId'),
      readKey(detail, 'reviewHash'),
      digPath(detail, ['data', 'detailRequestId']),
    ]);
    final hotelId = firstNonEmpty([
      readKey(detail, 'tjHotelId'),
      digPath(detail, ['hotel', 'tjid']),
      digPath(detail, ['data', 'tjHotelId']),
      readKey(option, 'hid'),
    ], fallback: widget.hotel.id);

    return <String, dynamic>{
      'correlationId': correlationId,
      'reviewHash': detailRequestId,
      'hid': hotelId,
      'searchId': widget.searchId,
      'detailRequestId': detailRequestId,
      'optionId': widget.room.optionId,
      'tjHotelId': hotelId,
    };
  }

  Future<void> _openReview() async {
    setState(() {
      _loadingReview = true;
      _reviewError = null;
    });
    try {
      final review = await widget.api.reviewHotelBooking(_reviewPayload);
      if (!mounted) return;
      setState(() {
        _review = review;
        _loadingReview = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        _reviewError = e;
      });
    }
  }

  FareBreakdown get _fare {
    final total = _payableAmount;
    final perNight = widget.nights > 0 ? total / widget.nights : total;
    return FareBreakdown(
      lines: [
        FareLine(
          widget.room.name,
          total,
          detail: widget.nights > 0
              ? '${widget.nights} night${widget.nights == 1 ? '' : 's'} · '
                    '${formatPrice(perNight)} per night'
              : '',
        ),
      ],
      total: total,
    );
  }

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
    if (!_email.text.trim().contains('@') || _email.text.trim().length < 5) {
      errors['email'] = 'Enter a valid email address';
    }
    if (_mobile.text.trim().length < 10) {
      errors['mobile'] = 'Enter a valid mobile number';
    }
    // A 10-character PAN in the AAAAA9999A pattern; the hotel rejects
    // anything else outright rather than at check-in.
    if (_panRequired &&
        !RegExp(
          r'^[A-Z]{5}[0-9]{4}[A-Z]$',
        ).hasMatch(_pan.text.trim().toUpperCase())) {
      errors['pan'] = 'Enter a valid 10-character PAN';
    }
    if (_passportRequired && _passport.text.trim().isEmpty) {
      errors['passport'] = 'This property requires a passport number';
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

    _guest
      ..firstName = _firstName.text.trim()
      ..lastName = _lastName.text.trim()
      ..pan = _pan.text.trim()
      ..passportNumber = _passport.text.trim();
    return true;
  }

  // -------------------------------------------------------------------------
  // Booking
  // -------------------------------------------------------------------------

  Map<String, dynamic> get _bookingPayload => <String, dynamic>{
    'bookingId': _bookingId,
    'roomTravellerInfo': [
      {
        'travellerInfo': [
          _guest.toJson(
            panRequired: _panRequired,
            passportRequired: _passportRequired,
          ),
        ],
      },
    ],
    'deliveryInfo': {
      'emails': [_email.text.trim()],
      'contacts': [_mobile.text.trim()],
      'code': [_countryCode.replaceFirst('+', '')],
    },
    'paymentInfos': [
      {'amount': _payableAmount},
    ],
    'expectedAmount': _payableAmount,
    'type': 'HOTEL',
    'ipr': _panRequired,
    'ipm': _passportRequired,
    'hotelId': firstNonEmpty([
      digPath(_review, ['hotelInfo', 'tjid']),
      digPath(_review, ['hotelSummary', 'tjid']),
    ], fallback: widget.hotel.id),
    'optionId': firstNonEmpty([
      digPath(_review, ['selectedOption', 'optionId']),
      digPath(_review, ['selectedOption', 'id']),
    ], fallback: widget.room.optionId),
    'reviewData': _review,
  };

  Future<void> _pay() async {
    if (_submitting || _bookingId.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (!_validate()) {
      AppSnackbar.error(context, 'Please complete the highlighted details.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final payload = _bookingPayload;

      setState(() => _stage = 'Starting secure payment…');
      final order = await widget.api.createHotelPaymentOrder(payload);
      if (!mounted) return;

      setState(() => _stage = null);
      final outcome = await RazorpayCheckout.open(
        context,
        order: order,
        title: 'HappyWedz Hotels',
        description: widget.hotel.name,
        prefill: (
          name: '${_guest.firstName} ${_guest.lastName}'.trim(),
          email: _email.text.trim(),
          contact: _mobile.text.trim(),
        ),
      );
      if (!mounted) return;

      switch (outcome) {
        case RazorpayDismissed():
          setState(
            () => _submitError =
                'The payment was cancelled before it completed. Your room is '
                'not held — prices can change if you wait.',
          );
        case RazorpayFailure(:final message):
          setState(() => _submitError = message);
        case RazorpaySuccess(:final result):
          setState(() => _stage = 'Confirming with the hotel…');
          final booking = await widget.api.verifyHotelPaymentAndBook({
            'bookingId': _bookingId,
            ...result.toVerifyJson(),
          });
          if (!mounted) return;
          _goToConfirmation(booking);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitError = bookingErrorText(e));
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
                  initialProduct: TravelProduct.hotel,
                ),
              ),
            );
          },
          summaryTitle: widget.hotel.name,
          summarySubtitle: widget.hotel.address.isNotEmpty
              ? widget.hotel.address
              : widget.hotel.city,
          details: [
            DetailRow(
              label: 'Check-in',
              value: formatTripDate(widget.checkIn),
              icon: Icons.login_rounded,
            ),
            DetailRow(
              label: 'Check-out',
              value: formatTripDate(widget.checkOut),
              icon: Icons.logout_rounded,
            ),
            DetailRow(
              label: 'Room',
              value: widget.room.name,
              icon: Icons.king_bed_outlined,
            ),
            DetailRow(
              label: 'Guest',
              value: '${_guest.firstName} ${_guest.lastName}'.trim(),
              icon: Icons.person_outline_rounded,
            ),
          ],
          nextSteps: const [
            (
              title: 'Voucher on its way',
              body:
                  'Your hotel voucher is emailed once the property confirms, '
                  'usually within a few minutes.',
            ),
            (
              title: 'At check-in',
              body:
                  'Show the voucher and a photo ID for every guest. Some '
                  'properties ask for the card used to pay.',
            ),
            (
              title: 'Need to change it?',
              body:
                  'Cancellation terms depend on the rate you booked — they '
                  'are on your voucher.',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Guest details',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(widget.checkIn)} – '
              '${formatTripDate(widget.checkOut)}',
              style: AppText.caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: AsyncView(
        isLoading: _loadingReview,
        error: _reviewError,
        onRetry: _openReview,
        errorTitle: 'That room is no longer available',
        errorMessage:
            'The rate we had has changed or sold out. Go back and pick '
            'another room.',
        child: _form(),
      ),
      bottomNavigationBar: _loadingReview || _reviewError != null
          ? null
          : BookingActionBar(
              fare: _fare,
              priceLabel: 'Total payable',
              actionLabel: 'Pay & book',
              isLoading: _submitting,
              onAction: _pay,
              onShowBreakdown: () => showFareBreakdownSheet(
                context,
                _fare,
                title: 'Price breakdown',
                footnote:
                    'City taxes and resort fees, where a property charges '
                    'them, are payable at check-in.',
              ),
            ),
    );
  }

  Widget _form() {
    final priceMoved =
        widget.room.price > 0 &&
        (_payableAmount - widget.room.price).abs() >= 1;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        if (_submitError != null) ...[
          InfoBanner(
            tone: InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _submitError!,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        _StayCard(
          hotel: widget.hotel,
          room: widget.room,
          checkIn: widget.checkIn,
          checkOut: widget.checkOut,
          nights: widget.nights,
        ),
        const SizedBox(height: AppSpacing.md),

        if (priceMoved) ...[
          InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.price_change_outlined,
            message:
                'The hotel re-quoted this room at ${formatPrice(_payableAmount)} '
                'when we confirmed availability.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        FormSection(
          title: 'Lead guest',
          subtitle: 'Exactly as on the ID they will present at check-in',
          icon: Icons.person_outline_rounded,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  // Narrow enough that the name field beside it stays usable
                  // at 320 px.
                  width: 88,
                  child: PickerField(
                    label: 'Title',
                    value: _guest.title,
                    onTap: () async {
                      final picked = await showOptionSheet<String>(
                        context,
                        title: 'Title',
                        options: const ['Mr', 'Mrs', 'Ms'],
                        labelOf: (v) => v,
                        selected: _guest.title,
                      );
                      if (picked != null) setState(() => _guest.title = picked);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: KeyedSubtree(
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
                ),
              ],
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
            if (_panRequired) ...[
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('pan'),
                child: AppTextField(
                  controller: _pan,
                  label: 'PAN',
                  required: true,
                  helperText: 'This property requires a PAN to confirm',
                  maxLength: 10,
                  textCapitalization: TextCapitalization.characters,
                  errorText: _errors['pan'],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (_) => _clear('pan'),
                ),
              ),
            ],
            if (_passportRequired) ...[
              const SizedBox(height: AppSpacing.md),
              KeyedSubtree(
                key: _anchorFor('passport'),
                child: AppTextField(
                  controller: _passport,
                  label: 'Passport number',
                  required: true,
                  helperText: 'Required by this property for check-in',
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  errorText: _errors['passport'],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                  ],
                  onChanged: (_) => _clear('passport'),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        FormSection(
          title: 'Contact details',
          subtitle: 'Where your voucher goes',
          icon: Icons.alternate_email_rounded,
          children: [
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
              key: _anchorFor('mobile'),
              child: PhoneField(
                controller: _mobile,
                countryCode: _countryCode,
                errorText: _errors['mobile'],
                onCountryCodeChanged: (code) =>
                    setState(() => _countryCode = code),
              ),
            ),
          ],
        ),

        if (widget.room.cancellation.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          FormSection(
            title: 'Cancellation policy',
            icon: Icons.policy_outlined,
            children: [
              Text(widget.room.cancellation, style: AppText.bodySm),
            ],
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        if (_stage != null) ...[
          InfoBanner(icon: Icons.autorenew_rounded, message: _stage!),
          const SizedBox(height: AppSpacing.md),
        ],
        const TermsNotice(product: 'hotel'),
      ],
    );
  }

  void _clear(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }
}

// ---------------------------------------------------------------------------

class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.hotel,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.nights,
  });

  final HotelResult hotel;
  final HotelRoomOption room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int nights;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkImageWidget(
                url: hotel.imageUrl,
                width: 72,
                height: 72,
                radius: AppRadii.md,
                memCacheWidth: 220,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hotel.name,
                      style: AppText.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hotel.address.isNotEmpty ? hotel.address : hotel.city,
                      style: AppText.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: AppSpacing.md),
          // Two dates side by side is the one place a Row is safe here: both
          // values are short and each half is constrained.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Check-in',
                  value: formatTripDate(checkIn),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Check-out',
                  value: formatTripDate(checkOut),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              MetaChip(icon: Icons.king_bed_outlined, label: room.name),
              if (nights > 0)
                MetaChip(
                  icon: Icons.nights_stay_outlined,
                  label: '$nights night${nights == 1 ? '' : 's'}',
                ),
              if (room.mealPlan.isNotEmpty)
                MetaChip(icon: Icons.restaurant_rounded, label: room.mealPlan),
              if (room.refundable != null)
                MetaChip(
                  icon: room.refundable!
                      ? Icons.check_circle_outline_rounded
                      : Icons.block_rounded,
                  label: room.refundable! ? 'Refundable' : 'Non-refundable',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.caption),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppText.bodyStrong,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
