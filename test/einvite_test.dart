// E-invite tests: the card model, the save/load API, and the editor.
//
// The fixture below is a real production template, copied from
// `GET /einvites/cards` on 2026-09-21. Every rule these tests pin down was
// read from the live website bundle (the `src (1)` snapshot is missing the
// design code), so a failure here means the app and the website would draw or
// save the same card differently — the exact bug this port fixes: the old
// editor placed these fractional positions as raw pixels.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/einvite1/data/einvite_api.dart';
import 'package:happy_wedz/einvite1/data/einvite_design.dart';
import 'package:happy_wedz/einvite1/ui/einvite_editor_screen.dart';
import 'package:happy_wedz/einvite1/ui/einvite_page_view.dart';

/// "Wedding card" as production serves it (background cleared so widget
/// tests make no image requests). Round-tripped through JSON so it has the
/// same loose types a real `jsonDecode` response has.
Map<String, dynamic> liveTemplate() =>
    jsonDecode(jsonEncode(_liveTemplate)) as Map<String, dynamic>;

const Map<String, dynamic> _liveTemplate = {
      'id': '46498110-f4ce-4a5c-ae04-f09be5f2f625',
      'name': 'Wedding card',
      'cardType': 'wedding_einvite',
      'isTemplate': true,
      'designVersion': 2,
      'backgroundUrl': '',
      'thumbnailUrl': null,
      'pricing': {'isPaid': false, 'price': 0, 'mrp': null},
      'isUnlocked': true,
      'isActive': true,
      'pages': [
        {
          'id': 'page_1789716505094_759632',
          'name': 'Page 1',
          'backgroundUrl': '',
          'fields': [
            {
              'x': 0.1, 'y': 0.1, 'id': 'field_a', 'align': 'center',
              'color': '#e07c1f', 'label': 'Names', 'width': 0.8,
              'fontSize': 116, 'fontStyle': 'normal', 'uppercase': false,
              'fontFamily': 'Playfair Display', 'fontWeight': 400,
              'lineHeight': 1.2, 'defaultText': 'Testing', 'letterSpacing': 0,
            },
            {
              'x': 0.0674, 'y': 0.3102, 'id': 'field_b', 'align': 'center',
              'color': '#dc7a1e', 'label': 'Date', 'width': 0.8,
              'fontSize': 64, 'fontStyle': 'normal', 'uppercase': false,
              'fontFamily': 'Playfair Display', 'fontWeight': 400,
              'lineHeight': 1.2, 'defaultText': 'Your text', 'letterSpacing': 0,
            },
          ],
        },
      ],
    };

void main() {
  // ---------------------------------------------------------------------------
  // Model
  // ---------------------------------------------------------------------------

  group('getCardPages — design version 2', () {
    test('keeps positions as fractions of the card, not pixels', () {
      final pages = getCardPages(liveTemplate());
      expect(pages, hasLength(1));

      final names = pages.first.fields.first;
      expect(names.x, 0.1);
      expect(names.y, 0.1);
      expect(names.width, 0.8);
      expect(names.fontSize, 116);
      expect(names.defaultText, 'Testing');
      expect(pages.first.heightFactor, kCardAspect);
    });

    test('a card with no pages falls back to editableFields', () {
      final card = liveTemplate()
        ..remove('pages')
        ..['editableFields'] = [
          {'id': 'f', 'x': 0.2, 'y': 0.3, 'defaultText': 'Hi'},
        ]
        ..['backgroundUrl'] = 'https://x/bg.png';
      final pages = getCardPages(card);

      expect(pages.single.id, 'page_1');
      expect(pages.single.backgroundUrl, 'https://x/bg.png');
      expect(pages.single.fields.single.x, 0.2);
    });

    test('image placeholders are not editable text', () {
      final card = liveTemplate();
      (card['pages'][0]['fields'] as List).addAll([
        {'id': 'img1', 'src': 'https://x/photo.png'},
        {'id': 'img2', 'label': 'image'},
        {'id': 'img3', 'defaultText': 'image'},
      ]);
      final ids = getCardPages(card).first.fields.map((f) => f.id);
      expect(ids, ['field_a', 'field_b']);
    });

    test('video cards become 16:9 scenes with timing', () {
      final card = liveTemplate()
        ..['cardType'] = 'video'
        ..['video'] = {'duration': 12};
      final page = getCardPages(card).single;
      expect(page.heightFactor, kSceneAspect);
      expect(page.start, 0);
      expect(page.end, 12);
    });
  });

  group('EinviteField.normalize — matches the website normaliser', () {
    EinviteField n(Map<String, dynamic> m) => EinviteField.normalize(m, 0);

    test('clamps out-of-range values', () {
      final f = n({'fontSize': 1000, 'x': 9, 'lineHeight': 0.1});
      expect(f.fontSize, 400);
      expect(f.x, 1.5);
      expect(f.lineHeight, 0.6);
    });

    test('defaults a missing value, but reads an explicit null as 0', () {
      // JavaScript: Number(undefined) is NaN (→ default), Number(null) is 0.
      expect(n({}).x, 0.1);
      expect(n({'x': null}).x, 0);
    });

    test('collapses weights to 400/700 exactly as the web does', () {
      expect(n({'fontWeight': 600}).fontWeight, 700);
      expect(n({'fontWeight': 500}).fontWeight, 400);
      // The web's Number("bold") is NaN, so a v2 "bold" string is 400.
      expect(n({'fontWeight': 'bold'}).fontWeight, 400);
    });

    test('fills labels, ids, alignment and animation', () {
      final f = EinviteField.normalize({'align': 'justify'}, 2);
      expect(f.label, 'Text 3');
      expect(f.id, startsWith('field_'));
      expect(f.align, 'center');
      expect(f.animation, 'fade');
      expect(f.fontFamily, 'Playfair Display');
    });

    test('an empty character limit means none', () {
      expect(n({'characterLimit': ''}).characterLimit, isNull);
      expect(n({'characterLimit': 40.4}).characterLimit, 40);
      expect(n({}).maxLength, 1000);
    });
  });

  group('legacy version-1 conversion', () {
    test('templates convert from the 350×500 canvas', () {
      final pages = getCardPages({
        'isTemplate': true,
        'designVersion': 1,
        'editableFields': [
          {'id': 'f', 'x': 35, 'y': 100, 'fontSize': 20},
        ],
      });
      final f = pages.single.fields.single;
      expect(f.x, closeTo(0.1, 1e-9));
      expect(f.y, closeTo((100 - 20 * 0.85) / 500, 1e-9));
      expect(f.fontSize, closeTo(20 * 1000 / 350, 1e-9));
      expect(f.width, isNull);
      expect(f.align, 'left');
      expect(f.lineHeight, 1.15);
    });

    test('customer copies convert from the 414-wide canvas-editor', () {
      final pages = getCardPages({
        'isTemplate': false,
        'editableFields': [
          {'id': 'f', 'x': 207, 'y': 100, 'fontSize': 30, 'originX': 'center'},
        ],
      });
      final f = pages.single.fields.single;
      expect(f.x, closeTo(207 / 414 - 0.4, 1e-9));
      expect(f.y, closeTo(100 / 659.288, 1e-9));
      expect(f.width, 0.8);
      expect(f.align, 'center');
      expect(f.fontSize, closeTo(30 * 1000 / 414, 1e-9));
    });
  });

  test('a saved page carries exactly the keys the website saves', () {
    final json = getCardPages(liveTemplate()).first.toSaveJson();
    expect(json.keys, ['id', 'name', 'backgroundUrl', 'fields']);
    final field = (json['fields'] as List).first as Map;
    expect(field['x'], 0.1);
    expect(field['defaultText'], 'Testing');
    // Round-trips unchanged through a second normalise, as the web would.
    final again = EinviteField.normalize(
      Map<String, dynamic>.from(field),
      0,
    ).toJson();
    expect(again, field);
  });

  test('parseCssColor handles the formats the designer saves', () {
    expect(parseCssColor('#e07c1f'), const Color(0xFFE07C1F));
    expect(parseCssColor('#fff'), const Color(0xFFFFFFFF));
    expect(parseCssColor('#11223380'), const Color(0x80112233));
    expect(parseCssColor('red'), Colors.black);
  });

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  group('EinviteApi', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'tok',
        'user_id': 42,
      });
    });

    test('createInstance posts the web payload with the bearer token',
        () async {
      late http.Request sent;
      final api = EinviteApi(
        client: MockClient((req) async {
          sent = req;
          return http.Response(
            jsonEncode({'success': true, 'data': {'id': 'copy-1'}}),
            201,
          );
        }),
      );

      final saved = await api.createInstance(
        name: 'Our wedding',
        pages: getCardPages(liveTemplate()),
        originalTemplateId: 'tpl-1',
        ownerUserId: '42',
      );

      expect(saved['id'], 'copy-1');
      expect(sent.method, 'POST');
      expect(sent.url.path, '/einvites/cards/instances');
      expect(sent.headers['Authorization'], 'Bearer tok');
      final body = jsonDecode(sent.body) as Map;
      expect(body.keys,
          containsAll(['name', 'pages', 'originalTemplateId', 'ownerUserId']));
      expect(body['originalTemplateId'], 'tpl-1');
      expect((body['pages'] as List).single['fields'][0]['x'], 0.1);
    });

    test('a create reply without an id is a failure, not a success',
        () async {
      final api = EinviteApi(
        client: MockClient((_) async => http.Response('{"success":true}', 200)),
      );
      expect(
        api.createInstance(
          name: 'x',
          pages: const [],
          originalTemplateId: 't',
          ownerUserId: '42',
        ),
        throwsA(isA<EinviteApiException>()),
      );
    });

    test('updateInstance puts to the instance route', () async {
      late http.Request sent;
      final api = EinviteApi(
        client: MockClient((req) async {
          sent = req;
          return http.Response(jsonEncode({'data': {'id': 'copy-1'}}), 200);
        }),
      );
      await api.updateInstance('copy-1', name: 'n', pages: const []);
      expect(sent.method, 'PUT');
      expect(sent.url.path, '/einvites/cards/copy-1/instance');
      expect(jsonDecode(sent.body).keys, ['name', 'pages']);
    });

    test('getMyCards reads the user id and accepts either envelope', () async {
      late Uri asked;
      for (final body in [
        '[{"id":"a"}]',
        '{"success":true,"data":[{"id":"a"}]}',
      ]) {
        final api = EinviteApi(
          client: MockClient((req) async {
            asked = req.url;
            return http.Response(body, 200);
          }),
        );
        final cards = await api.getMyCards();
        expect(cards.single['id'], 'a');
      }
      expect(asked.path, '/einvites/42/einvites');
    });

    test('getMyCards with no signed-in user asks to sign in', () async {
      SharedPreferences.setMockInitialValues({});
      final api = EinviteApi(
        client: MockClient((_) async => http.Response('[]', 200)),
      );
      expect(
        api.getMyCards(),
        throwsA(isA<EinviteApiException>()
            .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue)),
      );
    });

    test('server errors become readable messages', () async {
      final api = EinviteApi(
        client: MockClient((_) async => http.Response(
            '{"success":false,"message":"Route not found"}', 404)),
      );
      expect(
        api.getCard('nope'),
        throwsA(isA<EinviteApiException>()
            .having((e) => e.message, 'message', 'Route not found')),
      );

      final down = EinviteApi(
        client: MockClient((_) async => http.Response('<html>502</html>', 502)),
      );
      expect(
        down.getCard('x'),
        throwsA(isA<EinviteApiException>().having(
            (e) => e.message, 'message', contains('busy'))),
      );
    });

    test('share link points at the website guest view', () {
      expect(einviteViewUrl('abc'), 'https://www.happywedz.com/einvites/view/abc');
    });
  });

  // ---------------------------------------------------------------------------
  // Rendering
  // ---------------------------------------------------------------------------

  testWidgets('fields are placed as fractions of the drawn card',
      (tester) async {
    final page = getCardPages(liveTemplate()).first;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 400, child: EinvitePageView(page: page)),
        ),
      ),
    ));

    // 400 wide → 560 tall; "Testing" at (0.1, 0.1) → (40, 56).
    final origin = tester.getTopLeft(find.byType(EinvitePageView));
    final text = tester.getTopLeft(find.text('Testing'));
    expect(text.dx - origin.dx, closeTo(40, 0.5));
    expect(text.dy - origin.dy, closeTo(56, 0.5));

    // Box is 0.8 of the width; font scales by 400/1000.
    expect(tester.getSize(find.text('Testing')).width, closeTo(320, 0.5));
    final style = tester.widget<Text>(find.text('Testing')).style!;
    expect(style.fontSize, closeTo(116 * 0.4, 1e-9));
  });

  // ---------------------------------------------------------------------------
  // Editor
  // ---------------------------------------------------------------------------

  group('EinviteEditorScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'auth_token': 'tok',
        'user_id': 42,
      });
    });

    /// A fake backend that records calls and serves [card] for every GET.
    EinviteApi fakeApi(Map<String, dynamic> card, List<http.Request> calls) {
      return EinviteApi(
        client: MockClient((req) async {
          calls.add(req);
          if (req.method == 'GET') {
            return http.Response(jsonEncode({'success': true, 'data': card}), 200);
          }
          final body = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                ...body,
                'id': 'copy-1',
                'isTemplate': false,
                'ownerUserId': 42,
              },
            }),
            200,
          );
        }),
      );
    }

    Future<void> pumpEditor(
      WidgetTester tester,
      EinviteApi api, {
      Size size = const Size(400, 900),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        home: EinviteEditorScreen(cardId: 'tpl', api: api),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('typing updates the card live', (tester) async {
      await pumpEditor(tester, fakeApi(liveTemplate(), []));

      expect(find.text('Not saved yet'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Testing'), 'Asha & Ravi');
      await tester.pump();

      // Once in the input, once drawn on the card.
      expect(find.text('Asha & Ravi'), findsNWidgets(2));
      expect(find.text('Unsaved changes'), findsOneWidget);
    });

    testWidgets('A+ grows the text by 8%, A− shrinks it by 8%', (tester) async {
      await pumpEditor(tester, fakeApi(liveTemplate(), []));
      double size() => tester
          .widget<Text>(find.descendant(
              of: find.byType(EinvitePageView), matching: find.text('Testing')))
          .style!
          .fontSize!;

      final before = size();
      final larger = find.byTooltip('Larger text for Names');
      await tester.ensureVisible(larger);
      await tester.pumpAndSettle();
      await tester.tap(larger);
      await tester.pump();
      expect(size(), closeTo(before * 1.08, 0.05));

      await tester.tap(find.byTooltip('Smaller text for Names'));
      await tester.pump();
      expect(size(), closeTo(before * 1.08 * 0.92, 0.05));
    });

    testWidgets(
        'first save copies the template; later saves update that copy',
        (tester) async {
      final calls = <http.Request>[];
      await pumpEditor(tester, fakeApi(liveTemplate(), calls));

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final create = calls.where((r) => r.method == 'POST').single;
      expect(create.url.path, '/einvites/cards/instances');
      expect(find.text('All changes saved'), findsOneWidget);

      // Let the floating "Saved to Your Cards" snackbar clear the action bar.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Testing'), 'Edited');
      await tester.pump(); // the edit re-enables Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // No second copy: the edit went to the customer's own card.
      expect(calls.where((r) => r.method == 'POST'), hasLength(1));
      final update = calls.where((r) => r.method == 'PUT').single;
      expect(update.url.path, '/einvites/cards/copy-1/instance');
      final fields =
          (jsonDecode(update.body)['pages'] as List).single['fields'] as List;
      expect(fields.first['defaultText'], 'Edited');
    });

    testWidgets("refuses to open another account's card", (tester) async {
      final someoneElses = liveTemplate()
        ..['isTemplate'] = false
        ..['ownerUserId'] = 7;
      await pumpEditor(tester, fakeApi(someoneElses, []));

      expect(find.text('This invitation belongs to another account.'),
          findsOneWidget);
      expect(find.text('Save & share'), findsNothing);
    });

    testWidgets('fits a 320-wide phone without overflow', (tester) async {
      await pumpEditor(
        tester,
        fakeApi(liveTemplate(), []),
        size: const Size(320, 640),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Save & share'), findsOneWidget);
    });
  });
}
