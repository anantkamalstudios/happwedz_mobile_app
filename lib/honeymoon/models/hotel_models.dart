/// Models for the hotel booking funnel — everything between picking a hotel
/// from the results and holding a confirmed voucher.
///
/// Search-level models (`HotelResult`, `HotelSearchQuery`) live in
/// `honeymoon_models.dart`; the shared booking plumbing (payment, outcome,
/// My trips rows) lives in `booking_models.dart`. What is here is specific to
/// the TripJack hotel flow the web client drives from
/// `src/components/pages/Travels/hotelbeds/`:
///
/// ```
/// hotels/detail          → HotelRoomOption      (one bookable room + rate)
/// hotels/static-content  → HotelStaticContent   (photos, policies, rooms)
/// hotels/review          → HotelReview          (final price, compliance)
/// hotels/booking-details → HotelBookingStatus   (order status + display)
/// ```
///
/// Every parser mirrors the web's `hotelbedsDetailHelpers.js` field-for-field
/// and was checked against live responses, which arrive in two shapes: the
/// v3 "official" shape (`options[].pricing.totalPrice`, `roomInfo[].name`) and
/// the legacy one the backend still mirrors (`ops[].tp`, `ris[].srn`). Both are
/// read, v3 first.
library;

import 'dart:convert';
import 'dart:math' as math;

import 'honeymoon_models.dart';

// ---------------------------------------------------------------------------
// Small shared helpers
// ---------------------------------------------------------------------------

/// Parses a string that should hold a JSON object; null when it does not.
///
/// TripJack stores several policy blocks and the whole `descriptions.default`
/// as stringified JSON, so this is needed in more than one place.
Map<String, dynamic>? _parseJsonObject(dynamic value) {
  if (value is Map) return asJsonMap(value);
  if (value is! String || value.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(value);
    return decoded is Map ? asJsonMap(decoded) : null;
  } catch (_) {
    return null;
  }
}

String _collapseSpaces(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Suppliers shout place names ("BHAVANI NAGAR"). Mixed case is left alone,
/// and short all-caps tokens ("NCR", "UK") keep their capitals — the same rule
/// as the web's `toTitleCase`.
String supplierTitleCase(String value) {
  final text = value.trim();
  if (text.isEmpty || text != text.toUpperCase()) return text;
  return text.toLowerCase().replaceAllMapped(
    RegExp(r'\b[a-z]'),
    (m) => m.group(0)!.toUpperCase(),
  );
}

List<String> _dedupe(Iterable<String> values) {
  final seen = <String>{};
  final out = <String>[];
  for (final raw in values) {
    final value = raw.trim();
    if (value.isEmpty || !seen.add(value.toLowerCase())) continue;
    out.add(value);
  }
  return out;
}

/// Amenity maps come keyed by index (`{"0": {...}, "1": {...}}`) as often as
/// they come as lists; both are flattened to names.
List<String> _namesOf(dynamic value) {
  final items = value is Map ? value.values.toList() : asList(value);
  return items
      .map(
        (item) => item is String
            ? item
            : firstNonEmpty([readKey(item, 'name'), readKey(item, 'nm')]),
      )
      .where((name) => name.isNotEmpty)
      .toList();
}

/// The best URL an image entry carries, whichever of the four shapes it uses.
String _imageUrl(dynamic image) {
  if (image is String) return image;
  return firstNonEmpty([
    readKey(image, 'url'),
    readKey(image, 'imageUrl'),
    readKey(image, 'path'),
    digPath(image, ['links', 'original', 'href']),
    digPath(image, ['links', 'Original', 'href']),
    digPath(image, ['links', 'Standard', 'href']),
    digPath(image, ['links', 'XXL', 'href']),
    digPath(image, ['links', 0, 'url']),
  ]);
}

/// Image list with the property's cover photo first.
///
/// TripJack flags it with `is_hero_image`/`isHero` and it is rarely at index 0,
/// so reading the list as-is opened galleries on a bathroom.
List<String> _orderedImages(dynamic images) {
  final list = asList(images);
  final hero = list.where(
    (i) => readKey(i, 'is_hero_image') == true || readKey(i, 'isHero') == true,
  );
  return _dedupe([...hero.map(_imageUrl), ...list.map(_imageUrl)]);
}

double _round2(double value) => (value * 100).roundToDouble() / 100;

// ---------------------------------------------------------------------------
// Cancellation and pricing
// ---------------------------------------------------------------------------

/// One slab of a cancellation policy: cancelling between [from] and [to]
/// costs [amount].
class HotelPenalty {
  const HotelPenalty({this.from = '', this.to = '', this.amount});

  final String from;
  final String to;

  /// Null when the supplier gave a slab without a figure ("as per policy").
  final double? amount;

  DateTime? get fromDate => DateTime.tryParse(from);
  DateTime? get toDate => DateTime.tryParse(to);

  /// Reads either `penalties[{from,to,amount}]` or the legacy
  /// `pd[{fdt,tdt,am}]`, the two shapes the web's `getCancellationPenalties`
  /// accepts.
  static List<HotelPenalty> listFrom(dynamic cancellation) {
    final v3 = asList(readKey(cancellation, 'penalties'));
    final legacy = asList(readKey(cancellation, 'pd'));
    final source = v3.isNotEmpty ? v3 : legacy;
    return source.map((p) {
      final rawAmount =
          readKey(p, 'amount') ?? readKey(p, 'am') ?? readKey(p, 'charge');
      return HotelPenalty(
        from: firstNonEmpty([
          readKey(p, 'from'),
          readKey(p, 'fdt'),
          readKey(p, 'fromDate'),
        ]),
        to: firstNonEmpty([
          readKey(p, 'to'),
          readKey(p, 'tdt'),
          readKey(p, 'toDate'),
        ]),
        amount: rawAmount == null ? null : asDouble(rawAmount),
      );
    }).toList();
  }
}

/// How a room's price is built — the web's fare-breakup panel.
class HotelPricing {
  const HotelPricing({
    this.total = 0,
    this.base = 0,
    this.discount = 0,
    this.taxes = 0,
    this.managementFee = 0,
    this.managementFeeTax = 0,
    this.gstClaimable = 0,
    this.strikethrough,
    this.currency = 'INR',
    this.commission = 0,
    this.commissionType = '',
  });

  final double total;
  final double base;
  final double discount;
  final double taxes;
  final double managementFee;
  final double managementFeeTax;
  final double gstClaimable;
  final double? strikethrough;
  final String currency;

  /// `option.commercial` — the rate plan (`NET`…) and any commission on it.
  final double commission;
  final String commissionType;

  /// Everything above the base fare. The difference is preferred over the
  /// sum of parts so the lines always add up, even when a supplier adds a fee
  /// component nobody has mapped yet — `normalizeReviewResponseForUi` does
  /// the same.
  double get taxesAndFees => total > 0 && base > 0
      ? _round2(total - base)
      : taxes + managementFee + managementFeeTax;

  /// What is left of taxes & fees once the management fee and its tax are
  /// taken out — the web labels it "Markup".
  double get markup =>
      math.max(0, _round2(taxesAndFees - managementFee - managementFeeTax));

  /// `pricing` (v3) first, then the legacy `tfcs` codes.
  factory HotelPricing.fromOption(dynamic option) {
    final pricing = readKey(option, 'pricing');
    final tfcs = readKey(option, 'tfcs');
    final strike = readKey(pricing, 'strikethrough');
    final commercial = readKey(option, 'commercial');
    return HotelPricing(
      commission: asDouble(readKey(commercial, 'commission')),
      commissionType: asString(readKey(commercial, 'type')),
      total: asDouble(
        readKey(pricing, 'totalPrice') ??
            readKey(option, 'totalPrice') ??
            readKey(option, 'tp') ??
            readKey(tfcs, 'TF'),
      ),
      base: asDouble(readKey(pricing, 'basePrice') ?? readKey(tfcs, 'BF')),
      discount: asDouble(readKey(pricing, 'discount')),
      taxes: asDouble(readKey(pricing, 'taxes') ?? readKey(tfcs, 'TAF')),
      managementFee: asDouble(readKey(pricing, 'mf') ?? readKey(tfcs, 'MF')),
      managementFeeTax: asDouble(
        readKey(pricing, 'mft') ?? readKey(tfcs, 'MFT'),
      ),
      gstClaimable: asDouble(readKey(pricing, 'gstClaimableAmount')),
      strikethrough: strike == null ? null : asDouble(strike),
      currency: firstNonEmpty([
        readKey(pricing, 'currency'),
        readKey(option, 'currency'),
        readKey(option, 'sc'),
      ], fallback: 'INR'),
    );
  }
}

// ---------------------------------------------------------------------------
// Policy notes
// ---------------------------------------------------------------------------

/// A labelled policy line ("Know before you go: …").
class HotelPolicyNote {
  const HotelPolicyNote({this.label = '', required this.text});

  final String label;
  final String text;

  static List<HotelPolicyNote> _entries(Map<String, dynamic> map) => [
    for (final e in map.entries)
      if (_collapseSpaces(asString(e.value)).isNotEmpty)
        HotelPolicyNote(
          label: e.key.replaceAll('_', ' ').trim(),
          text: _collapseSpaces(asString(e.value)),
        ),
  ];

  /// `special_instructions`, `know_before_you_go` and `mandatory_fees` arrive
  /// as stringified `{label: text}` objects; plain strings are kept as-is.
  /// Mirrors the web's `parsePolicyEntries`.
  static List<HotelPolicyNote> fromPolicyField(dynamic value) {
    final parsed = _parseJsonObject(value);
    if (parsed != null) return _entries(parsed);
    final text = _collapseSpaces(asString(value));
    return text.isEmpty ? const [] : [HotelPolicyNote(text: text)];
  }

  /// The review's `option.inclusions` is those same JSON objects *split on
  /// every comma* by the supplier, so fragments are re-joined until they parse
  /// again. Mirrors the web's `parseReviewInclusions`.
  static List<HotelPolicyNote> fromInclusions(dynamic inclusions) {
    final out = <HotelPolicyNote>[];
    var buffer = '';
    for (final entry in asList(inclusions)) {
      final text = asString(entry);
      if (text.isEmpty) continue;
      buffer = buffer.isEmpty ? text : '$buffer, $text';
      final parsed = _parseJsonObject(buffer);
      if (parsed != null) {
        out.addAll(_entries(parsed));
        buffer = '';
      }
    }
    // Anything that never closed is shown as plain text rather than dropped.
    if (buffer.isNotEmpty) {
      final text = _collapseSpaces(buffer.replaceAll(RegExp(r'^\{|\}$'), ''));
      if (text.isNotEmpty) out.add(HotelPolicyNote(text: text));
    }
    return out;
  }
}

// ---------------------------------------------------------------------------
// Static content (POST hotels/static-content)
// ---------------------------------------------------------------------------

/// A room as the static catalogue describes it — photos, beds, occupancy.
/// Matched to a priced option by id, then by name.
class HotelStaticRoom {
  const HotelStaticRoom({
    this.id = '',
    this.name = '',
    this.images = const [],
    this.amenities = const [],
    this.bedSummary = '',
    this.guestSummary = '',
  });

  final String id;
  final String name;
  final List<String> images;
  final List<String> amenities;
  final String bedSummary;
  final String guestSummary;

  factory HotelStaticRoom.fromJson(dynamic json) {
    // Hero first, then images captioned "Room", then supplier order.
    final raw = [
      ...asList(readKey(json, 'images')),
      ...asList(readKey(json, 'img')),
    ];
    int rank(dynamic image) {
      if (readKey(image, 'is_hero_image') == true ||
          readKey(image, 'isHero') == true) {
        return 0;
      }
      return asString(readKey(image, 'caption')).toLowerCase() == 'room'
          ? 1
          : 2;
    }

    final indexed = [for (var i = 0; i < raw.length; i++) (i, raw[i])]
      ..sort((a, b) {
        final byRank = rank(a.$2).compareTo(rank(b.$2));
        return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
      });

    return HotelStaticRoom(
      id: firstNonEmpty([
        readKey(json, 'id'),
        readKey(json, 'rid'),
        readKey(json, 'roomId'),
      ]),
      name: asString(readKey(json, 'name')),
      images: _dedupe(indexed.map((e) => _imageUrl(e.$2))),
      amenities: _dedupe([
        ..._namesOf(readKey(json, 'amenities')),
        ..._namesOf(readKey(json, 'facilities')),
      ]),
      bedSummary: _bedSummary(readKey(json, 'bed_config')),
      guestSummary: _guestSummary(digPath(json, ['occupancy', 'max_allowed'])),
    );
  }

  static String _bedSummary(dynamic config) {
    final description = asString(readKey(config, 'description'));
    if (description.isNotEmpty) return description;

    final configuration = readKey(config, 'configuration');
    if (configuration is Map) {
      final parts = configuration.values
          .map((bed) {
            final quantity = asInt(
              readKey(bed, 'quantity') ??
                  readKey(bed, 'count') ??
                  readKey(bed, 'bed_count'),
            );
            final label = firstNonEmpty([
              readKey(bed, 'type'),
              readKey(bed, 'name'),
              readKey(bed, 'size'),
            ]);
            if (label.isEmpty && quantity <= 0) return '';
            return quantity <= 0
                ? label
                : '$quantity ${label.isEmpty ? 'Bed' : label}';
          })
          .where((s) => s.isNotEmpty);
      if (parts.isNotEmpty) return parts.join(', ');
    }

    return asList(readKey(config, 'bed_types'))
        .map((bed) {
          final count = asInt(
            readKey(bed, 'count') ?? readKey(bed, 'bed_count'),
            fallback: 1,
          );
          final name = firstNonEmpty([
            readKey(bed, 'name'),
            readKey(bed, 'type'),
          ], fallback: 'Bed');
          return '$count $name';
        })
        .join(', ');
  }

  static String _guestSummary(dynamic max) {
    final total = asInt(readKey(max, 'total'));
    final adults = asInt(readKey(max, 'adults'));
    final children = asInt(readKey(max, 'children'));
    if (total > 0) return 'Fits max. $total guest${total > 1 ? 's' : ''}';
    return [
      if (adults > 0) '$adults adult${adults > 1 ? 's' : ''}',
      if (children > 0) '$children child${children > 1 ? 'ren' : ''}',
    ].join(' • ');
  }
}

/// Descriptive content for one property.
class HotelStaticContent {
  const HotelStaticContent({
    this.images = const [],
    this.headline = '',
    this.aboutSections = const [],
    this.amenities = const [],
    this.amenityGroups = const [],
    this.checkInFrom = '',
    this.checkInTill = '',
    this.checkOutFrom = '',
    this.checkOutTill = '',
    this.minCheckInAge = '',
    this.specialInstructions = const [],
    this.knowBeforeYouGo = const [],
    this.mandatoryFees = const [],
    this.propertyType = '',
    this.phone = '',
    this.chain = '',
    this.brand = '',
    this.starRating = 0,
    this.address = '',
    this.city = '',
    this.postalCode = '',
    this.latitude,
    this.longitude,
    this.rooms = const [],
  });

  static const HotelStaticContent empty = HotelStaticContent();

  final List<String> images;
  final String headline;

  /// "About this property" sections, in the web's order, empty ones dropped.
  final List<({String title, String body})> aboutSections;

  final List<String> amenities;
  final List<({String title, List<String> items})> amenityGroups;

  final String checkInFrom;
  final String checkInTill;
  final String checkOutFrom;
  final String checkOutTill;
  final String minCheckInAge;

  final List<HotelPolicyNote> specialInstructions;
  final List<HotelPolicyNote> knowBeforeYouGo;
  final List<HotelPolicyNote> mandatoryFees;

  final String propertyType;
  final String phone;
  final String chain;
  final String brand;
  final double starRating;
  final String address;
  final String city;
  final String postalCode;
  final double? latitude;
  final double? longitude;
  final List<HotelStaticRoom> rooms;

  bool get hasImportantInfo =>
      specialInstructions.isNotEmpty ||
      knowBeforeYouGo.isNotEmpty ||
      mandatoryFees.isNotEmpty;

  bool get hasStayTimes => checkInFrom.isNotEmpty || checkOutFrom.isNotEmpty;

  /// The first readable paragraph, for the collapsed "About" block.
  String get aboutText => aboutSections.isEmpty ? '' : aboutSections.first.body;

  static const _sectionOrder = <(String, String)>[
    ('location', 'Location'),
    ('amenities', 'Amenities'),
    ('rooms', 'Rooms'),
    ('dining', 'Dining'),
    ('business_amenities', 'Business amenities'),
    ('attractions', 'Nearby attractions'),
    ('onsite_payments', 'Payments accepted'),
    ('spoken_languages', 'Languages spoken'),
  ];

  /// `{status, hotels:[...]}`; the entry whose id matches [hotelId] wins, the
  /// first one otherwise — as in the web's `normalizeHotelDetails`.
  factory HotelStaticContent.fromResponse(dynamic json, {String hotelId = ''}) {
    final hotels = json is List
        ? json
        : asList(readKey(json, 'hotels') ?? digPath(json, ['data', 'hotels']));
    if (hotels.isEmpty) return HotelStaticContent.empty;

    final match = hotels.firstWhere(
      (h) =>
          hotelId.isNotEmpty &&
          firstNonEmpty([
                readKey(h, 'tjHotelId'),
                readKey(h, 'tjHotelID'),
                readKey(h, 'hotelId'),
                readKey(h, 'id'),
              ]) ==
              hotelId,
      orElse: () => hotels.first,
    );
    return HotelStaticContent.fromHotel(match);
  }

  /// One static hotel record.
  factory HotelStaticContent.fromHotel(dynamic hotel) {
    final descriptions = readKey(hotel, 'descriptions');
    final packed =
        _parseJsonObject(readKey(descriptions, 'default')) ??
        _parseJsonObject(readKey(hotel, 'description')) ??
        const <String, dynamic>{};
    String section(String key) => _collapseSpaces(
      firstNonEmpty([readKey(descriptions, key), packed[key]]),
    );

    final times = digPath(hotel, ['policies', 'checkInCheckOut']);
    final policies = readKey(hotel, 'policies');
    final address = digPath(hotel, ['locale', 'address']);
    final coords = digPath(hotel, ['locale', 'coordinates']);

    final groups = asList(readKey(hotel, 'tja'))
        .map(
          (g) => (
            title: asString(readKey(g, 'catg')),
            items: asList(readKey(g, 'am'))
                .map((a) {
                  final name = asString(readKey(a, 'name'));
                  final sub = asString(readKey(a, 'subA'));
                  return sub.isEmpty ? name : '$name ($sub)';
                })
                .where((s) => s.isNotEmpty)
                .toList(),
          ),
        )
        .where((g) => g.title.isNotEmpty && g.items.isNotEmpty)
        .toList();
    final flatAmenities = _namesOf(readKey(hotel, 'amenities'));

    final rooms = readKey(hotel, 'rooms');
    final roomEntries = rooms is Map ? rooms.values.toList() : asList(rooms);

    String firstOf(dynamic list) {
      final items = asList(list);
      return items.isEmpty ? '' : asString(items.first);
    }

    return HotelStaticContent(
      images: _orderedImages(readKey(hotel, 'images')),
      // descriptions.headline repeats the long location blurb; the short
      // locality line lives inside descriptions.default, so that one wins.
      headline: firstNonEmpty([
        packed['headline'],
        readKey(descriptions, 'headline'),
      ]),
      aboutSections: [
        for (final (key, title) in _sectionOrder)
          if (section(key).isNotEmpty) (title: title, body: section(key)),
      ],
      amenities: _dedupe([
        ...groups.expand((g) => g.items),
        ...flatAmenities,
        ..._namesOf(readKey(hotel, 'facilities')),
      ]),
      amenityGroups: groups.isNotEmpty
          ? groups
          : flatAmenities.isNotEmpty
          ? [(title: 'Hotel amenities', items: _dedupe(flatAmenities))]
          : const [],
      checkInFrom: asString(readKey(times, 'checkin_from')),
      checkInTill: asString(readKey(times, 'checkin_till')),
      checkOutFrom: asString(readKey(times, 'checkout_from')),
      checkOutTill: asString(readKey(times, 'checkout_till')),
      minCheckInAge: asString(readKey(times, 'checkin_min_age')),
      specialInstructions: HotelPolicyNote.fromPolicyField(
        readKey(policies, 'special_instructions') ??
            readKey(hotel, 'checkInInstructions'),
      ),
      knowBeforeYouGo: HotelPolicyNote.fromPolicyField(
        readKey(policies, 'know_before_you_go') ??
            readKey(hotel, 'knowBeforeYouGo'),
      ),
      mandatoryFees: HotelPolicyNote.fromPolicyField(
        readKey(policies, 'mandatory_fees') ?? readKey(hotel, 'mandatoryFees'),
      ),
      propertyType: asString(digPath(hotel, ['property_type', 'name'])),
      phone: firstOf(digPath(hotel, ['locale', 'phone'])),
      chain: asString(digPath(hotel, ['chain', 'name'])),
      brand: asString(digPath(hotel, ['chain', 'brand', 'name'])),
      starRating: asDouble(readKey(hotel, 'star_rating')),
      address: [
        asString(readKey(address, 'line_1')),
        asString(readKey(address, 'line_2')),
      ].where((s) => s.isNotEmpty).join(', '),
      city: supplierTitleCase(asString(readKey(address, 'city'))),
      postalCode: asString(readKey(address, 'postal_code')),
      latitude: readKey(coords, 'lat') == null
          ? null
          : asDouble(readKey(coords, 'lat')),
      longitude: readKey(coords, 'long') == null
          ? null
          : asDouble(readKey(coords, 'long')),
      rooms: roomEntries.map(HotelStaticRoom.fromJson).toList(),
    );
  }

  /// The static room describing [option], matched by id, then exact name,
  /// then a loose name ("Royal Deluxe Room" ≈ "Royal Deluxe").
  HotelStaticRoom? roomFor(HotelRoomOption option) {
    if (rooms.isEmpty) return null;
    final id = option.roomId;
    final name = option.name.toLowerCase().trim();
    final loose = _looseRoomKey(option.name);

    for (final room in rooms) {
      if (id.isNotEmpty && room.id == id) return room;
    }
    for (final room in rooms) {
      if (room.name.toLowerCase().trim() == name) return room;
    }
    if (loose.isEmpty) return null;
    for (final room in rooms) {
      final key = _looseRoomKey(room.name);
      if (key.isEmpty) continue;
      if (key == loose || key.contains(loose) || loose.contains(key)) {
        return room;
      }
    }
    return null;
  }

  static String _looseRoomKey(String value) => value
      .toLowerCase()
      .replaceAll(
        RegExp(
          r'\b(room|rooms|double|twin|king|queen|single|bed|non-?smoking|smoking|with|or)\b',
        ),
        ' ',
      )
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

// ---------------------------------------------------------------------------
// Room option (POST hotels/detail)
// ---------------------------------------------------------------------------

/// One room line inside an option — an option can bundle several rooms.
class HotelRoomLine {
  const HotelRoomLine({
    this.id = '',
    this.name = '',
    this.adults = 0,
    this.children = 0,
    this.mealPlan = '',
  });

  final String id;
  final String name;
  final int adults;
  final int children;
  final String mealPlan;

  /// `roomInfo[{id,name,adults,children}]` (v3) or
  /// `roomInfos/ris[{id,srn,rt,rc,adt,chd}]` (legacy).
  factory HotelRoomLine.fromJson(dynamic json) => HotelRoomLine(
    id: firstNonEmpty([
      readKey(json, 'id'),
      readKey(json, 'rid'),
      readKey(json, 'roomId'),
    ]),
    name: firstNonEmpty([
      readKey(json, 'name'),
      readKey(json, 'srn'),
      readKey(json, 'rt'),
      readKey(json, 'rc'),
    ]),
    adults: asInt(readKey(json, 'adults') ?? readKey(json, 'adt')),
    children: asInt(readKey(json, 'children') ?? readKey(json, 'chd')),
    mealPlan: asString(readKey(json, 'mb')),
  );
}

/// One bookable room + rate from `hotels/detail`.
///
/// The display fields are only half of what this carries: [optionId] and
/// [raw] are what the review call needs to price this exact room, and without
/// them a room can be shown but never booked.
class HotelRoomOption {
  const HotelRoomOption({
    required this.name,
    this.optionId = '',
    this.mealPlan = '',
    this.cancellation = '',
    this.price = 0,
    this.refundable,
    this.raw = const <String, dynamic>{},
    this.rooms = const [],
    this.pricing = const HotelPricing(),
    this.penalties = const [],
    this.panRequired = false,
    this.passportRequired = false,
    this.inclusions = const [],
    this.deadline = '',
    this.images = const [],
    this.amenities = const [],
    this.bedSummary = '',
    this.guestSummary = '',
  });

  final String name;

  /// `option.optionId` — identifies this room+rate to the supplier.
  final String optionId;

  final String mealPlan;

  /// One-line summary of the cancellation terms, e.g. "Free cancellation
  /// till 16 Oct 2026". Derived from [penalties]; kept as text so a card can
  /// show it without knowing the slab structure.
  final String cancellation;

  final double price;
  final bool? refundable;
  final Map<String, dynamic> raw;

  final List<HotelRoomLine> rooms;
  final HotelPricing pricing;
  final List<HotelPenalty> penalties;
  final bool panRequired;
  final bool passportRequired;
  final List<String> inclusions;

  /// Last moment the booking can be held/cancelled free, when given.
  final String deadline;

  // Filled from static content — see [withStatic].
  final List<String> images;
  final List<String> amenities;
  final String bedSummary;
  final String guestSummary;

  bool get isBookable => optionId.isNotEmpty;

  String get roomId => rooms.isEmpty ? '' : rooms.first.id;

  bool get includesBreakfast => mealPlan.toLowerCase().contains('breakfast');

  String get cancellationLabel => refundable == true
      ? 'Refundable'
      : refundable == false
      ? 'Non-refundable'
      : 'Cancellation policy';

  factory HotelRoomOption.fromJson(dynamic json) {
    final roomSource = asList(
      readKey(json, 'roomInfo') ??
          readKey(json, 'roomInfos') ??
          readKey(json, 'ris') ??
          readKey(json, 'rooms'),
    );
    final rooms = roomSource.map(HotelRoomLine.fromJson).toList();
    final first = rooms.isEmpty ? const HotelRoomLine() : rooms.first;

    final cancellation = readKey(json, 'cancellation') ?? readKey(json, 'cnp');
    final penalties = HotelPenalty.listFrom(cancellation);
    final refundableRaw =
        readKey(cancellation, 'isRefundable') ??
        readKey(cancellation, 'ifra') ??
        readKey(json, 'isRefundable') ??
        readKey(json, 'refundable');
    final bool? refundable = refundableRaw is bool
        ? refundableRaw
        : readKey(cancellation, 'inra') == true
        ? false
        : null;

    final pricing = HotelPricing.fromOption(json);
    final compliance = readKey(json, 'compliance');

    return HotelRoomOption(
      name: firstNonEmpty([
        first.name,
        readKey(json, 'roomTypeName'),
        readKey(json, 'name'),
      ], fallback: 'Room'),
      optionId: firstNonEmpty([
        readKey(json, 'optionId'),
        readKey(json, 'id'),
        readKey(json, 'oid'),
      ]),
      mealPlan: firstNonEmpty([
        readKey(json, 'mealBasis'),
        readKey(json, 'mb'),
        first.mealPlan,
      ], fallback: 'Room Only'),
      cancellation: _summarise(refundable, penalties),
      price: pricing.total,
      refundable: refundable,
      raw: asJsonMap(json),
      rooms: rooms,
      pricing: pricing,
      penalties: penalties,
      panRequired:
          readKey(compliance, 'panRequired') == true ||
          readKey(json, 'ipr') == true,
      passportRequired:
          readKey(compliance, 'passportRequired') == true ||
          readKey(json, 'ipm') == true,
      inclusions: asList(
        readKey(json, 'inclusions'),
      ).map(asString).where((s) => s.isNotEmpty).toList(),
      deadline: firstNonEmpty([
        readKey(json, 'deadlineDateTime'),
        readKey(json, 'ddt'),
      ]),
    );
  }

  /// This option with photos, beds, occupancy and amenities taken from the
  /// static catalogue. Falls back to [fallbackImages] (the property's own
  /// gallery) when the room has none, as the web does.
  HotelRoomOption withStatic(
    HotelStaticContent content, {
    List<String> fallbackImages = const [],
  }) {
    final room = content.roomFor(this);
    return HotelRoomOption(
      name: name,
      optionId: optionId,
      mealPlan: mealPlan,
      cancellation: cancellation,
      price: price,
      refundable: refundable,
      raw: raw,
      rooms: rooms,
      pricing: pricing,
      penalties: penalties,
      panRequired: panRequired,
      passportRequired: passportRequired,
      inclusions: inclusions,
      deadline: deadline,
      images: room != null && room.images.isNotEmpty
          ? room.images
          : fallbackImages,
      amenities: room?.amenities ?? const [],
      bedSummary: room?.bedSummary ?? '',
      guestSummary: room?.guestSummary ?? '',
    );
  }

  static String _summarise(bool? refundable, List<HotelPenalty> penalties) {
    if (refundable == false) return 'Non-refundable';
    final free = penalties.where((p) => (p.amount ?? -1) == 0).toList();
    if (free.isNotEmpty) {
      final till = free.last.toDate;
      if (till != null) return 'Free cancellation till ${_shortDate(till)}';
      return 'Free cancellation';
    }
    return refundable == true ? 'Refundable (charges may apply)' : '';
  }

  static String _shortDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  /// Every option in a `hotels/detail` response.
  ///
  /// The backend answers with the v3 `options[]` at the top level and mirrors
  /// it as legacy `hotelInfo.ops[]`; older deployments only had the nested
  /// `searchResult.hotelInfos[0].ops`. The first non-empty one wins.
  static List<HotelRoomOption> listFromDetail(dynamic detail) {
    final candidates = [
      readKey(detail, 'options'),
      digPath(detail, ['data', 'options']),
      digPath(detail, ['hotelInfo', 'ops']),
      digPath(detail, ['hotel', 'ops']),
      digPath(detail, ['searchResult', 'hotelInfos', 0, 'ops']),
      digPath(detail, ['data', 'searchResult', 'hotelInfos', 0, 'ops']),
      readKey(detail, 'ops'),
    ];
    for (final c in candidates) {
      final list = asList(c);
      if (list.isEmpty) continue;
      return list
          .map(HotelRoomOption.fromJson)
          .where((o) => o.optionId.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

// ---------------------------------------------------------------------------
// Review (POST hotels/review)
// ---------------------------------------------------------------------------

/// The supplier's answer to "can I still book this room at this price?".
///
/// Live responses come back raw — `{bookingId, hotelId, hotelName, option,
/// onholdAllowed}` — while some cached ones carry the web's normalised UI
/// shape (`priceSummary`, `selectedOption`, `bookingRequirements`). Both are
/// read; `normalizeReviewResponseForUi` does the same on the web.
class HotelReview {
  const HotelReview({
    required this.bookingId,
    required this.option,
    this.hotelId = '',
    this.hotelName = '',
    this.amount = 0,
    this.baseFare = 0,
    this.taxesAndFees = 0,
    this.managementFee = 0,
    this.managementFeeTax = 0,
    this.currency = 'INR',
    this.panRequired = false,
    this.passportRequired = false,
    this.onholdAllowed = false,
    this.deadline = '',
    this.policyNotes = const [],
    this.importantNotes = const [],
    this.raw = const <String, dynamic>{},
  });

  final String bookingId;
  final HotelRoomOption option;
  final String hotelId;
  final String hotelName;

  /// The payable total. The booking is rejected if a different figure is sent.
  final double amount;
  final double baseFare;
  final double taxesAndFees;
  final double managementFee;
  final double managementFeeTax;
  final String currency;

  final bool panRequired;
  final bool passportRequired;

  /// The supplier allows "Hold & confirm" for this rate.
  final bool onholdAllowed;
  final String deadline;

  /// The booked option's own policies (`option.inclusions`).
  final List<HotelPolicyNote> policyNotes;

  /// `bookingConditions` values and `alerts` messages, capped at eight.
  final List<String> importantNotes;

  final Map<String, dynamic> raw;

  bool? get refundable => option.refundable;

  /// Whatever is not the management fee or its tax is the markup.
  double get markup =>
      math.max(0, _round2(taxesAndFees - managementFee - managementFeeTax));

  factory HotelReview.fromJson(dynamic json) {
    final optionJson =
        readKey(json, 'option') ?? readKey(json, 'selectedOption') ?? const {};
    final option = HotelRoomOption.fromJson(optionJson);
    final summary = readKey(json, 'priceSummary');
    final requirements = readKey(json, 'bookingRequirements');

    // A valid backend priceSummary wins; otherwise the option's own pricing.
    final hasSummary = asDouble(readKey(summary, 'amount')) > 0;
    final pricing = option.pricing;

    final notes = <String>[];
    final conditions = readKey(json, 'bookingConditions');
    if (conditions is Map) {
      for (final value in conditions.values) {
        if (value is List) {
          notes.addAll(value.map(asString).where((s) => s.isNotEmpty));
        } else if (asString(value).isNotEmpty) {
          notes.add(asString(value));
        }
      }
    }
    for (final alert in asList(readKey(json, 'alerts'))) {
      final message = alert is String
          ? alert
          : firstNonEmpty([readKey(alert, 'message'), readKey(alert, 'msg')]);
      if (message.isNotEmpty) notes.add(message);
    }

    return HotelReview(
      bookingId: asString(readKey(json, 'bookingId')),
      option: option,
      hotelId: firstNonEmpty([
        readKey(json, 'tjHotelId'),
        readKey(json, 'hotelId'),
        digPath(json, ['hotelInfo', 'tjid']),
        digPath(json, ['hotelSummary', 'tjid']),
      ]),
      hotelName: firstNonEmpty([
        readKey(json, 'hotelName'),
        digPath(json, ['hotelSummary', 'name']),
        digPath(json, ['hotelInfo', 'name']),
      ]),
      amount: hasSummary ? asDouble(readKey(summary, 'amount')) : pricing.total,
      baseFare: hasSummary
          ? asDouble(readKey(summary, 'baseFare'))
          : pricing.base,
      taxesAndFees: hasSummary
          ? asDouble(readKey(summary, 'taxesAndFees'))
          : pricing.taxesAndFees,
      managementFee: hasSummary
          ? asDouble(readKey(summary, 'managementFee'))
          : pricing.managementFee,
      managementFeeTax: hasSummary
          ? asDouble(readKey(summary, 'managementFeeTax'))
          : pricing.managementFeeTax,
      currency: firstNonEmpty([
        readKey(summary, 'currency'),
        pricing.currency,
      ], fallback: 'INR'),
      panRequired:
          readKey(requirements, 'panRequired') == true || option.panRequired,
      passportRequired:
          readKey(requirements, 'passportRequired') == true ||
          option.passportRequired,
      onholdAllowed:
          readKey(json, 'onholdAllowed') == true ||
          readKey(requirements, 'onholdAllowed') == true,
      deadline: firstNonEmpty([
        readKey(requirements, 'deadlineDatetime'),
        option.deadline,
      ]),
      policyNotes: HotelPolicyNote.fromInclusions(
        readKey(optionJson, 'inclusions'),
      ),
      importantNotes: notes.take(8).toList(),
      raw: asJsonMap(json),
    );
  }
}

// ---------------------------------------------------------------------------
// Booking status (POST hotels/booking-details, verify/hold/confirm answers)
// ---------------------------------------------------------------------------

const Set<String> kHotelSuccessStatuses = {'SUCCESS', 'CONFIRMED', 'VOUCHERED'};
const Set<String> kHotelFailureStatuses = {'FAILED', 'ABORTED', 'CANCELLED'};

/// Whether a booking/hold/verify answer is the supplier *refusing* the
/// request. These come back as HTTP 200 with a `bookingId` still attached, so
/// treating "has a booking id" as success reads a refusal as a confirmation.
/// Mirrors the three checks the web makes after every such call.
bool isHotelSupplierDenial(dynamic json) =>
    readKey(json, 'success') == false ||
    readKey(json, 'tripjackRequestAccepted') == false ||
    digPath(json, ['status', 'success']) == false;

/// The supplier's reason for a refusal, if it gave one.
String hotelDenialReason(dynamic json) => firstNonEmpty([
  readKey(json, 'error'),
  digPath(json, ['errors', 0, 'message']),
  readKey(json, 'message'),
]);

/// The order status inside a verify/confirm answer, which nests the latest
/// `bookingDetails` — the web's `extractOrderStatusFromBookingDetails`.
String hotelOrderStatusOf(dynamic json) => firstNonEmpty([
  digPath(json, ['bookingDetails', 'order', 'status']),
  digPath(json, ['bookingDetails', 'orderStatus']),
  digPath(json, ['order', 'status']),
  readKey(json, 'orderStatus'),
]).toUpperCase();

/// Customer-facing label for an order status, from the web's
/// `HotelBookingsPage`/`HotelBookingDetailsPage` wording.
String hotelStatusLabel(String status, {String userStatus = ''}) {
  if (userStatus.trim().isNotEmpty) return userStatus.trim();
  final s = status.toUpperCase();
  return switch (s) {
    'PAYMENT_SUCCESS' => 'Payment success – pending voucher',
    'SUCCESS' || 'CONFIRMED' || 'VOUCHERED' => 'Booking confirmed',
    'ON_HOLD' => 'Booking on hold',
    'IN_PROGRESS' || 'PENDING' => 'Booking processing',
    'PAYMENT_PENDING' => 'Payment pending',
    'PAYMENT_FAILED' => 'Payment failed',
    'BOOK_FAILED_AFTER_PAYMENT' => 'Booking failed after payment',
    'CANCELLATION_REQUESTED' ||
    'CANCELLATION_PENDING' => 'Cancellation pending',
    'FAILED' || 'ABORTED' => 'Booking failed',
    'CANCELLED' => 'Cancelled',
    '' => 'Booking processing',
    _ =>
      s
          .toLowerCase()
          .split('_')
          .where((p) => p.isNotEmpty)
          .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
          .join(' '),
  };
}

/// One stay as `hotels/booking-details` describes it.
///
/// The backend wraps TripJack's order in its own envelope:
/// `{bookingId, orderStatus, userStatus, bookingType, paymentStatus,
/// bookingStatusMeta{normalizedStatus, rawStatus, isSuccessTerminal,
/// isFailureTerminal}, bookingDisplay{...}, raw{order, itemInfos.HOTEL}}`.
class HotelBookingStatus {
  const HotelBookingStatus({
    this.bookingId = '',
    this.status = '',
    this.rawStatus = '',
    this.isSuccessTerminal = false,
    this.isFailureTerminal = false,
    this.userStatus = '',
    this.bookingType = '',
    this.paymentStatus = '',
    this.hotelName = '',
    this.address = '',
    this.checkIn = '',
    this.checkOut = '',
    this.roomName = '',
    this.totalRooms = 1,
    this.adults = 0,
    this.children = 0,
    this.guests = const [],
    this.email = '',
    this.phone = '',
    this.createdOn = '',
    this.deadline = '',
    this.baseFare = 0,
    this.taxes = 0,
    this.managementFee = 0,
    this.managementFeeTax = 0,
    this.total = 0,
    this.currency = 'INR',
    this.penalties = const [],
    this.raw = const <String, dynamic>{},
  });

  final String bookingId;

  /// Upper-cased, normalised order status (`SUCCESS`, `ON_HOLD`, …).
  final String status;
  final String rawStatus;
  final bool isSuccessTerminal;
  final bool isFailureTerminal;

  /// Wording the backend chose for this status, preferred when present.
  final String userStatus;
  final String bookingType;
  final String paymentStatus;

  final String hotelName;
  final String address;
  final String checkIn;
  final String checkOut;
  final String roomName;
  final int totalRooms;
  final int adults;
  final int children;
  final List<String> guests;
  final String email;
  final String phone;
  final String createdOn;
  final String deadline;

  final double baseFare;
  final double taxes;
  final double managementFee;
  final double managementFeeTax;
  final double total;
  final String currency;
  final List<HotelPenalty> penalties;

  final Map<String, dynamic> raw;

  bool get isPaid => paymentStatus.toUpperCase() == 'PAID';

  bool get isConfirmed => kHotelSuccessStatuses.contains(status);

  bool get isCancellationFlow =>
      const {
        'CANCELLATION_REQUESTED',
        'CANCELLATION_PENDING',
        'CANCELLED',
      }.contains(status) ||
      userStatus.toUpperCase().contains('CANCEL');

  /// A held room still waiting for payment.
  bool get isHoldPendingPayment =>
      const {
        'ON_HOLD',
        'IN_PROGRESS',
        'PENDING',
        'PAYMENT_PENDING',
      }.contains(status) &&
      (bookingType.toUpperCase() == 'HOLD' || status == 'ON_HOLD') &&
      !isPaid;

  bool get canCancel =>
      !isCancellationFlow &&
      const {
        'SUCCESS',
        'CONFIRMED',
        'VOUCHERED',
        'ON_HOLD',
        'PAYMENT_SUCCESS',
      }.contains(status);

  bool get canConfirmHold => isHoldPendingPayment;

  /// The receipt only exists once the payment is captured *and* the hotel
  /// confirmed; the voucher only once the hotel confirmed.
  bool get canDownloadReceipt => isPaid && isConfirmed;
  bool get canDownloadVoucher => isConfirmed && !isHoldPendingPayment;

  String get statusLabel => isCancellationFlow
      ? (status == 'CANCELLED' ? 'Booking cancelled' : 'Cancellation pending')
      : hotelStatusLabel(status, userStatus: userStatus);

  int get nights {
    final a = DateTime.tryParse(checkIn);
    final b = DateTime.tryParse(checkOut);
    if (a == null || b == null) return 0;
    final diff = b.difference(a).inDays;
    return diff > 0 ? diff : 0;
  }

  factory HotelBookingStatus.fromJson(
    dynamic json, {
    String fallbackBookingId = '',
  }) {
    final display = readKey(json, 'bookingDisplay');
    final meta = readKey(json, 'bookingStatusMeta');
    final rawRoot = readKey(json, 'raw') ?? json;
    final order = readKey(rawRoot, 'order') ?? readKey(json, 'order');
    final hotelItem =
        digPath(rawRoot, ['itemInfos', 'HOTEL']) ??
        digPath(json, ['itemInfos', 'HOTEL']);
    final hInfo = readKey(hotelItem, 'hInfo');
    final option = digPath(hInfo, ['ops', 0]);
    final rooms = asList(readKey(option, 'ris'));
    final room = rooms.isEmpty ? null : rooms.first;
    final fare = readKey(room, 'tfcs') ?? readKey(option, 'tfcs');
    final query = readKey(hotelItem, 'query');

    final guests = <String>[];
    for (final r in rooms) {
      for (final t in asList(readKey(r, 'ti'))) {
        final name = [
          asString(readKey(t, 'ti')),
          asString(readKey(t, 'fN')),
          asString(readKey(t, 'lN')),
        ].where((s) => s.isNotEmpty).join(' ');
        if (name.isNotEmpty) guests.add(name);
      }
    }
    final displayGuest = asString(readKey(display, 'guestName'));
    if (guests.isEmpty && displayGuest.isNotEmpty) guests.add(displayGuest);

    final displayPolicies = asList(readKey(display, 'cancellationPolicies'));
    final delivery =
        readKey(json, 'deliveryInfo') ?? readKey(order, 'deliveryInfo');

    return HotelBookingStatus(
      bookingId: firstNonEmpty([
        readKey(json, 'bookingId'),
        readKey(order, 'bookingId'),
        fallbackBookingId,
      ]),
      status: firstNonEmpty([
        readKey(meta, 'normalizedStatus'),
        readKey(json, 'orderStatus'),
        readKey(order, 'status'),
        readKey(meta, 'rawStatus'),
      ]).toUpperCase(),
      rawStatus: firstNonEmpty([
        readKey(meta, 'rawStatus'),
        readKey(json, 'orderStatus'),
      ]).toUpperCase(),
      isSuccessTerminal: readKey(meta, 'isSuccessTerminal') == true,
      isFailureTerminal: readKey(meta, 'isFailureTerminal') == true,
      userStatus: asString(readKey(json, 'userStatus')),
      bookingType: firstNonEmpty([
        readKey(json, 'bookingType'),
        readKey(json, 'booking_type'),
      ]),
      paymentStatus: firstNonEmpty([
        readKey(json, 'paymentStatus'),
        readKey(json, 'payment_status'),
      ]),
      hotelName: firstNonEmpty([
        readKey(display, 'hotelName'),
        readKey(hInfo, 'name'),
      ]),
      address: firstNonEmpty([
        readKey(display, 'hotelAddress'),
        digPath(hInfo, ['ad', 'adr']),
        digPath(hInfo, ['ad', 'line1']),
        digPath(hInfo, ['ad', 'city', 'name']),
      ]),
      checkIn: firstNonEmpty([
        readKey(display, 'checkIn'),
        readKey(room, 'checkInDate'),
        readKey(query, 'checkinDate'),
      ]),
      checkOut: firstNonEmpty([
        readKey(display, 'checkOut'),
        readKey(room, 'checkOutDate'),
        readKey(query, 'checkoutDate'),
      ]),
      roomName: firstNonEmpty([
        readKey(display, 'roomName'),
        readKey(room, 'rc'),
        readKey(room, 'rt'),
      ]),
      totalRooms: rooms.isEmpty ? 1 : rooms.length,
      adults: asInt(readKey(room, 'adt'), fallback: 1),
      children: asInt(readKey(room, 'chd')),
      guests: guests,
      email: firstNonEmpty([
        readKey(display, 'email'),
        digPath(delivery, ['emails', 0]),
      ]),
      phone: firstNonEmpty([
        readKey(display, 'phone'),
        digPath(delivery, ['contacts', 0]),
      ]),
      createdOn: firstNonEmpty([
        readKey(display, 'createdOn'),
        readKey(json, 'createdOn'),
        readKey(order, 'createdOn'),
      ]),
      deadline: firstNonEmpty([
        readKey(display, 'deadlineDatetime'),
        readKey(json, 'deadlineDatetime'),
        readKey(option, 'ddt'),
      ]),
      baseFare: asDouble(readKey(display, 'baseFare') ?? readKey(fare, 'BF')),
      taxes: asDouble(readKey(display, 'taxes') ?? readKey(fare, 'TAF')),
      managementFee: asDouble(readKey(display, 'mf')),
      managementFeeTax: asDouble(readKey(display, 'mft')),
      total: asDouble(
        readKey(display, 'totalAmount') ??
            readKey(json, 'amount') ??
            readKey(order, 'amount') ??
            readKey(option, 'tp'),
      ),
      currency: firstNonEmpty([
        readKey(display, 'currency'),
        readKey(option, 'sc'),
      ], fallback: 'INR'),
      penalties: displayPolicies.isNotEmpty
          ? HotelPenalty.listFrom({'penalties': displayPolicies})
          : HotelPenalty.listFrom(readKey(option, 'cnp')),
      raw: asJsonMap(json),
    );
  }
}

// ---------------------------------------------------------------------------
// Failures after payment
// ---------------------------------------------------------------------------

/// What went wrong when a hotel booking call failed, read from the error body
/// the backend returns. The web makes every recovery decision from these
/// flags, so they are surfaced rather than flattened into a message.
class HotelBookingFailure {
  const HotelBookingFailure({
    this.source = '',
    this.statusCode = 0,
    this.message = '',
    this.errorCode = '',
    this.bookingId = '',
    this.duplicateBookingBlocked = false,
    this.paymentCaptured = false,
    this.requiresManualAction = false,
    this.tripjackStatus = '',
  });

  /// `VALIDATION`, `TRIPJACK` or `PAYMENT`.
  final String source;
  final int statusCode;
  final String message;
  final String errorCode;
  final String bookingId;

  /// The payment for this booking was already captured; paying again must be
  /// prevented.
  final bool duplicateBookingBlocked;
  final bool paymentCaptured;
  final bool requiresManualAction;
  final String tripjackStatus;

  bool get isValidation => source == 'VALIDATION';

  /// TripJack refused the request (a 400, or `status.success:false`, which
  /// [HotelBookingFailure.fromBody] folds into a 400).
  bool get isSupplierDenial => source == 'TRIPJACK' && statusCode == 400;

  bool get isSupplierOutage => source == 'TRIPJACK' && statusCode >= 500;

  bool get isPayment =>
      source == 'PAYMENT' ||
      RegExp(
        r'razorpay|international cards are not supported|'
        r'international_transaction_not_allowed|payment could not be completed',
        caseSensitive: false,
      ).hasMatch(message);

  factory HotelBookingFailure.fromBody(
    Map<String, dynamic> body, {
    int statusCode = 0,
  }) {
    final supplierFailed = digPath(body, ['status', 'success']) == false;
    final code = asInt(readKey(body, 'status_code'), fallback: statusCode);
    return HotelBookingFailure(
      source: asString(readKey(body, 'source')).toUpperCase(),
      // A supplier `status.success:false` is a refusal whatever the HTTP code.
      statusCode: supplierFailed && code < 400 ? 400 : code,
      message: firstNonEmpty([
        readKey(body, 'error'),
        readKey(body, 'message'),
      ]),
      errorCode: asString(digPath(body, ['errors', 0, 'errCode'])),
      bookingId: asString(readKey(body, 'bookingId')),
      duplicateBookingBlocked: readKey(body, 'duplicateBookingBlocked') == true,
      paymentCaptured: readKey(body, 'paymentCaptured') == true,
      requiresManualAction: readKey(body, 'requiresManualAction') == true,
      tripjackStatus: asString(
        digPath(body, ['bookingSummary', 'tripjackStatus']),
      ),
    );
  }
}
