import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getRecentlyViewed } from '../../services/localStorageService';
import { FaEye, FaClock, FaMapMarkerAlt, FaRupeeSign } from 'react-icons/fa';
import './RecentlyViewed.css';
import { formatDate } from '../../utils/dateFormat';

const RecentlyViewedLocal = ({ limit = 6, showTitle = true }) => {
  const navigate = useNavigate();
  const [recentItems, setRecentItems] = useState([]);

  useEffect(() => {
    // Load from localStorage
    const items = getRecentlyViewed(limit);
    setRecentItems(items);
  }, [limit]);

  const handleCardClick = (item) => {
    // Navigate to vendor/venue detail page
    const slug = item.slug || item.id;
    const category = item.category || 'vendor';
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

  // Don't show if no items
  if (recentItems.length === 0) {
    return null;
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
          return (
            <div
              key={item.id}
              className="recently-viewed-card"
              onClick={() => handleCardClick(item)}
            >
              <div className="card-image-wrapper">
                <img
                  src={item.image || '/placeholder-vendor.jpg'}
                  alt={item.name || 'Vendor'}
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
                  {item.name || 'Vendor Name'}
                </h3>

                {item.category && (
                  <p className="card-category">
                    {item.category.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                  </p>
                )}

                {item.location && (
                  <p className="card-location">
                    <FaMapMarkerAlt className="icon" />
                    {item.location}
                  </p>
                )}

                {item.price_range && (
                  <p className="card-price">
                    <FaRupeeSign className="icon" />
                    {item.price_range}
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

export default RecentlyViewedLocal;
