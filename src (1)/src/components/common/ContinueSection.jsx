import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import { useNavigate } from 'react-router-dom';
import { getUserActivitySummary, getLastPreferences } from '../../services/interactionService';
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

const ContinueSection = () => {
  const { user } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [activityData, setActivityData] = useState(null);
  const [lastPreferences, setLastPreferences] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user?.id) {
      setLoading(false);
      return;
    }

    const fetchData = async () => {
      try {
        setLoading(true);
        const [summaryResponse, preferencesResponse] = await Promise.all([
          getUserActivitySummary(user.id),
          getLastPreferences(user.id)
        ]);

        setActivityData(summaryResponse.data);
        setLastPreferences(preferencesResponse.data);
      } catch (error) {
        console.error('Error fetching continue section data:', error);
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, [user?.id]);

  const handleContinueSearch = () => {
    if (lastPreferences?.preferences) {
      const prefs = lastPreferences.preferences;
      // Navigate to search with last preferences
      const params = new URLSearchParams();
      if (prefs.location) params.append('location', prefs.location);
      if (prefs.category) params.append('category', prefs.category);
      if (prefs.budget) params.append('budget', prefs.budget);
      navigate(`/search?${params.toString()}`);
    }
  };

  const handleViewWishlist = () => {
    navigate('/wishlist');
  };

  // Don't show if user is not logged in
  if (!user?.id) {
    return null;
  }

  // Don't show if no activity yet
  if (!loading && (!activityData || activityData.total_interactions === 0)) {
    return null;
  }

  if (loading) {
    return (
      <div className="continue-section">
        <div className="continue-container">
          <div className="continue-loading">
            <div className="loading-spinner"></div>
            <p>Loading your activity...</p>
          </div>
        </div>
      </div>
    );
  }

  const viewCount = activityData?.activity_counts?.find(a => a.action === 'view')?.count || 0;
  const wishlistCount = activityData?.activity_counts?.find(a => a.action === 'wishlist')?.count || 0;
  const inquiryCount = activityData?.activity_counts?.find(a => a.action === 'inquiry')?.count || 0;

  return (
    <div className="continue-section">
      <div className="continue-container">
        <div className="continue-header">
          <h2 className="continue-title">
            <FaPlay className="continue-icon" />
            Continue Where You Left Off
          </h2>
          <p className="continue-subtitle">
            Welcome back, {user.name || 'there'}! Here's your wedding planning progress
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
                <span className="stat-value">{activityData?.unique_vendors_viewed || 0}</span>
              </div>
              <div className="stat-item">
                <span className="stat-label">
                  <FaHeart style={{ marginRight: '8px' }} />
                  Wishlisted
                </span>
                <span className="stat-value">{wishlistCount}</span>
              </div>
              <div className="stat-item">
                <span className="stat-label">
                  <FaEnvelope style={{ marginRight: '8px' }} />
                  Inquiries Sent
                </span>
                <span className="stat-value">{inquiryCount}</span>
              </div>
            </div>
            {wishlistCount > 0 && (
              <div className="card-footer">
                <button className="action-btn" onClick={handleViewWishlist}>
                  View Wishlist
                  <FaArrowRight className="btn-icon" />
                </button>
              </div>
            )}
          </div>

          {/* Last Search Preferences Card */}
          {lastPreferences && (
            <div className="continue-card">
              <div className="card-header">
                <FaSearch className="card-icon" />
                <h3 className="card-title">Last Search</h3>
              </div>
              <div className="card-body">
                {lastPreferences.preferences?.location && (
                  <div className="preference-item">
                    <FaMapMarkerAlt className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Location:</span>
                      {lastPreferences.preferences.location}
                    </p>
                  </div>
                )}
                {lastPreferences.preferences?.category && (
                  <div className="preference-item">
                    <FaSearch className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Category:</span>
                      {lastPreferences.preferences.category}
                    </p>
                  </div>
                )}
                {lastPreferences.preferences?.budget && (
                  <div className="preference-item">
                    <FaRupeeSign className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Budget:</span>
                      ₹{lastPreferences.preferences.budget}
                    </p>
                  </div>
                )}
                {lastPreferences.preferences?.guest_count && (
                  <div className="preference-item">
                    <FaUsers className="preference-icon" />
                    <p className="preference-text">
                      <span className="preference-label">Guests:</span>
                      {lastPreferences.preferences.guest_count}
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
          {activityData?.favorite_categories && activityData.favorite_categories.length > 0 && (
            <div className="continue-card">
              <div className="card-header">
                <FaHeart className="card-icon" />
                <h3 className="card-title">You're Interested In</h3>
              </div>
              <div className="card-body">
                {activityData.favorite_categories.slice(0, 5).map((cat, index) => (
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
                  onClick={() => navigate(`/vendors/${activityData.favorite_categories[0].category}`)}
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

export default ContinueSection;
