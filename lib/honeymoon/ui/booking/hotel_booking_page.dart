/// The hotel booking funnel — the web's `TripJackBookingReview` page and the
/// `handleProceedToBook` / `handleCreateHoldBooking` logic behind it.
///
/// ```
/// review (final price + what the rate requires)
///   └─ guests (every room) + contact + PAN + terms
///        ├─ pay  → create order → Razorpay → verify & book ─┐
///        └─ hold → hotels/hold ─────────────────────────────┤
///                                                           └→ status (polls)
/// ```
///
/// The review step is not decoration: it is where the supplier tells us the
/// real payable amount and whether this rate demands a PAN or a passport, so
/// the form below is built from its answer rather than from assumptions.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// import '../../../authservice.dart'; // GUEST-FIRST: gate moved to requireAuthentication
import '../../../core/core.dart';
import '../../../main.dart' show requireAuthentication;
import '../../data/honeymoon_api.dart';
import '../../data/hotel_draft_store.dart';
import '../../models/booking_models.dart';
import '../../models/honeymoon_models.dart';
import '../../models/hotel_models.dart';
import '../../payment/razorpay_checkout.dart';
import '../widgets/honeymoon_widgets.dart';
import '../widgets/hotel_widgets.dart';
import 'booking_widgets.dart';
import 'hotel_booking_status_page.dart';

class HotelBookingPage extends StatefulWidget {
  const HotelBookingPage({
    super.key,
    required this.api,
    required this.hotel,
    required this.room,
    required this.query,
    required this.detail,
    this.searchId = '',
    this.staticContent = HotelStaticContent.empty,
    this.restoreDraft,
  });

  final HoneymoonApi api;
  final HotelResult hotel;
  final HotelRoomOption room;
  final HotelSearchQuery query;
  final String searchId;

  /// The raw `hotels/detail` response the room came from — the review payload
  /// is keyed on ids that exist only there.
  final Map<String, dynamic> detail;

  /// For the stay times, address and policies the review does not repeat.
  final HotelStaticContent staticContent;

  /// A form parked before a sign-in, merged onto the form built from the
  /// fresh review — the web's `handleReviewRoomOption({restoreForm})`.
  final HotelBookingDraft? restoreDraft;

  @override
  State<HotelBookingPage> createState() => _HotelBookingPageState();
}

/// One guest's inputs.
class _GuestFields {
  _GuestFields({required bool isLead, required bool isChild})
    : input = HotelGuestInput(isLead: isLead, isChild: isChild);

  final HotelGuestInput input;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final passport = TextEditingController();

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    passport.dispose();
  }
}

/// One room's guests plus the PAN collected against its lead guest.
class _RoomFields {
  _RoomFields(this.guests);

  final List<_GuestFields> guests;
  final pan = TextEditingController();

  /// The lead is the room's first adult.
  int get leadIndex {
    final i = guests.indexWhere((g) => !g.input.isChild);
    return i < 0 ? 0 : i;
  }

  int get adults => guests.where((g) => !g.input.isChild).length;
  int get children => guests.where((g) => g.input.isChild).length;

  void dispose() {
    for (final g in guests) {
      g.dispose();
    }
    pan.dispose();
  }
}

class _HotelBookingPageState extends State<HotelBookingPage> {
  // --- Review --------------------------------------------------------------

  HotelReview? _review;
  bool _loadingReview = true;
  Object? _reviewError;

  String get _bookingId => _review?.bookingId ?? '';
  bool get _panRequired => _review?.panRequired ?? widget.room.panRequired;
  bool get _passportRequired =>
      _review?.passportRequired ?? widget.room.passportRequired;

  /// What the supplier will actually charge. The booking is rejected if a
  /// different figure is sent, so the review's amount always wins.
  double get _payableAmount {
    final amount = _review?.amount ?? 0;
    return amount > 0 ? amount : widget.room.price;
  }

  // --- Form ----------------------------------------------------------------

  List<_RoomFields> _rooms = const [];
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  String _countryCode = '+91';
  bool _termsAccepted = false;

  /// The web's "Personal PAN / Corporate PAN" switch. It only relabels the
  /// name field; the payload carries the PAN on the room's lead guest either
  /// way.
  bool _corporatePan = false;

  final Map<String, String> _errors = {};
  final Map<String, GlobalKey> _anchors = {};

  bool _submitting = false;
  String? _stage;
  String? _submitError;

  /// A payment already went through for this booking but the booking itself
  /// failed. The next submit retries the booking *without* charging again —
  /// the web's `retryWithoutRepayment`.
  bool _paymentCaptured = false;

  @override
  void initState() {
    super.initState();
    _openReview();
  }

  @override
  void dispose() {
    for (final r in _rooms) {
      r.dispose();
    }
    _email.dispose();
    _mobile.dispose();
    super.dispose();
  }

  GlobalKey _anchorFor(String key) => _anchors.putIfAbsent(key, GlobalKey.new);

  // -------------------------------------------------------------------------
  // Review
  // -------------------------------------------------------------------------

  /// The supplier accepts two payload shapes — the official one keyed on
  /// `correlationId + reviewHash + hid` and a legacy one on `searchId +
  /// detailRequestId + tjHotelId` — and both are sent. Ids resolve in the
  /// web's order (`handleReviewRoomOption` / `getReviewPayloadFields`).
  Map<String, dynamic> get _reviewPayload {
    final detail = widget.detail;
    final meta = readKey(detail, 'metaData');

    final correlationId = firstNonEmpty([
      readKey(detail, 'correlationId'),
      readKey(meta, 'correlationId'),
      digPath(detail, ['data', 'correlationId']),
      widget.query.correlationId,
    ]);
    final reviewHash = firstNonEmpty([
      readKey(meta, 'requestId'),
      readKey(meta, 'reviewHash'),
      readKey(detail, 'reviewHash'),
      readKey(detail, 'requestId'),
      readKey(detail, 'detailRequestId'),
      digPath(detail, ['data', 'detailRequestId']),
      readKey(widget.room.raw, 'reviewHash'),
      readKey(widget.room.raw, 'requestId'),
    ]);
    final searchId = firstNonEmpty([
      readKey(meta, 'searchId'),
      readKey(detail, 'searchId'),
      widget.searchId,
    ]);
    final hotelId = firstNonEmpty([
      readKey(detail, 'tjHotelId'),
      readKey(detail, 'hotelId'),
      digPath(detail, ['hotelInfo', 'tjid']),
      digPath(detail, ['hotel', 'tjid']),
      digPath(detail, ['data', 'tjHotelId']),
    ], fallback: widget.hotel.id);

    return <String, dynamic>{
      'correlationId': correlationId,
      'reviewHash': reviewHash,
      'hid': hotelId,
      'searchId': searchId,
      'detailRequestId': reviewHash,
      'optionId': widget.room.optionId,
      'tjHotelId': hotelId,
    };
  }

  Future<void> _openReview() async {
    setState(() {
      _loadingReview = true;
      _reviewError = null;
    });

    final payload = _reviewPayload;
    final official =
        asString(payload['correlationId']).isNotEmpty &&
        asString(payload['reviewHash']).isNotEmpty &&
        asString(payload['optionId']).isNotEmpty &&
        asString(payload['hid']).isNotEmpty;
    final legacy =
        asString(payload['searchId']).isNotEmpty &&
        asString(payload['detailRequestId']).isNotEmpty &&
        asString(payload['optionId']).isNotEmpty &&
        asString(payload['tjHotelId']).isNotEmpty;
    if (!official && !legacy) {
      // The web refuses to send an incomplete review rather than let the
      // supplier reject it.
      setState(() {
        _loadingReview = false;
        _reviewError = HoneymoonApiException(
          'Some room details are missing. Please go back and pick the room '
          'again.',
        );
      });
      return;
    }

    try {
      final review = await widget.api.reviewHotelBooking(payload);
      if (!mounted) return;
      setState(() {
        _review = review;
        _rooms = _buildRooms(review);
        _loadingReview = false;
      });
      final draft = widget.restoreDraft;
      if (draft != null && !_restored) {
        _restored = true;
        _applyDraft(draft);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingReview = false;
        // The parked rate expired or sold out while the traveller signed in;
        // say so instead of the generic error, as the web does.
        _reviewError = widget.restoreDraft != null && !_restored
            ? HoneymoonApiException(
                'That room is no longer available at the saved price. Please '
                'go back and pick a room again.',
              )
            : e;
      });
    }
  }

  bool _restored = false;

  /// Merges a parked form onto the one built from the fresh review — the
  /// web's `mergeBookingForm`. Room and guest counts follow the new review;
  /// saved values land only where a matching slot (same room, same position,
  /// same adult/child type) still exists. PAN was never stored, and the
  /// terms are asked for again because the policy may have changed.
  void _applyDraft(HotelBookingDraft draft) {
    for (var r = 0; r < _rooms.length && r < draft.rooms.length; r++) {
      final saved = draft.rooms[r];
      final guests = _rooms[r].guests;
      for (var g = 0; g < guests.length && g < saved.length; g++) {
        final fields = guests[g];
        final entry = saved[g];
        if (entry.isChild != fields.input.isChild) continue;
        if (fields.input.titles.contains(entry.title)) {
          fields.input.title = entry.title;
        }
        fields.firstName.text = entry.firstName;
        fields.lastName.text = entry.lastName;
        if (_passportRequired && !fields.input.isChild) {
          fields.passport.text = entry.passportNumber;
        }
      }
    }
    if (draft.email.isNotEmpty) _email.text = draft.email;
    if (draft.mobile.isNotEmpty) _mobile.text = draft.mobile;
    setState(() {
      if (draft.countryCode.isNotEmpty) _countryCode = draft.countryCode;
      _termsAccepted = false;
    });
    AppSnackbar.success(
      context,
      _panRequired
          ? 'Your booking details are back. Please re-enter PAN and accept '
                'the terms.'
          : 'Your booking details are back. Please review and accept the '
                'terms.',
    );
  }

  /// Parks what the traveller typed so it survives the sign-in the expired
  /// session forces — the web's `parkBookingAndLogin`. Nothing here needs a
  /// live context: the screen may already be coming down.
  Future<void> _parkDraft() {
    return HotelDraftStore.save(
      HotelBookingDraft(
        hotel: widget.hotel,
        optionId: widget.room.optionId,
        query: widget.query,
        searchId: widget.searchId,
        rooms: [
          for (final room in _rooms)
            [
              for (final g in room.guests)
                HotelDraftGuest(
                  isChild: g.input.isChild,
                  title: g.input.title,
                  firstName: g.firstName.text.trim(),
                  lastName: g.lastName.text.trim(),
                  passportNumber: g.passport.text.trim(),
                ),
            ],
        ],
        email: _email.text.trim(),
        mobile: _mobile.text.trim(),
        countryCode: _countryCode,
        savedAt: DateTime.now(),
      ),
    );
  }

  /// One block per searched room, one entry per guest in it — the web's
  /// `createInitialBookingForm`. The occupancy comes from the reviewed
  /// option's room lines, falling back to what was searched.
  List<_RoomFields> _buildRooms(HotelReview review) {
    final lines = review.option.rooms;
    return [
      for (var i = 0; i < widget.query.rooms.length; i++)
        () {
          final searched = widget.query.rooms[i];
          final line = lines.length > i
              ? lines[i]
              : (lines.isNotEmpty ? lines.first : null);
          final adults = line != null && line.adults > 0
              ? line.adults
              : searched.adults;
          final children = line != null && line.children > 0
              ? line.children
              : searched.children;
          return _RoomFields([
            for (var a = 0; a < (adults < 1 ? 1 : adults); a++)
              _GuestFields(isLead: a == 0, isChild: false),
            for (var c = 0; c < children; c++)
              _GuestFields(isLead: false, isChild: true),
          ]);
        }(),
    ];
  }

  FareBreakdown get _fare {
    final review = _review;
    if (review == null) {
      return FareBreakdown(
        lines: [FareLine(widget.room.name, _payableAmount)],
        total: _payableAmount,
      );
    }
    // Base fare, then taxes & fees split the way the web's fare summary
    // splits them: markup, management fee, management fee tax.
    return FareBreakdown(
      lines: [
        FareLine(
          'Base fare',
          review.baseFare,
          detail:
              '${widget.room.name} · ${widget.query.nights} '
              'night${widget.query.nights == 1 ? '' : 's'}',
        ),
        if (review.markup > 0) FareLine('Markup', review.markup),
        if (review.managementFee > 0)
          FareLine('Management fees', review.managementFee),
        if (review.managementFeeTax > 0)
          FareLine('Management fees tax', review.managementFeeTax),
      ],
      total: _payableAmount,
    );
  }

  // -------------------------------------------------------------------------
  // Validation — the web's `validateBookingForm`
  // -------------------------------------------------------------------------

  static final _panPattern = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _passportPattern = RegExp(
    r'^[A-Z0-9]{6,20}$',
    caseSensitive: false,
  );
  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final _phonePattern = RegExp(r'^[0-9]{7,15}$');

  bool _validate() {
    final errors = <String, String>{};

    for (var r = 0; r < _rooms.length; r++) {
      final room = _rooms[r];
      for (var g = 0; g < room.guests.length; g++) {
        final guest = room.guests[g];
        final isAdult = !guest.input.isChild;
        final isLead = g == room.leadIndex;
        final hasAnyName =
            guest.firstName.text.trim().isNotEmpty ||
            guest.lastName.text.trim().isNotEmpty;
        final needsPassport = isAdult && _passportRequired;
        // Only the lead is mandatory; a blank extra guest is skipped (the
        // backend pads it) unless someone starts filling it in — or a
        // passport is required, which it is of every adult.
        if (!isLead && !hasAnyName && !needsPassport) continue;

        if (!guest.input.titles.contains(guest.input.title)) {
          errors['title_${r}_$g'] = 'Select a title';
        }
        if (guest.firstName.text.trim().isEmpty) {
          errors['first_${r}_$g'] = 'First name is required';
        }
        if (guest.lastName.text.trim().isEmpty) {
          errors['last_${r}_$g'] = 'Last name is required';
        }
        if (needsPassport &&
            !_passportPattern.hasMatch(guest.passport.text.trim())) {
          errors['passport_${r}_$g'] = 'Enter a valid passport number';
        }
      }
      if (_panRequired) {
        final pan = room.pan.text.toUpperCase().replaceAll(
          RegExp(r'[^A-Z0-9]'),
          '',
        );
        if (!_panPattern.hasMatch(pan)) {
          errors['pan_$r'] = 'Enter a valid 10-character PAN';
        }
      }
    }

    if (!_emailPattern.hasMatch(_email.text.trim())) {
      errors['email'] = 'Enter a valid email address';
    }
    if (!_phonePattern.hasMatch(_mobile.text.trim())) {
      errors['mobile'] = 'Enter a valid mobile number';
    }
    if (!_termsAccepted) {
      errors['terms'] = 'Accept the booking terms to continue';
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

    // Copy the fields into the guest models the payload is built from.
    for (final room in _rooms) {
      for (var g = 0; g < room.guests.length; g++) {
        final guest = room.guests[g];
        guest.input
          ..firstName = guest.firstName.text.trim()
          ..lastName = guest.lastName.text.trim()
          ..passportNumber = guest.passport.text.trim()
          // BUG FIX: PAN is collected once per room, but the backend rejects
          // the booking unless *every* adult carries a valid one —
          // "roomTravellerInfo[0].travellerInfo[1].pan is required and must
          // be a valid Indian PAN format". The web sends `pan: ""` for
          // non-lead adults and hits the same 400, so the room's PAN is
          // applied to each adult in it (children carry none).
          // ..pan = g == room.leadIndex ? room.pan.text.trim() : '';
          ..pan = guest.input.isChild ? '' : room.pan.text.trim();
      }
    }
    return true;
  }

  // -------------------------------------------------------------------------
  // Payloads — the web's `buildBookingPayload`
  // -------------------------------------------------------------------------

  List<Map<String, dynamic>> get _roomTravellerInfo => [
    for (final room in _rooms)
      {
        'travellerInfo': [
          for (final g in room.guests)
            g.input.toJson(
              panRequired: _panRequired,
              passportRequired: _passportRequired,
            ),
        ],
      },
  ];

  Map<String, dynamic> get _deliveryInfo => {
    'emails': [_email.text.trim()],
    'contacts': [_mobile.text.trim()],
    // BUG FIX: TripJack rejects a bare "91" — "deliveryInfo.code : Invalid
    // country code, the format should be like '+91'". The web's form starts
    // at "+91" too.
    // 'code': [_countryCode.replaceFirst('+', '')],
    'code': [_countryCode.startsWith('+') ? _countryCode : '+$_countryCode'],
  };

  Map<String, dynamic> _bookingPayload({bool includePayment = true}) {
    final review = _review!;
    return <String, dynamic>{
      'bookingId': _bookingId,
      'roomTravellerInfo': _roomTravellerInfo,
      'deliveryInfo': _deliveryInfo,
      if (includePayment) ...{
        'paymentInfos': [
          {'amount': _payableAmount},
        ],
        'expectedAmount': _payableAmount,
      },
      'type': 'HOTEL',
      'ipr': _panRequired,
      'ipm': _passportRequired,
      'hotelId': review.hotelId.isNotEmpty ? review.hotelId : widget.hotel.id,
      'optionId': review.option.optionId.isNotEmpty
          ? review.option.optionId
          : widget.room.optionId,
      'reviewData': _reviewData,
    };
  }

  /// The review the booking is made against, in the enriched shape the web
  /// sends as `reviewData` (`normalizeReviewResponseForUi` + display names):
  /// the supplier's raw answer, plus the search, hotel, price and room
  /// summaries the backend records alongside the booking.
  Map<String, dynamic> get _reviewData {
    final review = _review!;
    final option = review.option;
    final statics = widget.staticContent;
    final hotelId = review.hotelId.isNotEmpty
        ? review.hotelId
        : widget.hotel.id;
    final hotelName = review.hotelName.isNotEmpty
        ? review.hotelName
        : widget.hotel.name;
    final images = statics.images.isNotEmpty
        ? statics.images
        : widget.hotel.images;
    final stars = statics.starRating > 0
        ? statics.starRating
        : widget.hotel.starRating;
    final firstLine = option.rooms.isEmpty ? null : option.rooms.first;

    return <String, dynamic>{
      ...review.raw,
      'searchQuery': {
        'checkInDate': apiDate(widget.query.checkIn),
        'checkoutDate': apiDate(widget.query.checkOut),
        'roomInfo': widget.query.rooms.map((r) => r.toRoomInfo()).toList(),
      },
      'hotelInfo': {
        'id': hotelId,
        'tjid': hotelId,
        'tjHotelId': hotelId,
        'name': hotelName,
        'images': images,
        'rt': stars,
        if (statics.checkInFrom.isNotEmpty)
          'checkInTime': {
            'from': statics.checkInFrom,
            'to': statics.checkInTill,
          },
        if (statics.checkOutFrom.isNotEmpty)
          'checkOutTime': {'from': statics.checkOutFrom},
      },
      'selectedOption': {
        ...option.raw,
        'id': option.optionId,
        'optionId': option.optionId,
        'mb': option.mealPlan,
        'mealBasis': option.mealPlan,
        'tp': option.pricing.total,
        'totalPrice': option.pricing.total,
        'ipr': _panRequired,
        'ipm': _passportRequired,
      },
      'bookingRequirements': {
        'panRequired': _panRequired,
        'passportRequired': _passportRequired,
        'deadlineDatetime': review.deadline.isEmpty ? null : review.deadline,
        'isRefundable': option.refundable == true,
        'isNonRefundable': option.refundable != true,
        'gstType': asString(
          digPath(option.raw, ['compliance', 'gstType']),
          fallback: 'NA',
        ),
        'onholdAllowed': review.onholdAllowed,
      },
      'priceSummary': {
        'amount': _payableAmount,
        'baseFare': review.baseFare,
        'taxesAndFees': review.taxesAndFees,
        'currency': review.currency,
        'managementFee': review.managementFee,
        'managementFeeTax': review.managementFeeTax,
      },
      'roomSummary': {
        'roomName': firstLine?.name ?? widget.room.name,
        'mealBasis': option.mealPlan,
        'adults': firstLine?.adults ?? widget.query.adults,
        'children': firstLine?.children ?? widget.query.children,
      },
      'hotelSummary': {
        'id': hotelId,
        'tjid': hotelId,
        'tjHotelId': hotelId,
        'name': hotelName,
        'rating': stars,
        'images': images,
      },
      'displayHotelName': hotelName,
      'displayRoomName': firstLine?.name ?? widget.room.name,
    };
  }

  RazorpayPrefill get _prefill {
    final lead = _rooms.isEmpty ? null : _rooms.first.guests.first.input;
    return (
      name: lead == null ? '' : '${lead.firstName} ${lead.lastName}'.trim(),
      email: _email.text.trim(),
      contact: _mobile.text.trim(),
    );
  }

  // -------------------------------------------------------------------------
  // Pay & book — the web's `handleProceedToBook`
  // -------------------------------------------------------------------------

  // Replaced by [_ensureSession], which also parks the form.
  // bool _guardSignedIn() {
  //   if (AuthSession.instance.isAuthenticated) return true;
  //   AppSnackbar.error(context, 'Please sign in to book this stay.');
  //   return false;
  // }

  /// Re-checks the session before any payment, as the web checks
  /// `isAuthenticated` in `handleProceedToBook`. A guest (or a lapsed
  /// session) signs in on top of this form and payment continues; backing
  /// out parks the form so the honeymoon screen can offer it back.
  Future<bool> _ensureSession() async {
    if (await requireAuthentication(
      context,
      reason: 'Sign in to book this stay.',
    )) {
      return true;
    }
    await _parkDraft();
    return false;
  }

  Future<void> _pay() async {
    if (_submitting || _bookingId.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (!await _ensureSession() || !mounted) return;
    if (!_validate()) {
      AppSnackbar.error(context, 'Please complete the highlighted details.');
      return;
    }
    if (_payableAmount <= 0) {
      setState(
        () => _submitError =
            'The booking amount is unavailable. Please go back and review '
            'the room again.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final payload = _bookingPayload();
    // Set once Razorpay reports success: from then on a failure must never
    // lead to a second charge.
    var paid = _paymentCaptured;

    try {
      Map<String, dynamic> booking;

      if (_paymentCaptured) {
        // The payment already went through on an earlier try; only the
        // booking failed. Resend the corrected guests without charging.
        setState(
          () => _stage =
              'Payment already received. Retrying the booking with the '
              'updated details…',
        );
        booking = await widget.api.verifyHotelPaymentAndBook({
          'bookingId': _bookingId,
          'roomTravellerInfo': payload['roomTravellerInfo'],
          'deliveryInfo': payload['deliveryInfo'],
          'ipr': payload['ipr'],
          'ipm': payload['ipm'],
          'type': payload['type'],
        });
      } else {
        setState(() => _stage = 'Starting secure payment…');
        final order = await widget.api.createHotelPaymentOrder(payload);
        if (!mounted) return;

        setState(() => _stage = null);
        final outcome = await RazorpayCheckout.open(
          context,
          order: order,
          title: 'HappyWedz Hotels',
          restrictMethodsInTestMode: true,
          allowRetry: true,
          description: order.description.isNotEmpty
              ? order.description
              : widget.hotel.name,
          prefill: _prefill,
        );
        if (!mounted) return;

        switch (outcome) {
          case RazorpayDismissed():
            setState(
              () => _submitError =
                  'The payment was cancelled before it completed. Your room '
                  'is not held — prices can change if you wait.',
            );
            return;
          case RazorpayFailure(:final message):
            setState(() => _submitError = _paymentFailureText(message));
            return;
          case RazorpaySuccess(:final result):
            paid = true;
            setState(
              () => _stage = 'Payment verified. Confirming with the hotel…',
            );
            booking = await widget.api.verifyHotelPaymentAndBook({
              'bookingId': _bookingId,
              ...result.toVerifyJson(),
            });
        }
      }
      if (!mounted) return;

      final bookingId = firstNonEmpty([
        readKey(booking, 'bookingId'),
      ], fallback: _bookingId);

      // BUG FIX: a refusal arrives as a 200 that still carries a booking id,
      // and used to be shown as a confirmed booking.
      if (isHotelSupplierDenial(booking)) {
        await _openStatus(
          bookingId: bookingId,
          phase: HotelBookingPhase.denied,
          message:
              'The booking request was declined: '
              '${hotelDenialReason(booking).isEmpty ? 'access denied' : hotelDenialReason(booking)}',
          errorCode: asString(digPath(booking, ['errors', 0, 'errCode'])),
          paymentCaptured: paid,
          initialStatus: HotelBookingStatus.fromJson(
            booking,
            fallbackBookingId: bookingId,
          ),
        );
        return;
      }

      final orderStatus = hotelOrderStatusOf(booking);
      await _openStatus(
        bookingId: bookingId,
        phase: HotelBookingPhase.polling,
        message: kHotelSuccessStatuses.contains(orderStatus)
            ? 'The hotel confirmed this booking.'
            : 'Your payment is successful. We are waiting for the final '
                  'confirmation from the hotel.',
        paymentCaptured: true,
        initialStatus: HotelBookingStatus.fromJson(
          readKey(booking, 'bookingDetails') ?? booking,
          fallbackBookingId: bookingId,
        ),
      );
    } on HoneymoonApiException catch (e) {
      // The session expired mid-booking: the exception has already signed
      // out, and AuthGate is taking the stack down. Park the form before it
      // goes — unless the payment went through, where the status must be
      // checked instead of the form replayed.
      if (e.statusCode == 401 && !paid) {
        await _parkDraft();
        return;
      }
      if (!mounted) return;
      await _handleFailure(e, paid: paid);
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

  /// Every failure branch of the web's `handleProceedToBook` catch block.
  Future<void> _handleFailure(
    HoneymoonApiException e, {
    required bool paid,
  }) async {
    final failure = HotelBookingFailure.fromBody(
      e.data,
      statusCode: e.statusCode ?? 0,
    );
    final bookingId = failure.bookingId.isNotEmpty
        ? failure.bookingId
        : _bookingId;

    // After payment, a timeout is "still confirming", not a failure.
    if (e.isTimeout && paid) {
      await _openStatus(
        bookingId: bookingId,
        phase: HotelBookingPhase.timeout,
        message:
            'Payment appears to be successful. The hotel is still confirming '
            'the booking. Please refresh the status after a short while.',
        paymentCaptured: true,
      );
      return;
    }

    // An earlier attempt was already paid for: never charge again, go and
    // fetch where that booking stands.
    if (failure.duplicateBookingBlocked) {
      await _openStatus(
        bookingId: bookingId,
        phase: HotelBookingPhase.alreadyPaid,
        message:
            'The payment for this booking was already captured. Do not pay '
            'again — we are fetching the latest status.',
        paymentCaptured: true,
        initialStatus: HotelBookingStatus(
          bookingId: bookingId,
          status: failure.tripjackStatus.toUpperCase(),
        ),
      );
      return;
    }

    final captured = paid || failure.paymentCaptured;
    final message = failure.isValidation
        ? (failure.message.isNotEmpty
              ? failure.message
              : 'Some guest details were not accepted. Please check them and '
                    'try again.')
        : failure.isSupplierDenial
        ? 'The booking was rejected: '
              '${failure.message.isNotEmpty ? failure.message : 'invalid guest details or supplier validation failed.'}'
        : failure.isSupplierOutage
        ? (failure.requiresManualAction || captured
              ? 'Our hotel partner is temporarily unavailable after your '
                    'payment was verified. Do not pay again — check the '
                    'booking status in a little while, or contact support with '
                    'booking ID $bookingId.'
              : (failure.message.isNotEmpty
                    ? failure.message
                    : 'Our hotel partner is temporarily unavailable. Please '
                          'try again shortly.'))
        : failure.isPayment
        ? _paymentFailureText(
            failure.message.isNotEmpty ? failure.message : e.message,
          )
        : captured
        ? 'We could not complete the booking. Your payment is safe — check '
              'the details and retry without paying again.'
        : e.message;

    setState(() {
      _paymentCaptured = captured;
      _submitError = message;
    });
    AppSnackbar.error(context, message);
  }

  /// Razorpay's test mode reports a missing wallet/UPI setup as an `org_id`
  /// error; the web rewrites it into something a traveller can act on.
  String _paymentFailureText(String message) {
    if (RegExp('org_id', caseSensitive: false).hasMatch(message)) {
      return 'Wallet or UPI payments are not available right now. Please use '
          'a card or netbanking.';
    }
    return message.isEmpty ? 'The payment could not be completed.' : message;
  }

  // -------------------------------------------------------------------------
  // Hold — the web's `handleCreateHoldBooking`
  // -------------------------------------------------------------------------

  Future<void> _hold() async {
    if (_submitting || _bookingId.isEmpty) return;
    FocusScope.of(context).unfocus();
    if (!await _ensureSession() || !mounted) return;
    if (!_validate()) {
      AppSnackbar.error(context, 'Please complete the highlighted details.');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
      _stage = 'Holding your room…';
    });

    try {
      final response = await widget.api.holdHotelBooking(
        _bookingPayload(includePayment: false),
      );
      if (!mounted) return;

      if (isHotelSupplierDenial(response)) {
        final reason = hotelDenialReason(response);
        setState(
          () => _submitError = reason.isNotEmpty
              ? reason
              : 'The room could not be held. Please try paying now instead.',
        );
        return;
      }

      final bookingId = firstNonEmpty([
        readKey(response, 'bookingId'),
      ], fallback: _bookingId);
      final held = HotelBookingStatus.fromJson(
        response,
        fallbackBookingId: bookingId,
      );
      await _openStatus(
        bookingId: bookingId,
        phase: HotelBookingPhase.success,
        message: asString(
          readKey(response, 'message'),
          fallback: 'Your room is held. Pay before the deadline to confirm it.',
        ),
        fromHold: true,
        initialStatus: HotelBookingStatus(
          bookingId: bookingId,
          status: held.status.isNotEmpty ? held.status : 'ON_HOLD',
          bookingType: held.bookingType.isNotEmpty ? held.bookingType : 'HOLD',
          paymentStatus: held.paymentStatus,
          deadline: held.deadline.isNotEmpty
              ? held.deadline
              : (_review?.deadline ?? ''),
          total: _payableAmount,
        ),
      );
    } on HoneymoonApiException catch (e) {
      if (e.statusCode == 401) {
        await _parkDraft();
        return;
      }
      if (!mounted) return;
      final message = firstNonEmpty([
        readKey(e.data, 'error'),
        readKey(e.data, 'message'),
      ], fallback: e.message);
      setState(() => _submitError = message);
      AppSnackbar.error(context, message);
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

  Future<void> _openStatus({
    required String bookingId,
    required HotelBookingPhase phase,
    String message = '',
    String errorCode = '',
    bool paymentCaptured = false,
    bool fromHold = false,
    HotelBookingStatus? initialStatus,
  }) async {
    // Once the booking has reached the supplier the draft is spent — a
    // second tab or a later restore must not resubmit the same details.
    await HotelDraftStore.clear();
    if (!mounted) return;
    final result = await Navigator.push<HotelBookingRetry>(
      context,
      AnimatedPageRoute(
        page: HotelBookingStatusPage(
          api: widget.api,
          bookingId: bookingId,
          hotelName: _review?.hotelName.isNotEmpty == true
              ? _review!.hotelName
              : widget.hotel.name,
          roomName: widget.room.name,
          query: widget.query,
          initialPhase: phase,
          initialMessage: message,
          initialStatus: initialStatus,
          errorCode: errorCode,
          amount: _payableAmount,
          paymentCaptured: paymentCaptured,
          fromHold: fromHold,
          holdPaymentPayload: fromHold ? _bookingPayload() : null,
          prefill: _prefill,
        ),
        style: PageTransitionStyle.slideRight,
      ),
    );
    if (!mounted || result == null) return;

    // "Fix details & retry": back on the form, and when the payment already
    // went through the next submit resends without charging.
    setState(() {
      _paymentCaptured = result.paymentCaptured;
      _submitError = result.paymentCaptured
          ? 'Your payment is safe. Correct the guest details and tap '
                '"Retry booking" — you will not be charged again.'
          : 'Correct the guest details and try again.';
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final review = _review;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppTopBar(
        elevated: true,
        titleWidget: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Review your booking',
              style: AppText.cardTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${formatTripDate(widget.query.checkIn)} – '
              '${formatTripDate(widget.query.checkOut)}',
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
        errorMessage: _reviewError is HoneymoonApiException
            ? (_reviewError as HoneymoonApiException).message
            : 'The rate we had has changed or sold out. Go back and pick '
                  'another room.',
        child: _form(),
      ),
      bottomNavigationBar: _loadingReview || _reviewError != null
          ? null
          : BookingActionBar(
              fare: _fare,
              priceLabel: 'Total payable',
              actionLabel: _paymentCaptured ? 'Retry booking' : 'Pay & book',
              isLoading: _submitting,
              onAction: _pay,
              amountFormatter: formatHotelFare,
              // The web offers "Hold & Confirm" only when the rate allows it.
              secondaryLabel:
                  (review?.onholdAllowed ?? false) && !_paymentCaptured
                  ? 'Hold & pay later'
                  : null,
              onSecondary: _hold,
              onShowBreakdown: () => showFareBreakdownSheet(
                context,
                _fare,
                title: 'Fare summary',
                footnote:
                    'City taxes and resort fees, where a property charges '
                    'them, are payable at check-in.',
                amountFormatter: formatHotelFare,
              ),
            ),
    );
  }

  Widget _form() {
    final review = _review;
    if (review == null) return const SizedBox.shrink();

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
            tone: _paymentCaptured ? InfoTone.warning : InfoTone.error,
            icon: Icons.error_outline_rounded,
            message: _submitError!,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        _StayCard(
          hotel: widget.hotel,
          statics: widget.staticContent,
          query: widget.query,
        ),
        const SizedBox(height: AppSpacing.md),

        if (priceMoved) ...[
          InfoBanner(
            tone: InfoTone.warning,
            icon: Icons.price_change_outlined,
            message:
                'The hotel re-quoted this room at ${formatHotelFare(_payableAmount)} '
                'when we confirmed availability.',
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        _roomBreakdown(review),
        const SizedBox(height: AppSpacing.md),
        _cancellationSection(review),
        const SizedBox(height: AppSpacing.md),
        _guestSection(),
        const SizedBox(height: AppSpacing.md),
        _contactSection(),
        if (_panRequired) ...[
          const SizedBox(height: AppSpacing.md),
          _panSection(),
        ],
        const SizedBox(height: AppSpacing.md),
        _importantInfo(review),
        const SizedBox(height: AppSpacing.md),
        _snapshot(review),

        const SizedBox(height: AppSpacing.lg),
        KeyedSubtree(
          key: _anchorFor('terms'),
          child: CheckboxListTile(
            value: _termsAccepted,
            onChanged: _submitting
                ? null
                : (v) => setState(() {
                    _termsAccepted = v ?? false;
                    _errors.remove('terms');
                  }),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            title: Text(
              'I confirm that I have reviewed and agree to proceed with the '
              'selected room category and hotel booking terms.',
              style: AppText.bodySm,
            ),
            subtitle: _errors['terms'] == null
                ? null
                : Text(_errors['terms']!, style: AppText.error),
          ),
        ),
        if (_stage != null) ...[
          const SizedBox(height: AppSpacing.md),
          InfoBanner(icon: Icons.autorenew_rounded, message: _stage!),
        ],
        const SizedBox(height: AppSpacing.md),
        const TermsNotice(product: 'hotel'),
      ],
    );
  }

  /// "Room 1: Suite (2 Adults) · Refundable | Breakfast" — one line per room.
  Widget _roomBreakdown(HotelReview review) {
    final terms = [
      review.option.refundable == false
          ? 'Non refundable'
          : review.option.refundable == true
          ? 'Refundable'
          : 'Hotel policy',
      review.option.mealPlan,
    ].where((s) => s.isNotEmpty).join(' | ');

    return FormSection(
      title: 'Your rooms',
      icon: Icons.king_bed_outlined,
      children: [
        for (var i = 0; i < _rooms.length; i++) ...[
          if (i > 0)
            const Divider(height: AppSpacing.xl, color: AppColors.divider),
          Text(
            'Room ${i + 1}: ${_roomTitle(review, i)}',
            style: AppText.bodyStrong,
          ),
          Text(
            '${_rooms[i].adults} adult${_rooms[i].adults == 1 ? '' : 's'}'
            '${_rooms[i].children > 0 ? ', ${_rooms[i].children} child${_rooms[i].children == 1 ? '' : 'ren'}' : ''}',
            style: AppText.caption,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(terms, style: AppText.bodySm),
        ],
      ],
    );
  }

  String _roomTitle(HotelReview review, int index) {
    final lines = review.option.rooms;
    final line = lines.length > index
        ? lines[index]
        : (lines.isNotEmpty ? lines.first : null);
    return line != null && line.name.isNotEmpty ? line.name : widget.room.name;
  }

  Widget _cancellationSection(HotelReview review) {
    final nights = widget.query.nights;
    final rooms = widget.query.rooms.length;
    // The service fee is the management fee, spread per room per night.
    final serviceFeePerNight =
        nights > 0 && rooms > 0 && review.managementFee > 0
        ? review.managementFee / (nights * rooms)
        : 0.0;

    return FormSection(
      title: 'Cancellation policy',
      icon: Icons.policy_outlined,
      children: [
        HotelPenaltyTable(
          penalties: review.option.penalties,
          currency: review.currency,
        ),
        if (review.option.penalties.isEmpty && review.deadline.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Hold deadline: ${formatPolicyDateTime(review.deadline)}',
            style: AppText.caption,
          ),
        ],
        if (serviceFeePerNight > 0) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '• A non-refundable service fee of '
            '${formatHotelFare(serviceFeePerNight, currency: review.currency)} '
            'per room per night applies to each booking.',
            style: AppText.caption,
          ),
        ],
        const SizedBox(height: AppSpacing.xxs),
        Text(
          '• Please note that redeemed taxes and fees are non-refundable.',
          style: AppText.caption,
        ),
      ],
    );
  }

  Widget _guestSection() {
    return FormSection(
      title: 'Guest details',
      subtitle: 'Only the lead guest name is required · names as on ID',
      icon: Icons.person_outline_rounded,
      children: [
        for (var r = 0; r < _rooms.length; r++) ...[
          if (r > 0)
            const Divider(height: AppSpacing.xxl, color: AppColors.divider),
          Text(
            'Room ${r + 1} · ${_rooms[r].adults} adult${_rooms[r].adults == 1 ? '' : 's'}'
            '${_rooms[r].children > 0 ? ' · ${_rooms[r].children} child${_rooms[r].children == 1 ? '' : 'ren'}' : ''}',
            style: AppText.bodyStrong,
          ),
          const SizedBox(height: AppSpacing.md),
          for (var g = 0; g < _rooms[r].guests.length; g++) ...[
            if (g > 0) const SizedBox(height: AppSpacing.lg),
            _guestFields(r, g),
          ],
        ],
      ],
    );
  }

  Widget _guestFields(int r, int g) {
    final room = _rooms[r];
    final guest = room.guests[g];
    final isLead = g == room.leadIndex;
    final ordinal = room.guests
        .take(g + 1)
        .where((x) => x.input.isChild == guest.input.isChild)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '${guest.input.isChild ? 'CHILD' : 'GUEST'} $ordinal'
          '${isLead ? ' · LEAD GUEST' : ''}',
          style: AppText.caption.copyWith(letterSpacing: 0.5),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              // Narrow enough that the name field beside it stays usable at
              // 320 px.
              width: 96,
              child: KeyedSubtree(
                key: _anchorFor('title_${r}_$g'),
                child: PickerField(
                  label: 'Title',
                  value: guest.input.title,
                  errorText: _errors['title_${r}_$g'],
                  enabled: !_submitting,
                  onTap: () async {
                    final picked = await showOptionSheet<String>(
                      context,
                      title: 'Title',
                      options: guest.input.titles,
                      labelOf: (v) => v,
                      selected: guest.input.title,
                    );
                    if (picked != null) {
                      setState(() {
                        guest.input.title = picked;
                        _errors.remove('title_${r}_$g');
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: KeyedSubtree(
                key: _anchorFor('first_${r}_$g'),
                child: AppTextField(
                  controller: guest.firstName,
                  label: isLead ? 'Lead guest first name' : 'First name',
                  required: isLead,
                  enabled: !_submitting,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _errors['first_${r}_$g'],
                  autofillHints: isLead
                      ? const [AutofillHints.givenName]
                      : null,
                  onChanged: (_) => _clear('first_${r}_$g'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        KeyedSubtree(
          key: _anchorFor('last_${r}_$g'),
          child: AppTextField(
            controller: guest.lastName,
            label: 'Last name',
            required: isLead,
            enabled: !_submitting,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            errorText: _errors['last_${r}_$g'],
            autofillHints: isLead ? const [AutofillHints.familyName] : null,
            onChanged: (_) {
              _clear('last_${r}_$g');
              // The PAN block shows the lead's name; keep it current.
              if (isLead && _panRequired) setState(() {});
            },
          ),
        ),
        if (_passportRequired && !guest.input.isChild) ...[
          const SizedBox(height: AppSpacing.md),
          KeyedSubtree(
            key: _anchorFor('passport_${r}_$g'),
            child: AppTextField(
              controller: guest.passport,
              label: 'Passport number',
              required: true,
              enabled: !_submitting,
              helperText: 'Required by this rate for every adult',
              maxLength: 20,
              textCapitalization: TextCapitalization.characters,
              errorText: _errors['passport_${r}_$g'],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: (_) => _clear('passport_${r}_$g'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _contactSection() {
    return FormSection(
      title: 'Contact details',
      subtitle: 'Where your voucher goes',
      icon: Icons.alternate_email_rounded,
      children: [
        KeyedSubtree(
          key: _anchorFor('mobile'),
          child: PhoneField(
            controller: _mobile,
            countryCode: _countryCode,
            errorText: _errors['mobile'],
            onChanged: (_) => _clear('mobile'),
            onCountryCodeChanged: (code) => setState(() => _countryCode = code),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        KeyedSubtree(
          key: _anchorFor('email'),
          child: AppTextField(
            controller: _email,
            label: 'Email address',
            required: true,
            enabled: !_submitting,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            errorText: _errors['email'],
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => _clear('email'),
          ),
        ),
      ],
    );
  }

  /// PAN sits in its own block, one entry per room rather than one per adult;
  /// the value is carried on that room's lead guest.
  Widget _panSection() {
    return FormSection(
      title: 'PAN information',
      subtitle: 'Required by this rate — applied to every adult in the room',
      icon: Icons.badge_outlined,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final corporate in [false, true])
              ChoiceChip(
                label: Text(corporate ? 'Corporate PAN' : 'Personal PAN'),
                selected: _corporatePan == corporate,
                selectedColor: AppColors.pinkSurface,
                onSelected: _submitting
                    ? null
                    : (_) => setState(() => _corporatePan = corporate),
              ),
          ],
        ),
        for (var r = 0; r < _rooms.length; r++) ...[
          const SizedBox(height: AppSpacing.md),
          Builder(
            builder: (context) {
              final lead = _rooms[r].guests[_rooms[r].leadIndex];
              final name = [
                lead.firstName.text.trim(),
                lead.lastName.text.trim(),
              ].where((s) => s.isNotEmpty).join(' ');
              return Text(
                '${_corporatePan ? 'Company' : 'Name'} (Room ${r + 1}): '
                '${name.isEmpty ? 'taken from the lead guest' : name}',
                style: AppText.caption,
              );
            },
          ),
          const SizedBox(height: AppSpacing.xs),
          KeyedSubtree(
            key: _anchorFor('pan_$r'),
            child: AppTextField(
              controller: _rooms[r].pan,
              label: 'PAN',
              hint: 'ABCDE1234F',
              required: true,
              enabled: !_submitting,
              maxLength: 10,
              textCapitalization: TextCapitalization.characters,
              errorText: _errors['pan_$r'],
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              ],
              onChanged: (_) => _clear('pan_$r'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _importantInfo(HotelReview review) {
    final refundable = review.option.refundable;
    final bullets = <String>[
      refundable == false
          ? 'This selected room is non-refundable.'
          : refundable == true
          ? 'Cancellation charges apply according to the policy above.'
          : 'Cancellation is subject to hotel policy.',
      _panRequired
          ? 'PAN is required for this booking.'
          : 'PAN is not required for this room option.',
      _passportRequired
          ? 'A passport number is required for adult guests.'
          : 'A passport number is not required for this room option.',
      ...review.importantNotes,
    ];
    // The booked rate's own policies, with the hotel's static ones as backup.
    final policies = review.policyNotes.isNotEmpty
        ? review.policyNotes
        : [
            ...widget.staticContent.knowBeforeYouGo,
            ...widget.staticContent.specialInstructions,
            ...widget.staticContent.mandatoryFees,
          ];

    return FormSection(
      title: 'Important information',
      subtitle: 'Booking notes and general terms',
      icon: Icons.info_outline_rounded,
      collapsible: true,
      initiallyExpanded: false,
      children: [
        for (final b in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Text('• $b', style: AppText.bodySm),
          ),
        if (policies.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text('Policies', style: AppText.bodyStrong),
          const SizedBox(height: AppSpacing.sm),
          HotelPolicyNotes(notes: policies),
        ],
      ],
    );
  }

  Widget _snapshot(HotelReview review) {
    return FormSection(
      title: 'Booking snapshot',
      icon: Icons.receipt_long_outlined,
      children: [
        DetailRow(label: 'Booking ID', value: review.bookingId),
        DetailRow(label: 'Room', value: _roomTitle(review, 0)),
        DetailRow(label: 'Meal basis', value: review.option.mealPlan),
        DetailRow(
          label: 'Refundability',
          value: review.option.refundable == false
              ? 'Non-refundable'
              : review.option.refundable == true
              ? 'Refundable'
              : 'Hotel policy',
        ),
      ],
    );
  }

  void _clear(String key) {
    if (!_errors.containsKey(key)) return;
    setState(() => _errors.remove(key));
  }
}

// ---------------------------------------------------------------------------

/// Hotel, dates, rooms/guests and the property's check-in/out times — the
/// top two panels of the web's review page.
class _StayCard extends StatelessWidget {
  const _StayCard({
    required this.hotel,
    required this.statics,
    required this.query,
  });

  final HotelResult hotel;
  final HotelStaticContent statics;
  final HotelSearchQuery query;

  @override
  Widget build(BuildContext context) {
    final nights = query.nights;
    final image = statics.images.isNotEmpty
        ? statics.images.first
        : hotel.imageUrl;
    final stars = statics.starRating > 0
        ? statics.starRating
        : hotel.starRating;
    final address = [
      statics.address.isNotEmpty ? statics.address : hotel.address,
      statics.city.isNotEmpty ? statics.city : hotel.city,
      if (statics.postalCode.isNotEmpty) statics.postalCode,
    ].where((s) => s.isNotEmpty).join(', ');

    String range(String from, String till) =>
        [from, till].where((s) => s.isNotEmpty).join(' – ');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NetworkImageWidget(
                url: image,
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
                    if (stars > 0)
                      Text(
                        '★' * stars.round().clamp(0, 5),
                        style: AppText.caption.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    if (address.isNotEmpty)
                      Text(
                        address,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Stat(
                  label: 'Check-in',
                  value: formatTripDate(query.checkIn),
                ),
              ),
              Expanded(
                child: _Stat(
                  label: 'Check-out',
                  value: formatTripDate(query.checkOut),
                ),
              ),
            ],
          ),
          if (statics.hasStayTimes) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'From ${range(statics.checkInFrom, statics.checkInTill)}',
                    style: AppText.caption,
                  ),
                ),
                Expanded(
                  child: Text(
                    statics.checkOutFrom.isEmpty
                        ? ''
                        : 'Until ${statics.checkOutFrom}',
                    style: AppText.caption,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (nights > 0)
                MetaChip(
                  icon: Icons.nights_stay_outlined,
                  label: '$nights night${nights == 1 ? '' : 's'}',
                ),
              MetaChip(
                icon: Icons.meeting_room_outlined,
                label:
                    '${query.rooms.length} room${query.rooms.length == 1 ? '' : 's'}',
              ),
              MetaChip(
                icon: Icons.people_outline_rounded,
                label: '${query.guests} guest${query.guests == 1 ? '' : 's'}',
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

// ---------------------------------------------------------------------------
// Superseded
// ---------------------------------------------------------------------------
//
// The previous funnel booked one adult in one room whatever was searched, did
// not check a verify answer for a supplier refusal, skipped the status poll
// (showing "confirmed" straight after payment) and had no recovery path when
// the payment went through but the booking failed. Replaced by the flow
// above, which follows the web's TripJackBookingReview / handleProceedToBook.
// The old members of _HotelBookingPageState are kept below.
//   /// The supplier accepts two payload shapes here — a newer correlation-based
//   /// one and a legacy search-based one — and which ids came back depends on
//   /// how the detail was fetched. Both are sent; the backend uses whichever is
//   /// complete.
//   Map<String, dynamic> get _reviewPayload {
//     final detail = widget.detail;
//     final option = widget.room.raw;
//
//     final correlationId = firstNonEmpty([
//       readKey(detail, 'correlationId'),
//       digPath(detail, ['data', 'correlationId']),
//     ]);
//     final detailRequestId = firstNonEmpty([
//       readKey(detail, 'detailRequestId'),
//       readKey(detail, 'reviewHash'),
//       digPath(detail, ['data', 'detailRequestId']),
//     ]);
//     final hotelId = firstNonEmpty([
//       readKey(detail, 'tjHotelId'),
//       digPath(detail, ['hotel', 'tjid']),
//       digPath(detail, ['data', 'tjHotelId']),
//       readKey(option, 'hid'),
//     ], fallback: widget.hotel.id);
//
//     return <String, dynamic>{
//       'correlationId': correlationId,
//       'reviewHash': detailRequestId,
//       'hid': hotelId,
//       'searchId': widget.searchId,
//       'detailRequestId': detailRequestId,
//       'optionId': widget.room.optionId,
//       'tjHotelId': hotelId,
//     };
//   }
//
//   Future<void> _openReview() async {
//     setState(() {
//       _loadingReview = true;
//       _reviewError = null;
//     });
//     try {
//       final review = await widget.api.reviewHotelBooking(_reviewPayload);
//       if (!mounted) return;
//       setState(() {
//         _review = review;
//         _loadingReview = false;
//       });
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _loadingReview = false;
//         _reviewError = e;
//       });
//     }
//   }
//
//   FareBreakdown get _fare {
//     final total = _payableAmount;
//     final perNight = widget.nights > 0 ? total / widget.nights : total;
//     return FareBreakdown(
//       lines: [
//         FareLine(
//           widget.room.name,
//           total,
//           detail: widget.nights > 0
//               ? '${widget.nights} night${widget.nights == 1 ? '' : 's'} · '
//                     '${formatPrice(perNight)} per night'
//               : '',
//         ),
//       ],
//       total: total,
//     );
//   }
//
//   // -------------------------------------------------------------------------
//   // Validation
//   // -------------------------------------------------------------------------
//
//   bool _validate() {
//     final errors = <String, String>{};
//
//     if (_firstName.text.trim().isEmpty) {
//       errors['firstName'] = 'First name is required';
//     }
//     if (_lastName.text.trim().isEmpty) {
//       errors['lastName'] = 'Last name is required';
//     }
//     if (!_email.text.trim().contains('@') || _email.text.trim().length < 5) {
//       errors['email'] = 'Enter a valid email address';
//     }
//     if (_mobile.text.trim().length < 10) {
//       errors['mobile'] = 'Enter a valid mobile number';
//     }
//     // A 10-character PAN in the AAAAA9999A pattern; the hotel rejects
//     // anything else outright rather than at check-in.
//     if (_panRequired &&
//         !RegExp(
//           r'^[A-Z]{5}[0-9]{4}[A-Z]$',
//         ).hasMatch(_pan.text.trim().toUpperCase())) {
//       errors['pan'] = 'Enter a valid 10-character PAN';
//     }
//     if (_passportRequired && _passport.text.trim().isEmpty) {
//       errors['passport'] = 'This property requires a passport number';
//     }
//
//     setState(() {
//       _errors
//         ..clear()
//         ..addAll(errors);
//     });
//
//     if (errors.isNotEmpty) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         final ctx = _anchors[errors.keys.first]?.currentContext;
//         if (ctx != null) {
//           Scrollable.ensureVisible(
//             ctx,
//             duration: AppMotion.normal,
//             curve: AppMotion.standard,
//             alignment: 0.2,
//           );
//         }
//       });
//       return false;
//     }
//
//     _guest
//       ..firstName = _firstName.text.trim()
//       ..lastName = _lastName.text.trim()
//       ..pan = _pan.text.trim()
//       ..passportNumber = _passport.text.trim();
//     return true;
//   }
//
//   // -------------------------------------------------------------------------
//   // Booking
//   // -------------------------------------------------------------------------
//
//   Map<String, dynamic> get _bookingPayload => <String, dynamic>{
//     'bookingId': _bookingId,
//     'roomTravellerInfo': [
//       {
//         'travellerInfo': [
//           _guest.toJson(
//             panRequired: _panRequired,
//             passportRequired: _passportRequired,
//           ),
//         ],
//       },
//     ],
//     'deliveryInfo': {
//       'emails': [_email.text.trim()],
//       'contacts': [_mobile.text.trim()],
//       'code': [_countryCode.replaceFirst('+', '')],
//     },
//     'paymentInfos': [
//       {'amount': _payableAmount},
//     ],
//     'expectedAmount': _payableAmount,
//     'type': 'HOTEL',
//     'ipr': _panRequired,
//     'ipm': _passportRequired,
//     'hotelId': firstNonEmpty([
//       digPath(_review, ['hotelInfo', 'tjid']),
//       digPath(_review, ['hotelSummary', 'tjid']),
//       digPath(_review, ['tjHotelId']),
//       digPath(_review, ['hotelId']),
//     ], fallback: widget.hotel.id),
//     'optionId': firstNonEmpty([
//       digPath(_review, ['selectedOption', 'optionId']),
//       digPath(_review, ['selectedOption', 'id']),
//       digPath(_review, ['option', 'optionId']),
//       digPath(_review, ['option', 'id']),
//     ], fallback: widget.room.optionId),
//     'reviewData': _review,
//   };
//
//   Future<void> _pay() async {
//     if (_submitting || _bookingId.isEmpty) return;
//     FocusScope.of(context).unfocus();
//     if (!_validate()) {
//       AppSnackbar.error(context, 'Please complete the highlighted details.');
//       return;
//     }
//
//     setState(() {
//       _submitting = true;
//       _submitError = null;
//     });
//
//     try {
//       final payload = _bookingPayload;
//
//       setState(() => _stage = 'Starting secure payment…');
//       final order = await widget.api.createHotelPaymentOrder(payload);
//       if (!mounted) return;
//
//       setState(() => _stage = null);
//       final outcome = await RazorpayCheckout.open(
//         context,
//         order: order,
//         title: 'HappyWedz Hotels',
//         description: widget.hotel.name,
//         prefill: (
//           name: '${_guest.firstName} ${_guest.lastName}'.trim(),
//           email: _email.text.trim(),
//           contact: _mobile.text.trim(),
//         ),
//       );
//       if (!mounted) return;
//
//       switch (outcome) {
//         case RazorpayDismissed():
//           setState(
//             () => _submitError =
//                 'The payment was cancelled before it completed. Your room is '
//                 'not held — prices can change if you wait.',
//           );
//         case RazorpayFailure(:final message):
//           setState(() => _submitError = message);
//         case RazorpaySuccess(:final result):
//           setState(() => _stage = 'Confirming with the hotel…');
//           final booking = await widget.api.verifyHotelPaymentAndBook({
//             'bookingId': _bookingId,
//             ...result.toVerifyJson(),
//           });
//           if (!mounted) return;
//           _goToConfirmation(booking);
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _submitError = bookingErrorText(e));
//     } finally {
//       if (mounted) {
//         setState(() {
//           _submitting = false;
//           _stage = null;
//         });
//       }
//     }
//   }
//
//   void _goToConfirmation(BookingOutcome outcome) {
//     // Captured before the replace: this State's context is gone by the time
//     // the confirmation screen's actions fire.
//     final navigator = Navigator.of(context);
//
//     navigator.pushReplacement(
//       MaterialPageRoute(
//         builder: (_) => BookingConfirmationPage(
//           outcome: outcome,
//           onViewBookings: () {
//             // Unwind the checkout first so "back" from My trips lands where
//             // the traveller started, not inside a spent booking form.
//             navigator.popUntil((route) => route.isFirst);
//             navigator.push(
//               MaterialPageRoute(
//                 builder: (_) => const MyTripsPage(
//                   initialProduct: TravelProduct.hotel,
//                 ),
//               ),
//             );
//           },
//           summaryTitle: widget.hotel.name,
//           summarySubtitle: widget.hotel.address.isNotEmpty
//               ? widget.hotel.address
//               : widget.hotel.city,
//           details: [
//             DetailRow(
//               label: 'Check-in',
//               value: formatTripDate(widget.checkIn),
//               icon: Icons.login_rounded,
//             ),
//             DetailRow(
//               label: 'Check-out',
//               value: formatTripDate(widget.checkOut),
//               icon: Icons.logout_rounded,
//             ),
//             DetailRow(
//               label: 'Room',
//               value: widget.room.name,
//               icon: Icons.king_bed_outlined,
//             ),
//             DetailRow(
//               label: 'Guest',
//               value: '${_guest.firstName} ${_guest.lastName}'.trim(),
//               icon: Icons.person_outline_rounded,
//             ),
//           ],
//           nextSteps: const [
//             (
//               title: 'Voucher on its way',
//               body:
//                   'Your hotel voucher is emailed once the property confirms, '
//                   'usually within a few minutes.',
//             ),
//             (
//               title: 'At check-in',
//               body:
//                   'Show the voucher and a photo ID for every guest. Some '
//                   'properties ask for the card used to pay.',
//             ),
//             (
//               title: 'Need to change it?',
//               body:
//                   'Cancellation terms depend on the rate you booked — they '
//                   'are on your voucher.',
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//
// Old stay card (took separate dates instead of the search query):
// class _StayCard extends StatelessWidget {
//   const _StayCard({
//     required this.hotel,
//     required this.room,
//     required this.checkIn,
//     required this.checkOut,
//     required this.nights,
//   });
//
//   final HotelResult hotel;
//   final HotelRoomOption room;
//   final DateTime checkIn;
//   final DateTime checkOut;
//   final int nights;
//
//   @override
//   Widget build(BuildContext context) {
//     return AppCard(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               NetworkImageWidget(
//                 url: hotel.imageUrl,
//                 width: 72,
//                 height: 72,
//                 radius: AppRadii.md,
//                 memCacheWidth: 220,
//               ),
//               const SizedBox(width: AppSpacing.md),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       hotel.name,
//                       style: AppText.cardTitle,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                     const SizedBox(height: 2),
//                     Text(
//                       hotel.address.isNotEmpty ? hotel.address : hotel.city,
//                       style: AppText.caption,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           const Divider(height: 1, color: AppColors.divider),
//           const SizedBox(height: AppSpacing.md),
//           // Two dates side by side is the one place a Row is safe here: both
//           // values are short and each half is constrained.
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Expanded(
//                 child: _Stat(
//                   label: 'Check-in',
//                   value: formatTripDate(checkIn),
//                 ),
//               ),
//               Expanded(
//                 child: _Stat(
//                   label: 'Check-out',
//                   value: formatTripDate(checkOut),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: AppSpacing.md),
//           Wrap(
//             spacing: AppSpacing.xs,
//             runSpacing: AppSpacing.xs,
//             children: [
//               MetaChip(icon: Icons.king_bed_outlined, label: room.name),
//               if (nights > 0)
//                 MetaChip(
//                   icon: Icons.nights_stay_outlined,
//                   label: '$nights night${nights == 1 ? '' : 's'}',
//                 ),
//               if (room.mealPlan.isNotEmpty)
//                 MetaChip(icon: Icons.restaurant_rounded, label: room.mealPlan),
//               if (room.refundable != null)
//                 MetaChip(
//                   icon: room.refundable!
//                       ? Icons.check_circle_outline_rounded
//                       : Icons.block_rounded,
//                   label: room.refundable! ? 'Refundable' : 'Non-refundable',
//                 ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }
//
