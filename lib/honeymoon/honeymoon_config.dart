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

  /// Matches the web client's `VITE_API_URL` default.
  static const String apiBase = 'https://happywedz.com/api';

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