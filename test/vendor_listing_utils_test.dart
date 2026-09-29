// Listing helpers ported from the website: card price, recently viewed,
// venue FAQ, plus the fire-and-forget trackers.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:happy_wedz/vendor/vendor_listing_utils.dart';

void main() {
  group('vendorCardPrice', () {
    test('venue by attributes.vendor_type: veg / non-veg with Rs. stripped', () {
      final p = vendorCardPrice({
        'attributes': {'vendor_type': 'Venues', 'veg_price': 'Rs. 800', 'non_veg_price': 1000, 'price': 5},
      });
      expect(p.isVenue, isTrue);
      expect(p.startingPrice, isNull);
      expect(p.lines.map((l) => l.display), ['Veg ₹ 800', 'Non-Veg ₹ 1000']);
      expect(p.label, 'Veg ₹ 800 · Non-Veg ₹ 1000');
    });

    test('venue detected via vendor.vendorType / subcategory.vendorType, CapitalCase keys', () {
      final p = vendorCardPrice({
        'vendor': {'vendorType': {'name': 'Wedding Venues'}},
        'attributes': {'VegPrice': '1,200'},
      });
      expect(p.label, 'Veg ₹ 1,200');
      final q = vendorCardPrice({
        'subcategory': {'vendorType': {'name': 'Venue'}},
        'attributes': {'NonVegPrice': '1,500'},
      });
      expect(q.label, 'Non-Veg ₹ 1,500');
    });

    test('venue without prices → Contact for pricing (starting price ignored)', () {
      final p = vendorCardPrice({'attributes': {'vendor_type': 'Venues', 'PriceRange': '50,000'}});
      expect(p.hasPrice, isFalse);
      expect(p.label, 'Contact for pricing');
    });

    test('non-venue precedence: photo package → photo+video → PriceRange → price', () {
      Map svc(Map<String, dynamic> attrs) => {'attributes': {'vendor_type': 'Photographers', ...attrs}};
      expect(vendorCardPrice(svc({
        'PhotoPackage_price_inr': '45,000',
        'photo_video_package_price': '90,000',
        'PriceRange': '1',
        'price': '2',
      })).label, '₹ 45,000');
      expect(vendorCardPrice(svc({'PhotoVideo_Price': 'Rs. 90,000', 'PriceRange': '1'})).label, '₹ 90,000');
      expect(vendorCardPrice(svc({'PriceRange': '20,000 - 40,000', 'price': '2'})).label, '₹ 20,000 - 40,000');
      expect(vendorCardPrice(svc({'price': 15000})).label, '₹ 15000');
      // JS falsy values are skipped like `||`.
      expect(vendorCardPrice(svc({'photo_package_price': '', 'price': 0})).label, 'Contact for pricing');
      expect(vendorCardPrice(svc({'photo_package_price': '', 'Photo_video': '30,000'})).label, '₹ 30,000');
    });

    test('non-venue ignores veg prices', () {
      final p = vendorCardPrice({'attributes': {'vendor_type': 'Caterers', 'veg_price': '500'}});
      expect(p.isVenue, isFalse);
      expect(p.label, 'Contact for pricing');
    });
  });

  group('RecentlyViewedStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('records newest first, de-duplicates, caps at 20, uses the web key', () async {
      final store = RecentlyViewedStore.instance;
      for (var i = 1; i <= 22; i++) {
        await store.record({'id': i, 'name': 'V$i'});
      }
      await store.record({'id': 5, 'name': 'V5 again'});
      final ids = await store.ids();
      expect(ids.length, 20);
      expect(ids.first, '5');
      expect(ids.where((e) => e == '5').length, 1);
      expect(ids[1], '22');
      expect(ids.contains('1'), isFalse); // oldest dropped

      final prefs = await SharedPreferences.getInstance();
      final stored = jsonDecode(prefs.getString('happywedz_recently_viewed')!) as List;
      expect(stored.first['name'], 'V5 again');
      expect(stored.first['viewed_at'], isA<String>());
    });

    test('sortRecentFirst moves viewed to the top in view order, rest keep order', () async {
      final store = RecentlyViewedStore.instance;
      await store.record({'id': 3});
      await store.record({'id': 7}); // most recent
      final sorted = await store.sortRecentFirst([
        {'id': 1}, {'id': 3}, {'id': 5}, {'id': 7}, {'id': 9},
      ]);
      expect(sorted.map((e) => e['id']), [7, 3, 1, 5, 9]);
    });

    test('sortByRecentIds matches string and int ids; empty history is a no-op', () {
      expect(RecentlyViewedStore.sortByRecentIds<int>([1, 2, 3], ['3'], (x) => x), [3, 1, 2]);
      expect(RecentlyViewedStore.sortByRecentIds<int>([1, 2, 3], [], (x) => x), [1, 2, 3]);
    });

    test('entryForService mirrors GridView.handleCardClick', () {
      final e = RecentlyViewedStore.entryForService({
        'id': 42,
        'slug': 'vista',
        'media': ['https://s3/a.jpg'],
        'attributes': {'vendor_type': 'Venues', 'vendor_name': 'Vista', 'city': 'Mumbai', 'veg_price': '900'},
      });
      expect(e, {
        'id': 42,
        'name': 'Vista',
        'category': 'Venues',
        'type': 'Venues',
        'location': 'Mumbai',
        'image': 'https://s3/a.jpg',
        'price_range': '900',
        'slug': 'vista',
      });
    });
  });

  group('trackers', () {
    test('trackVendorInteraction posts only with a token', () async {
      final calls = <http.Request>[];
      final client = MockClient((r) async {
        calls.add(r);
        return http.Response('{}', 200);
      });

      SharedPreferences.setMockInitialValues({});
      await trackVendorInteraction(9, VendorInteraction.click, client: client);
      expect(calls, isEmpty);

      SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
      await trackVendorInteraction('9', VendorInteraction.wishlist, client: client);
      expect(calls.single.url.toString(), 'https://api.happywedz.com/interactions/add');
      expect(calls.single.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(calls.single.body), {'vendor_subcategory_data_id': 9, 'action': 'wishlist'});
    });

    test('trackVendorInteraction swallows errors', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'tok'});
      final client = MockClient((_) async => throw Exception('offline'));
      await trackVendorInteraction(1, VendorInteraction.click, client: client);
    });

    test('incrementVendorView once per session, only after success', () async {
      resetVendorViewSession();
      var n = 0;
      var fail = true;
      final client = MockClient((r) async {
        n++;
        expect(r.url.toString(), 'https://api.happywedz.com/api/vendor/increment-view/77');
        expect(r.method, 'POST');
        if (fail) return http.Response('err', 500);
        return http.Response('{"vendor":{"profileViews":12}}', 200);
      });
      expect(await incrementVendorView(77, client: client), isNull);
      fail = false;
      expect(await incrementVendorView(77, client: client), 12);
      expect(await incrementVendorView('77', client: client), isNull);
      expect(n, 2);
    });
  });

  group('vendorFaqs', () {
    test('all nine questions with exact copy', () {
      final faqs = vendorFaqs({
        'attributes': {
          'name': 'Vista Banquet',
          'city': 'Mumbai',
          'veg_starting_price': '800',
          'veg_non_veg': 'Veg & Non-Veg',
          'catering_policy': 'Inhouse only',
          'dj_policy': 'Outside DJ allowed',
          'rooms': 12,
          'parking': 'Valet',
          'slots': ['Morning', 'Evening'],
          'advance_booking': '25%',
          'venue_master': {
            'space_capacity': {'indoor_seating': 150, 'max_guests': 250},
            'facilities': {'parking_capacity': 40},
          },
        },
      });
      expect(faqs.length, 9);
      expect(faqs[0].question, 'What is the price per plate at Vista Banquet?');
      expect(faqs[0].answer, 'Vista Banquet in Mumbai starts at ₹800 per plate for vegetarian menus.');
      expect(faqs[1].question, 'How many guests can Vista Banquet accommodate?');
      expect(faqs[1].answer, 'Vista Banquet can accommodate seating for 150 and up to 250 total guests.');
      expect(faqs[2].question, 'Is non-veg food allowed at Vista Banquet?');
      expect(faqs[2].answer, 'Yes, non-vegetarian food options are available at Vista Banquet (Veg & Non-Veg).');
      expect(faqs[3].answer, 'Catering policy at Vista Banquet: Inhouse only.');
      expect(faqs[4].question, 'Is outside DJ allowed at Vista Banquet?');
      expect(faqs[4].answer, 'DJ policy at Vista Banquet: Outside DJ allowed.');
      expect(faqs[5].answer, 'Yes, Vista Banquet offers 12 rooms for guests and bridal party stay.');
      expect(faqs[6].answer, 'Parking at Vista Banquet: Valet (Capacity: 40 vehicles).');
      expect(faqs[7].question, 'What are the available time slots at Vista Banquet?');
      expect(faqs[7].answer, 'Available booking slots/duration at Vista Banquet: Morning, Evening.');
      expect(faqs[8].question, 'How much is the booking advance at Vista Banquet?');
      expect(faqs[8].answer, 'The advance payment required for booking Vista Banquet is 25%.');
      expect(vendorFaqTitle({'attributes': {'name': 'Vista Banquet'}}),
          'Frequently Asked Questions about Vista Banquet');
    });

    test('variants: pure veg, starting price, capacity-only, parking without info', () {
      final faqs = vendorFaqs({
        'attributes': {
          'vendor_name': 'Green Lawn',
          'veg_non_veg': 'Pure Veg',
          'venue_master': {
            'pricing_booking': {'starting_venue_price': '2,00,000'},
            'space_capacity': {'max_guests': 500},
            'facilities': {'parking_capacity': 100},
          },
        },
      });
      expect(faqs.map((f) => f.answer), [
        'Green Lawn starts at starting price of ₹2,00,000.',
        'Green Lawn can accommodate up to 500 guests.',
        'No, Green Lawn is a pure vegetarian venue.',
        'Parking at Green Lawn: Available (Capacity: 100 vehicles).',
      ]);
    });

    test('name / city overrides like activeVendor; zero rooms skipped', () {
      final faqs = vendorFaqs(
        {'attributes': {'area': '300 Seating', 'rooms': '0', 'parking': 'Yes'}},
        name: 'Override Hall',
        city: 'Pune',
      );
      expect(faqs.map((f) => f.answer), [
        'Override Hall can accommodate 300 Seating.',
        'Parking at Override Hall: Yes.',
      ]);
    });

    test('fewer than two → empty; fallback name', () {
      expect(vendorFaqs({'attributes': {'parking': 'Yes'}}), isEmpty);
      expect(vendorFaqs({}), isEmpty);
      expect(vendorFaqVenueName({}), 'this venue');
    });
  });
}
