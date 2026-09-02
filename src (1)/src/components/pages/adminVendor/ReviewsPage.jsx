import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import {
  FiStar,
  FiMail,
  FiCheckCircle,
  FiMessageSquare,
  FiCornerUpLeft,
  FiTrash2,
  FiEdit3,
  FiCalendar,
  FiUser,
  FiAward,
  FiCode,
} from "react-icons/fi";

import ReviewsCollector from "./subVendors/ReviewsCollector";
import ReviewWidget from "./subVendors/ReviewWidget";
import axiosInstance from "../../../services/api/axiosInstance";
import { formatDate } from "../../../utils/dateFormat";

const getAvatarBg = (name = "") => {
  const colors = [
    "#ed1173",
    "#6366f1",
    "#0ea5e9",
    "#10b981",
    "#f59e0b",
    "#8b5cf6",
  ];
  let hash = 0;
  for (let i = 0; i < name.length; i++) {
    hash = name.charCodeAt(i) + ((hash << 5) - hash);
  }
  return colors[Math.abs(hash) % colors.length];
};

const getInitials = (name = "") => {
  if (!name.trim()) return "U";
  const parts = name.trim().split(" ");
  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
  return name.slice(0, 2).toUpperCase();
};

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

      const formattedReviews = (data.reviews || []).map((r) => ({
        id: r.id,
        name: r.user?.name || "Verified Couple",
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
        date: formatDate(r.createdAt),
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

  const totalReviews = stats.reviewCount || reviews.length;
  const averageRating = stats.averageRating || 0;
  const repliedCount = reviews.filter((r) => r.reply).length;

  const renderStars = (rating) => {
    const full = Math.floor(rating);
    const hasHalf = rating - full >= 0.4;
    return (
      <div className="d-inline-flex align-items-center gap-1">
        {[1, 2, 3, 4, 5].map((star) => (
          <span
            key={star}
            style={{
              color: star <= full ? "#f59e0b" : star === full + 1 && hasHalf ? "#fbbf24" : "#e2e8f0",
              fontSize: "1rem",
            }}
          >
            ★
          </span>
        ))}
      </div>
    );
  };

  return (
    <div className="py-4">
      <style>{`
        .reviews-tab-btn {
          border: none;
          background: transparent;
          color: #64748b;
          font-weight: 600;
          font-size: 0.95rem;
          padding: 0.75rem 1.25rem;
          border-bottom: 2px solid transparent;
          transition: all 0.2s ease;
          display: inline-flex;
          align-items: center;
          gap: 0.5rem;
        }
        .reviews-tab-btn:hover {
          color: #0f172a;
        }
        .reviews-tab-btn.active {
          color: #ed1173;
          border-bottom-color: #ed1173;
        }
        .stat-card-hover {
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .stat-card-hover:hover {
          transform: translateY(-2px);
          box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.08) !important;
        }
      `}</style>

      <div className="container" style={{ maxWidth: 1060 }}>
        {/* Navigation Tabs */}
        <div className="d-flex border-bottom mb-4 gap-2">
          <button
            type="button"
            className={`reviews-tab-btn ${activeSection === "reviews" ? "active" : ""}`}
            onClick={() => setActiveSection("reviews")}
          >
            <FiStar size={17} />
            <span>Reviews</span>
          </button>
          <button
            type="button"
            className={`reviews-tab-btn ${activeSection === "review-collector" ? "active" : ""}`}
            onClick={() => setActiveSection("review-collector")}
          >
            <FiMail size={17} />
            <span>Review Collector</span>
          </button>
          <button
            type="button"
            className={`reviews-tab-btn ${activeSection === "review-widget" ? "active" : ""}`}
            onClick={() => setActiveSection("review-widget")}
          >
            <FiCode size={17} />
            <span>Review Widget</span>
          </button>
        </div>

        {activeSection === "review-collector" ? (
          <ReviewsCollector />
        ) : activeSection === "review-widget" ? (
          <ReviewWidget />
        ) : (
          <div>
            {/* Header */}
            <div className="text-center mb-4">
              <h3
                className="fw-bold mb-2"
                style={{ color: "#0f172a", fontSize: "1.6rem", letterSpacing: "-0.02em" }}
              >
                Wedding Reviews
              </h3>
              <p className="text-muted mb-0 fs-14">
                Real experiences and verified feedback from happy couples
              </p>
            </div>

            {loading ? (
              <div className="text-center py-5">
                <div
                  className="spinner-border"
                  role="status"
                  style={{ color: "#ed1173", width: "2.5rem", height: "2.5rem" }}
                >
                  <span className="visually-hidden">Loading...</span>
                </div>
                <p className="mt-3 text-muted fs-14">Loading reviews...</p>
              </div>
            ) : error ? (
              <div className="alert alert-danger rounded-3" role="alert">
                {error}
              </div>
            ) : (
              <>
                {/* 3 Metric Stat Cards */}
                <div className="row g-3 mb-4">
                  {/* Average Rating */}
                  <div className="col-12 col-md-4">
                    <div
                      className="card border-0 shadow-sm rounded-4 h-100 stat-card-hover"
                      style={{ backgroundColor: "#ffffff", border: "1px solid #f1f5f9" }}
                    >
                      <div className="card-body p-4 text-center d-flex flex-column align-items-center justify-content-center">
                        <div
                          className="d-inline-flex align-items-center justify-content-center rounded-circle mb-2"
                          style={{
                            width: "48px",
                            height: "48px",
                            backgroundColor: "#fffbeb",
                            color: "#f59e0b",
                          }}
                        >
                          <FiAward size={22} />
                        </div>
                        <h2 className="fw-bold mb-1 text-dark" style={{ fontSize: "2rem" }}>
                          {averageRating > 0 ? averageRating.toFixed(1) : "0.0"}
                        </h2>
                        <div className="mb-2">{renderStars(averageRating)}</div>
                        <span className="text-muted small fw-medium">Average Rating</span>
                      </div>
                    </div>
                  </div>

                  {/* Total Reviews */}
                  <div className="col-12 col-md-4">
                    <div
                      className="card border-0 shadow-sm rounded-4 h-100 stat-card-hover"
                      style={{ backgroundColor: "#ffffff", border: "1px solid #f1f5f9" }}
                    >
                      <div className="card-body p-4 text-center d-flex flex-column align-items-center justify-content-center">
                        <div
                          className="d-inline-flex align-items-center justify-content-center rounded-circle mb-2"
                          style={{
                            width: "48px",
                            height: "48px",
                            backgroundColor: "#fff1f6",
                            color: "#ed1173",
                          }}
                        >
                          <FiMessageSquare size={22} />
                        </div>
                        <h2 className="fw-bold mb-1 text-dark" style={{ fontSize: "2rem" }}>
                          {totalReviews}
                        </h2>
                        <p className="text-muted small mb-0 fw-medium">Total Reviews</p>
                      </div>
                    </div>
                  </div>

                  {/* Replies Sent */}
                  <div className="col-12 col-md-4">
                    <div
                      className="card border-0 shadow-sm rounded-4 h-100 stat-card-hover"
                      style={{ backgroundColor: "#ffffff", border: "1px solid #f1f5f9" }}
                    >
                      <div className="card-body p-4 text-center d-flex flex-column align-items-center justify-content-center">
                        <div
                          className="d-inline-flex align-items-center justify-content-center rounded-circle mb-2"
                          style={{
                            width: "48px",
                            height: "48px",
                            backgroundColor: "#ecfdf5",
                            color: "#10b981",
                          }}
                        >
                          <FiCornerUpLeft size={22} />
                        </div>
                        <h2 className="fw-bold mb-1 text-dark" style={{ fontSize: "2rem" }}>
                          {repliedCount}
                        </h2>
                        <p className="text-muted small mb-0 fw-medium">Replies Sent</p>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Reviews List */}
                {reviews.length === 0 ? (
                  <div
                    className="card border-0 shadow-sm rounded-4 p-5 text-center my-3"
                    style={{ backgroundColor: "#fafbfc", border: "2px dashed #cbd5e1" }}
                  >
                    <div
                      className="d-inline-flex align-items-center justify-content-center mb-3 rounded-circle"
                      style={{
                        width: "64px",
                        height: "64px",
                        backgroundColor: "#fff1f6",
                        color: "#ed1173",
                      }}
                    >
                      <FiStar size={28} />
                    </div>
                    <h5 className="fw-bold text-dark mb-1 fs-16">No Reviews Yet</h5>
                    <p className="text-muted small mb-3" style={{ maxWidth: "420px", margin: "0 auto" }}>
                      Send review requests to your past clients using Review Collector to build trust and attract more couples.
                    </p>
                    <div>
                      <button
                        type="button"
                        className="btn btn-primary btn-sm rounded-pill px-4 py-2 fw-semibold"
                        style={{ backgroundColor: "#ed1173", borderColor: "#ed1173" }}
                        onClick={() => setActiveSection("review-collector")}
                      >
                        <FiMail className="me-1" />
                        Go to Review Collector
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="d-flex flex-column gap-3">
                    {reviews.map((review) => (
                      <ReviewItem
                        key={review.id}
                        review={review}
                        renderStars={renderStars}
                        onReplySubmit={handleReplySubmit}
                        onDelete={handleDelete}
                      />
                    ))}
                  </div>
                )}
              </>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

const ReviewItem = ({ review, renderStars, onReplySubmit, onDelete }) => {
  const [replying, setReplying] = useState(false);
  const [replyText, setReplyText] = useState(review.reply || "");

  const handleSaveReply = () => {
    if (replyText.trim()) {
      onReplySubmit(review.id, replyText.trim());
      setReplying(false);
    }
  };

  const handleCancelReply = () => {
    setReplyText(review.reply || "");
    setReplying(false);
  };

  return (
    <div
      className="card border-0 shadow-sm rounded-4 overflow-hidden"
      style={{ backgroundColor: "#ffffff", border: "1px solid #f1f5f9" }}
    >
      <div className="card-body p-4">
        {/* Top Header: Avatar + User Info + Stars */}
        <div className="d-flex justify-content-between align-items-start gap-3 flex-wrap mb-3">
          {/* User Info */}
          <div className="d-flex align-items-center gap-3">
            <div
              className="d-flex align-items-center justify-content-center rounded-circle text-white fw-bold shadow-sm flex-shrink-0"
              style={{
                width: "48px",
                height: "48px",
                backgroundColor: getAvatarBg(review.name),
                fontSize: "1.1rem",
                letterSpacing: "0.5px",
              }}
            >
              {getInitials(review.name)}
            </div>

            <div>
              <div className="d-flex align-items-center gap-2 flex-wrap">
                <h5 className="fw-bold text-dark mb-0 fs-16" style={{ letterSpacing: "-0.01em" }}>
                  {review.name}
                </h5>
                {review.verified && (
                  <span
                    className="badge rounded-pill fw-semibold d-inline-flex align-items-center gap-1"
                    style={{
                      backgroundColor: "#ecfdf5",
                      color: "#059669",
                      border: "1px solid #a7f3d0",
                      fontSize: "11px",
                      padding: "3px 8px",
                    }}
                  >
                    <FiCheckCircle size={11} />
                    <span>Verified Couple</span>
                  </span>
                )}
              </div>

              <div className="text-muted small mt-1 d-flex align-items-center gap-1" style={{ fontSize: "12px" }}>
                <FiCalendar size={12} className="text-muted" />
                <span>{review.date}</span>
              </div>
            </div>
          </div>

          {/* Rating Badge */}
          <div className="d-flex flex-column align-items-end">
            <div className="d-flex align-items-center gap-2">
              {renderStars(review.rating)}
              <span
                className="badge rounded-pill fw-bold"
                style={{
                  backgroundColor: "#fffbeb",
                  color: "#b45309",
                  border: "1px solid #fde68a",
                  fontSize: "12px",
                }}
              >
                {review.rating.toFixed(1)} / 5.0
              </span>
            </div>
          </div>
        </div>

        {/* Review Comment */}
        <div className="mb-3 ps-md-2">
          <p
            className="mb-0 text-secondary"
            style={{
              fontSize: "14.5px",
              lineHeight: "1.65",
              whiteSpace: "pre-wrap",
              wordBreak: "break-word",
            }}
          >
            {review.review}
          </p>
        </div>

        {/* Existing Vendor Reply */}
        {review.reply && !replying && (
          <div
            className="p-3 rounded-3 mb-3"
            style={{
              backgroundColor: "#fff1f6",
              border: "1px solid #fce7f3",
            }}
          >
            <div className="d-flex align-items-center justify-content-between mb-1">
              <span
                className="fw-bold d-inline-flex align-items-center gap-1"
                style={{ color: "#ed1173", fontSize: "13px" }}
              >
                <FiCornerUpLeft size={13} />
                <span>Your Response</span>
              </span>
            </div>
            <p
              className="mb-0 text-dark small"
              style={{
                lineHeight: "1.6",
                whiteSpace: "pre-wrap",
                wordBreak: "break-word",
              }}
            >
              {review.reply}
            </p>
          </div>
        )}

        {/* Inline Reply Form */}
        {replying && (
          <div
            className="p-3 rounded-3 mb-3"
            style={{ backgroundColor: "#fafbfc", border: "1px solid #e2e8f0" }}
          >
            <label className="form-label fw-semibold text-dark fs-13 mb-2 d-flex align-items-center gap-1">
              <FiCornerUpLeft style={{ color: "#ed1173" }} size={14} />
              <span>Write a response to this couple:</span>
            </label>
            <textarea
              className="form-control fs-14 mb-2"
              rows="3"
              placeholder="Thank the couple and add your reply..."
              value={replyText}
              onChange={(e) => setReplyText(e.target.value)}
              style={{ borderColor: "#e2e8f0", borderRadius: "10px" }}
            />
            <div className="d-flex gap-2">
              <button
                type="button"
                className="btn btn-primary btn-sm rounded-pill px-3 fw-semibold"
                style={{ backgroundColor: "#ed1173", borderColor: "#ed1173" }}
                onClick={handleSaveReply}
                disabled={!replyText.trim()}
              >
                Submit Response
              </button>
              <button
                type="button"
                className="btn btn-outline-secondary btn-sm rounded-pill px-3"
                onClick={handleCancelReply}
              >
                Cancel
              </button>
            </div>
          </div>
        )}

        {/* Card Footer Actions */}
        <div className="d-flex justify-content-end align-items-center gap-2 pt-2 border-top">
          {!replying && (
            <button
              type="button"
              className="btn btn-outline-primary btn-sm rounded-pill px-3 fs-13 d-inline-flex align-items-center gap-1"
              style={{
                color: "#ed1173",
                borderColor: "#fce7f3",
                backgroundColor: "#fff1f6",
              }}
              onClick={() => {
                setReplyText(review.reply || "");
                setReplying(true);
              }}
            >
              <FiEdit3 size={13} />
              <span>{review.reply ? "Edit Reply" : "Reply"}</span>
            </button>
          )}

          <button
            type="button"
            className="btn btn-outline-danger btn-sm rounded-pill px-3 fs-13 d-inline-flex align-items-center gap-1"
            style={{
              color: "#ef4444",
              borderColor: "#fee2e2",
              backgroundColor: "#fef2f2",
            }}
            onClick={() => onDelete(review.id)}
          >
            <FiTrash2 size={13} />
            <span>Delete</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default ReviewsPage;
