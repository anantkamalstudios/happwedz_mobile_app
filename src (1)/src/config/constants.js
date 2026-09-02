// API Configuration
export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || import.meta.env.VITE_API_URL || "http://localhost:4000/api";
// Host that serves relative upload paths (/uploads/...) written by the backend.
export const IMAGE_BASE_URL = "https://happywedzbackend.happywedz.com/";

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
