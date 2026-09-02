import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import { FaStar } from "react-icons/fa";
import "react-toastify/dist/ReactToastify.css";
import "bootstrap/dist/css/bootstrap.min.css";
import { Button, Card, Modal } from "react-bootstrap";
import { formatDate } from "../../utils/dateFormat";

const API_BASE_URL = "https://happywedz.com/api";

const getReviewerName = (review) => review?.user?.name || "Anonymous";
const getReviewerInitial = (review) =>
  getReviewerName(review).trim().charAt(0).toUpperCase() || "A";

const ReviewSection = ({ vendor }) => {
  const { user, token } = useSelector((state) => state.auth);
  const navigate = useNavigate();

  const [reviews, setReviews] = useState([]);
  const [showDetailModal, setShowDetailModal] = useState(false);
  const [selectedReview, setSelectedReview] = useState(null);
  const [showAllReviews, setShowAllReviews] = useState(false);

  useEffect(() => {
    if (!vendor?.id) return;

    const controller = new AbortController();
    fetch(`${API_BASE_URL}/reviews/${vendor.id}`, { signal: controller.signal })
      .then((res) => res.json())
      .then((data) => {
        if (data.success) setReviews(data.reviews);
      })
      .catch(() => {});

    return () => controller.abort();
  }, [vendor?.id]);

  const handleReadMoreClick = (review) => {
    setSelectedReview(review);
    setShowDetailModal(true);
  };

  const handleWriteReviewClick = () => {
    if (!user || !token) navigate("/customer-login");
    else navigate(`/write-review/${vendor.id}`);
  };

  const calculateAverageRating = (field) => {
    if (reviews.length === 0) return 0;
    const sum = reviews.reduce((acc, review) => acc + (review[field] || 0), 0);
    return (sum / reviews.length).toFixed(1);
  };

  const overallRating =
    reviews.length > 0
      ? (
          reviews.reduce((sum, r) => sum + r.rating_quality, 0) / reviews.length
        ).toFixed(1)
      : "0.0";

  const ratingCategories = [
    {
      label: "Quality of service",
      field: "rating_quality",
      value: calculateAverageRating("rating_quality"),
      icon: "/images/review/quality.png",
    },
    {
      label: "Responsiveness",
      field: "rating_responsiveness",
      value: calculateAverageRating("rating_responsiveness"),
      icon: "/images/review/responsiveness.png",
    },
    {
      label: "Professionalism",
      field: "rating_professionalism",
      value: calculateAverageRating("rating_professionalism"),
      icon: "/images/review/professionalism.png",
    },
    {
      label: "Value",
      field: "rating_value",
      value: calculateAverageRating("rating_value"),
      icon: "/images/review/value.png",
    },
    {
      label: "Flexibility",
      field: "rating_flexibility",
      value: calculateAverageRating("rating_flexibility"),
      icon: "/images/review/flexibility.png",
    },
  ];

  const displayedReviews = showAllReviews ? reviews : reviews.slice(0, 6);

  const getRatingDistribution = () => {
    const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    reviews.forEach((review) => {
      const rating = Math.round(review.rating_quality);
      if (rating >= 1 && rating <= 5) {
        distribution[rating]++;
      }
    });
    return distribution;
  };

  const ratingDistribution = getRatingDistribution();

  return (
    <div className="container my-5">
      {/* <div className="row mb-5">
        <div className="col-12">
          <div className="d-flex align-items-center justify-content-between mb-4">
            <div className="d-flex align-items-center gap-2">
              <FaStar size={28} />
              <h2 className="mb-0 fw-bold" style={{ fontSize: "26px" }}>
                {overallRating} · {reviews.length} review{reviews.length !== 1 ? "s" : ""}
              </h2>
            </div>
            <Button
              className="btn-dark rounded-3 px-4 py-2 fw-semibold"
              style={{ fontSize: "16px" }}
              onClick={handleWriteReviewClick}
            >
              Write a review
            </Button>
          </div>
        </div>
      </div> */}

      <div className="d-flex justify-content-between align-items-center mb-4 flex-wrap gap-3">
        <div>
          <h2 className="fw-bold mb-2 fs-22">
            Reviews of{" "}
            {vendor?.attributes?.name ||
              vendor?.name ||
              vendor?.businessName ||
              vendor?.Name}{" "}
          </h2>
          <div className="d-flex align-items-center mb-1">
            <FaStar className="text-warning me-2" size={14} />
            <div className="mb-0 fw-bold fs-14">
              {reviews.length > 0
                ? (
                    reviews.reduce((sum, r) => sum + r.rating_quality, 0) /
                    reviews.length
                  ).toFixed(1)
                : "0.0"}{" "}
              <span className="text-dark fw-normal fs-14">Excellent</span>
            </div>
            <span className="text-muted ms-2 fs-14">
              • {reviews.length} Reviews
            </span>
          </div>
        </div>

        <div className="d-flex align-items-center">
          <Button
            className="btn-outline-primary fs-14"
            onClick={handleWriteReviewClick}
          >
            Write a review
          </Button>
        </div>
      </div>

      {reviews.length > 0 ? (
        <>
          <div className="row mb-5 justify-content-between border-bottom pb-4">
            <div className="col-md-4 mb-4 mb-md-0">
              <div className="d-flex flex-column gap-3">
                {[5, 4, 3, 2, 1].map((rating) => (
                  <div key={rating} className="d-flex align-items-center gap-3">
                    <span
                      className="text-dark"
                      style={{ fontSize: "14px", minWidth: "12px" }}
                    >
                      {rating}
                    </span>
                    <div
                      className="flex-grow-1 position-relative"
                      style={{
                        height: "6px",
                        backgroundColor: "#e0e0e0",
                        borderRadius: "4px",
                      }}
                    >
                      <div
                        style={{
                          position: "absolute",
                          left: 0,
                          top: 0,
                          height: "100%",
                          width:
                            reviews.length > 0
                              ? `${
                                  (ratingDistribution[rating] /
                                    reviews.length) *
                                  100
                                }%`
                              : "0%",
                          backgroundColor: "#222",
                          borderRadius: "4px",
                        }}
                      />
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div className="col-md-8 mb-4 mb-md-0 px-4">
              <div className="row g-4">
                {ratingCategories.map((category, index) => (
                  <div key={index} className="col-md-6 col-lg-6">
                    <div className="d-flex flex-column">
                      <div className="d-flex align-items-center justify-content-between mb-2">
                        <div className="d-flex align-items-center gap-2">
                          <img
                            src={category.icon}
                            alt={category.label}
                            style={{
                              width: "24px",
                              height: "24px",
                              objectFit: "contain",
                            }}
                            onError={(e) => {
                              e.target.style.display = "none";
                            }}
                          />
                          <span
                            className="text-dark"
                            style={{ fontSize: "14px", fontWeight: "500" }}
                          >
                            {category.label}
                          </span>
                        </div>
                        <span
                          className="text-dark fw-semibold"
                          style={{ fontSize: "14px" }}
                        >
                          {category.value}
                        </span>
                      </div>
                      <div
                        className="position-relative"
                        style={{
                          height: "4px",
                          backgroundColor: "#e0e0e0",
                          borderRadius: "4px",
                        }}
                      >
                        <div
                          style={{
                            position: "absolute",
                            left: 0,
                            top: 0,
                            height: "100%",
                            width: `${(category.value / 5) * 100}%`,
                            backgroundColor: "#222",
                            borderRadius: "4px",
                          }}
                        />
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="row g-4 mb-4">
            {displayedReviews.map((review) => (
              <div key={review.id} className="col-md-6 col-lg-6">
                <div className="h-100">
                  <div className="d-flex align-items-start gap-3 mb-3">
                    {review.user?.image ? (
                      <img
                        src={review.user.image}
                        alt={getReviewerName(review)}
                        className="rounded-circle"
                        style={{
                          width: "48px",
                          height: "48px",
                          objectFit: "cover",
                        }}
                        onError={(e) => {
                          // Replace broken image with initial avatar fallback.
                          e.currentTarget.style.display = "none";
                          const fallback = e.currentTarget.nextElementSibling;
                          if (fallback) fallback.style.display = "flex";
                        }}
                      />
                    ) : null}
                    <div
                      className="rounded-circle align-items-center justify-content-center fw-bold text-white"
                      style={{
                        width: "48px",
                        height: "48px",
                        backgroundColor: "#6c757d",
                        fontSize: "18px",
                        display: review.user?.image ? "none" : "flex",
                      }}
                      aria-label={getReviewerName(review)}
                      title={getReviewerName(review)}
                    >
                      {getReviewerInitial(review)}
                    </div>
                    <div className="flex-grow-1">
                      <h6
                        className="mb-0 fw-semibold"
                        style={{ fontSize: "16px" }}
                      >
                        {getReviewerName(review)}
                      </h6>
                      <p
                        className="mb-0 text-muted"
                        style={{ fontSize: "14px" }}
                      >
                        {formatDate(review.createdAt)}
                      </p>
                    </div>
                  </div>

                  <div className="d-flex align-items-center gap-1 mb-3">
                    {Array.from({ length: 5 }).map((_, i) => (
                      <FaStar
                        key={i}
                        size={12}
                        color={
                          i < review.rating_quality ? "#ff9114" : "#e0e0e0"
                        }
                      />
                    ))}
                  </div>

                  <p
                    className="text-dark mb-2"
                    style={{ fontSize: "14px", lineHeight: "1.6" }}
                  >
                    {review.comment.length > 180
                      ? review.comment.slice(0, 180) + "..."
                      : review.comment}
                  </p>

                  {review.comment.length > 180 && (
                    <button
                      className="btn btn-link p-0 text-dark fw-semibold text-decoration-underline"
                      style={{ fontSize: "14px" }}
                      onClick={() => handleReadMoreClick(review)}
                    >
                      Show more
                    </button>
                  )}
                </div>
              </div>
            ))}
          </div>

          {reviews.length > 6 && (
            <div className="mb-4">
              <button
                className="btn btn-outline-dark rounded-3 px-4 py-2 fw-semibold"
                style={{ fontSize: "16px", border: "1px solid #222" }}
                onClick={() => setShowAllReviews(!showAllReviews)}
              >
                {showAllReviews
                  ? "Show less"
                  : `Show all ${reviews.length} reviews`}
              </button>
            </div>
          )}
        </>
      ) : (
        <div className=""></div>
      )}

      <Modal
        show={showDetailModal}
        onHide={() => setShowDetailModal(false)}
        centered
        size="lg"
      >
        <Modal.Header closeButton className="border-0 pb-0">
          <Modal.Title className="fw-bold" style={{ fontSize: "22px" }}>
            Review
          </Modal.Title>
        </Modal.Header>

        <Modal.Body className="px-4 py-4">
          {selectedReview && (
            <div>
              <div className="d-flex align-items-start gap-3 mb-4">
                {selectedReview.user?.image ? (
                  <img
                    src={selectedReview.user.image}
                    alt={getReviewerName(selectedReview)}
                    className="rounded-circle"
                    style={{ width: "56px", height: "56px", objectFit: "cover" }}
                    onError={(e) => {
                      e.currentTarget.style.display = "none";
                      const fallback = e.currentTarget.nextElementSibling;
                      if (fallback) fallback.style.display = "flex";
                    }}
                  />
                ) : null}
                <div
                  className="rounded-circle align-items-center justify-content-center fw-bold text-white"
                  style={{
                    width: "56px",
                    height: "56px",
                    backgroundColor: "#6c757d",
                    fontSize: "20px",
                    display: selectedReview.user?.image ? "none" : "flex",
                  }}
                  aria-label={getReviewerName(selectedReview)}
                  title={getReviewerName(selectedReview)}
                >
                  {getReviewerInitial(selectedReview)}
                </div>
                <div className="flex-grow-1">
                  <h6 className="mb-0 fw-bold" style={{ fontSize: "18px" }}>
                    {getReviewerName(selectedReview)}
                  </h6>
                  <p className="mb-0 text-muted" style={{ fontSize: "14px" }}>
                    {formatDate(selectedReview.createdAt)}
                  </p>
                </div>
              </div>

              <div className="d-flex align-items-center gap-1 mb-3">
                {Array.from({ length: 5 }).map((_, i) => (
                  <FaStar
                    key={i}
                    size={16}
                    color={
                      i < selectedReview.rating_quality ? "#222" : "#e0e0e0"
                    }
                  />
                ))}
                <span className="ms-2 fw-semibold" style={{ fontSize: "16px" }}>
                  {selectedReview.rating_quality.toFixed(1)}
                </span>
              </div>

              {selectedReview.title && (
                <div className="fw-bold mb-3 fs-18">
                  {selectedReview.title}
                </div>
              )}

              <p
                className="text-dark mb-4"
                style={{ fontSize: "16px", lineHeight: "1.7" }}
              >
                {selectedReview.comment}
              </p>

              <div className="border-top pt-4 mb-4">
                <div className="fw-semibold mb-3" style={{ fontSize: "16px" }}>
                  Rating breakdown
                </div>
                <div className="row g-3">
                  {[
                    { label: "Quality of service", key: "rating_quality" },
                    { label: "Responsiveness", key: "rating_responsiveness" },
                    { label: "Professionalism", key: "rating_professionalism" },
                    { label: "Value", key: "rating_value" },
                    { label: "Flexibility", key: "rating_flexibility" },
                  ].map((item) => (
                    <div className="col-6" key={item.key}>
                      <div className="d-flex justify-content-between align-items-center mb-2">
                        <span style={{ fontSize: "14px" }}>{item.label}</span>
                        <span
                          className="fw-semibold"
                          style={{ fontSize: "14px" }}
                        >
                          {selectedReview[item.key].toFixed(1)}
                        </span>
                      </div>
                      <div
                        className="position-relative"
                        style={{
                          height: "4px",
                          backgroundColor: "#e0e0e0",
                          borderRadius: "4px",
                        }}
                      >
                        <div
                          style={{
                            position: "absolute",
                            left: 0,
                            top: 0,
                            height: "100%",
                            width: `${(selectedReview[item.key] / 5) * 100}%`,
                            backgroundColor: "#222",
                            borderRadius: "4px",
                          }}
                        />
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {selectedReview.media && selectedReview.media.length > 0 && (
                <div className="mb-4">
                  <div className="fw-semibold mb-3" style={{ fontSize: "16px" }}>
                    Photos
                  </div>
                  <div className="d-flex flex-wrap gap-2">
                    {selectedReview.media.map((imgUrl, idx) => (
                      <img
                        key={idx}
                        src={imgUrl}
                        alt="review"
                        className="rounded"
                        style={{
                          width: "120px",
                          height: "120px",
                          objectFit: "cover",
                          cursor: "pointer",
                        }}
                      />
                    ))}
                  </div>
                </div>
              )}

              {selectedReview.vendor_reply && (
                <div
                  className="border rounded p-3 mt-4"
                  style={{ backgroundColor: "#f7f7f7" }}
                >
                  <div className="fw-semibold mb-2" style={{ fontSize: "16px" }}>
                    Response from {vendor?.name || "vendor"}
                  </div>
                  <p
                    className="mb-0"
                    style={{ fontSize: "14px", whiteSpace: "pre-line" }}
                  >
                    {selectedReview.vendor_reply}
                  </p>
                </div>
              )}
            </div>
          )}
        </Modal.Body>

        <Modal.Footer className="border-0 pt-0">
          <Button
            variant="light"
            className="rounded-3 px-4 py-2"
            style={{ fontSize: "14px" }}
            onClick={() => setShowDetailModal(false)}
          >
            Close
          </Button>
        </Modal.Footer>
      </Modal>
    </div>
  );
};

export default ReviewSection;
