import React, { useState } from "react";
import { getImageUrl, handleImageError } from "../../../utils/imageUtils";

const EinviteShareModal = ({ show, onHide, card, onPublish }) => {
  const [shareMethod, setShareMethod] = useState("whatsapp");
  const [personalMessage, setPersonalMessage] = useState("");


  const handlePublish = () => {
    onPublish({
      shareMethod,
      personalMessage,
      card,
    });
    onHide();
  };

  const shareOptions = [
    { value: "whatsapp", label: "WhatsApp", icon: "fab fa-whatsapp" },
    { value: "email", label: "Email", icon: "fas fa-envelope" },
    { value: "sms", label: "SMS", icon: "fas fa-sms" },
    { value: "link", label: "Copy Link", icon: "fas fa-link" },
  ];

  return (
    <div
      className={`modal fade ${show ? "show" : ""}`}
      style={{ display: show ? "block" : "none" }}
    >
      <div className="modal-dialog modal-lg">
        <div className="modal-content">
          <div className="modal-header">
            <h5 className="modal-title">
              <i className="fas fa-share me-2"></i>
              Share Your E-Invitation
            </h5>
            <button
              type="button"
              className="btn-close"
              onClick={onHide}
            ></button>
          </div>

          <div className="modal-body">
            <div className="row">
              <div className="col-md-6">
                <div className="einvite-share-preview">
                  <img
                    src={getImageUrl(card?.thumbnailUrl || card?.thumbnail_url)}
                    alt="Card Preview"
                    className="img-fluid rounded"
                    onError={(e) =>
                      handleImageError(
                        e,
                        card?.thumbnailUrl || card?.thumbnail_url
                      )
                    }
                  />
                  <h6 className="mt-2">{card?.name}</h6>
                </div>
              </div>

              <div className="col-md-6">
                <div className="einvite-share-options">
                  <h6>Choose Sharing Method</h6>
                  <div className="einvite-share-methods">
                    {shareOptions.map((option) => (
                      <div key={option.value} className="form-check">
                        <input
                          className="form-check-input"
                          type="radio"
                          name="shareMethod"
                          id={option.value}
                          value={option.value}
                          checked={shareMethod === option.value}
                          onChange={(e) => setShareMethod(e.target.value)}
                        />
                        <label
                          className="form-check-label"
                          htmlFor={option.value}
                        >
                          <i className={`${option.icon} me-2`}></i>
                          {option.label}
                        </label>
                      </div>
                    ))}
                  </div>

                  <div className="mt-3">
                    <label className="form-label">
                      Personal Message (Optional)
                    </label>
                    <textarea
                      className="form-control"
                      rows="3"
                      placeholder="Add a personal message to your invitation..."
                      value={personalMessage}
                      onChange={(e) => setPersonalMessage(e.target.value)}
                    ></textarea>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <div className="modal-footer">
            <button
              type="button"
              className="btn btn-secondary"
              onClick={onHide}
            >
              Cancel
            </button>
            <button
              type="button"
              className="btn btn-primary"
              onClick={handlePublish}
            >
              <i className="fas fa-share me-2"></i>
              Publish & Share
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default EinviteShareModal;
