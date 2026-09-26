/// Single place for the backend hosts every module (other than Honeymoon,
/// which has its own `HoneymoonConfig`) talks to.
///
/// Before this file existed, `https://happywedz.com` (and its equivalents)
/// were typed as a raw string literal at ~150 call sites across ~25 files.
/// The backend has since consolidated `happywedz.com`, `www.happywedz.com`,
/// `happywedzbackend.happywedz.com` and the old `shaadiai.happywedz.com` AI
/// subdomain onto a single `api.happywedz.com` host (AI traffic under the
/// `/ai` path) — [backendBaseUrl] and [aiChatBaseUrl] are kept as separate
/// constants below only so call sites stay self-documenting about which
/// backend surface they're hitting.
library;

class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = 'https://api.happywedz.com';
  static const String apiBase = 'https://api.happywedz.com';

  /// Origin of the **public website**, as opposed to the API.
  ///
  /// These are different hosts and are not interchangeable. Anything a user
  /// can open in a browser — a shared wedding-website link, a wedding-form
  /// template page — belongs here; [baseUrl] serves JSON only and answers
  /// such paths with 404. Verified live:
  ///
  ///   https://api.happywedz.com/wedding/<slug>  -> 404 route not found
  ///   https://happywedz.com/wedding/<slug>      -> 200
  ///
  /// The website builds the same links from `window.location.origin`
  /// (`getPublicUrl` in `weddingWebsiteApi.js`), i.e. its own origin — which
  /// is this host, never the API one.
  static const String webAppBaseUrl = 'https://happywedz.com';

  /// Backend surface used by a handful of screens (venues, home feed,
  /// vendor detail, wishlist, real-wedding stories).
  static const String backendBaseUrl = 'https://api.happywedz.com';

  /// Genie chat assistant (GenieScreen / ai_chat_screen) and ShaadiAI.
  static const String aiChatBaseUrl = 'https://api.happywedz.com/ai';

  /// Movment Plus' face-matching service — a distinct `/ai/api` path off the
  /// main domain, not the Shaadi AI subdomain above. Identifies the caller by
  /// an `X-User-ID` header rather than the JWT, and matching can take up to a
  /// few minutes (dlib CNN face comparison), so callers need a long timeout.
  static const String movmentPlusAiBaseUrl = 'https://www.happywedz.com/ai/api';

  /// SharedPreferences key the rest of the app stores the JWT under.
  static const String authTokenKey = 'auth_token';
}
