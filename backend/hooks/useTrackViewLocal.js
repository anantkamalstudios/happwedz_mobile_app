import { useEffect, useRef } from 'react';
import { trackView, updateFavoriteCategory } from '../services/localStorageService';

/**
 * Custom hook to automatically track vendor/venue views using localStorage
 * No authentication required
 * 
 * Usage: useTrackViewLocal(vendorData)
 */
export const useTrackViewLocal = (vendorData) => {
  const hasTracked = useRef(false);

  useEffect(() => {
    // Only track if we have vendor data and haven't tracked yet
    if (!vendorData || !vendorData.id || hasTracked.current) {
      return;
    }

    const track = () => {
      try {
        // Track the view
        trackView({
          id: vendorData.id,
          name: vendorData.name,
          category: vendorData.category,
          type: vendorData.type || 'vendor',
          location: vendorData.location,
          image: vendorData.image || vendorData.cover_image,
          price_range: vendorData.price_range,
          slug: vendorData.slug
        });

        // Update favorite category
        if (vendorData.category) {
          updateFavoriteCategory(vendorData.category);
        }

        hasTracked.current = true;
      } catch (error) {
        console.error('Failed to track view:', error);
      }
    };

    // Track after a small delay to avoid tracking accidental clicks
    const timer = setTimeout(track, 1000);

    return () => clearTimeout(timer);
  }, [vendorData]);
};

export default useTrackViewLocal;
