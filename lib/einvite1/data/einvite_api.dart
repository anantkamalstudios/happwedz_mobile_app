/// The e-invite endpoints for saving and reopening a customer's own cards.
///
/// Ported from the website's `einviteApi.js`, taking the **live production
/// bundle** as the source of truth where it differs from `src (1)` (the
/// snapshot is older: its `getUserEinvites` sends no auth header, which the
/// live site has since fixed).
///
/// Verified against production on 2026-09-21 before porting, so nothing here
/// is a guess:
///   `GET  einvites/cards/:idOrSlug`      → 200, templates *and* saved copies
///   `PUT  einvites/cards/:id/instance`   → 401 unauthenticated (route exists)
///   `GET  einvites/:userId/einvites`     → 401 unauthenticated (route exists)
///   `GET  einvites/cards/instances/:id`  → 404 "Route not found" — the web
///       tries this first and falls back to `cards/:id`, so only the fallback
///       is used here.
///   `GET  einvites/search`               → 404 — not ported.
/// `DELETE einvites/:id` is also not ported: the website never calls it (its
/// "delete" only clears local drafts) and it sends no auth header.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import 'einvite_design.dart';

/// Public page a guest opens from a shared invitation — the website's
/// `${origin}/einvites/view/:id`.
String einviteViewUrl(String id) =>
    'https://www.happywedz.com/einvites/view/${Uri.encodeComponent(id)}';

/// A failure the UI can show as-is.
class EinviteApiException implements Exception {
  EinviteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class EinviteApi {
  EinviteApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('${ApiConfig.apiBase}/einvites/$path');

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.authTokenKey) ?? '';
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      debugPrint('[EinviteApi] token read failed: $e');
    }
    return headers;
  }

  /// The signed-in user's id, or empty when there is none.
  Future<String> currentUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id != null) return '$id';
      return prefs.getString('user_id') ?? '';
    } catch (_) {
      return '';
    }
  }

  dynamic _decode(http.Response res, String fallback) {
    dynamic body;
    try {
      body = res.body.trim().isEmpty ? null : jsonDecode(res.body);
    } catch (_) {
      body = null;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    debugPrint('[EinviteApi] HTTP ${res.statusCode}: ${res.body}');
    throw EinviteApiException(
      _messageFor(res.statusCode, body, fallback),
      statusCode: res.statusCode,
    );
  }

  String _messageFor(int status, dynamic body, String fallback) {
    if (status == 401 || status == 403) {
      return 'Please sign in again to save your invitation.';
    }
    if (status >= 500) {
      return 'Our server is busy right now. Please try again shortly.';
    }
    // The web surfaces `body.message`; keep that, but never a wall of text.
    final message = body is Map ? body['message'] : null;
    if (message is String && message.isNotEmpty && message.length <= 160) {
      return message;
    }
    return fallback;
  }

  /// `created?.data || created` — the website accepts either envelope.
  Map<String, dynamic>? _unwrap(dynamic body) {
    if (body is Map) {
      final data = body['data'];
      if (data is Map) return Map<String, dynamic>.from(data);
      return Map<String, dynamic>.from(body);
    }
    return null;
  }

  Future<T> _guard<T>(Future<T> Function() run, String fallback) async {
    try {
      return await run();
    } on EinviteApiException {
      rethrow;
    } on TimeoutException {
      throw EinviteApiException(
        'This is taking too long. Check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[EinviteApi] $fallback: $e');
      throw EinviteApiException(
        'Could not reach HappyWedz. Check your connection and try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Endpoints
  // ---------------------------------------------------------------------------

  /// A template or a customer's saved copy — `getCard`.
  Future<Map<String, dynamic>> getCard(String idOrSlug) {
    return _guard(() async {
      final res = await _client
          .get(_uri('cards/${Uri.encodeComponent(idOrSlug)}'),
              headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      final body = _decode(res, 'Failed to load the invitation');
      final data = body is Map ? body['data'] : null;
      if (data is! Map) {
        throw EinviteApiException('This invitation could not be found.');
      }
      return Map<String, dynamic>.from(data);
    }, 'getCard');
  }

  /// Saves a first copy of a template as the customer's own card.
  ///
  /// Sends `ownerUserId` as the card editor on the website does (its newer
  /// video editor leaves it to the token; including it is harmless).
  Future<Map<String, dynamic>> createInstance({
    required String name,
    required List<EinvitePage> pages,
    required String originalTemplateId,
    required String ownerUserId,
  }) {
    return _guard(() async {
      final res = await _client
          .post(
            _uri('cards/instances'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name,
              'pages': pages.map((p) => p.toSaveJson()).toList(),
              'originalTemplateId': originalTemplateId,
              'ownerUserId': ownerUserId,
            }),
          )
          .timeout(_timeout);
      final saved = _unwrap(_decode(res, 'Failed to save your invitation.'));
      if (saved == null || saved['id'] == null) {
        throw EinviteApiException('Failed to save your invitation.');
      }
      return saved;
    }, 'createInstance');
  }

  /// Saves changes to a card the customer already owns.
  Future<Map<String, dynamic>> updateInstance(
    String id, {
    required String name,
    required List<EinvitePage> pages,
  }) {
    return _guard(() async {
      final res = await _client
          .put(
            _uri('cards/${Uri.encodeComponent(id)}/instance'),
            headers: await _headers(),
            body: jsonEncode({
              'name': name,
              'pages': pages.map((p) => p.toSaveJson()).toList(),
            }),
          )
          .timeout(_timeout);
      final saved = _unwrap(_decode(res, 'Failed to save your invitation.'));
      if (saved == null) {
        throw EinviteApiException('Failed to save your invitation.');
      }
      return saved;
    }, 'updateInstance');
  }

  /// The signed-in customer's saved cards — `getUserEinvites`.
  Future<List<Map<String, dynamic>>> getMyCards() {
    return _guard(() async {
      final userId = await currentUserId();
      if (userId.isEmpty) {
        throw EinviteApiException(
          'Please sign in to see your cards.',
          statusCode: 401,
        );
      }
      final res = await _client
          .get(_uri('${Uri.encodeComponent(userId)}/einvites'),
              headers: await _headers())
          .timeout(_timeout);
      final body = _decode(res, 'Failed to load your cards');

      // `Array.isArray(data) ? data : data?.data || []`
      final rows = body is List ? body : (body is Map ? body['data'] : null);
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((row) => Map<String, dynamic>.from(row))
          .toList();
    }, 'getMyCards');
  }
}
