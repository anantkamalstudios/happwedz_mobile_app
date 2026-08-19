
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserPrefs {
  /// Keys the signed-in session is stored under. Kept as constants so the
  /// session, the screens and the logout flow can never drift apart.
  static const String isLoggedInKey = 'is_logged_in';

  /// Older flag still written by some screens; kept in sync for compatibility.
  static const String legacyIsLoggedInKey = 'isLoggedIn';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userPhoneKey = 'user_phone';
  static const String userMobileKey = 'user_mobile';
  static const String userPhotoKey = 'user_photo';
  static const String tokenKey = 'auth_token';
  static const String tokenSavedAtKey = 'token_saved_at';
  static const String weddingVenueKey = 'wedding_venue';
  static const String weddingDateKey = 'wedding_date';

  /// Everything that belongs to the signed-in user. Wiped on logout so a
  /// second account never sees the first account's cached profile.
  static const List<String> sessionKeys = [
    isLoggedInKey,
    legacyIsLoggedInKey,
    userIdKey,
    userNameKey,
    userEmailKey,
    userPhoneKey,
    userMobileKey,
    userPhotoKey,
    tokenKey,
    tokenSavedAtKey,
    weddingVenueKey,
    weddingDateKey,
  ];

  static Future<SharedPreferences> _prefs() async {
    return await SharedPreferences.getInstance();
  }

  /// Save values
  static Future<void> saveUser({
    required int id,
    required String name,
    required String email,
    required String token,
    String? phone,
    String? photo,
  }) async {
    final prefs = await _prefs();
    await prefs.setBool(isLoggedInKey, true);
    await prefs.setBool(legacyIsLoggedInKey, true);
    await prefs.setInt(userIdKey, id);
    await prefs.setString(userNameKey, name);
    await prefs.setString(userEmailKey, email);
    await prefs.setString(tokenKey, token);
    await prefs.setString(userPhoneKey, phone ?? "");
    await prefs.setString(userPhotoKey, photo ?? "");
    // Stamps when the token was issued so expiry can be checked later.
    await prefs.setString(tokenSavedAtKey, DateTime.now().toIso8601String());
  }

  /// Check login status
  static Future<bool> isLoggedIn() async {
    final prefs = await _prefs();
    return prefs.getBool(isLoggedInKey) ?? false;
  }

  /// Get user values
  static Future<int?> getUserId() async {
    final prefs = await _prefs();
    return prefs.getInt(userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await _prefs();
    return prefs.getString(userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await _prefs();
    return prefs.getString(userEmailKey);
  }

  static Future<String?> getUserPhoto() async {
    final prefs = await _prefs();
    return prefs.getString(userPhotoKey);
  }

  static Future<String?> getToken() async {
    final prefs = await _prefs();
    return prefs.getString(tokenKey);
  }

  /// Logout — removes every user-specific key, leaving app-level preferences
  /// (theme, onboarding, …) untouched.
  static Future<void> clear() async {
    final prefs = await _prefs();
    for (final key in sessionKeys) {
      await prefs.remove(key);
    }
  }
}

/// Single source of truth for "is somebody signed in right now".
///
/// It never holds a hardcoded state: [refresh] always re-reads the persisted
/// session written by [UserPrefs], so a missing, incomplete or expired token
/// resolves to *not authenticated*. Listeners (the app's `AuthGate`) rebuild
/// whenever that answer changes, which is what makes login mandatory app-wide.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  /// A stored token older than this is treated as expired.
  static const int tokenExpiryDays = 2;

  bool _ready = false;
  bool _authenticated = false;

  /// False until the first [refresh] completes — the app shows the splash
  /// until then so a protected screen is never flashed at a signed-out user.
  bool get isReady => _ready;

  bool get isAuthenticated => _authenticated;

  /// Re-reads the stored session and publishes the result.
  ///
  /// Called on startup, when the app resumes (the token may have expired while
  /// it slept) and right after a successful sign-in has been persisted.
  Future<bool> refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final valid = await _hasValidSession(prefs);
    if (!valid) {
      // Drop half-written or expired sessions so nothing downstream can read
      // a stale token out of preferences.
      await UserPrefs.clear();
    }
    return _publish(valid);
  }

  /// Clears the session everywhere: local storage plus the Google/Firebase
  /// providers, then notifies listeners so the app returns to the login screen.
  Future<void> signOut() async {
    await UserPrefs.clear();

    // Provider sign-out is best effort — a failure here must not leave the
    // user stuck in a half-logged-out state.
    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      debugPrint('Google sign-out failed: $e');
    }
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      debugPrint('Firebase sign-out failed: $e');
    }

    _publish(false);
  }

  Future<bool> _hasValidSession(SharedPreferences prefs) async {
    final token = prefs.getString(UserPrefs.tokenKey);
    if (token == null || token.trim().isEmpty) return false;

    final userId = prefs.getInt(UserPrefs.userIdKey);
    if (userId == null || userId <= 0) return false;

    return !await _isExpired(prefs);
  }

  Future<bool> _isExpired(SharedPreferences prefs) async {
    final savedAt = prefs.getString(UserPrefs.tokenSavedAtKey);
    if (savedAt == null) {
      // Session saved before issue-time stamping existed: adopt it now rather
      // than signing a valid user out, and start the clock from here.
      await prefs.setString(
        UserPrefs.tokenSavedAtKey,
        DateTime.now().toIso8601String(),
      );
      return false;
    }

    final issuedAt = DateTime.tryParse(savedAt);
    if (issuedAt == null) return true;

    return DateTime.now().difference(issuedAt).inDays >= tokenExpiryDays;
  }

  bool _publish(bool authenticated) {
    final changed = !_ready || _authenticated != authenticated;
    _ready = true;
    _authenticated = authenticated;
    if (changed) notifyListeners();
    return authenticated;
  }
}