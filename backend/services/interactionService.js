import axios from 'axios';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://happywedz.com/api';

/**
 * Track user interaction with vendors/venues
 */
export const trackInteraction = async (interactionData) => {
  try {
    const response = await axios.post(`${API_BASE_URL}/interactions/track`, interactionData);
    return response.data;
  } catch (error) {
    console.error('Error tracking interaction:', error);
    throw error;
  }
};

/**
 * Get recently viewed vendors/venues for a user
 */
export const getRecentlyViewed = async (userId, limit = 10) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/interactions/recently-viewed`, {
      params: { user_id: userId, limit }
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching recently viewed:', error);
    throw error;
  }
};

/**
 * Get user activity summary
 */
export const getUserActivitySummary = async (userId) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/interactions/summary`, {
      params: { user_id: userId }
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching activity summary:', error);
    throw error;
  }
};

/**
 * Get last search/filter preferences
 */
export const getLastPreferences = async (userId) => {
  try {
    const response = await axios.get(`${API_BASE_URL}/interactions/last-preferences`, {
      params: { user_id: userId }
    });
    return response.data;
  } catch (error) {
    console.error('Error fetching last preferences:', error);
    throw error;
  }
};

/**
 * Clear user interaction history
 */
export const clearUserHistory = async (userId) => {
  try {
    const response = await axios.delete(`${API_BASE_URL}/interactions/clear`, {
      params: { user_id: userId }
    });
    return response.data;
  } catch (error) {
    console.error('Error clearing user history:', error);
    throw error;
  }
};
