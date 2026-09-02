/// Models for the ShaadiAI wedding-planning assistant.
///
/// Ported from `ShaadiAI.jsx` (the live component starts at line 690; lines
/// 1-689 in the React source are dead/commented-out code) and
/// `ChatFeatures.jsx`. Every field name below is taken verbatim from those
/// files' JSX/JS — nothing here is invented.
library;

// ---------------------------------------------------------------------------
// JSON helpers — kept local to this module rather than importing the
// honeymoon module's equivalents, so the two feature modules stay decoupled.
// ---------------------------------------------------------------------------

String asString(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final s = value.toString();
  return s.isEmpty ? fallback : s;
}

double asDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

int asInt(dynamic value, {int fallback = 0}) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

bool asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

List<dynamic> asList(dynamic value) => value is List ? value : const [];

List<String> asStringList(dynamic value) =>
    asList(value).map((e) => e.toString()).toList();

Map<String, dynamic> asJsonMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};

dynamic readKey(dynamic json, String key) =>
    json is Map ? json[key] : null;

// ---------------------------------------------------------------------------
// `/ai/chat` response — vendors / products / orders / comparisons
// ---------------------------------------------------------------------------

class ShaadiVendor {
  const ShaadiVendor({
    required this.vendorId,
    required this.name,
    required this.category,
    required this.location,
    required this.priceRange,
    required this.whyRecommended,
  });

  final String vendorId;
  final String name;
  final String category;
  final String location;
  final String priceRange;
  final List<String> whyRecommended;

  factory ShaadiVendor.fromJson(dynamic json) => ShaadiVendor(
    vendorId: asString(readKey(json, 'vendor_id')),
    name: asString(readKey(json, 'name')),
    category: asString(readKey(json, 'category')),
    location: asString(readKey(json, 'location')),
    priceRange: asString(readKey(json, 'price_range')),
    whyRecommended: asStringList(readKey(json, 'why_recommended')),
  );

  Map<String, dynamic> toJson() => {
    'vendor_id': vendorId,
    'name': name,
    'category': category,
    'location': location,
    'price_range': priceRange,
    'why_recommended': whyRecommended,
  };
}

class ShaadiProduct {
  const ShaadiProduct({
    required this.id,
    required this.url,
    required this.image,
    required this.inStock,
    required this.category,
    required this.title,
    required this.price,
    required this.originalPrice,
    required this.reasons,
  });

  final String id;
  final String url;
  final String image;
  final bool inStock;
  final String category;
  final String title;
  final double price;
  final double originalPrice;
  final List<String> reasons;

  factory ShaadiProduct.fromJson(dynamic json) => ShaadiProduct(
    id: asString(readKey(json, 'id')),
    url: asString(readKey(json, 'url')),
    image: asString(readKey(json, 'image')),
    inStock: asBool(readKey(json, 'inStock'), fallback: true),
    category: asString(readKey(json, 'category')),
    title: asString(readKey(json, 'title')),
    price: asDouble(readKey(json, 'price')),
    originalPrice: asDouble(readKey(json, 'originalPrice')),
    reasons: asStringList(readKey(json, 'reasons')),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'url': url,
    'image': image,
    'inStock': inStock,
    'category': category,
    'title': title,
    'price': price,
    'originalPrice': originalPrice,
    'reasons': reasons,
  };
}

class ShaadiOrderItem {
  const ShaadiOrderItem({
    required this.id,
    required this.image,
    required this.title,
    required this.quantity,
  });

  final String id;
  final String image;
  final String title;
  final int quantity;

  factory ShaadiOrderItem.fromJson(dynamic json) => ShaadiOrderItem(
    id: asString(readKey(json, 'id')),
    image: asString(readKey(json, 'image')),
    title: asString(readKey(json, 'title')),
    quantity: asInt(readKey(json, 'quantity'), fallback: 1),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'image': image,
    'title': title,
    'quantity': quantity,
  };
}

/// Same store-order concept as `GET /api/store/orders/mine`
/// (`lib/my_bookings/my_bookings.dart`), but a distinct, narrower shape as
/// surfaced inline in a chat reply — no payment/shipping/currency fields.
class ShaadiOrder {
  const ShaadiOrder({
    required this.id,
    required this.invoice,
    required this.status,
    required this.items,
    required this.itemCount,
    required this.total,
  });

  final String id;
  final String invoice;
  final String status;
  final List<ShaadiOrderItem> items;
  final int itemCount;
  final double total;

  factory ShaadiOrder.fromJson(dynamic json) => ShaadiOrder(
    id: asString(readKey(json, 'id')),
    invoice: asString(readKey(json, 'invoice')),
    status: asString(readKey(json, 'status')),
    items: asList(
      readKey(json, 'items'),
    ).map(ShaadiOrderItem.fromJson).toList(),
    itemCount: asInt(readKey(json, 'itemCount')),
    total: asDouble(readKey(json, 'total')),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice': invoice,
    'status': status,
    'items': items.map((i) => i.toJson()).toList(),
    'itemCount': itemCount,
    'total': total,
  };
}

class ShaadiComparisonSide {
  const ShaadiComparisonSide({
    required this.name,
    required this.price,
    required this.capacity,
    required this.indoorOutdoor,
  });

  final String name;
  final String price;
  final String capacity;
  final String indoorOutdoor;

  factory ShaadiComparisonSide.fromJson(dynamic json) => ShaadiComparisonSide(
    name: asString(readKey(json, 'name')),
    price: asString(readKey(json, 'price')),
    capacity: asString(readKey(json, 'capacity')),
    indoorOutdoor: asString(readKey(json, 'indoor_outdoor')),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'price': price,
    'capacity': capacity,
    'indoor_outdoor': indoorOutdoor,
  };
}

class ShaadiComparison {
  const ShaadiComparison({
    required this.vendor1,
    required this.vendor2,
    required this.recommendation,
  });

  final ShaadiComparisonSide vendor1;
  final ShaadiComparisonSide vendor2;
  final String recommendation;

  factory ShaadiComparison.fromJson(dynamic json) => ShaadiComparison(
    vendor1: ShaadiComparisonSide.fromJson(readKey(json, 'vendor_1')),
    vendor2: ShaadiComparisonSide.fromJson(readKey(json, 'vendor_2')),
    recommendation: asString(readKey(json, 'recommendation')),
  );

  Map<String, dynamic> toJson() => {
    'vendor_1': vendor1.toJson(),
    'vendor_2': vendor2.toJson(),
    'recommendation': recommendation,
  };
}

// ---------------------------------------------------------------------------
// Feature: Personality Quiz
// ---------------------------------------------------------------------------

/// One of the 7 fixed two-option questions asked once per partner.
/// Text is quoted verbatim from `ChatFeatures.jsx`.
class PersonalityQuizQuestion {
  const PersonalityQuizQuestion({
    required this.id,
    required this.question,
    required this.option1,
    required this.option2,
  });

  final String id;
  final String question;
  final String option1;
  final String option2;
}

const List<PersonalityQuizQuestion> kPersonalityQuizQuestions = [
  PersonalityQuizQuestion(
    id: '1',
    question: 'Wedding Scale',
    option1: 'Intimate (30–60 guests)',
    option2: 'Grand (200+ guests)',
  ),
  PersonalityQuizQuestion(
    id: '2',
    question: 'Formality',
    option1: 'Casual/barefoot',
    option2: 'Black tie',
  ),
  PersonalityQuizQuestion(
    id: '3',
    question: 'Emotion',
    option1: 'Romantic & heartfelt',
    option2: 'Fun & wild',
  ),
  PersonalityQuizQuestion(
    id: '4',
    question: 'Culture',
    option1: 'Full traditional rituals',
    option2: 'Modern selective',
  ),
  PersonalityQuizQuestion(
    id: '5',
    question: 'Pace',
    option1: 'Relaxed & flowing',
    option2: 'Perfectly choreographed',
  ),
  PersonalityQuizQuestion(
    id: '6',
    question: 'Focus',
    option1: 'Ceremony is main event',
    option2: 'Reception is main event',
  ),
  PersonalityQuizQuestion(
    id: '7',
    question: 'Vibe',
    option1: 'Timeless & classic',
    option2: 'Unique & unexpected',
  ),
];

class PersonalityQuizResult {
  const PersonalityQuizResult({
    required this.profileName,
    required this.description,
    required this.traits,
    required this.venueStyle,
    required this.decorStyle,
    this.mismatchAlert,
    required this.recommendationsLens,
    required this.raw,
  });

  final String profileName;
  final String description;
  final List<String> traits;
  final String venueStyle;
  final String decorStyle;
  final String? mismatchAlert;
  final String recommendationsLens;

  /// The exact response body, persisted verbatim to local storage — the
  /// other 3 features read `raw['recommendations_lens']` back out, so the
  /// round trip must not lose fields this model doesn't otherwise surface.
  final Map<String, dynamic> raw;

  factory PersonalityQuizResult.fromJson(dynamic json) {
    final map = asJsonMap(json);
    final alert = readKey(map, 'mismatch_alert');
    return PersonalityQuizResult(
      profileName: asString(readKey(map, 'profile_name')),
      description: asString(readKey(map, 'description')),
      traits: asStringList(readKey(map, 'traits')),
      venueStyle: asString(readKey(map, 'venue_style')),
      decorStyle: asString(readKey(map, 'decor_style')),
      mismatchAlert: alert == null ? null : asString(alert),
      recommendationsLens: asString(readKey(map, 'recommendations_lens')),
      raw: map,
    );
  }
}

// ---------------------------------------------------------------------------
// Feature: Culture Blender
// ---------------------------------------------------------------------------

/// Fixed 21-culture list, quoted verbatim from `ChatFeatures.jsx`.
const List<String> kCultureOptions = [
  'Indian (Hindu)',
  'Indian (Muslim)',
  'Indian (Sikh)',
  'Indian (Christian)',
  'Chinese',
  'Japanese',
  'Korean',
  'Thai',
  'Vietnamese',
  'Mexican',
  'Brazilian',
  'Italian',
  'French',
  'Spanish',
  'Greek',
  'British',
  'Irish',
  'German',
  'Nigerian',
  'Lebanese',
  'Turkish',
];

const List<String> kCeremonyTypes = ['Religious', 'Civil', 'Symbolic'];

class CultureCeremonySection {
  const CultureCeremonySection({
    required this.name,
    required this.origin,
    required this.durationMins,
    required this.description,
    this.guestExplanation,
  });

  final String name;
  final String origin;
  final int durationMins;
  final String description;
  final String? guestExplanation;

  factory CultureCeremonySection.fromJson(dynamic json) {
    final explanation = readKey(json, 'guest_explanation');
    return CultureCeremonySection(
      name: asString(readKey(json, 'name')),
      origin: asString(readKey(json, 'origin')),
      durationMins: asInt(readKey(json, 'duration_mins')),
      description: asString(readKey(json, 'description')),
      guestExplanation: explanation == null ? null : asString(explanation),
    );
  }
}

class CultureBlenderResult {
  const CultureBlenderResult({
    required this.ceremonySections,
    required this.attireSuggestion,
    required this.foodSuggestion,
    required this.musicSuggestion,
  });

  final List<CultureCeremonySection> ceremonySections;
  final String attireSuggestion;
  final String foodSuggestion;
  final String musicSuggestion;

  factory CultureBlenderResult.fromJson(dynamic json) {
    final map = asJsonMap(json);
    return CultureBlenderResult(
      ceremonySections: asList(
        readKey(map, 'ceremony_sections'),
      ).map(CultureCeremonySection.fromJson).toList(),
      attireSuggestion: asString(readKey(map, 'attire_suggestion')),
      foodSuggestion: asString(readKey(map, 'food_suggestion')),
      musicSuggestion: asString(readKey(map, 'music_suggestion')),
    );
  }
}

/// Priority sliders exist in the React UI but are never wired up — every
/// submission sends this exact constant for both partners. Reproduced as-is
/// rather than "fixed", since the backend contract expects this shape.
const Map<String, int> kCulturePrioritiesConstant = {
  'rituals': 2,
  'attire': 2,
  'food': 2,
  'music': 2,
  'venueStyle': 2,
};

// ---------------------------------------------------------------------------
// Feature: Conflict Resolver
// ---------------------------------------------------------------------------

/// Fixed 8-topic list, quoted verbatim from `ChatFeatures.jsx`.
const List<String> kConflictTopics = [
  'Venue',
  'Guest list size',
  'Budget split',
  'Date',
  'Décor',
  'Food',
  'Specific guests',
  'Other',
];

class ConflictOption {
  const ConflictOption({
    required this.title,
    required this.description,
    required this.partner1GivesUp,
    required this.partner2GivesUp,
    required this.aiRecommended,
  });

  final String title;
  final String description;
  final String partner1GivesUp;
  final String partner2GivesUp;
  final bool aiRecommended;

  factory ConflictOption.fromJson(dynamic json) => ConflictOption(
    title: asString(readKey(json, 'title')),
    description: asString(readKey(json, 'description')),
    partner1GivesUp: asString(readKey(json, 'partner1_gives_up')),
    partner2GivesUp: asString(readKey(json, 'partner2_gives_up')),
    aiRecommended: asBool(readKey(json, 'ai_recommended')),
  );
}

class ConflictResolverResult {
  const ConflictResolverResult({
    required this.reframe,
    required this.partner1RealNeed,
    required this.partner2RealNeed,
    required this.options,
  });

  final String reframe;
  final String partner1RealNeed;
  final String partner2RealNeed;
  final List<ConflictOption> options;

  factory ConflictResolverResult.fromJson(dynamic json) {
    final map = asJsonMap(json);
    return ConflictResolverResult(
      reframe: asString(readKey(map, 'reframe')),
      partner1RealNeed: asString(readKey(map, 'partner1_real_need')),
      partner2RealNeed: asString(readKey(map, 'partner2_real_need')),
      options: asList(
        readKey(map, 'options'),
      ).map(ConflictOption.fromJson).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Feature: Timeline Generator
// ---------------------------------------------------------------------------

/// Fixed 14-event checklist, quoted verbatim from `ChatFeatures.jsx`.
const List<String> kTimelineEvents = [
  'Mehendi Ceremony',
  'Sangeet Night',
  'Haldi Ceremony',
  'Wedding Ceremony',
  'Cocktail Hour',
  'Reception',
  'Baraat Procession',
  'Pheras/Vows',
  'Couple Photography',
  'Family Photography',
  'Dinner Service',
  'Cake Cutting',
  'First Dance',
  'Entertainment/Performances',
];

class TimelineItem {
  const TimelineItem({
    required this.time,
    required this.durationMins,
    required this.title,
    required this.type,
    this.notes,
    required this.warning,
  });

  final String time;
  final int durationMins;
  final String title;
  final String type;
  final String? notes;
  final bool warning;

  factory TimelineItem.fromJson(dynamic json) {
    final notesValue = readKey(json, 'notes');
    return TimelineItem(
      time: asString(readKey(json, 'time')),
      durationMins: asInt(readKey(json, 'duration_mins')),
      title: asString(readKey(json, 'title')),
      type: asString(readKey(json, 'type')),
      notes: notesValue == null ? null : asString(notesValue),
      warning: asBool(readKey(json, 'warning')),
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'duration_mins': durationMins,
    'title': title,
    'type': type,
    if (notes != null) 'notes': notes,
    'warning': warning,
  };
}

/// The endpoint answers either a bare array or `{timeline: [...]}` — both are
/// handled here so callers never need to care which shape came back.
List<TimelineItem> timelineResultFromJson(dynamic json) {
  final list = json is List ? json : asList(readKey(json, 'timeline'));
  return list.map(TimelineItem.fromJson).toList();
}

// ---------------------------------------------------------------------------
// Feature type + chat message
// ---------------------------------------------------------------------------

enum ShaadiFeatureType {
  personalityQuiz('personality-quiz', 'Personality Quiz'),
  cultureBlender('culture-blender', 'Culture Blender'),
  conflictResolver('conflict-resolver', 'Conflict Resolver'),
  timelineGenerator('timeline-generator', 'Timeline Generator');

  const ShaadiFeatureType(this.slug, this.label);

  /// Slash-command / storage identifier, e.g. `personality-quiz`.
  final String slug;

  /// Human label, e.g. "Personality Quiz".
  final String label;

  static ShaadiFeatureType? fromSlug(String? slug) {
    for (final f in ShaadiFeatureType.values) {
      if (f.slug == slug) return f;
    }
    return null;
  }
}

/// One message in a ShaadiAI conversation. `role` is `'user'` or
/// `'assistant'`, matching the React source's own vocabulary so the
/// `conversationHistory` sent back to `/ai/chat` needs no translation.
class ShaadiChatMessage {
  ShaadiChatMessage({
    required this.role,
    required this.content,
    this.vendors = const [],
    this.products = const [],
    this.orders = const [],
    this.comparisons = const [],
    this.suggestions = const [],
    this.budgetBreakdown = const {},
    this.featureType,
    this.featureResult,
    this.featureError,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  final String role;
  final String content;
  final List<ShaadiVendor> vendors;
  final List<ShaadiProduct> products;
  final List<ShaadiOrder> orders;
  final List<ShaadiComparison> comparisons;
  final List<String> suggestions;
  final Map<String, double> budgetBreakdown;
  final DateTime timestamp;

  /// Set on the placeholder message a slash-command/keyword match opens —
  /// cleared to look up which inline form (if any) is still pending.
  final ShaadiFeatureType? featureType;

  /// One of [PersonalityQuizResult] / [CultureBlenderResult] /
  /// [ConflictResolverResult] / `List<TimelineItem>`, set once the form
  /// completes. Null while the form is still open.
  final dynamic featureResult;

  /// Set instead of [featureResult] when the feature's own POST failed.
  final String? featureError;

  bool get isUser => role == 'user';

  /// True once every optional field is empty — i.e. this message is really
  /// just plain text (or, for a still-open feature form, no text at all).
  bool get hasResults =>
      vendors.isNotEmpty ||
      products.isNotEmpty ||
      orders.isNotEmpty ||
      comparisons.isNotEmpty ||
      suggestions.isNotEmpty ||
      budgetBreakdown.isNotEmpty;

  factory ShaadiChatMessage.fromChatResponse(dynamic json) {
    final map = asJsonMap(json);
    final budget = asJsonMap(readKey(map, 'budget_breakdown'));
    return ShaadiChatMessage(
      role: 'assistant',
      content: asString(readKey(map, 'summary')),
      vendors: asList(readKey(map, 'vendors')).map(ShaadiVendor.fromJson).toList(),
      products: asList(
        readKey(map, 'products'),
      ).map(ShaadiProduct.fromJson).toList(),
      orders: asList(readKey(map, 'orders')).map(ShaadiOrder.fromJson).toList(),
      comparisons: asList(
        readKey(map, 'comparisons'),
      ).map(ShaadiComparison.fromJson).toList(),
      suggestions: asStringList(readKey(map, 'suggestions')),
      budgetBreakdown: budget.map(
        (k, v) => MapEntry(k, asDouble(v)),
      ),
    );
  }

  /// Stripped copy for local storage — only non-empty optional fields are
  /// kept, matching the React source's `shaadi_ai_chats` persistence.
  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    if (vendors.isNotEmpty)
      'vendors': vendors.map((v) => v.toJson()).toList(),
    if (products.isNotEmpty)
      'products': products.map((p) => p.toJson()).toList(),
    if (orders.isNotEmpty) 'orders': orders.map((o) => o.toJson()).toList(),
    if (comparisons.isNotEmpty)
      'comparisons': comparisons.map((c) => c.toJson()).toList(),
    if (suggestions.isNotEmpty) 'suggestions': suggestions,
    if (budgetBreakdown.isNotEmpty) 'budget_breakdown': budgetBreakdown,
    if (featureType != null) 'featureType': featureType!.slug,
    if (featureResult != null) 'featureResult': _encodeFeatureResult(),
    if (featureError != null) 'featureError': featureError,
    'timestamp': timestamp.toIso8601String(),
  };

  dynamic _encodeFeatureResult() {
    final r = featureResult;
    if (r is PersonalityQuizResult) return r.raw;
    if (r is CultureBlenderResult) {
      return {
        'ceremony_sections': r.ceremonySections
            .map(
              (s) => {
                'name': s.name,
                'origin': s.origin,
                'duration_mins': s.durationMins,
                'description': s.description,
                if (s.guestExplanation != null)
                  'guest_explanation': s.guestExplanation,
              },
            )
            .toList(),
        'attire_suggestion': r.attireSuggestion,
        'food_suggestion': r.foodSuggestion,
        'music_suggestion': r.musicSuggestion,
      };
    }
    if (r is ConflictResolverResult) {
      return {
        'reframe': r.reframe,
        'partner1_real_need': r.partner1RealNeed,
        'partner2_real_need': r.partner2RealNeed,
        'options': r.options
            .map(
              (o) => {
                'title': o.title,
                'description': o.description,
                'partner1_gives_up': o.partner1GivesUp,
                'partner2_gives_up': o.partner2GivesUp,
                'ai_recommended': o.aiRecommended,
              },
            )
            .toList(),
      };
    }
    if (r is List<TimelineItem>) {
      return r.map((t) => t.toJson()).toList();
    }
    return null;
  }

  factory ShaadiChatMessage.fromJson(dynamic json) {
    final map = asJsonMap(json);
    final budget = asJsonMap(readKey(map, 'budget_breakdown'));
    final featureType = ShaadiFeatureType.fromSlug(
      readKey(map, 'featureType') as String?,
    );
    final rawResult = readKey(map, 'featureResult');

    dynamic decodedResult;
    if (rawResult != null && featureType != null) {
      decodedResult = switch (featureType) {
        ShaadiFeatureType.personalityQuiz => PersonalityQuizResult.fromJson(
          rawResult,
        ),
        ShaadiFeatureType.cultureBlender => CultureBlenderResult.fromJson(
          rawResult,
        ),
        ShaadiFeatureType.conflictResolver =>
          ConflictResolverResult.fromJson(rawResult),
        ShaadiFeatureType.timelineGenerator => timelineResultFromJson(
          rawResult,
        ),
      };
    }

    return ShaadiChatMessage(
      role: asString(readKey(map, 'role'), fallback: 'assistant'),
      content: asString(readKey(map, 'content')),
      vendors: asList(readKey(map, 'vendors')).map(ShaadiVendor.fromJson).toList(),
      products: asList(
        readKey(map, 'products'),
      ).map(ShaadiProduct.fromJson).toList(),
      orders: asList(readKey(map, 'orders')).map(ShaadiOrder.fromJson).toList(),
      comparisons: asList(
        readKey(map, 'comparisons'),
      ).map(ShaadiComparison.fromJson).toList(),
      suggestions: asStringList(readKey(map, 'suggestions')),
      budgetBreakdown: budget.map((k, v) => MapEntry(k, asDouble(v))),
      featureType: featureType,
      featureResult: decodedResult,
      featureError: readKey(map, 'featureError') == null
          ? null
          : asString(readKey(map, 'featureError')),
      timestamp:
          DateTime.tryParse(asString(readKey(map, 'timestamp'))) ??
          DateTime.now(),
    );
  }
}

/// One saved conversation in the `shaadi_ai_chats` sidebar.
class ShaadiChatSession {
  const ShaadiChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final List<ShaadiChatMessage> messages;
  final DateTime updatedAt;

  factory ShaadiChatSession.fromJson(dynamic json) {
    final map = asJsonMap(json);
    return ShaadiChatSession(
      id: asString(readKey(map, 'id')),
      title: asString(readKey(map, 'title'), fallback: 'New Chat'),
      messages: asList(
        readKey(map, 'messages'),
      ).map(ShaadiChatMessage.fromJson).toList(),
      updatedAt:
          DateTime.tryParse(asString(readKey(map, 'updatedAt'))) ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((m) => m.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// "First user message, truncated to 60 chars" — or "New Chat" if there
  /// isn't one yet. Matches the React source's title derivation exactly.
  static String titleFor(List<ShaadiChatMessage> messages) {
    final firstUser = messages.where((m) => m.isUser).firstOrNull;
    if (firstUser == null || firstUser.content.trim().isEmpty) {
      return 'New Chat';
    }
    final content = firstUser.content.trim();
    return content.length > 60 ? '${content.substring(0, 60)}...' : content;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// `₹1,24,600` — Indian grouping, `₹0` if not finite. Matches the React
/// source's `formatBudget`.
String formatBudgetAmount(double amount) {
  if (!amount.isFinite) return '₹0';
  final negative = amount < 0;
  final digits = amount.abs().round().toString();

  late final String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final lastThree = digits.substring(digits.length - 3);
    final rest = digits.substring(0, digits.length - 3);
    final pairs = <String>[];
    var i = rest.length;
    while (i > 2) {
      pairs.insert(0, rest.substring(i - 2, i));
      i -= 2;
    }
    if (i > 0) pairs.insert(0, rest.substring(0, i));
    grouped = '${pairs.join(',')},$lastThree';
  }
  return '${negative ? '-' : ''}₹$grouped';
}
