/// "Is there a newer build of this app in the store?" — resolved at runtime,
/// never hardcoded.
///
/// The installed version comes from the platform package metadata, so it
/// tracks `versionName`/`CFBundleShortVersionString` automatically. The store
/// version is read from the live listing on each check, so publishing
/// 1.0.21, 1.1.0 or 2.0.0 is picked up with no Flutter change — there is no
/// version literal anywhere in this file.
///
/// **Fail-open by design.** Every failure path — offline, timeout, store
/// markup changed, listing not found, unparseable version — returns
/// [UpdateStatus.unknown], which shows no popup. A version check that cannot
/// complete must never become a permanent wall between a user and the app;
/// the check simply runs again on the next resume or reconnect.
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'app_version.dart';

/// Master switch. Flip to false to ship a build that never blocks, without
/// unpicking the integration — the escape hatch if a store ever starts
/// reporting a bogus version and users get locked out.
const bool kMandatoryUpdateEnabled = true;

/// Storefront to query, as a two-letter country code.
///
/// Play and the App Store can stage a release per country; this app's
/// audience is India, and asking the wrong storefront is how a rolled-out
/// version appears missing.
const String kStoreCountry = 'in';

/// Numeric App Store id (the digits in `apps.apple.com/app/id123456789`).
///
/// Left null until the app is actually on the App Store: with it set, the
/// store page opens directly by id; without it, the lookup falls back to the
/// bundle identifier from the running binary.
const String? kAppStoreId = null;

class UpdateStatus {
  const UpdateStatus._({
    required this.updateRequired,
    this.installedVersion,
    this.storeVersion,
    this.storeUrl,
  });

  /// A newer version is live in the store.
  const UpdateStatus.required({
    required String installed,
    required String store,
    required String url,
  }) : this._(
          updateRequired: true,
          installedVersion: installed,
          storeVersion: store,
          storeUrl: url,
        );

  /// The app is current.
  const UpdateStatus.upToDate({
    String? installed,
    String? store,
  }) : this._(
          updateRequired: false,
          installedVersion: installed,
          storeVersion: store,
        );

  /// The check could not be completed. Treated exactly like [upToDate] by the
  /// UI — no popup — and retried later.
  const UpdateStatus.unknown() : this._(updateRequired: false);

  final bool updateRequired;
  final String? installedVersion;
  final String? storeVersion;
  final String? storeUrl;
}

class UpdateService {
  const UpdateService();

  /// How long to wait on a store listing before giving up. Short on purpose:
  /// this runs at startup and must not hold the app behind a slow network.
  static const Duration _timeout = Duration(seconds: 8);

  /// Resolves the installed and store versions and compares them.
  ///
  /// Never throws.
  Future<UpdateStatus> check({http.Client? client}) async {
    if (!kMandatoryUpdateEnabled) return const UpdateStatus.unknown();

    // The store listing only exists for the two mobile platforms.
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return const UpdateStatus.unknown();
    }

    final ownedClient = client == null;
    final httpClient = client ?? http.Client();

    try {
      final info = await PackageInfo.fromPlatform();
      final installed = info.version;
      final packageName = info.packageName;
      if (installed.isEmpty || packageName.isEmpty) {
        return const UpdateStatus.unknown();
      }

      final String? storeVersion;
      final String storeUrl;

      if (Platform.isAndroid) {
        storeVersion = await _playStoreVersion(httpClient, packageName);
        storeUrl = playStoreUrl(packageName);
      } else {
        storeVersion = await _appStoreVersion(httpClient, packageName);
        storeUrl = appStoreUrl(packageName);
      }

      if (storeVersion == null) {
        debugPrint('[UpdateService] store version unavailable — not blocking');
        return UpdateStatus.upToDate(installed: installed);
      }

      final needsUpdate = isUpdateRequired(
        installed: installed,
        store: storeVersion,
      );
      debugPrint(
        '[UpdateService] installed=$installed store=$storeVersion '
        'required=$needsUpdate',
      );

      if (!needsUpdate) {
        return UpdateStatus.upToDate(
          installed: installed,
          store: storeVersion,
        );
      }
      return UpdateStatus.required(
        installed: installed,
        store: storeVersion,
        url: storeUrl,
      );
    } catch (e) {
      // Offline, DNS failure, timeout, malformed body — all non-blocking.
      debugPrint('[UpdateService] check failed, not blocking: $e');
      return const UpdateStatus.unknown();
    } finally {
      if (ownedClient) httpClient.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Store lookups
  // ---------------------------------------------------------------------------

  /// The live version on the App Store, via Apple's public lookup service.
  ///
  /// Queries by bundle identifier so it follows the running binary rather
  /// than a constant. An unpublished or mis-configured bundle id returns
  /// `resultCount: 0`, which yields null — no popup.
  static Future<String?> _appStoreVersion(
    http.Client client,
    String bundleId,
  ) async {
    final uri = Uri.https('itunes.apple.com', '/lookup', {
      'bundleId': bundleId,
      'country': kStoreCountry,
      // Defeat Apple's edge cache, which can serve a stale version for hours
      // after a release goes live.
      't': DateTime.now().millisecondsSinceEpoch.toString(),
    });

    final response = await client.get(uri).timeout(_timeout);
    if (response.statusCode != 200) return null;

    final decoded = json.decode(response.body);
    if (decoded is! Map) return null;
    final results = decoded['results'];
    if (results is! List || results.isEmpty) return null;
    final first = results.first;
    if (first is! Map) return null;

    final version = first['version'];
    return version is String && version.trim().isNotEmpty ? version : null;
  }

  /// The live version on Google Play, read from the public listing.
  ///
  /// Play has no version API, so this parses the listing page. Google embeds
  /// the version in a JSON blob whose shape has changed more than once, so
  /// several known shapes are tried and anything unrecognised yields null
  /// rather than a guess. Listings that report "Varies with device" have no
  /// number to find and also yield null.
  ///
  /// This is the one genuinely brittle part of the feature: if Google changes
  /// the markup again, update checks silently stop (no popup) until the
  /// patterns are refreshed. See the note in the service docs about moving
  /// this to a backend-published version instead.
  static Future<String?> _playStoreVersion(
    http.Client client,
    String packageName,
  ) async {
    final uri = Uri.https('play.google.com', '/store/apps/details', {
      'id': packageName,
      'hl': 'en',
      'gl': kStoreCountry,
    });

    final response = await client.get(
      uri,
      // Without a desktop UA Play serves a trimmed page with no version data.
      headers: const {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0 Safari/537.36',
      },
    ).timeout(_timeout);

    if (response.statusCode != 200) return null;
    return parsePlayStoreVersion(response.body);
  }

  /// Extracts a version from Play listing HTML. Exposed for tests.
  @visibleForTesting
  static String? parsePlayStoreVersion(String html) {
    const patterns = <String>[
      // Current shape: the version sits alone in a nested array in the
      // AF_initDataCallback payload.
      r'\[\[\["(\d+(?:\.\d+)+)"\]\]',
      // Older listings exposed a labelled "Current Version" row.
      r'Current Version.{0,80}?>(\d+(?:\.\d+)+)<',
      // Seen on some locales: an explicit key in the embedded JSON.
      r'"softwareVersion"\s*:\s*"(\d+(?:\.\d+)+)"',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern, dotAll: true).firstMatch(html);
      final captured = match?.group(1);
      // Round-trip through the parser: only a value that reads as a real
      // version is trusted, so a stray number in the markup cannot lock
      // anyone out.
      if (AppVersion.tryParse(captured) != null) return captured;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Store URLs
  // ---------------------------------------------------------------------------

  /// Play listing for [packageName] — the app's own application id, so the
  /// link always points at this app.
  static String playStoreUrl(String packageName) =>
      'https://play.google.com/store/apps/details?id=$packageName';

  /// App Store listing, by numeric id when configured, otherwise a storefront
  /// search for the bundle identifier.
  static String appStoreUrl(String bundleId) {
    if (kAppStoreId != null && kAppStoreId!.isNotEmpty) {
      return 'https://apps.apple.com/$kStoreCountry/app/id$kAppStoreId';
    }
    return 'https://apps.apple.com/$kStoreCountry/search?term='
        '${Uri.encodeQueryComponent(bundleId)}';
  }
}
