import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Prints every HTTP request and response made through `package:http`.
///
/// Installed app-wide from `main()` via [http.runWithClient], so top-level
/// `http.get/post/...`, every `http.Client()` and `MultipartRequest.send()`
/// all go through it without touching the call sites. Debug builds only.
class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient([http.Client? inner]) : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final started = DateTime.now();
    _printRequest(request);

    final http.StreamedResponse response;
    try {
      response = await _inner.send(request);
    } catch (e) {
      _print('❌ ${request.method} ${request.url}\n   ERROR: $e');
      rethrow;
    }

    // Buffer the body so it can be printed and still handed to the caller.
    final bytes = await response.stream.toBytes();
    final ms = DateTime.now().difference(started).inMilliseconds;
    final type = response.headers['content-type'] ?? '';

    _print(
      '⬅️ ${response.statusCode} ${request.method} ${request.url} (${ms}ms)\n'
      '${_bodyText(bytes, type)}',
    );

    return http.StreamedResponse(
      http.ByteStream.fromBytes(bytes),
      response.statusCode,
      contentLength: bytes.length,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();

  void _printRequest(http.BaseRequest request) {
    final buffer = StringBuffer('➡️ ${request.method} ${request.url}');
    if (request is http.Request && request.body.isNotEmpty) {
      buffer.write('\n   BODY: ${request.body}');
    } else if (request is http.MultipartRequest) {
      buffer.write('\n   FIELDS: ${request.fields}');
      buffer.write('\n   FILES: ${request.files.map((f) => '${f.field}=${f.filename}').toList()}');
    }
    _print(buffer.toString());
  }

  static String _bodyText(List<int> bytes, String contentType) {
    if (bytes.isEmpty) return '   <empty body>';
    final isText = contentType.isEmpty ||
        contentType.contains('json') ||
        contentType.contains('text') ||
        contentType.contains('xml') ||
        contentType.contains('javascript');
    if (!isText) return '   <$contentType, ${bytes.length} bytes>';
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(text));
    } catch (_) {
      return text;
    }
  }

  /// Logcat cuts long lines, so print in chunks.
  static void _print(String message) {
    const chunk = 800;
    for (var i = 0; i < message.length; i += chunk) {
      debugPrint(message.substring(
          i, i + chunk > message.length ? message.length : i + chunk));
    }
  }
}

/// Runs [body] with [LoggingHttpClient] as the default `package:http` client
/// in debug builds; in release it just runs [body].
R runWithHttpLogging<R>(R Function() body) {
  if (!kDebugMode) return body();
  return http.runWithClient(body, () => LoggingHttpClient(http.Client()));
}
