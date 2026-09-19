/// A hotel booking parked while the traveller signs back in — the web's
/// `utils/bookingDraft.js`.
///
/// In the app the whole shell sits behind `AuthGate`, so this matters when a
/// session expires *mid-booking*: the gate tears the stack down to the login
/// screen and everything typed into the guest form would be lost. The form is
/// parked here first and offered back on the honeymoon screen after sign-in.
///
/// The web's two storage rules are kept:
///
///   - PAN is never written. The traveller re-enters it after signing in.
///   - Nothing time-sensitive from the supplier is kept — no bookingId, fare
///     or cancellation policy. The room is re-reviewed on restore, because
///     paying against a stale bookingId fails or bills the wrong amount.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/honeymoon_models.dart';

/// One guest as typed — `{ti, pt, fN, lN, pNum}`, never `pan`.
class HotelDraftGuest {
  const HotelDraftGuest({
    required this.isChild,
    this.title = '',
    this.firstName = '',
    this.lastName = '',
    this.passportNumber = '',
  });

  final bool isChild;
  final String title;
  final String firstName;
  final String lastName;
  final String passportNumber;

  Map<String, dynamic> toJson() => {
    'pt': isChild ? 'CHILD' : 'ADULT',
    'ti': title,
    'fN': firstName,
    'lN': lastName,
    'pNum': passportNumber,
  };

  factory HotelDraftGuest.fromJson(dynamic json) => HotelDraftGuest(
    isChild: asString(readKey(json, 'pt')) == 'CHILD',
    title: asString(readKey(json, 'ti')),
    firstName: asString(readKey(json, 'fN')),
    lastName: asString(readKey(json, 'lN')),
    passportNumber: asString(readKey(json, 'pNum')),
  );
}

class HotelBookingDraft {
  const HotelBookingDraft({
    required this.hotel,
    required this.optionId,
    required this.query,
    this.searchId = '',
    this.rooms = const [],
    this.email = '',
    this.mobile = '',
    this.countryCode = '+91',
    required this.savedAt,
  });

  final HotelResult hotel;

  /// The room option to re-review on restore.
  final String optionId;
  final HotelSearchQuery query;
  final String searchId;

  /// Guests per room, as typed.
  final List<List<HotelDraftGuest>> rooms;
  final String email;
  final String mobile;
  final String countryCode;
  final DateTime savedAt;

  Map<String, dynamic> toJson() => {
    'kind': 'hotel',
    'hotelId': hotel.id,
    'hotel': hotel.toJson(),
    'optionId': optionId,
    'query': query.toJson(),
    'searchId': searchId,
    'rooms': [
      for (final room in rooms) [for (final g in room) g.toJson()],
    ],
    'deliveryInfo': {
      'emails': [email],
      'contacts': [mobile],
      'code': [countryCode],
    },
    'savedAt': savedAt.millisecondsSinceEpoch,
  };

  static HotelBookingDraft? fromJson(dynamic json) {
    final query = HotelSearchQuery.fromJson(readKey(json, 'query'));
    final optionId = asString(readKey(json, 'optionId'));
    final hotel = HotelResult.fromJson(readKey(json, 'hotel'));
    if (query == null || optionId.isEmpty || hotel.id.isEmpty) return null;
    final delivery = readKey(json, 'deliveryInfo');
    return HotelBookingDraft(
      hotel: hotel,
      optionId: optionId,
      query: query,
      searchId: asString(readKey(json, 'searchId')),
      rooms: [
        for (final room in asList(readKey(json, 'rooms')))
          [for (final g in asList(room)) HotelDraftGuest.fromJson(g)],
      ],
      email: asString(digPath(delivery, ['emails', 0])),
      mobile: asString(digPath(delivery, ['contacts', 0])),
      countryCode: asString(digPath(delivery, ['code', 0]), fallback: '+91'),
      savedAt: DateTime.fromMillisecondsSinceEpoch(
        asInt(readKey(json, 'savedAt')),
      ),
    );
  }
}

class HotelDraftStore {
  const HotelDraftStore._();

  /// Same key and lifetime as the web's draft.
  static const String _key = 'hw:bookingDraft';
  static const Duration ttl = Duration(minutes: 30);

  static Future<bool> save(HotelBookingDraft draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(draft.toJson()));
      return true;
    } catch (e) {
      debugPrint('[HotelDraftStore] could not save draft: $e');
      return false;
    }
  }

  /// The draft, or null. One past its lifetime or unreadable is removed
  /// rather than returned, so a stale one can never be replayed into a
  /// booking. [hotelId] scopes the read so another hotel cannot pick it up.
  static Future<HotelBookingDraft?> read({String hotelId = ''}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      final json = jsonDecode(raw);
      if (asString(readKey(json, 'kind')) != 'hotel') return null;
      final draft = HotelBookingDraft.fromJson(json);
      if (draft == null || DateTime.now().difference(draft.savedAt) > ttl) {
        await clear();
        return null;
      }
      if (hotelId.isNotEmpty && draft.hotel.id != hotelId) return null;
      return draft;
    } catch (e) {
      debugPrint('[HotelDraftStore] draft unreadable, discarding: $e');
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
