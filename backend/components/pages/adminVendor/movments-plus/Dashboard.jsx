import React, { useState, useEffect } from "react";
import { VscRefresh } from "react-icons/vsc";
import {
  FiUpload,
  FiImage,
  FiKey,
  FiEye,
  FiClock,
  FiPackage,
  FiAlertCircle,
  FiCheckCircle,
  FiFolder,
  FiPlus,
  FiSettings,
  FiTrendingUp,
  FiTrendingDown,
  FiBarChart2,
  FiUsers,
  FiActivity,
} from "react-icons/fi";
import axiosInstance from "../../../../services/api/axiosInstance";
import "./dashboard.css";
import Loader from "../../../ui/Loader";
import { useSelector } from "react-redux";
const VendorDashboard = ({ onNavigate }) => {
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentTime, setCurrentTime] = useState(new Date());
  const [isOnline, setIsOnline] = useState(navigator.onLine);
  const vendor = useSelector((state) => state.vendorAuth.vendor);
  console.log("vendor -> ", vendor);
  useEffect(() => {
    fetchDashboardAnalytics();

    const timeInterval = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);

    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener("online", handleOnline);
    window.addEventListener("offline", handleOffline);

    return () => {
      clearInterval(timeInterval);
      window.removeEventListener("online", handleOnline);
      window.removeEventListener("offline", handleOffline);
    };
  }, []);

  const fetchDashboardAnalytics = async () => {
    try {
      setLoading(true);
      const response = await axiosInstance.get("/vendor/dashboard/analytics");

      if (response.data.success) {
        setAnalytics(response.data);
      } else {
        setError("Failed to load dashboard data");
      }
    } catch (err) {
      setError(err.response?.data?.message || "Failed to fetch analytics");
      console.error("Dashboard error:", err);
    } finally {
      setLoading(false);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return "Never";
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now - date;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return `${diffMins}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  };

  const formatBytes = (mb) => {
    if (mb >= 1024) return `${(mb / 1024).toFixed(1)} GB`;
    return `${mb.toFixed(0)} MB`;
  };

  const formatTime = () => {
    return currentTime.toLocaleTimeString("en-US", {
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    });
  };

  const formatFullDate = () => {
    return currentTime.toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  if (loading) {
    return (
      <div className="movments-plus-dashboard-container w-100 justify-content-center">
        <div className="loading-state">
          <Loader />
        </div>
      </div>
    );
  }

  const { package: pkg, media, tokens, reach, activity, usage } = analytics;

  return (
    <>
      <div className="movements-plus-dashboard-container">
        {/* Header with Status */}
        <div className="dashboard-header px-0">
          <div className="header-left w-100 px-2">
            <h3 className="dashboard-title text-start text-black">
              Dashboard Overview
            </h3>
            <div className="status-bar w-100 d-flex justify-content-between flex-wrap gap-3">
              <div className="d-flex gap-3 flex-wrap align-items-center">
                <div
                  className={`status-indicator inter ${
                    isOnline ? "online" : "offline"
                  }`}
                >
                  <span className="status-dot inter"></span>
                  {isOnline ? "Online" : "Offline"}
                </div>
                <div className="time-display inter text-black fs-16">
                  <FiClock size={14} />
                  <span>{formatTime()}</span>
                </div>
                <div className="date-display inter text-black fs-16">
                  {formatFullDate()}
                </div>
              </div>

              <button
                className="btn-refresh inter"
                onClick={fetchDashboardAnalytics}
              >
                <VscRefresh size={18} />
                Refresh Data
              </button>
            </div>
          </div>
        </div>

        {/* Storage Warning */}
        {usage.storageWarning && (
          <div className="alert-warning">
            <FiAlertCircle size={20} />
            <span>
              Storage is running low! Consider upgrading your package.
            </span>
          </div>
        )}

        {/* Primary Stats - 4 Cards */}
        <div className="stats-grid">
          <div className="stat-card primary">
            <div className="stat-header">
              <div className="stat-icon-wrapper pink">
                <FiPackage size={24} />
              </div>
              <span className="stat-trend positive">
                <FiTrendingUp size={14} />
                {pkg.usagePercent}%
              </span>
            </div>
            <div className="stat-body">
              <h3 className="stat-value text-black">
                {formatBytes(pkg.usedMB)}
              </h3>
              <p className="stat-label">Storage Used</p>
              <div className="progress-bar">
                <div
                  className="progress-fill pink"
                  style={{ width: `${pkg.usagePercent}%` }}
                ></div>
              </div>
              <p className="stat-detail d-flex justify-content-center my-2 pt-2">
                {formatBytes(pkg.remainingMB)} of {formatBytes(pkg.limitMB)}{" "}
                remaining
              </p>
            </div>
          </div>

          <div className="stat-card primary">
            <div className="stat-header">
              <div className="stat-icon-wrapper pink">
                <FiImage size={24} />
              </div>
              <span className="stat-trend positive">
                <FiTrendingUp size={14} />
                12.5%
              </span>
            </div>
            <div className="stat-body">
              <h3 className="stat-value text-black">
                {media.total.toLocaleString()}
              </h3>
              <p className="stat-label">Total Media Files</p>
              <div className="stat-breakdown d-flex justify-content-center my-2 pt-2">
                <span>{media.byCollection.length} Collections</span>
                <span>•</span>
                <span className="d-flex justify-content-center">
                  {media.visibility.find((v) => v.type === "Public")?.count ||
                    0}{" "}
                  Public
                </span>
              </div>
            </div>
          </div>

          <div className="stat-card primary">
            <div className="stat-header">
              <div className="stat-icon-wrapper pink">
                <FiEye size={24} />
              </div>
              <span className="stat-trend positive">
                <FiTrendingUp size={14} />
                24.8%
              </span>
            </div>
            <div className="stat-body">
              <h3 className="stat-value text-black">
                {reach.totalViews.toLocaleString()}
              </h3>
              <p className="stat-label">Total Gallery Views</p>
              <div className="stat-breakdown d-flex justify-content-center my-2 pt-2">
                <span>
                  {reach.uniqueViews.toLocaleString()} Unique Visitors
                </span>
              </div>
            </div>
          </div>

          <div className="stat-card primary">
            <div className="stat-header">
              <div className="stat-icon-wrapper pink">
                <FiKey size={24} />
              </div>
              <span className="stat-trend neutral">
                <FiActivity size={14} />
                {tokens.active}
              </span>
            </div>
            <div className="stat-body">
              <h3 className="stat-value text-black">{tokens.total}</h3>
              <p className="stat-label">Access Tokens</p>
              <div className="stat-breakdown d-flex justify-content-center my-2 pt-2">
                <span>{tokens.active} Active</span>
                <span>•</span>
                <span>{tokens.total - tokens.active} Inactive</span>
              </div>
            </div>
          </div>
        </div>

        {/* Middle Section - 2 Columns */}
        <div className="content-row">
          <div className="content-card collections-card">
            <div className="card-header">
              <div className="card-title-group">
                <FiFolder size={20} />
                <h5 className="inter">Media Collections</h5>
              </div>
              <button
                className="btn-icon"
                onClick={() => onNavigate && onNavigate("galleries")}
              >
                <FiPlus size={18} />
              </button>
            </div>
            <div className="collections-list">
              {media.byCollection.length > 0 ? (
                media.byCollection.map((collection, index) => (
                  <div key={index} className="collection-item">
                    <div className="collection-info">
                      <div className="collection-icon">
                        <FiFolder size={18} />
                      </div>
                      <div>
                        <p className="collection-name">{collection.name}</p>
                        <p className="collection-meta">
                          {collection.count} files
                        </p>
                      </div>
                    </div>
                    <div className="collection-bar">
                      <div
                        className="collection-bar-fill"
                        style={{
                          width: `${(collection.count / media.total) * 100}%`,
                        }}
                      ></div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="empty-state-inline">
                  <FiFolder size={32} />
                  <p>No collections created yet</p>
                  <button className="btn-outline-small">
                    <FiPlus size={14} />
                    Create Collection
                  </button>
                </div>
              )}
            </div>
          </div>

          <div className="content-card activity-card">
            <div className="card-header">
              <div className="card-title-group">
                <FiActivity size={20} />
                <h5 className="inter">Recent Activity</h5>
              </div>
              <span className="badge-today inter">Today</span>
            </div>
            <div className="activity-timeline">
              <div className="timeline-item">
                <div className="timeline-dot pink"></div>
                <div className="timeline-content">
                  <div className="timeline-header">
                    <FiUpload size={16} />
                    <span className="timeline-title">Media Upload</span>
                  </div>
                  <p className="timeline-time">
                    {formatDate(activity.lastUploadAt)}
                  </p>
                </div>
              </div>
              <div className="timeline-item">
                <div className="timeline-dot pink"></div>
                <div className="timeline-content">
                  <div className="timeline-header">
                    <FiKey size={16} />
                    <span className="timeline-title">Token Generated</span>
                  </div>
                  <p className="timeline-time">
                    {formatDate(activity.lastTokenCreatedAt)}
                  </p>
                </div>
              </div>
              <div className="timeline-item">
                <div className="timeline-dot pink"></div>
                <div className="timeline-content">
                  <div className="timeline-header">
                    <FiEye size={16} />
                    <span className="timeline-title">Gallery Viewed</span>
                  </div>
                  <p className="timeline-time">2 hours ago</p>
                </div>
              </div>
              <div className="timeline-item">
                <div className="timeline-dot"></div>
                <div className="timeline-content">
                  <div className="timeline-header">
                    <FiCheckCircle size={16} />
                    <span className="timeline-title">Package Activated</span>
                  </div>
                  <p className="timeline-time">Yesterday</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Bottom Section - 3 Cards */}
        <div className="bottom-row">
          <div className="content-card package-card">
            <div className="card-header">
              <div className="card-title-group">
                <FiPackage size={20} />
                <h5>Current Package</h5>
              </div>
            </div>
            <div className="package-content">
              <div className="package-badge-large">{pkg.name} Plan</div>
              <div className="package-stats">
                <div className="package-stat-item">
                  <span className="package-stat-label">Storage Limit</span>
                  <strong className="package-stat-value">
                    {formatBytes(pkg.limitMB)}
                  </strong>
                </div>
                <div className="package-stat-item">
                  <span className="package-stat-label">Used Space</span>
                  <strong className="package-stat-value">
                    {formatBytes(pkg.usedMB)}
                  </strong>
                </div>
                <div className="package-stat-item">
                  <span className="package-stat-label">Available</span>
                  <strong className="package-stat-value pink-text">
                    {formatBytes(pkg.remainingMB)}
                  </strong>
                </div>
              </div>
              {(pkg.name === "Basic" || pkg.name === "Standard") && (
                <button
                  className="btn-primary full-width"
                  onClick={() => onNavigate && onNavigate("packages-storage")}
                >
                  <FiTrendingUp size={16} />
                  Upgrade Package
                </button>
              )}
            </div>
          </div>

          <div className="content-card tokens-card">
            <div className="card-header">
              <div className="card-title-group">
                <FiKey size={20} />
                <h5>Token Distribution</h5>
              </div>
            </div>
            <div className="tokens-content">
              {tokens.byType.length > 0 ? (
                tokens.byType.map((token, index) => (
                  <div key={index} className="token-item">
                    <div className="token-info">
                      <div className="token-icon">
                        <FiKey size={16} />
                      </div>
                      <span className="token-name">{token.type}</span>
                    </div>
                    <div className="token-count-wrapper">
                      <span className="token-count">{token.count}</span>
                      <div className="token-progress">
                        <div
                          className="token-progress-fill"
                          style={{
                            width: `${(token.count / tokens.total) * 100}%`,
                          }}
                        ></div>
                      </div>
                    </div>
                  </div>
                ))
              ) : (
                <div className="empty-state-inline">
                  <FiKey size={28} />
                  <p>No tokens created</p>
                </div>
              )}
            </div>
          </div>

          <div className="content-card quick-actions-card">
            <div className="card-header">
              <div className="card-title-group">
                <FiSettings size={20} />
                <h5>Quick Actions</h5>
              </div>
            </div>
            <div className="quick-actions-grid">
              <button
                className="action-button"
                disabled={!usage.canUpload}
                onClick={() => onNavigate && onNavigate("upload-media")}
              >
                <div className="action-icon">
                  <FiUpload size={20} />
                </div>
                <span>Upload Media</span>
              </button>
              <button
                className="action-button"
                onClick={() => onNavigate && onNavigate("galleries")}
              >
                <div className="action-icon">
                  <FiFolder size={20} />
                </div>
                <span>New Collection</span>
              </button>
              <button
                className="action-button"
                onClick={() => onNavigate && onNavigate("tokens-sharing")}
              >
                <div className="action-icon">
                  <FiKey size={20} />
                </div>
                <span>Generate Token</span>
              </button>
              <button
                className="action-button"
                onClick={() => onNavigate && onNavigate("analytics")}
              >
                <div className="action-icon">
                  <FiBarChart2 size={20} />
                </div>
                <span>View Analytics</span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};

export default VendorDashboard;
