import React, { useState } from "react";

const ReplyForm = ({ reviewId, onReplySubmit }) => {
  const [replyText, setReplyText] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();
    if (replyText.trim()) {
      onReplySubmit(reviewId, replyText);
      setReplyText("");
    }
  };

  return (
    <form onSubmit={handleSubmit} className="reviews__reply-form">
      <textarea
        value={replyText}
        onChange={(e) => setReplyText(e.target.value)}
        placeholder="Write your reply..."
        className="form-control"
        rows="3"
      ></textarea>
      <button type="submit" className="btn btn-primary mt-2">
        Submit Reply
      </button>
    </form>
  );
};

const Reviews = ({
  reviews,
  onReplySubmit,
  averageRating,
  totalReviews,
  onDelete,
}) => {
  const [replyingTo, setReplyingTo] = useState(null);

  const renderStars = (rating) =>
    Array.from({ length: 5 }, (_, i) => (
      <span key={i}>{i < rating ? "⭐" : "☆"}</span>
    ));

  const distribution = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
  reviews.forEach((review) => {
    const rounded = Math.round(review.rating);
    if (distribution[rounded] !== undefined) distribution[rounded]++;
  });

  return (
    <div className="reviews">
      <div className="reviews__header mb-4">
        <h3>Customer Reviews ({totalReviews})</h3>
        <div className="reviews__average mb-3">
          <span className="reviews__average-score">{averageRating}</span>
          <div className="reviews__average-stars">
            {renderStars(Math.round(averageRating))}
          </div>
          <span className="reviews__average-text">Average Rating</span>
        </div>
      </div>

      <div className="reviews__list">
        {reviews.length > 0 ? (
          reviews.map((review) => (
            <div
              key={review.id}
              className="p-3 mb-3 border rounded-3 bg-white"
              style={{ fontSize: "0.85rem", lineHeight: "1.4" }}
            >
              <div className="d-flex justify-content-between align-items-center">
                <div>
                  <strong>{review.name}</strong>{" "}
                  {review.verified && (
                    <span className="text-success">✓ Verified</span>
                  )}
                  <div className="text-muted">{review.date}</div>
                </div>
                <div>{renderStars(Math.round(review.rating))}</div>
              </div>
              {review.review && <p className="mt-2">{review.review}</p>}

              {review.reply ? (
                <blockquote className="border-left ps-3 mt-2">
                  <strong>Your Reply:</strong>
                  <p>{review.reply}</p>
                </blockquote>
              ) : replyingTo === review.id ? (
                <ReplyForm
                  reviewId={review.id}
                  onReplySubmit={(id, text) => {
                    onReplySubmit(id, text);
                    setReplyingTo(null);
                  }}
                />
              ) : (
                <>
                  <button
                    className="btn btn-sm btn-outline-primary mt-2"
                    onClick={() => setReplyingTo(review.id)}
                  >
                    Reply
                  </button>
                  <button
                    className="btn btn-sm btn-outline-danger mt-2 ms-2"
                    onClick={() => onDelete(review.id)}
                  >
                    Delete
                  </button>
                </>
              )}
            </div>
          ))
        ) : (
          <p>No reviews available.</p>
        )}
      </div>
    </div>
  );
};

export default Reviews;
