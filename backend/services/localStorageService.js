/**
 * LocalStorage Service for Recently Viewed & User Tracking
 * No authentication required - works for all users
 */

const STORAGE_KEYS = {
  RECENTLY_VIEWED: 'happywedz_recently_viewed',
  USER_ACTIVITY: 'happywedz_user_activity',
  LAST_SEARCH: 'happywedz_last_search'
};

const MAX_RECENTLY_VIEWED = 20; // Keep last 20 items

/**
 * Track vendor/venue view
 */
export const trackView = (vendorData) => {
  try {
    const recentlyViewed = getRecentlyViewed();
    
    // Create view entry
    const viewEntry = {
      id: vendorData.id,
      name: vendorData.name,
      category: vendorData.category,
      type: vendorData.type || 'vendor',
      location: vendorData.location,
      image: vendorData.image,
      price_range: vendorData.price_range,
      slug: vendorData.slug,
      viewed_at: new Date().toISOString()
    };

    // Remove if already exists (to update timestamp)
    const filtered = recentlyViewed.filter(item => item.id !== vendorData.id);
    
    // Add to beginning
    filtered.unshift(viewEntry);
    
    // Keep only last MAX_RECENTLY_VIEWED items
    const limited = filtered.slice(0, MAX_RECENTLY_VIEWED);
    
    // Save to localStorage
    localStorage.setItem(STORAGE_KEYS.RECENTLY_VIEWED, JSON.stringify(limited));
    
    // Update activity stats
    updateActivityStats('view');
    
    return true;
  } catch (error) {
    console.error('Error tracking view:', error);
    return false;
  }
};

/**
 * Get recently viewed items
 */
export const getRecentlyViewed = (limit = 10) => {
  try {
    const data = localStorage.getItem(STORAGE_KEYS.RECENTLY_VIEWED);
    const items = data ? JSON.parse(data) : [];
    return limit ? items.slice(0, limit) : items;
  } catch (error) {
    console.error('Error getting recently viewed:', error);
    return [];
  }
};

/**
 * Track wishlist action
 */
export const trackWishlist = (vendorId) => {
  try {
    updateActivityStats('wishlist');
    return true;
  } catch (error) {
    console.error('Error tracking wishlist:', error);
    return false;
  }
};

/**
 * Track inquiry action
 */
export const trackInquiry = (vendorId) => {
  try {
    updateActivityStats('inquiry');
    return true;
  } catch (error) {
    console.error('Error tracking inquiry:', error);
    return false;
  }
};

/**
 * Save search preferences
 */
export const saveSearchPreferences = (searchData) => {
  try {
    const searchEntry = {
      ...searchData,
      searched_at: new Date().toISOString()
    };
    localStorage.setItem(STORAGE_KEYS.LAST_SEARCH, JSON.stringify(searchEntry));
    updateActivityStats('search');
    return true;
  } catch (error) {
    console.error('Error saving search preferences:', error);
    return false;
  }
};

/**
 * Get last search preferences
 */
export const getLastSearch = () => {
  try {
    const data = localStorage.getItem(STORAGE_KEYS.LAST_SEARCH);
    return data ? JSON.parse(data) : null;
  } catch (error) {
    console.error('Error getting last search:', error);
    return null;
  }
};

/**
 * Get activity stats
 */
export const getActivityStats = () => {
  try {
    const data = localStorage.getItem(STORAGE_KEYS.USER_ACTIVITY);
    const stats = data ? JSON.parse(data) : {
      total_views: 0,
      total_wishlists: 0,
      total_inquiries: 0,
      total_searches: 0,
      favorite_categories: {}
    };
    return stats;
  } catch (error) {
    console.error('Error getting activity stats:', error);
    return {
      total_views: 0,
      total_wishlists: 0,
      total_inquiries: 0,
      total_searches: 0,
      favorite_categories: {}
    };
  }
};

/**
 * Update activity stats
 */
const updateActivityStats = (action) => {
  try {
    const stats = getActivityStats();
    
    switch (action) {
      case 'view':
        stats.total_views = (stats.total_views || 0) + 1;
        break;
      case 'wishlist':
        stats.total_wishlists = (stats.total_wishlists || 0) + 1;
        break;
      case 'inquiry':
        stats.total_inquiries = (stats.total_inquiries || 0) + 1;
        break;
      case 'search':
        stats.total_searches = (stats.total_searches || 0) + 1;
        break;
    }
    
    localStorage.setItem(STORAGE_KEYS.USER_ACTIVITY, JSON.stringify(stats));
  } catch (error) {
    console.error('Error updating activity stats:', error);
  }
};

/**
 * Update favorite categories
 */
export const updateFavoriteCategory = (category) => {
  try {
    const stats = getActivityStats();
    if (!stats.favorite_categories) {
      stats.favorite_categories = {};
    }
    stats.favorite_categories[category] = (stats.favorite_categories[category] || 0) + 1;
    localStorage.setItem(STORAGE_KEYS.USER_ACTIVITY, JSON.stringify(stats));
  } catch (error) {
    console.error('Error updating favorite category:', error);
  }
};

/**
 * Get favorite categories sorted by count
 */
export const getFavoriteCategories = (limit = 5) => {
  try {
    const stats = getActivityStats();
    const categories = stats.favorite_categories || {};
    
    // Convert to array and sort
    const sorted = Object.entries(categories)
      .map(([category, count]) => ({ category, count }))
      .sort((a, b) => b.count - a.count);
    
    return limit ? sorted.slice(0, limit) : sorted;
  } catch (error) {
    console.error('Error getting favorite categories:', error);
    return [];
  }
};

/**
 * Clear all data (for privacy)
 */
export const clearAllData = () => {
  try {
    localStorage.removeItem(STORAGE_KEYS.RECENTLY_VIEWED);
    localStorage.removeItem(STORAGE_KEYS.USER_ACTIVITY);
    localStorage.removeItem(STORAGE_KEYS.LAST_SEARCH);
    return true;
  } catch (error) {
    console.error('Error clearing data:', error);
    return false;
  }
};

/**
 * Get unique vendors viewed count
 */
export const getUniqueVendorsCount = () => {
  try {
    const recentlyViewed = getRecentlyViewed(999);
    return recentlyViewed.length;
  } catch (error) {
    return 0;
  }
};
