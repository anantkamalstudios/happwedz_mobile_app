import { useEffect, useRef } from 'react';
import { useSelector } from 'react-redux';
import { trackInteraction } from '../services/interactionService';

/**
 * Custom hook to automatically track user interactions
 * Usage: useTrackInteraction(vendorId, action, metadata)
 */
export const useTrackInteraction = (vendorSubcategoryDataId, action = 'view', metadata = {}) => {
  const { user } = useSelector((state) => state.auth);
  const hasTracked = useRef(false);

  useEffect(() => {
    // Only track if user is logged in and we have a vendor ID
    if (!user?.id || !vendorSubcategoryDataId || hasTracked.current) {
      return;
    }

    const track = async () => {
      try {
        await trackInteraction({
          user_id: user.id,
          vendor_subcategory_data_id: vendorSubcategoryDataId,
          action,
          value: {
            ...metadata,
            timestamp: new Date().toISOString(),
            page_url: window.location.pathname
          }
        });
        hasTracked.current = true;
      } catch (error) {
        console.error('Failed to track interaction:', error);
      }
    };

    // Track after a small delay to avoid tracking accidental clicks
    const timer = setTimeout(track, 1000);

    return () => clearTimeout(timer);
  }, [user?.id, vendorSubcategoryDataId, action, metadata]);
};

/**
 * Manual tracking function for immediate tracking
 */
export const useManualTrack = () => {
  const { user } = useSelector((state) => state.auth);

  const track = async (vendorSubcategoryDataId, action, metadata = {}) => {
    if (!user?.id || !vendorSubcategoryDataId) {
      return;
    }

    try {
      await trackInteraction({
        user_id: user.id,
        vendor_subcategory_data_id: vendorSubcategoryDataId,
        action,
        value: {
          ...metadata,
          timestamp: new Date().toISOString(),
          page_url: window.location.pathname
        }
      });
    } catch (error) {
      console.error('Failed to track interaction:', error);
    }
  };

  return track;
};
