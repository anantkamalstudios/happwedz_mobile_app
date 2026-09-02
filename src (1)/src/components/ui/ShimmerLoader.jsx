import React from "react";

const ShimmerLoader = () => {
  return (
    <div className="shimmer-container">
      <div className="shimmer-wrapper">
        {/* Header shimmer */}
        <div className="shimmer-header">
          <div className="shimmer-line shimmer-title"></div>
          <div className="shimmer-line shimmer-subtitle"></div>
          <div className="shimmer-line shimmer-subtitle-small"></div>
        </div>

        {/* Content shimmer */}
        <div className="shimmer-content">
          <div className="shimmer-card">
            <div className="shimmer-image"></div>
            <div className="shimmer-text">
              <div className="shimmer-line shimmer-line-medium"></div>
              <div className="shimmer-line shimmer-line-small"></div>
              <div className="shimmer-line shimmer-line-large"></div>
            </div>
          </div>

          <div className="shimmer-card">
            <div className="shimmer-image"></div>
            <div className="shimmer-text">
              <div className="shimmer-line shimmer-line-medium"></div>
              <div className="shimmer-line shimmer-line-small"></div>
              <div className="shimmer-line shimmer-line-large"></div>
            </div>
          </div>

          <div className="shimmer-card">
            <div className="shimmer-image"></div>
            <div className="shimmer-text">
              <div className="shimmer-line shimmer-line-medium"></div>
              <div className="shimmer-line shimmer-line-small"></div>
              <div className="shimmer-line shimmer-line-large"></div>
            </div>
          </div>
        </div>

        {/* Navigation shimmer */}
        <div className="shimmer-navigation">
          <div className="shimmer-nav-item"></div>
          <div className="shimmer-nav-item"></div>
          <div className="shimmer-nav-item"></div>
          <div className="shimmer-nav-item"></div>
          <div className="shimmer-nav-item"></div>
        </div>

        {/* Footer shimmer */}
        <div className="shimmer-footer">
          <div className="shimmer-line shimmer-footer-line"></div>
          <div className="shimmer-line shimmer-footer-line-small"></div>
        </div>
      </div>
    </div>
  );
};

export default ShimmerLoader;
