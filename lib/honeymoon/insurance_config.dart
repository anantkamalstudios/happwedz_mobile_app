/// Travel-insurance options, ported from the web client.
///
/// TripSafe has no endpoint for destinations, plan types or durations — the
/// web hardcodes them (`config/insuranceCountries.js`,
/// `InsuranceSearchPanel.jsx`), so these are the same values, generated from
/// that file rather than retyped.
///
/// BUG FIX: the app used to send invented region keys (`WORLDWIDE`, `USA`,
/// `THAILAND`, …). TripSafe keys popular regions as `WW` / `SCH` / `ASI` /
/// `EUR` (`rt: POPULARREGION`) and countries by ISO code (`rt: COUNTRY`).
library;

/// A destination as `isq.isc.iri[]` takes it.
class InsuranceDestination {
  const InsuranceDestination({
    required this.rkey,
    required this.label,
    this.rt = 'COUNTRY',
  });

  final String rkey;
  final String label;

  /// `COUNTRY` or `POPULARREGION`.
  final String rt;

  bool get isRegion => rt == 'POPULARREGION';

  Map<String, dynamic> toIri() => {'rkey': rkey, 'rt': rt};

  Map<String, dynamic> toJson() => {'rkey': rkey, 'label': label, 'rt': rt};

  factory InsuranceDestination.fromJson(Map<String, dynamic> json) =>
      InsuranceDestination(
        rkey: '${json['rkey'] ?? ''}',
        label: '${json['label'] ?? ''}',
        rt: '${json['rt'] ?? 'COUNTRY'}',
      );

  @override
  bool operator ==(Object other) =>
      other is InsuranceDestination && other.rkey == rkey && other.rt == rt;

  @override
  int get hashCode => Object.hash(rkey, rt);
}

/// `INSURANCE_POPULAR_REGIONS`.
const List<InsuranceDestination> kInsurancePopularRegions = [
  InsuranceDestination(rkey: 'ASI', label: 'Asia', rt: 'POPULARREGION'),
  InsuranceDestination(rkey: 'EUR', label: 'Europe', rt: 'POPULARREGION'),
  InsuranceDestination(rkey: 'SCH', label: 'Schengen', rt: 'POPULARREGION'),
  InsuranceDestination(rkey: 'WW', label: 'Worldwide', rt: 'POPULARREGION'),
];

/// `INSURANCE_COUNTRIES` — every country TripSafe includes, by ISO code.
const List<InsuranceDestination> kInsuranceCountries = [
  InsuranceDestination(rkey: 'AF', label: 'Afghanistan'),
  InsuranceDestination(rkey: 'AX', label: 'Aland Islands'),
  InsuranceDestination(rkey: 'AL', label: 'Albania'),
  InsuranceDestination(rkey: 'DZ', label: 'Algeria'),
  InsuranceDestination(rkey: 'AS', label: 'American Samoa'),
  InsuranceDestination(rkey: 'AD', label: 'Andorra'),
  InsuranceDestination(rkey: 'AO', label: 'Angola'),
  InsuranceDestination(rkey: 'AI', label: 'Anguilla'),
  InsuranceDestination(rkey: 'AQ', label: 'Antarctica'),
  InsuranceDestination(rkey: 'AG', label: 'Antigua and Barbuda'),
  InsuranceDestination(rkey: 'AR', label: 'Argentina'),
  InsuranceDestination(rkey: 'AM', label: 'Armenia'),
  InsuranceDestination(rkey: 'AW', label: 'Aruba'),
  InsuranceDestination(rkey: 'AC', label: 'Ascension Island'),
  InsuranceDestination(rkey: 'AU', label: 'Australia'),
  InsuranceDestination(rkey: 'AT', label: 'Austria'),
  InsuranceDestination(rkey: 'AZ', label: 'Azerbaijan'),
  InsuranceDestination(rkey: 'BS', label: 'Bahamas'),
  InsuranceDestination(rkey: 'BH', label: 'Bahrain'),
  InsuranceDestination(rkey: 'BD', label: 'Bangladesh'),
  InsuranceDestination(rkey: 'BB', label: 'Barbados'),
  InsuranceDestination(rkey: 'BY', label: 'Belarus'),
  InsuranceDestination(rkey: 'BE', label: 'Belgium'),
  InsuranceDestination(rkey: 'BZ', label: 'Belize'),
  InsuranceDestination(rkey: 'BJ', label: 'Benin'),
  InsuranceDestination(rkey: 'BM', label: 'Bermuda'),
  InsuranceDestination(rkey: 'BT', label: 'Bhutan'),
  InsuranceDestination(rkey: 'BO', label: 'Bolivia'),
  InsuranceDestination(rkey: 'BA', label: 'Bosnia and Herzegovina'),
  InsuranceDestination(rkey: 'BW', label: 'Botswana'),
  InsuranceDestination(rkey: 'BV', label: 'Bouvet Island'),
  InsuranceDestination(rkey: 'BR', label: 'Brazil'),
  InsuranceDestination(rkey: 'IO', label: 'British Indian Ocean Territory'),
  InsuranceDestination(rkey: 'VG', label: 'British Virgin Islands'),
  InsuranceDestination(rkey: 'BN', label: 'Brunei'),
  InsuranceDestination(rkey: 'BG', label: 'Bulgaria'),
  InsuranceDestination(rkey: 'BF', label: 'Burkina Faso'),
  InsuranceDestination(rkey: 'MM', label: 'Burma (Myanmar)'),
  InsuranceDestination(rkey: 'BI', label: 'Burundi'),
  InsuranceDestination(rkey: 'KH', label: 'Cambodia'),
  InsuranceDestination(rkey: 'CM', label: 'Cameroon'),
  InsuranceDestination(rkey: 'CA', label: 'Canada'),
  InsuranceDestination(rkey: 'CV', label: 'Cape Verde'),
  InsuranceDestination(rkey: 'KY', label: 'Cayman Islands'),
  InsuranceDestination(rkey: 'CF', label: 'Central African Republic'),
  InsuranceDestination(rkey: 'TD', label: 'Chad'),
  InsuranceDestination(rkey: 'CL', label: 'Chile'),
  InsuranceDestination(rkey: 'CN', label: 'China'),
  InsuranceDestination(rkey: 'CX', label: 'Christmas Island'),
  InsuranceDestination(rkey: 'CC', label: 'Cocos (Keeling) Islands'),
  InsuranceDestination(rkey: 'CO', label: 'Colombia'),
  InsuranceDestination(rkey: 'KM', label: 'Comoros'),
  InsuranceDestination(rkey: 'CG', label: 'Congo'),
  InsuranceDestination(rkey: 'CK', label: 'Cook Islands'),
  InsuranceDestination(rkey: 'CR', label: 'Costa Rica'),
  InsuranceDestination(rkey: 'HR', label: 'Croatia'),
  InsuranceDestination(rkey: 'CU', label: 'Cuba'),
  InsuranceDestination(rkey: 'CY', label: 'Cyprus'),
  InsuranceDestination(rkey: 'CZ', label: 'Czech Republic'),
  InsuranceDestination(rkey: 'CD', label: 'Democratic Republic of the Congo'),
  InsuranceDestination(rkey: 'DK', label: 'Denmark'),
  InsuranceDestination(rkey: 'DG', label: 'Diego Garcia'),
  InsuranceDestination(rkey: 'DJ', label: 'Djibouti'),
  InsuranceDestination(rkey: 'DM', label: 'Dominica'),
  InsuranceDestination(rkey: 'DO', label: 'Dominican Republic'),
  InsuranceDestination(rkey: 'EC', label: 'Ecuador'),
  InsuranceDestination(rkey: 'EG', label: 'Egypt'),
  InsuranceDestination(rkey: 'SV', label: 'El Salvador'),
  InsuranceDestination(rkey: 'GQ', label: 'Equatorial Guinea'),
  InsuranceDestination(rkey: 'ER', label: 'Eritrea'),
  InsuranceDestination(rkey: 'EE', label: 'Estonia'),
  InsuranceDestination(rkey: 'ET', label: 'Ethiopia'),
  InsuranceDestination(rkey: 'FK', label: 'Falkland Islands'),
  InsuranceDestination(rkey: 'FO', label: 'Faroe Islands'),
  InsuranceDestination(rkey: 'FJ', label: 'Fiji'),
  InsuranceDestination(rkey: 'FI', label: 'Finland'),
  InsuranceDestination(rkey: 'FR', label: 'France'),
  InsuranceDestination(rkey: 'GF', label: 'French Guiana'),
  InsuranceDestination(rkey: 'PF', label: 'French Polynesia'),
  InsuranceDestination(rkey: 'TF', label: 'French Southern Territories'),
  InsuranceDestination(rkey: 'GA', label: 'Gabon'),
  InsuranceDestination(rkey: 'GM', label: 'Gambia'),
  InsuranceDestination(rkey: 'GE', label: 'Georgia'),
  InsuranceDestination(rkey: 'DE', label: 'Germany'),
  InsuranceDestination(rkey: 'GH', label: 'Ghana'),
  InsuranceDestination(rkey: 'GI', label: 'Gibraltar'),
  InsuranceDestination(rkey: 'GR', label: 'Greece'),
  InsuranceDestination(rkey: 'GL', label: 'Greenland'),
  InsuranceDestination(rkey: 'GD', label: 'Grenada'),
  InsuranceDestination(rkey: 'GP', label: 'Guadeloupe'),
  InsuranceDestination(rkey: 'GU', label: 'Guam'),
  InsuranceDestination(rkey: 'GT', label: 'Guatemala'),
  InsuranceDestination(rkey: 'GG', label: 'Guernsey'),
  InsuranceDestination(rkey: 'GN', label: 'Guinea'),
  InsuranceDestination(rkey: 'GW', label: 'Guinea-Bissau'),
  InsuranceDestination(rkey: 'GY', label: 'Guyana'),
  InsuranceDestination(rkey: 'HT', label: 'Haiti'),
  InsuranceDestination(rkey: 'HM', label: 'Heard Island and Mcdonald Islands'),
  InsuranceDestination(rkey: 'VA', label: 'Holy See (Vatican City)'),
  InsuranceDestination(rkey: 'HN', label: 'Honduras'),
  InsuranceDestination(rkey: 'HK', label: 'Hong Kong'),
  InsuranceDestination(rkey: 'HU', label: 'Hungary'),
  InsuranceDestination(rkey: 'IS', label: 'Iceland'),
  InsuranceDestination(rkey: 'IN', label: 'India'),
  InsuranceDestination(rkey: 'ID', label: 'Indonesia'),
  InsuranceDestination(rkey: 'IR', label: 'Iran'),
  InsuranceDestination(rkey: 'IQ', label: 'Iraq'),
  InsuranceDestination(rkey: 'IE', label: 'Ireland'),
  InsuranceDestination(rkey: 'IM', label: 'Isle of Man'),
  InsuranceDestination(rkey: 'IL', label: 'Israel'),
  InsuranceDestination(rkey: 'IT', label: 'Italy'),
  InsuranceDestination(rkey: 'CI', label: 'Ivory Coast'),
  InsuranceDestination(rkey: 'JM', label: 'Jamaica'),
  InsuranceDestination(rkey: 'JP', label: 'Japan'),
  InsuranceDestination(rkey: 'JE', label: 'Jersey'),
  InsuranceDestination(rkey: 'JO', label: 'Jordan'),
  InsuranceDestination(rkey: 'KZ', label: 'Kazakhstan'),
  InsuranceDestination(rkey: 'KE', label: 'Kenya'),
  InsuranceDestination(rkey: 'KI', label: 'Kiribati'),
  InsuranceDestination(rkey: 'XK', label: 'Kosovo'),
  InsuranceDestination(rkey: 'KW', label: 'Kuwait'),
  InsuranceDestination(rkey: 'KG', label: 'Kyrgyzstan'),
  InsuranceDestination(rkey: 'LA', label: 'Laos'),
  InsuranceDestination(rkey: 'LV', label: 'Latvia'),
  InsuranceDestination(rkey: 'LB', label: 'Lebanon'),
  InsuranceDestination(rkey: 'LS', label: 'Lesotho'),
  InsuranceDestination(rkey: 'LR', label: 'Liberia'),
  InsuranceDestination(rkey: 'LY', label: 'Libya'),
  InsuranceDestination(rkey: 'LI', label: 'Liechtenstein'),
  InsuranceDestination(rkey: 'LT', label: 'Lithuania'),
  InsuranceDestination(rkey: 'LU', label: 'Luxembourg'),
  InsuranceDestination(rkey: 'MO', label: 'Macau'),
  InsuranceDestination(rkey: 'MK', label: 'Macedonia'),
  InsuranceDestination(rkey: 'MG', label: 'Madagascar'),
  InsuranceDestination(rkey: 'MW', label: 'Malawi'),
  InsuranceDestination(rkey: 'MY', label: 'Malaysia'),
  InsuranceDestination(rkey: 'MV', label: 'Maldives'),
  InsuranceDestination(rkey: 'ML', label: 'Mali'),
  InsuranceDestination(rkey: 'MT', label: 'Malta'),
  InsuranceDestination(rkey: 'MH', label: 'Marshall Islands'),
  InsuranceDestination(rkey: 'MQ', label: 'Martinique'),
  InsuranceDestination(rkey: 'MR', label: 'Mauritania'),
  InsuranceDestination(rkey: 'MU', label: 'Mauritius'),
  InsuranceDestination(rkey: 'YT', label: 'Mayotte'),
  InsuranceDestination(rkey: 'MX', label: 'Mexico'),
  InsuranceDestination(rkey: 'FM', label: 'Micronesia'),
  InsuranceDestination(rkey: 'MD', label: 'Moldova'),
  InsuranceDestination(rkey: 'MC', label: 'Monaco'),
  InsuranceDestination(rkey: 'MN', label: 'Mongolia'),
  InsuranceDestination(rkey: 'ME', label: 'Montenegro'),
  InsuranceDestination(rkey: 'MS', label: 'Montserrat'),
  InsuranceDestination(rkey: 'MA', label: 'Morocco'),
  InsuranceDestination(rkey: 'MZ', label: 'Mozambique'),
  InsuranceDestination(rkey: 'NA', label: 'Namibia'),
  InsuranceDestination(rkey: 'NR', label: 'Nauru'),
  InsuranceDestination(rkey: 'NP', label: 'Nepal'),
  InsuranceDestination(rkey: 'NL', label: 'Netherlands'),
  InsuranceDestination(rkey: 'AN', label: 'Netherlands Antilles'),
  InsuranceDestination(rkey: 'NC', label: 'New Caledonia'),
  InsuranceDestination(rkey: 'NZ', label: 'New Zealand'),
  InsuranceDestination(rkey: 'NI', label: 'Nicaragua'),
  InsuranceDestination(rkey: 'NE', label: 'Niger'),
  InsuranceDestination(rkey: 'NG', label: 'Nigeria'),
  InsuranceDestination(rkey: 'NU', label: 'Niue'),
  InsuranceDestination(rkey: 'NF', label: 'Norfolk Island'),
  InsuranceDestination(rkey: 'KP', label: 'North Korea'),
  InsuranceDestination(rkey: 'MP', label: 'Northern Mariana Islands'),
  InsuranceDestination(rkey: 'NO', label: 'Norway'),
  InsuranceDestination(rkey: 'OM', label: 'Oman'),
  InsuranceDestination(rkey: 'PK', label: 'Pakistan'),
  InsuranceDestination(rkey: 'PW', label: 'Palau'),
  InsuranceDestination(rkey: 'PS', label: 'Palestine'),
  InsuranceDestination(rkey: 'PA', label: 'Panama'),
  InsuranceDestination(rkey: 'PG', label: 'Papua New Guinea'),
  InsuranceDestination(rkey: 'PY', label: 'Paraguay'),
  InsuranceDestination(rkey: 'PE', label: 'Peru'),
  InsuranceDestination(rkey: 'PH', label: 'Philippines'),
  InsuranceDestination(rkey: 'PN', label: 'Pitcairn Islands'),
  InsuranceDestination(rkey: 'PL', label: 'Poland'),
  InsuranceDestination(rkey: 'PT', label: 'Portugal'),
  InsuranceDestination(rkey: 'PR', label: 'Puerto Rico'),
  InsuranceDestination(rkey: 'QA', label: 'Qatar'),
  InsuranceDestination(rkey: 'RE', label: 'Reunion Island'),
  InsuranceDestination(rkey: 'RO', label: 'Romania'),
  InsuranceDestination(rkey: 'RU', label: 'Russia'),
  InsuranceDestination(rkey: 'RW', label: 'Rwanda'),
  InsuranceDestination(rkey: 'BL', label: 'Saint Barthelemy'),
  InsuranceDestination(rkey: 'SH', label: 'Saint Helena'),
  InsuranceDestination(rkey: 'KN', label: 'Saint Kitts and Nevis'),
  InsuranceDestination(rkey: 'LC', label: 'Saint Lucia'),
  InsuranceDestination(rkey: 'MF', label: 'Saint Martin'),
  InsuranceDestination(rkey: 'PM', label: 'Saint Pierre and Miquelon'),
  InsuranceDestination(rkey: 'VC', label: 'Saint Vincent and the Grenadines'),
  InsuranceDestination(rkey: 'WS', label: 'Samoa'),
  InsuranceDestination(rkey: 'SM', label: 'San Marino'),
  InsuranceDestination(rkey: 'ST', label: 'Sao Tome and Principe'),
  InsuranceDestination(rkey: 'SA', label: 'Saudi Arabia'),
  InsuranceDestination(rkey: 'SN', label: 'Senegal'),
  InsuranceDestination(rkey: 'RS', label: 'Serbia'),
  InsuranceDestination(rkey: 'SC', label: 'Seychelles'),
  InsuranceDestination(rkey: 'SL', label: 'Sierra Leone'),
  InsuranceDestination(rkey: 'SG', label: 'Singapore'),
  InsuranceDestination(rkey: 'SX', label: 'Sint Maarten'),
  InsuranceDestination(rkey: 'SK', label: 'Slovakia'),
  InsuranceDestination(rkey: 'SI', label: 'Slovenia'),
  InsuranceDestination(rkey: 'SB', label: 'Solomon Islands'),
  InsuranceDestination(rkey: 'SO', label: 'Somalia'),
  InsuranceDestination(rkey: 'ZA', label: 'South Africa'),
  InsuranceDestination(
    rkey: 'GS',
    label: 'South Georgia and the South Sandwich Islands',
  ),
  InsuranceDestination(rkey: 'KR', label: 'South Korea'),
  InsuranceDestination(rkey: 'SS', label: 'South Sudan'),
  InsuranceDestination(rkey: 'ES', label: 'Spain'),
  InsuranceDestination(rkey: 'LK', label: 'Sri Lanka'),
  InsuranceDestination(rkey: 'SD', label: 'Sudan'),
  InsuranceDestination(rkey: 'SR', label: 'Suriname'),
  InsuranceDestination(rkey: 'SJ', label: 'Svalbard'),
  InsuranceDestination(rkey: 'SZ', label: 'Swaziland'),
  InsuranceDestination(rkey: 'SE', label: 'Sweden'),
  InsuranceDestination(rkey: 'CH', label: 'Switzerland'),
  InsuranceDestination(rkey: 'SY', label: 'Syria'),
  InsuranceDestination(rkey: 'TW', label: 'Taiwan'),
  InsuranceDestination(rkey: 'TJ', label: 'Tajikistan'),
  InsuranceDestination(rkey: 'TZ', label: 'Tanzania'),
  InsuranceDestination(rkey: 'TH', label: 'Thailand'),
  InsuranceDestination(rkey: 'TL', label: 'Timor-Leste (East Timor)'),
  InsuranceDestination(rkey: 'TG', label: 'Togo'),
  InsuranceDestination(rkey: 'TK', label: 'Tokelau'),
  InsuranceDestination(rkey: 'TO', label: 'Tonga Islands'),
  InsuranceDestination(rkey: 'TT', label: 'Trinidad and Tobago'),
  InsuranceDestination(rkey: 'TN', label: 'Tunisia'),
  InsuranceDestination(rkey: 'TR', label: 'Turkey'),
  InsuranceDestination(rkey: 'TM', label: 'Turkmenistan'),
  InsuranceDestination(rkey: 'TC', label: 'Turks and Caicos Islands'),
  InsuranceDestination(rkey: 'TV', label: 'Tuvalu'),
  InsuranceDestination(rkey: 'UG', label: 'Uganda'),
  InsuranceDestination(rkey: 'UA', label: 'Ukraine'),
  InsuranceDestination(rkey: 'AE', label: 'United Arab Emirates'),
  InsuranceDestination(rkey: 'GB', label: 'United Kingdom'),
  InsuranceDestination(rkey: 'US', label: 'United States'),
  InsuranceDestination(rkey: 'UY', label: 'Uruguay'),
  InsuranceDestination(rkey: 'VI', label: 'US Virgin Islands'),
  InsuranceDestination(rkey: 'UZ', label: 'Uzbekistan'),
  InsuranceDestination(rkey: 'VU', label: 'Vanuatu'),
  InsuranceDestination(rkey: 'VE', label: 'Venezuela'),
  InsuranceDestination(rkey: 'VN', label: 'Vietnam'),
  InsuranceDestination(rkey: 'WF', label: 'Wallis and Futuna'),
  InsuranceDestination(rkey: 'EH', label: 'Western Sahara'),
  InsuranceDestination(rkey: 'YE', label: 'Yemen'),
  InsuranceDestination(rkey: 'ZM', label: 'Zambia'),
  InsuranceDestination(rkey: 'ZW', label: 'Zimbabwe'),
];

/// The three plan types of the web's search panel, with the `ict` each sends
/// (`PLAN_TYPES`).
enum InsurancePlanType { international, student, annualMultiTrip }

extension InsurancePlanTypeInfo on InsurancePlanType {
  String get label => switch (this) {
    InsurancePlanType.international => 'International',
    InsurancePlanType.student => 'Student',
    InsurancePlanType.annualMultiTrip => 'Annual Multi Trip',
  };

  /// Null for international single-trip cover.
  String? get ict => switch (this) {
    InsurancePlanType.international => null,
    InsurancePlanType.student => 'STUDENT',
    InsurancePlanType.annualMultiTrip => 'AMT',
  };
}

/// Student cover lengths, 1 month to 2 years (`COVERAGE_DURATIONS`).
const List<({int days, String label})> kStudentCoverageDurations = [
  (days: 30, label: '1 Month'),
  (days: 60, label: '2 Months'),
  (days: 90, label: '3 Months'),
  (days: 120, label: '4 Months'),
  (days: 150, label: '5 Months'),
  (days: 180, label: '6 Months'),
  (days: 210, label: '7 Months'),
  (days: 240, label: '8 Months'),
  (days: 270, label: '9 Months'),
  (days: 300, label: '10 Months'),
  (days: 330, label: '11 Months'),
  (days: 365, label: '1 Year'),
  (days: 730, label: '2 Years'),
];

/// Annual multi-trip: the longest single trip covered (`AMT_DURATIONS`).
const List<({int days, String label})> kAmtTripDurations = [
  (days: 30, label: '30 Days'),
  (days: 45, label: '45 Days'),
  (days: 60, label: '60 Days'),
];

/// Annual multi-trip destinations (`AMT_DESTINATIONS`), always popular
/// regions.
const List<InsuranceDestination> kAmtDestinations = [
  InsuranceDestination(rkey: 'WW', label: 'Worldwide', rt: 'POPULARREGION'),
  InsuranceDestination(
    rkey: 'WWXUSCA',
    label: 'Worldwide excl US & Canada',
    rt: 'POPULARREGION',
  ),
];

/// The web's limits and defaults for the search panel.
class InsuranceLimits {
  const InsuranceLimits._();

  /// 1–6 travellers on every plan type.
  static const int minTravellers = 1;
  static const int maxTravellers = 6;

  /// International: ages 1–99, defaulting to 30.
  static const int minAge = 1;
  static const int maxAge = 99;
  static const int defaultAge = 30;

  /// Student: the age picker offers 16–50; an unknown age searches as 22.
  static const int minStudentAge = 16;
  static const int maxStudentAge = 50;
  static const int defaultStudentAge = 22;

  /// TripJack rejects any search whose `ed` is 180 or more days after `sd`
  /// ("must be less than or equal to 180 days" — it counts both ends), so the
  /// latest end date is start + 179. Verified live on 2026-09-19: +179 is
  /// accepted, +180 is refused. The web's own `+ 180` default hits this.
  static const int maxPolicyWindowDays = 179;

  /// Annual multi-trip: the age picker offers 1–80; the policy window is
  /// TripJack's limit above.
  static const int maxAmtAge = 80;
  // static const int amtMaxWindowDays = 180; // the web's value; refused live
  static const int amtMaxWindowDays = maxPolicyWindowDays;

  /// Dates open a week out, for a two-day trip, as the web does.
  static const int defaultStartOffsetDays = 7;
  static const int defaultTripDays = 2;
  static const int defaultStudentCoverageDays = 180;
  static const int defaultAmtTripDays = 45;
}

/// Nominee relations the booking form offers (`NOMINEE_RELATIONS`).
const List<String> kInsuranceNomineeRelations = [
  'LEGAL HEIR',
  'SPOUSE',
  'FATHER',
  'MOTHER',
  'SON',
  'DAUGHTER',
  'BROTHER',
  'SISTER',
];

/// Insurer codes the payload carries, and how the web names them.
const Map<String, String> kInsurerLabels = {
  'ABHI': 'Aditya Birla Health Insurance',
};

String insurerLabelFor(String code) {
  final upper = code.toUpperCase();
  return kInsurerLabels[upper] ??
      (code.isEmpty ? 'Insurance partner' : '$code Insurance');
}

/// The declaration the web asks the customer to accept before booking.
const String kInsuranceDeclaration =
    'I confirm that all passengers are Indian nationals between 0 to 80 years '
    'of age, have authorised me to add Insurance, and agree to the T&C';

/// The web's disclaimer under the booking form.
const String kInsuranceDisclaimer =
    'Insurance is through a group master policy with Aditya Birla Health '
    'Insurance.';
