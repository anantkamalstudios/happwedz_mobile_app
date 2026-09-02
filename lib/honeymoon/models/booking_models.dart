/// Models for the Honeymoon *booking* funnels — everything after a search
/// result is chosen.
///
/// Search models live in `honeymoon_models.dart`; these are the shapes the
/// four supplier booking flows need on top of them:
///
/// ```
/// flights    review → travellers → review → pay → confirm
/// hotels     guests → review → pay → confirm
/// cabs       passenger → book → pay → confirm
/// insurance  travellers → review → book → confirm
/// ```
///
/// Field names follow the supplier's own abbreviations (`fN`, `pt`, `iti`)
/// only at the JSON boundary — the Dart side always uses real words, so a
/// screen never has to know that a first name is called `fN` upstream.
library;

import 'honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Shared value types
// ---------------------------------------------------------------------------

/// Which supplier product a booking belongs to. Drives the icon, the colour
/// and which detail screen "My trips" opens.
enum TravelProduct { flight, hotel, cab, insurance }

extension TravelProductLabel on TravelProduct {
  String get label => switch (this) {
    TravelProduct.flight => 'Flight',
    TravelProduct.hotel => 'Hotel',
    TravelProduct.cab => 'Transfer',
    TravelProduct.insurance => 'Insurance',
  };

  String get pluralLabel => switch (this) {
    TravelProduct.flight => 'Flights',
    TravelProduct.hotel => 'Hotels',
    TravelProduct.cab => 'Transfers',
    TravelProduct.insurance => 'Insurance',
  };
}

/// Passenger category. The age bands are assessed on the *travel* date, not
/// today — see [dobBoundsFor].
enum PaxType { adult, child, infant }

extension PaxTypeCode on PaxType {
  /// What the supplier calls it.
  String get code => switch (this) {
    PaxType.adult => 'ADULT',
    PaxType.child => 'CHILD',
    PaxType.infant => 'INFANT',
  };

  /// Single letter shown after a name on the review screen.
  String get initial => switch (this) {
    PaxType.adult => 'A',
    PaxType.child => 'C',
    PaxType.infant => 'I',
  };

  /// Titles the supplier accepts for this category.
  List<String> get titles => this == PaxType.adult
      ? const ['Mr', 'Mrs', 'Ms']
      : const ['Master', 'Miss'];
}

/// Earliest/latest date of birth valid for [type] on [travelDate].
///
/// ```
/// ADULT   12+ on the travel date     → dob <= travel - 12y
/// CHILD   2 to under 12 on that date → travel - 12y < dob <= travel - 2y
/// INFANT  under 2 on that date       → travel - 2y < dob <= today
/// ```
///
/// Anchoring on today instead would pass a child who turns twelve before the
/// flight and have them refused at check-in.
({DateTime? min, DateTime? max}) dobBoundsFor(
  PaxType type,
  DateTime? travelDate,
) {
  final anchor = travelDate ?? DateTime.now();
  final today = DateTime.now();
  final twelve = DateTime(anchor.year - 12, anchor.month, anchor.day);
  final two = DateTime(anchor.year - 2, anchor.month, anchor.day);

  return switch (type) {
    PaxType.adult => (min: null, max: twelve),
    PaxType.child => (min: twelve.add(const Duration(days: 1)), max: two),
    PaxType.infant => (
      min: two.add(const Duration(days: 1)),
      max: DateTime(today.year, today.month, today.day),
    ),
  };
}

/// `yyyy-MM-dd`, the only date format any of these endpoints accepts.
String apiDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

// ---------------------------------------------------------------------------
// Contact / traveller input
// ---------------------------------------------------------------------------

/// Dialling codes for the markets these routes actually serve, mirroring the
/// web client's list so a number entered on either surface books the same way.
const List<({String code, String name})> kCountryDialCodes = [
  (code: '+91', name: 'India'),
  (code: '+971', name: 'UAE'),
  (code: '+966', name: 'Saudi Arabia'),
  (code: '+974', name: 'Qatar'),
  (code: '+968', name: 'Oman'),
  (code: '+973', name: 'Bahrain'),
  (code: '+965', name: 'Kuwait'),
  (code: '+65', name: 'Singapore'),
  (code: '+66', name: 'Thailand'),
  (code: '+60', name: 'Malaysia'),
  (code: '+94', name: 'Sri Lanka'),
  (code: '+977', name: 'Nepal'),
  (code: '+880', name: 'Bangladesh'),
  (code: '+44', name: 'United Kingdom'),
  (code: '+1', name: 'USA / Canada'),
  (code: '+61', name: 'Australia'),
  (code: '+64', name: 'New Zealand'),
  (code: '+49', name: 'Germany'),
  (code: '+33', name: 'France'),
  (code: '+81', name: 'Japan'),
];

/// Who to send the ticket/voucher to.
class ContactDetails {
  ContactDetails({this.countryCode = '+91', this.mobile = '', this.email = ''});

  String countryCode;
  String mobile;
  String email;

  /// Dialling code and number with no plus — the shape `deliveryInfo.contacts`
  /// expects.
  String get dialled =>
      '${countryCode.replaceFirst('+', '')}${mobile.trim()}';

  bool get isValid =>
      mobile.trim().length >= 10 &&
      email.trim().isNotEmpty &&
      email.contains('@');
}

/// Optional business-invoice details.
class GstDetails {
  GstDetails({
    this.companyName = '',
    this.gstNumber = '',
    this.companyEmail = '',
  });

  String companyName;
  String gstNumber;
  String companyEmail;

  Map<String, dynamic> toJson(String contactNumber) => <String, dynamic>{
    'gstNumber': gstNumber.trim().toUpperCase(),
    'email': companyEmail.trim(),
    'registeredName': companyName.trim(),
    'mobile': contactNumber,
    'address': '',
  };
}

/// Only collected when the fare demands it (`conditions.iecr`).
class EmergencyContact {
  EmergencyContact({this.name = '', this.email = '', this.mobile = ''});

  String name;
  String email;
  String mobile;
}

/// One person on a flight booking. Mutable because it backs a form.
class TravellerInput {
  TravellerInput({required this.type, String? title})
    : title = title ?? (type == PaxType.adult ? 'Mr' : 'Master');

  final PaxType type;
  String title;
  String firstName = '';
  String lastName = '';
  DateTime? dob;
  String nationality = 'IN';
  String passportNumber = '';
  DateTime? passportExpiry;
  DateTime? passportIssueDate;
  String documentId = '';

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();

  /// The supplier's `travellerInfo` entry. Optional blocks are omitted rather
  /// than sent empty — an empty `pNum` is rejected where a missing one is fine.
  Map<String, dynamic> toJson({
    required bool passportRequired,
    required bool docIdApplicable,
  }) {
    return <String, dynamic>{
      'ti': title,
      'fN': firstName.trim(),
      'lN': lastName.trim(),
      'pt': type.code,
      if (dob != null) 'dob': apiDate(dob!),
      if (passportRequired) ...<String, dynamic>{
        'pNat': nationality,
        'pNum': passportNumber.trim().toUpperCase(),
        if (passportExpiry != null) 'eD': apiDate(passportExpiry!),
        if (passportIssueDate != null) 'pid': apiDate(passportIssueDate!),
      },
      if (docIdApplicable && documentId.trim().isNotEmpty)
        'di': documentId.trim(),
    };
  }
}

/// One person on a cab booking. The supplier takes a single lead passenger.
class CabPassengerInput {
  CabPassengerInput();

  String firstName = '';
  String lastName = '';
  String email = '';
  String phone = '';
  String flightNumber = '';
  String serviceRequest = '';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstName': firstName.trim(),
    'lastName': lastName.trim(),
    'email': email.trim(),
    'phone': phone.trim(),
    if (flightNumber.trim().isNotEmpty)
      'flightDetails': {'number': flightNumber.trim()},
  };
}

/// One insured traveller. The insurer keys everything off age, which comes
/// from the search rather than the form, so it is fixed here.
class InsuranceTravellerInput {
  InsuranceTravellerInput({required this.id, required this.age});

  final int id;
  final int age;

  String fullName = '';
  String gender = 'M';
  String passport = '';
  String mobile = '';
  String email = '';
  String pincode = '';
  String nomineeName = 'LEGAL HEIR';
  String nomineeRelation = 'LEGAL HEIR';

  /// The insurer needs the name split, and treats a single-word name as both
  /// given and family name rather than rejecting it.
  ({String first, String last}) get splitName {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (first: '', last: '');
    if (parts.length == 1) return (first: parts.first, last: parts.first);
    return (first: parts.first, last: parts.sublist(1).join(' '));
  }

  Map<String, dynamic> toJson() {
    final name = splitName;
    return <String, dynamic>{
      'id': id,
      'age': age,
      'fn': name.first,
      'ln': name.last,
      'eid': email.trim(),
      'pnum': passport.trim().toUpperCase(),
      'cnum': mobile.trim(),
      'pincode': pincode.trim(),
      'gen': gender,
      'ni': [
        {'nn': nomineeName.trim(), 'nr': nomineeRelation},
      ],
    };
  }
}

const List<String> kNomineeRelations = [
  'LEGAL HEIR',
  'SPOUSE',
  'FATHER',
  'MOTHER',
  'SON',
  'DAUGHTER',
  'BROTHER',
  'SISTER',
];

/// One guest on a hotel room.
class HotelGuestInput {
  HotelGuestInput({this.isLead = false});

  final bool isLead;

  String title = 'Mr';
  String firstName = '';
  String lastName = '';
  String pan = '';
  String passportNumber = '';

  Map<String, dynamic> toJson({
    bool panRequired = false,
    bool passportRequired = false,
  }) => <String, dynamic>{
    'ti': title,
    'fN': firstName.trim(),
    'lN': lastName.trim(),
    'pt': 'ADULT',
    if (isLead) 'isLeadPax': true,
    if (panRequired && pan.trim().isNotEmpty) 'pan': pan.trim().toUpperCase(),
    if (passportRequired && passportNumber.trim().isNotEmpty)
      'pNum': passportNumber.trim().toUpperCase(),
  };
}

// ---------------------------------------------------------------------------
// Flight review (POST /tj/fms/review)
// ---------------------------------------------------------------------------

/// What the airline requires of this particular fare.
///
/// Every rule below is read from the review response rather than hardcoded:
/// the same route can require a passport on one fare and not on another, and
/// carriers cap name lengths differently.
class FareConditions {
  const FareConditions({
    this.passportRequired = false,
    this.passportIssueDateRequired = false,
    this.docIdApplicable = false,
    this.docIdMandatory = false,
    this.emergencyContactRequired = false,
    this.blockAllowed = false,
    this.firstNameMax = 50,
    this.lastNameMax = 50,
    this.firstNameMin = 1,
    this.lastNameMin = 1,
    this.combinedNameMax = 0,
    this.adultDobRequired = true,
    this.childDobRequired = true,
    this.infantDobRequired = true,
    this.sessionSeconds = 0,
    this.sessionStartedAt,
  });

  /// International itineraries need passport details; domestic ones do not.
  final bool passportRequired;
  final bool passportIssueDateRequired;

  /// Student / senior-citizen fares ask for a supporting document id.
  final bool docIdApplicable;
  final bool docIdMandatory;

  final bool emergencyContactRequired;

  /// Whether this fare may be held without payment (`conditions.isBA`).
  final bool blockAllowed;

  final int firstNameMax;
  final int lastNameMax;
  final int firstNameMin;
  final int lastNameMin;

  /// Some carriers cap the full name too, not just each field. 0 means no cap.
  final int combinedNameMax;

  final bool adultDobRequired;
  final bool childDobRequired;
  final bool infantDobRequired;

  /// How long the quoted fare is held for, and when the clock started.
  final int sessionSeconds;
  final DateTime? sessionStartedAt;

  bool dobRequiredFor(PaxType type) => switch (type) {
    PaxType.adult => adultDobRequired,
    PaxType.child => childDobRequired,
    PaxType.infant => infantDobRequired,
  };

  /// When the held fare lapses, or null when the fare carries no clock.
  DateTime? get expiresAt {
    if (sessionSeconds <= 0) return null;
    final started = sessionStartedAt ?? DateTime.now();
    return started.add(Duration(seconds: sessionSeconds));
  }

  factory FareConditions.fromJson(dynamic json) {
    final pcs = readKey(json, 'pcs');
    final anlm = readKey(json, 'anlm');
    final dc = readKey(json, 'dc');
    final dob = readKey(json, 'dob');

    // `pcs` is only present on international fares, and `pm: false` opts an
    // international fare *out* of requiring a passport.
    final passportRequired = pcs != null && readKey(pcs, 'pm') != false;

    return FareConditions(
      passportRequired: passportRequired,
      passportIssueDateRequired: readKey(pcs, 'pid') == true,
      docIdApplicable: readKey(dc, 'ida') == true,
      docIdMandatory: readKey(dc, 'idm') == true,
      emergencyContactRequired: readKey(json, 'iecr') == true,
      blockAllowed: readKey(json, 'isBA') == true,
      firstNameMax: asInt(readKey(anlm, 'fN'), fallback: 50),
      lastNameMax: asInt(readKey(anlm, 'lN'), fallback: 50),
      firstNameMin: asInt(readKey(anlm, 'finml'), fallback: 1),
      lastNameMin: asInt(readKey(anlm, 'lnml'), fallback: 1),
      combinedNameMax: asInt(readKey(anlm, 'n')),
      adultDobRequired: readKey(dob, 'adobr') != false,
      childDobRequired: readKey(dob, 'cdobr') != false,
      infantDobRequired: readKey(dob, 'idobr') != false,
      sessionSeconds: asInt(readKey(json, 'st')),
      sessionStartedAt: DateTime.tryParse(asString(readKey(json, 'sct'))),
    );
  }
}

/// A re-priced itinerary with a live booking session.
///
/// The review response — not the search result — is authoritative for price:
/// reading `totalPriceList[0]` off the search showed whichever fare was
/// cheapest on the card no matter which one the traveller actually picked.
class FlightReview {
  const FlightReview({
    required this.bookingId,
    this.conditions = const FareConditions(),
    this.trips = const [],
    this.totalFare = 0,
    this.raw = const <String, dynamic>{},
  });

  final String bookingId;
  final FareConditions conditions;

  /// Re-priced `tripInfos`, onward first.
  final List<Map<String, dynamic>> trips;

  /// The supplier's own grand total for this session, across every passenger.
  ///
  /// Deriving it instead by walking `tripInfos[].fd.ADULT` charged for a
  /// single adult while the supplier was still owed the whole party's fare.
  final double totalFare;

  final Map<String, dynamic> raw;

  bool get isUsable => bookingId.isNotEmpty;

  /// The fare amount `paymentInfos` must carry. The supplier validates this
  /// against its own session quote and rejects any difference, which is why
  /// our service charge never goes in here.
  double get supplierPayableAmount {
    final nf = asDouble(
      digPath(raw, ['totalPriceInfo', 'totalFareDetail', 'fC', 'NF']),
    );
    return nf > 0 ? nf : totalFare;
  }

  factory FlightReview.fromJson(dynamic json) {
    // Most endpoints answer at the root or behind `data`; the supplier's own
    // envelope (`payload`) shows up on some proxied routes.
    final root =
        readKey(json, 'data') ?? readKey(json, 'payload') ?? json;
    final totalDetail = digPath(root, [
      'totalPriceInfo',
      'totalFareDetail',
      'fC',
    ]);

    final tf = asDouble(readKey(totalDetail, 'TF'));
    final nf = asDouble(readKey(totalDetail, 'NF'));

    return FlightReview(
      bookingId: firstNonEmpty([
        readKey(root, 'bookingId'),
        readKey(root, 'bookingID'),
      ]),
      conditions: FareConditions.fromJson(readKey(root, 'conditions')),
      trips: asList(readKey(root, 'tripInfos')).map(asJsonMap).toList(),
      totalFare: tf > 0 ? tf : nf,
      raw: asJsonMap(root),
    );
  }
}

// ---------------------------------------------------------------------------
// Fare presentation
// ---------------------------------------------------------------------------

/// One row of the fare summary.
class FareLine {
  const FareLine(this.label, this.amount, {this.detail = ''});

  final String label;
  final double amount;

  /// Optional qualifier shown under the label, e.g. "2 adults".
  final String detail;
}

/// The fare summary shown on every step of a booking.
class FareBreakdown {
  const FareBreakdown({this.lines = const [], this.total = 0});

  final List<FareLine> lines;
  final double total;

  bool get isEmpty => total <= 0 && lines.isEmpty;

  /// Sums a fare component across every passenger type.
  ///
  /// `fd` is keyed by passenger type and each amount is *per passenger*, so
  /// reading `fd.ADULT` alone prices the booking for one adult regardless of
  /// who is actually travelling.
  static double sumAcrossPax(
    dynamic fare,
    String key,
    Map<PaxType, int> counts,
  ) {
    double total = 0;
    for (final entry in counts.entries) {
      if (entry.value <= 0) continue;
      final amount = asDouble(digPath(fare, ['fd', entry.key.code, 'fC', key]));
      total += amount * entry.value;
    }
    return total;
  }

  /// Base fare / taxes / total for one or two legs.
  ///
  /// [supplierTotal] is the grand total the review response quoted. When it is
  /// present it wins: the per-leg walk below is only a fallback for responses
  /// that omit `totalPriceInfo`, and any gap between the two is shown as its
  /// own line rather than silently changing the number the traveller saw.
  factory FareBreakdown.forFlight({
    required List<dynamic> fares,
    required Map<PaxType, int> paxCounts,
    double supplierTotal = 0,
    double serviceCharge = 0,
  }) {
    double base = 0;
    double taxes = 0;
    for (final f in fares) {
      if (f == null) continue;
      final legBase = sumAcrossPax(f, 'BF', paxCounts);
      final legTotal = sumAcrossPax(f, 'TF', paxCounts);
      final legFees = sumAcrossPax(f, 'TAF', paxCounts);
      base += legBase;
      taxes += legFees > 0 ? legFees : (legTotal - legBase);
    }

    final derived = base + taxes;
    final flightTotal = supplierTotal > 0 ? supplierTotal : derived;
    final adjustment = supplierTotal > 0 && derived > 0
        ? supplierTotal - derived
        : 0.0;

    return FareBreakdown(
      lines: [
        if (base > 0) FareLine('Base fare', base, detail: paxLabel(paxCounts)),
        if (taxes > 0) FareLine('Taxes & fees', taxes),
        if (adjustment.abs() >= 1) FareLine('Fare adjustment', adjustment),
        if (serviceCharge > 0) FareLine('Service charge', serviceCharge),
      ],
      total: flightTotal + serviceCharge,
    );
  }

  /// "2 adults, 1 child" — used as the qualifier under the base fare.
  static String paxLabel(Map<PaxType, int> counts) {
    final parts = <String>[];
    for (final e in counts.entries) {
      if (e.value <= 0) continue;
      final noun = switch (e.key) {
        PaxType.adult => e.value == 1 ? 'adult' : 'adults',
        PaxType.child => e.value == 1 ? 'child' : 'children',
        PaxType.infant => e.value == 1 ? 'infant' : 'infants',
      };
      parts.add('${e.value} $noun');
    }
    return parts.join(', ');
  }
}

// ---------------------------------------------------------------------------
// Payment
// ---------------------------------------------------------------------------

/// A gateway order, normalised.
///
/// The three payment endpoints spell these fields differently
/// (`razorpay_order_id` / `razorpayOrderId`, `key_id` / `keyId`), so each is
/// read from every spelling once, here, instead of at four call sites.
class PaymentOrder {
  const PaymentOrder({
    required this.orderId,
    required this.keyId,
    this.amountInPaise = 0,
    this.currency = 'INR',
    this.description = '',
    this.raw = const <String, dynamic>{},
  });

  final String orderId;
  final String keyId;
  final int amountInPaise;
  final String currency;
  final String description;
  final Map<String, dynamic> raw;

  bool get isUsable => orderId.isNotEmpty && keyId.isNotEmpty;

  factory PaymentOrder.fromJson(dynamic json) {
    final root = readKey(json, 'data') ?? json;
    return PaymentOrder(
      orderId: firstNonEmpty([
        readKey(root, 'razorpay_order_id'),
        readKey(root, 'razorpayOrderId'),
        readKey(root, 'order_id'),
        digPath(root, ['order', 'id']),
        readKey(root, 'id'),
      ]),
      keyId: firstNonEmpty([
        readKey(root, 'key_id'),
        readKey(root, 'keyId'),
        readKey(root, 'key'),
        readKey(root, 'razorpay_key'),
      ]),
      amountInPaise: asInt(
        readKey(root, 'amount') ?? digPath(root, ['order', 'amount']),
      ),
      currency: firstNonEmpty([
        readKey(root, 'currency'),
        digPath(root, ['order', 'currency']),
      ], fallback: 'INR'),
      description: asString(readKey(root, 'hotelName')),
      raw: asJsonMap(root),
    );
  }
}

/// What the gateway sends back when a payment succeeds.
class PaymentResult {
  const PaymentResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;

  Map<String, dynamic> toVerifyJson() => <String, dynamic>{
    'razorpay_order_id': orderId,
    'razorpay_payment_id': paymentId,
    'razorpay_signature': signature,
  };

  factory PaymentResult.fromJson(dynamic json) => PaymentResult(
    orderId: asString(readKey(json, 'razorpay_order_id')),
    paymentId: asString(readKey(json, 'razorpay_payment_id')),
    signature: asString(readKey(json, 'razorpay_signature')),
  );
}

// ---------------------------------------------------------------------------
// Booking outcome
// ---------------------------------------------------------------------------

/// The end state of a booking attempt, whichever product it was.
class BookingOutcome {
  const BookingOutcome({
    required this.product,
    required this.reference,
    this.status = '',
    this.amountPaid = 0,
    this.onHold = false,
    this.message = '',
    this.raw = const <String, dynamic>{},
  });

  final TravelProduct product;

  /// What the traveller quotes to support — an order id or booking id.
  final String reference;
  final String status;
  final double amountPaid;

  /// A fare blocked without payment: held by the supplier, unticketed.
  final bool onHold;
  final String message;
  final Map<String, dynamic> raw;

  bool get isConfirmed => reference.isNotEmpty;

  /// True while the supplier is still deciding — the traveller has paid but
  /// the PNR/voucher has not landed. Worth saying out loud rather than
  /// showing a bare "pending".
  bool get isAwaitingSupplier {
    final s = status.toUpperCase();
    return s.contains('PENDING') ||
        s.contains('PROCESS') ||
        s == 'PAYMENT_SUCCESS';
  }
}

// ---------------------------------------------------------------------------
// My trips
// ---------------------------------------------------------------------------

/// One row in "My trips", flattened from four very different payloads into the
/// handful of fields a mobile card can actually show.
class TravelBooking {
  const TravelBooking({
    required this.product,
    required this.reference,
    this.title = '',
    this.subtitle = '',
    this.travelDate,
    this.bookedOn,
    this.status = '',
    this.paymentStatus = '',
    this.amount = 0,
    this.travellerSummary = '',
    this.raw = const <String, dynamic>{},
  });

  final TravelProduct product;
  final String reference;
  final String title;
  final String subtitle;
  final DateTime? travelDate;
  final DateTime? bookedOn;
  final String status;
  final String paymentStatus;
  final double amount;
  final String travellerSummary;
  final Map<String, dynamic> raw;

  /// Upcoming trips sort to the top of the list and get the accent treatment.
  bool get isUpcoming =>
      travelDate != null && travelDate!.isAfter(DateTime.now());

  bool get isCancelled {
    final s = '$status $paymentStatus'.toUpperCase();
    return s.contains('CANCEL') || s.contains('REFUND');
  }

  bool get isConfirmed {
    if (isCancelled) return false;
    final s = status.toUpperCase();
    return s.contains('CONFIRM') ||
        s.contains('SUCCESS') ||
        s.contains('TICKET');
  }

  // --- Per-product adapters -------------------------------------------------

  /// `GET /tj/my-bookings`
  factory TravelBooking.fromFlightRow(dynamic json) {
    final from = firstNonEmpty([readKey(json, 'from'), readKey(json, 'origin')]);
    final to = firstNonEmpty([
      readKey(json, 'to'),
      readKey(json, 'destination'),
    ]);
    final count = asInt(readKey(json, 'passenger_count'));

    return TravelBooking(
      product: TravelProduct.flight,
      reference: firstNonEmpty([
        readKey(json, 'order_id'),
        readKey(json, 'booking_id'),
        readKey(json, 'bookingId'),
      ]),
      title: from.isNotEmpty && to.isNotEmpty
          ? '$from → $to'
          : firstNonEmpty([
              readKey(json, 'airline'),
            ], fallback: 'Flight booking'),
      subtitle: firstNonEmpty([
        readKey(json, 'airline'),
        readKey(json, 'flight_no'),
      ]),
      travelDate: DateTime.tryParse(
        firstNonEmpty([
          readKey(json, 'departure'),
          readKey(json, 'travel_date'),
        ]),
      ),
      bookedOn: DateTime.tryParse(
        firstNonEmpty([
          readKey(json, 'created_at'),
          readKey(json, 'booking_date'),
        ]),
      ),
      status: firstNonEmpty([
        readKey(json, 'booking_status'),
        readKey(json, 'status'),
      ]),
      paymentStatus: asString(readKey(json, 'payment_status')),
      amount: asDouble(readKey(json, 'amount_paid') ?? readKey(json, 'amount')),
      travellerSummary: [
        asString(readKey(json, 'passenger_name')),
        if (count > 1) '+${count - 1} more',
      ].where((s) => s.isNotEmpty).join(' '),
      raw: asJsonMap(json),
    );
  }

  /// `GET hotels/all-bookings`
  factory TravelBooking.fromHotelRow(dynamic json) {
    final checkIn = DateTime.tryParse(
      firstNonEmpty([
        readKey(json, 'checkin_date'),
        readKey(json, 'checkinDate'),
      ]),
    );
    final checkOut = DateTime.tryParse(
      firstNonEmpty([
        readKey(json, 'checkout_date'),
        readKey(json, 'checkoutDate'),
      ]),
    );
    final nights = checkIn != null && checkOut != null
        ? checkOut.difference(checkIn).inDays
        : 0;

    return TravelBooking(
      product: TravelProduct.hotel,
      reference: firstNonEmpty([
        readKey(json, 'booking_id'),
        readKey(json, 'bookingId'),
        readKey(json, 'id'),
      ]),
      title: firstNonEmpty([
        readKey(json, 'hotel_name'),
        readKey(json, 'hotelName'),
      ], fallback: 'Hotel booking'),
      subtitle: firstNonEmpty([
        readKey(json, 'city'),
        readKey(json, 'hotel_city'),
        readKey(json, 'address'),
      ]),
      travelDate: checkIn,
      bookedOn: DateTime.tryParse(
        firstNonEmpty([
          readKey(json, 'created_at'),
          readKey(json, 'createdOn'),
        ]),
      ),
      status: firstNonEmpty([
        readKey(json, 'booking_status'),
        readKey(json, 'status'),
      ]),
      paymentStatus: firstNonEmpty([
        readKey(json, 'payment_status'),
        readKey(json, 'paymentStatus'),
      ]),
      amount: asDouble(readKey(json, 'amount') ?? readKey(json, 'total_amount')),
      travellerSummary: nights > 0
          ? '$nights night${nights == 1 ? '' : 's'}'
          : '',
      raw: asJsonMap(json),
    );
  }

  /// One entry of `GET tripjack-cabs/booking/details`.
  factory TravelBooking.fromCabEntry(dynamic entry) {
    final order = readKey(entry, 'order');
    final cab = digPath(entry, ['itemInfos', 'CAB']);
    final journey = readKey(cab, 'journeyInfo');
    final pax = readKey(cab, 'paxDetails');

    final source = firstNonEmpty([
      digPath(journey, ['source', 'displayAddress']),
      readKey(journey, 'source'),
    ]);
    final destination = firstNonEmpty([
      digPath(journey, ['destination', 'displayAddress']),
      readKey(journey, 'destination'),
    ]);

    return TravelBooking(
      product: TravelProduct.cab,
      reference: asString(readKey(order, 'bookingId')),
      title: source.isNotEmpty && destination.isNotEmpty
          ? '$source → $destination'
          : 'Transfer',
      subtitle: firstNonEmpty([
        digPath(cab, ['vehicleDetail', 'model']),
        digPath(cab, ['vehicleDetail', 'vehicleCategory']),
      ]),
      travelDate: DateTime.tryParse(asString(readKey(journey, 'pickupDate'))),
      bookedOn: DateTime.tryParse(asString(readKey(order, 'createdOn'))),
      status: asString(readKey(order, 'status')),
      paymentStatus: asString(readKey(order, 'paymentStatus')),
      amount: asDouble(
        digPath(cab, ['pricing', 'grossAmount']) ?? readKey(order, 'amount'),
      ),
      travellerSummary: [
        asString(readKey(pax, 'firstName')),
        asString(readKey(pax, 'lastName')),
      ].where((s) => s.isNotEmpty).join(' '),
      raw: asJsonMap(entry),
    );
  }

  /// One entry of `GET tripjack-cabs/invoices` — a flatter, listing-oriented
  /// shape than [fromCabEntry]'s single-booking lookup. `route` arrives
  /// pre-joined as "Pickup → Dropoff"; the web client (`useBookingData.js`
  /// `fromInvoice`) splits it back apart for pickup/dropoff, but a mobile
  /// card just shows the joined route directly.
  factory TravelBooking.fromCabInvoiceRow(dynamic json) {
    final route = asString(readKey(json, 'route'));

    return TravelBooking(
      product: TravelProduct.cab,
      reference: firstNonEmpty([
        readKey(json, 'bookingId'),
        readKey(json, 'id'),
      ]),
      title: route.isNotEmpty ? route : 'Transfer',
      subtitle: asString(readKey(json, 'passengerName')),
      travelDate: DateTime.tryParse(asString(readKey(json, 'pickupTime'))),
      bookedOn: DateTime.tryParse(asString(readKey(json, 'createdAt'))),
      status: asString(readKey(json, 'bookingStatus')),
      paymentStatus: asString(readKey(json, 'paymentStatus')),
      amount: asDouble(readKey(json, 'amount')),
      travellerSummary: asString(readKey(json, 'passengerName')),
      raw: asJsonMap(json),
    );
  }

  /// `GET /insurance_payment/bookings`
  factory TravelBooking.fromInsuranceRow(dynamic json) {
    final travellers = asList(readKey(json, 'travellers'));

    return TravelBooking(
      product: TravelProduct.insurance,
      reference: firstNonEmpty([
        readKey(json, 'booking_id'),
        readKey(json, 'bookingId'),
      ]),
      title: firstNonEmpty([
        readKey(json, 'plan_name'),
        readKey(json, 'planLabel'),
      ], fallback: 'Travel insurance'),
      subtitle: firstNonEmpty([
        readKey(json, 'region_name'),
        readKey(json, 'regionName'),
        readKey(json, 'insurer'),
      ]),
      travelDate: DateTime.tryParse(
        firstNonEmpty([readKey(json, 'start_date'), readKey(json, 'sd')]),
      ),
      bookedOn: DateTime.tryParse(
        firstNonEmpty([
          readKey(json, 'created_at'),
          readKey(json, 'createdOn'),
        ]),
      ),
      status: firstNonEmpty([
        readKey(json, 'booking_status'),
        readKey(json, 'status'),
      ]),
      paymentStatus: asString(readKey(json, 'payment_status')),
      amount: asDouble(readKey(json, 'amount')),
      travellerSummary: travellers.isEmpty
          ? ''
          : '${travellers.length} traveller'
                '${travellers.length == 1 ? '' : 's'}',
      raw: asJsonMap(json),
    );
  }
}

// ---------------------------------------------------------------------------
// Flight trip context
// ---------------------------------------------------------------------------

/// What was searched for, carried through the booking funnel.
///
/// Passenger counts are not derivable from the fare — the fare quotes an
/// amount *per* passenger type — so the search's own numbers have to travel
/// with the itinerary all the way to the payment call.
class FlightTripContext {
  const FlightTripContext({
    required this.from,
    required this.to,
    required this.departure,
    this.returnDate,
    this.adults = 1,
    this.children = 0,
    this.infants = 0,
    this.cabinClass = 'ECONOMY',
  });

  final FlightLocation from;
  final FlightLocation to;
  final DateTime departure;
  final DateTime? returnDate;
  final int adults;
  final int children;
  final int infants;
  final String cabinClass;

  bool get isRoundTrip => returnDate != null;

  int get travellerCount => adults + children + infants;

  Map<PaxType, int> get paxCounts => <PaxType, int>{
    PaxType.adult: adults,
    PaxType.child: children,
    PaxType.infant: infants,
  };

  /// One blank form row per traveller, adults first — the order the supplier
  /// expects `travellerInfo` in.
  List<TravellerInput> buildTravellerForms() => <TravellerInput>[
    for (var i = 0; i < adults; i++) TravellerInput(type: PaxType.adult),
    for (var i = 0; i < children; i++) TravellerInput(type: PaxType.child),
    for (var i = 0; i < infants; i++) TravellerInput(type: PaxType.infant),
  ];

  /// "Adult 2", "Child 1" — the label above each form panel.
  String labelFor(int index) {
    if (index < adults) return 'Adult ${index + 1}';
    if (index < adults + children) return 'Child ${index - adults + 1}';
    return 'Infant ${index - adults - children + 1}';
  }

  String get travellerSummary {
    final label = FareBreakdown.paxLabel(paxCounts);
    final cabin = cabinClass
        .replaceAll('_', ' ')
        .toLowerCase()
        .replaceFirstMapped(RegExp(r'^\w'), (m) => m[0]!.toUpperCase());
    return '$label · $cabin';
  }
}
