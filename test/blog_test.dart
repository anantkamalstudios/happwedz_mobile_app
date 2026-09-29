import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:happy_wedz/blog/blog_api.dart';
import 'package:happy_wedz/blog/blog_article_page.dart';
import 'package:happy_wedz/blog/blog_list_view.dart';

Map<String, dynamic> _blog(int id, String title, {String author = 'By Nidhi'}) => {
      'id': '$id',
      'title': title,
      'shortDescription': 'Short description for $title ' * 5,
      'image': 'https://cdn.example/b$id.jpg',
      'author': author,
      'postDate': '2026-09-16T07:56:38.457Z',
      'category': {'id': 3, 'name': 'Wedding Songs and Videos'},
    };

/// Image placeholders shimmer forever, so pumpAndSettle never returns.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final requests = <http.Request>[];

  MockClient server({List<Map<String, dynamic>>? all, List<Map>? search}) =>
      MockClient((req) async {
        requests.add(req);
        final path = req.url.path;
        if (path == '/blogs/all') {
          return http.Response(jsonEncode({'success': true, 'data': all ?? []}), 200);
        }
        if (path == '/blogs/search') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {'results': search ?? [], 'total': (search ?? []).length},
            }),
            200,
          );
        }
        if (path.endsWith('/increment-search')) return http.Response('{}', 200);
        if (path == '/blogs/16') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': '16',
                'title': 'Yellow Memory Wall',
                'shortDescription': 'A Haldi makeover.',
                'fullDescription': ['<p>First <strong>para</strong></p>', '<p>Second</p>'],
                'images': ['https://cdn.example/1.jpg'],
                'tags': ['#Haldi', 'Memory'],
                'author': 'By Nidhi',
                'category': 'Wedding Songs and Videos',
                'readTime': '5 min',
                'createdDate': '2026-09-16T07:56:38.457Z',
              },
            }),
            200,
          );
        }
        if (path == '/blogs/404') {
          return http.Response(jsonEncode({'success': false}), 200);
        }
        return http.Response('{}', 404);
      });

  setUp(requests.clear);

  test('summary parsing mirrors the website card', () {
    final b = BlogSummary.fromJson(_blog(1, 'T'));
    expect(b.byline, 'BY By Nidhi');
    expect(b.excerpt.endsWith('...'), isTrue);
    expect(b.excerpt.length, 123);
    expect(b.readTime, '5 min read');
    expect(b.category, 'Wedding Songs and Videos');
    expect(blogDate('2026-09-16T07:56:38.457Z'), '16/09/2026');
    expect(BlogSummary.fromJson({'id': 2}).title, 'Untitled');
  });

  testWidgets('6 per page with pagination; title filter when search is empty',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 3000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = BlogApi(
      client: server(all: [for (var i = 1; i <= 8; i++) _blog(i, 'Post $i')]),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BlogListView(api: api))));
    await _settle(tester);
    expect(find.text('Post 1'), findsOneWidget);
    expect(find.text('Post 6'), findsOneWidget);
    expect(find.text('Post 7'), findsNothing);
    await tester.tap(find.text('2'));
    await _settle(tester);
    expect(find.text('Post 7'), findsOneWidget);

    // Server search returns nothing → the loaded list is filtered by title.
    await tester.enterText(find.byType(TextField).first, 'Post 8');
    await tester.pump(const Duration(milliseconds: 350));
    await _settle(tester);
    // Once in the search box, once as the card title.
    expect(find.text('Post 8'), findsNWidgets(2));
    expect(find.text('Post 1'), findsNothing);
    expect(
      requests.any((r) =>
          r.url.path == '/blogs/search' &&
          r.url.queryParameters['q'] == 'Post 8' &&
          r.url.queryParameters['limit'] == '10'),
      isTrue,
    );
  });

  testWidgets('opening a search result reports increment-search',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 2000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final api = BlogApi(
      client: server(all: [_blog(1, 'Other')], search: [_blog(16, 'Yellow Memory Wall')]),
    );
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: BlogListView(api: api))));
    await _settle(tester);
    await tester.enterText(find.byType(TextField).first, 'yellow');
    await tester.pump(const Duration(milliseconds: 350));
    await _settle(tester);
    await tester.tap(find.text('Yellow Memory Wall'));
    await _settle(tester);
    expect(
      requests.any((r) => r.method == 'POST' && r.url.path == '/blogs/16/increment-search'),
      isTrue,
    );
  });

  testWidgets('article shows the full body, tags, share and author card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 4000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: BlogArticlePage(blogId: '16', api: BlogApi(client: server())),
    ));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('Yellow Memory Wall'), findsOneWidget);
    expect(find.text('WEDDING SONGS AND VIDEOS'), findsOneWidget);
    expect(find.text('BY By Nidhi'), findsOneWidget);
    expect(find.text('5 min read'), findsOneWidget);
    expect(find.text('#Haldi'), findsOneWidget);
    expect(find.text('#Memory'), findsOneWidget);
    expect(find.text('WhatsApp'), findsOneWidget);
    expect(find.text('Written by By Nidhi'), findsOneWidget);
    await tester.tap(find.text('Love this wedding?'));
    await tester.pump();
    expect(find.text('Liked!'), findsOneWidget);
  });

  testWidgets('missing article shows "Blog not found"', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BlogArticlePage(blogId: '404', api: BlogApi(client: server())),
    ));
    await _settle(tester);
    expect(find.text('Blog not found'), findsOneWidget);
    expect(find.text('Back to Blogs'), findsOneWidget);
  });
}
