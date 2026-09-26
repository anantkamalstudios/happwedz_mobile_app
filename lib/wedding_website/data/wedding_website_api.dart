/// The only place in the Wedding Websites module that talks HTTP or touches
/// JSON. Screens never parse a response themselves.
///
/// Every endpoint here was taken from the existing web client:
///   `src/services/api/weddingWebsiteApi.js` — the 7 live endpoints below.
///   `src/components/pages/WeddingWebsiteForm.jsx` — the exact multipart
///     field names (`buildFormData`), including which JSON blob goes with
///     which repeated file field.
///
/// **Path prefix note (2026-09-18):** `weddingWebsiteApi.js` calls
/// `weddingwebsite/wedding-websites...`, but `MyWeddingWebsites.jsx` in the
/// same source tree calls raw `fetch('/api/wedding-websites'...)` — a
/// different, shorter prefix. Verified live against production before
/// picking one:
///   `GET https://api.happywedz.com/wedding-websites`              → 404 "Route not found"
///   `GET https://api.happywedz.com/weddingwebsite/wedding-websites` → 401 "No token provided" (route exists)
/// `weddingWebsiteApi.js`'s prefix is the real one; `MyWeddingWebsites.jsx`'s
/// raw `fetch` calls are stale in the source itself. This file uses the
/// working prefix for everything, including create/get/update/delete/publish;
/// only the public-view path breaks the `/wedding-websites` pattern (it is
/// `weddingwebsite/wedding/:websiteUrl`, per `viewPublicWebsite` in the
/// source), which is preserved here.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../models/wedding_website_models.dart';

/// A failure the UI can render without leaking internals.
class WeddingWebsiteApiException implements Exception {
  WeddingWebsiteApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Result of `POST wedding-websites/:id/publish`.
class WeddingWebsitePublishResult {
  const WeddingWebsitePublishResult({required this.websiteUrl, required this.publicUrl});

  /// The slug (`websiteUrl` on the record) used to build the public link.
  final String websiteUrl;

  /// The full link, e.g. `https://happywedz.com/wedding/<slug>`.
  final String publicUrl;
}

class WeddingWebsiteApi {
  WeddingWebsiteApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Plumbing
  // ---------------------------------------------------------------------------

  Uri _uri(String path) => Uri.parse('${ApiConfig.apiBase}/weddingwebsite/$path');

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.authTokenKey) ?? '';
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      debugPrint('[WeddingWebsiteApi] token read failed: $e');
    }
    return headers;
  }

  Future<String> _userId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getInt('user_id');
      if (id != null) return '$id';
      return prefs.getString('user_id') ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<dynamic> _decode(http.Response res, String label) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return Future.value(<String, dynamic>{});
      try {
        return Future.value(jsonDecode(res.body));
      } catch (e) {
        debugPrint('[WeddingWebsiteApi] $label decode error: $e');
        throw WeddingWebsiteApiException(
          'We received an unexpected response. Please try again.',
        );
      }
    }
    debugPrint('[WeddingWebsiteApi] $label HTTP ${res.statusCode}: ${res.body}');
    throw WeddingWebsiteApiException(
      _messageForStatus(res.statusCode, res.body),
      statusCode: res.statusCode,
    );
  }

  String _messageForStatus(int status, String body) {
    final detail = _extractMessage(body);
    switch (status) {
      case 401:
      case 403:
        return 'Please sign in to continue.';
      case 404:
        return 'This wedding website could not be found.';
      case 422:
        return detail.isNotEmpty && detail.length <= 160
            ? detail
            : 'Some of those details are not valid. Please review and try again.';
      default:
        if (status >= 500) {
          return 'Our server is busy right now. Please try again shortly.';
        }
        return detail.isNotEmpty && detail.length <= 160
            ? detail
            : 'Something went wrong. Please try again.';
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
      // Not JSON — fall through.
    }
    return '';
  }

  Future<http.Response> _run(
    Future<http.Response> Function() run,
    String label,
  ) async {
    try {
      return await run().timeout(_timeout);
    } on TimeoutException {
      throw WeddingWebsiteApiException(
        'That took too long. Please check your connection and try again.',
      );
    } catch (e) {
      debugPrint('[WeddingWebsiteApi] $label transport error: $e');
      throw WeddingWebsiteApiException(
        "We couldn't reach the server. Please check your connection.",
      );
    }
  }

  Future<dynamic> _get(String path) async {
    final res = await _run(
      () async => _client.get(_uri(path), headers: await _headers()),
      'GET $path',
    );
    return _decode(res, 'GET $path');
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    final res = await _run(
      () async => _client.post(
        _uri(path),
        headers: await _headers(),
        body: jsonEncode(body),
      ),
      'POST $path',
    );
    return _decode(res, 'POST $path');
  }

  Future<dynamic> _delete(String path) async {
    final res = await _run(
      () async => _client.delete(_uri(path), headers: await _headers()),
      'DELETE $path',
    );
    return _decode(res, 'DELETE $path');
  }

  /// Sends [fields] as plain text parts, [repeatedTextFields] as several text
  /// parts sharing the same field name (mirrors `formData.append(key, url)`
  /// called in a loop in `buildFormData`), and [fileFields] as file parts.
  Future<dynamic> _multipart(
    String method,
    String path, {
    required Map<String, String> fields,
    Map<String, List<String>> repeatedTextFields = const {},
    Map<String, List<File>> fileFields = const {},
  }) async {
    final res = await _run(() async {
      final request = http.MultipartRequest(method, _uri(path));
      final headers = await _headers(json: false);
      headers.remove('Content-Type'); // MultipartRequest sets its own.
      request.headers.addAll(headers);
      request.fields.addAll(fields);

      for (final entry in repeatedTextFields.entries) {
        for (final value in entry.value) {
          // No filename: a server reading multipart/form-data (multer,
          // busboy, …) treats a part without one as a plain field, exactly
          // like the browser's `FormData.append(key, aStringValue)` does.
          request.files.add(http.MultipartFile.fromString(entry.key, value));
        }
      }

      for (final entry in fileFields.entries) {
        for (final file in entry.value) {
          final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
          request.files.add(
            await http.MultipartFile.fromPath(
              entry.key,
              file.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      // `BaseRequest.send()` would spin up its own throwaway `Client()`,
      // bypassing the injected [_client] entirely — sending through
      // `_client.send` keeps this the module's one real HTTP boundary and
      // makes multipart calls mockable in tests, same as every GET/POST here.
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    }, '$method $path (multipart)');

    return _decode(res, '$method $path (multipart)');
  }

  // ---------------------------------------------------------------------------
  // The 7 endpoints — weddingWebsiteApi.js
  // ---------------------------------------------------------------------------

  /// `GET weddingwebsite/wedding-websites` — `getMyWebsites`.
  Future<List<WeddingWebsiteSummary>> fetchMyWebsites() async {
    final json = await _get('wedding-websites');
    final list = json is List
        ? json
        : (json is Map ? (json['data'] ?? json['websites'] ?? const []) : const []);
    return asList(list).map(WeddingWebsiteSummary.fromJson).toList();
  }

  /// `GET weddingwebsite/wedding-websites/:id` — `getWebsiteById`.
  Future<WeddingWebsiteDetail> fetchWebsite(String id) async {
    final json = await _get('wedding-websites/${Uri.encodeComponent(id)}');
    final data = json is Map && json['data'] is Map ? json['data'] : json;
    return WeddingWebsiteDetail.fromJson(data);
  }

  /// `POST weddingwebsite/wedding-websites` — `createWebsite`. Multipart;
  /// field names come straight from `buildFormData` in
  /// `WeddingWebsiteForm.jsx`.
  Future<String> createWebsite(WeddingWebsiteDraft draft) async {
    final built = await _buildMultipartParts(draft);
    final json = await _multipart(
      'POST',
      'wedding-websites',
      fields: built.fields,
      repeatedTextFields: built.repeatedTextFields,
      fileFields: built.fileFields,
    );
    return firstNonEmpty([
      json is Map ? json['id'] : null,
      json is Map ? json['_id'] : null,
    ]);
  }

  /// `PUT weddingwebsite/wedding-websites/:id` — `updateWebsite`.
  Future<void> updateWebsite(String id, WeddingWebsiteDraft draft) async {
    final built = await _buildMultipartParts(draft);
    await _multipart(
      'PUT',
      'wedding-websites/${Uri.encodeComponent(id)}',
      fields: built.fields,
      repeatedTextFields: built.repeatedTextFields,
      fileFields: built.fileFields,
    );
  }

  /// `DELETE weddingwebsite/wedding-websites/:id` — `deleteWebsite`.
  Future<void> deleteWebsite(String id) async {
    await _delete('wedding-websites/${Uri.encodeComponent(id)}');
  }

  /// `POST weddingwebsite/wedding-websites/:id/publish` — `publishWebsite`.
  ///
  /// The response has been seen carrying either `websiteUrl` directly or only
  /// `publicUrl` (`.../wedding/<slug>`), from which `WeddingWebsiteView.jsx`
  /// derives the slug with `publicUrl.split("/wedding/")[1]`. Both are
  /// handled here the same way.
  Future<WeddingWebsitePublishResult> publishWebsite(String id) async {
    final json = await _post('wedding-websites/${Uri.encodeComponent(id)}/publish', const {});
    final map = json is Map ? json : const {};
    final publicUrl = asString(map['publicUrl']);
    var slug = asString(map['websiteUrl']);
    if (slug.isEmpty && publicUrl.contains('/wedding/')) {
      slug = publicUrl.split('/wedding/').last;
    }
    return WeddingWebsitePublishResult(
      websiteUrl: slug,
      // AUDIT FIX: this passed the server's `publicUrl` through untouched,
      // and that value has been seen carrying the API host — producing
      // `https://api.happywedz.com/wedding/<slug>`, which answers "route not
      // found". The response is only trusted for the slug now; the host is
      // always this app's, so a shared link cannot inherit a wrong origin
      // from the backend.
      publicUrl: slug.isNotEmpty
          ? publicUrlFor(slug)
          : _withWebAppHost(publicUrl),
    );
  }

  /// Re-hosts an absolute URL onto [ApiConfig.webAppBaseUrl], keeping its
  /// path. Used only when no slug could be recovered.
  static String _withWebAppHost(String url) {
    if (url.isEmpty) return url;
    final parsed = Uri.tryParse(url);
    if (parsed == null || !parsed.hasAuthority) return url;
    final base = Uri.parse(ApiConfig.webAppBaseUrl);
    return parsed.replace(scheme: base.scheme, host: base.host, port: null).toString();
  }

  /// `GET weddingwebsite/wedding/:websiteUrl` — `viewPublicWebsite`. Public,
  /// no auth — the header is simply omitted when there is no stored token,
  /// same as every other public read in this app.
  Future<WeddingWebsiteDetail> fetchPublicWebsite(String websiteUrl) async {
    final res = await _run(
      () async => _client.get(
        _uri('wedding/${Uri.encodeComponent(websiteUrl)}'),
        headers: {'Accept': 'application/json'},
      ),
      'GET wedding/$websiteUrl',
    );
    final json = await _decode(res, 'GET wedding/$websiteUrl');
    final data = json is Map && json['data'] is Map ? json['data'] : json;
    return WeddingWebsiteDetail.fromJson(data);
  }

  /// `getPublicUrl` in `weddingWebsiteApi.js` — `${origin}/wedding/${slug}`,
  /// where `origin` is the **website's** origin, not the API's.
  ///
  /// AUDIT FIX: this used `ApiConfig.baseUrl`, so every shared link pointed
  /// at `https://api.happywedz.com/wedding/<slug>` — a JSON host with no such
  /// route, which answers "route not found". Anyone sent a wedding-website
  /// link from the app got an error page instead of the couple's site.
  /// Verified live: the API host 404s, `happywedz.com` returns 200.
  static String publicUrlFor(String websiteUrl) =>
      '${ApiConfig.webAppBaseUrl}/wedding/$websiteUrl';

  // ---------------------------------------------------------------------------
  // Multipart body builder — mirrors buildFormData() in WeddingWebsiteForm.jsx
  // ---------------------------------------------------------------------------

  Future<_MultipartParts> _buildMultipartParts(WeddingWebsiteDraft draft) async {
    final fields = <String, String>{
      'userId': await _userId(),
      'templateId': draft.template.id,
      'weddingDate': draft.weddingDate,
    };

    fields['brideData'] = jsonEncode(_personJson(draft.brideName, draft.brideDescription, draft.brideImage));
    fields['groomData'] = jsonEncode(_personJson(draft.groomName, draft.groomDescription, draft.groomImage));

    final loveStory = _reorderFilesFirst<LoveStoryDraft>(
      draft.loveStory,
      (e) => e.image.file,
      (e) => {
        'title': e.title,
        'description': e.description,
        'date': e.date,
        if (e.image.file == null && (e.image.existingUrl ?? '').isNotEmpty)
          'image_url': e.image.existingUrl,
      },
    );
    fields['loveStory'] = jsonEncode(loveStory.json);

    final weddingParty = _reorderFilesFirst<WeddingPartyDraft>(
      draft.weddingParty,
      (e) => e.image.file,
      (e) => {
        'name': e.name,
        'title': e.name,
        'relation': e.relation,
        'role': e.relation,
        if (e.image.file == null && (e.image.existingUrl ?? '').isNotEmpty)
          'image_url': e.image.existingUrl,
      },
    );
    fields['weddingParty'] = jsonEncode(weddingParty.json);

    final whenWhere = _reorderFilesFirst<WhenWhereDraft>(
      draft.whenWhere,
      (e) => e.image.file,
      (e) => {
        'title': e.title,
        'location': e.location,
        'description': e.description,
        'date': e.date,
        'time': e.time,
        if (e.image.file == null && (e.image.existingUrl ?? '').isNotEmpty)
          'image_url': e.image.existingUrl,
      },
    );
    fields['whenWhere'] = jsonEncode(whenWhere.json);

    // Existing gallery URLs travel as a JSON array; new gallery files go
    // under the `gallery` field, unordered (the source does not reorder
    // gallery/slider — only the indexed entry arrays above).
    fields['galleryImages'] = jsonEncode(
      draft.galleryImages
          .where((g) => g.file == null && (g.existingUrl ?? '').isNotEmpty)
          .map((g) => g.existingUrl)
          .toList(),
    );

    final repeatedTextFields = <String, List<String>>{
      // Existing slider URLs are preserved as repeated `sliderImages` parts,
      // exactly like `sliderImages.forEach(url => formData.append(...))`.
      'sliderImages': draft.sliderImages
          .where((s) => s.file == null && (s.existingUrl ?? '').isNotEmpty)
          .map((s) => s.existingUrl!)
          .toList(),
    };

    final fileFields = <String, List<File>>{
      'slider': draft.sliderImages.where((s) => s.file != null).map((s) => s.file!).toList(),
      'gallery': draft.galleryImages.where((g) => g.file != null).map((g) => g.file!).toList(),
      'loveStory': loveStory.files,
      'weddingParty': weddingParty.files,
      'whenWhere': whenWhere.files,
    };
    if (draft.brideImage.file != null) fileFields['bride'] = [draft.brideImage.file!];
    if (draft.groomImage.file != null) fileFields['groom'] = [draft.groomImage.file!];

    return _MultipartParts(
      fields: fields,
      repeatedTextFields: repeatedTextFields,
      fileFields: fileFields,
    );
  }

  Map<String, dynamic> _personJson(String name, String description, DraftImage image) => {
    'name': name,
    'title': name, // some backend revisions read `title` instead of `name`
    'description': description,
    if (image.file == null && (image.existingUrl ?? '').isNotEmpty) ...{
      'image': image.existingUrl,
      'image_url': image.existingUrl,
    },
  };

  /// Puts entries with a new file first, matching `reorderWithFilesFirst` in
  /// `WeddingWebsiteForm.jsx` — the comment there says this keeps an
  /// index-based backend's uploaded files aligned with the right JSON entry.
  _Reordered<T> _reorderFilesFirst<T>(
    List<T> items,
    File? Function(T) fileOf,
    Map<String, dynamic> Function(T) jsonOf,
  ) {
    final withFile = items.where((e) => fileOf(e) != null).toList();
    final withoutFile = items.where((e) => fileOf(e) == null).toList();
    return _Reordered(
      json: [...withFile.map(jsonOf), ...withoutFile.map(jsonOf)],
      files: withFile.map(fileOf).whereType<File>().toList(),
    );
  }

  void dispose() => _client.close();
}

class _MultipartParts {
  const _MultipartParts({
    required this.fields,
    required this.repeatedTextFields,
    required this.fileFields,
  });

  final Map<String, String> fields;
  final Map<String, List<String>> repeatedTextFields;
  final Map<String, List<File>> fileFields;
}

class _Reordered<T> {
  const _Reordered({required this.json, required this.files});

  final List<Map<String, dynamic>> json;
  final List<File> files;
}
