/// Car-rental (TripJack cabs) models around [CabQuote]: the search itself,
/// its timing rules, the booked ride and the invoice views.
///
/// Each mirrors a piece of the web client:
///  * [CabSearchQuery.toPayload] ← `CarRentalSearchForm.jsx` `handleSearch`;
///  * [cabPickupProblem] / [cabReturnProblem] ← its `validatePickup` /
///    `validateReturn` (the two rules the cabs API enforces);
///  * [CabBookingDetail] ← `normalizeCabBookingDetail` in `cabApi.js`;
///  * [CabInvoiceDetail] ← `CabBookingDetail.jsx`
///    (`GET tripjack-cabs/invoice/:id/details`);
///  * [cabStatusOf] ← `utils/bookingStatus.js`, source `cab`.
library;

import 'honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

/// The three journey types the portal offers, as a radio group.
enum CabJourneyType {
  airportTransfer('airport_transfer', 'Airport Transfers'),
  outstation('outstation', 'Outstation'),
  local('local', 'Local');

  const CabJourneyType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CabJourneyType fromApi(String value) => CabJourneyType.values
      .firstWhere((t) => t.apiValue == value, orElse: () => airportTransfer);
}

/// The web's form limits and defaults (`CabPaxField`, `CarRentalSearchForm`).
class CabLimits {
  const CabLimits._();

  static const int minPassengers = 1;
  static const int maxPassengers = 10;
  static const int minBags = 0;
  static const int maxBags = 10;
  static const int defaultBags = 1;

  /// A pickup must be at least 2 hours out.
  static const Duration minLead = Duration(hours: 2);

  /// On a round trip the return must be at least 30 minutes after pickup.
  static const Duration minReturnGap = Duration(minutes: 30);

  /// Default clock times the two pickers open on.
  static const int defaultPickupHour = 9;
  static const int defaultReturnHour = 18;

  /// Location autocomplete starts at two characters (`CabLocationField`).
  static const int minLocationQuery = 2;
}

/// "Pickup time must be at least 2 hours from now", or null when fine.
String? cabPickupProblem(DateTime pickupAt, {DateTime? now}) {
  final from = now ?? DateTime.now();
  if (pickupAt.difference(from) < CabLimits.minLead) {
    return 'Pickup time must be at least 2 hours from now';
  }
  return null;
}

/// The return rule. The wording (including "atleast") is the web's.
String? cabReturnProblem(DateTime? pickupAt, DateTime returnAt) {
  if (pickupAt == null) return 'Select a pickup date and time first';
  if (returnAt.difference(pickupAt) < CabLimits.minReturnGap) {
    return 'Return time must be atleast 30 minutes after pickup time';
  }
  return null;
}

/// "YYYY-MM-DD HH:mm" — the cabs API's date-time string.
String cabApiDateTime(DateTime d) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
}

/// Everything a cab search was made with. Origin and destination are the
/// nodes `buildCabLocationNode` produces (coordinates already resolved).
class CabSearchQuery {
  const CabSearchQuery({
    required this.journeyType,
    required this.origin,
    required this.destination,
    required this.pickupAt,
    this.returnAt,
    this.passengers = CabLimits.minPassengers,
    this.bags = CabLimits.defaultBags,
  });

  final CabJourneyType journeyType;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final DateTime pickupAt;

  /// A return date makes it a round trip; none makes it one way — the portal
  /// has no separate switch, so the two can never disagree.
  final DateTime? returnAt;
  final int passengers;
  final int bags;

  bool get isRoundTrip => returnAt != null;
  String get tripType => isRoundTrip ? 'roundtrip' : 'oneway';

  String get originLabel => asString(readKey(origin, 'displayAddress'));
  String get destinationLabel =>
      asString(readKey(destination, 'displayAddress'));

  /// The `tripjack-cabs/quotes` body, exactly as `handleSearch` builds it.
  /// `luggageCount` is only sent for outstation, as on the web.
  Map<String, dynamic> toPayload() {
    final pax = passengers < 1 ? 1 : passengers;
    return <String, dynamic>{
      'pickupDate': cabApiDateTime(pickupAt),
      if (returnAt != null) 'returnDate': cabApiDateTime(returnAt!),
      'origin': origin,
      'destination': destination,
      'journeyType': journeyType.apiValue,
      'tripType': tripType,
      'passengers': pax,
      'quoteFilter': <String, dynamic>{
        'paxCount': pax,
        if (journeyType == CabJourneyType.outstation)
          'luggageCount': bags < 1 ? 1 : bags,
      },
    };
  }

  CabSearchQuery copyWith({
    CabJourneyType? journeyType,
    Map<String, dynamic>? origin,
    Map<String, dynamic>? destination,
    DateTime? pickupAt,
    DateTime? returnAt,
    bool clearReturn = false,
    int? passengers,
    int? bags,
  }) => CabSearchQuery(
    journeyType: journeyType ?? this.journeyType,
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    pickupAt: pickupAt ?? this.pickupAt,
    returnAt: clearReturn ? null : (returnAt ?? this.returnAt),
    passengers: passengers ?? this.passengers,
    bags: bags ?? this.bags,
  );

  /// For parking a search across a sign-in ([CabBookingDraft]).
  Map<String, dynamic> toJson() => {
    'journeyType': journeyType.apiValue,
    'origin': origin,
    'destination': destination,
    'pickupAt': pickupAt.toIso8601String(),
    if (returnAt != null) 'returnAt': returnAt!.toIso8601String(),
    'passengers': passengers,
    'bags': bags,
  };

  static CabSearchQuery? fromJson(dynamic json) {
    final pickup = DateTime.tryParse(asString(readKey(json, 'pickupAt')));
    final origin = asJsonMap(readKey(json, 'origin'));
    final destination = asJsonMap(readKey(json, 'destination'));
    if (pickup == null || origin.isEmpty || destination.isEmpty) return null;
    return CabSearchQuery(
      journeyType: CabJourneyType.fromApi(
        asString(readKey(json, 'journeyType')),
      ),
      origin: origin,
      destination: destination,
      pickupAt: pickup,
      returnAt: DateTime.tryParse(asString(readKey(json, 'returnAt'))),
      passengers: asInt(readKey(json, 'passengers'), fallback: 1),
      bags: asInt(readKey(json, 'bags'), fallback: CabLimits.defaultBags),
    );
  }
}

// ---------------------------------------------------------------------------
// Quotes
// ---------------------------------------------------------------------------

/// The key the results page groups quotes into one card by — the web's
/// `${vehicleType}|${vehicleCategory}|${label}`.
String cabClassKey(CabQuote q) => '${q.vehicleType}|${q.category}|${q.label}';

/// One quote's identity across a re-search (a parked booking is resumed by
/// searching again and picking the same vehicle class from the same vendor).
String cabQuoteIdentity(CabQuote q) => '${cabClassKey(q)}|${q.vendorId}';

/// "One Way" / "Round Trip" from the API's tripType (`titleTrip`).
String cabTripTitle(String tripType) =>
    tripType.toLowerCase() == 'roundtrip' ? 'Round Trip' : 'One Way';

// ---------------------------------------------------------------------------
// Booked ride (tripjack-cabs/booking/details, payment/verify.bookingDetails)
// ---------------------------------------------------------------------------

/// The web's `normalizeCabBookingDetail`: one entry of the booking-details
/// list, flattened.
class CabBookingDetail {
  const CabBookingDetail({
    required this.bookingId,
    this.status = '',
    this.paymentStatus = '',
    this.rideStatus = '',
    this.trackingLink = '',
    this.helpline = '',
    this.tripType = '',
    this.passengerName = '',
    this.vehicleClass = '',
    this.source = '',
    this.destination = '',
    this.pickupDate,
    this.returnDate,
    this.distance = '',
    this.flightNumber = '',
    this.grossAmount,
  });

  final String bookingId;
  final String status;
  final String paymentStatus;
  final String rideStatus;
  final String trackingLink;
  final String helpline;
  final String tripType;
  final String passengerName;
  final String vehicleClass;
  final String source;
  final String destination;
  final DateTime? pickupDate;
  final DateTime? returnDate;
  final String distance;
  final String flightNumber;

  /// `pricing.grossAmount`; null when the supplier left it out, so the page
  /// can fall back to the booking's own total.
  final double? grossAmount;

  bool get isPaid => paymentStatus.toUpperCase() == 'SUCCESS';

  /// Places come back as plain strings or as location nodes.
  static String _place(dynamic value) => value is Map
      ? firstNonEmpty([value['displayAddress'], value['city']])
      : asString(value);

  factory CabBookingDetail.fromEntry(dynamic entry) {
    final order = readKey(entry, 'order');
    final cab = digPath(entry, ['itemInfos', 'CAB']);
    final journey = readKey(cab, 'journeyInfo');
    final pax = readKey(cab, 'paxDetails');
    final gross = digPath(cab, ['pricing', 'grossAmount']);
    return CabBookingDetail(
      bookingId: asString(readKey(order, 'bookingId')),
      status: asString(readKey(order, 'status')),
      paymentStatus: asString(readKey(order, 'paymentStatus')),
      rideStatus: asString(readKey(order, 'rideStatus')),
      trackingLink: asString(readKey(order, 'trackingLink')),
      helpline: asString(readKey(order, 'helpline')),
      tripType: asString(readKey(order, 'tripType')),
      passengerName: firstNonEmpty([
        readKey(pax, 'fullName'),
        [
          asString(readKey(pax, 'firstName')),
          asString(readKey(pax, 'lastName')),
        ].where((s) => s.isNotEmpty).join(' '),
      ]),
      vehicleClass: asString(readKey(readKey(cab, 'vehicleDetail'), 'clazz')),
      source: _place(readKey(journey, 'source')),
      destination: _place(readKey(journey, 'destination')),
      pickupDate: DateTime.tryParse(asString(readKey(journey, 'pickupDate'))),
      returnDate: DateTime.tryParse(asString(readKey(journey, 'returnDate'))),
      distance: asString(readKey(journey, 'distance')),
      flightNumber: asString(digPath(journey, ['flightDetails', 'number'])),
      grossAmount: gross == null ? null : asDouble(gross),
    );
  }

  /// The booking the verify call echoes back (`verifyResult.bookingDetails`),
  /// or null when it sent none.
  static CabBookingDetail? fromVerify(dynamic verifyJson) {
    final list = asList(readKey(verifyJson, 'bookingDetails'));
    if (list.isEmpty) return null;
    return CabBookingDetail.fromEntry(list.first);
  }
}

/// What `POST tripjack-cabs/book` returns (`data`), for the success page while
/// the booking detail is not in yet — the web falls back to the same fields.
class CabCreatedBooking {
  const CabCreatedBooking({
    required this.id,
    this.status = '',
    this.paymentStatus = '',
    this.totalPrice = 0,
    this.passengerName = '',
    this.vehicleClass = '',
    this.trackingLink = '',
    this.source = '',
    this.destination = '',
    this.pickupDate,
    this.distance = '',
  });

  final String id;
  final String status;
  final String paymentStatus;
  final double totalPrice;
  final String passengerName;
  final String vehicleClass;
  final String trackingLink;
  final String source;
  final String destination;
  final DateTime? pickupDate;
  final String distance;

  factory CabCreatedBooking.fromJson(dynamic data) {
    final journey = readKey(data, 'journey');
    return CabCreatedBooking(
      id: asString(readKey(data, 'id')),
      status: asString(readKey(data, 'status')),
      paymentStatus: asString(readKey(data, 'paymentStatus')),
      totalPrice: asDouble(readKey(data, 'totalPrice')),
      passengerName: asString(digPath(data, ['passenger', 'fullName'])),
      vehicleClass: asString(digPath(data, ['bookingVehicle', 'clazz'])),
      trackingLink: asString(readKey(data, 'trackingLink')),
      source: CabBookingDetail._place(readKey(journey, 'source')),
      destination: CabBookingDetail._place(readKey(journey, 'destination')),
      pickupDate: DateTime.tryParse(asString(readKey(journey, 'pickupDate'))),
      distance: asString(readKey(journey, 'distance')),
    );
  }
}

// ---------------------------------------------------------------------------
// Invoices (the dashboard's cab list and detail)
// ---------------------------------------------------------------------------

/// `GET tripjack-cabs/invoice/:id/details` → `invoice`, read the way
/// `CabBookingDetail.jsx` reads it.
class CabInvoiceDetail {
  const CabInvoiceDetail({
    required this.invoiceNumber,
    this.bookingId = '',
    this.orderId = '',
    this.pickupLocation = '',
    this.dropoffLocation = '',
    this.pickupTime,
    this.distance = '',
    this.passengerName = '',
    this.passengerEmail = '',
    this.passengerPhone = '',
    this.baseFare = 0,
    this.taxes = 0,
    this.total = 0,
    this.bookingStatus = '',
    this.paymentStatus = '',
    this.createdAt,
  });

  final String invoiceNumber;
  final String bookingId;

  /// The Razorpay order id — the invoice PDF is fetched by this.
  final String orderId;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime? pickupTime;
  final String distance;
  final String passengerName;
  final String passengerEmail;
  final String passengerPhone;
  final double baseFare;
  final double taxes;
  final double total;
  final String bookingStatus;
  final String paymentStatus;
  final DateTime? createdAt;

  /// "Booking ID: {invoiceNumber || bookingId}".
  String get displayId => invoiceNumber.isNotEmpty ? invoiceNumber : bookingId;

  factory CabInvoiceDetail.fromJson(dynamic invoice) {
    final journey = readKey(invoice, 'journey');
    final passenger = readKey(invoice, 'passenger');
    final pricing = readKey(invoice, 'pricing');
    return CabInvoiceDetail(
      invoiceNumber: asString(readKey(invoice, 'invoiceNumber')),
      bookingId: asString(readKey(invoice, 'bookingId')),
      orderId: asString(readKey(invoice, 'orderId')),
      pickupLocation: asString(readKey(journey, 'pickupLocation')),
      dropoffLocation: asString(readKey(journey, 'dropoffLocation')),
      pickupTime: DateTime.tryParse(asString(readKey(journey, 'pickupTime'))),
      distance: asString(readKey(journey, 'distance')),
      passengerName: asString(readKey(passenger, 'name')),
      passengerEmail: asString(readKey(passenger, 'email')),
      passengerPhone: asString(readKey(passenger, 'phone')),
      baseFare: asDouble(readKey(pricing, 'baseFare')),
      taxes: asDouble(readKey(pricing, 'taxes')),
      total: asDouble(readKey(pricing, 'total')),
      bookingStatus: asString(digPath(invoice, ['booking', 'status'])),
      paymentStatus: asString(digPath(invoice, ['payment', 'status'])),
      createdAt: DateTime.tryParse(asString(readKey(invoice, 'createdAt'))),
    );
  }
}

// ---------------------------------------------------------------------------
// Status (utils/bookingStatus.js → cab)
// ---------------------------------------------------------------------------

enum CabStatusKey { confirmed, pending, cancelled, failed, unknown }

class CabStatus {
  const CabStatus(this.key, this.label);

  final CabStatusKey key;
  final String label;
}

/// The dashboard's status pills, in the order the web builds them.
const List<CabStatusKey> kCabStatusFilters = [
  CabStatusKey.confirmed,
  CabStatusKey.pending,
  CabStatusKey.cancelled,
];

CabStatus cabStatusOf(String raw) {
  final upper = raw.trim().toUpperCase();
  final key = switch (upper) {
    'SUCCESS' || 'CONFIRMED' => CabStatusKey.confirmed,
    'PENDING' || 'IN_PROGRESS' => CabStatusKey.pending,
    'CANCELLED' || 'CANCELED' => CabStatusKey.cancelled,
    'FAILED' => CabStatusKey.failed,
    _ => CabStatusKey.unknown,
  };
  // The generic label is the title-cased raw status ("Payment Pending").
  final label = upper.isEmpty
      ? 'Unknown'
      : upper
            .toLowerCase()
            .split(RegExp(r'[\s_-]+'))
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + w.substring(1))
            .join(' ');
  return CabStatus(key, label);
}

// ---------------------------------------------------------------------------
// Formatting
// ---------------------------------------------------------------------------

const _kCabDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _kCabMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "09:00 AM".
String formatCabTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final suffix = d.hour >= 12 ? 'PM' : 'AM';
  return '${h.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')} $suffix';
}

/// The portal's field value: "Sat, 29 Aug'26, 09:00 AM" (`formatDateTime` in
/// `CabDateTimeField.jsx`). With [withTime] false, the date part alone.
String formatCabDateTime(DateTime d, {bool withTime = true}) {
  final stamp =
      '${_kCabDays[d.weekday - 1]}, ${d.day} ${_kCabMonths[d.month - 1]}'
      "'${(d.year % 100).toString().padLeft(2, '0')}";
  return withTime ? '$stamp, ${formatCabTime(d)}' : stamp;
}
