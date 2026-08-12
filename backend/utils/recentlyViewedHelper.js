/**
 * Helper to prioritize recently viewed vendors in listing pages
 */

import { getRecentlyViewed } from '../services/localStorageService';

/**
 * Reorder vendors array to show recently viewed first
 * @param {Array} vendors - Array of all vendors
 * @returns {Array} - Reordered array with recently viewed first
 */
export const prioritizeRecentlyViewed = (vendors) => {
  if (!vendors || vendors.length === 0) {
    return vendors;
  }

  try {
    // Get recently viewed IDs
    const recentlyViewed = getRecentlyViewed(999); // Get all
    const recentlyViewedIds = recentlyViewed.map(item => item.id);

    if (recentlyViewedIds.length === 0) {
      return vendors;
    }

    // Separate vendors into two groups
    const recentlyViewedVendors = [];
    const otherVendors = [];

    vendors.forEach(vendor => {
      if (recentlyViewedIds.includes(vendor.id)) {
        recentlyViewedVendors.push(vendor);
      } else {
        otherVendors.push(vendor);
      }
    });

    // Sort recently viewed by the order they were viewed (most recent first)
    recentlyViewedVendors.sort((a, b) => {
      const indexA = recentlyViewedIds.indexOf(a.id);
      const indexB = recentlyViewedIds.indexOf(b.id);
      return indexA - indexB;
    });

    // Return recently viewed first, then others
    return [...recentlyViewedVendors, ...otherVendors];
  } catch (error) {
    console.error('Error prioritizing recently viewed:', error);
    return vendors;
  }
};

/**
 * Check if a vendor was recently viewed
 * @param {number} vendorId - Vendor ID to check
 * @returns {boolean} - True if recently viewed
 */
export const isRecentlyViewed = (vendorId) => {
  try {
    const recentlyViewed = getRecentlyViewed(999);
    return recentlyViewed.some(item => item.id === vendorId);
  } catch (error) {
    return false;
  }
};

/**
 * Add a badge/indicator to recently viewed vendors
 * @param {number} vendorId - Vendor ID to check
 * @returns {object|null} - Badge data or null
 */
export const getRecentlyViewedBadge = (vendorId) => {
  try {
    const recentlyViewed = getRecentlyViewed(999);
    const item = recentlyViewed.find(v => v.id === vendorId);
    
    if (item) {
      return {
        isRecentlyViewed: true,
        viewedAt: item.viewed_at,
        badge: '👁️ Recently Viewed'
      };
    }
    
    return null;
  } catch (error) {
    return null;
  }
};
