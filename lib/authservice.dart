
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

  /// Data that belongs to whoever was signed in but lives outside the session
  /// keys — locally cached wishlists, chat history, booking drafts with names
  /// and phone numbers, saved GST profiles, unsent drafts. Wiped when a signed-in
  /// session ends so the next person on this device (guest or another account)
  /// never sees it.
  ///
  /// Deliberately *not* here: public caches (`ResponseCache`), recent flight
  /// searches, app config — nothing that identifies the previous user.
  static const List<String> userScopedKeys = [
    'favourite_venues', // VenuesScreen wishlist hearts
    'favourite_vendors', // VendorDetailsScreen wishlist hearts
    'chat_messages', // AiChatScreen history
    'shaadi_ai_chats', // Shaadi AI history
    'wedding_personality_profile', // Shaadi AI quiz result
    'genie_session_id',
    'genie_local_messages',
    'hw:bookingDraft', // honeymoon hotel draft (traveller names/contact)
    'hw:cabBookingDraft', // honeymoon cab draft (name/email/phone)
    'hw_gst_history', // saved company GST profiles
    'hw_traveller_hidden',
    'movment_plus_guest_token', // Moments+ event gallery access code
    'real_wedding_story_draft', // unsent Real Wedding story
    'checklist_start_date',
    'invite_template', // guest-list invite message
    'draftList', // legacy e-invite drafts
    'drafts',
  ];

  /// Prefix of legacy per-card e-invite drafts (`draft_<cardId>`).
  static const String einviteDraftPrefix = 'draft_';

  /// Removes [userScopedKeys] and legacy e-invite drafts. Only called when a
  /// signed-in session ends — never for a guest, whose own drafts (e.g. a
  /// booking parked before sign-in) must survive until they sign in.
  static Future<void> clearUserScopedData() async {
    final prefs = await _prefs();
    for (final key in userScopedKeys) {
      await prefs.remove(key);
    }
    for (final key in prefs.getKeys().toList()) {
      if (key.startsWith(einviteDraftPrefix)) await prefs.remove(key);
    }
  }

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

/// The three states the app can be in with respect to authentication.
///
/// [guest] is a legitimate, first-class state — the public app is fully usable
/// in it. It is *not* a fake signed-in user: there is no user id and no token.
enum AuthStatus {
  /// The stored session has not been read yet (app is still starting up).
  unknown,

  /// No valid session. Public features work; protected actions ask to sign in.
  guest,

  /// A valid, unexpired session is stored.
  authenticated,
}

/// Why the app last went from signed-in to guest. Lets the UI tell a
/// deliberate logout apart from a session that expired on its own.
enum SignOutReason { none, userLogout, sessionExpired }

/// Single source of truth for "is somebody signed in right now".
///
/// It never holds a hardcoded state: [refresh] always re-reads the persisted
/// session written by [UserPrefs], so a missing, incomplete or expired token
/// resolves to [AuthStatus.guest]. Listeners (the app's `AuthGate`) rebuild
/// whenever that answer changes. Login is never required to open the app —
/// protected actions request it through `requireAuthentication()`.
class AuthSession extends ChangeNotifier {
  AuthSession._();

  static final AuthSession instance = AuthSession._();

  /// A stored token older than this is treated as expired.
  static const int tokenExpiryDays = 2;

  bool _ready = false;
  bool _authenticated = false;

  /// Bumped every time a signed-in session ends (logout or expiry). The app
  /// shell is keyed on it, so every screen that loaded the previous user's
  /// data is rebuilt from scratch instead of showing it to the guest.
  int _sessionEpoch = 0;

  SignOutReason _lastSignOutReason = SignOutReason.none;

  /// False until the first [refresh] completes — the app shows the splash
  /// until then so the UI never flickers between guest and signed-in.
  bool get isReady => _ready;

  bool get isAuthenticated => _authenticated;

  /// True once startup has finished and nobody is signed in.
  bool get isGuest => _ready && !_authenticated;

  AuthStatus get status => !_ready
      ? AuthStatus.unknown
      : (_authenticated ? AuthStatus.authenticated : AuthStatus.guest);

  int get sessionEpoch => _sessionEpoch;

  SignOutReason get lastSignOutReason => _lastSignOutReason;

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
      // The signed-in session just expired: its private data goes too.
      if (_authenticated) await UserPrefs.clearUserScopedData();
    }
    return _publish(valid, reason: SignOutReason.sessionExpired);
  }

  /// Clears the session everywhere: local storage plus the Google/Firebase
  /// providers, then notifies listeners so the app drops back to guest mode.
  ///
  /// [reason] defaults to [SignOutReason.sessionExpired] because every caller
  /// other than the Log out button is reacting to a rejected token (401).
  Future<void> signOut({
    SignOutReason reason = SignOutReason.sessionExpired,
  }) async {
    await UserPrefs.clear();
    // A guest has no previous user's data to protect — and may have a booking
    // draft parked for after sign-in, which must survive.
    if (_authenticated) await UserPrefs.clearUserScopedData();

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

    _publish(false, reason: reason);
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

  bool _publish(
    bool authenticated, {
    SignOutReason reason = SignOutReason.none,
  }) {
    final changed = !_ready || _authenticated != authenticated;
    if (_authenticated && !authenticated) {
      // A signed-in session just ended.
      _sessionEpoch++;
      _lastSignOutReason = reason;
    } else if (authenticated) {
      _lastSignOutReason = SignOutReason.none;
    }
    _ready = true;
    _authenticated = authenticated;
    if (changed) notifyListeners();
    return authenticated;
  }
}