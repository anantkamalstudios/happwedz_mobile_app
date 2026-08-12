import React, { useState } from "react";
import { useNavigate } from "react-router-dom";
import { getImageUrl, handleImageError } from "../../../utils/imageUtils";
import Swal from "sweetalert2";

const EinvitePreviewPublish = ({ card, onPublish, onSaveDraft }) => {
  const navigate = useNavigate();
  const [shareUrl] = useState(
    `${window.location.origin}/einvites/view/${card.id}`
  );

  const handleCopyLink = async () => {
    try {
      await navigator.clipboard.writeText(shareUrl);
      Swal.fire({
        text: "Link copied to clipboard!",
        timer: 1500,
        icon: "success",
      });
    } catch (err) {
      console.error("Failed to copy link:", err);
      // Fallback for older browsers
      const textArea = document.createElement("textarea");
      textArea.value = shareUrl;
      document.body.appendChild(textArea);
      textArea.select();
      document.execCommand("copy");
      document.body.removeChild(textArea);
      Swal.fire({
        text: "Link copied to clipboard!",
        timer: 1500,
        icon: "success",
      });
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

  const handleEdit = () => {
    navigate(`/einvites/editor/${card.id}`);
  };

  const handleViewSharePage = () => {
    navigate(`/einvites/share/${card.id}`);
  };

  return (
    <div className="einvite-preview-publish">
      <div className="container">
        <div className="row">
          <div className="col-lg-8">
            <div className="einvite-preview-container">
              <div className="einvite-preview-card position-relative">
                <img
                  src={getImageUrl(card.backgroundUrl || card.background_url)}
                  alt="Card Preview"
                  className="einvite-preview-image w-100 rounded shadow"
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
                    className="einvite-preview-field"
                    style={{
                      position: "absolute",
                      left: field.x,
                      top: field.y,
                      color: field.color,
                      fontFamily: field.fontFamily,
                      fontSize: field.fontSize,
                    }}
                  >
                    {field.defaultText}
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="col-lg-4">
            <div className="einvite-publish-info p-4 shadow rounded bg-white">
              <h4 className="mb-4">
                <i className="fas fa-share-alt me-2 text-primary"></i>
                Share Your Card
              </h4>

              <div className="mb-4">
                <label className="form-label fw-semibold">Share Link</label>
                <div className="input-group">
                  <input
                    type="text"
                    className="form-control"
                    value={shareUrl}
                    readOnly
                    style={{ fontSize: "12px" }}
                  />
                  <button
                    className="btn btn-outline-primary"
                    onClick={handleCopyLink}
                    title="Copy link"
                  >
                    <i className="fas fa-copy"></i>
                  </button>
                </div>
                <small className="text-muted">
                  Share this link with your guests
                </small>
              </div>

              <div className="einvite-publish-actions mb-4">
                <button
                  className="btn btn-success w-100 mb-2"
                  onClick={handleWhatsAppShare}
                >
                  <i className="fab fa-whatsapp me-2"></i>
                  Share on WhatsApp
                </button>
                <button
                  className="btn btn-primary w-100 mb-2"
                  onClick={handleEmailShare}
                >
                  <i className="fas fa-envelope me-2"></i>
                  Share via Email
                </button>
                <button
                  className="btn btn-outline-primary w-100 mb-2"
                  onClick={handleViewSharePage}
                >
                  <i className="fas fa-share-alt me-2"></i>
                  More Share Options
                </button>
              </div>

              <hr />

              <div className="mb-3">
                <h6 className="fw-semibold mb-3">Card Information</h6>
                <div className="mb-2">
                  <strong>Name:</strong> {card.name}
                </div>
                <div className="mb-2">
                  <strong>Type:</strong> {card.cardType}
                </div>
                <div className="mb-2">
                  <strong>Created:</strong>{" "}
                  {new Date(card.created_at).toLocaleDateString()}
                </div>
                <div className="mb-2">
                  <strong>Status:</strong>{" "}
                  <span
                    className={`badge ${
                      card.isActive ? "bg-success" : "bg-secondary"
                    }`}
                  >
                    {card.isActive ? "Published" : "Draft"}
                  </span>
                </div>
              </div>

              <div className="einvite-publish-actions">
                <button
                  className="btn btn-outline-primary w-100"
                  onClick={handleEdit}
                >
                  <i className="fas fa-edit me-2"></i>
                  Edit Card
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinvitePreviewPublish;
