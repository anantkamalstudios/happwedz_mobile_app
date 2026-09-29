/// Listing helpers ported from the website:
///
///  - [vendorCardPrice] — price fields of `transformApiData`
///    (`src/hooks/useInfiniteScroll.js:62-227`) and their display in
///    `components/layouts/Main/GridView.jsx:457-506`;
///  - [RecentlyViewedStore] — `services/localStorageService.js` `trackView` /
///    `getRecentlyViewed` + `utils/recentlyViewedHelper.js`;
///  - [trackVendorInteraction] — `GridView.jsx:225-270` `/interactions/add`;
///  - [incrementVendorView] — `components/layouts/Detailed.jsx:5575-5607`;
///  - [vendorFaqs] — `components/layouts/VenueFAQ.jsx`.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config/api_config.dart';

// ---------------------------------------------------------------------------
// JS-truthiness helpers
// ---------------------------------------------------------------------------

/// JS `a || b` semantics: null, false, '', 0 and NaN are falsy.
Object? _t(Object? v) {
  if (v == null || v == false) return null;
  if (v is String && v.isEmpty) return null;
  if (v is num && (v == 0 || v.isNaN)) return null;
  return v;
}

Object? _firstTruthy(Iterable<Object?> values) {
  for (final v in values) {
    final t = _t(v);
    if (t != null) return t;
  }
  return null;
}

Map _map(Object? v) => v is Map ? v : const {};

/// JS template-literal string for a value (`${x}`).
String _js(Object? v) {
  if (v == null) return 'null';
  if (v is double && v == v.roundToDouble() && v.isFinite) return v.toInt().toString();
  if (v is List) return v.map((e) => e == null ? '' : _js(e)).join(',');
  return v.toString();
}

/// `vendorTypeName` from `useInfiniteScroll.js:89-93`.
String vendorTypeNameOf(Map service) {
  final attrs = _map(service['attributes']);
  final vendor = _map(service['vendor']);
  final sub = _map(service['subcategory']);
  final v = _firstTruthy([
    attrs['vendor_type'],
    _map(vendor['vendorType'])['name'],
    _map(sub['vendorType'])['name'],
  ]);
  return v == null ? '' : _js(v);
}

// ---------------------------------------------------------------------------
// (a) Card price
// ---------------------------------------------------------------------------

/// One labelled price on a card ("Veg" / "Non-Veg" / starting price).
@immutable
class VendorPriceLine {
  const VendorPriceLine(this.label, this.amount);

  /// "Veg", "Non-Veg" or null for a plain starting price.
  final String? label;

  /// Display amount with the `Rs.` prefix removed, e.g. "1,200".
  final String amount;

  String get display => label == null ? '₹ $amount' : '$label ₹ $amount';
}

/// Price fields of a listing card.
@immutable
class VendorCardPrice {
  const VendorCardPrice({
    required this.isVenue,
    this.vegPrice,
    this.nonVegPrice,
    this.startingPrice,
  });

  final bool isVenue;
  final String? vegPrice;
  final String? nonVegPrice;
  final String? startingPrice;

  static String _strip(String raw) => raw.replaceFirst('Rs.', '').trim();

  /// The lines GridView renders: Veg / Non-Veg when either exists, otherwise
  /// the starting price; empty when there is nothing (→ "Contact for pricing").
  List<VendorPriceLine> get lines {
    if (vegPrice != null || nonVegPrice != null) {
      return [
        if (vegPrice != null && _strip(vegPrice!).isNotEmpty) VendorPriceLine('Veg', _strip(vegPrice!)),
        if (nonVegPrice != null && _strip(nonVegPrice!).isNotEmpty)
          VendorPriceLine('Non-Veg', _strip(nonVegPrice!)),
      ];
    }
    if (startingPrice != null && _strip(startingPrice!).isNotEmpty) {
      return [VendorPriceLine(null, _strip(startingPrice!))];
    }
    return const [];
  }

  bool get hasPrice => lines.isNotEmpty;

  /// One-line label: "Veg ₹ 800 · Non-Veg ₹ 1,000", "₹ 50,000" or
  /// "Contact for pricing".
  String get label {
    final l = lines;
    if (l.isEmpty) return 'Contact for pricing';
    return l.map((e) => e.display).join(' · ');
  }

  /// The raw value the web's map popup / recently-viewed entry uses
  /// (`starting_price || vegPrice || nonVegPrice`).
  String? get rawBadge => startingPrice ?? vegPrice ?? nonVegPrice;
}

/// Price logic of `transformApiData` (`useInfiniteScroll.js:94-170`): a
/// venue (vendor type name contains "venue") shows veg / non-veg per plate;
/// anything else a starting price from the photo package variants, then the
/// photo+video package variants, then `PriceRange`, then `price`.
VendorCardPrice vendorCardPrice(Map service) {
  final a = _map(service['attributes']);
  // final isVenue = vendorTypeNameOf(service).toLowerCase().contains('venue');
  // Website bug not ported: the web takes `attributes.vendor_type` first,
  // which on live rows often holds a *subcategory* name ("Wedding Resorts"),
  // so a venue was priced from `PriceRange` ("₹ 0 - 500") instead of its
  // veg/non-veg per-plate prices. Any of the type fields naming a venue
  // counts here.
  final isVenue = [
    _map(service['attributes'])['vendor_type'],
    _map(_map(service['vendor'])['vendorType'])['name'],
    _map(_map(service['subcategory'])['vendorType'])['name'],
  ].any((t) => (t ?? '').toString().toLowerCase().contains('venue'));

  String? s(Object? v) => v == null ? null : _js(v);

  if (isVenue) {
    return VendorCardPrice(
      isVenue: true,
      vegPrice: s(_firstTruthy([a['veg_price'], a['VegPrice']])),
      nonVegPrice: s(_firstTruthy([a['non_veg_price'], a['NonVegPrice']])),
    );
  }

  final photoPackage = _firstTruthy([
    a['photo_package_price'],
    a['PhotoPackage_Price'],
    a['PhotoPackage'],
    a['PhotoPackage_price'],
    a['PhotoPackagePrice'],
    a['PhotoPackage_price_inr'],
  ]);
  final photoVideoPackage = _firstTruthy([
    a['photo_video_package_price'],
    a['Photo_video_Price'],
    a['Photo_video'],
    a['PhotoVideo_Price'],
    a['PhotoVideoPackage'],
  ]);
  return VendorCardPrice(
    isVenue: false,
    startingPrice: s(_firstTruthy([photoPackage, photoVideoPackage, a['PriceRange'], a['price']])),
  );
}

// ---------------------------------------------------------------------------
// Card fields shared with the map view
// ---------------------------------------------------------------------------

const String kImageNotFound = '/images/imageNotFound.jpg';

String _notUnknown(Object? v) {
  if (v is! String || v.isEmpty) return '';
  return v.toLowerCase() == 'unknown' ? '' : v;
}

/// The subset of `transformApiData` (`useInfiniteScroll.js:62-224`) the map
/// and recently-viewed code need, from a raw vendor-service map.
@immutable
class VendorCardFields {
  const VendorCardFields({
    required this.id,
    required this.name,
    required this.image,
    required this.address,
    required this.area,
    required this.city,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.slug,
    required this.vendorType,
  });

  final Object? id;
  final String name;

  /// First gallery image, or [kImageNotFound] like the web.
  final String image;
  final String address;
  final String area;

  /// Also the web's `location`.
  final String city;
  final double? lat;
  final double? lng;

  /// Raw `attributes.rating || 0`.
  final Object rating;
  final String slug;
  final String vendorType;

  factory VendorCardFields.of(Map service) {
    final a = _map(service['attributes']);
    final vendor = _map(service['vendor']);

    final media = service['media'] is List ? service['media'] as List : const [];
    final portfolio = a['Portfolio'] is String
        ? (a['Portfolio'] as String).split('|').map((u) => u.trim()).where((u) => u.isNotEmpty).toList()
        : const <String>[];
    String? normalize(Object? u) {
      final raw = u is Map ? (u['url'] ?? u['path']) : u;
      if (raw == null || '$raw'.isEmpty) return null;
      final s = '$raw';
      if (RegExp(r'^https?://', caseSensitive: false).hasMatch(s)) return s;
      return '${ApiConfig.apiBase}${s.startsWith('/') ? s : '/$s'}';
    }

    final gallery = (media.isNotEmpty ? media : portfolio).map(normalize).whereType<String>().toList();

    final lat = double.tryParse('${_firstTruthy([a['latitude'], a['Latitude']]) ?? ''}');
    final lng = double.tryParse('${_firstTruthy([a['longitude'], a['Longitude']]) ?? ''}');
    final hasCoords = lat != null && lng != null && !lat.isNaN && !lng.isNaN;

    final city = _notUnknown(a['city']).isNotEmpty ? _notUnknown(a['city']) : _notUnknown(vendor['city']);
    final address =
        _notUnknown(a['address']).isNotEmpty ? _notUnknown(a['address']) : _notUnknown(a['Address']);

    return VendorCardFields(
      id: service['id'],
      name: _js(_firstTruthy([a['vendor_name'], a['Name'], vendor['businessName']]) ?? 'Unknown Vendor'),
      image: gallery.isNotEmpty ? gallery.first : kImageNotFound,
      address: address,
      area: _notUnknown(a['area']),
      city: city,
      lat: hasCoords ? lat : null,
      lng: hasCoords ? lng : null,
      rating: _t(a['rating']) ?? 0,
      slug: _js(_firstTruthy([service['slug'], a['slug']]) ?? ''),
      vendorType: vendorTypeNameOf(service),
    );
  }
}

// ---------------------------------------------------------------------------
// (b) Recently viewed
// ---------------------------------------------------------------------------

/// Port of the web's recently-viewed list (`localStorageService.js:7-68`):
/// stored under `happywedz_recently_viewed`, newest first, max 20, keyed by
/// the vendor-service `id` (the card id — `GridView.jsx:239-248`).
class RecentlyViewedStore {
  RecentlyViewedStore._();
  static final RecentlyViewedStore instance = RecentlyViewedStore._();

  static const String storageKey = 'happywedz_recently_viewed';
  static const int maxItems = 20;

  Future<List<Map<String, dynamic>>> items() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Ids, most recent first (compared as strings so `12` and `"12"` match).
  Future<List<String>> ids() async => (await items()).map((e) => '${e['id']}').toList();

  /// `trackView`: moves/adds [entry] to the front and trims to [maxItems].
  /// [entry] must carry an `id`; `viewed_at` is stamped here. Use
  /// [entryForService] to build it from a raw vendor-service map.
  Future<void> record(Map<String, dynamic> entry) async {
    final id = entry['id'];
    if (id == null) return;
    try {
      final list = await items();
      list.removeWhere((e) => '${e['id']}' == '$id');
      list.insert(0, {...entry, 'viewed_at': DateTime.now().toUtc().toIso8601String()});
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(storageKey, jsonEncode(list.take(maxItems).toList()));
    } catch (e) {
      debugPrint('[RecentlyViewed] record failed: $e');
    }
  }

  /// The entry `GridView.handleCardClick` stores (`GridView.jsx:239-248`).
  static Map<String, dynamic> entryForService(Map service) {
    final f = VendorCardFields.of(service);
    final location = f.city.isNotEmpty ? f.city : (f.address.isNotEmpty ? f.address : null);
    return {
      'id': f.id,
      'name': f.name,
      'category': f.vendorType,
      'type': f.vendorType.isNotEmpty ? f.vendorType : 'vendor',
      'location': location,
      'image': f.image,
      'price_range': vendorCardPrice(service).rawBadge,
      'slug': f.slug.isNotEmpty ? f.slug : f.id,
    };
  }

  /// `prioritizeRecentlyViewed` (`recentlyViewedHelper.js:12-51`): viewed
  /// items first in most-recent-first order, then everything else in its
  /// original order.
  Future<List<Map<String, dynamic>>> sortRecentFirst(List<Map<String, dynamic>> list) async {
    return sortByRecentIds(list, await ids(), (m) => m['id']);
  }

  /// Pure form of [sortRecentFirst] for any item type.
  static List<T> sortByRecentIds<T>(List<T> list, List<String> recentIds, Object? Function(T) idOf) {
    if (list.isEmpty || recentIds.isEmpty) return List<T>.from(list);
    final rank = <String, int>{};
    for (var i = 0; i < recentIds.length; i++) {
      rank.putIfAbsent(recentIds[i], () => i);
    }
    final recent = <T>[];
    final others = <T>[];
    for (final item in list) {
      (rank.containsKey('${idOf(item)}') ? recent : others).add(item);
    }
    // List.sort is not stable; keep ties in input order explicitly.
    final indexed = recent.asMap().entries.toList()
      ..sort((x, y) {
        final c = rank['${idOf(x.value)}']!.compareTo(rank['${idOf(y.value)}']!);
        return c != 0 ? c : x.key.compareTo(y.key);
      });
    return [...indexed.map((e) => e.value), ...others];
  }
}

// ---------------------------------------------------------------------------
// (c) Interactions  (d) Profile view counter
// ---------------------------------------------------------------------------

/// Actions the web records on `/interactions/add`.
enum VendorInteraction { click, wishlist }

/// Fire-and-forget `POST {apiBase}/interactions/add` for a signed-in user
/// (`GridView.jsx:225-270`); silently does nothing without a token and never
/// throws.
Future<void> trackVendorInteraction(Object? serviceId, VendorInteraction action, {http.Client? client}) async {
  if (serviceId == null) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(ApiConfig.authTokenKey) ?? '';
    if (token.isEmpty) return;
    final id = serviceId is num ? serviceId : (int.tryParse('$serviceId') ?? serviceId);
    final c = client ?? http.Client();
    try {
      await c
          .post(
            Uri.parse('${ApiConfig.apiBase}/interactions/add'),
            headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
            body: jsonEncode({'vendor_subcategory_data_id': id, 'action': action.name}),
          )
          .timeout(const Duration(seconds: 15));
    } finally {
      if (client == null) c.close();
    }
  } catch (e) {
    debugPrint('[Interactions] ${action.name} tracking failed: $e');
  }
}

final Set<String> _viewedVendors = <String>{};
final Set<String> _inFlightViews = <String>{};

/// `POST {apiBase}/api/vendor/increment-view/{vendorId}`, at most once per
/// app session per vendor (web: `sessionStorage` key `vendor_viewed_<id>`,
/// set only after the request succeeds — `Detailed.jsx:5575-5607`). No auth
/// header, like the web's bare `axios.post`. Returns the vendor's updated
/// `profileViews` when the server reports it; never throws.
Future<int?> incrementVendorView(Object? vendorId, {http.Client? client}) async {
  final key = '${vendorId ?? ''}'.trim();
  if (key.isEmpty || key == 'null' || key == '0') return null;
  if (_viewedVendors.contains(key) || _inFlightViews.contains(key)) return null;
  _inFlightViews.add(key);
  final c = client ?? http.Client();
  try {
    final res = await c
        .post(Uri.parse('${ApiConfig.apiBase}/api/vendor/increment-view/$key'))
        .timeout(const Duration(seconds: 15));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    _viewedVendors.add(key);
    try {
      final body = jsonDecode(res.body);
      final views = body is Map ? _map(body['vendor'])['profileViews'] : null;
      if (views is num) return views.toInt();
      if (views is String) return int.tryParse(views);
    } catch (_) {}
    return null;
  } catch (e) {
    debugPrint('[IncrementView] failed: $e');
    return null;
  } finally {
    _inFlightViews.remove(key);
    if (client == null) c.close();
  }
}

/// Test hook: forget which vendors were counted this session.
@visibleForTesting
void resetVendorViewSession() {
  _viewedVendors.clear();
  _inFlightViews.clear();
}

// ---------------------------------------------------------------------------
// (e) Venue FAQ (VenueFAQ.jsx)
// ---------------------------------------------------------------------------

@immutable
class VendorFaq {
  const VendorFaq(this.question, this.answer);
  final String question;
  final String answer;

  @override
  String toString() => 'Q: $question\nA: $answer';
}

/// Venue name the FAQ uses (`VenueFAQ.jsx:8-12`); [name] mirrors
/// `activeVendor?.name`.
String vendorFaqVenueName(Map service, {String? name}) {
  final a = _map(service['attributes']);
  return _js(_firstTruthy([name, a['name'], a['vendor_name']]) ?? 'this venue');
}

/// Heading above the FAQ (`VenueFAQ.jsx:165`).
String vendorFaqTitle(Map service, {String? name}) =>
    'Frequently Asked Questions about ${vendorFaqVenueName(service, name: name)}';

/// Up to nine Q&A pairs built from the venue's attributes, exactly as
/// `VenueFAQ.jsx:24-132` builds them. Returns an empty list when fewer than
/// two qualify (the web renders nothing then). [name] / [city] mirror the
/// web's `activeVendor.name` / `activeVendor.location` overrides.
List<VendorFaq> vendorFaqs(Map service, {String? name, String? city}) {
  final attrs = _map(service['attributes']);
  final vm = _map(attrs['venue_master']);
  final vFood = _map(vm['food']);
  final vSpace = _map(vm['space_capacity']);
  final vEnt = _map(vm['entertainment']);
  final vRooms = _map(vm['rooms']);
  final vFac = _map(vm['facilities']);
  final vPricing = _map(vm['pricing_booking']);

  final venueName = vendorFaqVenueName(service, name: name);
  final venueCityRaw = _firstTruthy([city, attrs['city']]);
  final venueCity = venueCityRaw == null ? '' : _js(venueCityRaw);

  final faqs = <VendorFaq>[];

  // 1. Price per plate / starting price
  final vegStartingPrice = _firstTruthy([attrs['veg_starting_price'], vFood['per_plate_cost_range']]);
  final generalStartingPrice = _firstTruthy([attrs['starting_price'], vPricing['starting_venue_price']]);
  if (vegStartingPrice != null || generalStartingPrice != null) {
    final priceText = vegStartingPrice != null
        ? '₹${_js(vegStartingPrice)} per plate for vegetarian menus'
        : 'starting price of ₹${_js(generalStartingPrice)}';
    faqs.add(VendorFaq(
      'What is the price per plate at $venueName?',
      '$venueName${venueCity.isNotEmpty ? ' in $venueCity' : ''} starts at $priceText.',
    ));
  }

  // 2. Guest capacity
  final seatingCap = _firstTruthy([vSpace['indoor_seating'], attrs['area']]);
  final maxGuests = _t(vSpace['max_guests']);
  if (seatingCap != null || maxGuests != null) {
    final String capText;
    if (seatingCap != null && maxGuests != null) {
      capText = 'accommodate seating for ${_js(seatingCap)} and up to ${_js(maxGuests)} total guests';
    } else if (seatingCap != null) {
      capText = 'accommodate ${_js(seatingCap)}';
    } else {
      capText = 'accommodate up to ${_js(maxGuests)} guests';
    }
    faqs.add(VendorFaq('How many guests can $venueName accommodate?', '$venueName can $capText.'));
  }

  // 3. Non-veg food policy
  final vegNonVeg = _firstTruthy([vFood['veg_non_veg'], attrs['veg_non_veg']]);
  if (vegNonVeg != null) {
    final text = _js(vegNonVeg);
    final lower = text.toLowerCase();
    final isPureVeg = lower.contains('pure veg') || lower == 'veg';
    faqs.add(VendorFaq(
      'Is non-veg food allowed at $venueName?',
      isPureVeg
          ? 'No, $venueName is a pure vegetarian venue.'
          : 'Yes, non-vegetarian food options are available at $venueName ($text).',
    ));
  }

  // 4. Outside catering policy
  final cateringPolicy = _firstTruthy([vFood['catering_policy'], attrs['catering_policy']]);
  if (cateringPolicy != null) {
    faqs.add(VendorFaq(
      'Is outside catering allowed at $venueName?',
      'Catering policy at $venueName: ${_js(cateringPolicy)}.',
    ));
  }

  // 5. Outside DJ policy
  final djPolicy = _firstTruthy([vEnt['dj_policy'], attrs['dJ_policy'], attrs['dj_policy']]);
  if (djPolicy != null) {
    faqs.add(VendorFaq(
      'Is outside DJ allowed at $venueName?',
      'DJ policy at $venueName: ${_js(djPolicy)}.',
    ));
  }

  // 6. Rooms available
  final roomCount = _firstTruthy([vRooms['num_rooms'], attrs['rooms']]);
  if (roomCount != null && roomCount != '0') {
    faqs.add(VendorFaq(
      'Are rooms available at $venueName?',
      'Yes, $venueName offers ${_js(roomCount)} rooms for guests and bridal party stay.',
    ));
  }

  // 7. Parking
  final parkingInfo = _t(_firstTruthy([vFac['parking'], attrs['parking']]));
  final parkingCap = _t(vFac['parking_capacity']);
  if (parkingInfo != null || parkingCap != null) {
    final parkDetails = parkingCap != null
        ? '${parkingInfo != null ? _js(parkingInfo) : 'Available'} (Capacity: ${_js(parkingCap)} vehicles)'
        : _js(parkingInfo);
    faqs.add(VendorFaq('Is parking available at $venueName?', 'Parking at $venueName: $parkDetails.'));
  }

  // 8. Time slots
  final slots = _firstTruthy([attrs['slots'], vPricing['min_booking_duration']]);
  if (slots != null) {
    final slotText = slots is List ? slots.map((e) => e == null ? '' : _js(e)).join(', ') : _js(slots);
    faqs.add(VendorFaq(
      'What are the available time slots at $venueName?',
      'Available booking slots/duration at $venueName: $slotText.',
    ));
  }

  // 9. Booking advance
  final advance = _firstTruthy([vPricing['advance_payment_range'], attrs['advance_booking']]);
  if (advance != null) {
    faqs.add(VendorFaq(
      'How much is the booking advance at $venueName?',
      'The advance payment required for booking $venueName is ${_js(advance)}.',
    ));
  }

  if (faqs.length < 2) return const [];
  return faqs;
}
