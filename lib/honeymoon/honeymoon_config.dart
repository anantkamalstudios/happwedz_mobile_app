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
  ///
  /// BUG FIX: this was the app's own paraphrase — and said "60+" where the
  /// rule is *above 61*. It is now the web's text word for word
  /// (`FareTypeFilter.jsx` `FARE_TYPES[].info`).
  String? get note => switch (this) {
    FareType.regular => null,
    FareType.student =>
      'Only students above 12 years of age are eligible for special fares '
          'and/or additional baggage allowances. Carrying valid student ID '
          'cards and student visas (where applicable) is mandatory, else the '
          'passenger may be denied boarding or asked to pay for extra baggage.',
    FareType.seniorCitizen =>
      'Only senior citizens above the age of 61 years can avail this special '
          'fare. It is mandatory to produce proof of Date of Birth at the '
          'airport, without which prevailing fares will be charged.',
  };
}

/// Flight passenger limits — the web's "Passengers & Class" dropdown
/// (`FlightSearchForm.jsx`): everyone counts toward the total of nine,
/// infants included, the form starts on one adult, and there can never be
/// more infants than adults.
class FlightPaxLimits {
  const FlightPaxLimits._();

  static const int maxTotal = 9;
  static const int defaultAdults = 1;
  static const int minAdults = 1;
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
// ---------------------------------------------------------------------------
// Hotel search options
// ---------------------------------------------------------------------------

/// Occupancy limits of the web's Rooms & Guests picker (`HotelSearchForm`).
class HotelOccupancyLimits {
  const HotelOccupancyLimits._();

  static const int maxRooms = 9;
  static const int maxAdultsPerRoom = 8;
  static const int maxChildrenPerRoom = 4;

  /// Children are 0–9; the age picker offers 1–9 and defaults to 1.
  static const int minChildAge = 1;
  static const int maxChildAge = 9;
}

/// A country TripJack identifies by numeric id — nationality and country of
/// residence are sent as these ids (`106` = India), not as names.
class HotelCountryOption {
  const HotelCountryOption(this.code, this.name);

  final String code;
  final String name;
}

/// The web's `HOTEL_COUNTRIES` table. TripJack has no endpoint for these ids,
/// so the web hard-codes them and so does this.
const List<HotelCountryOption> kHotelNationalities = [
  HotelCountryOption('106', 'India'),
  HotelCountryOption('9', 'Australia'),
  HotelCountryOption('13', 'Bahrain'),
  HotelCountryOption('14', 'Bangladesh'),
  HotelCountryOption('18', 'Belgium'),
  HotelCountryOption('22', 'Bolivia'),
  HotelCountryOption('25', 'Brazil'),
  HotelCountryOption('33', 'Canada'),
  HotelCountryOption('39', 'China'),
  HotelCountryOption('43', 'Croatia'),
  HotelCountryOption('48', 'Denmark'),
  HotelCountryOption('52', 'Ecuador'),
  HotelCountryOption('53', 'Egypt'),
  HotelCountryOption('62', 'France'),
  HotelCountryOption('68', 'Germany'),
  HotelCountryOption('71', 'Greece'),
  HotelCountryOption('82', 'Hong Kong'),
  HotelCountryOption('88', 'Ireland'),
  HotelCountryOption('91', 'Italy'),
  HotelCountryOption('94', 'Japan'),
  HotelCountryOption('116', 'Malaysia'),
  HotelCountryOption('124', 'Mexico'),
  HotelCountryOption('134', 'Nepal'),
  HotelCountryOption('137', 'New Zealand'),
  HotelCountryOption('149', 'Philippines'),
  HotelCountryOption('150', 'Poland'),
  HotelCountryOption('151', 'Portugal'),
  HotelCountryOption('162', 'Saudi Arabia'),
  HotelCountryOption('167', 'Singapore'),
  HotelCountryOption('174', 'Spain'),
  HotelCountryOption('175', 'Sri Lanka'),
  HotelCountryOption('185', 'Thailand'),
  HotelCountryOption('188', 'Tunisia'),
  HotelCountryOption('194', 'United Arab Emirates'),
  HotelCountryOption('195', 'United Kingdom'),
  HotelCountryOption('196', 'United States'),
  HotelCountryOption('201', 'Vietnam'),
];

/// The web's `HOTEL_RATING_OPTIONS` — `"0"` is an unrated property.
const List<({String value, String label})> kHotelRatingOptions = [
  (value: '5', label: '5 Star'),
  (value: '4', label: '4 Star'),
  (value: '3', label: '3 Star'),
  (value: '2', label: '2 Star'),
  (value: '1', label: '1 Star'),
  (value: '0', label: 'Unrated'),
];
