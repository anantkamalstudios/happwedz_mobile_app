/// Detects the user's city from the device's approximate location.
///
/// ```
/// permission (coarse)  →  last known position (instant)
///                          else a fresh low-accuracy fix (≤ 8 s)
///                      →  reverse geocode  →  locality
///                      →  the spelling the HappyWedz catalogue uses
/// ```
///
/// Approximate accuracy is enough for a city and is quicker and lighter on
/// the battery than a GPS fix. Every failure — location off, permission
/// refused, no fix, no address — returns null, so a caller can always fall
/// back to the city it already had.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Why detection returned no city, so the UI can say something useful.
enum CityDetectFailure { serviceOff, denied, deniedForever, noFix, noAddress }

class CityDetectResult {
  const CityDetectResult.found(String this.city) : failure = null;
  const CityDetectResult.failed(CityDetectFailure this.failure) : city = null;

  final String? city;
  final CityDetectFailure? failure;

  bool get ok => city != null;
}

class CityLocator {
  const CityLocator._();

  /// Names reverse geocoding returns that the catalogue spells differently.
  /// Checked live against `vendor-services?city=…`: an unknown spelling
  /// silently falls back to the nationwide list, so these must map.
  static const Map<String, String> _catalogueSpelling = {
    'new delhi': 'Delhi',
    'delhi': 'Delhi',
    'bangalore': 'Bengaluru',
    'bengaluru': 'Bengaluru',
    'bombay': 'Mumbai',
    'mumbai': 'Mumbai',
    'gurgaon': 'Gurugram',
    'calcutta': 'Kolkata',
    'madras': 'Chennai',
    'poona': 'Pune',
    'nasik': 'Nashik',
  };

  /// The catalogue's spelling of a geocoded place name.
  @visibleForTesting
  static String catalogueName(String raw) {
    final name = raw.trim();
    return _catalogueSpelling[name.toLowerCase()] ?? name;
  }

  /// Detects the city. With [prompt] false the permission dialog is never
  /// shown — detection only runs if permission was already granted (used on
  /// app open after the user has declined once).
  static Future<CityDetectResult> detect({bool prompt = true}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const CityDetectResult.failed(CityDetectFailure.serviceOff);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && prompt) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const CityDetectResult.failed(CityDetectFailure.deniedForever);
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        return const CityDetectResult.failed(CityDetectFailure.denied);
      }

      // The last known fix is instant and, for a city, almost always right.
      Position? position = await Geolocator.getLastKnownPosition();
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 8),
        ),
      );

      final marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));

      for (final mark in marks) {
        for (final candidate in [
          mark.locality,
          mark.subAdministrativeArea,
          mark.administrativeArea,
        ]) {
          if (candidate != null && candidate.trim().isNotEmpty) {
            return CityDetectResult.found(catalogueName(candidate));
          }
        }
      }
      return const CityDetectResult.failed(CityDetectFailure.noAddress);
    } on TimeoutException {
      return const CityDetectResult.failed(CityDetectFailure.noFix);
    } catch (e) {
      debugPrint('[CityLocator] detection failed: $e');
      return const CityDetectResult.failed(CityDetectFailure.noFix);
    }
  }

  /// Opens the system screen where a permanently refused permission can be
  /// turned back on.
  static Future<void> openSettings(CityDetectFailure failure) async {
    if (failure == CityDetectFailure.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
