import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../authservice.dart';
import '../config/api_config.dart';

/// Outcome of [WishlistStore.toggle].
class WishlistToggleResult {
  const WishlistToggleResult._({
    required this.success,
    this.added = false,
    this.message,
    this.sessionExpired = false,
  });

  final bool success;

  /// True when the vendor is now saved, false when it was removed. Only
  /// meaningful when [success] is true.
  final bool added;

  /// Server message for a failed request, if any.
  final String? message;

  /// The token was rejected (401); the session has already been ended.
  final bool sessionExpired;
}

/// The signed-in user's wishlist, shared by every heart/bookmark in the app.
///
/// Mirrors the website: the saved set comes from `GET /wishlist`
/// (`data[].vendor_services_id`), and a toggle is `POST /wishlist/toggle`
/// `{vendor_services_id}` with the Bearer token. The endpoint is a toggle, so
/// whether the vendor ended up saved is read from the response — it returns
/// `data` only when the item was added (`src/redux/authSlice.js`
/// `toggleWishlist`) — never guessed from local state. Before this store the
/// app kept three unrelated local sets that were never seeded from the server,
/// so a vendor saved on the website showed as unsaved and tapping it removed it
/// while the app said "Saved".
///
/// Cleared when the signed-in session ends; loaded again on sign-in.
class WishlistStore extends ChangeNotifier {
  WishlistStore._({http.Client? client}) : _client = client ?? http.Client() {
    AuthSession.instance.addListener(_onAuthChanged);
  }

  static final WishlistStore instance = WishlistStore._();

  /// A store with its own HTTP client, for tests.
  @visibleForTesting
  factory WishlistStore.forTesting(http.Client client) =>
      WishlistStore._(client: client);

  final http.Client _client;
  final Set<String> _ids = {};
  final Set<String> _pending = {};
  bool _loaded = false;
  Future<void>? _loading;

  bool get isLoaded => _loaded;

  /// Saved vendor-service ids.
  Set<String> get ids => Set.unmodifiable(_ids);

  int get count => _ids.length;

  bool contains(Object? vendorServiceId) =>
      vendorServiceId != null && _ids.contains(vendorServiceId.toString());

  /// True while a toggle for this id is in flight.
  bool isBusy(Object? vendorServiceId) =>
      vendorServiceId != null && _pending.contains(vendorServiceId.toString());

  void _onAuthChanged() {
    if (AuthSession.instance.isAuthenticated) {
      load(force: true);
    } else if (_ids.isNotEmpty || _loaded) {
      _ids.clear();
      _loaded = false;
      notifyListeners();
    }
  }

  /// Loads the saved set once per session; later calls reuse it unless
  /// [force] is set.
  Future<void> ensureLoaded() => load();

  Future<void> load({bool force = false}) {
    if (_loaded && !force) return Future.value();
    return _loading ??= _fetch().whenComplete(() => _loading = null);
  }

  Future<void> _fetch() async {
    final token = await _token();
    if (token == null) return;
    try {
      final res = await _client
          .get(
            Uri.parse('${ApiConfig.apiBase}/wishlist'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 25));
      if (res.statusCode == 401) {
        await AuthSession.instance.signOut();
        return;
      }
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body);
      final data = body is Map ? body['data'] : null;
      if (data is! List) return;
      _ids
        ..clear()
        ..addAll(parseIds(data));
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('WishlistStore load failed: $e');
    }
  }

  /// `vendor_services_id` of each `GET /wishlist` row.
  static Iterable<String> parseIds(List rows) sync* {
    for (final row in rows) {
      if (row is! Map) continue;
      final id = row['vendor_services_id'] ?? row['vendorServicesId'];
      if (id != null && id.toString().isNotEmpty) yield id.toString();
    }
  }

  /// Toggles [vendorServiceId]. The caller must have ensured the user is
  /// signed in (`requireAuthentication`). Updates optimistically and rolls
  /// back if the request fails.
  Future<WishlistToggleResult> toggle(Object vendorServiceId) async {
    final id = vendorServiceId.toString();
    final token = await _token();
    if (token == null) {
      return const WishlistToggleResult._(success: false);
    }
    if (_pending.contains(id)) {
      return const WishlistToggleResult._(success: false);
    }

    final wasSaved = _ids.contains(id);
    _pending.add(id);
    _set(id, !wasSaved);

    try {
      final res = await _client
          .post(
            Uri.parse('${ApiConfig.apiBase}/wishlist/toggle'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'vendor_services_id': int.tryParse(id) ?? id}),
          )
          .timeout(const Duration(seconds: 25));

      Map result = const {};
      try {
        final decoded = jsonDecode(res.body);
        if (decoded is Map) result = decoded;
      } catch (_) {}

      if (res.statusCode == 401) {
        _set(id, wasSaved);
        await AuthSession.instance.signOut();
        return const WishlistToggleResult._(
          success: false,
          sessionExpired: true,
        );
      }
      if (res.statusCode < 200 ||
          res.statusCode >= 300 ||
          result['success'] != true) {
        _set(id, wasSaved);
        return WishlistToggleResult._(
          success: false,
          message: result['message']?.toString(),
        );
      }
      final added = result['data'] != null;
      _set(id, added);
      return WishlistToggleResult._(success: true, added: added);
    } catch (e) {
      debugPrint('WishlistStore toggle failed: $e');
      _set(id, wasSaved);
      return const WishlistToggleResult._(success: false);
    } finally {
      _pending.remove(id);
      notifyListeners();
    }
  }

  void _set(String id, bool saved) {
    final changed = saved ? _ids.add(id) : _ids.remove(id);
    if (changed) notifyListeners();
  }

  Future<String?> _token() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.authTokenKey);
    return (token == null || token.trim().isEmpty) ? null : token;
  }

  /// Website copy for the failure toast (`showWishlistError`).
  static String failureMessage(WishlistToggleResult r) =>
      (r.message != null && r.message!.trim().isNotEmpty)
          ? r.message!
          : 'Could not update your wishlist. Please try again.';

  /// Website bubble copy (`WishlistBubble.jsx`).
  static String successMessage(bool added) =>
      added ? 'Added to wishlist' : 'Removed from wishlist';
}
