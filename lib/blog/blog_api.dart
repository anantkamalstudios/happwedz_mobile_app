import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

// Blog data, as the website reads it (components/pages/BlogLists.jsx,
// BlogDetails.jsx): `GET /blogs/all`, `GET /blogs/:id`,
// `GET /blogs/search?q=&limit=10&offset=0` (data.results) and the fire-and-
// forget `POST /blogs/:id/increment-search` when a search result is opened.

/// Every user-facing blog date renders as DD/MM/YYYY on the website
/// (utils/dateFormat.js).
String blogDate(Object? raw) {
  final d = DateTime.tryParse((raw ?? '').toString());
  if (d == null) return '';
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year}';
}

List<String> _stringList(Object? v) {
  if (v is List) {
    return v
        .map((e) => e?.toString().replaceAll('`', '').trim() ?? '')
        .where((e) => e.isNotEmpty && e != 'null')
        .toList();
  }
  if (v is String && v.trim().isNotEmpty) {
    return [v.replaceAll('`', '').trim()];
  }
  return const [];
}

String _absolute(String url) {
  if (url.startsWith('http')) return url;
  if (url.startsWith('//')) return 'https:$url';
  return '${ApiConfig.apiBase}/${url.replaceFirst(RegExp(r'^/+'), '')}';
}

/// A blog row from `/blogs/all` or `/blogs/search`.
class BlogSummary {
  BlogSummary({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.images,
    required this.author,
    required this.postDate,
    required this.readTime,
    required this.category,
  });

  factory BlogSummary.fromJson(Map json) {
    final cat = json['category'];
    return BlogSummary(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString().trim().isEmpty
          ? 'Untitled'
          : json['title'].toString(),
      shortDescription: (json['shortDescription'] ?? '').toString(),
      images: _stringList(json['image']).map(_absolute).toList(),
      author: (json['author'] ?? '').toString(),
      postDate: (json['postDate'] ?? '').toString(),
      readTime: (json['readTime'] ?? '').toString().trim().isEmpty
          ? '5 min read'
          : json['readTime'].toString(),
      category: cat is Map ? (cat['name'] ?? '').toString() : (cat ?? '').toString(),
    );
  }

  final String id;
  final String title;
  final String shortDescription;

  /// One or more images; the website shows two side by side when there are
  /// several.
  final List<String> images;
  final String author;
  final String postDate;
  final String readTime;
  final String category;

  /// Website card byline: "BY {author || Admin}".
  String get byline => 'BY ${author.trim().isEmpty ? 'Admin' : author}';

  /// First 120 characters of the summary followed by "..." (web card).
  String get excerpt {
    final s = shortDescription;
    return '${s.length > 120 ? s.substring(0, 120) : s}...';
  }
}

/// A full blog from `/blogs/:id`.
class BlogArticle {
  BlogArticle({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.paragraphs,
    required this.images,
    required this.tags,
    required this.author,
    required this.category,
    required this.readTime,
    required this.createdDate,
  });

  factory BlogArticle.fromJson(Map json) {
    final paras = json['fullDescription'];
    return BlogArticle(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      shortDescription: (json['shortDescription'] ?? '').toString(),
      paragraphs: paras is List
          ? paras.map((p) => p?.toString() ?? '').toList()
          : (paras is String && paras.isNotEmpty ? [paras] : const []),
      images: _stringList(json['images']).map(_absolute).toList(),
      tags: _stringList(json['tags']),
      author: (json['author'] ?? '').toString(),
      category: (json['category'] is Map
              ? json['category']['name']
              : json['category'] ?? '')
          .toString(),
      readTime: (json['readTime'] ?? '').toString(),
      createdDate: (json['createdDate'] ?? '').toString(),
    );
  }

  final String id;
  final String title;
  final String shortDescription;

  /// Summernote HTML paragraphs; image `i` is shown before paragraph `i`.
  final List<String> paragraphs;
  final List<String> images;
  final List<String> tags;
  final String author;
  final String category;
  final String readTime;
  final String createdDate;

  String get authorName => author.trim().isEmpty ? 'Admin' : author;

  /// Website: "{readTime || '5 min'} read".
  String get readLabel =>
      '${readTime.trim().isEmpty ? '5 min' : readTime} read';

  /// Images left over after one per paragraph, shown at the end.
  List<String> get trailingImages => images.length > paragraphs.length
      ? images.sublist(paragraphs.length)
      : const [];

  /// The website's share URL for this post.
  String get shareUrl => 'https://happywedz.com/blog/$id';
}

class BlogApiException implements Exception {
  BlogApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class BlogApi {
  BlogApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _timeout = Duration(seconds: 25);

  Future<Map> _getJson(Uri url) async {
    final res = await _client
        .get(url, headers: {'Accept': 'application/json'}).timeout(_timeout);
    if (res.statusCode != 200) {
      throw BlogApiException('HTTP ${res.statusCode}');
    }
    final body = jsonDecode(res.body);
    if (body is! Map) throw BlogApiException('Unexpected response');
    return body;
  }

  /// `GET /blogs/all` — every published blog.
  Future<List<BlogSummary>> fetchAll() async {
    final body = await _getJson(Uri.parse('${ApiConfig.apiBase}/blogs/all'));
    final data = body['data'];
    if (body['success'] != true || data is! List) return const [];
    return data.whereType<Map>().map(BlogSummary.fromJson).toList();
  }

  /// `GET /blogs/:id` — null when the post does not exist (web: "Blog not
  /// found").
  Future<BlogArticle?> fetchById(String id) async {
    final body = await _getJson(Uri.parse('${ApiConfig.apiBase}/blogs/$id'));
    final data = body['data'];
    if (body['success'] != true || data is! Map) return null;
    return BlogArticle.fromJson(data);
  }

  /// `GET /blogs/search?q=&limit=10&offset=0` → `data.results`.
  Future<List<BlogSummary>> search(String q) async {
    final body = await _getJson(Uri.parse('${ApiConfig.apiBase}/blogs/search')
        .replace(queryParameters: {'q': q, 'limit': '10', 'offset': '0'}));
    final data = body['data'];
    final results = data is Map ? data['results'] : null;
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((m) => BlogSummary.fromJson({...m, 'readTime': '5 min read'}))
        .toList();
  }

  /// `POST /blogs/:id/increment-search`, fire and forget.
  Future<void> incrementSearch(String id) async {
    final n = int.tryParse(id);
    if (n == null) return;
    try {
      await _client
          .post(Uri.parse('${ApiConfig.apiBase}/blogs/$n/increment-search'))
          .timeout(_timeout);
    } catch (_) {}
  }
}
