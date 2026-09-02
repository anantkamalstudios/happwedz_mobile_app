/**
 * Helper to detect whether a vendor has actually uploaded 360° content.
 *
 * Vendors add 360° assets from their storefront login (Storefront → View360 tab).
 * Depending on how/when it was saved, the assets can land in a few shapes:
 *   - top level string columns  : view360_image / view360_video
 *   - top level arrays          : view360_images / view360_video
 *   - inside attributes         : attributes.view360_images / attributes.view360_video
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
 * @returns {{ images: string[], videos: string[] }}
 */
export const get360Assets = (item) => {
  if (!item || typeof item !== "object") return { images: [], videos: [] };

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

  const { images, videos } = get360Assets(item);
  return images.length > 0 || videos.length > 0;
};

export default hasView360;
