import React, { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { einviteApi } from "../../services/api/einviteApi";
import { getImageUrl, handleImageError } from "../../utils/imageUtils";
import { FaHeart, FaMapMarkerAlt, FaComment } from "react-icons/fa";

const EinviteViewPage = () => {
  const { id } = useParams();
  const navigate = useNavigate();
  const [cardData, setCardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [rsvpStatus, setRsvpStatus] = useState("");
  const [guestName, setGuestName] = useState("");
  const [guestComment, setGuestComment] = useState("");
  const [showRsvpForm, setShowRsvpForm] = useState(false);

  // Font preloading effect for custom fonts
  useEffect(() => {
    if (cardData && cardData.editableFields) {
      const editableFields = Array.isArray(cardData.editableFields)
        ? cardData.editableFields
        : typeof cardData.editableFields === "string"
        ? JSON.parse(cardData.editableFields)
        : [];

      const uniqueFonts = [
        ...new Set(
          editableFields.map((field) => field.fontFamily).filter(Boolean)
        ),
      ];

      uniqueFonts.forEach((fontFamily) => {
        // Check if font is already loaded
        if (!document.querySelector(`link[href*="${fontFamily}"]`)) {
          const fontUrl = `https://fonts.googleapis.com/css2?family=${encodeURIComponent(
            fontFamily
          )}:wght@400;500;600;700&display=swap`;

          const fontLink = document.createElement("link");
          fontLink.rel = "stylesheet";
          fontLink.href = fontUrl;
          document.head.appendChild(fontLink);
        }
      });
    }
  }, [cardData]);

  useEffect(() => {
    const fetchEinvite = async () => {
      try {
        setLoading(true);
        setError(null);

        const response = await einviteApi.getPublicEinviteInstance(id);
 
        let data = null;
        if (response.success && response.data) {
          data = response.data;
        } else if (response.data) {
          data = response.data;
        } else if (response.success === true || response.success === false) {
          data = response;
        } else {
          data = response;
        }

        if (data && (data.id || data._id)) { 
          setCardData(data);
        } else { 
          setError("E-invite not found or invalid data format");
        }
      } catch (err) { 
        setError(`Failed to load e-invite: ${err.message}`);
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchEinvite();
    }
  }, [id]);

  const handleRsvpSubmit = (e) => {
    e.preventDefault();
    alert(`Thank you ${guestName}! Your RSVP has been recorded.`);
    setShowRsvpForm(false);
    setGuestName("");
    setGuestComment("");
    setRsvpStatus("");
  };

  if (loading) {
    return (
      <div className="container text-center py-5">
        <div className="spinner-border text-primary" role="status">
          <span className="visually-hidden">Loading...</span>
        </div>
        <p className="mt-3">Loading your invitation...</p>
      </div>
    );
  }

  if (error || !cardData) {
    return (
      <div className="container text-center py-5">
        <h3 className="text-danger mb-3">Oops!</h3>
        <p>{error || "E-invite not found"}</p>
        <div
          className="alert alert-info mt-3 text-start"
          style={{ maxWidth: "600px", margin: "0 auto" }}
        >
          <h6>Debug Information:</h6>
          <p className="mb-1">
            <strong>ID:</strong> {id}
          </p>
          <p className="mb-1">
            <strong>Error:</strong> {error}
          </p>
          <p className="mb-0 small">
            Check the browser console (F12) for more details.
          </p>
        </div>
        <button className="btn btn-primary mt-3" onClick={() => navigate("/")}>
          Go to Home
        </button>
      </div>
    );
  }

  const bgUrl = getImageUrl(cardData.backgroundUrl || cardData.background_url);
  const editableFields = Array.isArray(cardData.editableFields)
    ? cardData.editableFields
    : typeof cardData.editableFields === "string"
    ? JSON.parse(cardData.editableFields)
    : [];

  return (
    <div
      className="einvite-view-page"
      style={{
        backgroundColor: "#f8f9fa",
        minHeight: "100vh",
        paddingTop: "2rem",
        paddingBottom: "3rem",
      }}
    >
      <div className="container">
        <div className="row justify-content-center">
          <div className="col-12 col-sm-10 col-md-8 col-lg-6 col-xl-5">
            {/* E-Invite Card Display - Fixed size 414x659.288 */}
            <div
              className="card border-0 shadow-lg mb-4 mx-auto"
              style={{
                width: "414px",
                maxWidth: "100%",
              }}
            >
              <div
                className="position-relative"
                style={{
                  backgroundColor: "#ffffff",
                  width: "100%",
                  paddingBottom: "159.25%",
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    position: "absolute",
                    top: 0,
                    left: 0,
                    width: "100%",
                    height: "100%",
                  }}
                >
                  {bgUrl ? (
                    <img
                      src={bgUrl}
                      alt="E-Invite"
                      className="d-block"
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                      onError={(e) =>
                        handleImageError(
                          e,
                          cardData.backgroundUrl || cardData.background_url
                        )
                      }
                    />
                  ) : (
                    <div
                      className="text-center text-muted p-5"
                      style={{
                        height: "100%",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      No background image found
                    </div>
                  )}

                  {/* Text Fields Overlay */}
                  {editableFields.map((field) => (
                    <div
                      key={field.id}
                      style={{
                        position: "absolute",
                        left: field.x,
                        top: field.y,
                        color: field.color,
                        fontFamily: `"${field.fontFamily}", Arial, sans-serif`,
                        fontSize: `${field.fontSize}px`,
                        fontWeight: "normal",
                        whiteSpace: "nowrap",
                        userSelect: "none",
                        pointerEvents: "none",
                        textShadow: "1px 1px 2px rgba(0,0,0,0.3)",
                        zIndex: 5,
                      }}
                      className="einvite-text-field"
                    >
                      {field.defaultText}
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Card Info - Shows below the e-invite card */}
            <div className="card border-0 shadow-sm mb-4">
              <div className="card-body text-center p-4">
                <h4 className="mb-3 fw-bold">
                  {cardData.name || "Wedding Invitation"}
                </h4>
                <p className="text-muted mb-4">
                  You're invited to celebrate this special occasion with us!
                </p>

                {/* Action Buttons */}
                <div className="d-flex gap-2 justify-content-center flex-wrap">
                  <button
                    className="btn btn-primary d-flex align-items-center gap-2 px-3 py-2"
                    onClick={() => setShowRsvpForm(!showRsvpForm)}
                  >
                    <FaHeart /> <span>RSVP</span>
                  </button>
                  <button className="btn btn-outline-primary d-flex align-items-center gap-2 px-3 py-2">
                    <FaMapMarkerAlt /> <span>Location</span>
                  </button>
                  <button className="btn btn-outline-primary d-flex align-items-center gap-2 px-3 py-2">
                    <FaComment /> <span>Comment</span>
                  </button>
                </div>
              </div>
            </div>

            {/* RSVP Form */}
            {showRsvpForm && (
              <div className="card border-0 shadow-sm animate-fade-in">
                <div className="card-body p-4">
                  <h5 className="mb-4 fw-bold">RSVP to this Event</h5>
                  <form onSubmit={handleRsvpSubmit}>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">
                        Your Name
                      </label>
                      <input
                        type="text"
                        className="form-control"
                        placeholder="Enter your full name"
                        value={guestName}
                        onChange={(e) => setGuestName(e.target.value)}
                        required
                      />
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">
                        Will you attend?
                      </label>
                      <select
                        className="form-select"
                        value={rsvpStatus}
                        onChange={(e) => setRsvpStatus(e.target.value)}
                        required
                      >
                        <option value="">Select your response...</option>
                        <option value="yes">Yes, I'll be there!</option>
                        <option value="no">Sorry, can't make it</option>
                        <option value="maybe">Maybe</option>
                      </select>
                    </div>
                    <div className="mb-3">
                      <label className="form-label fw-semibold">
                        Message (Optional)
                      </label>
                      <textarea
                        className="form-control"
                        rows="3"
                        placeholder="Leave a message for the host..."
                        value={guestComment}
                        onChange={(e) => setGuestComment(e.target.value)}
                      ></textarea>
                    </div>
                    <div className="d-flex gap-2">
                      <button
                        type="submit"
                        className="btn btn-primary flex-grow-1"
                      >
                        Submit RSVP
                      </button>
                      <button
                        type="button"
                        className="btn btn-outline-secondary"
                        onClick={() => setShowRsvpForm(false)}
                      >
                        Cancel
                      </button>
                    </div>
                  </form>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>

      <style jsx>{`
        .einvite-text-field {
          font-display: swap !important;
          font-synthesis: none;
          text-rendering: optimizeLegibility;
          -webkit-font-smoothing: antialiased;
          -moz-osx-font-smoothing: grayscale;
        }

        /* Ensure fonts load properly */
        @font-face {
          font-family: "Aguafina Script";
          font-display: swap;
        }

        .animate-fade-in {
          animation: fadeIn 0.3s ease-in;
        }

        @keyframes fadeIn {
          from {
            opacity: 0;
            transform: translateY(-10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .btn {
          transition: all 0.3s ease;
        }

        .btn:hover {
          transform: translateY(-2px);
          box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
        }

        @media (max-width: 480px) {
          .btn span {
            display: none;
          }
          .btn {
            padding: 0.5rem 0.75rem !important;
          }
        }
      `}</style>
    </div>
  );
};

export default EinviteViewPage;
