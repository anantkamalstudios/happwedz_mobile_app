/**
 * Transform API vendor data to match the expected component format
 * This ensures compatibility with existing components while using dynamic data
 */

export const transformVendorData = (apiVendor) => {
  if (!apiVendor) return null;

  const attrs = apiVendor.attributes || {};
  const baseCurrency = attrs.currency || apiVendor.currency || "INR";
  const ratingValue = parseFloat(attrs.rating || apiVendor.rating);
  const reviewsCount =
    safeNumber(attrs.reviews_count) ?? safeNumber(apiVendor.reviews_count) ?? 0;
  const capacityMin = safeNumber(attrs.capacity_min) ?? safeNumber(apiVendor.capacity_min) ?? 0;
  const capacityMax = safeNumber(attrs.capacity_max) ?? safeNumber(apiVendor.capacity_max) ?? 0;
  const startingPrice = safeNumber(attrs.starting_price) ?? safeNumber(apiVendor.starting_price) ?? 0;

  return {
    id: apiVendor.id,
    name: attrs.name || apiVendor.name || "",
    description: attrs.description || apiVendor.description || attrs.tagline || apiVendor.tagline || "",
    location: formatLocation(attrs.location || apiVendor.location),
    rating: isNaN(ratingValue) ? 0 : ratingValue,
    reviews: reviewsCount,
    capacity: capacityMax || capacityMin || 0,
    call: truthy(attrs.within_24hr_available ?? apiVendor.within_24hr_available)
      ? "Responds within 24 hours"
      : null,
    price: formatPrice(startingPrice, baseCurrency),
    image: getPrimaryImage(apiVendor.media),
    slug: attrs.slug || apiVendor.slug || "",
    tagline: attrs.tagline || apiVendor.tagline || "",
    subtitle: attrs.subtitle || apiVendor.subtitle || "",
    badges: attrs.badges || apiVendor.badges || {},
    contact: attrs.contact || apiVendor.contact || {},
    price_range: attrs.price_range || apiVendor.price_range || { min: 0, max: 0 },
    currency: baseCurrency,
    deals: attrs.deals || apiVendor.deals || [],
    packages: attrs.packages || apiVendor.packages || [],
    capacity_min: capacityMin,
    capacity_max: capacityMax,
    rooms: safeNumber(attrs.rooms) ?? safeNumber(apiVendor.rooms) ?? 0,
    car_parking: safeNumber(attrs.car_parking) ?? safeNumber(apiVendor.car_parking) ?? 0,
    hall_types_note: attrs.hall_types_note || apiVendor.hall_types_note || "",
    indoor_outdoor: attrs.indoor_outdoor || apiVendor.indoor_outdoor || "",
    alcohol_policy: attrs.alcohol_policy || apiVendor.alcohol_policy || "",
    dj_policy: attrs.dj_policy || apiVendor.dj_policy || "",
    catering_policy: attrs.catering_policy || apiVendor.catering_policy || "",
    deco_policy: attrs.deco_policy || apiVendor.deco_policy || "",
    timing_open: attrs.timing_open || apiVendor.timing_open || "",
    timing_close: attrs.timing_close || apiVendor.timing_close || "",
    timing_last_entry: attrs.timing_last_entry || apiVendor.timing_last_entry || "",
    cancellation_policy: attrs.cancellation_policy || apiVendor.cancellation_policy || "",
    refund_policy: attrs.refund_policy || apiVendor.refund_policy || "",
    payment_terms: attrs.payment_terms || apiVendor.payment_terms || "",
    tnc: attrs.tnc || apiVendor.tnc || "",
    blackout_dates: attrs.blackout_dates || apiVendor.blackout_dates || [],
    available_slots: attrs.available_slots || apiVendor.available_slots || [],
    primary_cta: attrs.primary_cta || apiVendor.primary_cta || "",
    cta_phone: attrs.cta_phone || apiVendor.cta_phone || "",
    cta_url: normalizeUrl(attrs.cta_url || apiVendor.cta_url || ""),
    auto_reply: attrs.auto_reply || apiVendor.auto_reply || "",
    is_featured: truthy(attrs.is_featured ?? apiVendor.is_featured),
    within_24hr_available: truthy(attrs.within_24hr_available ?? apiVendor.within_24hr_available),
    is_feature_available: truthy(attrs.is_feature_available ?? apiVendor.is_feature_available),
    sort_weight: safeNumber(attrs.sort_weight) ?? safeNumber(apiVendor.sort_weight) ?? 0,
    tags: attrs.tags || apiVendor.tags || [],
    createdAt: apiVendor.createdAt,
    updatedAt: apiVendor.updatedAt,
    deletedAt: apiVendor.deletedAt,
  };
};

export const transformVendorsData = (apiVendors) => {
  if (!Array.isArray(apiVendors)) return [];
  
  const transformed = apiVendors.map(transformVendorData).filter(Boolean);
  
  // Deduplicate by ID and Name + Location to prevent duplicate vendor cards in UI lists
  const uniqueTransformed = [];
  const seenIds = new Set();
  const seenNames = new Set();

  transformed.forEach((vendor) => {
    if (!vendor || !vendor.image || String(vendor.image).trim() === "") return;
    const id = vendor.id;
    const name = (vendor.name || "").trim().toLowerCase();
    const location = (vendor.location || "").trim().toLowerCase();
    const key = `${name}|${location}`;

    if (id && !seenIds.has(id)) {
      if (!name || !seenNames.has(key)) {
        seenIds.add(id);
        if (name) seenNames.add(key);
        uniqueTransformed.push(vendor);
      }
    }
  });

  return uniqueTransformed;
};

// Helper functions
const formatLocation = (location) => {
  if (!location) return "";

  if (typeof location === "string") {
    return location;
  }

  if (typeof location === "object") {
    const parts = [];
    if (location.address) parts.push(location.address);
    if (location.city) parts.push(location.city);
    if (location.state) parts.push(location.state);
    return parts.join(", ");
  }

  return "";
};

const formatPrice = (price, currency = "INR") => {
  if (!price) return "0";

  const numPrice = parseFloat(price);
  if (isNaN(numPrice)) return "0";

  // Convert to lakhs if price is in lakhs range
  if (numPrice >= 100000) {
    const lakhs = (numPrice / 100000).toFixed(1);
    return `${lakhs} Lakh`;
  }

  // Convert to thousands if price is in thousands range
  if (numPrice >= 1000) {
    const thousands = (numPrice / 1000).toFixed(0);
    return `${thousands}K`;
  }

  return `${numPrice}`;
};

const getPrimaryImage = (media) => {
  if (!media || typeof media !== "object") return null;

  // Prefer explicit cover image
  if (media.coverImage && typeof media.coverImage === "string") {
    return normalizeMediaUrl(media.coverImage) || null;
  }

  // Support gallery array (strings or objects)
  if (Array.isArray(media.gallery) && media.gallery.length > 0) {
    const first = media.gallery[0];
    if (typeof first === "string") return normalizeMediaUrl(first) || null;
    if (typeof first === "object") {
      const url = first.url || first.src || first.path || first.image || "";
      return normalizeMediaUrl(url) || null;
    }
  }

  // Backward compatibility: media.images
  if (Array.isArray(media.images) && media.images.length > 0) {
    const first = media.images[0];
    if (typeof first === "string") return normalizeMediaUrl(first) || null;
    if (typeof first === "object") {
      const url = first.url || first.src || first.path || first.image || "";
      return normalizeMediaUrl(url) || null;
    }
  }

  return null;
};

// Utilities
const API_BASE_URL = "https://happywedz.com";

const normalizeMediaUrl = (url) => {
  if (!url) return "";
  // Already absolute
  if (/^https?:\/\//i.test(url)) return url;
  // Prefix site base for paths starting with '/'
  if (url.startsWith("/")) return `${API_BASE_URL}${url}`;
  // Otherwise, treat as uploads relative
  return `${API_BASE_URL}/${url}`;
};

const normalizeUrl = (url) => {
  if (!url) return "";
  if (/^https?:\/\//i.test(url)) return url;
  // If only domain provided, add protocol
  return `https://${url}`;
};

const safeNumber = (value) => {
  if (value === null || value === undefined || value === "") return 0;
  const n = Number(value);
  return isNaN(n) ? 0 : n;
};

const truthy = (value) => {
  if (typeof value === "string") {
    const v = value.toLowerCase();
    return v === "true" || v === "1" || v === "yes";
  }
  return Boolean(value);
};

// Filter functions for different vendor types
export const filterVendorsByType = (vendors, vendorType) => {
  if (!vendorType) return vendors;
  return vendors.filter((vendor) => vendor.vendor_type === vendorType);
};

export const filterVendorsByCategory = (vendors, categoryId) => {
  if (!categoryId) return vendors;
  return vendors.filter((vendor) => vendor.category_id === categoryId);
};

export const filterVendorsByLocation = (vendors, location) => {
  if (!location) return vendors;
  return vendors.filter((vendor) =>
    vendor.location.toLowerCase().includes(location.toLowerCase())
  );
};

export const searchVendors = (vendors, searchTerm) => {
  if (!searchTerm) return vendors;

  const term = searchTerm.toLowerCase();
  return vendors.filter(
    (vendor) =>
      vendor.name.toLowerCase().includes(term) ||
      vendor.description.toLowerCase().includes(term) ||
      vendor.location.toLowerCase().includes(term) ||
      vendor.tagline?.toLowerCase().includes(term) ||
      vendor.tags?.some((tag) => tag.toLowerCase().includes(term))
  );
};

// Sort functions
export const sortVendors = (vendors, sortBy = "name", sortOrder = "asc") => {
  const sorted = [...vendors].sort((a, b) => {
    let aValue = a[sortBy];
    let bValue = b[sortBy];

    if (typeof aValue === "string") {
      aValue = aValue.toLowerCase();
      bValue = bValue.toLowerCase();
    }

    if (sortOrder === "desc") {
      return bValue > aValue ? 1 : -1;
    }

    return aValue > bValue ? 1 : -1;
  });

  return sorted;
};
