// API-layer tests for the Wedding Websites module.
//
// `WeddingWebsiteApi` takes an `http.Client`, so all of this is testable
// without a network, mirroring `test/honeymoon_api_test.dart`'s style.
//
// What these pin down:
//   1. The chosen path prefix (`weddingwebsite/wedding-websites...`) is what
//      every authenticated call actually sends — see the path-inconsistency
//      note at the top of `lib/wedding_website/data/wedding_website_api.dart`.
//   2. `GET weddingwebsite/wedding/:slug` (public view) never attaches the
//      stored auth token, even when one exists.
//   3. Bride/groom/slider/gallery fall back through every key shape the
//      source's own `mapExistingToFormState`/`normalizeWebsiteData` read.
//   4. `publishWebsite` derives the slug from `publicUrl` when the response
//      carries no bare `websiteUrl`, matching `WeddingWebsiteView.jsx`.
//   5. The create/update multipart body reorders an indexed section
//      (love story / wedding party / when & where) so an entry with a new
//      photo is sent first — matching `reorderWithFilesFirst` in
//      `WeddingWebsiteForm.jsx`.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/wedding_website/data/wedding_website_api.dart';
import 'package:happy_wedz/wedding_website/models/wedding_website_models.dart';

/// A client that answers every request with [body] at [status].
MockClient respondWith(Object body, {int status = 200}) {
  return MockClient((request) async {
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

/// Captures the outgoing request (including a multipart body's raw bytes) so
/// it can be asserted on.
MockClient capturing(List<http.Request> sink, Object body, {int status = 200}) {
  return MockClient((request) async {
    sink.add(request);
    return http.Response(
      body is String ? body : jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
  });
}

/// A small real file on disk — `MultipartFile.fromPath` needs one to exist.
File _tempImage(Directory dir, String name) {
  final file = File('${dir.path}/$name');
  file.writeAsBytesSync([0xFF, 0xD8, 0xFF, 0xD9]);
  return file;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('fetchMyWebsites', () {
    test('parses a bare array response', () async {
      final api = WeddingWebsiteApi(
        client: respondWith([
          {'id': '1', 'templateId': 'royal', 'brideName': 'Asha', 'groomName': 'Rahul'},
        ]),
      );
      final list = await api.fetchMyWebsites();
      expect(list, hasLength(1));
      expect(list.single.brideName, 'Asha');
      expect(list.single.templateId, 'royal');
    });

    test('parses a {data: [...]} envelope too', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'data': [
            {'id': '2', 'templateId': 'floral'},
          ],
        }),
      );
      final list = await api.fetchMyWebsites();
      expect(list.single.id, '2');
    });

    test('hits the weddingwebsite/wedding-websites path, authenticated', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'jwt-1'});
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, []));
      await api.fetchMyWebsites();
      expect(sent.single.url.path, endsWith('/weddingwebsite/wedding-websites'));
      expect(sent.single.headers['Authorization'], 'Bearer jwt-1');
    });
  });

  group('fetchWebsite reads every fallback key the source reads', () {
    test('bride/groom name/description/image fall back through brideData/title', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'id': 'w1',
          'templateId': 'royal',
          'brideData': {'title': 'Priya', 'description': 'Loves gardens', 'image_url': 'https://x/bride.jpg'},
          'groom': {'name': 'Vikram'},
        }),
      );
      final detail = await api.fetchWebsite('w1');
      expect(detail.bride.name, 'Priya');
      expect(detail.bride.description, 'Loves gardens');
      expect(detail.bride.imageUrl, 'https://x/bride.jpg');
      expect(detail.groom.name, 'Vikram');
    });

    test('slider/gallery prefer the live keys over the older *Images ones', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'id': 'w1',
          'templateId': 'royal',
          'slider': ['https://x/1.jpg'],
          'sliderImages': ['https://x/should-not-appear.jpg'],
          'galleryImages': ['https://x/g1.jpg'],
        }),
      );
      final detail = await api.fetchWebsite('w1');
      expect(detail.sliderImages, ['https://x/1.jpg']);
      expect(detail.galleryImages, ['https://x/g1.jpg']);
    });

    test('gallery/slider entries can be bare strings or {url} objects', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'id': 'w1',
          'templateId': 'royal',
          'gallery': [
            'https://x/a.jpg',
            {'url': 'https://x/b.jpg'},
          ],
        }),
      );
      final detail = await api.fetchWebsite('w1');
      expect(detail.galleryImages, ['https://x/a.jpg', 'https://x/b.jpg']);
    });

    test('loveStory/weddingParty/whenWhere entries parse their own fields', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'id': 'w1',
          'templateId': 'modern',
          'loveStory': [
            {'title': 'We met', 'date': '2020-01-01', 'image': 'https://x/s.jpg'},
          ],
          'weddingParty': [
            {'title': 'Best Man', 'role': 'Friend'},
          ],
          'whenWhere': [
            {'title': 'Ceremony', 'location': 'Goa', 'date': '2027-01-01', 'time': '10:00'},
          ],
        }),
      );
      final detail = await api.fetchWebsite('w1');
      expect(detail.loveStory.single.title, 'We met');
      expect(detail.loveStory.single.imageUrl, 'https://x/s.jpg');
      expect(detail.weddingParty.single.name, 'Best Man'); // falls back to `title`
      expect(detail.weddingParty.single.relation, 'Friend'); // falls back to `role`
      expect(detail.whenWhere.single.location, 'Goa');
      expect(detail.template, WeddingWebsiteTemplate.modern);
    });
  });

  group('publishWebsite', () {
    test('uses websiteUrl when the response carries one', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({'websiteUrl': 'asha-rahul', 'publicUrl': 'https://happywedz.com/wedding/asha-rahul'}),
      );
      final result = await api.publishWebsite('w1');
      expect(result.websiteUrl, 'asha-rahul');
    });

    test('derives the slug from publicUrl when websiteUrl is missing', () async {
      // WeddingWebsiteView.jsx: `result.publicUrl?.split("/wedding/")[1]`.
      final api = WeddingWebsiteApi(
        client: respondWith({'publicUrl': 'https://happywedz.com/wedding/priya-vikram'}),
      );
      final result = await api.publishWebsite('w1');
      expect(result.websiteUrl, 'priya-vikram');
    });

    test('posts to wedding-websites/:id/publish', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'websiteUrl': 'x'}));
      await api.publishWebsite('abc123');
      expect(sent.single.method, 'POST');
      expect(sent.single.url.path, endsWith('/weddingwebsite/wedding-websites/abc123/publish'));
    });
  });

  group('deleteWebsite', () {
    test('sends DELETE to wedding-websites/:id', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {}));
      await api.deleteWebsite('abc123');
      expect(sent.single.method, 'DELETE');
      expect(sent.single.url.path, endsWith('/weddingwebsite/wedding-websites/abc123'));
    });
  });

  group('Public view is genuinely public', () {
    test('never attaches Authorization, even with a token stored', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'jwt-1'});
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(
        client: capturing(sent, {'id': 'w1', 'templateId': 'royal'}),
      );
      await api.fetchPublicWebsite('asha-rahul');
      expect(sent.single.headers.containsKey('Authorization'), isFalse);
    });

    test('hits weddingwebsite/wedding/:slug, not .../wedding-websites/:slug', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(
        client: capturing(sent, {'id': 'w1', 'templateId': 'royal'}),
      );
      await api.fetchPublicWebsite('asha-rahul');
      expect(sent.single.url.path, endsWith('/weddingwebsite/wedding/asha-rahul'));
    });
  });

  group('HTTP failures are translated', () {
    test('a 401 asks the user to sign in', () async {
      final api = WeddingWebsiteApi(client: respondWith({}, status: 401));
      try {
        await api.fetchMyWebsites();
        fail('expected a WeddingWebsiteApiException');
      } on WeddingWebsiteApiException catch (e) {
        expect(e.isUnauthorized, isTrue);
        expect(e.message, contains('sign in'));
      }
    });

    test('a 500 blames the server, not the user', () async {
      final api = WeddingWebsiteApi(client: respondWith({}, status: 500));
      try {
        await api.fetchMyWebsites();
        fail('expected a WeddingWebsiteApiException');
      } on WeddingWebsiteApiException catch (e) {
        expect(e.message, contains('busy'));
      }
    });
  });

  group('createWebsite / updateWebsite multipart shape', () {
    late Directory tempDir;
    setUp(() => tempDir = Directory.systemTemp.createTempSync('wwapi'));
    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('sends the basic text fields and JSON blobs', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'id': 'new1'}));

      final draft = WeddingWebsiteDraft(
        template: WeddingWebsiteTemplate.royal,
        weddingDate: '2027-02-14',
        brideName: 'Asha',
        groomName: 'Rahul',
      );
      final id = await api.createWebsite(draft);

      expect(id, 'new1');
      final req = sent.single;
      expect(req.method, 'POST');
      expect(req.url.path, endsWith('/weddingwebsite/wedding-websites'));
      expect(req.headers['content-type'], contains('multipart/form-data'));

      final body = utf8.decode(req.bodyBytes, allowMalformed: true);
      expect(body, contains('name="templateId"'));
      expect(body, contains('royal'));
      expect(body, contains('name="weddingDate"'));
      expect(body, contains('2027-02-14'));
      expect(body, contains('name="brideData"'));
      expect(body, contains('Asha'));
    });

    test('an entry with a new photo is sent before one without', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'id': 'new1'}));
      final photo = _tempImage(tempDir, 'story.jpg');

      final draft = WeddingWebsiteDraft(
        template: WeddingWebsiteTemplate.royal,
        weddingDate: '2027-02-14',
        loveStory: [
          LoveStoryDraft(title: 'NoPhotoEntry'),
          LoveStoryDraft(title: 'HasPhotoEntry', image: DraftImage.picked(photo)),
        ],
      );
      await api.createWebsite(draft);

      final body = utf8.decode(sent.single.bodyBytes, allowMalformed: true);
      // Both entries are present, but the JSON-encoded `loveStory` field must
      // list the photographed one first (`reorderWithFilesFirst`).
      final withPhotoIndex = body.indexOf('HasPhotoEntry');
      final withoutPhotoIndex = body.indexOf('NoPhotoEntry');
      expect(withPhotoIndex, greaterThanOrEqualTo(0));
      expect(withoutPhotoIndex, greaterThan(withPhotoIndex));
      // And the actual file bytes travel under the `loveStory` field name.
      expect(body, contains('name="loveStory"; filename='));
    });

    test('bride/groom photos are sent under the bride/groom field names', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'id': 'new1'}));
      final bridePhoto = _tempImage(tempDir, 'bride.jpg');

      final draft = WeddingWebsiteDraft(
        template: WeddingWebsiteTemplate.floral,
        weddingDate: '2027-02-14',
        brideImage: DraftImage.picked(bridePhoto),
      );
      await api.createWebsite(draft);

      final body = utf8.decode(sent.single.bodyBytes, allowMalformed: true);
      expect(body, contains('name="bride"; filename='));
      // No new groom photo was set, so no `groom` file part should exist.
      expect(body, isNot(contains('name="groom"; filename=')));
    });

    test('existing slider URLs travel as repeated sliderImages text parts', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'id': 'new1'}));

      final draft = WeddingWebsiteDraft(
        template: WeddingWebsiteTemplate.royal,
        weddingDate: '2027-02-14',
        sliderImages: [
          DraftImage.existing('https://x/1.jpg'),
          DraftImage.existing('https://x/2.jpg'),
        ],
      );
      await api.createWebsite(draft);

      final body = utf8.decode(sent.single.bodyBytes, allowMalformed: true);
      expect('name="sliderImages"'.allMatches(body).length, 2);
      expect(body, contains('https://x/1.jpg'));
      expect(body, contains('https://x/2.jpg'));
    });

    test('updateWebsite PUTs to wedding-websites/:id', () async {
      final sent = <http.Request>[];
      final api = WeddingWebsiteApi(client: capturing(sent, {'id': 'w1'}));
      await api.updateWebsite('w1', WeddingWebsiteDraft(template: WeddingWebsiteTemplate.modern));
      expect(sent.single.method, 'PUT');
      expect(sent.single.url.path, endsWith('/weddingwebsite/wedding-websites/w1'));
    });
  });

  // The shared link is the whole point of this feature, and it was pointing
  // at the API host: `https://api.happywedz.com/wedding/<slug>` answers
  // "route not found" (verified live: API host 404, happywedz.com 200).
  // Anyone sent a wedding-website link from the app got an error page.
  //
  // The website builds the same link from `window.location.origin`
  // (`getPublicUrl` in weddingWebsiteApi.js) — its own origin, never the API.
  group('public share URL', () {
    test('is built on the website host, not the API host', () {
      final url = WeddingWebsiteApi.publicUrlFor('harshada-royal-10');

      expect(url, 'https://happywedz.com/wedding/harshada-royal-10');
      expect(url, isNot(contains('api.happywedz.com')));
    });

    test('publish re-hosts a server publicUrl that carries the API host', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({
          'publicUrl': 'https://api.happywedz.com/wedding/harshada-royal-10',
        }),
      );

      final result = await api.publishWebsite('w1');

      // The response is trusted for the slug only — the host is always ours,
      // so a wrong origin from the backend cannot reach a shared link.
      expect(result.websiteUrl, 'harshada-royal-10');
      expect(result.publicUrl, 'https://happywedz.com/wedding/harshada-royal-10');
    });

    test('publish keeps using the website host when a bare slug comes back', () async {
      final api = WeddingWebsiteApi(
        client: respondWith({'websiteUrl': 'asha-floral-3'}),
      );

      final result = await api.publishWebsite('w1');
      expect(result.publicUrl, 'https://happywedz.com/wedding/asha-floral-3');
    });
  });
}
