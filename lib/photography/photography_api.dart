import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

// Photo-inspiration data, as the website reads it
// (services/api/photographyApi.js):
//   `GET /photography-types`              — main types, each with a hero_image
//   `GET /photography/photography`        — every photo ({count, data})
//   `GET /photography/filter?type={id}`   — photos of one type ({count, data})
// The website only ever shows photos whose status is "active"
// (GridImages.jsx, MansoryImageSection.jsx), so the same filter is applied
// here.

List<String> _stringList(Object? v) {
  if (v is List) {
    return v
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty && e != 'null')
        .toList();
  }
  if (v is String && v.trim().isNotEmpty) return [v.trim()];
  return const [];
}

/// Photo URLs come back absolute; type hero images come back relative
/// (`uploads/hero_image-….jpg`) and the website prefixes them with the API
/// host.
String _absolute(String url) {
  if (url.startsWith('http')) return url;
  if (url.startsWith('//')) return 'https:$url';
  return '${ApiConfig.apiBase}/${url.replaceFirst(RegExp(r'^/+'), '')}';
}

/// A row from `/photography-types`.
class PhotographyType {
  PhotographyType({required this.id, required this.name, required this.heroImage});

  factory PhotographyType.fromJson(Map json) {
    final hero = (json['hero_image'] ?? '').toString().trim();
    return PhotographyType(
      id: int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      heroImage: hero.isEmpty ? '' : _absolute(hero),
    );
  }

  final int id;
  final String name;
  final String heroImage;
}

/// A photo from `/photography/photography` or `/photography/filter`.
class InspirationPhoto {
  InspirationPhoto({
    required this.id,
    required this.title,
    required this.typeId,
    required this.description,
    required this.photographerName,
    required this.cityName,
    required this.tags,
    required this.thumbnails,
    required this.images,
    required this.status,
  });

  factory InspirationPhoto.fromJson(Map json) {
    return InspirationPhoto(
      id: int.tryParse('${json['id']}') ?? 0,
      title: (json['title'] ?? '').toString(),
      typeId: int.tryParse('${json['photography_type_id']}'),
      description: (json['description'] ?? '').toString(),
      photographerName: (json['photographer_name'] ?? '').toString(),
      cityName: (json['city_name'] ?? '').toString(),
      tags: _stringList(json['tags']),
      thumbnails: _stringList(json['thumbnails']).map(_absolute).toList(),
      images: _stringList(json['images']).map(_absolute).toList(),
      status: (json['status'] ?? '').toString(),
    );
  }

  final int id;
  final String title;
  final int? typeId;
  final String description;
  final String photographerName;
  final String cityName;
  final List<String> tags;
  final List<String> thumbnails;
  final List<String> images;
  final String status;

  bool get isActive => status == 'active';

  /// Grid image: the full image first, as the website's grid does
  /// (`img.images[0]`), falling back to the thumbnail.
  String get coverUrl =>
      images.isNotEmpty ? images.first : (thumbnails.isNotEmpty ? thumbnails.first : '');

  /// Everything viewable full screen, full images first.
  List<String> get allImages => images.isNotEmpty ? images : thumbnails;
}

class PhotographyApi {
  PhotographyApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<List<PhotographyType>> fetchTypes() async {
    final res = await _client.get(Uri.parse('${ApiConfig.apiBase}/photography-types'));
    if (res.statusCode != 200) {
      throw Exception('Failed to load photo categories (${res.statusCode})');
    }
    final decoded = json.decode(res.body);
    final list = decoded is List ? decoded : (decoded is Map ? decoded['data'] : null);
    if (list is! List) return const [];
    return list.whereType<Map>().map(PhotographyType.fromJson).toList();
  }

  /// All active photos, or only those of [typeId] when given.
  Future<List<InspirationPhoto>> fetchPhotos({int? typeId}) async {
    final url = typeId == null
        ? '${ApiConfig.apiBase}/photography/photography'
        : '${ApiConfig.apiBase}/photography/filter?type=$typeId';
    final res = await _client.get(Uri.parse(url));
    if (res.statusCode != 200) {
      throw Exception('Failed to load photos (${res.statusCode})');
    }
    return parsePhotos(res.body);
  }

  static List<InspirationPhoto> parsePhotos(String body) {
    final decoded = json.decode(body);
    final list = decoded is List ? decoded : (decoded is Map ? decoded['data'] : null);
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map(InspirationPhoto.fromJson)
        .where((p) => p.isActive && p.coverUrl.isNotEmpty)
        .toList();
  }
}
