import { getRecentlyViewed } from '../services/localStorageService';

/**
 * Personalize vendor/venue results by showing previously viewed items first
 * @param {Array} vendors - Array of vendors/venues to personalize
 * @returns {Array} - Reordered array with viewed items first
 */
export const personalizeResults = (vendors) => {
  if (!vendors || vendors.length === 0) return vendors;

  try {
    // Get recently viewed IDs
    const recentlyViewed = getRecentlyViewed(999); // Get all
    const viewedIds = new Set(recentlyViewed.map(item => item.id));

    // Split into viewed and not viewed
    const viewedVendors = [];
    const notViewedVendors = [];

    vendors.forEach(vendor => {
      if (viewedIds.has(vendor.id)) {
        viewedVendors.push(vendor);
      } else {
        notViewedVendors.push(vendor);
      }
    });

    // Return viewed first, then rest
    return [...viewedVendors, ...notViewedVendors];
  } catch (error) {
    console.error('Error personalizing results:', error);
    return vendors;
  }
};

/**
 * Check if a vendor was previously viewed
 * @param {number} vendorId - Vendor ID to check
 * @returns {boolean} - True if viewed before
 */
export const wasViewed = (vendorId) => {
  try {
    const recentlyViewed = getRecentlyViewed(999);
    return recentlyViewed.some(item => item.id === vendorId);
  } catch (error) {
    return false;
  }
};

/**
 * Add "Previously Viewed" badge data to vendors
 * @param {Array} vendors - Array of vendors
 * @returns {Array} - Vendors with isViewed flag
 */
export const addViewedFlags = (vendors) => {
  if (!vendors || vendors.length === 0) return vendors;

  try {
    const recentlyViewed = getRecentlyViewed(999);
    const viewedIds = new Set(recentlyViewed.map(item => item.id));

    return vendors.map(vendor => ({
      ...vendor,
      isViewed: viewedIds.has(vendor.id)
    }));
  } catch (error) {
    return vendors;
  }
};
