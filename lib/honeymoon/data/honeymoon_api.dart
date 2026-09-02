/// The only place in the Honeymoon module that talks HTTP or touches JSON.
///
/// Every endpoint here was taken from the existing web client under
/// `backend/services/api/` — nothing is invented:
///   hotels      → backend/services/api/hotelApi.js
///   flights     → backend/services/api/flightApi.js
///   insurance   → backend/services/api/tripSafeApi.js
///   car rental  → backend/services/api/cabApi.js
///
/// Auth mirrors the web `axiosInstance` request interceptor: attach
/// `Authorization: Bearer <token>` when a token is stored. Endpoints that are
/// public stay public — the header is simply omitted when there is no token.
///
/// One deliberate exception: `tripSafeApi.js` issues its calls with bare
/// `axios`, so it never passes through the interceptor. Those requests are
/// sent unauthenticated here too (`auth: false`) to keep the contract identical.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../honeymoon_config.dart';
import '../models/booking_models.dart';
import '../models/honeymoon_models.dart';

/// A failure the UI can render without leaking internals.
class HoneymoonApiException implements Exception {
  HoneymoonApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class HoneymoonApi {
  HoneymoonApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // ---------------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------------

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalised = path.startsWith('/') ? path.substring(1) : path;
    final base = Uri.parse('${HoneymoonConfig.apiBase}/$normalised');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        ...base.queryParameters,
        for (final e in query.entries)
          if (e.value != null) e.key: '${e.value}',
      },
    );
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    // Some endpoints are called with bare axios on the web (no interceptor),
    // so they must not receive an Authorization header here either.
    if (!auth) return headers;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(HoneymoonConfig.authTokenKey) ?? '';
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      // A missing token store must not break public endpoints.
      debugPrint('[HoneymoonApi] token read failed: $e');
    }
    return headers;
  }

  /// Turns any transport/HTTP failure into a [HoneymoonApiException] and any
  /// success into decoded JSON. Returns `{}` for an empty body.
  Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) run,
    String label, {
    bool auth = true,
    Duration? timeout,
  }) async {
    late final http.Response res;
    try {
      res = await run(
        await _headers(auth: auth),
      ).timeout(timeout ?? HoneymoonConfig.requestTimeout);
    } on TimeoutException {
      throw HoneymoonApiException(
        'That took too long. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[HoneymoonApi] $label transport error: $e');
      throw HoneymoonApiException(
        "We couldn't reach our travel partner. Please check your connection.",
      );
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(res.body);
      } catch (e) {
        debugPrint('[HoneymoonApi] $label decode error: $e');
        throw HoneymoonApiException(
          'We received an unexpected response. Please try again.',
        );
      }
    }

    debugPrint('[HoneymoonApi] $label HTTP ${res.statusCode}');
    throw HoneymoonApiException(
      _messageForStatus(res.statusCode, res.body),
      statusCode: res.statusCode,
    );
  }

  /// User-facing copy per status. Raw server text is never surfaced except for
  /// 422, where the field message is genuinely useful — and even then only if
  /// it is short enough to be a sentence rather than a stack trace.
  String _messageForStatus(int status, String body) {
    switch (status) {
      case 400:
        // The supplier explains fare-combination refusals here, and its
        // wording is the only thing that tells a traveller what to change.
        final reason = _extractMessage(body);
        return reason.isNotEmpty && reason.length <= 160
            ? reason
            : 'Some of those details look off. Please review and try again.';
      case 401:
      case 403:
        return 'Please sign in to continue.';
      case 404:
        return 'We could not find anything for that search.';
      case 422:
        final detail = _extractMessage(body);
        return detail.isNotEmpty && detail.length <= 160
            ? detail
            : 'Some of those details are not valid. Please review and try again.';
      case 429:
        return 'Too many searches just now. Please wait a moment and retry.';
      default:
        if (status >= 500) {
          return 'Our travel partner is busy right now. Please try again shortly.';
        }
        return 'Something went wrong. Please try again.';
    }
  }

  String _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        for (final key in ['message', 'error', 'detail']) {
          final v = decoded[key];
          if (v is String && v.trim().isNotEmpty) return v.trim();
        }
        // The supplier reports refusals as a list of errors rather than a
        // single message — `{errors: [{errCode, message}]}`.
        final errors = decoded['errors'];
        if (errors is List) {
          for (final e in errors) {
            final v = e is Map ? e['message'] : null;
            if (v is String && v.trim().isNotEmpty) return v.trim();
          }
        }
        final nested = _digDynamic(decoded, ['status', 'message']);
        if (nested is String && nested.trim().isNotEmpty) return nested.trim();
      }
    } catch (_) {
      // Body was not JSON — fall through to the generic message.
    }
    return '';
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) =>
      _send((h) => _client.get(_uri(path, query), headers: h), 'GET $path');

  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) => _send(
    (h) => _client.post(_uri(path), headers: h, body: jsonEncode(body)),
    'POST $path',
    auth: auth,
  );

  // ---------------------------------------------------------------------------
  // Destinations — hotelApi.js
  // ---------------------------------------------------------------------------

  /// `GET hotels/city-regions` with the documented POST fallback on 404.
  Future<List<HoneymoonDestination>> searchCityRegions(
    String keyword, {
    String? country,
    int limit = 30,
  }) async {
    if (keyword.trim().length < 2) return const [];

    final params = <String, dynamic>{
      'keyword': keyword.trim(),
      'limit': limit,
      if (country != null && country.isNotEmpty) 'selectedCountry': country,
    };

    dynamic json;
    try {
      json = await _get('hotels/city-regions', params);
    } on HoneymoonApiException catch (e) {
      if (e.statusCode != 404) rethrow;
      json = await _post('hotels/city-regions', params);
    }

    return _unwrapList(json, const [
      'cityRegions',
      'regions',
      'suggestions',
      'results',
      'data',
      'items',
    ]).map(HoneymoonDestination.fromCityRegion).where((d) => d.displayName.isNotEmpty).toList();
  }

  /// `GET hotels/static-hotels/search` — specific properties by name.
  Future<List<HoneymoonDestination>> searchStaticHotels(
    String keyword, {
    int limit = 15,
  }) async {
    if (keyword.trim().length < 3) return const [];
    final json = await _get('hotels/static-hotels/search', {
      'keyword': keyword.trim(),
      'limit': limit,
    });
    return _unwrapList(json, const [
      'hotels',
      'suggestions',
      'results',
      'data',
      'items',
    ]).map(HoneymoonDestination.fromStaticHotel).where((d) => d.displayName.isNotEmpty).toList();
  }

  /// `GET hotels/countries`.
  Future<List<String>> fetchCountries() async {
    try {
      final json = await _get('hotels/countries');
      return _unwrapList(json, const ['countries', 'data'])
          .map((c) => c is String ? c : asString(_nameOf(c)))
          .where((c) => c.isNotEmpty)
          .toList();
    } on HoneymoonApiException {
      // The web client degrades to a minimal list here rather than blocking
      // the hero; do the same.
      return const [HoneymoonConfig.defaultCountryName];
    }
  }

  // ---------------------------------------------------------------------------
  // Hotels — hotelApi.js
  // ---------------------------------------------------------------------------

  /// `POST hotels/search`. Payload mirrors HotelSearchForm.jsx exactly.
  Future<HotelSearchResult> searchHotels({
    required HoneymoonDestination destination,
    required DateTime checkIn,
    required DateTime checkOut,
    required List<RoomOccupancy> rooms,
    List<int> ratings = const [],
    String sortOrder = 'popularity',
    int pageSize = 15,
    String lastHotelId = '',
    String searchId = '',
  }) async {
    final isHotel = destination.isHotel;
    final tjids = isHotel && destination.hotelId.isNotEmpty
        ? [destination.hotelId]
        : <String>[];

    final payload = <String, dynamic>{
      'searchQuery': {
        'checkinDate': _apiDate(checkIn),
        'checkoutDate': _apiDate(checkOut),
        'roomInfo': rooms.map((r) => r.toRoomInfo()).toList(),
        'searchCriteria': {
          'city': tjids.isEmpty ? destination.city : '',
          'cityRegionIds':
              !isHotel && destination.id.isNotEmpty ? [destination.id] : <String>[],
          'regionIds':
              !isHotel && destination.id.isNotEmpty ? [destination.id] : <String>[],
          'countryName': destination.country.isNotEmpty
              ? destination.country
              : HoneymoonConfig.defaultCountryName,
          'tjids': tjids,
          'nationality': HoneymoonConfig.defaultNationality,
          'countryOfResidence': HoneymoonConfig.defaultCountryOfResidence,
          'currency': HoneymoonConfig.currency,
          'searchRegionName': destination.searchRegionName,
          'searchRegionType': destination.searchRegionType,
        },
        'searchType': isHotel ? 'HOTEL' : 'CITY',
        'gstApplied': false,
      },
      'allOptions': true,
      'appliedFilters': {
        'ratings': ratings,
        'onlyFavorites': false,
        'hotelName': '',
      },
      'pagination': {'pageSize': pageSize, 'lastHotelId': lastHotelId},
      'searchId': searchId,
      'correlationId': _correlationId(),
      'filterType': 'BOTH',
      'sortOrder': sortOrder,
    };

    return HotelSearchResult.fromJson(await _post('hotels/search', payload));
  }

  /// `POST hotels/filters` — the facets the backend can actually apply.
  Future<Map<String, dynamic>> fetchHotelFilters({
    required String searchId,
  }) async {
    final json = await _post('hotels/filters', {'searchId': searchId});
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  /// `POST hotels/detail` — room options and pricing for one property.
  Future<Map<String, dynamic>> fetchHotelDetail({
    required String hotelId,
    String searchId = '',
    String optionId = '',
  }) async {
    final json = await _post('hotels/detail', {
      'hotelId': hotelId,
      if (searchId.isNotEmpty) 'searchId': searchId,
      if (optionId.isNotEmpty) 'optionId': optionId,
    });
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  /// `POST hotels/static-content` — descriptions, images, amenities.
  Future<Map<String, dynamic>> fetchHotelStaticContent({
    required String hotelId,
  }) async {
    final json = await _post('hotels/static-content', {'hotelId': hotelId});
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  // ---------------------------------------------------------------------------
  // Flights — flightApi.js
  // ---------------------------------------------------------------------------

  /// `GET /tj/meta/locations`.
  ///
  /// This endpoint alone returns the supplier's raw envelope —
  /// `{ payload: { suggestions: [...] } }` — where the rest return their list
  /// under `data`. Without `payload`/`suggestions` in the key list nothing
  /// matched, the airport picker was always empty, and flight search could
  /// never be started at all.
  Future<List<FlightLocation>> searchFlightLocations(String query) async {
    if (query.trim().length < 2) return const [];
    final json = await _get('tj/meta/locations', {'q': query.trim()});
    _throwIfHandledFailure(json, 'Airport lookup is unavailable right now.');
    return _unwrapList(json, const [
          'suggestions',
          'locations',
          'results',
          'data',
          'items',
          'payload',
        ])
        .map(FlightLocation.fromJson)
        .where((l) => l.code.isNotEmpty)
        .toList();
  }

  /// `POST /tj/fms/search`. searchQuery built per utils/flightSearchUtils.js.
  Future<FlightSearchResult> searchFlights({
    required String fromCode,
    required String toCode,
    required DateTime departure,
    DateTime? returnDate,
    int adults = 2,
    int children = 0,
    int infants = 0,
    String cabinClass = 'ECONOMY',
    bool directOnly = false,
  }) async {
    final routeInfos = <Map<String, dynamic>>[
      {
        'fromCityOrAirport': {'code': fromCode},
        'toCityOrAirport': {'code': toCode},
        'travelDate': _apiDate(departure),
      },
      if (returnDate != null)
        {
          'fromCityOrAirport': {'code': toCode},
          'toCityOrAirport': {'code': fromCode},
          'travelDate': _apiDate(returnDate),
        },
    ];

    final searchQuery = <String, dynamic>{
      'cabinClass': cabinClass.toUpperCase().replaceAll(RegExp(r'\s+'), '_'),
      'paxInfo': {
        'ADULT': '$adults',
        'CHILD': '$children',
        'INFANT': '$infants',
      },
      'routeInfos': routeInfos,
      'searchModifiers': {
        'isDirectFlight': directOnly,
        'isConnectingFlight': !directOnly,
      },
    };

    final json = await _post('tj/fms/search', {'searchQuery': searchQuery});
    _throwIfHandledFailure(json, 'Flight search is unavailable right now.');
    return _extractFlights(json);
  }

  /// TripJack groups trips under `searchResult.tripInfos.{ONWARD, RETURN}`.
  ///
  /// Those groups are the whole point on a round trip: flattening them into
  /// one list — as this used to — mixed outbound and return flights into a
  /// single set of cards with no way to tell which leg a card belonged to.
  FlightSearchResult _extractFlights(dynamic json) {
    final tripInfos =
        _digDynamic(json, ['searchResult', 'tripInfos']) ??
        _digDynamic(json, ['data', 'searchResult', 'tripInfos']) ??
        _digDynamic(json, ['tripInfos']);

    List<FlightResult> parse(dynamic entry) => asList(entry)
        .map(FlightResult.fromTripJack)
        .where((f) => f.id.isNotEmpty)
        .toList();

    if (tripInfos is List) {
      return FlightSearchResult(onward: parse(tripInfos));
    }
    if (tripInfos is! Map) return const FlightSearchResult();

    final onward = <FlightResult>[];
    final inbound = <FlightResult>[];

    for (final entry in tripInfos.entries) {
      final key = asString(entry.key).toUpperCase();
      final flights = parse(entry.value);
      // Anything not explicitly a return leg is treated as outbound, which is
      // also what makes a one-way response (`ONWARD` only) land correctly.
      if (key.contains('RETURN') || key.contains('INBOUND')) {
        inbound.addAll(flights);
      } else {
        onward.addAll(flights);
      }
    }

    return FlightSearchResult(onward: onward, inbound: inbound);
  }

  // ---------------------------------------------------------------------------
  // Insurance — tripSafeApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripsafe/search` for an international single trip. Payload shape
  /// copied from InsuranceSearchPanel.jsx (the `isq` envelope).
  Future<List<InsurancePlan>> searchInsurance({
    required String regionKey,
    required DateTime start,
    required DateTime end,
    required List<int> travellerAges,
    String regionType = 'COUNTRY',
  }) async {
    final payload = <String, dynamic>{
      'isq': {
        'sd': _apiDate(start),
        'ed': _apiDate(end),
        'isc': {
          'iri': [
            {'rkey': regionKey, 'rt': regionType},
          ],
        },
        'iti': travellerAges.map((age) => {'age': age}).toList(),
        'isp': <String, dynamic>{},
      },
    };

    // tripSafeApi.js calls this with bare axios, i.e. unauthenticated.
    final json = await _post('tripsafe/search', payload, auth: false);

    // The service returns { status: false, message } for handled failures.
    if (json is Map && json['status'] == false) {
      throw HoneymoonApiException(
        asString(json['message'], fallback: 'Insurance search failed.'),
      );
    }

    return InsurancePlan.fromSearchResponse(json)
        .where((p) => p.isBookable)
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  // ---------------------------------------------------------------------------
  // Car rental — cabApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripjack-cabs/search-locations` — Google Places autocomplete.
  Future<List<Map<String, dynamic>>> searchCabLocations(String input) async {
    if (input.trim().length < 3) return const [];
    final json = await _post('tripjack-cabs/search-locations', {
      'input': input.trim(),
    });
    final places = _digDynamic(json, ['data', 'places']) ?? _digDynamic(json, ['places']);
    return asList(places).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  /// `POST tripjack-cabs/lat-long` — resolves a place id to coordinates.
  Future<Map<String, dynamic>> fetchCabPlaceDetails(String placeId) async {
    final json = await _post('tripjack-cabs/lat-long', {'placeId': placeId});
    final data = _digDynamic(json, ['data']) ?? json;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  /// `POST tripjack-cabs/quotes`. Origin/destination nodes are built the same
  /// way as buildCabLocationNode() in cabApi.js.
  ///
  /// Returns the whole payload, not just the fares: `journeyInfo` and
  /// `routeDetails` are echoed back verbatim in the booking request, so
  /// discarding them here would make the quotes unbookable.
  Future<CabQuoteResult> fetchCabQuotes({
    required Map<String, dynamic> origin,
    required Map<String, dynamic> destination,
    required DateTime pickupAt,
    String journeyType = 'airport_transfer',
    String tripType = 'oneway',
  }) async {
    final json = await _post('tripjack-cabs/quotes', {
      'journeyType': journeyType,
      'tripType': tripType,
      'origin': origin,
      'destination': destination,
      'pickupDateTime': pickupAt.toIso8601String(),
    });

    _throwIfHandledFailure(json, 'Could not fetch cab quotes.');
    final data = _digDynamic(json, ['data']) ?? json;
    return CabQuoteResult.fromJson(data);
  }

  /// Builds the origin/destination node the quotes endpoint expects.
  static Map<String, dynamic> buildCabLocationNode({
    required String displayAddress,
    required Map<String, dynamic> details,
  }) {
    final location = details['location'];
    final address = details['address'];
    return {
      'type': 'location',
      'displayAddress': displayAddress,
      'lat': asString(location is Map ? location['lat'] : null),
      'long': asString(location is Map ? location['lng'] : null),
      'address': {
        'city': asString(address is Map ? address['city'] : null),
        'country': asString(address is Map ? address['country'] : null),
        'postalCode': asString(address is Map ? address['postalCode'] : null),
      },
    };
  }

  // ---------------------------------------------------------------------------
  // Flight booking — flightApi.js
  // ---------------------------------------------------------------------------

  /// `POST /tj/fms/review` — re-prices the chosen fare and opens a booking
  /// session. Nothing downstream works without the `bookingId` it returns.
  Future<FlightReview> reviewFlight(List<String> priceIds) async {
    final ids = priceIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) {
      throw HoneymoonApiException(
        'That fare is no longer available. Please search again.',
      );
    }
    final review = FlightReview.fromJson(
      await _post('tj/fms/review', {'priceIds': ids}),
    );
    if (!review.isUsable) {
      throw HoneymoonApiException(
        'That fare could not be confirmed. Please search again.',
      );
    }
    return review;
  }

  /// `GET Flight_booking/travellers` — people this account has booked for
  /// before, to prefill the passenger form.
  ///
  /// Returns an empty list rather than throwing: a convenience lookup must
  /// never block a booking.
  Future<List<Map<String, dynamic>>> fetchSavedTravellers() async {
    try {
      final json = await _get('Flight_booking/travellers');
      return _unwrapList(json, const ['data', 'travellers', 'results'])
          .map(asJsonMap)
          .toList();
    } catch (e) {
      debugPrint('[HoneymoonApi] saved travellers unavailable: $e');
      return const [];
    }
  }

  /// Reshapes the booking payload into what our payment endpoints expect.
  ///
  /// `flightApi.js` does this mapping inside the API layer rather than at the
  /// call site, and the rename matters: the endpoint reads `amount`, so
  /// passing the caller's `price` through untouched is rejected outright with
  /// *"Missing offer_id/provider/amount"*. Keeping the translation here means
  /// the screens go on describing a fare in their own words.
  static Map<String, dynamic> _flightPaymentBody(
    Map<String, dynamic> payload, {
    required bool includeOfferId,
    bool isHoldConfirm = false,
  }) {
    return <String, dynamic>{
      if (includeOfferId) 'offer_id': payload['offer_id'],
      'provider': payload['provider'],
      'amount': payload['price'],
      'trip_type': payload['trip_type'],
      'from': payload['from'],
      'to': payload['to'],
      'departure': payload['departure'],
      'arrival': payload['arrival'],
      'flight_no': payload['flight_no'],
      'airline': payload['airline'],
      'cabin_class': payload['cabin_class'],
      'passengers': payload['passengers'],
      'contact': payload['contact'],
      'booking_payload': payload['booking_payload'],
      if (includeOfferId) 'is_hold_confirm': isHoldConfirm,
    };
  }

  /// `POST /flight_payment/hold` — blocks the fare without payment. Only
  /// offered when the review said the fare allows it.
  Future<BookingOutcome> holdFlight(Map<String, dynamic> payload) async {
    final json = await _post(
      'flight_payment/hold',
      _flightPaymentBody(payload, includeOfferId: false),
    );
    final ok = readKey(json, 'status');
    if (ok == false) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback: 'Could not hold this fare. Please try again.',
        ),
      );
    }
    return BookingOutcome(
      product: TravelProduct.flight,
      reference: firstNonEmpty([
        readKey(json, 'held_booking_id'),
        readKey(json, 'order_id'),
        readKey(json, 'bookingId'),
      ]),
      status: asString(readKey(json, 'status')),
      onHold: true,
      message: asString(readKey(json, 'message')),
      raw: asJsonMap(json),
    );
  }

  /// `POST /flight_payment/create_order` — a gateway order for the fare.
  ///
  /// [isHoldConfirm] is set when paying for a fare that was previously held,
  /// which tells the backend to ticket via confirm-book rather than book.
  Future<PaymentOrder> createFlightPaymentOrder(
    Map<String, dynamic> payload, {
    bool isHoldConfirm = false,
  }) async {
    final order = PaymentOrder.fromJson(
      await _post(
        'flight_payment/create_order',
        _flightPaymentBody(
          payload,
          includeOfferId: true,
          isHoldConfirm: isHoldConfirm,
        ),
      ),
    );
    if (!order.isUsable) {
      throw HoneymoonApiException(
        'The payment could not be started. Please try again in a moment.',
      );
    }
    return order;
  }

  /// `POST /flight_payment/verify_and_book` — verifies the payment signature
  /// and issues the ticket. The one call that must never be retried blindly.
  Future<BookingOutcome> verifyAndBookFlight(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post('flight_payment/verify_and_book', payload);
    final reference = firstNonEmpty([
      readKey(json, 'order_id'),
      readKey(json, 'booking_id'),
      readKey(json, 'bookingId'),
    ]);

    if (reference.isEmpty && readKey(json, 'status') != true) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback:
              'Your payment went through but the booking could not be '
              'confirmed. Our team will contact you shortly.',
        ),
      );
    }

    return BookingOutcome(
      product: TravelProduct.flight,
      reference: reference,
      status: firstNonEmpty([
        readKey(json, 'booking_status'),
        readKey(json, 'order_status'),
      ], fallback: 'CONFIRMED'),
      amountPaid: asDouble(
        readKey(json, 'amount_paid') ?? readKey(json, 'amount'),
      ),
      message: asString(readKey(json, 'message')),
      raw: asJsonMap(json),
    );
  }

  /// `GET /tj/my-bookings`
  Future<List<TravelBooking>> fetchFlightBookings() async {
    final json = await _get('tj/my-bookings');
    return _unwrapList(json, const ['data', 'bookings', 'results'])
        .map(TravelBooking.fromFlightRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  /// `POST /tj/oms/booking-details`
  Future<Map<String, dynamic>> fetchFlightBookingDetails(
    String bookingId,
  ) async {
    final json = await _post('tj/oms/booking-details', {
      'bookingId': bookingId,
      'requirePaxPricing': true,
    });
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `POST /tj/oms/cancel-charges` — previews the refund. Does *not* cancel.
  Future<Map<String, dynamic>> fetchFlightCancelCharges(String orderId) async {
    final json = await _post('tj/oms/cancel-charges', {
      'provider': 'tripjack',
      'order_id': orderId,
    });
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `POST /tj/oms/cancel`
  Future<Map<String, dynamic>> cancelFlightBooking(String orderId) async {
    final json = await _post('tj/oms/cancel', {
      'provider': 'tripjack',
      'order_id': orderId,
    });
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `POST /tj/oms/release-hold` — gives back a held fare that was not paid.
  Future<void> releaseHeldFlight(String orderId) async {
    await _post('tj/oms/release-hold', {'order_id': orderId});
  }

  /// `POST /flight_payment/email-ticket`
  Future<void> emailFlightTicket(String orderId) async {
    await _post('flight_payment/email-ticket', {'order_id': orderId});
  }

  // ---------------------------------------------------------------------------
  // Hotel booking — hotelApi.js
  // ---------------------------------------------------------------------------

  /// `POST hotels/review` — final price and booking requirements for the
  /// chosen room option, plus the `bookingId` the rest of the flow needs.
  Future<Map<String, dynamic>> reviewHotelBooking(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post('hotels/review', payload);
    final data = asJsonMap(readKey(json, 'data') ?? json);
    if (asString(readKey(data, 'bookingId')).isEmpty) {
      throw HoneymoonApiException(
        'This room is no longer available at that price. Please pick another.',
      );
    }
    return data;
  }

  /// `POST hotels/cancellation-policy`
  Future<Map<String, dynamic>> fetchHotelCancellationPolicy(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post('hotels/cancellation-policy', payload);
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `POST hotels/create-payment-order`
  Future<PaymentOrder> createHotelPaymentOrder(
    Map<String, dynamic> payload,
  ) async {
    final order = PaymentOrder.fromJson(
      await _post('hotels/create-payment-order', payload),
    );
    if (!order.isUsable) {
      throw HoneymoonApiException(
        'The payment could not be started. Please try again in a moment.',
      );
    }
    return order;
  }

  /// `POST hotels/verify-payment-and-book`
  Future<BookingOutcome> verifyHotelPaymentAndBook(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post('hotels/verify-payment-and-book', payload);
    final reference = firstNonEmpty([
      readKey(json, 'bookingId'),
      readKey(json, 'booking_id'),
      digPath(json, ['data', 'bookingId']),
    ]);

    if (reference.isEmpty) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback:
              'Your payment went through but the booking is still being '
              'confirmed. Check "My trips" in a few minutes.',
        ),
      );
    }

    return BookingOutcome(
      product: TravelProduct.hotel,
      reference: reference,
      status: firstNonEmpty([
        readKey(json, 'orderStatus'),
        readKey(json, 'status'),
      ], fallback: 'PAYMENT_SUCCESS'),
      amountPaid: asDouble(readKey(json, 'amount')),
      message: asString(readKey(json, 'message')),
      raw: asJsonMap(json),
    );
  }

  /// `GET hotels/all-bookings`
  Future<List<TravelBooking>> fetchHotelBookings() async {
    final json = await _get('hotels/all-bookings');
    return _unwrapList(json, const ['data', 'bookings', 'results'])
        .map(TravelBooking.fromHotelRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  /// `POST hotels/booking-details`
  Future<Map<String, dynamic>> fetchHotelBookingDetails(
    String bookingId,
  ) async {
    final json = await _post('hotels/booking-details', {
      'bookingId': bookingId,
    });
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `POST hotels/cancel-booking/:bookingId`
  Future<Map<String, dynamic>> cancelHotelBooking(String bookingId) async {
    final json = await _post(
      'hotels/cancel-booking/${Uri.encodeComponent(bookingId)}',
      const <String, dynamic>{},
    );
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  // ---------------------------------------------------------------------------
  // Cab booking — cabApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripjack-cabs/book` — creates the booking as payment-pending.
  Future<Map<String, dynamic>> createCabBooking(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post('tripjack-cabs/book', payload);
    _throwIfHandledFailure(json, 'Could not create the booking.');
    final data = asJsonMap(readKey(json, 'data') ?? json);
    if (asString(readKey(data, 'id')).isEmpty) {
      throw HoneymoonApiException(
        'The booking could not be created. Please try again.',
      );
    }
    return data;
  }

  /// `POST tripjack-cabs/payment/create-order`
  ///
  /// [amount] is what the traveller pays; [supplierAmount] is the quoted gross
  /// the supplier is owed. They are separate because settlement validates
  /// against the quote and rejects anything else.
  Future<PaymentOrder> createCabPaymentOrder({
    required String bookingId,
    required double amount,
    required double supplierAmount,
  }) async {
    final order = PaymentOrder.fromJson(
      await _post('tripjack-cabs/payment/create-order', {
        'bookingId': bookingId,
        'amount': amount,
        'supplierAmount': supplierAmount,
      }),
    );
    if (!order.isUsable) {
      throw HoneymoonApiException(
        'The payment could not be started. Please try again in a moment.',
      );
    }
    return order;
  }

  /// `POST tripjack-cabs/payment/verify`
  ///
  /// The backend settles with the supplier from the agent wallet after
  /// verifying, which is slow, so this call gets its own longer timeout.
  Future<BookingOutcome> verifyCabPayment(Map<String, dynamic> payload) async {
    final json = await _send(
      (h) => _client.post(
        _uri('tripjack-cabs/payment/verify'),
        headers: h,
        body: jsonEncode(payload),
      ),
      'POST tripjack-cabs/payment/verify',
      timeout: const Duration(seconds: 90),
    );

    return BookingOutcome(
      product: TravelProduct.cab,
      reference: firstNonEmpty([
        readKey(json, 'bookingId'),
        readKey(payload, 'bookingId'),
      ]),
      status: firstNonEmpty([readKey(json, 'status')], fallback: 'SUCCESS'),
      message: asString(readKey(json, 'message')),
      raw: asJsonMap(json),
    );
  }

  /// `GET tripjack-cabs/booking/details`
  Future<List<TravelBooking>> fetchCabBookings(List<String> bookingIds) async {
    final ids = bookingIds.where((id) => id.isNotEmpty).join(',');
    if (ids.isEmpty) return const [];
    final json = await _get('tripjack-cabs/booking/details', {
      'bookingIds': ids,
    });
    _throwIfHandledFailure(json, 'Could not fetch booking details.');
    return _unwrapList(json, const ['data', 'bookings'])
        .map(TravelBooking.fromCabEntry)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  /// `GET tripjack-cabs/invoices`
  ///
  /// AUDIT FIX: MIGRATION_NOTES.md previously claimed no cab-listing endpoint
  /// exists, since `cabApi.js` only exports the by-id lookup above. That was
  /// incomplete — the web client's booking dashboard (`useBookingData.js`)
  /// calls this endpoint directly via `axiosInstance`, bypassing `cabApi.js`
  /// entirely. Confirmed live against production (401 unauthenticated, not
  /// 404) before wiring this in.
  Future<List<TravelBooking>> fetchCabInvoices() async {
    final json = await _get('tripjack-cabs/invoices');
    _throwIfHandledFailure(json, 'Could not load your transfer bookings.');
    return _unwrapList(json, const ['invoices'])
        .map(TravelBooking.fromCabInvoiceRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Insurance booking — tripSafeApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripsafe/review` — confirms the premium and opens a booking id.
  ///
  /// Called unauthenticated to match the web client, which issues these with
  /// bare axios rather than through its interceptor.
  Future<({String bookingId, double price})> reviewInsurancePlan(
    InsurancePlan plan,
  ) async {
    final json = await _post('tripsafe/review', {
      'pli': [
        {
          'plid': plan.planId,
          'pi': [
            {'pid': plan.productId},
          ],
        },
      ],
    }, auth: false);

    _throwIfHandledFailure(json, 'This plan could not be confirmed.');

    final data = readKey(json, 'data') ?? json;
    final bookingId = firstNonEmpty([
      readKey(data, 'bid'),
      readKey(data, 'bookingId'),
    ]);

    if (bookingId.isEmpty) {
      throw HoneymoonApiException(
        'This plan could not be confirmed. Please pick another.',
      );
    }

    // Re-read the premium from the review — it is the authoritative one, and
    // it can differ from the search quote.
    final reviewed = InsurancePlan.fromSearchResponse(json)
        .where((p) => p.productId == plan.productId)
        .map((p) => p.price)
        .firstWhere((p) => p > 0, orElse: () => plan.price);

    return (bookingId: bookingId, price: reviewed);
  }

  /// `POST tripsafe/book`
  Future<BookingOutcome> bookInsurance(Map<String, dynamic> payload) async {
    final json = await _post('tripsafe/book', payload, auth: false);
    _throwIfHandledFailure(json, 'The policy could not be issued.');

    final data = readKey(json, 'data') ?? json;
    return BookingOutcome(
      product: TravelProduct.insurance,
      reference: firstNonEmpty([
        readKey(data, 'bookingId'),
        digPath(data, ['order', 'bookingId']),
        readKey(payload, 'bookingId'),
      ]),
      status: firstNonEmpty([
        digPath(data, ['order', 'status']),
        readKey(data, 'status'),
      ], fallback: 'CONFIRMED'),
      amountPaid: asDouble(digPath(data, ['order', 'amount'])),
      raw: asJsonMap(data),
    );
  }

  /// `POST tripsafe/booking-details`
  Future<Map<String, dynamic>> fetchInsuranceBookingDetails(
    String bookingId,
  ) async {
    final json = await _post('tripsafe/booking-details', {
      'bookingId': bookingId,
    }, auth: false);
    _throwIfHandledFailure(json, 'Could not load this policy.');
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// `GET /insurance_payment/bookings`
  Future<List<TravelBooking>> fetchInsuranceBookings() async {
    final json = await _get('insurance_payment/bookings');
    return _unwrapList(json, const ['data', 'bookings', 'results'])
        .map(TravelBooking.fromInsuranceRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Several of these endpoints report an upstream failure — an invalid key, a
  /// supplier outage — as HTTP 200 with a failure flag in the body. Without
  /// this check the caller reads a failure as an empty result and shows an
  /// "empty" state for what is actually an error: an airport picker that says
  /// "no airports found" while the supplier is down is actively misleading,
  /// because the traveller retypes instead of retrying.
  ///
  /// Two shapes are seen in the wild:
  ///   `{ status: false, message }`            our own backend
  ///   `{ status: { success: false }, ... }`   the supplier's error, passed
  ///                                           straight through (a Cloudflare
  ///                                           502 page arrives exactly here)
  static void _throwIfHandledFailure(dynamic json, String fallback) {
    if (json is! Map) return;

    final flag = json['success'] ?? json['status'];
    final nested = _digDynamic(json, ['status', 'success']);
    if (flag != false && nested != false) return;

    // An upstream 5xx is a "come back shortly", not something the traveller
    // can fix by editing their search — and the supplier's own error text is
    // a Cloudflare support page, which is no use to them.
    final upstreamCode = asInt(json['error_code'] ?? json['errorCode']);
    if (upstreamCode >= 500 || json['cloudflare_error'] == true) {
      throw HoneymoonApiException(
        'Our travel partner is busy right now. Please try again in a minute.',
        statusCode: upstreamCode == 0 ? null : upstreamCode,
      );
    }

    throw HoneymoonApiException(
      firstNonEmpty([
        json['message'],
        _digDynamic(json, ['details', 'message']),
      ], fallback: fallback),
    );
  }

  /// The API takes plain `yyyy-MM-dd`; UI-formatted dates never leave the UI.
  static String _apiDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static String _correlationId() =>
      'hw-${DateTime.now().millisecondsSinceEpoch}';

  /// Finds the first list-shaped value among [keys], tolerating both a bare
  /// list response and a `{ data: [...] }` envelope.
  static List<dynamic> _unwrapList(dynamic json, List<String> keys) {
    if (json is List) return json.where((e) => e != null).toList();
    if (json is! Map) return const [];

    for (final key in keys) {
      final v = json[key];
      if (v is List) return v.where((e) => e != null).toList();
      // One level deeper, e.g. { data: { hotels: [...] } }.
      if (v is Map) {
        for (final inner in keys) {
          final iv = v[inner];
          if (iv is List) return iv.where((e) => e != null).toList();
        }
      }
    }
    return const [];
  }

  static Object? _digDynamic(dynamic source, List<String> path) {
    dynamic current = source;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current;
  }

  static Object? _nameOf(dynamic v) =>
      v is Map ? (v['name'] ?? v['countryName'] ?? v['label']) : null;

  void dispose() => _client.close();
}