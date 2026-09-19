/// Which saved travellers the user asked to hide from the picker.
///
/// The saved-traveller list comes from the backend
/// (`GET Flight_booking/travellers`), built from past bookings, so the
/// passenger panel's "Add this to My Travellers List" tick works as a
/// suppression switch: unticking someone keeps them out of the picker on later
/// bookings. The web keeps that set per browser under `hw_traveller_hidden`
/// (`travellerStore.js`); here it is per device. It is a convenience, never
/// booking data.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TravellerSuppressionStore {
  const TravellerSuppressionStore._();

  static const String _key = 'hw_traveller_hidden';

  static Future<Set<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return {for (final k in decoded) k.toString()};
    } catch (e) {
      debugPrint('[TravellerSuppressionStore] unreadable: $e');
      return <String>{};
    }
  }

  static Future<void> save(Set<String> keys) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(keys.toList()));
    } catch (e) {
      // Must never break the form it belongs to.
      debugPrint('[TravellerSuppressionStore] could not save: $e');
    }
  }
}
