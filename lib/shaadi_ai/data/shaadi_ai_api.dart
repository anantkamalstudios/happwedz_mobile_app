/// The only place in the ShaadiAI module that talks HTTP.
///
/// All 5 endpoints go through the same host as everything else in the app
/// (`ApiConfig.apiBase`) — confirmed from the React source (`ShaadiAI.jsx`,
/// `ChatFeatures.jsx`) that they use the *default* `axiosInstance`, never
/// `aiAxiosInstance` and never the `shaadiai.happywedz.com` host the
/// already-ported Genie chat (`lib/ai_chat_screen/`) uses — these are two
/// unrelated features that happen to share the word "AI".
///
/// Auth mirrors the web `axiosInstance` request interceptor: attach
/// `Authorization: Bearer <token>` when a token is stored, omit it
/// otherwise. Unlike most of this app's APIs, nothing here requires a
/// token — ShaadiAI works fully signed out in the React source.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/api_config.dart';
import '../models/shaadi_ai_models.dart';

/// A failure the UI can render without leaking internals. The two fallback
/// strings below are quoted verbatim from the React source, which does not
/// vary its copy by HTTP status the way `HoneymoonApi` does.
class ShaadiAiException implements Exception {
  ShaadiAiException(this.message);

  final String message;

  @override
  String toString() => message;
}

const String kShaadiChatFallbackMessage =
    'Oops! Something went wrong. Please try again in a moment. 🙏';

const String kShaadiFeatureFallbackMessage =
    "Couldn't process that — try again";

class ShaadiAiApi {
  ShaadiAiApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.apiBase}/$path');

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(ApiConfig.authTokenKey) ?? '';
      if (token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      debugPrint('[ShaadiAiApi] token read failed: $e');
    }
    return headers;
  }

  Future<dynamic> _post(String path, Map<String, dynamic> body) async {
    late final http.Response res;
    try {
      res = await _client
          .post(_uri(path), headers: await _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ShaadiAiException(kShaadiFeatureFallbackMessage);
    } catch (e) {
      debugPrint('[ShaadiAiApi] POST $path transport error: $e');
      throw ShaadiAiException(kShaadiFeatureFallbackMessage);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.trim().isEmpty) return <String, dynamic>{};
      try {
        return jsonDecode(res.body);
      } catch (e) {
        debugPrint('[ShaadiAiApi] POST $path decode error: $e');
        throw ShaadiAiException(kShaadiFeatureFallbackMessage);
      }
    }

    debugPrint('[ShaadiAiApi] POST $path HTTP ${res.statusCode}');
    throw ShaadiAiException(kShaadiFeatureFallbackMessage);
  }

  /// `POST /ai/chat`
  Future<ShaadiChatMessage> sendChat({
    required String message,
    required List<Map<String, String>> conversationHistory,
  }) async {
    try {
      final json = await _post('ai/chat', {
        'message': message,
        'conversationHistory': conversationHistory,
      });
      return ShaadiChatMessage.fromChatResponse(json);
    } on ShaadiAiException {
      throw ShaadiAiException(kShaadiChatFallbackMessage);
    }
  }

  /// `POST /ai/personality-quiz`
  Future<PersonalityQuizResult> submitPersonalityQuiz({
    required List<int?> partner1Answers,
    required List<int?> partner2Answers,
  }) async {
    final json = await _post('ai/personality-quiz', {
      'partner1Answers': partner1Answers,
      'partner2Answers': partner2Answers,
    });
    return PersonalityQuizResult.fromJson(json);
  }

  /// `POST /ai/culture-blender`
  Future<CultureBlenderResult> submitCultureBlender({
    required String culture1,
    required String culture2,
    required String ceremonyType,
    String? recommendationsLens,
  }) async {
    final json = await _post('ai/culture-blender', {
      'culture1': culture1,
      'culture2': culture2,
      'ceremonyType': ceremonyType,
      'partner1Priorities': kCulturePrioritiesConstant,
      'partner2Priorities': kCulturePrioritiesConstant,
      'recommendationsLens': recommendationsLens,
    });
    return CultureBlenderResult.fromJson(json);
  }

  /// `POST /ai/conflict-resolver`
  Future<ConflictResolverResult> submitConflictResolver({
    required String topic,
    required String partner1Input,
    required String partner2Input,
    String? recommendationsLens,
  }) async {
    final json = await _post('ai/conflict-resolver', {
      'topic': topic,
      'partner1Input': partner1Input,
      'partner2Input': partner2Input,
      'recommendationsLens': recommendationsLens,
    });
    return ConflictResolverResult.fromJson(json);
  }

  /// `POST /ai/timeline-generator`
  Future<List<TimelineItem>> submitTimelineGenerator({
    required String startTime,
    required List<String> selectedEvents,
    required int travelMins,
    String? constraints,
    String? recommendationsLens,
  }) async {
    final json = await _post('ai/timeline-generator', {
      'startTime': startTime,
      'selectedEvents': selectedEvents,
      'travelMins': travelMins,
      'constraints': constraints,
      'recommendationsLens': recommendationsLens,
    });
    return timelineResultFromJson(json);
  }

  void dispose() => _client.close();
}
