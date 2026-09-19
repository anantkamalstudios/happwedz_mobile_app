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
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../authservice.dart';
import '../honeymoon_config.dart';
import '../models/addon_models.dart';
import '../models/booking_models.dart';
import '../models/cab_models.dart';
import '../models/flight_models.dart';
import '../models/honeymoon_models.dart';
import '../models/hotel_models.dart';
import '../models/insurance_models.dart';

/// A failure the UI can render without leaking internals.
class HoneymoonApiException implements Exception {
  HoneymoonApiException(
    this.message, {
    this.statusCode,
    this.data = const <String, dynamic>{},
    this.isTimeout = false,
  }) {
    // AUDIT FIX: `isUnauthorized` was defined but never read anywhere in the
    // app, so an expired/invalid token surfaced only as an inline error
    // message on whatever screen made the call — the user was never actually
    // signed out or returned to the login screen. Firing sign-out here, at
    // the one place every honeymoon API failure already flows through, makes
    // an expired session behave the same way everywhere in this module
    // without having to touch each of the ~30 call sites individually.
    //
    // BUG FIX: this must only fire on 401 (session actually invalid), not
    // 403. A 403 means "authenticated, but forbidden for this request" —
    // e.g. a booking permission/business-rule rejection — and says nothing
    // about session validity. Bundling it in here was blowing away a
    // perfectly valid app-wide session and booting an already-logged-in
    // user back to the login screen. The web client's axiosInstance
    // interceptor (`src (1)/src/services/api/axiosInstance.js`), which this
    // module otherwise mirrors, only signs out on 401 — never 403.
    if (statusCode == 401) {
      // ignore: discarded_futures
      AuthSession.instance.signOut();
    }
  }

  final String message;
  final int? statusCode;

  /// The decoded error body, when the server sent JSON.
  ///
  /// Most screens only need [message], but the hotel booking recovery paths
  /// branch on flags inside it — `duplicateBookingBlocked`,
  /// `paymentCaptured`, `source` — exactly as the web client does, and those
  /// are lost if only the message survives.
  final Map<String, dynamic> data;

  /// The request was sent but no answer came back in time. After a payment
  /// this does not mean the booking failed — the web treats it as "still
  /// confirming" rather than as an error.
  final bool isTimeout;

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
  ///
  /// DEBUG: logs the full request (url + body) and response (status + body)
  /// for every call, success or failure — this is the single chokepoint every
  /// honeymoon request flows through, so it's the one place to add this
  /// without touching each of the ~30 call sites.
  Future<dynamic> _send(
    Future<http.Response> Function(Map<String, String> headers) run,
    String label, {
    bool auth = true,
    Duration? timeout,
    Uri? uri,
    Object? requestBody,
    bool retryOnDroppedConnection = false,
  }) async {
    debugPrint('[HoneymoonApi] → $label');
    if (uri != null) debugPrint('[HoneymoonApi]   url: $uri');
    if (requestBody != null) {
      // Redacted: booking bodies carry passports, dates of birth and contact
      // details, which must never reach a log.
      debugPrint(
        '[HoneymoonApi]   request body: '
        '${jsonEncode(_redactForLog(requestBody))}',
      );
    }

    late final http.Response res;
    try {
      res = await run(
        await _headers(auth: auth),
      ).timeout(timeout ?? HoneymoonConfig.requestTimeout);
    } on TimeoutException {
      debugPrint('[HoneymoonApi] ← $label timed out');
      throw HoneymoonApiException(
        'That took too long. Please check your connection and try again.',
        isTimeout: true,
      );
    } on http.ClientException catch (e) {
      debugPrint('[HoneymoonApi] ← $label transport error: $e');
      // A pooled keep-alive connection the server already dropped fails with
      // "Connection closed before full header was received". For a read-only
      // request one immediate retry on a fresh connection is safe and almost
      // always succeeds; writes are never replayed.
      if (retryOnDroppedConnection && e.message.contains('Connection closed')) {
        debugPrint('[HoneymoonApi] ↻ retrying $label once');
        return _send(run, label, auth: auth, timeout: timeout, uri: uri);
      }
      throw HoneymoonApiException(
        "We couldn't reach our travel partner. Please check your connection.",
      );
    } catch (e) {
      debugPrint('[HoneymoonApi] ← $label transport error: $e');
      throw HoneymoonApiException(
        "We couldn't reach our travel partner. Please check your connection.",
      );
    }

    debugPrint('[HoneymoonApi] ← $label HTTP ${res.statusCode}');
    debugPrint('[HoneymoonApi]   response body: ${_safeLogBody(res.body)}');

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
      data: _decodeErrorBody(res.body),
    );
  }

  static Map<String, dynamic> _decodeErrorBody(String body) {
    try {
      return asJsonMap(jsonDecode(body));
    } catch (_) {
      return const <String, dynamic>{};
    }
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

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) {
    final uri = _uri(path, query);
    return _send(
      (h) => _client.get(uri, headers: h),
      'GET $path',
      uri: uri,
      retryOnDroppedConnection: true,
    );
  }

  Future<dynamic> _post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
    Duration? timeout,
  }) {
    final uri = _uri(path);
    return _send(
      (h) => _client.post(uri, headers: h, body: jsonEncode(body)),
      'POST $path',
      auth: auth,
      uri: uri,
      requestBody: body,
      timeout: timeout,
    );
  }

  /// Fetches a binary document (PDF voucher, receipt, policy) and saves it to
  /// a temporary file, returning the path.
  ///
  /// These endpoints answer with `application/pdf` on success but with a JSON
  /// error body on failure, so the content type decides which it is — parsing
  /// the bytes as a PDF regardless would save an error message as a .pdf and
  /// hand the user a file that will not open.
  Future<String> _download(String path, String filename) async {
    final uri = _uri(path);
    debugPrint('[HoneymoonApi] → GET $path');
    debugPrint('[HoneymoonApi]   url: $uri');

    late final http.Response res;
    try {
      final headers = await _headers();
      headers['Accept'] = 'application/pdf';
      res = await _client
          .get(uri, headers: headers)
          .timeout(HoneymoonConfig.requestTimeout);
    } on TimeoutException {
      debugPrint('[HoneymoonApi] ← GET $path timed out');
      throw HoneymoonApiException(
        'That took too long. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[HoneymoonApi] ← GET $path transport error: $e');
      throw HoneymoonApiException(
        "We couldn't reach our travel partner. Please check your connection.",
      );
    }

    final contentType = res.headers['content-type'] ?? '';
    debugPrint(
      '[HoneymoonApi] ← GET $path HTTP ${res.statusCode} ($contentType)',
    );
    if (res.statusCode < 200 ||
        res.statusCode >= 300 ||
        !contentType.contains('pdf')) {
      debugPrint('[HoneymoonApi]   response body: ${_safeLogBody(res.body)}');
      throw HoneymoonApiException(
        _extractMessage(res.body).isNotEmpty
            ? _extractMessage(res.body)
            : _messageForStatus(res.statusCode, res.body),
        statusCode: res.statusCode,
      );
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(res.bodyBytes, flush: true);
      return file.path;
    } catch (e) {
      debugPrint('[HoneymoonApi] could not save $filename: $e');
      throw HoneymoonApiException(
        "The document downloaded but couldn't be saved to this device.",
      );
    }
  }

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
        ])
        .map(HoneymoonDestination.fromCityRegion)
        .where((d) => d.displayName.isNotEmpty)
        .toList();
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
        ])
        .map(HoneymoonDestination.fromStaticHotel)
        .where((d) => d.displayName.isNotEmpty)
        .toList();
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

  /// `GET hotels/countries`, as the `{code, name}` pairs the search form's
  /// country picker needs. The web keys each country by its upper-cased
  /// `countryName` (`INDIA`) and shows its `label` (`India`).
  Future<List<({String code, String name})>> fetchHotelCountryOptions() async {
    const fallback = [(code: 'INDIA', name: 'India')];
    try {
      final json = await _get('hotels/countries');
      final list = _unwrapList(json, const ['countries', 'data'])
          .map((c) {
            final code = firstNonEmpty([
              readKey(c, 'countryName'),
              readKey(c, 'id'),
            ]).toUpperCase();
            final name = firstNonEmpty([
              readKey(c, 'label'),
              readKey(c, 'countryName'),
              readKey(c, 'id'),
            ]);
            return (code: code, name: name);
          })
          .where((c) => c.code.isNotEmpty)
          .toList();
      return list.isEmpty ? fallback : list;
    } on HoneymoonApiException {
      return fallback;
    }
  }

  /// `GET hotels/suggestions` — one ranked list of places *and* properties.
  ///
  /// This is the only autosuggest the web's `HotelSearchForm` calls; it
  /// replaced the separate `city-regions` + `static-hotels/search` pair, and
  /// its rows carry the region ids the search payload needs.
  Future<List<HoneymoonDestination>> suggestHotels(
    String keyword, {
    String country = 'INDIA',
    int limit = 20,
  }) async {
    if (keyword.trim().length < 2) return const [];
    final json = await _get('hotels/suggestions', {
      'keyword': keyword.trim(),
      'selectedCountry': country,
      'limit': limit,
    });

    final seen = <String>{};
    return _unwrapList(json, const ['suggestions', 'data', 'items', 'results'])
        .map(HoneymoonDestination.fromSuggestion)
        .where((d) => d.id.isNotEmpty && d.displayName.isNotEmpty)
        .where((d) => seen.add('${d.isHotel}|${d.id}'))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Hotels — hotelApi.js
  // ---------------------------------------------------------------------------

  /// The default `appliedFilters` block the web sends with every search
  /// (`defaultFilters()` in hotelbedsDetailHelpers.js). The backend reads the
  /// whole shape, so a partial block is not equivalent.
  static Map<String, dynamic> _defaultHotelFilters({
    List<String> ratings = const [],
  }) => <String, dynamic>{
    'hotelName': '',
    'ratings': ratings,
    'userRating': <String>[],
    'propertyType': <String>[],
    'mealType': <String>[],
    'cancellationPolicy': <String>[],
    'suppliers': <String>[],
    'amenities': <String>[],
    'brand': <String>[],
    'distance': <String>[],
    'popularPlaces': <String>[],
    'roomViews': <String>[],
    'priceRange': <String>[],
    'ramadanMeal': <String>[],
    'gstApplicable': <String>[],
    'onlyFavorites': false,
  };

  /// `POST hotels/search`. Payload mirrors HotelSearchForm.jsx exactly.
  ///
  /// BUG FIX: `searchCriteria.city` carried the city *name* ("GOA"); the web
  /// sends the region *id* (`699356`), and `searchType` was forced to `CITY`
  /// for every place where the web sends the suggestion's own region type
  /// (`PROVINCE_STATE`, `MULTI_CITY_VICINITY`…). Nationality, residence,
  /// country, star ratings and the GST claim now come from the form instead
  /// of being hard-coded, and paging reuses the search's correlation id.
  Future<HotelSearchResult> searchHotels(
    HotelSearchQuery query, {
    String sortOrder = 'popularity',
    int pageSize = 15,
    String lastHotelId = '',
    String searchId = '',
  }) async {
    final destination = query.destination;
    final isHotel = destination.isHotel;
    final tjids = isHotel && destination.hotelId.isNotEmpty
        ? [destination.hotelId]
        : <String>[];

    final payload = <String, dynamic>{
      'searchQuery': {
        'checkinDate': _apiDate(query.checkIn),
        'checkoutDate': _apiDate(query.checkOut),
        'roomInfo': query.rooms.map((r) => r.toRoomInfo()).toList(),
        'searchCriteria': {
          'city': tjids.isEmpty ? destination.city : '',
          'cityRegionIds': !isHotel && destination.id.isNotEmpty
              ? [destination.id]
              : <String>[],
          'regionIds': !isHotel && destination.id.isNotEmpty
              ? [destination.id]
              : <String>[],
          'countryName': query.countryName,
          'tjids': tjids,
          'nationality': query.nationality,
          'countryOfResidence': query.countryOfResidence,
          'currency': HoneymoonConfig.currency,
          'searchRegionName': destination.searchRegionName,
          'searchRegionType': destination.searchRegionType,
        },
        'searchType': destination.searchRegionType.isNotEmpty
            ? destination.searchRegionType
            : (isHotel ? 'HOTEL' : 'CITY'),
        'gstApplied': query.gstApplied,
      },
      'allOptions': true,
      'appliedFilters': _defaultHotelFilters(ratings: query.ratings),
      'pagination': {'pageSize': pageSize, 'lastHotelId': lastHotelId},
      'searchId': searchId,
      'correlationId': query.correlationId,
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
  ///
  /// Shape copied from `buildDetailPayload()` in `HotelbedsHotelsPage.jsx`:
  /// `searchRegionId` is the search's region id, `gstApplied` is always
  /// false there, and `userIntent` names the option, supplier and price the
  /// result card showed.
  Future<Map<String, dynamic>> fetchHotelDetail({
    required HotelResult hotel,
    required HotelSearchQuery query,
    String searchId = '',
  }) async {
    final destination = query.destination;
    final json = await _post('hotels/detail', {
      'correlationId': query.correlationId,
      'searchQuery': {
        'checkInDate': _apiDate(query.checkIn),
        'checkoutDate': _apiDate(query.checkOut),
        'roomInfo': query.rooms.map((r) => r.toRoomInfo()).toList(),
        'hotelSearchCriteria': {
          'nationality': query.nationality,
          'countryOfResidence': query.countryOfResidence,
          'currency': HoneymoonConfig.currency,
        },
        'searchPreferences': {
          'hids': [hotel.id],
        },
        'searchRegionId': destination.isHotel ? '' : destination.city,
        'searchRegionName': destination.searchRegionName,
        'searchRegionType': destination.searchRegionType.isNotEmpty
            ? destination.searchRegionType
            : 'CITY',
        'gstApplied': false,
        'isLimitOptionAllowed': true,
      },
      'searchId': searchId,
      'userIntent': {
        'optionId': hotel.optionId,
        'supplierName': hotel.supplierName,
        'price': hotel.price > 0 ? hotel.price.toString() : '',
      },
    });
    return json is Map<String, dynamic> ? json : <String, dynamic>{};
  }

  /// `POST hotels/static-content` — descriptions, images, policies, rooms.
  ///
  /// BUG FIX: the response is `{status, hotels: [...]}` and the page read
  /// `images`/`description`/`facilities` off the top level, where they never
  /// are — so no static content ever showed. It is parsed into
  /// [HotelStaticContent] here, from `hotels[]`, the way the web does.
  Future<HotelStaticContent> fetchHotelStaticContent({
    required String hotelId,
    String searchId = '',
  }) async {
    final json = await _post('hotels/static-content', {
      'tjHotelIds': [hotelId],
      if (searchId.isNotEmpty) 'searchId': searchId,
    });
    return HotelStaticContent.fromResponse(json, hotelId: hotelId);
  }

  // Previous versions, replaced by the HotelSearchQuery-based ones above.
  // /// `POST hotels/search`. Payload mirrors HotelSearchForm.jsx exactly.
  // Future<HotelSearchResult> searchHotels({
  //   required HoneymoonDestination destination,
  //   required DateTime checkIn,
  //   required DateTime checkOut,
  //   required List<RoomOccupancy> rooms,
  //   List<int> ratings = const [],
  //   String sortOrder = 'popularity',
  //   int pageSize = 15,
  //   String lastHotelId = '',
  //   String searchId = '',
  // }) async {
  //   final isHotel = destination.isHotel;
  //   final tjids = isHotel && destination.hotelId.isNotEmpty
  //       ? [destination.hotelId]
  //       : <String>[];
  //
  //   final payload = <String, dynamic>{
  //     'searchQuery': {
  //       'checkinDate': _apiDate(checkIn),
  //       'checkoutDate': _apiDate(checkOut),
  //       'roomInfo': rooms.map((r) => r.toRoomInfo()).toList(),
  //       'searchCriteria': {
  //         'city': tjids.isEmpty ? destination.city : '',
  //         'cityRegionIds': !isHotel && destination.id.isNotEmpty
  //             ? [destination.id]
  //             : <String>[],
  //         'regionIds': !isHotel && destination.id.isNotEmpty
  //             ? [destination.id]
  //             : <String>[],
  //         'countryName': destination.country.isNotEmpty
  //             ? destination.country
  //             : HoneymoonConfig.defaultCountryName,
  //         'tjids': tjids,
  //         'nationality': HoneymoonConfig.defaultNationality,
  //         'countryOfResidence': HoneymoonConfig.defaultCountryOfResidence,
  //         'currency': HoneymoonConfig.currency,
  //         'searchRegionName': destination.searchRegionName,
  //         'searchRegionType': destination.searchRegionType,
  //       },
  //       'searchType': isHotel ? 'HOTEL' : 'CITY',
  //       'gstApplied': false,
  //     },
  //     'allOptions': true,
  //     'appliedFilters': {
  //       'ratings': ratings,
  //       'onlyFavorites': false,
  //       'hotelName': '',
  //     },
  //     'pagination': {'pageSize': pageSize, 'lastHotelId': lastHotelId},
  //     'searchId': searchId,
  //     'correlationId': _correlationId(),
  //     'filterType': 'BOTH',
  //     'sortOrder': sortOrder,
  //   };
  //
  //   return HotelSearchResult.fromJson(await _post('hotels/search', payload));
  // }
  //
  // /// `POST hotels/filters` — the facets the backend can actually apply.
  // Future<Map<String, dynamic>> fetchHotelFilters({
  //   required String searchId,
  // }) async {
  //   final json = await _post('hotels/filters', {'searchId': searchId});
  //   return json is Map<String, dynamic> ? json : <String, dynamic>{};
  // }
  //
  // /// `POST hotels/detail` — room options and pricing for one property.
  // ///
  // /// BUG FIX: this used to send just `{hotelId, searchId, optionId}`, which
  // /// the backend rejects with `400 { error: "searchQuery.checkInDate is
  // /// required" }` — confirmed live. The web client never actually calls this
  // /// endpoint for honeymoon hotels (it reads the already-fetched search
  // /// result instead), so there was no working reference for the honeymoon
  // /// flow specifically; the shape below is copied from the *other* caller of
  // /// this same backend route, `buildDetailPayload()` in
  // /// `HotelbedsHotelsPage.jsx`, which mirrors the `hotels/search` payload
  // /// `searchHotels()` above already builds.
  // Future<Map<String, dynamic>> fetchHotelDetail({
  //   required String hotelId,
  //   required HoneymoonDestination destination,
  //   required DateTime checkIn,
  //   required DateTime checkOut,
  //   required List<RoomOccupancy> rooms,
  //   String searchId = '',
  //   String optionId = '',
  //   double price = 0,
  // }) async {
  //   final isHotel = destination.isHotel;
  //   final json = await _post('hotels/detail', {
  //     'correlationId': _correlationId(),
  //     'searchQuery': {
  //       'checkInDate': _apiDate(checkIn),
  //       'checkoutDate': _apiDate(checkOut),
  //       'roomInfo': rooms.map((r) => r.toRoomInfo()).toList(),
  //       'hotelSearchCriteria': {
  //         'nationality': HoneymoonConfig.defaultNationality,
  //         'countryOfResidence': HoneymoonConfig.defaultCountryOfResidence,
  //         'currency': HoneymoonConfig.currency,
  //       },
  //       'searchPreferences': {
  //         'hids': [hotelId],
  //       },
  //       'searchRegionId': isHotel ? '' : destination.city,
  //       'searchRegionName': destination.searchRegionName,
  //       'searchRegionType': destination.searchRegionType,
  //       'gstApplied': false,
  //       'isLimitOptionAllowed': true,
  //     },
  //     'searchId': searchId,
  //     'userIntent': {
  //       'optionId': optionId,
  //       'supplierName': '',
  //       if (price > 0) 'price': price.toStringAsFixed(0),
  //     },
  //   });
  //   return json is Map<String, dynamic> ? json : <String, dynamic>{};
  // }
  //
  // /// `POST hotels/static-content` — descriptions, images, amenities.
  // ///
  // /// BUG FIX: this used to send `{hotelId}`, which the backend rejects with
  // /// `400 { error: "tjHotelIds is required" }` — confirmed live. The web
  // /// client (`HotelbedsDetailsPage.jsx`) sends `tjHotelIds` as a list plus an
  // /// optional `searchId`.
  // Future<Map<String, dynamic>> fetchHotelStaticContent({
  //   required String hotelId,
  //   String searchId = '',
  // }) async {
  //   final json = await _post('hotels/static-content', {
  //     'tjHotelIds': [hotelId],
  //     if (searchId.isNotEmpty) 'searchId': searchId,
  //   });
  //   return json is Map<String, dynamic> ? json : <String, dynamic>{};
  // }

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
    ]).map(FlightLocation.fromJson).where((l) => l.code.isNotEmpty).toList();
  }

  /// `POST /tj/fms/search`. searchQuery built per utils/flightSearchUtils.js.
  ///
  /// BUG FIX: with "Non-stop flights only" off, the web does not run one
  /// search — it runs two in parallel, one with `isDirectFlight: true` and
  /// one with `isConnectingFlight: true`, and lists both
  /// (`FlightSearchForm.jsx` `runSearch`). The supplier returns only connecting
  /// itineraries for the second, so the single connecting-only search this
  /// used to send left every non-stop flight off the results. The two are
  /// settled independently, exactly like the web's `Promise.allSettled`: one
  /// failing still shows what the other found, and only both failing is an
  /// error.
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
    String paxType = 'REGULAR',
    List<String> preferredAirlines = const [],
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

    // `preferredAirline` is an array of { code }, capped at 10 by the supplier.
    final airlineCodes = preferredAirlines
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .take(10)
        .map((code) => {'code': code})
        .toList();

    Map<String, dynamic> queryFor({required bool direct}) => <String, dynamic>{
      'cabinClass': cabinClass.toUpperCase().replaceAll(RegExp(r'\s+'), '_'),
      'paxInfo': {
        'ADULT': '$adults',
        'CHILD': '$children',
        'INFANT': '$infants',
      },
      'routeInfos': routeInfos,
      'searchModifiers': {
        'isDirectFlight': direct,
        'isConnectingFlight': !direct,
        // TripJack puts the fare type inside searchModifiers, not at the root,
        // and only when it is not the default. REGULAR / STUDENT / SENIOR_CITIZEN.
        if (paxType.isNotEmpty && paxType.toUpperCase() != 'REGULAR')
          'pft': paxType.toUpperCase(),
      },
      if (airlineCodes.isNotEmpty) 'preferredAirline': airlineCodes,
    };

    // "Direct Flight" checked → only non-stop results, one search.
    if (directOnly) {
      return _runFlightSearch(queryFor(direct: true), 'search (direct only)');
    }

    final outcomes = await Future.wait([
      _settleSearch(
        _runFlightSearch(queryFor(direct: true), 'search (direct)'),
      ),
      _settleSearch(
        _runFlightSearch(queryFor(direct: false), 'search (connecting)'),
      ),
    ]);

    final found = [for (final o in outcomes) ?o.result];
    if (found.isEmpty) {
      final error = outcomes.first.error;
      if (error is HoneymoonApiException) throw error;
      throw HoneymoonApiException('Flight search is unavailable right now.');
    }

    // Direct first, then connecting — the order the web merges them in.
    return FlightSearchResult(
      onward: [for (final r in found) ...r.onward],
      inbound: [for (final r in found) ...r.inbound],
    );
  }

  /// One `tj/fms/search` call, logged in the flight debug format.
  Future<FlightSearchResult> _runFlightSearch(
    Map<String, dynamic> searchQuery,
    String action,
  ) async {
    final watch = Stopwatch()..start();
    try {
      final json = await _post('tj/fms/search', {'searchQuery': searchQuery});
      _throwIfHandledFailure(json, 'Flight search is unavailable right now.');
      final result = _extractFlights(json);
      _flightLog(
        action,
        endpoint: 'POST /tj/fms/search',
        request: {'searchQuery': searchQuery},
        result:
            'ONWARD ${result.onward.length} · RETURN ${result.inbound.length}',
        took: watch.elapsed,
      );
      return result;
    } catch (e) {
      _flightLog(
        action,
        endpoint: 'POST /tj/fms/search',
        request: {'searchQuery': searchQuery},
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  /// `Promise.allSettled` for one search: the result or the error, never a
  /// throw.
  static Future<({FlightSearchResult? result, Object? error})> _settleSearch(
    Future<FlightSearchResult> search,
  ) async {
    try {
      return (result: await search, error: null);
    } catch (e) {
      return (result: null, error: e);
    }
  }

  // Old single-search version, kept for reference. It sent one
  // `isConnectingFlight` search when "non-stop only" was off, which is why
  // non-stop flights were missing — see [searchFlights].
  // /// `POST /tj/fms/search`. searchQuery built per utils/flightSearchUtils.js.
  // Future<FlightSearchResult> searchFlights({
  //   required String fromCode,
  //   required String toCode,
  //   required DateTime departure,
  //   DateTime? returnDate,
  //   int adults = 2,
  //   int children = 0,
  //   int infants = 0,
  //   String cabinClass = 'ECONOMY',
  //   bool directOnly = false,
  //   String paxType = 'REGULAR',
  //   List<String> preferredAirlines = const [],
  // }) async {
  //   final routeInfos = <Map<String, dynamic>>[
  //     {
  //       'fromCityOrAirport': {'code': fromCode},
  //       'toCityOrAirport': {'code': toCode},
  //       'travelDate': _apiDate(departure),
  //     },
  //     if (returnDate != null)
  //       {
  //         'fromCityOrAirport': {'code': toCode},
  //         'toCityOrAirport': {'code': fromCode},
  //         'travelDate': _apiDate(returnDate),
  //       },
  //   ];
  //
  //   final searchQuery = <String, dynamic>{
  //     'cabinClass': cabinClass.toUpperCase().replaceAll(RegExp(r'\s+'), '_'),
  //     'paxInfo': {
  //       'ADULT': '$adults',
  //       'CHILD': '$children',
  //       'INFANT': '$infants',
  //     },
  //     'routeInfos': routeInfos,
  //     'searchModifiers': {
  //       'isDirectFlight': directOnly,
  //       'isConnectingFlight': !directOnly,
  //       // TripJack puts the fare type inside searchModifiers, not at the root,
  //       // and only when it is not the default. REGULAR / STUDENT / SENIOR_CITIZEN.
  //       if (paxType.isNotEmpty && paxType.toUpperCase() != 'REGULAR')
  //         'pft': paxType.toUpperCase(),
  //     },
  //   };
  //
  //   // `preferredAirline` is an array of { code }, capped at 10 by the supplier.
  //   final airlineCodes = preferredAirlines
  //       .map((c) => c.trim().toUpperCase())
  //       .where((c) => c.isNotEmpty)
  //       .take(10)
  //       .map((code) => {'code': code})
  //       .toList();
  //   if (airlineCodes.isNotEmpty) {
  //     searchQuery['preferredAirline'] = airlineCodes;
  //   }
  //
  //   final json = await _post('tj/fms/search', {'searchQuery': searchQuery});
  //   _throwIfHandledFailure(json, 'Flight search is unavailable right now.');
  //   return _extractFlights(json);
  // }

  /// `POST tj/fms/search` for a multi-city itinerary.
  ///
  /// Same endpoint as a one-way or return search — the only difference is that
  /// `routeInfos` carries one entry per leg. The supplier always treats these
  /// as connecting rather than direct, which is what the web client sends too.
  Future<MultiCitySearchResult> searchMultiCityFlights({
    required List<FlightLeg> legs,
    int adults = 1,
    int children = 0,
    int infants = 0,
    String cabinClass = 'ECONOMY',
    String paxType = 'REGULAR',
    List<String> preferredAirlines = const [],
  }) async {
    final searchQuery = <String, dynamic>{
      'cabinClass': cabinClass.toUpperCase().replaceAll(RegExp(r'\s+'), '_'),
      // The web's multi-city search sends these as numbers, unlike the
      // one-way/round builder which sends strings.
      'paxInfo': {'ADULT': adults, 'CHILD': children, 'INFANT': infants},
      'routeInfos': [for (final leg in legs) leg.toRouteInfo(_apiDate)],
      'searchModifiers': {
        'isDirectFlight': false,
        'isConnectingFlight': true,
        if (paxType.isNotEmpty && paxType.toUpperCase() != 'REGULAR')
          'pft': paxType.toUpperCase(),
      },
    };

    final airlineCodes = preferredAirlines
        .map((c) => c.trim().toUpperCase())
        .where((c) => c.isNotEmpty)
        .take(10)
        .map((code) => {'code': code})
        .toList();
    if (airlineCodes.isNotEmpty) {
      searchQuery['preferredAirline'] = airlineCodes;
    }

    final watch = Stopwatch()..start();
    try {
      final json = await _post('tj/fms/search', {'searchQuery': searchQuery});
      _throwIfHandledFailure(json, 'Flight search is unavailable right now.');
      final result = MultiCitySearchResult.fromJson(json, legs.length);
      _flightLog(
        'search (multi-city)',
        endpoint: 'POST /tj/fms/search',
        request: {'searchQuery': searchQuery},
        result: result.isCombo
            ? 'COMBO ${result.forRoute(0).length}'
            : [
                for (final r in result.bookableRoutes)
                  'route $r: ${result.forRoute(r).length}',
              ].join(' · '),
        took: watch.elapsed,
      );
      return result;
    } catch (e) {
      _flightLog(
        'search (multi-city)',
        endpoint: 'POST /tj/fms/search',
        request: {'searchQuery': searchQuery},
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
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

    List<FlightResult> parse(dynamic entry) => asList(
      entry,
    ).map(FlightResult.fromTripJack).where((f) => f.id.isNotEmpty).toList();

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

  /// `POST tripsafe/search` — or `tripsafe/search/embedded` when the cover
  /// is embedded in a flight booking — for any of the three plan types.
  ///
  /// The payload is built by [InsuranceSearchQuery.toPayload] exactly as
  /// `InsuranceSearchPanel.jsx` builds it. Failure handling follows
  /// `searchTripSafeInsurance`:
  ///   * `{status: false, message}` from our backend → that message;
  ///   * `data.status.success == false` from TripJack →
  ///     `"TripJack error: <httpStatus>"`.
  ///
  /// BUG FIX: only International was searchable, with invented region keys;
  /// plans without a price were dropped and the rest re-sorted. The web lists
  /// every package in the order the insurer returns them.
  ///
  /// Called without an Authorization header — the web uses bare axios here.
  Future<List<InsurancePlan>> searchInsurance(
    InsuranceSearchQuery query,
  ) async {
    final payload = query.toPayload();
    final path = query.isEmbedded
        ? 'tripsafe/search/embedded'
        : 'tripsafe/search';
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      // Supplier search is slow; the web's bare axios has no timeout at all.
      json = await _post(
        path,
        payload,
        auth: false,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _insuranceLog(path, request: payload, error: e, took: watch.elapsed);
      rethrow;
    }

    if (json is Map && json['status'] == false) {
      _insuranceLog(
        path,
        request: payload,
        response: json,
        took: watch.elapsed,
      );
      throw HoneymoonApiException(
        asString(json['message'], fallback: 'Insurance search failed'),
        data: asJsonMap(json),
      );
    }
    final tripjack = readKey(json, 'data') ?? json;
    final supplierStatus = readKey(tripjack, 'status');
    if (supplierStatus is Map && readKey(supplierStatus, 'success') != true) {
      _insuranceLog(
        path,
        request: payload,
        response: json,
        took: watch.elapsed,
      );
      final http = readKey(supplierStatus, 'httpStatus');
      throw HoneymoonApiException(
        http == null ? 'Insurance search failed' : 'TripJack error: $http',
        data: asJsonMap(json),
      );
    }

    final plans = InsurancePlan.fromSearchResponse(
      json,
      fallbackTravellerCount: query.travellerCount,
    ).where((p) => p.planId.isNotEmpty && p.productId.isNotEmpty).toList();
    _insuranceLog(
      path,
      request: payload,
      status: 200,
      summary: 'packages=${plans.length}',
      took: watch.elapsed,
    );
    return plans;
  }

  // Previous international-only search, kept for reference:
  // /// `POST tripsafe/search` for an international single trip. Payload shape
  // /// copied from InsuranceSearchPanel.jsx (the `isq` envelope).
  // Future<List<InsurancePlan>> searchInsurance({
  //   required String regionKey,
  //   required DateTime start,
  //   required DateTime end,
  //   required List<int> travellerAges,
  //   String regionType = 'COUNTRY',
  // }) async {
  //   final payload = <String, dynamic>{
  //     'isq': {
  //       'sd': _apiDate(start),
  //       'ed': _apiDate(end),
  //       'isc': {
  //         'iri': [
  //           {'rkey': regionKey, 'rt': regionType},
  //         ],
  //       },
  //       'iti': travellerAges.map((age) => {'age': age}).toList(),
  //       'isp': <String, dynamic>{},
  //     },
  //   };
  //
  //   // tripSafeApi.js calls this with bare axios, i.e. unauthenticated.
  //   final json = await _post('tripsafe/search', payload, auth: false);
  //
  //   // The service returns { status: false, message } for handled failures.
  //   if (json is Map && json['status'] == false) {
  //     throw HoneymoonApiException(
  //       asString(json['message'], fallback: 'Insurance search failed.'),
  //     );
  //   }
  //
  //   return InsurancePlan.fromSearchResponse(
  //       json,
  //     ).where((p) => p.isBookable).toList()
  //     ..sort((a, b) => a.price.compareTo(b.price));
  // }

  // ---------------------------------------------------------------------------
  // Car rental — cabApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripjack-cabs/search-locations` — Google Places autocomplete.
  ///
  /// Starts at two characters (`CabLocationField`). A `status:false` answer
  /// is an error, as `unwrap()` makes it on the web — it used to read as "no
  /// places".
  Future<List<Map<String, dynamic>>> searchCabLocations(String input) async {
    final query = input.trim();
    if (query.length < CabLimits.minLocationQuery) return const [];
    const path = 'tripjack-cabs/search-locations';
    final request = {'input': query};
    final dynamic json;
    try {
      json = await _post(path, request);
      _throwIfHandledFailure(json, 'Could not fetch locations');
    } catch (e) {
      _cabLog(path, request: request, error: e);
      rethrow;
    }
    final places =
        _digDynamic(json, ['data', 'places']) ?? _digDynamic(json, ['places']);
    final list = asList(
      places,
    ).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    _cabLog(path, request: request, summary: '${list.length} places');
    return list;
  }

  /// `POST tripjack-cabs/lat-long` — resolves a place id to coordinates.
  Future<Map<String, dynamic>> fetchCabPlaceDetails(String placeId) async {
    const path = 'tripjack-cabs/lat-long';
    final request = {'placeId': placeId};
    final dynamic json;
    try {
      json = await _post(path, request);
      _throwIfHandledFailure(json, 'Could not resolve this location');
    } catch (e) {
      _cabLog(path, request: request, error: e);
      rethrow;
    }
    _cabLog(path, request: request, response: json);
    final data = _digDynamic(json, ['data']) ?? json;
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  /// `POST tripjack-cabs/quotes` with the web's full search payload
  /// ([CabSearchQuery.toPayload]: journey type, one way / round trip,
  /// passengers and the quote filter).
  ///
  /// Returns the whole payload, not just the fares: `journeyInfo` and
  /// `routeDetails` are echoed back verbatim in the booking request, so
  /// discarding them here would make the quotes unbookable.
  Future<CabQuoteResult> searchCabQuotes(CabSearchQuery query) async {
    const path = 'tripjack-cabs/quotes';
    final request = query.toPayload();
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post(path, request);
      _throwIfHandledFailure(json, 'Could not fetch cab quotes');
    } catch (e) {
      _cabLog(path, request: request, error: e, took: watch.elapsed);
      rethrow;
    }
    final data = _digDynamic(json, ['data']) ?? json;
    final result = CabQuoteResult.fromJson(data);
    _cabLog(
      path,
      request: request,
      summary:
          '${result.quotes.length} quotes · '
          'journey=${asString(readKey(result.journeyInfo, 'journeyType'))}',
      took: watch.elapsed,
    );
    return result;
  }

  // Previous versions, kept for reference: search from three letters with
  // no failure check, and quotes hardwired to one-way airport transfers.
  // /// `POST tripjack-cabs/search-locations` — Google Places autocomplete.
  // Future<List<Map<String, dynamic>>> searchCabLocations(String input) async {
  //   if (input.trim().length < 3) return const [];
  //   final json = await _post('tripjack-cabs/search-locations', {
  //     'input': input.trim(),
  //   });
  //   final places =
  //       _digDynamic(json, ['data', 'places']) ?? _digDynamic(json, ['places']);
  //   return asList(
  //     places,
  //   ).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  // }
  //
  // /// `POST tripjack-cabs/lat-long` — resolves a place id to coordinates.
  // Future<Map<String, dynamic>> fetchCabPlaceDetails(String placeId) async {
  //   final json = await _post('tripjack-cabs/lat-long', {'placeId': placeId});
  //   final data = _digDynamic(json, ['data']) ?? json;
  //   return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  // }
  //
  // /// `POST tripjack-cabs/quotes`. Origin/destination nodes are built the same
  // /// way as buildCabLocationNode() in cabApi.js.
  // ///
  // /// Returns the whole payload, not just the fares: `journeyInfo` and
  // /// `routeDetails` are echoed back verbatim in the booking request, so
  // /// discarding them here would make the quotes unbookable.
  // Future<CabQuoteResult> fetchCabQuotes({
  //   required Map<String, dynamic> origin,
  //   required Map<String, dynamic> destination,
  //   required DateTime pickupAt,
  //   String journeyType = 'airport_transfer',
  //   String tripType = 'oneway',
  // }) async {
  //   final json = await _post('tripjack-cabs/quotes', {
  //     'journeyType': journeyType,
  //     'tripType': tripType,
  //     'origin': origin,
  //     'destination': destination,
  //     // BUG FIX: the backend expects `pickupDate` as a plain
  //     // "YYYY-MM-DD HH:mm" string (see CarRentalSearchForm.jsx's payload),
  //     // not `pickupDateTime` as an ISO8601 timestamp. The old key/format was
  //     // silently dropped, surfacing as "missing required field: pickupDate".
  //     'pickupDate': _apiDateTime(pickupAt),
  //   });
  //
  //   _throwIfHandledFailure(json, 'Could not fetch cab quotes.');
  //   final data = _digDynamic(json, ['data']) ?? json;
  //   return CabQuoteResult.fromJson(data);
  // }

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
        // Sent only when present, as `buildCabLocationNode` does.
        if (asString(address is Map ? address['subLocality'] : null).isNotEmpty)
          'subLocality': asString(
            address is Map ? address['subLocality'] : null,
          ),
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
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post('tj/fms/review', {'priceIds': ids});
    } catch (e) {
      _flightLog(
        'review',
        endpoint: 'POST /tj/fms/review',
        request: {'priceIds': ids},
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }

    final review = FlightReview.fromJson(json);
    final success =
        digPath(json, ['status', 'success']) ??
        digPath(json, ['data', 'status', 'success']);
    _flightLog(
      'review',
      endpoint: 'POST /tj/fms/review',
      request: {'priceIds': ids},
      result:
          'success=${success ?? '-'} · bookingId='
          '${review.bookingId.isEmpty ? '-' : review.bookingId} · '
          'total=${review.totalFare}',
      took: watch.elapsed,
    );

    // The web checks `status.success` first and shows the supplier's own
    // reason. The whole response rides along on the exception so the results
    // screen can tell a gone fare (errCode 1000) from any other refusal.
    if (success == false || !review.isUsable) {
      final errors = asList(readKey(json, 'errors'));
      throw HoneymoonApiException(
        firstNonEmpty([
          errors.isEmpty ? null : readKey(errors.first, 'message'),
          digPath(json, ['status', 'message']),
        ], fallback: 'That fare could not be confirmed. Please search again.'),
        data: asJsonMap(json),
      );
    }
    return review;
  }

  /// `POST tj/fms/seat` — the seat map for a priced itinerary, keyed by
  /// segment id.
  ///
  /// Seat selection is a convenience, never a blocker: a supplier that cannot
  /// serve a map (or an aircraft with no seat data) comes back as an empty
  /// map with [SeatMapResult.error] set, so the add-on step can say why
  /// instead of failing the booking.
  Future<SeatMapResult> fetchSeatMap(String bookingId) async {
    if (bookingId.isEmpty) {
      return const SeatMapResult(
        error: 'Seat selection is not available for this flight.',
      );
    }
    final watch = Stopwatch()..start();
    try {
      final json = asJsonMap(
        await _post('tj/fms/seat', {'bookingId': bookingId}),
      );
      _flightLog(
        'seat map',
        endpoint: 'POST /tj/fms/seat',
        request: {'bookingId': bookingId},
        result:
            'success=${digPath(json, ['status', 'success']) ?? '-'} · '
            'segments=${asJsonMap(digPath(json, ['tripSeatMap', 'tripSeat'])).length}',
        took: watch.elapsed,
      );
      if (digPath(json, ['status', 'success']) != true) {
        final errors = asList(readKey(json, 'errors'));
        final message = errors.isEmpty
            ? null
            : asString(readKey(errors.first, 'message'));
        return SeatMapResult(
          error: message == null || message.isEmpty
              ? 'Seat selection is not available for this flight.'
              : message,
        );
      }
      return SeatMapResult.fromJson(
        asJsonMap(digPath(json, ['tripSeatMap', 'tripSeat'])),
      );
    } catch (e) {
      _flightLog(
        'seat map',
        endpoint: 'POST /tj/fms/seat',
        request: {'bookingId': bookingId},
        error: e,
        took: watch.elapsed,
      );
      // TripJack refuses with HTTP 400 + `errors[0].message` when seats are
      // not sold for the itinerary (errCode 1056 "Seat Selection Not
      // Applicable for this Itinerary"). That is an answer, not a failure —
      // show it, as the web's success-false branch means to. Network errors
      // and timeouts keep the generic line.
      if (e is HoneymoonApiException && !e.isTimeout) {
        final errors = asList(readKey(e.data, 'errors'));
        final message = errors.isEmpty
            ? ''
            : asString(readKey(errors.first, 'message'));
        if (message.isNotEmpty) return SeatMapResult(error: message);
      }
      return const SeatMapResult(error: 'Could not load the seat map.');
    }
  }

  /// `POST tj/fms/farerule` — the cancellation and change rules behind a fare.
  Future<Map<String, dynamic>> fetchFareRule(String id, String flowType) async {
    return asJsonMap(
      await _post('tj/fms/farerule', {'id': id, 'flowType': flowType}),
    );
  }

  /// [fetchFareRule], parsed. [flowType] is `SEARCH` (a priceId from the
  /// results), `REVIEW` (the review's bookingId) or `BOOKING_DETAIL` (an
  /// order id) — the three places the web asks for rules.
  Future<FareRuleSet> fetchFareRules(String id, String flowType) async {
    final watch = Stopwatch()..start();
    final request = {'id': id, 'flowType': flowType};
    try {
      final rules = FareRuleSet.fromJson(
        await _post('tj/fms/farerule', request),
      );
      _flightLog(
        'fare rules ($flowType)',
        endpoint: 'POST /tj/fms/farerule',
        request: request,
        result: 'routes=${rules.routes.length}',
        took: watch.elapsed,
      );
      return rules;
    } catch (e) {
      _flightLog(
        'fare rules ($flowType)',
        endpoint: 'POST /tj/fms/farerule',
        request: request,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Flight debug logging
  // ---------------------------------------------------------------------------

  /// Keys whose values never reach a log: identity documents, dates of birth,
  /// contact details and payment secrets.
  static const Set<String> _sensitiveLogKeys = {
    'pNum',
    'dob',
    'eD',
    'pid',
    'di',
    'pan',
    'fFNumber',
    'emails',
    'contacts',
    'email',
    'phone',
    'mobile',
    'contact',
    'razorpay_signature',
    'razorpay_payment_id',
    'signature',
    'token',
    'accessToken',
    'refreshToken',
    'password',
    'cardNumber',
    'card',
    'cvv',
    'key_id',
    // Cab passenger and agent fields (`passengerDetail`, `agentEmail`…).
    'firstName',
    'lastName',
    'fullName',
    'passengerName',
    'agentEmail',
    'agentPhone',
    // Insurance traveller fields (`iti[]`, `deliveryInfo`).
    'eid',
    'cnum',
    'pnum',
    'pincode',
  };

  /// A response body fit for a log: JSON is redacted like a request; anything
  /// else (an HTML error page) is cut short.
  static String _safeLogBody(String body) {
    try {
      return jsonEncode(_redactForLog(jsonDecode(body)));
    } catch (_) {
      return body.length > 300 ? '${body.substring(0, 300)}…' : body;
    }
  }

  /// A copy of [value] with every sensitive key's value masked.
  static dynamic _redactForLog(dynamic value) {
    if (value is Map) {
      return {
        for (final e in value.entries)
          e.key: _sensitiveLogKeys.contains(e.key.toString())
              ? '<hidden>'
              : _redactForLog(e.value),
      };
    }
    if (value is List) return [for (final v in value) _redactForLog(v)];
    return value;
  }

  /// The insurance flow's debug block, in the requested format. Debug builds
  /// only; request and response bodies pass through [_redactForLog] (emails,
  /// mobiles, passport numbers are masked), and the auth header is never
  /// printed — most tripsafe calls send none, as on the web.
  void _insuranceLog(
    String api, {
    String method = 'POST',
    bool auth = false,
    Object? request,
    Object? response,
    int? status,
    String? summary,
    Object? error,
    Duration? took,
  }) {
    if (!kDebugMode) return;
    String clip(String s) => s.length > 1500 ? '${s.substring(0, 1500)}…' : s;
    final out = StringBuffer()
      ..writeln('========== INSURANCE API ==========')
      ..writeln('API: /$api')
      ..writeln('METHOD: $method');
    if (request != null) {
      out.writeln('REQUEST: ${clip(jsonEncode(_redactForLog(request)))}');
    }
    out.writeln(
      'HEADERS (hide secrets): '
      '${auth ? 'Authorization: Bearer <hidden>' : 'none (unauthenticated, as on the web)'}',
    );
    final responseStatus =
        status ??
        (error is HoneymoonApiException ? error.statusCode : null) ??
        (response != null ? 200 : null);
    if (responseStatus != null) out.writeln('RESPONSE STATUS: $responseStatus');
    if (response != null) {
      out.writeln('RESPONSE: ${clip(jsonEncode(_redactForLog(response)))}');
    } else if (summary != null) {
      out.writeln('RESPONSE: $summary');
    }
    if (error != null) {
      out.writeln(
        'ERROR: ${error is HoneymoonApiException ? error.message : error}',
      );
    }
    if (took != null) out.writeln('TIME: ${took.inMilliseconds} ms');
    out.write('===================================');
    debugPrint(out.toString());
  }

  /// The car-rental flow's debug block, in the requested format. Debug builds
  /// only; bodies pass through [_redactForLog] (names, email, phone, payment
  /// ids and signatures are masked) and the token is never printed. Every
  /// `tripjack-cabs` call is authenticated, as on the web (`axiosInstance`).
  void _cabLog(
    String api, {
    String method = 'POST',
    Object? request,
    Object? response,
    int? status,
    String? summary,
    Object? error,
    Duration? took,
  }) {
    if (!kDebugMode) return;
    String clip(String s) => s.length > 1500 ? '${s.substring(0, 1500)}…' : s;
    final out = StringBuffer()
      ..writeln('========== CAR RENTAL API ==========')
      ..writeln('API: /$api')
      ..writeln('METHOD: $method');
    if (request != null) {
      out.writeln('REQUEST: ${clip(jsonEncode(_redactForLog(request)))}');
    }
    out.writeln('HEADERS (hide secrets): Authorization: Bearer <hidden>');
    final responseStatus =
        status ??
        (error is HoneymoonApiException ? error.statusCode : null) ??
        (error == null ? 200 : null);
    if (responseStatus != null) out.writeln('RESPONSE STATUS: $responseStatus');
    if (response != null) {
      out.writeln('RESPONSE: ${clip(jsonEncode(_redactForLog(response)))}');
    } else if (summary != null) {
      out.writeln('RESPONSE: $summary');
    }
    if (error != null) {
      out.writeln(
        'ERROR: ${error is HoneymoonApiException ? error.message : error}',
      );
    }
    if (took != null) out.writeln('TIME: ${took.inMilliseconds} ms');
    out.write('=====================================');
    debugPrint(out.toString());
  }

  /// The flight flow's debug block. Debug builds only; the auth header is
  /// never printed and request bodies pass through [_redactForLog].
  void _flightLog(
    String action, {
    required String endpoint,
    Object? request,
    String? result,
    Object? error,
    Duration? took,
  }) {
    if (!kDebugMode) return;
    final out = StringBuffer()
      ..writeln('========== FLIGHT API ==========')
      ..writeln('ACTION   : $action')
      ..writeln('ENDPOINT : $endpoint')
      ..writeln('HEADERS  : Authorization: Bearer <hidden>');
    if (request != null) {
      out.writeln('REQUEST  : ${jsonEncode(_redactForLog(request))}');
    }
    if (result != null) out.writeln('RESULT   : $result');
    if (error != null) {
      final text = error is HoneymoonApiException
          ? '${error.statusCode ?? '-'} ${error.message}'
          : '$error';
      out.writeln('ERROR    : $text');
    }
    if (took != null) out.writeln('TIME     : ${took.inMilliseconds} ms');
    out.write('================================');
    debugPrint(out.toString());
  }

  /// `GET Flight_booking/travellers` — people this account has booked for
  /// before, to prefill the passenger form.
  ///
  /// Returns an empty list rather than throwing: a convenience lookup must
  /// never block a booking.
  Future<List<Map<String, dynamic>>> fetchSavedTravellers() async {
    try {
      final json = await _get('Flight_booking/travellers');
      final list = _unwrapList(json, const [
        'data',
        'travellers',
        'results',
      ]).map(asJsonMap).toList();
      _flightLog(
        'saved travellers',
        endpoint: 'GET /Flight_booking/travellers',
        result: 'count=${list.length}',
      );
      return list;
    } catch (e) {
      _flightLog(
        'saved travellers',
        endpoint: 'GET /Flight_booking/travellers',
        error: e,
      );
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
    final body = _flightPaymentBody(payload, includeOfferId: false);
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post('flight_payment/hold', body);
    } catch (e) {
      _flightLog(
        'hold (block)',
        endpoint: 'POST /flight_payment/hold',
        request: body,
        error: e,
        took: watch.elapsed,
      );
      if (e is HoneymoonApiException) {
        final message = asString(readKey(e.data, 'message'));
        if (message.isNotEmpty && e.statusCode != 401) {
          throw HoneymoonApiException(
            message,
            statusCode: e.statusCode,
            data: e.data,
          );
        }
      }
      rethrow;
    }

    final status = readKey(json, 'status');
    final reference = firstNonEmpty([
      readKey(json, 'held_booking_id'),
      readKey(json, 'order_id'),
      readKey(json, 'bookingId'),
    ]);
    _flightLog(
      'hold (block)',
      endpoint: 'POST /flight_payment/hold',
      request: body,
      result:
          'status=${status ?? '-'} · held_booking_id='
          '${reference.isEmpty ? '-' : reference}',
      took: watch.elapsed,
    );

    // BUG FIX: only an explicit `status: false` used to count as a refusal,
    // so a reply with no status at all was shown as a held booking. The web
    // (`BookingReview.jsx` `handleHold`) treats the hold as done only when
    // `status` is truthy, and shows the server's message otherwise.
    final ok =
        status == true ||
        (status is String && status.isNotEmpty && status != 'false') ||
        (status is num && status != 0);
    if (!ok) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback: 'Could not hold this fare. Please try again.',
        ),
        data: asJsonMap(json),
      );
    }
    return BookingOutcome(
      product: TravelProduct.flight,
      reference: reference,
      status: 'ON_HOLD',
      onHold: true,
      // Nothing is charged to block a fare.
      amountPaid: 0,
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
    final body = _flightPaymentBody(
      payload,
      includeOfferId: true,
      isHoldConfirm: isHoldConfirm,
    );
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post('flight_payment/create_order', body);
    } catch (e) {
      _flightLog(
        'create payment order',
        endpoint: 'POST /flight_payment/create_order',
        request: body,
        error: e,
        took: watch.elapsed,
      );
      // The web shows the endpoint's own message ("Failed to create payment
      // order" otherwise), which says what is actually wrong with the fare.
      if (e is HoneymoonApiException) {
        final message = asString(readKey(e.data, 'message'));
        if (message.isNotEmpty && e.statusCode != 401) {
          throw HoneymoonApiException(
            message,
            statusCode: e.statusCode,
            data: e.data,
          );
        }
      }
      rethrow;
    }

    final parsed = PaymentOrder.fromJson(json);

    // BUG FIX: Razorpay takes amounts in paise, but this endpoint answers
    // `amount` in rupees — the figure it was sent (e.g. 56338 for ₹56,338),
    // unlike the hotel endpoint, which answers in paise. Handed to checkout
    // as-is, a ₹56,338 order opened as ₹563.38 and the payment failed. When
    // the answer is the rupee amount requested, it is converted; an answer
    // already in paise (≈ ×100) is left alone.
    final requestedRupees = asDouble(body['amount']);
    final order =
        requestedRupees >= 1 &&
            parsed.amountInPaise > 0 &&
            (parsed.amountInPaise - requestedRupees).abs() < 1
        ? PaymentOrder(
            orderId: parsed.orderId,
            keyId: parsed.keyId,
            amountInPaise: (requestedRupees * 100).round(),
            currency: parsed.currency,
            description: parsed.description,
            raw: parsed.raw,
          )
        : parsed;
    if (!identical(order, parsed)) {
      debugPrint(
        '[HoneymoonApi] create_order answered amount in rupees '
        '(${parsed.amountInPaise}); using ${order.amountInPaise} paise',
      );
    }
    _flightLog(
      'create payment order',
      endpoint: 'POST /flight_payment/create_order',
      request: body,
      result:
          'razorpay_order_id=${order.orderId.isEmpty ? '-' : order.orderId} · '
          'amount(paise)=${order.amountInPaise} · currency=${order.currency}',
      took: watch.elapsed,
    );
    if (!order.isUsable) {
      throw HoneymoonApiException(
        'Payment order created but Razorpay credentials missing. Please '
        'contact support.',
      );
    }
    return order;
  }

  /// `POST /flight_payment/verify_and_book` — verifies the payment signature
  /// and issues the ticket. The one call that must never be retried blindly.
  Future<BookingOutcome> verifyAndBookFlight(
    Map<String, dynamic> payload,
  ) async {
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post('flight_payment/verify_and_book', payload);
    } catch (e) {
      _flightLog(
        'verify and book',
        endpoint: 'POST /flight_payment/verify_and_book',
        request: payload,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
    final reference = firstNonEmpty([
      readKey(json, 'order_id'),
      readKey(json, 'booking_id'),
      readKey(json, 'bookingId'),
    ]);
    _flightLog(
      'verify and book',
      endpoint: 'POST /flight_payment/verify_and_book',
      request: payload,
      result:
          'status=${readKey(json, 'status') ?? '-'} · order_id='
          '${reference.isEmpty ? '-' : reference}',
      took: watch.elapsed,
    );

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
    final watch = Stopwatch()..start();
    try {
      final json = await _get('tj/my-bookings');
      final rows = _unwrapList(json, const ['data', 'bookings', 'results'])
          .map(TravelBooking.fromFlightRow)
          .where((b) => b.reference.isNotEmpty)
          .toList();
      _flightLog(
        'my bookings',
        endpoint: 'GET /tj/my-bookings',
        result: 'count=${rows.length}',
        took: watch.elapsed,
      );
      return rows;
    } catch (e) {
      _flightLog(
        'my bookings',
        endpoint: 'GET /tj/my-bookings',
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  /// The answer as the web reads it (`response.data`): the fields sit at the
  /// root. A `data` envelope is only unwrapped when the root carries none of
  /// [rootKeys] — unwrapping blindly would lose a root that happens to have
  /// a `data` field of its own.
  static Map<String, dynamic> _rootOrData(dynamic json, List<String> rootKeys) {
    final root = asJsonMap(json);
    if (rootKeys.any(root.containsKey)) return root;
    final data = readKey(json, 'data');
    return data is Map ? asJsonMap(data) : root;
  }

  /// `POST /tj/oms/booking-details`
  Future<Map<String, dynamic>> fetchFlightBookingDetails(
    String bookingId,
  ) async {
    return (await fetchFlightBooking(bookingId)).raw;
  }

  /// [fetchFlightBookingDetails], parsed — the web's `adaptBookingDetails`.
  Future<FlightBookingDetails> fetchFlightBooking(String bookingId) async {
    final request = {'bookingId': bookingId, 'requirePaxPricing': true};
    final watch = Stopwatch()..start();
    try {
      final details = FlightBookingDetails(
        _rootOrData(await _post('tj/oms/booking-details', request), const [
          'order',
          'itemInfos',
        ]),
      );
      _flightLog(
        'booking details',
        endpoint: 'POST /tj/oms/booking-details',
        request: request,
        result:
            'status=${details.status.isEmpty ? '-' : details.status} · '
            'travellers=${details.travellers.length} · '
            'pnr=${FlightBookingDetails.hasPnrs(details.travellers) ? 'issued' : 'awaiting'}',
        took: watch.elapsed,
      );
      return details;
    } catch (e) {
      _flightLog(
        'booking details',
        endpoint: 'POST /tj/oms/booking-details',
        request: request,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  /// `POST /tj/oms/cancel-charges` — previews the refund. Does *not* cancel.
  Future<Map<String, dynamic>> fetchFlightCancelCharges(String orderId) async {
    return (await fetchFlightCancelQuote(orderId)).raw;
  }

  /// [fetchFlightCancelCharges], parsed.
  ///
  /// The booking-detail page asks with the order alone ("Get Cancel
  /// Quotation"); the cancellation flow also names the [trips] and
  /// travellers being cancelled and the reason, as the dashboard's modal
  /// does.
  Future<FlightCancelQuote> fetchFlightCancelQuote(
    String orderId, {
    String provider = 'tripjack',
    List<Map<String, dynamic>>? trips,
    String? remarks,
  }) async {
    final body = <String, dynamic>{
      'provider': provider.isEmpty ? 'tripjack' : provider,
      'order_id': orderId,
      'trips': ?trips,
      'remarks': ?remarks,
    };
    final watch = Stopwatch()..start();
    try {
      final quote = FlightCancelQuote(
        _rootOrData(await _post('tj/oms/cancel-charges', body), const [
          'available',
          'refund_amount',
          'amendment_charges',
          'status',
          'err_code',
        ]),
      );
      _flightLog(
        'cancel charges',
        endpoint: 'POST /tj/oms/cancel-charges',
        request: body,
        result:
            'available=${quote.available} · refund=${quote.refundAmount ?? '-'} '
            '· charges=${quote.amendmentCharges ?? '-'}',
        took: watch.elapsed,
      );
      return quote;
    } catch (e) {
      _flightLog(
        'cancel charges',
        endpoint: 'POST /tj/oms/cancel-charges',
        request: body,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  /// `POST /tj/oms/cancel` — raises the cancellation (an amendment).
  ///
  /// BUG FIX: this used to send the order alone, with no reason, and the
  /// caller then marked the booking cancelled on the spot. The web sends the
  /// chosen reason as `remarks` — plus, from the dashboard, the trips and
  /// travellers being cancelled and the previewed charges — and reads back an
  /// `amendment_id` whose status is then polled: a request is not a
  /// cancellation until the supplier says so. A reply without `status` is a
  /// refusal and throws with its message.
  Future<Map<String, dynamic>> cancelFlightBooking(
    String orderId, {
    String provider = 'tripjack',
    String? remarks,
    List<Map<String, dynamic>>? trips,
    Map<String, dynamic>? charges,
  }) async {
    final body = <String, dynamic>{
      'provider': provider.isEmpty ? 'tripjack' : provider,
      'order_id': orderId,
      'remarks': ?remarks,
      if (trips != null) ...{
        'trips': trips,
        'skipCharges': true,
        'charges': charges,
      },
    };
    final watch = Stopwatch()..start();
    final Map<String, dynamic> json;
    try {
      json = _rootOrData(await _post('tj/oms/cancel', body), const [
        'status',
        'amendment_id',
      ]);
    } catch (e) {
      _flightLog(
        'cancel',
        endpoint: 'POST /tj/oms/cancel',
        request: body,
        error: e,
        took: watch.elapsed,
      );
      if (e is HoneymoonApiException && e.statusCode != 401) {
        final message = asString(readKey(e.data, 'message'));
        if (message.isNotEmpty) {
          throw HoneymoonApiException(
            message,
            statusCode: e.statusCode,
            data: e.data,
          );
        }
      }
      rethrow;
    }
    _flightLog(
      'cancel',
      endpoint: 'POST /tj/oms/cancel',
      request: body,
      result:
          'status=${readKey(json, 'status') ?? '-'} · amendment_id='
          '${asString(readKey(json, 'amendment_id'), fallback: '-')} · '
          'amendment_status=${asString(readKey(json, 'amendment_status'), fallback: '-')}',
      took: watch.elapsed,
    );
    if (readKey(json, 'status') != true) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback: 'Cancellation failed. Please try again.',
        ),
        data: json,
      );
    }
    return json;
  }

  /// `POST /tj/oms/amendment/poll` — where a cancellation request stands.
  Future<FlightAmendment> pollFlightAmendment(String amendmentId) async {
    final request = {'amendmentId': amendmentId};
    final watch = Stopwatch()..start();
    try {
      final amendment = FlightAmendment(
        _rootOrData(await _post('tj/oms/amendment/poll', request), const [
          'amendmentId',
          'amendmentStatus',
        ]),
      );
      _flightLog(
        'amendment poll',
        endpoint: 'POST /tj/oms/amendment/poll',
        request: request,
        result:
            'status=${amendment.status.isEmpty ? '-' : amendment.status} · '
            'refundable=${amendment.refundableAmount ?? '-'}',
        took: watch.elapsed,
      );
      return amendment;
    } catch (e) {
      _flightLog(
        'amendment poll',
        endpoint: 'POST /tj/oms/amendment/poll',
        request: request,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
  }

  /// `POST /tj/oms/release-hold` — gives back a held fare that was not paid.
  ///
  /// The web shows the endpoint's message when `status` is not true, so a
  /// refused release is an error here rather than silently "released".
  Future<Map<String, dynamic>> releaseHeldFlight(String orderId) async {
    return _flightAction('release hold', 'tj/oms/release-hold', {
      'order_id': orderId,
    }, fallback: 'Could not release the hold.');
  }

  /// `POST /flight_payment/email-ticket`
  Future<Map<String, dynamic>> emailFlightTicket(String orderId) async {
    return _flightAction(
      'email ticket',
      'flight_payment/email-ticket',
      {'order_id': orderId},
      fallback: 'Could not send the ticket.',
    );
  }

  /// A `{status, message}` flight action: true status or an error carrying
  /// the endpoint's own message.
  Future<Map<String, dynamic>> _flightAction(
    String action,
    String path,
    Map<String, dynamic> body, {
    required String fallback,
  }) async {
    final watch = Stopwatch()..start();
    final Map<String, dynamic> json;
    try {
      json = asJsonMap(await _post(path, body));
    } catch (e) {
      _flightLog(action, endpoint: 'POST /$path', request: body, error: e);
      if (e is HoneymoonApiException && e.statusCode != 401) {
        final message = asString(readKey(e.data, 'message'));
        if (message.isNotEmpty) {
          throw HoneymoonApiException(
            message,
            statusCode: e.statusCode,
            data: e.data,
          );
        }
      }
      rethrow;
    }
    _flightLog(
      action,
      endpoint: 'POST /$path',
      request: body,
      result:
          'status=${readKey(json, 'status') ?? '-'} · '
          '${asString(readKey(json, 'message'))}',
      took: watch.elapsed,
    );
    if (readKey(json, 'status') != true) {
      throw HoneymoonApiException(
        asString(readKey(json, 'message'), fallback: fallback),
        data: json,
      );
    }
    return json;
  }

  /// `GET /flight_payment/invoice/:razorpayOrderId` — the payment invoice PDF
  /// (`InvoiceDownloadButton.jsx`, bookingType `flight`).
  Future<String> downloadFlightInvoice(
    String razorpayOrderId, {
    String invoiceNumber = '',
  }) {
    _flightLog(
      'invoice',
      endpoint: 'GET /flight_payment/invoice/$razorpayOrderId',
    );
    return _download(
      'flight_payment/invoice/${Uri.encodeComponent(razorpayOrderId)}',
      'FLIGHT_Invoice_${invoiceNumber.isEmpty ? razorpayOrderId : invoiceNumber}.pdf',
    );
  }

  // Previous post-booking calls, kept for reference:
  // /// `GET /tj/my-bookings`
  // Future<List<TravelBooking>> fetchFlightBookings() async {
  //   final json = await _get('tj/my-bookings');
  //   return _unwrapList(json, const ['data', 'bookings', 'results'])
  //       .map(TravelBooking.fromFlightRow)
  //       .where((b) => b.reference.isNotEmpty)
  //       .toList();
  // }
  //
  // /// `POST /tj/oms/booking-details`
  // Future<Map<String, dynamic>> fetchFlightBookingDetails(
  //   String bookingId,
  // ) async {
  //   final json = await _post('tj/oms/booking-details', {
  //     'bookingId': bookingId,
  //     'requirePaxPricing': true,
  //   });
  //   return asJsonMap(readKey(json, 'data') ?? json);
  // }
  //
  // /// `POST /tj/oms/cancel-charges` — previews the refund. Does *not* cancel.
  // Future<Map<String, dynamic>> fetchFlightCancelCharges(String orderId) async {
  //   final json = await _post('tj/oms/cancel-charges', {
  //     'provider': 'tripjack',
  //     'order_id': orderId,
  //   });
  //   return asJsonMap(readKey(json, 'data') ?? json);
  // }
  //
  // /// `POST /tj/oms/cancel`
  // Future<Map<String, dynamic>> cancelFlightBooking(String orderId) async {
  //   final json = await _post('tj/oms/cancel', {
  //     'provider': 'tripjack',
  //     'order_id': orderId,
  //   });
  //   return asJsonMap(readKey(json, 'data') ?? json);
  // }
  //
  // /// `POST /tj/oms/release-hold` — gives back a held fare that was not paid.
  // Future<void> releaseHeldFlight(String orderId) async {
  //   await _post('tj/oms/release-hold', {'order_id': orderId});
  // }
  //
  // /// `POST /flight_payment/email-ticket`
  // Future<void> emailFlightTicket(String orderId) async {
  //   await _post('flight_payment/email-ticket', {'order_id': orderId});
  // }

  // ---------------------------------------------------------------------------
  // Hotel booking — hotelApi.js
  // ---------------------------------------------------------------------------

  /// `POST hotels/review` — final price and booking requirements for the
  /// chosen room option, plus the `bookingId` the rest of the flow needs.
  ///
  /// The live answer is the supplier's raw shape — `{bookingId, hotelId,
  /// hotelName, option{pricing, compliance, cancellation, inclusions},
  /// onholdAllowed}` — parsed into [HotelReview].
  Future<HotelReview> reviewHotelBooking(Map<String, dynamic> payload) async {
    final json = await _post('hotels/review', payload);
    final data = asJsonMap(readKey(json, 'data') ?? json);
    if (asString(readKey(data, 'bookingId')).isEmpty) {
      throw HoneymoonApiException(
        'This room is no longer available at that price. Please pick another.',
      );
    }
    return HotelReview.fromJson(data);
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
  ///
  /// Two uses, as on the web: after Razorpay with `{bookingId,
  /// razorpay_order_id, razorpay_payment_id, razorpay_signature}`, and — when
  /// the payment is already captured and only the booking failed — a retry
  /// *without* paying again, with `{bookingId, roomTravellerInfo,
  /// deliveryInfo, ipr, ipm, type}`.
  ///
  /// BUG FIX: this used to return a confirmed [BookingOutcome] whenever the
  /// answer carried a `bookingId`. Supplier refusals carry one too
  /// (`success: false` / `tripjackRequestAccepted: false` /
  /// `status.success: false`), so a refused booking was shown as confirmed.
  /// The raw answer is now returned and the caller checks it with
  /// [isHotelSupplierDenial], then polls `hotels/booking-details` for the
  /// real outcome. Same 30 s timeout the web gives this call.
  Future<Map<String, dynamic>> verifyHotelPaymentAndBook(
    Map<String, dynamic> payload,
  ) async {
    final json = await _post(
      'hotels/verify-payment-and-book',
      payload,
      timeout: const Duration(seconds: 30),
    );
    return asJsonMap(json);
  }

  // Replaced by the raw-answer version above.
  // Future<BookingOutcome> verifyHotelPaymentAndBook(
  //   Map<String, dynamic> payload,
  // ) async {
  //   final json = await _post('hotels/verify-payment-and-book', payload);
  //   final reference = firstNonEmpty([
  //     readKey(json, 'bookingId'),
  //     readKey(json, 'booking_id'),
  //     digPath(json, ['data', 'bookingId']),
  //   ]);
  //
  //   if (reference.isEmpty) {
  //     throw HoneymoonApiException(
  //       asString(
  //         readKey(json, 'message'),
  //         fallback:
  //             'Your payment went through but the booking is still being '
  //             'confirmed. Check "My trips" in a few minutes.',
  //       ),
  //     );
  //   }
  //
  //   return BookingOutcome(
  //     product: TravelProduct.hotel,
  //     reference: reference,
  //     status: firstNonEmpty([
  //       readKey(json, 'orderStatus'),
  //       readKey(json, 'status'),
  //     ], fallback: 'PAYMENT_SUCCESS'),
  //     amountPaid: asDouble(readKey(json, 'amount')),
  //     message: asString(readKey(json, 'message')),
  //     raw: asJsonMap(json),
  //   );
  // }

  /// `POST hotels/hold` — blocks the room without payment. Same payload as
  /// the payment order, minus `paymentInfos`/`expectedAmount`.
  Future<Map<String, dynamic>> holdHotelBooking(
    Map<String, dynamic> payload,
  ) async {
    return asJsonMap(await _post('hotels/hold', payload));
  }

  /// `POST hotels/confirm-book` — pays for a held room:
  /// `{bookingId, paymentInfos, razorpay_order_id, razorpay_payment_id,
  /// razorpay_signature}`.
  Future<Map<String, dynamic>> confirmHotelBooking(
    Map<String, dynamic> payload,
  ) async {
    return asJsonMap(await _post('hotels/confirm-book', payload));
  }

  /// `GET hotels/all-bookings`, optionally filtered by status (`PENDING`,
  /// `SUCCESS`, `ON_HOLD`, `FAILED`, `CANCELLED`, `PAYMENT_PENDING`,
  /// `PAYMENT_FAILED`, `BOOK_FAILED_AFTER_PAYMENT`).
  Future<List<TravelBooking>> fetchHotelBookings({String status = ''}) async {
    final json = await _get(
      'hotels/all-bookings',
      status.isEmpty ? null : {'status': status},
    );
    return _unwrapList(json, const ['bookings', 'data', 'results'])
        .map(TravelBooking.fromHotelRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  /// `POST hotels/booking-details`
  ///
  /// BUG FIX: the web reads this answer as-is — `bookingStatusMeta`,
  /// `bookingDisplay` and `raw.itemInfos` all sit at its top level — but this
  /// unwrapped `data` first, which drops those keys whenever the envelope also
  /// carries a `data` field. The envelope is kept when it has them.
  Future<Map<String, dynamic>> fetchHotelBookingDetails(
    String bookingId,
  ) async {
    final json = await _post('hotels/booking-details', {
      'bookingId': bookingId,
    });
    final hasEnvelope = const [
      'bookingStatusMeta',
      'bookingDisplay',
      'orderStatus',
      'raw',
    ].any((key) => readKey(json, key) != null);
    if (hasEnvelope) return asJsonMap(json);
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// [fetchHotelBookingDetails], parsed.
  Future<HotelBookingStatus> fetchHotelBookingStatus(String bookingId) async {
    return HotelBookingStatus.fromJson(
      await fetchHotelBookingDetails(bookingId),
      fallbackBookingId: bookingId,
    );
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
    const path = 'tripjack-cabs/book';
    final dynamic json;
    try {
      json = await _post(path, payload);
      _throwIfHandledFailure(json, 'Could not create the booking.');
    } catch (e) {
      _cabLog(path, request: payload, error: e);
      rethrow;
    }
    _cabLog(path, request: payload, response: json);
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
    const path = 'tripjack-cabs/payment/create-order';
    final request = {
      'bookingId': bookingId,
      'amount': amount,
      'supplierAmount': supplierAmount,
    };
    final dynamic json;
    try {
      json = await _post(path, request);
    } catch (e) {
      _cabLog(path, request: request, error: e);
      rethrow;
    }
    _cabLog(path, request: request, response: json);
    // final order = PaymentOrder.fromJson(json);
    // The web reads `amount` as paise (`cabApi.js`). The flight endpoint
    // turned out to answer in rupees, so the same guard applies here: an
    // answer equal to the rupees requested is converted, one already in paise
    // (≈ ×100) is left alone.
    final parsed = PaymentOrder.fromJson(json);
    final order =
        amount >= 1 &&
            parsed.amountInPaise > 0 &&
            (parsed.amountInPaise - amount).abs() < 1
        ? PaymentOrder(
            orderId: parsed.orderId,
            keyId: parsed.keyId,
            amountInPaise: (amount * 100).round(),
            currency: parsed.currency,
            description: parsed.description,
            raw: parsed.raw,
          )
        : parsed;
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
    const path = 'tripjack-cabs/payment/verify';
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _send(
        (h) => _client.post(_uri(path), headers: h, body: jsonEncode(payload)),
        'POST $path',
        timeout: const Duration(seconds: 90),
      );
    } catch (e) {
      _cabLog(path, request: payload, error: e, took: watch.elapsed);
      rethrow;
    }
    _cabLog(path, request: payload, response: json, took: watch.elapsed);

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
    const path = 'tripjack-cabs/invoices';
    final dynamic json;
    try {
      json = await _get(path);
      _throwIfHandledFailure(json, 'Could not load your cab bookings.');
    } catch (e) {
      _cabLog(path, method: 'GET', error: e);
      rethrow;
    }
    final rows = _unwrapList(json, const ['invoices'])
        .map(TravelBooking.fromCabInvoiceRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
    _cabLog(path, method: 'GET', summary: '${rows.length} bookings');
    return rows;
  }

  /// `GET tripjack-cabs/booking/details?bookingIds=…`, read the way the web's
  /// `normalizeCabBookingDetail` reads it — what "Check payment status"
  /// reconciles against.
  Future<List<CabBookingDetail>> fetchCabBookingDetails(
    List<String> bookingIds,
  ) async {
    final ids = bookingIds.where((id) => id.isNotEmpty).join(',');
    if (ids.isEmpty) return const [];
    const path = 'tripjack-cabs/booking/details';
    final query = {'bookingIds': ids};
    final dynamic json;
    try {
      json = await _get(path, query);
      _throwIfHandledFailure(json, 'Could not fetch booking details');
    } catch (e) {
      _cabLog(path, method: 'GET', request: query, error: e);
      rethrow;
    }
    _cabLog(path, method: 'GET', request: query, response: json);
    return asList(readKey(json, 'data'))
        .map(CabBookingDetail.fromEntry)
        .where((d) => d.bookingId.isNotEmpty)
        .toList();
  }

  /// `GET tripjack-cabs/invoice/:id/details` — the dashboard's booking page
  /// (`CabBookingDetail.jsx`), by the invoice row's own `id`.
  Future<CabInvoiceDetail> fetchCabInvoiceDetail(String invoiceId) async {
    final path =
        'tripjack-cabs/invoice/${Uri.encodeComponent(invoiceId)}/details';
    final dynamic json;
    try {
      json = await _get(path);
    } catch (e) {
      _cabLog(path, method: 'GET', error: e);
      rethrow;
    }
    _cabLog(path, method: 'GET', response: json);
    final invoice = readKey(json, 'invoice');
    if (readKey(json, 'status') != true || invoice is! Map) {
      // The web's own message for a body without `status` + `invoice`.
      throw HoneymoonApiException('Invalid booking data received');
    }
    return CabInvoiceDetail.fromJson(invoice);
  }

  /// `GET tripjack-cabs/invoice/:orderId` — the invoice PDF, by the Razorpay
  /// order id (`InvoiceDownloadButton` with `bookingType="cabs"`).
  Future<String> downloadCabInvoice(String orderId, {String? invoiceNumber}) {
    final path = 'tripjack-cabs/invoice/${Uri.encodeComponent(orderId)}';
    _cabLog(path, method: 'GET', summary: 'PDF download');
    final name = invoiceNumber == null || invoiceNumber.isEmpty
        ? orderId
        : invoiceNumber;
    return _download(path, 'CABS_Invoice_$name.pdf');
  }

  // ---------------------------------------------------------------------------
  // Insurance booking — tripSafeApi.js
  // ---------------------------------------------------------------------------

  /// `POST tripsafe/review` — confirms the premium and opens a booking id
  /// (`reviewInsurancePlan` in tripSafeApi.js).
  ///
  /// BUG FIX: the reviewed premium was read from `isr.iinfo.pli` — the
  /// *search* path — and priced for one traveller, so it never applied. The
  /// review answers under `iinfo.pli`, and the web prices the matching
  /// product (else the first) for the party searched for.
  ///
  /// Called unauthenticated to match the web client.
  Future<({String bookingId, double price})> reviewInsurancePlan(
    InsurancePlan plan,
  ) async {
    final request = {
      'pli': [
        {
          'plid': plan.planId,
          'pi': [
            {'pid': plan.productId},
          ],
        },
      ],
    };
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      // json = await _post('tripsafe/review', request, auth: false);
      // Review re-prices with the insurer (no limit on the web); 60 s, as search.
      json = await _post(
        'tripsafe/review',
        request,
        auth: false,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _insuranceLog(
        'tripsafe/review',
        request: request,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
    _insuranceLog(
      'tripsafe/review',
      request: request,
      response: json,
      took: watch.elapsed,
    );

    _throwIfHandledFailure(json, 'Insurance review failed');

    final data = readKey(json, 'data') ?? json;
    final bookingId = firstNonEmpty([
      readKey(data, 'bid'),
      readKey(data, 'bookingId'),
    ]);
    if (bookingId.isEmpty) {
      throw HoneymoonApiException(
        asString(
          readKey(json, 'message'),
          fallback: 'Could not review plan. Try again.',
        ),
      );
    }

    double reviewed = 0;
    for (final p in asList(digPath(data, ['iinfo', 'pli']))) {
      final products = asList(readKey(p, 'pi'));
      if (products.isEmpty) continue;
      final match = products.firstWhere(
        (x) => asString(readKey(x, 'pid')) == plan.productId,
        orElse: () => products.first,
      );
      reviewed = InsurancePlan.priceFor(match, plan.travellerCount);
      break;
    }

    return (bookingId: bookingId, price: reviewed > 0 ? reviewed : plan.price);
  }

  // Previous review, kept for reference:
  // /// `POST tripsafe/review` — confirms the premium and opens a booking id.
  // ///
  // /// Called unauthenticated to match the web client, which issues these with
  // /// bare axios rather than through its interceptor.
  // Future<({String bookingId, double price})> reviewInsurancePlan(
  //   InsurancePlan plan,
  // ) async {
  //   final json = await _post('tripsafe/review', {
  //     'pli': [
  //       {
  //         'plid': plan.planId,
  //         'pi': [
  //           {'pid': plan.productId},
  //         ],
  //       },
  //     ],
  //   }, auth: false);
  //
  //   _throwIfHandledFailure(json, 'This plan could not be confirmed.');
  //
  //   final data = readKey(json, 'data') ?? json;
  //   final bookingId = firstNonEmpty([
  //     readKey(data, 'bid'),
  //     readKey(data, 'bookingId'),
  //   ]);
  //
  //   if (bookingId.isEmpty) {
  //     throw HoneymoonApiException(
  //       'This plan could not be confirmed. Please pick another.',
  //     );
  //   }
  //
  //   // Re-read the premium from the review — it is the authoritative one, and
  //   // it can differ from the search quote.
  //   final reviewed = InsurancePlan.fromSearchResponse(json)
  //       .where((p) => p.productId == plan.productId)
  //       .map((p) => p.price)
  //       .firstWhere((p) => p > 0, orElse: () => plan.price);
  //
  //   return (bookingId: bookingId, price: reviewed);
  // }

  /// `POST tripsafe/book`
  Future<BookingOutcome> bookInsurance(Map<String, dynamic> payload) async {
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      // json = await _post('tripsafe/book', payload, auth: false);
      // The web waits with no limit; issuing a policy can take the insurer a
      // while, and giving up at 30 s after the wallet was charged would invite
      // a second booking. Same 90 s the other booking confirmations use.
      json = await _post(
        'tripsafe/book',
        payload,
        auth: false,
        timeout: const Duration(seconds: 90),
      );
    } catch (e) {
      _insuranceLog(
        'tripsafe/book',
        request: payload,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
    _insuranceLog(
      'tripsafe/book',
      request: payload,
      response: json,
      took: watch.elapsed,
    );
    _throwIfHandledFailure(json, 'Booking failed');

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
    final request = {'bookingId': bookingId};
    final watch = Stopwatch()..start();
    final dynamic json;
    try {
      json = await _post('tripsafe/booking-details', request, auth: false);
    } catch (e) {
      _insuranceLog(
        'tripsafe/booking-details',
        request: request,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
    _insuranceLog(
      'tripsafe/booking-details',
      request: request,
      response: json,
      took: watch.elapsed,
    );
    _throwIfHandledFailure(json, 'Failed to load booking details');
    return asJsonMap(readKey(json, 'data') ?? json);
  }

  /// [fetchInsuranceBookingDetails], parsed — `getTripSafeBookingDetails`.
  Future<InsuranceBookingDetails> fetchInsuranceBooking(
    String bookingId,
  ) async {
    return InsuranceBookingDetails.fromJson(
      await fetchInsuranceBookingDetails(bookingId),
    );
  }

  /// `GET /insurance_payment/bookings`
  Future<List<TravelBooking>> fetchInsuranceBookings() async {
    final watch = Stopwatch()..start();
    try {
      final json = await _get('insurance_payment/bookings');
      final rows = _unwrapList(json, const ['bookings', 'data', 'results'])
          .map(TravelBooking.fromInsuranceRow)
          .where((b) => b.reference.isNotEmpty)
          .toList();
      _insuranceLog(
        'insurance_payment/bookings',
        method: 'GET',
        auth: true,
        status: 200,
        summary: 'bookings=${rows.length}',
        took: watch.elapsed,
      );
      return rows;
    } catch (e) {
      _insuranceLog(
        'insurance_payment/bookings',
        method: 'GET',
        auth: true,
        error: e,
        took: watch.elapsed,
      );
      rethrow;
    }
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

  // Unused since the cab search payload is built by
  // `CabSearchQuery.toPayload` (`cabApiDateTime`).
  // /// `yyyy-MM-dd HH:mm`, matching the web client's
  // /// `${pickupDate} ${pickupTime}` cab-quotes payload.
  // static String _apiDateTime(DateTime d) {
  //   final h = d.hour.toString().padLeft(2, '0');
  //   final min = d.minute.toString().padLeft(2, '0');
  //   return '${_apiDate(d)} $h:$min';
  // }

  // Unused since hotel calls share the search's own id
  // (`HotelSearchQuery.correlationId`), as the web's calls do.
  // static String _correlationId() =>
  //     'hw-${DateTime.now().millisecondsSinceEpoch}';

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

  // ---------------------------------------------------------------------------
  // Documents and post-booking actions
  //
  // These complete the set the web client exposes but the app had not yet
  // reached: hotel vouchers and receipts, the insurance policy PDF, the
  // insurance cancellation pair, and the two lookups the web booking screens
  // use to fill in payment details.
  // ---------------------------------------------------------------------------

  /// `GET hotels/:bookingId/voucher` — the stay voucher, saved to a temp file.
  Future<String> downloadHotelVoucher(String bookingId) => _download(
    'hotels/${Uri.encodeComponent(bookingId)}/voucher',
    'hotel-voucher-$bookingId.pdf',
  );

  /// `GET hotels/:bookingId/receipt` — the payment receipt.
  Future<String> downloadHotelReceipt(String bookingId) => _download(
    'hotels/${Uri.encodeComponent(bookingId)}/receipt',
    'hotel-receipt-$bookingId.pdf',
  );

  /// `GET insurance_payment/policy/:bookingId` — the issued policy document.
  Future<String> downloadInsurancePolicy(String bookingId) {
    _insuranceLog(
      'insurance_payment/policy/$bookingId',
      method: 'GET',
      auth: true,
      summary: 'PDF download',
    );
    return _download(
      'insurance_payment/policy/${Uri.encodeComponent(bookingId)}',
      'insurance-policy-$bookingId.pdf',
    );
  }

  /// `POST hotels/recent-bookings` — the few most recent stays, for the
  /// landing screen's "Recent bookings" strip.
  Future<List<TravelBooking>> fetchRecentHotelBookings({int limit = 3}) async {
    final json = await _post('hotels/recent-bookings', {'limit': limit});
    return _unwrapList(json, const ['bookings', 'data', 'results'])
        .map(TravelBooking.fromHotelRow)
        .where((b) => b.reference.isNotEmpty)
        .toList();
  }

  /// `GET tj/booking-record/:orderId` — our own record for a flight booking
  /// (booking date and the Razorpay payment), which the supplier's
  /// booking-details response does not carry.
  Future<Map<String, dynamic>> fetchFlightBookingRecord(String orderId) async {
    return (await fetchFlightRecord(orderId)).raw;
  }

  /// [fetchFlightBookingRecord], parsed. The web reads `status`, `booking`,
  /// `payment`, `contact`, `passengers` and `amendment_id` off the root.
  Future<FlightBookingRecord> fetchFlightRecord(String orderId) async {
    final path = 'tj/booking-record/${Uri.encodeComponent(orderId)}';
    final watch = Stopwatch()..start();
    try {
      final record = FlightBookingRecord(
        _rootOrData(await _get(path), const ['booking', 'payment', 'status']),
      );
      _flightLog(
        'booking record',
        endpoint: 'GET /$path',
        result:
            'booking_status=${record.bookingStatus.isEmpty ? '-' : record.bookingStatus} · '
            'payment=${record.payment == null ? '-' : asString(readKey(record.payment, 'payment_status'))} · '
            'amendment=${record.amendmentId.isEmpty ? '-' : record.amendmentId}',
        took: watch.elapsed,
      );
      return record;
    } catch (e) {
      _flightLog('booking record', endpoint: 'GET /$path', error: e);
      rethrow;
    }
  }

  /// `GET tripjack-cabs/payment/summary/:bookingId` — the amount actually due.
  /// For a round trip the summary also carries the paired booking ids.
  Future<Map<String, dynamic>> fetchCabPaymentSummary(String bookingId) async {
    final json = await _get(
      'tripjack-cabs/payment/summary/${Uri.encodeComponent(bookingId)}',
    );
    return asJsonMap(_digDynamic(json, ['data']) ?? json);
  }

  /// The `travellerKeys` block both insurance amendment calls expect:
  /// `{ <planId>: { <productId>: [{ id }] } }`.
  ///
  /// Passing no ids cancels the whole policy; passing a subset cancels only
  /// those travellers.
  static Map<String, dynamic> buildInsuranceCancellationPayload({
    required String bookingId,
    required String planId,
    required String productId,
    required List<String> travellerIds,
  }) => <String, dynamic>{
    'bookingId': bookingId,
    'type': 'CANCELLATION',
    'travellerKeys': {
      planId: {
        productId: [
          for (final id in travellerIds) {'id': int.tryParse(id) ?? id},
        ],
      },
    },
  };

  /// `POST tripsafe/amendment/raise` — step one of cancelling a policy.
  /// Returns the `amendmentId` the confirm step needs.
  ///
  /// Like the rest of tripsafe, this is called without an Authorization header
  /// to match the web client's bare-axios calls.
  Future<String> raiseInsuranceCancellation(
    Map<String, dynamic> payload,
  ) async {
    final dynamic json;
    try {
      json = await _post('tripsafe/amendment/raise', payload, auth: false);
    } catch (e) {
      _insuranceLog('tripsafe/amendment/raise', request: payload, error: e);
      rethrow;
    }
    _insuranceLog('tripsafe/amendment/raise', request: payload, response: json);
    _assertTripSafeOk(json, 'Failed to raise cancellation');

    final id = firstNonEmpty([
      _digDynamic(json, ['data', 'amendmentId']),
      _digDynamic(json, ['data', 'amendment', 'amendmentId']),
      _digDynamic(json, ['data', 'amendment', 'id']),
      _digDynamic(json, ['amendmentId']),
    ]);
    if (id.isEmpty) {
      throw HoneymoonApiException(
        'The insurer did not return a cancellation reference. Please try again.',
      );
    }
    return id;
  }

  /// `POST tripsafe/amendment/confirm-cancellation` — step two, which actually
  /// cancels. [amendmentId] comes from [raiseInsuranceCancellation].
  Future<Map<String, dynamic>> confirmInsuranceCancellation({
    required Map<String, dynamic> payload,
    required String amendmentId,
  }) async {
    final body = {...payload, 'amendmentId': amendmentId};
    final dynamic json;
    try {
      json = await _post(
        'tripsafe/amendment/confirm-cancellation',
        body,
        auth: false,
      );
    } catch (e) {
      _insuranceLog(
        'tripsafe/amendment/confirm-cancellation',
        request: body,
        error: e,
      );
      rethrow;
    }
    _insuranceLog(
      'tripsafe/amendment/confirm-cancellation',
      request: body,
      response: json,
    );
    _assertTripSafeOk(json, 'Failed to confirm cancellation');
    return asJsonMap(_digDynamic(json, ['data']) ?? json);
  }

  /// The tripsafe endpoints report failure as HTTP 200 with `status: false`,
  /// so a non-throwing response still has to be checked or the caller reads a
  /// refusal as success.
  static void _assertTripSafeOk(dynamic json, String fallback) {
    final ok = _digDynamic(json, ['status']) ?? _digDynamic(json, ['success']);
    if (ok == false) {
      final message = firstNonEmpty([
        _digDynamic(json, ['message']),
        _digDynamic(json, ['details', 'message']),
      ], fallback: fallback);
      throw HoneymoonApiException(message);
    }
  }

  void dispose() => _client.close();
}
