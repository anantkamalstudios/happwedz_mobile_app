import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

/// Thrown when no auth token is stored, so the caller can route to login
/// instead of showing a generic failure.
class NotSignedInException implements Exception {
  const NotSignedInException();
}

/// The six lists behind My Bookings, mirroring the web's `useBookingData.js`.
///
/// The web groups them into three categories: Wedding Services is
/// [quotations] alone, Honeymoon Travel is [hotels]/[flights]/[cabs]/
/// [insurance], and Shop Orders is [orders].
enum BookingSource {
  quotations('Could not load your service bookings.'),
  hotels('Could not load your hotel bookings.'),
  flights('Could not load your flight bookings.'),
  cabs('Could not load your cab bookings.'),
  insurance('Could not load your insurance bookings.'),
  orders('Could not load your shop orders.');

  const BookingSource(this.errorMessage);

  /// Shown in the panel when this list fails, so one dead endpoint names
  /// itself instead of blanking the whole screen.
  final String errorMessage;
}

/// One list's state: rows, whether it is still loading, and its error.
@immutable
class BookingSlice {
  const BookingSlice({this.rows = const [], this.loading = true, this.error});

  final List<dynamic> rows;
  final bool loading;
  final String? error;

  /// A count is shown once the list has resolved. A list that failed stays
  /// blank rather than claiming zero.
  int? get count => loading || error != null ? null : rows.length;

  BookingSlice copyWith({
    List<dynamic>? rows,
    bool? loading,
    String? error,
    bool clearError = false,
  }) => BookingSlice(
    rows: rows ?? this.rows,
    loading: loading ?? this.loading,
    error: clearError ? null : (error ?? this.error),
  );
}

class BookingsApi {
  const BookingsApi._();

  static const Duration _timeout = Duration(seconds: 30);

  static Future<String> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.authTokenKey);
    if (token == null || token.isEmpty) throw const NotSignedInException();
    return token;
  }

  static Future<Map<String, dynamic>> _get(String path) async {
    final token = await _token();
    final res = await http
        .get(
          Uri.parse('${ApiConfig.apiBase}$path'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_timeout);

    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

    final decoded = jsonDecode(res.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  static List<dynamic> _list(Object? value) =>
      value is List ? value : const <dynamic>[];

  /// Vendor quotation requests — the Wedding Services category.
  ///
  /// Absolute in the web because `axiosInstance`'s baseURL points at the same
  /// host; here it goes through [ApiConfig.apiBase] like everything else.
  static Future<List<dynamic>> quotations() async {
    final data = await _get('/request-pricing/user/quotations');
    return data['success'] == true ? _list(data['quotations']) : const [];
  }

  static Future<List<dynamic>> hotels() async {
    final data = await _get('/hotels/all-bookings');
    return _list(data['bookings']);
  }

  static Future<List<dynamic>> flights() async {
    final data = await _get('/tj/my-bookings');
    return data['status'] == true ? _list(data['data']) : const [];
  }

  /// The cab list is served off the invoice endpoint, so rows arrive in
  /// invoice shape and get flattened into the booking shape the card expects.
  static Future<List<dynamic>> cabs() async {
    final data = await _get('/tripjack-cabs/invoices');
    if (data['status'] != true) return const [];
    return _list(data['invoices']).map(_fromInvoice).toList();
  }

  static Future<List<dynamic>> insurance() async {
    final data = await _get('/insurance_payment/bookings');
    return data['status'] == true ? _list(data['bookings']) : const [];
  }

  /// Orders placed on the store (store.happywedz.com), a separate service with
  /// its own MongoDB. The HappyWedz backend resolves which store customer this
  /// user is and reshapes the orders into rows before they get here, so this
  /// fetcher looks like the other five even though the data crossed a service
  /// and a database engine to arrive.
  ///
  /// A user who has never shopped comes back `{linked: false, orders: []}` —
  /// an empty panel, not an error.
  static Future<List<dynamic>> orders() async {
    final data = await _get('/store/orders/mine');
    return data['success'] == true ? _list(data['orders']) : const [];
  }

  static Map<String, dynamic> _fromInvoice(dynamic invoice) {
    final route = invoice['route']?.toString() ?? '';
    final parts = route.split(' → ');
    return {
      'id': invoice['id'],
      'tripjackBookingId': invoice['bookingId'],
      'razorpayOrderId': invoice['orderId'],
      'route': invoice['route'],
      'pickupLocation': parts.isNotEmpty && parts[0].isNotEmpty
          ? parts[0]
          : '—',
      'dropoffLocation': parts.length > 1 && parts[1].isNotEmpty
          ? parts[1]
          : '—',
      'pickupAt': invoice['pickupTime'],
      'amount': invoice['amount'],
      'currency': invoice['currency'],
      'paymentStatus': invoice['paymentStatus'],
      'bookingStatus': invoice['bookingStatus'],
      'passengerName': invoice['passengerName'],
      'createdAt': invoice['createdAt'],
    };
  }

  static Future<List<dynamic>> fetch(BookingSource source) => switch (source) {
    BookingSource.quotations => quotations(),
    BookingSource.hotels => hotels(),
    BookingSource.flights => flights(),
    BookingSource.cabs => cabs(),
    BookingSource.insurance => insurance(),
    BookingSource.orders => orders(),
  };
}

/// Loads all six booking lists once, in parallel.
///
/// Fetching deliberately does not live in each panel: the category tabs and
/// the travel rail show counts, so the data they count has to load with the
/// screen, not with the panel. Switching sub-tabs is then instant, and a panel
/// that failed can be retried on its own.
class BookingsController extends ChangeNotifier {
  final Map<BookingSource, BookingSlice> _slices = {
    for (final source in BookingSource.values) source: const BookingSlice(),
  };

  bool _disposed = false;

  /// True when no auth token was stored — the screen shows a sign-in prompt
  /// rather than six identical failures.
  bool signedOut = false;

  BookingSlice slice(BookingSource source) => _slices[source]!;

  Future<void> loadAll() =>
      Future.wait(BookingSource.values.map(load)).then((_) {});

  Future<void> load(BookingSource source) async {
    _slices[source] = _slices[source]!.copyWith(
      loading: true,
      clearError: true,
    );
    _notify();

    try {
      final rows = await BookingsApi.fetch(source);
      _slices[source] = BookingSlice(rows: rows, loading: false);
    } on NotSignedInException {
      signedOut = true;
      _slices[source] = const BookingSlice(loading: false, rows: []);
    } catch (e, stack) {
      debugPrint('${source.name} bookings fetch error: $e\n$stack');
      _slices[source] = BookingSlice(
        loading: false,
        error: source.errorMessage,
      );
    }
    _notify();
  }

  /// Optimistic in-place edit, so cancelling a quotation need not refetch.
  void update(
    BookingSource source,
    List<dynamic> Function(List<dynamic>) updater,
  ) {
    _slices[source] = _slices[source]!.copyWith(
      rows: updater(_slices[source]!.rows),
    );
    _notify();
  }

  /// Sum of several lists' counts, or null while any of them is unresolved —
  /// so a travel badge never shows a total that is missing a category.
  int? totalOf(Iterable<BookingSource> sources) {
    var sum = 0;
    for (final source in sources) {
      final count = slice(source).count;
      if (count == null) return null;
      sum += count;
    }
    return sum;
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
