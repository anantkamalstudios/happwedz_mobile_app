// AUDIT NOTE:
// `checkPlayServices()` is never imported or called anywhere in `lib/`, so the
// Play Services availability check it performs never runs. It is worth wiring
// up before the Google sign-in flow on devices without Play Services — that is
// a product decision, not a bug fix, so it is left to the project owner.
// Kept intentionally and commented out as requested.
// Do not remove without confirming with the project owner.
//
// import 'package:google_api_availability/google_api_availability.dart';
//
// void checkPlayServices() async {
//   final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
//   print('Google Play Services status: $availability');
// }