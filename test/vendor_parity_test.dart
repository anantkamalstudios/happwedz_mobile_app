import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/core/services/wishlist_store.dart';
import 'package:happy_wedz/vendor/vendor_detail_sections.dart';
import 'package:happy_wedz/vendor/vendor_row.dart';
import 'package:happy_wedz/vendor/vendordetailsscreen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WishlistStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'auth_token': 't0k'});
    });

    test('parses vendor_services_id from GET /wishlist rows', () {
      expect(
        WishlistStore.parseIds([
          {'vendor_services_id': 12},
          {'vendor_services_id': '34'},
          {'other': 1},
          'junk',
        ]).toList(),
        ['12', '34'],
      );
    });

    test('load seeds the saved set with the bearer token', () async {
      late http.Request seen;
      final store = WishlistStore.forTesting(MockClient((req) async {
        seen = req;
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {'vendor_services_id': 73998},
            ],
          }),
          200,
        );
      }));
      await store.load(force: true);
      expect(seen.url.path, '/wishlist');
      expect(seen.headers['Authorization'], 'Bearer t0k');
      expect(store.contains(73998), isTrue);
      expect(store.contains('1'), isFalse);
    });

    test('toggle reads "added" from the response, not local state', () async {
      http.Request? posted;
      final store = WishlistStore.forTesting(MockClient((req) async {
        posted = req;
        // Server says it was removed (no `data`) even though locally it was
        // unsaved — the website treats `!!result.data` as "added".
        return http.Response(jsonEncode({'success': true}), 200);
      }));
      final r = await store.toggle('55');
      expect(r.success, isTrue);
      expect(r.added, isFalse);
      expect(store.contains('55'), isFalse);
      expect(jsonDecode(posted!.body), {'vendor_services_id': 55});
      expect(posted!.url.path, '/wishlist/toggle');
    });

    test('toggle rolls back on failure', () async {
      final store = WishlistStore.forTesting(MockClient((_) async =>
          http.Response(jsonEncode({'success': false, 'message': 'nope'}), 500)));
      final r = await store.toggle('9');
      expect(r.success, isFalse);
      expect(store.contains('9'), isFalse);
      expect(WishlistStore.failureMessage(r), 'nope');
      expect(WishlistStore.successMessage(true), 'Added to wishlist');
    });
  });

  group('slug lookup (website isSlugMatch)', () {
    test('exact, id-suffixed and name matches', () {
      final row = {
        'slug': 'nikhil-banquet-hall-73998',
        'attributes': {'name': 'Nikhil Banquet Hall'},
      };
      expect(VendorDetailsScreenTestHooks.slugMatches(row, 'nikhil-banquet-hall-73998'), isTrue);
      expect(VendorDetailsScreenTestHooks.slugMatches(row, 'nikhil-banquet-hall'), isTrue);
      expect(VendorDetailsScreenTestHooks.slugMatches(row, 'banquet-hall'), isTrue);
    });

    test('an unrelated row is rejected (no first-row fallback)', () {
      final row = {
        'slug': 'amrapali-resorts',
        'attributes': {'name': 'Amrapali Resorts'},
      };
      expect(VendorDetailsScreenTestHooks.slugMatches(row, 'nikhil-banquet-hall'), isFalse);
    });
  });

  group('card fields', () {
    final row = {
      'id': 73998,
      'vendor_id': 75077,
      'media': ['/uploads/a.jpg', 'https://cdn/x.jpg'],
      'attributes': {'name': 'Nikhil Banquet Hall', 'city': 'Unknown', 'rating': '4.2', 'review_count': 5},
      'vendor': {'businessName': 'Nikhil Venues', 'city': 'Nashik', 'phone': '74472 64535'},
    };

    test('name, image, city, rating, phone', () {
      expect(vendorCardName(row), 'Nikhil Banquet Hall');
      expect(vendorCardImage(row), 'https://api.happywedz.com/uploads/a.jpg');
      expect(vendorCardCity(row), 'Nashik'); // "Unknown" dropped
      expect(vendorCardRating(row), 4.2);
      expect(vendorCardReviewCount(row), 5);
      expect(vendorCardPhone(row), '7447264535');
      expect(vendorAccountId(row), '75077');
    });

    test('absolute and relative image URLs', () {
      expect(vendorAbsoluteUrl('https://s3/x.png'), 'https://s3/x.png');
      expect(vendorAbsoluteUrl('/uploads/y.png'), 'https://api.happywedz.com/uploads/y.png');
      expect(vendorAbsoluteUrl('//cdn/z.png'), 'https://cdn/z.png');
    });
  });

  group('detail sections', () {
    test('pricing details mirror the website', () {
      final d = VendorPricingDetails.of({
        'attributes': {
          'starting_price': 50000,
          'pricing_description': 'Packages…',
          'pricing_brochure_name': 'rates.pdf',
        },
      });
      expect(d.hasAny, isTrue);
      expect(d.isPdf, isTrue);
      expect(d.isImage, isFalse);
      expect(VendorPricingDetails.of({'attributes': {}}).hasAny, isFalse);
    });

    test('upcoming dates: future only, sorted, off when availability is off', () {
      final now = DateTime(2026, 9, 28);
      final service = {
        'attributes': {
          'available_slots': [
            {'date': '2026-10-05'},
            {'date': '2026-09-01'},
            {'date': '2026-09-28T00:00:00Z'},
          ],
        },
      };
      expect(upcomingAvailableDates(service, now: now), ['2026-09-28', '2026-10-05']);
      expect(
        upcomingAvailableDates({...service, 'availabilityActive': false}, now: now),
        isEmpty,
      );
    });
  });

  testWidgets('availability calendar renders (no locale data needed)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: VendorAvailabilityCalendar(dates: ['2030-01-05', '2030-02-10']),
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Available Dates'), findsOneWidget);
    expect(find.text('January 2030'), findsOneWidget);
    expect(find.text('2 Months'), findsOneWidget);
    await tester.tap(find.byTooltip('Next Month'));
    await tester.pump();
    expect(find.text('February 2030'), findsOneWidget);
  });

  testWidgets('pricing section lays out inside a scroll view', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ListView(
          children: [
            VendorPricingSection(
              details: VendorPricingDetails.of({
                'attributes': {
                  'starting_price': 50000,
                  'pricing_description': 'Packages for every size.',
                  'pricing_brochure_name': 'rates.pdf',
                },
              }),
              onRequestQuote: () {},
            ),
          ],
        ),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('Request Quote'), findsOneWidget);
    expect(find.text('Base Package Starting At'), findsOneWidget);
    expect(find.text('Request PDF Copy →'), findsOneWidget);
  });
}
