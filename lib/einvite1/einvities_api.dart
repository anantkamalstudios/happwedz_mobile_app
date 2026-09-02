import 'dart:convert';
import 'package:happy_wedz/core/config/api_config.dart';
import 'package:happy_wedz/einvite1/template_model.dart';
import 'package:http/http.dart' as http;


class EInviteAPI {
  final String base = '${ApiConfig.apiBase}/einvites';

  // Replace main domain with backend domain to avoid corrupted images
  String fixImageUrl(String url) {
    if (url.isEmpty) return url;
    if (url.contains('happywedz.com')) {
      return url.replaceFirst('happywedz.com', 'happywedzbackend.happywedz.com');
    }
    return url;
  }

  Future<List<EInviteTemplate>> fetchTemplates() async {
    final res = await http.get(Uri.parse('$base/cards'));

    if (res.statusCode != 200) {
      throw Exception('Failed to load templates');
    }

    final data = jsonDecode(res.body);

    // Process each template & fix image URLs
    final list = (data['data'] as List).map((e) {
      // Fix thumbnail + background before model creation
      e['thumbnailUrl'] = fixImageUrl(e['thumbnailUrl'] ?? '');
      e['backgroundUrl'] = fixImageUrl(e['backgroundUrl'] ?? '');

      return EInviteTemplate.fromJson(e);
    }).toList();

    return list;
  }

  Future<bool> saveDraft(Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$base/save_draft'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<List<dynamic>> fetchDrafts(int userId) async {
    final res = await http.get(Uri.parse('$base/drafts/$userId'));

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch drafts');
    }

    final data = jsonDecode(res.body);

    // Fix image URLs inside drafts also
    for (var item in data['data']) {
      item['thumbnailUrl'] = fixImageUrl(item['thumbnailUrl'] ?? '');
      item['backgroundUrl'] = fixImageUrl(item['backgroundUrl'] ?? '');
    }

    return data['data'];
  }
}
