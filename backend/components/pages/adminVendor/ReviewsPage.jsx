import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { FiStar, FiMail } from "react-icons/fi";

import ReviewsDashboard from "./subVendors/ReviewsDashboard";
import Reviews from "./subVendors/Reviews";
import ReviewsCollector from "./subVendors/ReviewsCollector";
import axiosInstance from "../../../services/api/axiosInstance";

const ReviewsPage = () => {
  const [activeSection, setActiveSection] = useState("reviews");
  const { vendor, token: vendorToken } = useSelector(
    (state) => state.vendorAuth
  );

  const [reviews, setReviews] = useState([]);
  const [stats, setStats] = useState({
    averageRating: 0,
    reviewCount: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const fetchAll = async () => {
    setLoading(true);
    setError(null);
    await Promise.all([fetchReviews(), fetchStats()]);
    setLoading(false);
  };

  const fetchReviews = async () => {
    try {
      const res = await axiosInstance.get("/reviews/my-reviews", {
        headers: { Authorization: `Bearer ${vendorToken}` },
      });
      const data = res.data;

      const formattedReviews = data.reviews.map((r) => ({
        id: r.id,
        name: r.user?.name || "Anonymous",
        rating: Number(
          (
            (r.rating_quality +
              r.rating_responsiveness +
              r.rating_professionalism +
              r.rating_value +
              r.rating_flexibility) /
            5
          ).toFixed(1)
        ),
        review: r.comment,
        date: new Date(r.createdAt).toLocaleDateString(),
        verified: true,
        reply: r.vendor_reply,
      }));

      setReviews(formattedReviews);
    } catch (err) {
      setError(err.message);
    }
  };

  const fetchStats = async () => {
    try {
      if (!vendor?.id) return;
      const res = await axiosInstance.get(
        `/reviews/vendor/${vendor.id}/average`
      );
      const data = res.data;

      setStats({
        averageRating: parseFloat(data.averageRating) || 0,
        reviewCount: parseInt(data.totalReviews) || 0,
      });
    } catch (err) {
      setError(err.message);
    }
  };

  useEffect(() => {
    if (!vendorToken) {
      setError("Vendor not authenticated.");
      setLoading(false);
      return;
    }
    fetchAll();
  }, [vendorToken]);

  const handleReplySubmit = async (reviewId, replyText) => {
    try {
      await axiosInstance.put(
        `/reviews/reply/${reviewId}`,
        { vendor_reply: replyText },
        {
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${vendorToken}`,
          },
        }
      );

      setReviews((prev) =>
        prev.map((rev) =>
          rev.id === reviewId ? { ...rev, reply: replyText } : rev
        )
      );
    } catch (err) {
      setError(err.message);
    }
  };

  const handleDelete = async (reviewId) => {
    if (!window.confirm("Are you sure you want to delete this review?")) {
      return;
    }

    try {
      await axiosInstance.delete(`/reviews/${reviewId}`, {
        headers: {
          Authorization: `Bearer ${vendorToken}`,
        },
      });

      setReviews((prev) => prev.filter((rev) => rev.id !== reviewId));
    } catch (err) {
      setError(err.message);
    }
  };

  const totalReviews = stats.reviewCount;
  const averageRating = stats.averageRating;
  const positiveReviews = reviews.filter((r) => r.rating >= 4).length;
  const negativeReviews = reviews.filter((r) => r.rating <= 2).length;

  const renderStars = (rating) =>
    Array.from({ length: 5 }, (_, i) => (
      <span key={i} style={{ color: i < rating ? "#ffc107" : "#e4e5e9" }}>
        {i < rating ? "★" : "☆"}
      </span>
    ));

  const renderContent = () => {
    if (activeSection === "review-collector") {
      return (
        <div>
          <ReviewsCollector />
        </div>
      );
    }

    if (activeSection === "reviews") {
      return (
        <div>
          <div className="text-center mb-5">
            <h3>Wedding Reviews</h3>
            <p>Real experiences from real couples</p>
          </div>
          {loading ? (
            <div className="text-center py-5">
              <div className="spinner-border text-primary" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
              <p className="mt-3">Loading reviews...</p>
            </div>
          ) : error ? (
            <div className="alert alert-danger" role="alert">
              {error}
            </div>
          ) : (
            <ReviewsCardGrid
              reviews={reviews}
              averageRating={averageRating}
              totalReviews={totalReviews}
              onReplySubmit={handleReplySubmit}
              onDelete={handleDelete}
              renderStars={renderStars}
            />
          )}
        </div>
      );
    }

    return (
      <div className="text-center py-5">
        <h2>{activeSection} Section</h2>
        <p>Content coming soon...</p>
      </div>
    );
  };

  return (
    <div className="">
      <style>{`
        .modern-tabs {
          border-bottom: 2px solid #e5e7eb;
          margin-bottom: 2rem;
        }
        
        .modern-tab {
          position: relative;
          padding: 0.875rem 1.5rem;
          border: none;
          background: transparent;
          color: #6b7280;
          font-weight: 500;
          font-size: 0.9375rem;
          cursor: pointer;
          transition: all 0.2s;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          border-bottom: 2px solid transparent;
          margin-bottom: -2px;
        }
        
        .modern-tab:hover {
          color: #111827;
        }
        
        .modern-tab.active {
          color: #e91e63;
          border-bottom-color: #e91e63;
        }
        
        .modern-tab svg {
          font-size: 1.125rem;
        }
      `}</style>
      <div className="container">
        <div className="d-flex justify-content-center">
          <div className="w-100" style={{ maxWidth: 1000 }}>
            <div className="modern-tabs d-flex justify-content-start flex-wrap">
              <button
                type="button"
                className={`modern-tab ${
                  activeSection === "reviews" ? "active" : ""
                }`}
                onClick={() => setActiveSection("reviews")}
              >
                <FiStar />
                Reviews
              </button>
              <button
                type="button"
                className={`modern-tab ${
                  activeSection === "review-collector" ? "active" : ""
                }`}
                onClick={() => setActiveSection("review-collector")}
              >
                <FiMail />
                Review Collector
              </button>
            </div>
            <div className="py-4">{renderContent()}</div>
          </div>
        </div>
      </div>
    </div>
  );
};

const ReviewsCardGrid = ({
  reviews,
  averageRating,
  totalReviews,
  onReplySubmit,
  onDelete,
  renderStars,
}) => {
  const [replyingTo, setReplyingTo] = useState(null);
  const [replyText, setReplyText] = useState("");

  const handleReplyClick = (reviewId, existingReply) => {
    setReplyingTo(reviewId);
    setReplyText(existingReply || "");
  };

  const handleReplyCancel = () => {
    setReplyingTo(null);
    setReplyText("");
  };

  const handleReplySubmitLocal = (reviewId) => {
    if (replyText.trim()) {
      onReplySubmit(reviewId, replyText);
      setReplyingTo(null);
      setReplyText("");
    }
  };

  return (
    <div className="container-fluid px-0">
      {/* Stats Summary - Responsive Grid */}
      <div className="row g-3 mb-4">
        <div className="col-12 col-sm-6 col-lg-4 d-flex">
          <div className="card shadow-sm rounded-3 h-100 w-100">
            <div className="card-body text-center py-3">
              <h3 className="mb-1">{averageRating.toFixed(1)}</h3>
              <div className="mb-2">
                {renderStars(Math.round(averageRating))}
              </div>
              <p className="text-muted mb-0 small">Average Rating</p>
            </div>
          </div>
        </div>

        <div className="col-12 col-sm-6 col-lg-4 d-flex">
          <div className="card shadow-sm rounded-3 h-100 w-100">
            <div className="card-body text-center py-3">
              <h3 className="mb-1">{totalReviews}</h3>
              <p className="text-muted mb-0 small">Total Reviews</p>
            </div>
          </div>
        </div>

        <div className="col-12 col-sm-12 col-lg-4 d-flex">
          <div className="card shadow-sm rounded-3 h-100 w-100">
            <div className="card-body text-center py-3">
              <h3 className="mb-1">{reviews.filter((r) => r.reply).length}</h3>
              <p className="text-muted mb-0 small">Replies Sent</p>
            </div>
          </div>
        </div>
      </div>

      {/* Reviews List - Horizontal Cards */}
      {reviews.length === 0 ? (
        <div className="text-center py-5">
          <p className="text-muted">No reviews yet</p>
        </div>
      ) : (
        <div className="d-flex flex-column gap-3">
          {reviews.map((review) => (
            <div key={review.id} className="card shadow-sm rounded-3">
              <div className="card-body p-3 p-md-4">
                <div className="row g-3">
                  {/* Left Section - User Info & Rating */}
                  <div className="col-12 col-md-3 col-lg-2">
                    <div className="d-flex flex-row flex-md-column align-items-start">
                      <div className="flex-grow-1 flex-md-grow-0">
                        <h5
                          className="card-title mb-1"
                          style={{ wordBreak: "break-word" }}
                        >
                          {review.name}
                        </h5>
                        <small className="text-muted d-block mb-2">
                          {review.date}
                        </small>
                        {review.verified && (
                          <span className="badge bg-success mb-2">
                            Verified
                          </span>
                        )}
                      </div>
                      <div className="ms-3 ms-md-0 mt-md-2">
                        <div className="d-flex align-items-center flex-nowrap">
                          <div className="me-2">
                            {renderStars(review.rating)}
                          </div>
                          <strong className="text-nowrap">
                            {review.rating}
                          </strong>
                        </div>
                      </div>
                    </div>
                  </div>

                  <div
                    className="col-12 col-md-9 col-lg-10 d-flex flex-column"
                    style={{ minHeight: "100%" }}
                  >
                    {/* Review Text */}
                    <div className="mb-3">
                      <p
                        className="card-text mb-0"
                        style={{
                          wordWrap: "break-word",
                          overflowWrap: "break-word",
                          whiteSpace: "pre-wrap",
                        }}
                      >
                        {review.review}
                      </p>
                    </div>

                    {review.reply && (
                      <div className="alert alert-light border rounded-3 mb-3">
                        <small className="text-muted d-block mb-1">
                          <strong>Your Reply:</strong>
                        </small>
                        <p
                          className="mb-0 small"
                          style={{
                            wordWrap: "break-word",
                            overflowWrap: "break-word",
                            whiteSpace: "pre-wrap",
                          }}
                        >
                          {review.reply}
                        </p>
                      </div>
                    )}

                    {replyingTo === review.id && (
                      <div className="mb-3">
                        <textarea
                          className="form-control rounded-3 mb-2"
                          rows="3"
                          placeholder="Write your reply..."
                          value={replyText}
                          onChange={(e) => setReplyText(e.target.value)}
                        />
                        <div className="d-flex flex-wrap gap-2">
                          <button
                            className="btn btn-primary btn-sm rounded-3"
                            onClick={() => handleReplySubmitLocal(review.id)}
                          >
                            Submit Reply
                          </button>
                          <button
                            className="btn btn-secondary btn-sm rounded-3"
                            onClick={handleReplyCancel}
                          >
                            Cancel
                          </button>
                        </div>
                      </div>
                    )}

                    <div className="mt-auto d-flex flex-row flex-md-row gap-2 justify-content-end">
                      {replyingTo !== review.id && (
                        <button
                          className="btn btn-outline-primary btn-sm rounded-3 col-3 w-md-auto"
                          onClick={() =>
                            handleReplyClick(review.id, review.reply)
                          }
                        >
                          {review.reply ? "Edit Reply" : "Reply"}
                        </button>
                      )}
                      <button
                        className="btn btn-outline-danger btn-sm rounded-3 col-3 w-md-auto"
                        onClick={() => onDelete(review.id)}
                      >
                        Delete
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};

export default ReviewsPage;
