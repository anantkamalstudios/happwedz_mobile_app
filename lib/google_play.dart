import 'package:google_api_availability/google_api_availability.dart';

void checkPlayServices() async {
  final availability = await GoogleApiAvailability.instance.checkGooglePlayServicesAvailability();
  print('Google Play Services status: $availability');
}
