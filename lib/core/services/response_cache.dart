/// A small on-disk cache of API response bodies, for stale-while-revalidate:
/// a screen shows the last good answer immediately, then refreshes it.
///
/// Bodies go in the app's cache directory (the OS may clear it; that only
/// costs one slow load), one file per key. Entries older than [maxAge] are
/// ignored. Only public catalogue data should be cached here — never
/// anything user-specific or sensitive.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ResponseCache {
  const ResponseCache._();

  static const Duration maxAge = Duration(days: 3);

  static Future<File> _file(String key) async {
    final dir = await getApplicationCacheDirectory();
    // Keys are URLs; hash them into a safe file name.
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    final safe = name.length > 120 ? name.substring(name.length - 120) : name;
    return File('${dir.path}/rc_$safe.json');
  }

  /// The cached body for [key], or null when absent, expired or unreadable.
  static Future<String?> read(String key) async {
    try {
      final file = await _file(key);
      if (!await file.exists()) return null;
      final age = DateTime.now().difference(await file.lastModified());
      if (age > maxAge) return null;
      return await file.readAsString();
    } catch (e) {
      debugPrint('[ResponseCache] read failed for $key: $e');
      return null;
    }
  }

  static Future<void> write(String key, String body) async {
    try {
      final file = await _file(key);
      await file.writeAsString(body, flush: false);
    } catch (e) {
      debugPrint('[ResponseCache] write failed for $key: $e');
    }
  }
}
