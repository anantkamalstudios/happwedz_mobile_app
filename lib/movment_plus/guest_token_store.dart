/// Persists the last gallery access token a guest successfully verified, so
/// screens reached outside the direct token-entry flow (the bottom-nav
/// "Upload Selfie" tab, the dashboard's "Free Signup" card) know which
/// gallery/event to match selfies against. Mirrors the website's
/// `guestToken` Redux slice, which does the same via `localStorage`.
library;

import 'package:shared_preferences/shared_preferences.dart';

class GuestTokenStore {
  const GuestTokenStore._();

  static const String _key = 'movment_plus_guest_token';

  static Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  static Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_key);
    return (token == null || token.isEmpty) ? null : token;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
