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
  }) async {
    late final http.Response res;
    try {
      res = await run(
        await _headers(auth: auth),
      ).timeout(HoneymoonConfig.requestTimeout);
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
        return 'Some of those search details look off. Please review and try again.';
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
  Future<List<FlightLocation>> searchFlightLocations(String query) async {
    if (query.trim().length < 2) return const [];
    final json = await _get('tj/meta/locations', {'q': query.trim()});
    return _unwrapList(json, const ['locations', 'results', 'data', 'items'])
        .map(FlightLocation.fromJson)
        .where((l) => l.code.isNotEmpty)
        .toList();
  }

  /// `POST /tj/fms/search`. searchQuery built per utils/flightSearchUtils.js.
  Future<List<FlightResult>> searchFlights({
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
    return _extractFlights(json);
  }

  /// TripJack returns trips grouped under `searchResult.tripInfos.{ONWARD,…}`.
  List<FlightResult> _extractFlights(dynamic json) {
    final tripInfos =
        _digDynamic(json, ['searchResult', 'tripInfos']) ??
        _digDynamic(json, ['data', 'searchResult', 'tripInfos']) ??
        _digDynamic(json, ['tripInfos']);

    final out = <FlightResult>[];
    if (tripInfos is Map) {
      for (final entry in tripInfos.values) {
        for (final trip in asList(entry)) {
          final f = FlightResult.fromTripJack(trip);
          if (f.id.isNotEmpty) out.add(f);
        }
      }
    } else if (tripInfos is List) {
      for (final trip in tripInfos) {
        final f = FlightResult.fromTripJack(trip);
        if (f.id.isNotEmpty) out.add(f);
      }
    }
    return out;
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

    return _unwrapList(json, const ['data', 'plans', 'results'])
        .map(InsurancePlan.fromJson)
        .where((p) => p.name.isNotEmpty)
        .toList();
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
  Future<List<CabQuote>> fetchCabQuotes({
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

    final quotes =
        _digDynamic(json, ['data', 'quotesInfo']) ??
        _digDynamic(json, ['quotesInfo']);
    return asList(quotes).map(CabQuote.fromJson).where((q) => q.price > 0).toList();
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
  // Helpers
  // ---------------------------------------------------------------------------

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