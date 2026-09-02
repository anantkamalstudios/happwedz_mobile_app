/// Single place for the backend hosts every module (other than Honeymoon,
/// which has its own `HoneymoonConfig`) talks to.
///
/// Before this file existed, `https://happywedz.com` (and its equivalents)
/// were typed as a raw string literal at ~150 call sites across ~25 files.
/// `happywedz.com`, `www.happywedz.com` and `happywedzbackend.happywedz.com`
/// all resolve to the same server (69.62.85.170) — `www` is folded into
/// [baseUrl] below since it serves nothing distinct; `happywedzbackend` and
/// the AI subdomain are kept separate because a handful of screens
/// deliberately call them for specific endpoints.
library;

class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://happywedz.com';
  static const String apiBase = 'https://happywedz.com/api';

  /// Dedicated backend subdomain used by a handful of screens (venues,
  /// home feed, vendor detail, wishlist, real-wedding stories).
  static const String backendBaseUrl = 'https://happywedzbackend.happywedz.com';

  /// Shaadi AI chat assistant.
  static const String aiChatBaseUrl = 'https://shaadiai.happywedz.com';

  /// SharedPreferences key the rest of the app stores the JWT under.
  static const String authTokenKey = 'auth_token';
}
