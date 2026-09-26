// E-Invite card types and video scene rendering.
//
// The category tiles filter the catalogue client-side by `cardType`, and the
// video tile asked for `video_invitation` — a value the backend does not use.
// Verified live against `GET /einvites/cards?limit=200`, which returns
// `total: 4`: three `wedding_einvite` and one `video`. Nothing matched, so the
// section rendered "Coming Soon!" and hid a real, fully-formed video card
// (with `video: {videoUrl, duration, audioUrl, sourceDuration}` and timed
// `pages[]` scenes).
//
// The renderer never had the bug — `einvite_design.dart` reads
// `card['cardType'] == 'video'` — which is why only the tile needed fixing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/einvite1/data/einvite_design.dart';
import 'package:happy_wedz/einvite1/einvite.dart';
import 'package:happy_wedz/einvite1/ui/einvite_page_view.dart';

/// A card shaped like the live API's video entry.
Map<String, dynamic> _videoCardJson() => {
      'id': 'ba210bd9',
      'name': 'Functions card',
      'cardType': 'video',
      'backgroundUrl': 'https://api.happywedz.com/uploads/einvites/poster.jpg',
      'video': {
        'audioUrl': null,
        'duration': 10,
        'videoUrl': 'https://api.happywedz.com/uploads/einvites/clip.mp4',
        'sourceDuration': 8,
      },
      'pages': [
        {
          'id': 'page_1',
          'name': 'Scene 1',
          'start': 0,
          'end': 5,
          'backgroundUrl':
              'https://api.happywedz.com/uploads/einvites/poster.jpg',
          'fields': const [],
        },
      ],
    };

void main() {
  group('card type taxonomy', () {
    test('the tiles use the cardType values the API actually serves', () {
      final types = {
        for (final t in invitationTypes) t['title']: t['type'],
      };

      expect(types['Wedding E-Invitations'], 'wedding_einvite');
      expect(types['Save The Date'], 'save_the_date');

      // The bug: this was 'video_invitation', which matches nothing.
      expect(
        types['Video Invitations'],
        'video',
        reason: 'the backend serves cardType "video"; anything else renders '
            'an empty section and hides the real card',
      );
    });

    test('every tile type is a plain lowercase snake_case token', () {
      for (final tile in invitationTypes) {
        expect(tile['type'], matches(RegExp(r'^[a-z_]+$')), reason: '$tile');
      }
    });
  });

  group('video scenes', () {
    test('a video card builds timed scene pages, not still pages', () {
      final pages = getCardPages(_videoCardJson());

      expect(pages, isNotEmpty);
      final scene = pages.first;
      // `start` is what marks a page as a scene rather than a still, and it
      // is what EinvitePageView keys video playback off.
      expect(scene.start, 0);
      expect(scene.end, 5);
      // A scene is 16:9; a still card is taller than it is wide.
      expect(scene.heightFactor, closeTo(kSceneAspect, 0.001));
    });

    test('a still card keeps the card aspect and has no scene timing', () {
      final pages = getCardPages({
        'id': 'w1',
        'cardType': 'wedding_einvite',
        'backgroundUrl': 'https://example.com/bg.jpg',
        'pages': [
          {
            'id': 'p1',
            'backgroundUrl': 'https://example.com/bg.jpg',
            'fields': const [],
          },
        ],
      });

      expect(pages.first.start, isNull);
      expect(pages.first.heightFactor, closeTo(kCardAspect, 0.001));
    });
  });

  group('EinvitePageView', () {
    testWidgets('renders a still page without a video layer', (tester) async {
      final pages = getCardPages(_videoCardJson());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              // No videoUrl passed: this is the grid-thumbnail case, which
              // must stay on the cheap poster rather than spinning up a
              // controller per tile.
              child: EinvitePageView(page: pages.first),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(EinvitePageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed video source degrades to the poster, not a blank card', (
      tester,
    ) async {
      final pages = getCardPages(_videoCardJson());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EinvitePageView(
                page: pages.first,
                // No video plugin in the test binding, so initialize() fails —
                // exactly the path a dead CDN link would take on device.
                videoUrl: 'https://example.com/missing.mp4',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // The poster Image is still there and nothing was thrown to the user.
      expect(find.byType(Image), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disposing the page view releases the scene player', (
      tester,
    ) async {
      final pages = getCardPages(_videoCardJson());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: EinvitePageView(
                page: pages.first,
                videoUrl: 'https://example.com/clip.mp4',
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // A surviving controller or listener would surface as a pending-timer
      // or setState-after-dispose failure at teardown.
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(EinvitePageView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
