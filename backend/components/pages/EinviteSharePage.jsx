import React, { useState, useEffect } from "react";
import { useParams, Link } from "react-router-dom";
import { einviteApi } from "../../services/api/einviteApi";
import { getImageUrl, handleImageError } from "../../utils/imageUtils";
import Swal from "sweetalert2";
import {
  FaWhatsapp,
  FaEnvelope,
  FaLink,
  FaDownload,
  FaShareAlt,
  FaEdit,
  FaArrowLeft,
  FaCalendarAlt,
  FaHeart,
  FaCheckCircle,
} from "react-icons/fa";

const EinviteSharePage = () => {
  const { id } = useParams();
  const [card, setCard] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [shareUrl, setShareUrl] = useState("");
  const [copied, setCopied] = useState(false);

  useEffect(() => {
    if (id) {
      fetchCard();
      setShareUrl(`${window.location.origin}/einvites/view/${id}`);
    }
  }, [id]);

  const fetchCard = async () => {
    try {
      setLoading(true);
      const data = await einviteApi.getEinviteById(id);
      setCard(data.data);
    } catch (err) {
      setError("Failed to load card");
      console.error("Error fetching card:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleWhatsAppShare = () => {
    const message = `Check out this beautiful wedding invitation: ${shareUrl}`;
    const whatsappUrl = `https://wa.me/?text=${encodeURIComponent(message)}`;
    window.open(whatsappUrl, "_blank");
  };

  const handleEmailShare = () => {
    const subject = "Wedding Invitation";
    const body = `You're invited to our wedding! View the invitation here: ${shareUrl}`;
    const mailtoUrl = `mailto:?subject=${encodeURIComponent(
      subject
    )}&body=${encodeURIComponent(body)}`;
    window.location.href = mailtoUrl;
  };

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      setCopied(true);
      Swal.fire({
        text: "Link copied to clipboard!",
        timer: 1500,
        icon: "success",
        showConfirmButton: false,
      });
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy link:", err);
      Swal.fire({
        text: "Failed to copy link",
        icon: "error",
      });
    }
  };

  const handleDownload = () => {
    Swal.fire({
      text: "Download functionality coming soon!",
      timer: 1500,
      icon: "info",
      showConfirmButton: false,
    });
  };

  if (loading) {
    return (
      <div
        className="min-vh-100 d-flex align-items-center justify-content-center"
        style={{
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
        }}
      >
        <div className="text-center text-white">
          <div
            className="spinner-border mb-3"
            role="status"
            style={{ width: "3rem", height: "3rem" }}
          >
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="fs-5 fw-light">Loading your invitation...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-vh-100 d-flex align-items-center justify-content-center bg-light">
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-md-6 text-center">
              <div className="card border-0 shadow-lg rounded-4 p-5">
                <div className="text-danger mb-4">
                  <FaHeart size={64} />
                </div>
                <h3 className="mb-3">Oops! Something went wrong</h3>
                <p className="text-muted mb-4">{error}</p>
                <Link
                  className="btn btn-primary btn-lg rounded-pill px-5"
                  to="/einvites"
                >
                  <FaArrowLeft className="me-2" /> Back to Browse
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  if (!card) {
    return (
      <div className="min-vh-100 d-flex align-items-center justify-content-center bg-light">
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-md-6 text-center">
              <div className="card border-0 shadow-lg rounded-4 p-5">
                <div className="text-muted mb-4">
                  <FaCalendarAlt size={64} />
                </div>
                <h3 className="mb-3">Invitation Not Found</h3>
                <p className="text-muted mb-4">
                  The requested invitation could not be found.
                </p>
                <Link
                  className="btn btn-primary btn-lg rounded-pill px-5"
                  to="/einvites"
                >
                  <FaArrowLeft className="me-2" /> Back to Browse
                </Link>
              </div>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      style={{
        minHeight: "100vh",
      }}
    >
      {/* Hero Section */}
      <div className="py-4 py-md-5">
        <div className="container">
          <Link
            to="/einvites"
            className="btn btn-light rounded-pill px-4 mb-4 shadow-sm"
            style={{
              backdropFilter: "blur(10px)",
              backgroundColor: "rgba(255, 255, 255, 1)",
            }}
          >
            <FaArrowLeft className="me-2" /> Back
          </Link>
        </div>
      </div>

      {/* Main Content */}
      <div className="container pb-5">
        <div className="row g-4 align-items-start justify-content-center">
          {/* Left - Card Preview */}
          <div className="col-lg-6 col-xl-5 d-flex justify-content-center">
            <div className="position-relative">
              {/* Decorative elements */}
              <div
                className="position-absolute rounded-4"
                style={{
                  top: "-15px",
                  left: "-15px",
                  width: "413px",
                  height: "659px",
                  background: "rgba(255, 255, 255, 0.1)",
                  backdropFilter: "blur(10px)",
                  zIndex: 0,
                }}
              />

              <div
                className="position-relative shadow-lg rounded-4 overflow-hidden"
                style={{
                  width: "413px",
                  height: "659px",
                  backgroundColor: "#fff",
                  zIndex: 1,
                }}
              >
                <img
                  src={getImageUrl(card.backgroundUrl || card.background_url)}
                  alt="Invitation Preview"
                  className="w-100 h-100 object-fit-cover"
                  onError={(e) =>
                    handleImageError(
                      e,
                      card.backgroundUrl || card.background_url
                    )
                  }
                />
                {card.editableFields?.map((field) => (
                  <div
                    key={field.id}
                    style={{
                      position: "absolute",
                      left: `${field.x}px`,
                      top: `${field.y}px`,
                      color: field.color,
                      fontFamily: field.fontFamily,
                      fontSize: `${field.fontSize}px`,
                      whiteSpace: "nowrap",
                      pointerEvents: "none",
                    }}
                  >
                    {field.defaultText}
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Right - Share Panel */}
          <div className="col-lg-6 col-xl-5">
            <div
              className="card border-0 shadow-lg rounded-4 overflow-hidden"
              style={{ backdropFilter: "blur(10px)" }}
            >
              {/* Header Section */}
              <div className="p-4 pb-0">
                <div className="d-flex align-items-center mb-4">
                  <div
                    className="rounded-circle d-flex align-items-center justify-content-center me-3"
                    style={{
                      width: "56px",
                      height: "56px",
                      background: "#ed1173",
                    }}
                  >
                    <FaShareAlt className="text-white" size={24} />
                  </div>
                  <div>
                    <h3 className="mb-1 fw-bold">Share Your Invitation</h3>
                    <p className="text-muted mb-0 small">
                      Spread the joy with friends & family
                    </p>
                  </div>
                </div>
              </div>

              {/* Share Options */}
              <div className="px-4 pb-4">
                <div className="row g-3 mb-4">
                  <div className="col-sm-6">
                    <button
                      className="btn btn-success w-100 py-3 rounded-3 shadow-sm d-flex align-items-center justify-content-center"
                      onClick={handleWhatsAppShare}
                      style={{ transition: "all 0.3s" }}
                    >
                      <FaWhatsapp className="me-2" size={20} />
                      <span className="fw-semibold">WhatsApp</span>
                    </button>
                  </div>

                  <div className="col-sm-6">
                    <button
                      className="btn btn-primary w-100 py-3 rounded-3 shadow-sm d-flex align-items-center justify-content-center"
                      onClick={handleEmailShare}
                      style={{
                        background: "#ed1173",
                        border: "none",
                        transition: "all 0.3s",
                      }}
                    >
                      <FaEnvelope className="me-2" size={18} />
                      <span className="fw-semibold">Email</span>
                    </button>
                  </div>

                  <div className="col-12">
                    <button
                      className="btn btn-outline-secondary w-100 py-3 rounded-3 d-flex align-items-center justify-content-center position-relative"
                      onClick={handleCopyLink}
                      style={{ transition: "all 0.3s" }}
                    >
                      {copied ? (
                        <>
                          <FaCheckCircle
                            className="me-2 text-success"
                            size={18}
                          />
                          <span className="fw-semibold">Copied!</span>
                        </>
                      ) : (
                        <>
                          <FaLink className="me-2" size={18} />
                          <span className="fw-semibold">Copy Link</span>
                        </>
                      )}
                    </button>
                  </div>

                  <div className="col-12">
                    <button
                      className="btn btn-light w-100 py-3 rounded-3 shadow-sm d-flex align-items-center justify-content-center"
                      onClick={handleDownload}
                      style={{ transition: "all 0.3s" }}
                    >
                      <FaDownload className="me-2" size={18} />
                      <span className="fw-semibold">Download</span>
                    </button>
                  </div>
                </div>

                {/* Card Information */}
                <div className="bg-light rounded-3 p-4 mb-3">
                  <h6 className="fw-bold mb-3 d-flex align-items-center">
                    <FaCalendarAlt className="me-2 text-primary" />
                    Invitation Details
                  </h6>
                  <div className="small">
                    <div className="d-flex justify-content-between py-2 border-bottom">
                      <span className="text-muted">Name</span>
                      <span className="fw-semibold">{card.name}</span>
                    </div>
                    <div className="d-flex justify-content-between py-2 border-bottom">
                      <span className="text-muted">Type</span>
                      <span className="fw-semibold">{card.cardType}</span>
                    </div>
                    <div className="d-flex justify-content-between py-2">
                      <span className="text-muted">Created</span>
                      <span className="fw-semibold">
                        {new Date(card.created_at).toLocaleDateString("en-US", {
                          month: "short",
                          day: "numeric",
                          year: "numeric",
                        })}
                      </span>
                    </div>
                  </div>
                </div>

                {/* Edit Button */}
                <Link
                  className="btn btn-outline-primary w-100 py-3 rounded-3 fw-semibold"
                  to={`/einvites/editor/${card.id}`}
                  style={{ transition: "all 0.3s" }}
                >
                  <FaEdit className="me-2" />
                  Edit Invitation
                </Link>
              </div>
            </div>

            {/* Pro Tip Card */}
            <div
              className="card border-0 shadow-sm rounded-4 mt-4"
              style={{
                background: "rgba(255, 255, 255, 0.95)",
                backdropFilter: "blur(10px)",
              }}
            >
              <div className="card-body p-4">
                <div className="d-flex">
                  <div className="me-3">
                    <div
                      className="rounded-circle d-flex align-items-center justify-content-center"
                      style={{
                        width: "40px",
                        height: "40px",
                        backgroundColor: "#fff3cd",
                      }}
                    >
                      💡
                    </div>
                  </div>
                  <div>
                    <h6 className="fw-bold mb-2">Pro Tip</h6>
                    <p className="text-muted small mb-0">
                      Share via WhatsApp for the best experience. Your guests
                      can RSVP directly!
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <style jsx>{`
        .btn:hover {
          transform: translateY(-2px);
          box-shadow: 0 8px 16px rgba(0, 0, 0, 0.1) !important;
        }

        .btn:active {
          transform: translateY(0);
        }

        .card {
          transition: all 0.3s ease;
        }

        @media (max-width: 991.98px) {
          .display-5 {
            font-size: 2rem;
          }
        }

        @media (max-width: 575.98px) {
          .display-5 {
            font-size: 1.75rem;
          }

          .lead {
            font-size: 1rem;
          }
        }
      `}</style>
    </div>
  );
};

export default EinviteSharePage;
