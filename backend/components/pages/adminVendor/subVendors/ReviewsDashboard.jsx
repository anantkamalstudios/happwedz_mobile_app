import React from "react";

const ReviewsDashboard = ({
  totalReviews,
  averageRating,
  positiveReviews,
  negativeReviews,
  reviewsData,
  renderStars,
}) => {
  return (
    <div>
      <div className="dashboard-view">
        <h2>Reviews Dashboard</h2>
        <div className="stats-container">
          <div className="stat-card">
            <h3>Total Reviews</h3>
            <p className="stat-value">{totalReviews}</p>
          </div>
          <div className="stat-card">
            <h3>Average Rating</h3>
            <div className="rating-display">
              {renderStars(averageRating)}
              <span>{averageRating.toFixed(1)}/5</span>
            </div>
          </div>
          <div className="stat-card positive">
            <h3>Positive Reviews</h3>
            <p className="stat-value">{positiveReviews}</p>
          </div>
          <div className="stat-card negative">
            <h3>Negative Reviews</h3>
            <p className="stat-value">{negativeReviews}</p>
          </div>
        </div>

        <div className="recent-reviews">
          <h3>Recent Reviews</h3>
          {reviewsData.slice(0, 3).map((review) => (
            <div key={review.id} className="review-card">
              <div className="review-header">
                <div className="reviewer-info">
                  <div className="avatar">{review.name.charAt(0)}</div>
                  <div>
                    <h4>{review.name}</h4>
                    <div className="review-rating">
                      {renderStars(review.rating)}
                      <span>{review.date}</span>
                    </div>
                  </div>
                </div>
                <div className="review-type">{review.type}</div>
              </div>
              <p>{review.comment}</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ReviewsDashboard;
