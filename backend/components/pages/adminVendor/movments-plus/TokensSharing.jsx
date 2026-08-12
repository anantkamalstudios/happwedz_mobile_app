import React, { useState, useEffect } from "react";
import {
  FiKey,
  FiMail,
  FiCopy,
  FiEye,
  FiEyeOff,
  FiShare2,
  FiPlus,
  FiTrash2,
  FiCheckCircle,
  FiAlertCircle,
  FiX,
  FiCalendar,
  FiUsers,
  FiActivity,
  FiRefreshCw,
} from "react-icons/fi";
import axiosInstance from "../../../../services/api/axiosInstance";
import "./tokens-sharing.css";
import { CiVideoOff } from "react-icons/ci";
import ShareModal from "./ShareModal";
import { SiJsonwebtokens } from "react-icons/si";
import { ClockLoader } from "react-spinners";
import { useSelector } from "react-redux";

const TokensSharing = () => {
  const [tokens, setTokens] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showShareModal, setShowShareModal] = useState(false);
  const [showGenerateModal, setShowGenerateModal] = useState(false);
  const [selectedToken, setSelectedToken] = useState(null);
  const [shareLoading, setShareLoading] = useState(false);
  const [generateLoading, setGenerateLoading] = useState(false);
  const [tokenType, setTokenType] = useState("private");
  const [copySuccess, setCopySuccess] = useState("");
  const [vendorId, setVendorId] = useState(null);
  const storedVendorId = useSelector((state) => state.vendorAuth.vendor.id);
  console.log("storedVendorId -> ", storedVendorId);
  useEffect(() => {
    setVendorId(storedVendorId);
    fetchTokens(storedVendorId);
  }, []);

  const fetchTokens = async (vId) => {
    try {
      setLoading(true);
      const response = await axiosInstance.get(`/token/vendor/${vId}`);

      if (response.data.success) {
        setTokens(response.data.tokens);
      } else {
        setError("Failed to load tokens");
      }
    } catch (err) {
      setError(err.response?.data?.message || "Failed to fetch tokens");
      console.error("Tokens error:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleGenerateToken = async () => {
    try {
      setGenerateLoading(true);
      const response = await axiosInstance.post("/token/generate", {
        vendorId: vendorId,
        type: tokenType,
      });
      if (response.data.success) {
        setShowGenerateModal(false);
        setTokenType("private");
        fetchTokens(vendorId);
        showNotification("Token generated successfully!", "success");
      }
    } catch (err) {
      showNotification(
        err.response?.data?.message || "Failed to generate token",
        "error"
      );
    } finally {
      setGenerateLoading(false);
    }
  };

  const handleDisableToken = async (tokenId) => {
    if (!window.confirm("Are you sure you want to disable this token?")) return;

    try {
      const response = await axiosInstance.put(`/token/${tokenId}/disable`);

      if (response.data.success) {
        fetchTokens(vendorId);
        showNotification("Token disabled successfully", "success");
      }
    } catch (err) {
      showNotification(
        err.response?.data?.message || "Failed to disable token",
        "error"
      );
    }
  };

  const handleShareViaEmail = async (email) => {
    if (!email || !selectedToken) {
      return Promise.reject(new Error("Invalid email or token"));
    }

    try {
      const response = await axiosInstance.post("/token/share-email", {
        token: selectedToken.token,
        emails: [email],
      });

      if (response.data.success) {
        return Promise.resolve();
      } else {
        return Promise.reject(new Error("Failed to send invitation"));
      }
    } catch (err) {
      return Promise.reject(err);
    }
  };

  const handleBulkShareComplete = () => {
    setShowShareModal(false);
    setSelectedToken(null);
    fetchTokens(vendorId);
    showNotification("Gallery invitations sent successfully!", "success");
  };

  const handleCopyToken = (token) => {
    const galleryUrl = `${window.location.origin}/gallery/${token}`;
    navigator.clipboard.writeText(galleryUrl);
    setCopySuccess(token);
    setTimeout(() => setCopySuccess(""), 2000);
    showNotification("Gallery link copied to clipboard!", "success");
  };

  const showNotification = (message, type) => {
    // You can integrate with toast library here
    alert(message);
  };

  const openShareModal = (token) => {
    setSelectedToken(token);
    setShowShareModal(true);
  };

  const formatDate = (dateString) => {
    if (!dateString) return "No expiry";
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  const formatDateTime = (dateString) => {
    if (!dateString) return "Never";
    const date = new Date(dateString);
    return date.toLocaleString("en-US", {
      month: "short",
      day: "numeric",
      hour: "2-digit",
      minute: "2-digit",
    });
  };

  if (loading) {
    return (
      <div className="tokens-container">
        <div className="loading-state">
          <div className="spinner"></div>
          <p className="mt-3">Loading tokens...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="tokens-container">
        <div className="error-state">
          <FiAlertCircle size={48} />
          <h4 className="mt-3">Unable to Load Tokens</h4>
          <p>{error}</p>
          <button
            className="btn-primary mt-3"
            onClick={() => fetchTokens(vendorId)}
          >
            <FiRefreshCw className="me-2" />
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="tokens-container">
      {/* Header */}
      <div className="tokens-header">
        <div>
          <h3 className="page-title inter">Tokens & Sharing</h3>
          <p className="page-subtitle inter fs-14">
            Manage gallery access tokens and share with clients
          </p>
        </div>
        <button
          className="btn-outline-primary d-flex align-items-center justify-content-center inter"
          onClick={() => setShowGenerateModal(true)}
          style={{ gap: "0.5rem" }}
        >
          <FiPlus size={18} />
          <span className="inter">Generate New Token</span>
        </button>
      </div>

      {/* Stats Cards */}
      <div className="stats-row">
        <div className="stat-box">
          <div className="stat-icon-wrapper">
            <FiKey size={20} />
          </div>
          <div>
            <p className="stat-box-label">Total Tokens</p>
            <h3 className="stat-box-value">{tokens.length}</h3>
          </div>
        </div>
        <div className="stat-box">
          <div className="stat-icon-wrapper">
            <FiCheckCircle size={20} />
          </div>
          <div>
            <p className="stat-box-label">Active Tokens</p>
            <h3 className="stat-box-value">
              {tokens.filter((t) => t.status === "active").length}
            </h3>
          </div>
        </div>
        <div className="stat-box">
          <div className="stat-icon-wrapper">
            <FiEye size={20} />
          </div>
          <div>
            <p className="stat-box-label">Total Views</p>
            <h3 className="stat-box-value">
              {tokens.reduce((sum, t) => sum + (t.view_count || 0), 0)}
            </h3>
          </div>
        </div>
        <div className="stat-box">
          <div className="stat-icon-wrapper">
            <FiMail size={20} />
          </div>
          <div>
            <p className="stat-box-label">Emails Sent</p>
            <h3 className="stat-box-value">
              {tokens.reduce((sum, t) => sum + (t.email_sent_count || 0), 0)}
            </h3>
          </div>
        </div>
      </div>

      {/* Tokens Table */}
      {tokens.length === 0 ? (
        <div className="empty-state-card">
          <FiKey size={64} />
          <h3>No Tokens Yet</h3>
          <p>
            Generate your first access token to start sharing galleries with
            clients
          </p>
          <button
            className="btn-primary mt-3"
            onClick={() => setShowGenerateModal(true)}
          >
            <FiPlus size={18} />
            Generate Token
          </button>
        </div>
      ) : (
        <div className="table-card">
          <div className="table-responsive">
            <table className="tokens-table">
              <thead>
                <tr>
                  <th>Token Code</th>
                  <th>Type</th>
                  <th>Event ID</th>
                  <th>Status</th>
                  <th>Views</th>
                  <th>Emails Sent</th>
                  <th>Expires</th>
                  <th>Created</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {tokens.map((token) => (
                  <tr key={token.id} className="token-row">
                    <td>
                      <div className="token-code-cell">
                        <FiKey className="me-2" />
                        <code className="token-code inter">{token.token}</code>
                      </div>
                    </td>
                    <td>
                      <span className={`inter badge badge-${token.type}`}>
                        {token.type}
                      </span>
                    </td>
                    <td>
                      <div className="event-cell inter">
                        <FiCalendar size={14} className="me-1" />
                        Event #{token.event_id}
                      </div>
                    </td>
                    <td>
                      <span
                        className={`inter status-badge status-${token.status}`}
                      >
                        {token.status === "active" ? (
                          <FiCheckCircle size={14} />
                        ) : (
                          <FiEyeOff size={14} />
                        )}
                        <span className="inter">{token.status}</span>
                      </span>
                    </td>
                    <td>
                      <div className="views-cell inter">
                        <FiEye size={14} className="me-1" />
                        <span className="inter">{token.view_count || 0}</span>
                        <small className="text-muted ms-1 inter">
                          ({token.unique_views || 0} unique)
                        </small>
                      </div>
                    </td>
                    <td>
                      <div className="emails-cell inter">
                        <FiMail size={14} className="me-1" />
                        <span className="inter">
                          {token.email_sent_count || 0}
                        </span>
                        {token.last_shared_at && (
                          <small className="text-muted d-block inter">
                            {formatDateTime(token.last_shared_at)}
                          </small>
                        )}
                      </div>
                    </td>
                    <td>
                      <div className="expiry-cell inter">
                        <span className="inter">
                          {formatDate(token.expires_at)}
                        </span>
                      </div>
                    </td>
                    <td>
                      <div className="created-cell inter">
                        <span className="inter">
                          {formatDateTime(token.created_at)}
                        </span>
                      </div>
                    </td>
                    <td>
                      <div className="action-buttons">
                        <button
                          className="action-btn"
                          onClick={() => handleCopyToken(token.token)}
                          title="Copy Link"
                        >
                          {copySuccess === token.token ? (
                            <FiCheckCircle size={26} className="text-success" />
                          ) : (
                            <FiCopy size={26} />
                          )}
                        </button>
                        <button
                          className="action-btn"
                          onClick={() => openShareModal(token)}
                          title="Share via Email"
                          disabled={token.status !== "active"}
                        >
                          <FiShare2 size={26} />
                        </button>
                        <button
                          className="action-btn danger"
                          onClick={() => handleDisableToken(token.id)}
                          title="Disable Token"
                          disabled={token.status !== "active"}
                        >
                          <CiVideoOff size={26} />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile View */}
          <div className="mobile-tokens">
            {tokens.map((token) => (
              <div key={token.id} className="mobile-token-card">
                <div className="mobile-token-header">
                  <div className="token-code-cell">
                    <FiKey className="me-2" />
                    <code className="token-code inter">{token.token}</code>
                  </div>
                  <span className={`inter status-badge status-${token.status}`}>
                    {token.status === "active" ? (
                      <FiCheckCircle size={14} />
                    ) : (
                      <FiEyeOff size={14} />
                    )}
                    <span className="inter">{token.status}</span>
                  </span>
                </div>

                <div className="mobile-token-body">
                  <div className="mobile-info-row">
                    <span className="mobile-label inter">Type:</span>
                    <span className={`inter badge badge-${token.type}`}>
                      {token.type}
                    </span>
                  </div>
                  <div className="mobile-info-row">
                    <span className="mobile-label inter">Event:</span>
                    <span className="inter">Event #{token.event_id}</span>
                  </div>
                  <div className="mobile-info-row">
                    <span className="mobile-label inter">Views:</span>
                    <span className="inter">
                      {token.view_count || 0} ({token.unique_views || 0} unique)
                    </span>
                  </div>
                  <div className="mobile-info-row">
                    <span className="mobile-label inter">Emails Sent:</span>
                    <span className="inter">{token.email_sent_count || 0}</span>
                  </div>
                  <div className="mobile-info-row">
                    <span className="mobile-label inter">Expires:</span>
                    <span className="inter">
                      {formatDate(token.expires_at)}
                    </span>
                  </div>
                </div>

                <div className="mobile-token-actions">
                  <button
                    className="action-btn-mobile inter"
                    onClick={() => handleCopyToken(token.token)}
                  >
                    <FiCopy size={16} />
                    Copy
                  </button>
                  <button
                    className="action-btn-mobile inter danger"
                    onClick={() => openShareModal(token)}
                    disabled={token.status !== "active"}
                  >
                    <FiShare2 size={16} />
                    Share
                  </button>
                  <button
                    className="action-btn-mobile inter danger"
                    onClick={() => handleDisableToken(token.id)}
                    disabled={token.status !== "active"}
                  >
                    <FiEyeOff size={16} />
                    Disable
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Share Modal */}
      <ShareModal
        isOpen={showShareModal}
        onClose={() => {
          setShowShareModal(false);
          setSelectedToken(null);
        }}
        projectData={{
          shareLink: selectedToken
            ? `${window.location.origin}/gallery/${selectedToken.token}`
            : "",
          generalAccess: {
            title: "Anyone with the link",
            description: "Anyone on the internet with the link can view",
            role: "Can view",
          },
          people: [],
          onInvite: handleShareViaEmail,
          onBulkComplete: handleBulkShareComplete,
        }}
      />

      {/* Generate Token Modal */}
      {showGenerateModal && (
        <div
          className="modal-overlay"
          onClick={() => setShowGenerateModal(false)}
        >
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h4 className="modal-title fs-20 inter">
                <FiKey className="me-2" />
                Generate New Token
              </h4>
              <button
                className="modal-close"
                onClick={() => setShowGenerateModal(false)}
              >
                <FiX size={20} />
              </button>
            </div>

            <div className="modal-body">
              <div className="form-group">
                <label className="form-label inter">Select Token Type</label>
                <div className="token-type-grid">
                  <div
                    className={`token-type-card inter ${
                      tokenType === "private" ? "selected" : ""
                    }`}
                    onClick={() => setTokenType("private")}
                  >
                    <div className="token-type-icon private inter">
                      <FiEyeOff size={28} />
                    </div>
                    <h4 className="token-type-title fs-16 inter">
                      Private Gallery
                    </h4>
                    <p className="token-type-description fs-14">
                      Only accessible with token link. Perfect for
                      client-exclusive galleries.
                    </p>
                    <div className="token-type-features fs-14">
                      <div className="feature-item inter">
                        <FiCheckCircle size={14} />
                        <span className="inter">Secure access</span>
                      </div>
                      <div className="feature-item inter">
                        <FiCheckCircle size={14} />
                        <span className="inter">Email sharing</span>
                      </div>
                      <div className="feature-item inter">
                        <FiCheckCircle size={14} />
                        <span className="inter">View tracking</span>
                      </div>
                    </div>
                    {tokenType === "private" && (
                      <div className="selected-badge inter">
                        <FiCheckCircle size={16} />
                        Selected
                      </div>
                    )}
                  </div>

                  <div
                    className={`token-type-card ${
                      tokenType === "public" ? "selected" : ""
                    }`}
                    onClick={() => setTokenType("public")}
                  >
                    <div className="token-type-icon public">
                      <FiEye size={28} />
                    </div>
                    <h4 className="token-type-title fs-16 inter">
                      Public Gallery
                    </h4>
                    <p className="token-type-description fs-14 inter">
                      Open to everyone with the link. Ideal for portfolio
                      showcases.
                    </p>
                    <div className="token-type-features fs-14 inter">
                      <div className="feature-item inter">
                        <FiCheckCircle size={14} />
                        <span className="inter">No restrictions</span>
                      </div>
                      <div className="feature-item">
                        <FiCheckCircle size={14} />
                        <span className="inter">Easy sharing</span>
                      </div>
                      <div className="feature-item inter">
                        <FiCheckCircle size={14} />
                        <span className="inter">SEO friendly</span>
                      </div>
                    </div>
                    {tokenType === "public" && (
                      <div className="selected-badge inter">
                        <FiCheckCircle size={16} />
                        <span className="inter">Selected</span>
                      </div>
                    )}
                  </div>
                </div>
              </div>

              <div className="info-box inter">
                <ClockLoader size={20} color="#1e40af" className="me-2 inter" />{" "}
                <span className="inter">
                  This token will be automatically linked to your active event
                </span>
              </div>
            </div>

            <div className="modal-footer">
              <button
                className="btn-secondary inter"
                onClick={() => setShowGenerateModal(false)}
                disabled={generateLoading}
              >
                Cancel
              </button>
              <button
                className="btn-primary inter"
                onClick={handleGenerateToken}
                disabled={generateLoading}
              >
                {generateLoading ? (
                  <>
                    <div className="spinner-small"></div>
                    Generating...
                  </>
                ) : (
                  <>
                    <FiPlus className="me-2" />
                    Generate Token
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default TokensSharing;
