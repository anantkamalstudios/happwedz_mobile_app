/// Local persistence for saved GST business-invoice profiles.
///
/// TripJack has no endpoint for this — it is the traveller's own
/// convenience, not supplier data — so the web keeps a `hw_gst_history` list
/// in `localStorage` (`PassengerDetails.jsx`'s `persistGst`/`gstHistory`).
/// This mirrors that exactly rather than inventing a backend table for it.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GstProfile {
  GstProfile({
    required this.gstNumber,
    required this.companyName,
    required this.companyEmail,
    this.phone = '',
    this.address = '',
  });

  final String gstNumber;
  final String companyName;
  final String companyEmail;
  final String phone;
  final String address;

  factory GstProfile.fromJson(Map<String, dynamic> json) => GstProfile(
    gstNumber: json['gstNumber']?.toString() ?? '',
    companyName: json['companyName']?.toString() ?? '',
    companyEmail: json['companyEmail']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    address: json['address']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'gstNumber': gstNumber,
    'companyName': companyName,
    'companyEmail': companyEmail,
    'phone': phone,
    'address': address,
  };
}

class GstProfileStore {
  static const String _key = 'hw_gst_history';
  static const int _maxEntries = 8;

  /// Most-recently-saved first, matching the React source's history order.
  static Future<List<GstProfile>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => GstProfile.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[GstProfileStore] history unreadable, discarding: $e');
      return [];
    }
  }

  /// Inserts/replaces by GST number at the front, capped at 8 — mirrors
  /// `persistGst()` in `PassengerDetails.jsx`. Storage failures are swallowed:
  /// this is a convenience feature and must never block a booking.
  static Future<void> save(GstProfile entry) async {
    if (entry.gstNumber.trim().isEmpty) return;
    try {
      final history = await loadHistory();
      final next = [
        entry,
        ...history.where((g) => g.gstNumber != entry.gstNumber),
      ].take(_maxEntries).toList();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(next.map((g) => g.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('[GstProfileStore] save failed, ignoring: $e');
    }
  }
}
