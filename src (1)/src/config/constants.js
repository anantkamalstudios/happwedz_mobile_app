// API Configuration
export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  "https://api.happywedz.com";
// Host that serves relative upload paths (/uploads/...) written by the backend.
export const IMAGE_BASE_URL =
  (
    import.meta.env.VITE_API_BASE_URL ||
    import.meta.env.VITE_API_URL ||
    "https://api.happywedz.com"
  ).replace(/\/+$/, "") + "/";

// General AI service (recommendations, design studio, etc).
export const AI_API_BASE_URL =
  import.meta.env.VITE_AI_API_BASE_URL || "https://www.happywedz.com/ai/api";

// Beauty/AI service (try-on uploads, makeup, product filters).
export const BEAUTY_API_BASE_URL = (
  import.meta.env.VITE_BEAUTY_API_BASE_URL || "https://www.happywedz.com/ai/api"
).replace(/\/+$/, "");

// Genie (Shaadi AI chat assistant) service.
export const SHADI_AI_API_BASE_URL =
  import.meta.env.VITE_SHADI_AI_API_BASE_URL ||
  "https://shaadiai.happywedz.com/api";

// Origin of the HappyWedz Store subdomain (see VITE_STORE_ORIGIN in .env).
export const STORE_ORIGIN =
  import.meta.env.VITE_STORE_ORIGIN || "https://store.happywedz.com";

// Legacy vendor media rows store absolute URLs against the S3 bucket's REST
// endpoint, and that bucket is the origin that actually holds the files — so the
// URL is passed through untouched by default. Point VITE_IMAGE_CDN_URL at a
// CloudFront (or other CDN) domain to serve the same keys from the edge instead.
//
// These URLs must never be rewritten to the web host: happywedz.com has no
// /uploads route, so it answers every such request with the SPA's index.html,
// which the browser cannot decode and every card falls back to the placeholder.
export const LEGACY_S3_ORIGIN =
  "https://happywedz-s3-bucket.s3.ap-south-1.amazonaws.com";

export const IMAGE_CDN_BASE_URL = (
  import.meta.env.VITE_IMAGE_CDN_URL || LEGACY_S3_ORIGIN
).replace(/\/+$/, "");

/** Map a stored media URL onto whichever origin currently serves the bucket. */
export const toCdnUrl = (url) =>
  typeof url === "string" && url.startsWith(LEGACY_S3_ORIGIN)
    ? IMAGE_CDN_BASE_URL + url.slice(LEGACY_S3_ORIGIN.length)
    : url;

// Host that the legacy CMS rows were written against, back when the API and the
// web app shared an origin. happywedz.com has no /uploads route today, so any
// such URL has to be moved onto the API origin or it resolves to index.html.
const LEGACY_UPLOAD_ORIGINS = [
  // The retired cPanel backend. Its DNS no longer resolves, so rows still
  // pointing at it hang until the browser gives up rather than failing fast.
  "https://happywedzbackend.happywedz.com",
  "http://happywedzbackend.happywedz.com",
  "https://happywedz.com:4000",
  "http://happywedz.com:4000",
  "https://happywedz.com",
  "http://happywedz.com",
];

const API_ORIGIN = IMAGE_BASE_URL.replace(/\/+$/, "");

// encodeURI escapes "%" itself, so running it over an already-encoded key turns
// %23 into %2523 and the request 404s. Several blog uploads are named after
// hashtags and carry %23 throughout, so only encode what is not encoded yet.
const encodeOnce = (url) => (/%[0-9A-Fa-f]{2}/.test(url) ? url : encodeURI(url));

/**
 * Resolve whatever a CMS row holds into a URL the browser can actually load.
 *
 * Home-page media now arrives in three shapes and every section has to cope
 * with all of them:
 *   - absolute S3 URLs      — everything uploaded since the S3 cutover
 *   - relative /uploads/... — rows written before it, still served off the API
 *   - legacy absolute URLs  — rows pointing at the retired shared origin
 *
 * Replaces the per-component string surgery each section used to carry.
 */
export const resolveMediaUrl = (value, fallback = null) => {
  if (!value || typeof value !== "string") return fallback;

  // Some rows were saved with stray backticks around the URL.
  const raw = value.replace(/`/g, "").trim();
  if (!raw) return fallback;

  if (/^data:/i.test(raw)) return raw;

  let url = raw;

  if (/^https?:\/\//i.test(url)) {
    const legacy = LEGACY_UPLOAD_ORIGINS.find(
      (origin) =>
        url.startsWith(`${origin}/uploads/`) ||
        url.startsWith(`${origin}/src/uploads/`),
    );
    // Bucket URLs fall through untouched (or onto the CDN when configured).
    if (legacy) url = API_ORIGIN + url.slice(legacy.length);
    return toCdnUrl(encodeOnce(url));
  }

  // A bare filename means a disk upload, which the API serves under /uploads
  // — matching toPublicUrl() in the backend's src/utils/s3Media.js.
  const path = url.startsWith("/") ? url : `/uploads/${url}`;
  return encodeOnce(API_ORIGIN + path);
};
