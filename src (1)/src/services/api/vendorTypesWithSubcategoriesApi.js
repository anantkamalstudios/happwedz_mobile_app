const API_BASE = import.meta.env.VITE_API_URL || "https://happywedz.com/api";
const ENDPOINT = `${API_BASE}/vendor-types/with-subcategories/all`;

// The vendor-type tree is static for the life of a page view but was being fetched
// independently by Herosection, WeddingCategories, Header (twice) and useHome —
// 5+ identical round trips before anything could render. Cache the resolved value
// and share the in-flight promise so concurrent callers coalesce into one request.
let cache = null;
let inFlight = null;

export const fetchVendorTypesWithSubcategoriesApi = async () => {
  if (cache) return cache;
  if (inFlight) return inFlight;

  inFlight = (async () => {
    try {
      const response = await fetch(ENDPOINT);
      const data = await response.json();
      cache = Array.isArray(data) ? data : [];
      return cache;
    } catch {
      return [];
    } finally {
      inFlight = null;
    }
  })();

  return inFlight;
};

// Escape hatch for anywhere that genuinely needs to re-read the list.
export const invalidateVendorTypesCache = () => {
  cache = null;
};
