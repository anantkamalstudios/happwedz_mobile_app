/// Local persistence for ShaadiAI — there is no backend session/history
/// endpoint (confirmed from the React source: chats live only in
/// `localStorage['shaadi_ai_chats']`), so this is the only place that data
/// exists at all.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shaadi_ai_models.dart';

class ShaadiAiStorage {
  static const String _chatsKey = 'shaadi_ai_chats';
  static const String _personalityProfileKey = 'wedding_personality_profile';

  /// Sorted newest-updated first, matching the React source's sidebar order.
  static Future<List<ShaadiChatSession>> loadChats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chatsKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      final sessions = decoded.map(ShaadiChatSession.fromJson).toList();
      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      debugPrint('[ShaadiAiStorage] chats unreadable, discarding: $e');
      return [];
    }
  }

  /// Inserts or updates one session (matched by id) and saves the whole
  /// list back, most-recently-updated first.
  static Future<void> saveChat(ShaadiChatSession session) async {
    final sessions = await loadChats();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveAll(sessions);
  }

  static Future<void> deleteChat(String id) async {
    final sessions = await loadChats();
    sessions.removeWhere((s) => s.id == id);
    await _saveAll(sessions);
  }

  static Future<void> _saveAll(List<ShaadiChatSession> sessions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _chatsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  /// `Date.now().toString() + random suffix` in the React source; a Dart
  /// equivalent that stays unique across rapid "New Chat" taps.
  static String newSessionId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final suffix = (now % 100000).toString().padLeft(5, '0');
    return '$now$suffix';
  }

  /// Written once on personality-quiz completion; read by the other 3
  /// feature forms as the "recommendations lens" they forward.
  static Future<void> savePersonalityProfile(
    PersonalityQuizResult result,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personalityProfileKey, jsonEncode(result.raw));
  }

  static Future<String?> loadRecommendationsLens() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_personalityProfileKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      final lens = decoded is Map ? decoded['recommendations_lens'] : null;
      return lens?.toString();
    } catch (e) {
      debugPrint('[ShaadiAiStorage] personality profile unreadable: $e');
      return null;
    }
  }
}
