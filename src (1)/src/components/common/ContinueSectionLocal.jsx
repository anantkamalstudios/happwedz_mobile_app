import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  getActivityStats, 
  getLastSearch, 
  getFavoriteCategories,
  getUniqueVendorsCount 
} from '../../services/localStorageService';
import { 
  FaPlay, 
  FaEye, 
  FaHeart, 
  FaEnvelope, 
  FaSearch, 
  FaMapMarkerAlt, 
  FaRupeeSign,
  FaUsers,
  FaArrowRight,
  FaInfoCircle
} from 'react-icons/fa';
import './ContinueSection.css';

const ContinueSectionLocal = () => {
  const navigate = useNavigate();
  const [activityData, setActivityData] = useState(null);
  const [lastSearch, setLastSearch] = useState(null);
  const [favoriteCategories, setFavoriteCategories] = useState([]);

  useEffect(() => {
    // Load from localStorage
    const stats = getActivityStats();
    const search = getLastSearch();
    const categories = getFavoriteCategories(5);
    const uniqueCount = getUniqueVendorsCount();

    setActivityData({
      ...stats,
      unique_vendors_viewed: uniqueCount
    });
    setLastSearch(search);
    setFavoriteCategories(categories);
  }, []);

  const handleContinueSearch = () => {
    if (lastSearch) {
      const params = new URLSearchParams();
      if (lastSearch.location) params.append('location', lastSearch.location);
      if (lastSearch.category) params.append('category', lastSearch.category);
      if (lastSearch.budget) params.append('budget', lastSearch.budget);
      navigate(`/search?${params.toString()}`);
    }
  };

  // Don't show if no activity yet
  if (!activityData || activityData.total_views === 0) {
    return null;
  }

  return (
    <div className="continue-section">
      <div className="continue-container">
        <div className="continue-header">
          <h2 className="continue-title">
            <FaPlay className="continue-icon" />
            Continue Where You Left Off
          </h2>
          <p className="continue-subtitle">
            Welcome back! Here's your wedding planning progress
          </p>
        </div>

        <div className="continue-content">
          {/* Activity Summary Card */}
          <div className="continue-card">
            <div className="card-header">
              <FaInfoCircle className="card-icon" />
              <h3 className="card-title">Your Activity</h3>
            </div>
            <div className="card-body">
              <div className="stat-item">
                <span className="stat-label">
                  <FaEye style={{ marginRight: '8px' }} />
                  Vendors Viewed
                </span>
                <span className="stat-value">{activityData.unique_vendors_viewed || 0}</span>
              </div>
              <div className="stat-item">
                <span className="stat-label">
                  <FaHeart style={{ marginRight: '8px' }} />
                  Wishlisted
                </span>
                <span className="stat-value">{activityData.total_wishlists || 0}</span>
              </div>
              <div className="stat-item">
                <span className="stat-label">
                  <FaEnvelope style={{ marginRight: '8px' }} />
                  Inquiries Sent
                </span>
                <span className="stat-value">{activityData.total_inquiries || 0}</span>
              </div>
            </div>
          </div>

          {/* Last Search Preferences Card */}
          {lastSearch && (
            <div className="continue-card">
              <div className="card-header">
                <FaSearch className="card-icon" />
                <h3 className="card-title">Last Search</h3>
              </div>
              <div className="card-body">
                {lastSearch.location && (
                  <div className="preference-item">
                    <FaMapMarkerAlt className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Location:</span>
                      {lastSearch.location}
                    </p>
                  </div>
                )}
                {lastSearch.category && (
                  <div className="preference-item">
                    <FaSearch className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Category:</span>
                      {lastSearch.category}
                    </p>
                  </div>
                )}
                {lastSearch.budget && (
                  <div className="preference-item">
                    <FaRupeeSign className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Budget:</span>
                      ₹{lastSearch.budget}
                    </p>
                  </div>
                )}
                {lastSearch.guest_count && (
                  <div className="preference-item">
                    <FaUsers className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Guests:</span>
                      {lastSearch.guest_count}
                    </p>
                  </div>
                )}
              </div>
              <div className="card-footer">
                <button className="action-btn" onClick={handleContinueSearch}>
                  Continue Search
                  <FaArrowRight className="btn-icon" />
                </button>
              </div>
            </div>
          )}

          {/* Favorite Categories Card */}
          {favoriteCategories.length > 0 && (
            <div className="continue-card">
              <div className="card-header">
                <FaHeart className="card-icon" />
                <h3 className="card-title">You're Interested In</h3>
              </div>
              <div className="card-body">
                {favoriteCategories.map((cat, index) => (
                  <div key={index} className="stat-item">
                    <span className="stat-label">
                      {cat.category?.replace(/-/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                    </span>
                    <span className="stat-value">{cat.count} views</span>
                  </div>
                ))}
              </div>
              <div className="card-footer">
                <button 
                  className="action-btn"
                  onClick={() => navigate(`/vendors/${favoriteCategories[0].category}`)}
                >
                  Explore More
                  <FaArrowRight className="btn-icon" />
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ContinueSectionLocal;
