/// Field definitions for the Matrimonial module.
///
/// Ported from the form state in `src/components/pages/matrimonial/
/// MatrimonialRegistration.jsx` (registration wizard), `Search.jsx` (advanced
/// search filters), `ProfileMatrimonial.jsx` (browse grooms/brides filters)
/// and `dashboard/EditProfile.jsx` (edit-profile fields).
///
/// IMPORTANT — see MIGRATION_NOTES.md's Matrimonial section: this module has
/// no backend anywhere in the source (confirmed by reading all ~26 files).
/// These classes exist only to hold what a person types into the forms below
/// for the lifetime of that screen — nothing here is ever sent anywhere or
/// persisted, and nothing here is pre-filled with fake data.
library;

/// One option list shared by every screen that asks for mother tongue.
///
/// The source's `Search.jsx` list included two junk placeholder entries
/// ("hdhgjhs", "dfeff") — an authoring mistake, not real data. Dropped here;
/// this is the real list used everywhere instead (registration, search,
/// browse filters, edit profile).
const List<String> kMotherTongues = [
  'Hindi',
  'English',
  'Bengali',
  'Tamil',
  'Telugu',
  'Marathi',
  'Gujarati',
  'Punjabi',
  'Kannada',
  'Malayalam',
  'Urdu',
  'Odia',
];

const List<String> kReligions = [
  'Hindu',
  'Muslim',
  'Christian',
  'Sikh',
  'Jain',
];

/// Castes offered depend on the chosen religion, exactly as in
/// `MatrimonialRegistration.jsx` (only Hindu and Muslim had options there;
/// other religions had none in the source, reproduced as-is).
const Map<String, List<String>> kCastesByReligion = {
  'Hindu': ['Brahmin', 'Maratha', 'Rajput'],
  'Muslim': ['Sunni', 'Shia'],
};

/// Wider caste list used by the browse/search filters, which are not gated
/// by a chosen religion in the source (`Search.jsx`, `ProfileMatrimonial.jsx`).
const List<String> kCasteFilterOptions = [
  'Any',
  'Brahmin',
  'Rajput',
  'Maratha',
  'Baniya',
];

const List<String> kProfileForOptions = [
  'Self',
  'Son',
  'Daughter',
  'Brother',
  'Sister',
];

const List<String> kProfileTypeOptions = ['Bride', 'Groom'];

const List<String> kFamilyTypes = [
  'Joint Family',
  'Nuclear Family',
  'Separate Family',
];

enum Manglik { manglik, nonManglik, dontKnow }

extension ManglikLabel on Manglik {
  String get label => switch (this) {
        Manglik.manglik => 'Manglik',
        Manglik.nonManglik => 'Non-manglik',
        Manglik.dontKnow => "Don't know",
      };
}

const List<String> kMaritalStatuses = [
  'Never Married',
  'Divorced',
  'Widowed',
  'Separated',
];

const List<String> kEducations = [
  'B.Tech',
  'MBA',
  'B.Sc',
  'M.Sc',
  'Ph.D',
  'MBBS',
  'B.Com',
];

const List<String> kEducationFields = [
  'Engineering',
  'Medicine',
  'Arts',
  'Commerce',
];

const List<String> kProfessions = [
  'Engineer',
  'Doctor',
  'Teacher',
  'Business',
  'Government Job',
];

const List<String> kIncomes = [
  'No Income',
  'Below 1 Lakh',
  '1-2 Lakhs',
  '2-5 Lakhs',
  '5+ Lakhs',
];

const List<String> kDiets = ['Vegetarian', 'Non-Vegetarian', 'Eggetarian', 'Jain'];

const List<String> kYesNoSometimes = ['No', 'Occasionally', 'Yes'];

const List<String> kBodyTypes = ['Slim', 'Average', 'Athletic', 'Heavy'];

const List<String> kHeights = [
  '4\'8"',
  '4\'10"',
  '5\'0"',
  '5\'2"',
  '5\'4"',
  '5\'6"',
  '5\'8"',
  '5\'10"',
  '6\'0"',
  '6\'2"',
];

const List<String> kCountries = ['India', 'USA', 'UK', 'Canada', 'Australia'];

const List<String> kStates = ['Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu'];

const List<String> kCities = [
  'Mumbai',
  'Delhi',
  'Bangalore',
  'Chennai',
  'Hyderabad',
  'Pune',
  'Kolkata',
  'Ahmedabad',
  'Surat',
  'Jaipur',
  'Lucknow',
];

const List<String> kCommunities = [
  'Iyer',
  'Iyengar',
  'Namboothiri',
  'Saraswat',
  'Kanyakubj',
  'Kulin',
  'Niyogi',
  'Havyaka',
  'Kota',
  'Kashmiri Pandit',
];

/// Registration wizard state — `MatrimonialRegistration.jsx`'s `formData`.
///
/// Field-for-field port; the two source fields that only ever fed the JS
/// component's own local flow (`phoneVerified`, `errors`) are handled by the
/// registration page's own state instead of living here, since they are UI
/// state, not profile data.
class MatrimonialRegistrationDraft {
  String profileFor = '';
  String profileType = '';
  String name = '';
  bool showName = true;
  DateTime? dob;
  String motherTongue = '';
  String religion = '';
  String caste = '';
  bool casteNoBar = false;
  Manglik manglik = Manglik.nonManglik;
  String phone = '';

  String familyType = '';
  int brothers = 0;
  int marriedBrothers = 0;
  int unmarriedBrothers = 0;
  int sisters = 0;
  int marriedSisters = 0;
  int unmarriedSisters = 0;
  String fatherOccupation = '';
  String motherOccupation = '';

  String aboutYourself = '';
  String hobbies = '';
  String partnerExpectations = '';

  /// Mirrors `validateStep(1)` in the source.
  Map<String, String> validateStep1() {
    final errors = <String, String>{};
    if (profileFor.trim().isEmpty) {
      errors['profileFor'] = 'Profile for is required';
    }
    if (profileType.trim().isEmpty) {
      errors['profileType'] = 'Profile type is required';
    }
    if (name.trim().isEmpty) {
      errors['name'] = 'Name is required';
    }
    if (dob == null) {
      errors['dob'] = 'Date of birth is required';
    }
    return errors;
  }

  /// Mirrors `validateStep(4)` in the source (phone, exactly 10 digits).
  static String? validatePhone(String phone) {
    if (phone.isEmpty) return 'Phone number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  String get nameLabel {
    if (profileType == 'Groom') return "Groom's Name";
    if (profileType == 'Bride') return "Bride's Name";
    return 'Name';
  }
}

/// `Search.jsx`'s category-search form — three nested sections, unchanged.
class MatrimonialSearchFilters {
  MatrimonialSearchFilters();

  String minAge = '25';
  String maxAge = '35';
  String maritalStatus = 'Any';
  String religion = 'Any';
  String caste = 'Any';
  String motherTongue = 'Any';
  String country = 'India';
  String state = 'Any';
  String city = 'Any';

  String education = 'Any';
  String educationField = 'Any';
  String profession = 'Any';
  String income = 'Any';

  String diet = 'Any';
  String smoke = 'Any';
  String drink = 'Any';
  String bodyType = 'Any';

  void reset() {
    minAge = '25';
    maxAge = '35';
    maritalStatus = 'Any';
    religion = 'Any';
    caste = 'Any';
    motherTongue = 'Any';
    country = 'India';
    state = 'Any';
    city = 'Any';
    education = 'Any';
    educationField = 'Any';
    profession = 'Any';
    income = 'Any';
    diet = 'Any';
    smoke = 'Any';
    drink = 'Any';
    bodyType = 'Any';
  }
}

/// `ProfileMatrimonial.jsx`'s "Refine Search" filter panel (browse grooms /
/// brides). A separate shape from [MatrimonialSearchFilters] because the
/// source keeps them as two independent, differently-structured forms.
class MatrimonialBrowseFilters {
  List<String> selectedCities = ['All Cities'];
  AgeRange ageRange = const AgeRange(25, 35);
  String minHeight = '5\'4"';
  String maxHeight = '6\'0"';
  List<String> maritalStatuses = ['Never Married'];
  String education = '';
  String profession = '';
  String income = '';
  List<String> diets = ['Vegetarian'];
  String motherTongue = '';
  String community = '';

  void reset() {
    selectedCities = ['All Cities'];
    ageRange = const AgeRange(25, 35);
    minHeight = '5\'4"';
    maxHeight = '6\'0"';
    maritalStatuses = ['Never Married'];
    education = '';
    profession = '';
    income = '';
    diets = ['Vegetarian'];
    motherTongue = '';
    community = '';
  }
}

/// Plain min/max holder for the age-range filter. Kept independent of
/// `package:flutter`'s `RangeValues` so this model file has no Flutter
/// dependency (same convention as `wedding_website_models.dart`); the UI
/// layer converts to/from the real `RangeValues` when it builds a slider.
class AgeRange {
  const AgeRange(this.min, this.max);
  final double min;
  final double max;
}

/// `dashboard/EditProfile.jsx`'s field set. Starts entirely blank — the
/// source pre-fills this with a hardcoded fake person ("Priya Sharma" etc.),
/// which this port deliberately does not reproduce (see MIGRATION_NOTES.md).
class MatrimonialEditProfileFields {
  String name = '';
  String email = '';
  String phone = '';
  DateTime? dob;
  String height = '';
  String maritalStatus = '';
  String religion = '';
  String caste = '';
  String motherTongue = '';
  String location = '';
  String education = '';
  String profession = '';
  String income = '';
  String about = '';
  String hobbies = '';
}
