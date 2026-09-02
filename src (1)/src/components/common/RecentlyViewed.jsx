import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { getRecentlyViewed } from '../../services/interactionService';
import { FaEye, FaClock, FaMapMarkerAlt, FaRupeeSign } from 'react-icons/fa';
import './RecentlyViewed.css';
import { formatDate } from '../../utils/dateFormat';

const RecentlyViewed = ({ limit = 6, showTitle = true }) => {
  const { user } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [recentItems, setRecentItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    const fetchRecentlyViewed = async () => {
      try {
        setLoading(true);
        const response = await getRecentlyViewed(user.id, limit);
        setRecentItems(response.data || []);
        setError(null);
      } catch (err) {
        console.error('Error fetching recently viewed:', err);
        setError('Failed to load recently viewed items');
      } finally {
        setLoading(false);
      }
    };

    fetchRecentlyViewed();
  }, [user?.id, limit]);

  const handleCardClick = (item) => {
    // Navigate to vendor/venue detail page
    const slug = item.attributes?.slug || item.id;
    const category = item.metadata?.category || 'vendor';
    navigate(`/${category}/${slug}`);
  };

  const formatTimeAgo = (date) => {
    const now = new Date();
    const viewed = new Date(date);
    const diffInSeconds = Math.floor((now - viewed) / 1000);

    if (diffInSeconds < 60) return 'Just now';
    if (diffInSeconds < 3600) return `${Math.floor(diffInSeconds / 60)}m ago`;
    if (diffInSeconds < 86400) return `${Math.floor(diffInSeconds / 3600)}h ago`;
    if (diffInSeconds < 604800) return `${Math.floor(diffInSeconds / 86400)}d ago`;
    return formatDate(viewed);
  };

  // Don't show if user is not logged in or no items
  if (!user?.id || (!loading && recentItems.length === 0)) {
    return null;
  }

  if (loading) {
    return (
      <div className="recently-viewed-section">
        {showTitle && <h2 className="section-title">Recently Viewed</h2>}
        <div className="recently-viewed-loading">
          <div className="spinner"></div>
          <p>Loading your recently viewed items...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return null; // Silently fail - don't show error to user
  }

  return (
    <div className="recently-viewed-section">
      {showTitle && (
        <div className="section-header">
          <h2 className="section-title">
            <FaEye className="title-icon" />
            Recently Viewed
          </h2>
          <p className="section-subtitle">Pick up where you left off</p>
        </div>
      )}

      <div className="recently-viewed-grid">
        {recentItems.map((item) => {
          const attributes = item.attributes || {};
          const media = item.media || {};
          const metadata = item.metadata || {};
          
          // Get first image
          const firstImage = media.images?.[0] || media.cover_image || '/placeholder-vendor.jpg';
          
          return (
            <div
              key={item.id}
              className="recently-viewed-card"
              onClick={() => handleCardClick(item)}
            >
              <div className="card-image-wrapper">
                <img
                  src={firstImage}
                  alt={attributes.name || metadata.name || 'Vendor'}
                  className="card-image"
                  onError={(e) => {
                    e.target.src = '/placeholder-vendor.jpg';
                  }}
                />
                <div className="viewed-badge">
                  <FaClock className="badge-icon" />
                  {formatTimeAgo(item.viewed_at)}
                </div>
              </div>

              <div className="card-content">
                <h3 className="card-title">
                  {attributes.name || metadata.name || 'Vendor Name'}
                </h3>

                {metadata.category && (
                  <p className="card-category">
                    {metadata.category.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </p>
                )}

                {metadata.location && (
                  <p className="card-location">
                    <FaMapMarkerAlt className="icon" />
                    {metadata.location}
                  </p>
                )}

                {metadata.price_range && (
                  <p className="card-price">
                    <FaRupeeSign className="icon" />
                    {metadata.price_range}
                  </p>
                )}
              </div>

              <div className="card-overlay">
                <button className="view-again-btn">View Again</button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default RecentlyViewed;
