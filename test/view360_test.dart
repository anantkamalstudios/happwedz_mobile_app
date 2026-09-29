// view360 helper — every data shape the web's view360Helper.js accepts,
// plus the app-side embedCode fix.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/vendor/view360.dart';

void main() {
  group('getSafe360Url', () {
    test('accepts http(s), strips stray backticks', () {
      expect(getSafe360Url('https://tour.example.com/a'), 'https://tour.example.com/a');
      expect(getSafe360Url(' `http://x.com/t` '), 'http://x.com/t');
    });
    test('rejects junk and unsafe schemes', () {
      expect(getSafe360Url('javascript:alert(1)'), isNull);
      expect(getSafe360Url('data:text/html,hi'), isNull);
      expect(getSafe360Url('null'), isNull);
      expect(getSafe360Url('undefined'), isNull);
      expect(getSafe360Url('not a url'), isNull);
      expect(getSafe360Url(''), isNull);
      expect(getSafe360Url(42), isNull);
    });
  });

  group('get360Assets', () {
    test('top-level string columns', () {
      final a = get360Assets({'view360_image': 'https://s3/p.jpg', 'view360_video': 'https://s3/v.mp4'});
      expect(a.images, ['https://s3/p.jpg']);
      expect(a.videos, ['https://s3/v.mp4']);
      expect(a.url, isNull);
    });

    test('top-level arrays and camelCase variants, objects with url/path/location', () {
      final a = get360Assets({
        'view360_images': ['https://s3/1.jpg', {'url': 'https://s3/2.jpg'}],
        'view360Images': [{'path': 'https://s3/3.jpg'}, {'location': 'https://s3/1.jpg'}],
        'view360_videos': ['https://s3/a.mp4'],
        'view360Videos': [{'url': 'https://s3/b.mp4'}],
      });
      expect(a.images, ['https://s3/1.jpg', 'https://s3/2.jpg', 'https://s3/3.jpg']); // de-duplicated
      expect(a.videos, ['https://s3/a.mp4', 'https://s3/b.mp4']);
    });

    test('inside attributes + pasted link', () {
      final a = get360Assets({
        'attributes': {
          'view360_images': ['https://s3/x.jpg'],
          'view360_video': 'https://s3/x.mp4',
          'view360_url': 'https://my.matterport.com/show/?m=abc',
        },
      });
      expect(a.images, ['https://s3/x.jpg']);
      expect(a.videos, ['https://s3/x.mp4']);
      expect(a.url, 'https://my.matterport.com/show/?m=abc');
    });

    test('attributes.view360_url wins over item.view360_url (JS ??)', () {
      final a = get360Assets({
        'view360_url': 'https://b.com',
        'attributes': {'view360_url': 'https://a.com'},
      });
      expect(a.url, 'https://a.com');
      // A present-but-unsafe attributes value is not skipped by ?? (web parity).
      expect(get360Assets({'view360_url': 'https://b.com', 'attributes': {'view360_url': 'javascript:x'}}).url, isNull);
    });

    test('media.view360 object: panoImage and modelUrl', () {
      final a = get360Assets({
        'media': {
          'view360': {'panoImage': 'https://s3/pano.jpg', 'modelUrl': 'https://s3/model.jpg'},
        },
      });
      expect(a.images, ['https://s3/pano.jpg', 'https://s3/model.jpg']);
    });

    test('media gallery arrays are never 360 content', () {
      expect(get360Assets({'media': ['https://s3/gallery.jpg']}).isEmpty, isTrue);
    });

    test('ignores null / "null" / empty placeholders', () {
      final a = get360Assets({
        'view360_image': null,
        'view360_video': 'null',
        'view360_images': ['', 'undefined', '``'],
      });
      expect(a.isEmpty, isTrue);
    });

    test('embedCode iframe src becomes the tour url (app fix)', () {
      final a = get360Assets({
        'media': {
          'view360': {
            'embedCode': '<iframe width="100%" src="https://kuula.co/share/abc?fs=1&amp;vr=0" allowfullscreen></iframe>',
          },
        },
      });
      expect(a.url, 'https://kuula.co/share/abc?fs=1&vr=0');
      expect(embedCodeSrc("<iframe src='http://x.com/t'></iframe>"), 'http://x.com/t');
      expect(embedCodeSrc('https://direct.example.com/tour'), 'https://direct.example.com/tour');
      expect(embedCodeSrc('<iframe src="javascript:alert(1)"></iframe>'), isNull);
      expect(embedCodeSrc('<div>no iframe</div>'), isNull);
    });

    test('pasted link wins over embedCode', () {
      final a = get360Assets({
        'attributes': {'view360_url': 'https://pasted.com'},
        'media': {'view360': {'embedCode': '<iframe src="https://embed.com"></iframe>'}},
      });
      expect(a.url, 'https://pasted.com');
    });

    test('non-map input', () {
      expect(get360Assets(null).isEmpty, isTrue);
      expect(get360Assets('x').isEmpty, isTrue);
    });
  });

  group('hasView360', () {
    test('precomputed has360 wins', () {
      expect(hasView360({'has360': false, 'view360_image': 'https://s3/p.jpg'}), isFalse);
      expect(hasView360({'has360': true}), isTrue);
    });
    test('any embed code counts (web parity)', () {
      expect(hasView360({'media': {'view360': {'embedCode': '<div>tour</div>'}}}), isTrue);
    });
    test('assets / link / nothing', () {
      expect(hasView360({'view360_video': 'https://s3/v.mp4'}), isTrue);
      expect(hasView360({'attributes': {'view360_url': 'https://t.com'}}), isTrue);
      expect(hasView360({'attributes': {'view360_url': 'ftp://t.com'}}), isFalse);
      expect(hasView360({'id': 1}), isFalse);
      expect(hasView360(null), isFalse);
    });
  });

  test('view360Title', () {
    expect(view360Title({'attributes': {'name': 'Vista Banquet'}}), 'Vista Banquet • 360°');
    expect(view360Title({'vendor': {'vendor_name': 'Studio'}}), 'Studio • 360°');
    expect(view360Title({}), 'Vendor • 360°');
  });

  testWidgets('screen: invalid id and empty service states', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Vendor360Screen(serviceId: 'abc')));
    await tester.pump();
    expect(find.text('Invalid or missing vendor service id.'), findsOneWidget);
    expect(find.text('Go Back'), findsOneWidget);

    await tester.pumpWidget(const MaterialApp(
      home: Vendor360Screen(serviceId: 5, service: {'id': 5, 'attributes': {'name': 'X'}}),
    ));
    await tester.pump();
    expect(find.text('No 360° content available for this vendor.'), findsOneWidget);
  });
}
