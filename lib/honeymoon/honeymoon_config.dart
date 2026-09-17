/// Single place for every configurable value in the Honeymoon module.
///
/// The backend exposes no honeymoon statistics or destination-catalogue
/// endpoint, so the hero figures below are configuration rather than data.
/// They live here — not scattered through the UI — so they can be swapped for
/// API values the moment such an endpoint exists.
library;

class HoneymoonConfig {
  const HoneymoonConfig._();

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  /// The web client's `VITE_API_URL` fallback is stale (`happywedz.com/api`
  /// now serves the SPA shell, not JSON — confirmed live, same issue fixed
  /// in [ApiConfig]). The backend was consolidated onto `api.happywedz.com`
  /// with no `/api` prefix; confirmed live against `/tj/meta/locations`.
  static const String apiBase = 'https://api.happywedz.com';

  /// SharedPreferences key the rest of the app already stores the JWT under.
  static const String authTokenKey = 'auth_token';

  static const Duration requestTimeout = Duration(seconds: 30);

  // ---------------------------------------------------------------------------
  // Search defaults
  // ---------------------------------------------------------------------------

  /// Honeymoon defaults to a couple.
  static const int defaultAdults = 2;
  static const int minTravellers = 1;
  static const int maxTravellers = 12;

  /// Nights offered by default between check-in and check-out.
  static const int defaultTripNights = 5;

  /// How far ahead a trip may be booked.
  static const int maxBookingDaysAhead = 365;

  /// TripJack expects an id here; the web client defaults both to India (106).
  static const String defaultNationality = '106';
  static const String defaultCountryOfResidence = '106';
  static const String defaultCountryName = 'India';
  static const String currency = 'INR';

  // ---------------------------------------------------------------------------
  // Hero
  // ---------------------------------------------------------------------------

  static const String heroTitle = 'Plan Your Perfect Honeymoon Escape';
  static const String heroSubtitle =
      'Discover romantic destinations, handpicked stays, unforgettable '
      'experiences and complete honeymoon packages.';

  /// Remote hero image. Swap for a bundled asset if you prefer no network hop.
  static const String heroImageUrl =
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=1600&q=80';

  /// Not API-backed — see the note at the top of this file.
  static const List<HoneymoonStat> heroStats = [
    HoneymoonStat(value: '100+', label: 'Destinations'),
    HoneymoonStat(value: '20K+', label: 'Happy Couples'),
    HoneymoonStat(value: '10+', label: 'Countries'),
  ];
}

class HoneymoonStat {
  const HoneymoonStat({required this.value, required this.label});

  final String value;
  final String label;
}

/// A cabin the supplier prices separately. The wire value is the label
/// upper-cased with spaces replaced by underscores, which is what
/// `searchQuery.cabinClass` expects.
enum CabinClass { economy, premiumEconomy, business, first }

extension CabinClassInfo on CabinClass {
  String get label => switch (this) {
    CabinClass.economy => 'Economy',
    CabinClass.premiumEconomy => 'Premium Economy',
    CabinClass.business => 'Business',
    CabinClass.first => 'First',
  };

  String get apiValue => label.toUpperCase().replaceAll(' ', '_');
}

/// TripJack's `pft` search modifier. Student and senior fares carry different
/// baggage and cancellation terms, so they are a search input rather than a
/// filter over regular results.
enum FareType { regular, student, seniorCitizen }

extension FareTypeInfo on FareType {
  String get label => switch (this) {
    FareType.regular => 'Regular',
    FareType.student => 'Student',
    FareType.seniorCitizen => 'Senior Citizen',
  };

  String get apiValue => switch (this) {
    FareType.regular => 'REGULAR',
    FareType.student => 'STUDENT',
    FareType.seniorCitizen => 'SENIOR_CITIZEN',
  };

  /// What the airline will ask for at check-in, shown beside the option so the
  /// traveller does not pick a fare they cannot produce documents for.
  String? get note => switch (this) {
    FareType.regular => null,
    FareType.student =>
      'Valid student ID required at check-in. Extra baggage on some airlines.',
    FareType.seniorCitizen =>
      'For travellers aged 60+. Photo ID required at check-in.',
  };
}

/// Airlines offered by the Preferred Airline picker.
///
/// The TripJack search API has no "list airlines" endpoint — `preferredAirline`
/// is only a filter field — so this list is static, exactly as the web client
/// and TripJack's own portal hardcode it.
class AirlineOption {
  const AirlineOption(this.code, this.name);

  final String code;
  final String name;
}

const List<AirlineOption> kPreferredAirlines = [
  AirlineOption('6E', 'IndiGo'),
  AirlineOption('SG', 'SpiceJet'),
  AirlineOption('AI', 'Air India'),
  AirlineOption('QP', 'Akasa Air'),
  AirlineOption('IX', 'AI Express'),
  AirlineOption('EK', 'Emirates'),
  AirlineOption('EY', 'Etihad Airways'),
  AirlineOption('SQ', 'Singapore Airlines'),
  AirlineOption('QR', 'Qatar Airways'),
  AirlineOption('TK', 'Turkish Airlines'),
  AirlineOption('LH', 'Lufthansa'),
  AirlineOption('BA', 'British Airways'),
  AirlineOption('CX', 'Cathay Pacific'),
  AirlineOption('TG', 'Thai Airways'),
  AirlineOption('MH', 'Malaysia Airlines'),
  AirlineOption('UL', 'SriLankan Airlines'),
  AirlineOption('WY', 'Oman Air'),
  AirlineOption('SV', 'Saudia'),
  AirlineOption('G9', 'Air Arabia'),
  AirlineOption('FZ', 'Flydubai'),
];

/// The supplier caps `preferredAirline` at ten entries.
const int kMaxPreferredAirlines = 10;