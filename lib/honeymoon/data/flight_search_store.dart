/// Local memory for the flight search form, mirroring the two stores
/// `components/FlightSearchForm.jsx` keeps:
///
///  * `hw_flightSearchForm` in `sessionStorage` — the form as last filled in,
///    so coming back from the results finds everything still there. A
///    session store lives only as long as the tab, so here it is held in
///    memory for the life of the app process rather than written to disk.
///  * `hw_flightRecentSearches` in `localStorage` — the last six one-way and
///    round-trip searches, de-duplicated on route and dates, newest first.
///    These survive restarts, so they go to [SharedPreferences].
///
/// Neither is supplier data and neither has a backend endpoint on the web.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/flight_models.dart';

class FlightSearchStore {
  const FlightSearchStore._();

  static const String _recentKey = 'hw_flightRecentSearches';
  static const int _maxRecent = 6;

  /// The form as last filled in, for this app session.
  static FlightSearchQuery? lastForm;

  /// Newest first. A corrupt entry is skipped rather than failing the list.
  static Future<List<FlightSearchQuery>> loadRecent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_recentKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final entry in decoded)
          if (entry is Map) FlightSearchQuery.fromJson(entry),
      ].where((q) => q.isRunnable).toList();
    } catch (e) {
      debugPrint('[FlightSearchStore] recent searches unreadable: $e');
      return const [];
    }
  }

  /// Puts [query] at the top, dropping any older entry for the same route and
  /// dates. Multi-city searches are not remembered — the web's "Search again"
  /// cannot run them either.
  static Future<void> saveRecent(FlightSearchQuery query) async {
    if (query.isMultiCity || !query.isRunnable) return;
    try {
      final existing = await loadRecent();
      final next = [
        query,
        ...existing.where((e) => e.recentKey != query.recentKey),
      ].take(_maxRecent);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _recentKey,
        jsonEncode([for (final q in next) q.toJson()]),
      );
    } catch (e) {
      debugPrint('[FlightSearchStore] could not save recent search: $e');
    }
  }
}
