import 'package:flutter/foundation.dart';

/// The city the user is browsing, shared across tabs.
///
/// Home owns the picker (and persists it under `selected_city`); the Venues
/// tab listens so it lists the same city, as the website's listings use the
/// stored location. `null` means all cities.
class SelectedCity {
  SelectedCity._();

  static final ValueNotifier<String?> notifier = ValueNotifier<String?>(null);

  static String? get value => notifier.value;

  static void set(String? city) {
    final c = (city ?? '').trim();
    notifier.value = c.isEmpty ? null : c;
  }
}
