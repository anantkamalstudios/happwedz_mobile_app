// Query-param building for vendor listing filters — must match what the
// website's useInfiniteScroll.js (+ priceFilterUtils.js) sends.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:happy_wedz/core/core.dart';
import 'package:happy_wedz/vendor/vendor_filters.dart';

void main() {
  group('filterKeyFor', () {
    test('venue listing without subcategory → venues', () {
      expect(filterKeyFor(isVenues: true), 'venues');
      expect(filterKeyFor(isVenues: true, vendorType: 'Venues'), 'venues');
    });
    test('lowercases and hyphenates like useFilters.js', () {
      expect(filterKeyFor(vendorType: 'Photographers'), 'photographers');
      expect(filterKeyFor(vendorType: 'Bridal Makeup'), 'bridal-makeup');
      expect(filterKeyFor(isVenues: true, subcategory: 'Banquet Halls'), 'banquet-halls');
    });
    test('vendorType wins over subcategory (DynamicAside: vendorType || slug)', () {
      expect(filterKeyFor(vendorType: 'Photographers', subcategory: 'Candid'), 'photographers');
      expect(filterKeyFor(subcategory: 'Decorators'), 'decorators');
    });
    test('display names with punctuation resolve to the web URL-slug keys', () {
      expect(filterKeyFor(isVenues: true, subcategory: 'Marriage Garden / Lawns'), 'marriage-garden--lawns');
      expect(filterKeyFor(isVenues: true, subcategory: 'Small Functions / Party Halls'),
          'small-functions--party-halls');
      expect(filterKeyFor(isVenues: true, subcategory: '4 Star & Above Wedding Hotels'),
          '4-star-and-above-wedding-hotels');
    });
    test('unknown / empty → DEFAULT', () {
      expect(filterKeyFor(vendorType: 'Astrologers'), kDefaultFilterKey);
      expect(filterKeyFor(), kDefaultFilterKey);
      expect(vendorFilterGroupsFor(kDefaultFilterKey), kDefaultVendorFilters);
    });
  });

  group('config', () {
    test('keeps every web key', () {
      const keys = [
        'photographers', 'bridal-makeup', 'makeup', 'wedding-planners', 'decorators', 'mehandi',
        'venues', 'banquet-halls', 'wedding-resorts', 'destination-wedding-venues',
        'small-functions--party-halls', 'marriage-garden--lawns', 'wedding-farmhouses',
        'kalyana-mandapams', '4-star-and-above-wedding-hotels', 'catering', 'jewellery',
        'wedding-cakes', 'invitations', 'groom', 'bridal', 'bands', 'choreographers', 'gifts',
        'honeymoon', 'djs', 'sangeet-choreographers', 'wedding-entertainment', 'trousseau-packers',
        'catering-services', 'cakes', 'bartenders', 'pre-wedding-shoot-location',
        'pre-wedding-photographers', 'bridal-lehengas', 'sherwani', 'accessories',
        'wedding-pandits', 'beauty-wellness',
      ];
      expect(kVendorFilterConfig.keys.toSet(), keys.toSet());
      expect(kVendorFilterConfig['venues']!.keys, ['venue Type', 'capacity', 'price Per Plate', 'rooms']);
      expect(kVendorFilterConfig['banquet-halls']!['price Per Plate'], ['<1000', '1000-2000', '2000-3000', '3000+']);
      expect(kDefaultVendorFilters['Price'],
          ['₹10,000 - ₹50,000', '₹50,000 - ₹1,00,000', '₹1,00,000 and more']);
    });
  });

  group('range parsing', () {
    test('price rules', () {
      expect(parsePriceRange('<1,000'), const FilterRange(max: 999));
      expect(parsePriceRange('under 500'), const FilterRange(max: 499));
      expect(parsePriceRange('1,60,000+'), const FilterRange(min: 160000));
      expect(parsePriceRange('80,000-1,20,000'), const FilterRange(min: 80000, max: 120000));
      expect(parsePriceRange('₹10,000 - ₹50,000'), const FilterRange(min: 10000, max: 50000));
      expect(parsePriceRange('40,000'), const FilterRange(max: 40000));
      expect(parsePriceRange('Rs 5,000'), const FilterRange(max: 5000));
      expect(parsePriceRange(''), isNull);
      expect(parsePriceRange('yes'), isNull);
    });
    test('fixes the web "and more" bug: min, not max', () {
      expect(parsePriceRange('₹1,00,000 and more'), const FilterRange(min: 100000));
    });
    test('capacity rules', () {
      expect(parseCapacityRange('<100'), const FilterRange(max: 99));
      expect(parseCapacityRange('1000+'), const FilterRange(min: 1000));
      expect(parseCapacityRange('200-500'), const FilterRange(min: 200, max: 500));
    });
  });

  group('vendorFilterQueryParams', () {
    test('venues example', () {
      final p = vendorFilterQueryParams('venues', {
        'venue Type': ['Banquet Halls', 'Wedding Resorts'],
        'capacity': ['100-200', '500-1000'],
        'price Per Plate': ['<1,000', '2,000-3,000'],
        'rooms': ['<10', '100+'],
      });
      expect(p, {
        'subCategory': 'Banquet Halls,Wedding Resorts',
        'minCapacity': '100',
        'maxCapacity': '1000',
        'minFoodPrice': '2000',
        'maxFoodPrice': '3000',
        // rooms: min 100 > max 9 → contradictory, dropped.
      });
    });

    test('photographers prices', () {
      expect(vendorFilterQueryParams('photographers', {'prices': ['40,000']}), {'maxPrice': '40000'});
      expect(
        vendorFilterQueryParams('photographers', {'prices': ['40,000-80,000', '80,000-1,20,000']}),
        {'minPrice': '40000', 'maxPrice': '120000'},
      );
      expect(vendorFilterQueryParams('photographers', {'prices': ['1,60,000+']}), {'minPrice': '160000'});
      // Web union bounding box: lowest min, highest max.
      expect(
        vendorFilterQueryParams('photographers', {'prices': ['40,000-80,000', '1,60,000+']}),
        {'minPrice': '40000', 'maxPrice': '80000'},
      );
      // Max-only + min-only that do not overlap → no price filter at all.
      expect(vendorFilterQueryParams('photographers', {'prices': ['40,000', '1,60,000+']}), isEmpty);
    });

    test('DEFAULT price options', () {
      expect(vendorFilterQueryParams(kDefaultFilterKey, {'Price': ['₹1,00,000 and more']}),
          {'minPrice': '100000'});
      expect(vendorFilterQueryParams(kDefaultFilterKey, {'Price': ['₹10,000 - ₹50,000', '₹50,000 - ₹1,00,000']}),
          {'minPrice': '10000', 'maxPrice': '100000'});
    });

    test('several price-like groups fold into one min/max', () {
      expect(
        vendorFilterQueryParams('bridal-makeup', {
          'price (Bridal Makeup)': ['12,000-16,000'],
          'price (Engagement)': ['18,000-25,000'],
        }),
        {'minPrice': '12000', 'maxPrice': '25000'},
      );
      expect(vendorFilterQueryParams('wedding-planners', {'prices': ['<200,000']}), {'maxPrice': '199999'});
      expect(vendorFilterQueryParams('decorators', {'home Function Decor': ['1,20,000+']}),
          {'minPrice': '120000'});
      expect(vendorFilterQueryParams('wedding-pandits', {'pricing': ['11,000-21,000']}),
          {'minPrice': '11000', 'maxPrice': '21000'});
    });

    test('catering price per plate → food price, not price', () {
      expect(vendorFilterQueryParams('catering', {'price Per Plate': ['1,500+'], 'capacity': ['<100']}),
          {'minFoodPrice': '1500', 'maxCapacity': '99'});
    });

    test('price Per Kg is dropped entirely', () {
      expect(vendorFilterQueryParams('cakes', {'price Per Kg': ['500-1,000']}), isEmpty);
    });

    test('rating, reviews and leftover filters JSON (bartenders)', () {
      final p = vendorFilterQueryParams('bartenders', {
        'type': ['flair bartenders'],
        'services': ['ice', 'glassware'],
        'pricing For 200 Guests': ['1,00,000+'],
        'rating': ['rated 4.5+', 'rated 4+'],
        'review Count': ['5+ reviews', '30+ reviews'],
      });
      expect(p['minPrice'], '100000');
      expect(p['minRating'], '4');
      expect(p['minReviews'], '5');
      expect(p.containsKey('maxRating'), isFalse);
      expect(jsonDecode(p['filters']!), {
        'type': ['flair bartenders'],
        'services': ['ice', 'glassware'],
      });
    });

    test('rating / review edge tokens', () {
      expect(vendorFilterQueryParams('bartenders', {'rating': ['rated 4.8+']}), {'minRating': '4.8'});
      expect(vendorFilterQueryParams('bartenders', {'rating': ['rated <4']}), {'maxRating': '4'});
      expect(vendorFilterQueryParams('bartenders', {'rating': ['all ratings']}), isEmpty);
      expect(vendorFilterQueryParams('bartenders', {'review Count': ['<5 reviews']}), {'maxReviews': '5'});
      expect(vendorFilterQueryParams('bartenders', {'rating': ['rated <4', 'rated 4.5+']}), isEmpty);
    });

    test('min/max Capacity groups are not "capacity" → filters JSON', () {
      final p = vendorFilterQueryParams('catering-services', {'min Capacity': ['<50']});
      expect(jsonDecode(p['filters']!), {'min Capacity': ['<50']});
    });

    test('groups outside the key and empty groups are ignored', () {
      expect(vendorFilterQueryParams('photographers', {'capacity': ['<100'], 'prices': []}), isEmpty);
      final honeymoon = vendorFilterQueryParams('honeymoon', {'budget': ['<50,000'], 'duration': ['5 days']});
      expect(jsonDecode(honeymoon['filters']!), {'budget': ['<50,000'], 'duration': ['5 days']});
    });
  });

  test('capitalizeFilterLabel mirrors TopFilter', () {
    expect(capitalizeFilterLabel('venue Type'), 'Venue Type');
    expect(capitalizeFilterLabel('Marriage Garden / lawns'), 'Marriage Garden / Lawns');
    expect(capitalizeFilterLabel('price_per plate'), 'Price Per Plate');
  });

  testWidgets('panel: Apply enables only on change and returns the pending selection', (tester) async {
    VendorFilterSheetResult? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: SingleChildScrollView(
          child: VendorFilterPanel(
            groups: vendorFilterGroupsFor('photographers'),
            showRating: true,
            onDone: (r) => result = r,
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Prices'), findsOneWidget);
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(result, isNull, reason: 'nothing pending yet');

    await tester.tap(find.text('40,000-80,000'));
    await tester.pump();
    expect(find.text('1'), findsOneWidget); // count badge
    await tester.ensureVisible(find.text('Apply'));
    await tester.tap(find.text('Apply'));
    await tester.pump();
    expect(result!.groups, {'prices': ['40,000-80,000']});

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(result!.isEmpty, isTrue);
  });
}
