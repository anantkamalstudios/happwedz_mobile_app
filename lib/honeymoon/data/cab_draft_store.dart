/// A cab booking parked while the traveller signs back in — the `kind: "cab"`
/// draft of the web's `utils/bookingDraft.js`.
///
/// On the web, choosing a cab while signed out saves the quote and sends the
/// traveller to login, and the results page picks the booking back up on
/// return. In the app the shell sits behind `AuthGate`, so this matters when a
/// session lapses mid-booking: the gate drops the stack to the login screen.
/// The search and what was typed are parked here and offered back on the
/// honeymoon screen after sign-in.
///
/// Nothing time-sensitive from the supplier is kept: no quote id, booking id
/// or fare. Continuing searches again and reopens the same vehicle class from
/// the same vendor, at today's price.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cab_models.dart';
import '../models/honeymoon_models.dart';

class CabBookingDraft {
  const CabBookingDraft({
    required this.query,
    required this.quoteIdentity,
    this.vehicleLabel = '',
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.phone = '',
    this.flightNumber = '',
    this.serviceRequest = '',
    required this.savedAt,
  });

  final CabSearchQuery query;

  /// [cabQuoteIdentity] of the chosen quote.
  final String quoteIdentity;
  final String vehicleLabel;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String flightNumber;
  final String serviceRequest;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'kind': 'cab',
    'query': query.toJson(),
    'quote': quoteIdentity,
    'vehicle': vehicleLabel,
    'passenger': {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'flightNumber': flightNumber,
      'serviceRequest': serviceRequest,
    },
    'savedAt': savedAt.millisecondsSinceEpoch,
  };

  static CabBookingDraft? fromJson(dynamic json) {
    final query = CabSearchQuery.fromJson(readKey(json, 'query'));
    final quote = asString(readKey(json, 'quote'));
    if (query == null || quote.isEmpty) return null;
    final pax = readKey(json, 'passenger');
    return CabBookingDraft(
      query: query,
      quoteIdentity: quote,
      vehicleLabel: asString(readKey(json, 'vehicle')),
      firstName: asString(readKey(pax, 'firstName')),
      lastName: asString(readKey(pax, 'lastName')),
      email: asString(readKey(pax, 'email')),
      phone: asString(readKey(pax, 'phone')),
      flightNumber: asString(readKey(pax, 'flightNumber')),
      serviceRequest: asString(readKey(pax, 'serviceRequest')),
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        asInt(readKey(json, 'savedAt')),
      ),
    );
  }
}

class CabDraftStore {
  const CabDraftStore._();

  /// Its own slot, so a parked cab never overwrites a parked hotel stay.
  static const String _key = 'hw:cabBookingDraft';

  /// The web's draft lifetime.
  static const Duration ttl = Duration(minutes: 30);

  static Future<bool> save(CabBookingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(draft.toJson()));
      return true;
    } catch (e) {
      debugPrint('[CabDraftStore] could not save draft: $e');
      return false;
    }
  }

  /// The draft, or null. One past its lifetime or unreadable is removed.
  static Future<CabBookingDraft?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final draft = CabBookingDraft.fromJson(jsonDecode(raw));
      if (draft == null || DateTime.now().difference(draft.savedAt) > ttl) {
        await clear();
        return null;
      }
      return draft;
    } catch (e) {
      debugPrint('[CabDraftStore] draft unreadable, discarding: $e');
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {
      // Nothing useful to do.
    }
  }
}
