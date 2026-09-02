import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { X, Link2, Copy, Check, Mail, MessageCircle } from "lucide-react";

const ShareModal = ({ isOpen, onClose, projectData }) => {
  const [emailInput, setEmailInput] = useState("");
  const [emails, setEmails] = useState([]);
  const [emailError, setEmailError] = useState("");
  const [copied, setCopied] = useState(false);
  const [isSending, setIsSending] = useState(false);
  const vendorPhone = useSelector((state) => state.vendorAuth.vendor?.phone);

  const {
    people = [],
    shareLink = "",
    generalAccess = {
      title: "Anyone with the link",
      description: "Anyone on the internet with the link can view",
      role: "Can view",
    },
    onInvite,
    onBulkComplete,
  } = projectData || {};

  // Reset emails when modal closes
  useEffect(() => {
    if (!isOpen) {
      setEmails([]);
      setEmailInput("");
      setEmailError("");
    }
  }, [isOpen]);

  const validateEmail = (email) => {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email.toLowerCase());
  };

  const handleAddEmail = (e) => {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      const email = emailInput.trim().replace(/,/g, "");

      if (!email) return;

      if (!validateEmail(email)) {
        setEmailError("Invalid email format");
        return;
      }

      if (emails.includes(email)) {
        setEmailError("Email already added");
        return;
      }

      setEmails([...emails, email]);
      setEmailInput("");
      setEmailError("");
    }
  };

  const handleRemoveEmail = (emailToRemove) => {
    setEmails(emails.filter((email) => email !== emailToRemove));
    setEmailError("");
  };

  const handleCopyLink = () => {
    navigator.clipboard.writeText(shareLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleWhatsAppShare = () => {
    if (!shareLink || !vendorPhone) return;
    const phone = String(vendorPhone).replace(/\D/g, "");
    const message = `Here is your access link: ${shareLink}`;
    const encoded = encodeURIComponent(message);
    const url = `https://wa.me/${phone}?text=${encoded}`;
    window.open(url, "_blank");
  };

  const handleInvite = async () => {
    if (emails.length === 0) {
      setEmailError("Please add at least one email address");
      return;
    }

    if (onInvite) {
      setIsSending(true);
      setEmailError("");
      try {
        // Send all emails - handle both success and partial failures
        const results = await Promise.allSettled(
          emails.map((email) => onInvite(email))
        );

        const failed = results.filter((r) => r.status === "rejected");
        const succeeded = results.filter((r) => r.status === "fulfilled");

        if (failed.length > 0) {
          setEmailError(
            `${failed.length} email(s) failed to send. ${succeeded.length} sent successfully.`
          );
        } else {
          // All emails sent successfully
          setEmails([]);
          setEmailInput("");
          if (onBulkComplete) {
            onBulkComplete();
          }
        }
      } catch (error) {
        setEmailError("Error sending invitations. Please try again.");
        console.error("Error sending invitations:", error);
      } finally {
        setIsSending(false);
      }
    }
  };

  const getAvatar = (person) => {
    if (person.avatar && person.avatar.trim() !== "") {
      return (
        <img src={person.avatar} alt={person.name} className="person-avatar" />
      );
    }

    // Show Gmail icon if no avatar
    return (
      <div className="person-avatar gmail-avatar">
        <Mail size={20} />
      </div>
    );
  };

  if (!isOpen) return null;

  return (
    <>
      <div className="modal-overlay" onClick={onClose} />
      <div className="share-modal">
        <div className="modal-header">
          <div>
            <h3 className="">Share this project</h3>
            <p className="modal-subtitle">
              Invite your team to review and collaborate on this project
            </p>
          </div>
          <button className="close-btn" onClick={onClose}>
            <X size={20} />
          </button>
        </div>

        <div className="modal-body">
          <div className="invite-section">
            <div className="email-input-wrapper">
              <div className="email-tags">
                {emails.map((email, index) => (
                  <span key={index} className="email-tag">
                    {email}
                    <button
                      className="email-tag-remove"
                      onClick={() => handleRemoveEmail(email)}
                      type="button"
                    >
                      <X size={14} />
                    </button>
                  </span>
                ))}
              </div>
              <input
                type="text"
                placeholder="Enter email and press Enter or comma"
                value={emailInput}
                onChange={(e) => {
                  setEmailInput(e.target.value);
                  setEmailError("");
                }}
                onKeyDown={handleAddEmail}
                className="email-input"
              />
            </div>
            {emailError && <div className="error-message">{emailError}</div>}
            <small className="form-hint">
              Press Enter or comma to add multiple emails
            </small>
            <button
              className="invite-btn"
              onClick={handleInvite}
              disabled={isSending || emails.length === 0}
            >
              {isSending ? "Sending..." : `Send Invitations (${emails.length})`}
            </button>
          </div>

          {people.length > 0 && (
            <div className="people-section">
              <h3 className="section-title">People with access</h3>
              <div className="people-list">
                {people.map((person) => (
                  <div key={person.id} className="person-item">
                    {getAvatar(person)}
                    <div className="person-info">
                      <div className="person-name">{person.name}</div>
                      <div className="person-email">{person.email}</div>
                    </div>
                    <span className="person-role">{person.role}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

          {generalAccess && (
            <div className="general-section">
              <h3 className="fs-20">General access</h3>
              <div className="link-access">
                <div className="link-icon-wrapper">
                  <Link2 size={20} />
                </div>
                <div className="link-info">
                  <div className="link-title">{generalAccess.title}</div>
                  <div className="link-description">
                    {generalAccess.description}
                  </div>
                </div>
                {/* <span className="access-role">{generalAccess.role}</span> */}
              </div>
            </div>
          )}

          {shareLink && (
            <div className="whatsapp-section">
              <button
                type="button"
                className="whatsapp-btn"
                onClick={handleWhatsAppShare}
              >
                <MessageCircle size={18} />
                <span className="whatsapp-text">Share via WhatsApp</span>
                {vendorPhone && (
                  <span className="whatsapp-phone">({vendorPhone})</span>
                )}
              </button>
            </div>
          )}

          {shareLink && (
            <div className="link-section">
              <div className="link-display">{shareLink}</div>
              <button className="copy-link-btn" onClick={handleCopyLink}>
                {copied ? <Check size={16} /> : <Copy size={16} />}
                {copied ? "Copied" : "Copy link"}
              </button>
            </div>
          )}
        </div>
      </div>

      <style jsx>{`
        .modal-overlay {
          position: fixed;
          inset: 0;
          background: rgba(0, 0, 0, 0.4);
          z-index: 999;
        }

        .share-modal {
          position: fixed;
          top: 50%;
          left: 50%;
          transform: translate(-50%, -50%);
          background: white;
          border-radius: 16px;
          width: 90%;
          max-width: 520px;
          max-height: 90vh;
          overflow-y: auto;
          z-index: 1000;
          box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1),
            0 10px 10px -5px rgba(0, 0, 0, 0.04);
        }

        .modal-header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding: 24px 24px 20px;
          border-bottom: 1px solid #e8ecef;
        }

        .modal-title {
          font-size: 20px;
          font-weight: 600;
          color: #1e293b;
          margin: 0 0 4px 0;
        }

        .modal-subtitle {
          font-size: 14px;
          color: #64748b;
          margin: 0;
        }

        .close-btn {
          background: none;
          border: none;
          color: #64748b;
          cursor: pointer;
          padding: 4px;
          display: flex;
          align-items: center;
          justify-content: center;
          border-radius: 6px;
          transition: all 0.2s;
        }

        .close-btn:hover {
          background: #f1f5f9;
          color: #334155;
        }

        .modal-body {
          padding: 24px;
        }

        .invite-section {
          margin-bottom: 32px;
        }

        .email-input-wrapper {
          display: flex;
          flex-wrap: wrap;
          gap: 8px;
          padding: 8px 12px;
          border: 1px solid #e2e8f0;
          border-radius: 8px;
          min-height: 48px;
          background: white;
          align-items: center;
        }

        .email-input-wrapper:focus-within {
          border-color: #cbd5e1;
          outline: 2px solid rgba(241, 45, 133, 0.1);
          outline-offset: -2px;
        }

        .email-tags {
          display: flex;
          flex-wrap: wrap;
          gap: 6px;
        }

        .email-tag {
          display: inline-flex;
          align-items: center;
          gap: 6px;
          padding: 4px 10px;
          background: #f1f5f9;
          border-radius: 16px;
          font-size: 14px;
          color: #1e293b;
        }

        .email-tag-remove {
          display: flex;
          align-items: center;
          justify-content: center;
          background: none;
          border: none;
          color: #64748b;
          cursor: pointer;
          padding: 2px;
          border-radius: 50%;
          transition: all 0.2s;
        }

        .email-tag-remove:hover {
          background: #e2e8f0;
          color: #1e293b;
        }

        .email-input {
          flex: 1;
          min-width: 200px;
          padding: 4px 0;
          border: none;
          outline: none;
          font-size: 15px;
          color: #1e293b;
          background: transparent;
        }

        .email-input::placeholder {
          color: #94a3b8;
        }

        .error-message {
          margin-top: 8px;
          font-size: 13px;
          color: #ef4444;
        }

        .form-hint {
          display: block;
          margin-top: 8px;
          font-size: 12px;
          color: #64748b;
        }

        .invite-btn {
          margin-top: 16px;
          padding: 10px 24px;
          width: 100%;
          background: #f12d85;
          color: white;
          border: none;
          border-radius: 8px;
          font-size: 15px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
        }

        .invite-btn:hover:not(:disabled) {
          background: #d91f6f;
        }

        .invite-btn:disabled {
          background: #fda4c0;
          cursor: not-allowed;
          opacity: 0.6;
        }

        .section-title {
          font-size: 14px;
          font-weight: 600;
          color: #1e293b;
          margin: 0 0 16px 0;
        }

        .people-section {
          margin-bottom: 32px;
        }

        .people-list {
          display: flex;
          flex-direction: column;
          gap: 12px;
        }

        .person-item {
          display: flex;
          align-items: center;
          gap: 12px;
        }

        .person-avatar {
          width: 40px;
          height: 40px;
          border-radius: 50%;
          object-fit: cover;
          flex-shrink: 0;
        }

        .gmail-avatar {
          background: linear-gradient(
            135deg,
            #ea4335 0%,
            #fbbc04 50%,
            #34a853 100%
          );
          display: flex;
          align-items: center;
          justify-content: center;
          color: white;
        }

        .person-info {
          flex: 1;
          min-width: 0;
        }

        .person-name {
          font-size: 15px;
          font-weight: 500;
          color: #1e293b;
          margin-bottom: 2px;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .person-email {
          font-size: 13px;
          color: #64748b;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }

        .person-role {
          font-size: 14px;
          color: #64748b;
          flex-shrink: 0;
        }

        .general-section {
          margin-bottom: 20px;
        }

        .link-access {
          display: flex;
          align-items: center;
          gap: 12px;
          padding: 12px 0;
        }

        .link-icon-wrapper {
          width: 40px;
          height: 40px;
          display: flex;
          align-items: center;
          justify-content: center;
          background: #f1f5f9;
          border-radius: 50%;
          color: #64748b;
          flex-shrink: 0;
        }

        .link-info {
          flex: 1;
          min-width: 0;
        }

        .link-title {
          font-size: 15px;
          font-weight: 500;
          color: #1e293b;
          margin-bottom: 2px;
        }

        .link-description {
          font-size: 13px;
          color: #64748b;
        }

        .access-role {
          font-size: 14px;
          color: #64748b;
          flex-shrink: 0;
        }

        .whatsapp-section {
          margin-bottom: 12px;
        }

        .whatsapp-btn {
          display: inline-flex;
          align-items: center;
          gap: 8px;
          padding: 10px 16px;
          background: #25d366;
          border-radius: 8px;
          border: none;
          color: #ffffff;
          font-size: 14px;
          font-weight: 500;
          cursor: pointer;
          transition: all 0.2s;
        }

        .whatsapp-btn:hover {
          background: #1ebe5d;
        }

        .whatsapp-text {
          white-space: nowrap;
        }

        .whatsapp-phone {
          font-size: 12px;
          opacity: 0.9;
        }

        .link-section {
          display: flex;
          gap: 12px;
          padding: 16px;
          background: #f8fafc;
          border-radius: 8px;
        }

        .link-display {
          flex: 1;
          font-size: 14px;
          color: #64748b;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
          line-height: 36px;
        }

        .copy-link-btn {
          display: flex;
          align-items: center;
          gap: 6px;
          padding: 8px 16px;
          background: white;
          border: 1px solid #e2e8f0;
          border-radius: 6px;
          font-size: 14px;
          font-weight: 500;
          color: #475569;
          cursor: pointer;
          transition: all 0.2s;
          white-space: nowrap;
        }

        .copy-link-btn:hover {
          background: #f8fafc;
          border-color: #cbd5e1;
        }

        @media (max-width: 640px) {
          .share-modal {
            width: 95%;
            max-width: none;
          }

          .modal-header {
            padding: 20px 20px 16px;
          }

          .modal-body {
            padding: 20px;
          }

          .email-input {
            min-width: 100%;
          }
        }
      `}</style>
    </>
  );
};

export default ShareModal;
