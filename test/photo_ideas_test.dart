import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:happy_wedz/photography/photo_ideas_view.dart';
import 'package:happy_wedz/photography/photography_api.dart';

Map<String, dynamic> _photo(int id, String title, {int type = 1, String status = 'active'}) => {
      'id': id,
      'title': title,
      'photography_type_id': type,
      'description': 'About $title',
      'photographer_name': 'Darshana',
      'city_name': 'Pune',
      'tags': ['lehenga'],
      'thumbnails': ['https://cdn.example/t$id.jpg'],
      'images': ['https://cdn.example/p$id.jpg'],
      'status': status,
    };

/// Image placeholders shimmer forever, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final requests = <Uri>[];

  MockClient server() => MockClient((req) async {
        requests.add(req.url);
        final path = req.url.path;
        if (path == '/photography-types') {
          return http.Response(
            jsonEncode([
              {'id': 1, 'name': 'Outfit', 'hero_image': 'uploads/hero.jpg'},
              {'id': 3, 'name': 'Groom Wear', 'hero_image': ''},
            ]),
            200,
          );
        }
        if (path == '/photography/photography') {
          return http.Response(
            jsonEncode({
              'count': 3,
              'data': [
                _photo(1, 'Bridal Lehenga'),
                _photo(2, 'Sherwani', type: 3),
                _photo(3, 'Hidden Card', status: 'inactive'),
              ],
            }),
            200,
          );
        }
        if (path == '/photography/filter') {
          return http.Response(
            jsonEncode({'count': 1, 'data': [_photo(2, 'Sherwani', type: 3)]}),
            200,
          );
        }
        return http.Response('not found', 404);
      });

  setUp(requests.clear);

  test('parsePhotos keeps only active photos with an image', () {
    final photos = PhotographyApi.parsePhotos(jsonEncode({
      'data': [
        _photo(1, 'A'),
        _photo(2, 'B', status: 'inactive'),
        {..._photo(3, 'C'), 'images': [], 'thumbnails': []},
      ],
    }));
    expect(photos.map((p) => p.title), ['A']);
    expect(photos.single.coverUrl, 'https://cdn.example/p1.jpg');
  });

  test('type hero images are made absolute', () {
    final t = PhotographyType.fromJson({'id': 1, 'name': 'Outfit', 'hero_image': 'uploads/h.jpg'});
    expect(t.heroImage, 'https://api.happywedz.com/uploads/h.jpg');
  });

  testWidgets('shows live photos, hides inactive, filters by type', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: PhotoIdeasView(api: PhotographyApi(client: server()))),
    ));
    await _settle(tester);

    expect(find.text('Bridal Lehenga'), findsOneWidget);
    expect(find.text('Sherwani'), findsOneWidget);
    expect(find.text('Hidden Card'), findsNothing);
    expect(find.text('All'), findsOneWidget);

    await tester.tap(find.text('Groom Wear'));
    await _settle(tester);

    expect(requests.last.path, '/photography/filter');
    expect(requests.last.queryParameters['type'], '3');
    expect(find.text('Bridal Lehenga'), findsNothing);
    expect(find.text('Sherwani'), findsOneWidget);
  });
}
