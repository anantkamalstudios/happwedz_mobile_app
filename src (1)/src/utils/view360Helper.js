/**
 * Helper to detect whether a vendor has actually uploaded 360° content.
 *
 * Vendors add 360° assets from their storefront login (Storefront → View360 tab).
 * Depending on how/when it was saved, the assets can land in a few shapes:
 *   - top level string columns  : view360_image / view360_video
 *   - top level arrays          : view360_images / view360_video
 *   - inside attributes         : attributes.view360_images / attributes.view360_video
 *   - a pasted link             : attributes.view360_url
 *   - sub-vendor media object   : media.view360 { embedCode, panoImage, modelUrl }
 * The listing card / detail page must only show the 360° button when at least
 * one of these holds a real asset.
 */

const isUsableUrl = (value) => {
  if (!value) return false;
  if (typeof value !== "string") return false;
  const cleaned = value.replace(/^\s*`|`\s*$/g, "").trim();
  if (!cleaned || cleaned.toLowerCase() === "null" || cleaned.toLowerCase() === "undefined") {
    return false;
  }
  return true;
};

/**
 * The vendor's pasted 360° link, but only when it is a plain http(s) URL.
 * Vendors can enter any text, so anything else (javascript:, data:, junk) must
 * never reach an href or iframe src.
 * @param {string} value
 * @returns {string|null}
 */
export const getSafe360Url = (value) => {
  if (!isUsableUrl(value)) return null;
  try {
    const parsed = new URL(value.replace(/^\s*`|`\s*$/g, "").trim());
    return parsed.protocol === "http:" || parsed.protocol === "https:"
      ? parsed.href
      : null;
  } catch {
    return null;
  }
};

const normalizeEntry = (entry) => {
  if (!entry) return null;
  const raw = typeof entry === "string" ? entry : entry.url || entry.path || entry.location;
  if (!isUsableUrl(raw)) return null;
  return raw.replace(/^\s*`|`\s*$/g, "").trim();
};

const toList = (value) => {
  if (!value) return [];
  const items = Array.isArray(value) ? value : [value];
  return items.map(normalizeEntry).filter(Boolean);
};

/**
 * Collect every 360° asset a vendor service carries.
 * @param {Object} item - raw vendor-service record or a transformed card object
 * @returns {{ images: string[], videos: string[], url: string|null }}
 */
export const get360Assets = (item) => {
  if (!item || typeof item !== "object") return { images: [], videos: [], url: null };

  const attributes = item.attributes || {};
  const media = item.media && !Array.isArray(item.media) ? item.media : {};
  const view360 = media.view360 || {};

  const images = [
    ...toList(item.view360_image),
    ...toList(item.view360_images),
    ...toList(item.view360Images),
    ...toList(attributes.view360_image),
    ...toList(attributes.view360_images),
    ...toList(view360.panoImage),
    ...toList(view360.modelUrl),
  ];

  const videos = [
    ...toList(item.view360_video),
    ...toList(item.view360_videos),
    ...toList(item.view360Videos),
    ...toList(attributes.view360_video),
    ...toList(attributes.view360_videos),
  ];

  return {
    images: [...new Set(images)],
    videos: [...new Set(videos)],
    url: getSafe360Url(attributes.view360_url ?? item.view360_url),
  };
};

/**
 * True only when the vendor has added 360° content from their login.
 * @param {Object} item - raw vendor-service record or a transformed card object
 * @returns {boolean}
 */
export const hasView360 = (item) => {
  if (!item || typeof item !== "object") return false;

  // Already computed upstream by a data transform (useInfiniteScroll, etc.)
  if (typeof item.has360 === "boolean") return item.has360;

  const media = item.media && !Array.isArray(item.media) ? item.media : {};
  if (isUsableUrl(media.view360?.embedCode)) return true;

  const { images, videos, url } = get360Assets(item);
  return images.length > 0 || videos.length > 0 || Boolean(url);
};

export default hasView360;
