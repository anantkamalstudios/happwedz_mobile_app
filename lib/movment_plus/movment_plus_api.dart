/// API client for Movment Plus' AI face-matching service — a separate host
/// (`ApiConfig.movmentPlusAiBaseUrl`) from the main backend. Mirrors
/// `movmentPlusApi.js` on the website: `POST /events/selfie` submits a
/// guest's selfie for matching against a gallery token; `GET
/// /events/my-photos` polls for the AI's results. The service identifies the
/// caller via an `X-User-ID` header rather than the JWT, so both calls
/// require a logged-in HappyWedz user.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../authservice.dart';
import '../core/config/api_config.dart';

class MovmentPlusAuthException implements Exception {
  MovmentPlusAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class MovmentPlusApiException implements Exception {
  MovmentPlusApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PhotoMatch {
  PhotoMatch({
    required this.photoId,
    required this.photoUrl,
    this.functionName,
    this.distance,
  });

  final String photoId;
  final String photoUrl;
  final String? functionName;
  final double? distance;

  factory PhotoMatch.fromJson(Map<String, dynamic> json) {
    return PhotoMatch(
      photoId: (json['photo_id'] ?? '').toString(),
      photoUrl: (json['photo_url'] ?? '').toString(),
      functionName: json['function_name']?.toString(),
      distance: (json['distance'] as num?)?.toDouble(),
    );
  }
}

class MyPhotosResult {
  MyPhotosResult({required this.matches, required this.count, this.message});

  final List<PhotoMatch> matches;
  final int count;

  /// Present when [matches] is empty, explaining why (no selfie uploaded
  /// yet, no face detected, gallery photos not yet encoded, or genuinely no
  /// match) — an empty list is a normal response, not an error.
  final String? message;

  factory MyPhotosResult.fromJson(Map<String, dynamic> json) {
    final rawMatches = json['matches'];
    final matches = rawMatches is List
        ? rawMatches
              .whereType<Map>()
              .map((e) => PhotoMatch.fromJson(Map<String, dynamic>.from(e)))
              .where((m) => m.photoUrl.isNotEmpty)
              .toList()
        : <PhotoMatch>[];
    return MyPhotosResult(
      matches: matches,
      count: (json['count'] as num?)?.toInt() ?? matches.length,
      message: json['message']?.toString(),
    );
  }
}

class MovmentPlusApi {
  const MovmentPlusApi._();

  static Future<int> _requireUserId() async {
    final id = await UserPrefs.getUserId();
    if (id == null || id <= 0) {
      throw MovmentPlusAuthException(
        'Please log in to your HappyWedz account to find your photos.',
      );
    }
    return id;
  }

  /// Uploads a guest's selfie for face-matching against [token]'s gallery.
  /// Matching happens asynchronously server-side — this only confirms the
  /// upload; poll [getMyPhotos] afterward for results.
  static Future<void> uploadSelfie({
    required String token,
    required File file,
  }) async {
    final userId = await _requireUserId();
    final uri = Uri.parse('${ApiConfig.movmentPlusAiBaseUrl}/events/selfie');
    final request = http.MultipartRequest('POST', uri)
      ..fields['token'] = token
      ..headers['X-User-ID'] = userId.toString();

    final mimeType = lookupMimeType(file.path) ?? 'image/jpeg';
    final parts = mimeType.split('/');
    request.files.add(
      await http.MultipartFile.fromPath(
        'image',
        file.path,
        contentType: MediaType(parts[0], parts.length > 1 ? parts[1] : 'jpeg'),
      ),
    );

    // Uploading a phone photo and forwarding it to S3 is slower than a
    // typical API call — matches the 2-minute client timeout the website
    // itself uses for this endpoint.
    final streamed = await request.send().timeout(const Duration(minutes: 2));
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MovmentPlusApiException(
        _extractError(response.body) ??
            'Could not upload your selfie. Please try again.',
      );
    }
  }

  /// Polls the AI service for photos matching the guest's most recent
  /// selfie upload in [token]'s gallery. Face comparison against every
  /// stored photo is slow (the website's own source measured ~78s for one
  /// selfie against 26 photos), hence the long timeout.
  static Future<MyPhotosResult> getMyPhotos({required String token}) async {
    final userId = await _requireUserId();
    final uri = Uri.parse(
      '${ApiConfig.movmentPlusAiBaseUrl}/events/my-photos',
    ).replace(queryParameters: {'token': token});

    final response = await http
        .get(
          uri,
          headers: {
            'X-User-ID': userId.toString(),
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(minutes: 4));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MovmentPlusApiException(
        _extractError(response.body) ??
            'Could not check for your photos. Please try again.',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw MovmentPlusApiException(
        'Unexpected response from the photo-matching service.',
      );
    }
    return MyPhotosResult.fromJson(Map<String, dynamic>.from(decoded));
  }

  static String? _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return (decoded['error'] ?? decoded['message'])?.toString();
      }
    } catch (_) {
      // Not JSON — fall through to the caller's default message.
    }
    return null;
  }
}
