import React, { useState, useEffect } from "react";
import { useSelector } from "react-redux";
import axios from "axios";
import Swal from "sweetalert2";
import {
  Copy,
  Check,
  Send,
  Users,
  Mail,
  Calendar,
  Link2,
  Sparkles,
} from "lucide-react";
import "bootstrap/dist/css/bootstrap.min.css";

export default function ReviewRequestForm() {
  const { vendor, token } = useSelector((state) => state.vendorAuth) || {};
  const [bookedLeads, setBookedLeads] = useState([]);
  const [selectedInboxId, setSelectedInboxId] = useState("");
  const [selectedLead, setSelectedLead] = useState(null);
  const [message, setMessage] = useState("");
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  const vendorId = vendor?.id || vendor?.vendorId;
  const [serviceId, setServiceId] = useState(null);

  const reviewUrl = `${window.location.origin}/write-review/${serviceId}`;

  useEffect(() => {
    if (!token) return;
    const fetchBooked = async () => {
      try {
        const res = await axios.get(
          "https://happywedz.com/api/inbox?filter=booked",
          {
            headers: { Authorization: `Bearer ${token}` },
          }
        );
        setBookedLeads(res.data.inbox || []);
      } catch (err) {
        console.error("Fetch Booked Leads Error:", err);
      }
    };
    fetchBooked();
  }, [token]);

  useEffect(() => {
    const fetchServiceId = async () => {
      if (!vendorId) return;
      try {
        const res = await axios.get(
          `https://happywedz.com/api/vendor-services/vendor/${vendorId}`,
          { headers: token ? { Authorization: `Bearer ${token}` } : {} }
        );
        const raw = res?.data;
        const list = Array.isArray(raw)
          ? raw
          : Array.isArray(raw?.data)
          ? raw.data
          : raw?.data
          ? [raw.data]
          : [];
        if (list.length > 0) {
          const preferred = list.find((s) => s?.vendor_subcategory_id === 2);
          const chosen = preferred || list[0];
          if (chosen?.id) setServiceId(chosen.id);
        }
      } catch (e) {
        setServiceId(null);
      }
    };
    fetchServiceId();
  }, [vendorId, token]);

  const handleSelectChange = (e) => {
    const inboxId = e.target.value;
    setSelectedInboxId(inboxId);
    const lead = bookedLeads.find((item) => item.id == inboxId);
    setSelectedLead(lead);

    if (lead) {
      const user = lead?.request?.user;
      const eventDate = lead.request?.eventDate;

      setMessage(
        `Hi ${user?.name || ""},\n\n` +
          `Thank you for choosing ${vendor?.businessName} for your event on ${eventDate}.\n` +
          `We would love to hear your feedback on our services!\n\n` +
          `Please review us on HappyWedz.\n\n` +
          `Thanks & Regards,\n${vendor?.businessName}`
      );
    }
  };

  const handleSend = async () => {
    if (!selectedLead) {
      return Swal.fire({
        icon: "error",
        text: "Please select a booked customer",
      });
    }

    const userId = selectedLead.request?.user?.id;
    const requestId = selectedLead.request?.id;

    if (!userId) {
      return Swal.fire({
        icon: "error",
        text: "User not found for this booking",
      });
    }

    if (!selectedLead.request?.user?.email) {
      return Swal.fire({
        icon: "error",
        text: "No email found for this customer",
      });
    }

    if (!message.trim()) {
      return Swal.fire({ icon: "warning", text: "Message cannot be empty" });
    }

    setLoading(true);
    try {
      await axios.post(
        `https://happywedz.com/api/reviews/send-review-request/${requestId}`,
        {
          message,
          reviewLink: reviewUrl,
        },
        {
          headers: { Authorization: `Bearer ${token}` },
        }
      );

      Swal.fire({
        icon: "success",
        text: "Review Request Sent Successfully!",
      });

      setSelectedInboxId("");
      setSelectedLead(null);
      setMessage("");
    } catch (err) {
      const apiMsg = err?.response?.data?.message;
      Swal.fire({
        icon: "error",
        text: apiMsg || "Failed to send review request.",
      });
    } finally {
      setLoading(false);
    }
  };

  const copyUrl = () => {
    navigator.clipboard
      .writeText(reviewUrl)
      .then(() => {
        setCopied(true);
        setTimeout(() => setCopied(false), 2000);
      })
      .catch((err) => {
        console.error("Failed to copy:", err);
        Swal.fire({
          icon: "error",
          text: "Failed to copy URL",
        });
      });
  };

  return (
    <div className="container py-4" style={{ maxWidth: "900px" }}>
      {/* Header Section */}
      <div className="text-center mb-5">
        <div
          className="d-inline-flex align-items-center gap-2 mb-3 px-3 py-2 rounded-pill"
          style={{
            background: "linear-gradient(135deg, #fef3f8 0%, #fff5f9 100%)",
            border: "1px solid #fce4ec",
          }}
        >
          <Sparkles size={18} style={{ color: "#ed1173" }} />
          <span
            style={{ color: "#ed1173", fontWeight: "600", fontSize: "14px" }}
          >
            Collect Reviews Effortlessly
          </span>
        </div>
        <h2 className="fw-bold mb-2" style={{ color: "#2d3748" }}>
          Review Collector
        </h2>
        <p className="text-muted mb-0">
          Send review requests to your happy clients and grow your reputation
        </p>
      </div>

      {/* Main Form Card */}
      <div
        className="card border-0 shadow-lg rounded-4 mb-4"
        style={{ overflow: "hidden" }}
      >
        {/* Card Header with Gradient */}
        <div
          className="px-4 py-3"
          style={{
            background: "linear-gradient(135deg, #ed1173 0%, #f72585 100%)",
          }}
        >
          <div className="d-flex align-items-center gap-2">
            <Send size={20} style={{ color: "white" }} />
            <h5 className="mb-0 text-white fw-semibold">Send Review Request</h5>
          </div>
        </div>

        <div className="card-body p-4">
          {/* Select Customer */}
          <div className="mb-4">
            <label
              className="form-label fw-semibold d-flex align-items-center gap-2 mb-2"
              style={{ color: "#2d3748" }}
            >
              <Users size={18} style={{ color: "#ed1173" }} />
              Select Customer
            </label>
            <select
              className="form-select rounded-3 border-2"
              style={{
                padding: "12px 16px",
                fontSize: "15px",
                borderColor: "#e2e8f0",
                transition: "all 0.2s",
              }}
              value={selectedInboxId}
              onChange={handleSelectChange}
            >
              <option value="">Choose a booked customer...</option>
              {bookedLeads.map((item) => (
                <option key={item.id} value={item.id}>
                  {`${item.request?.firstName || ""} ${
                    item.request?.lastName || ""
                  }`.trim() || "No Name"}{" "}
                  - {item.request?.eventDate}
                </option>
              ))}
            </select>
          </div>

          {/* Customer Details - Animated Reveal */}
          {selectedLead && (
            <div className="mb-4" style={{ animation: "fadeIn 0.3s ease-in" }}>
              <div className="row g-3">
                <div className="col-md-6">
                  <label
                    className="form-label fw-semibold d-flex align-items-center gap-2 mb-2"
                    style={{ color: "#2d3748", fontSize: "14px" }}
                  >
                    <Users size={16} style={{ color: "#ed1173" }} />
                    Customer Name
                  </label>
                  <div
                    className="p-3 rounded-3"
                    style={{
                      backgroundColor: "#f8fafc",
                      border: "1px solid #e2e8f0",
                    }}
                  >
                    <span style={{ color: "#475569", fontWeight: "500" }}>
                      {selectedLead.request.user.name}
                    </span>
                  </div>
                </div>

                <div className="col-md-6">
                  <label
                    className="form-label fw-semibold d-flex align-items-center gap-2 mb-2"
                    style={{ color: "#2d3748", fontSize: "14px" }}
                  >
                    <Mail size={16} style={{ color: "#ed1173" }} />
                    Email Address
                  </label>
                  <div
                    className="p-3 rounded-3"
                    style={{
                      backgroundColor: "#f8fafc",
                      border: "1px solid #e2e8f0",
                    }}
                  >
                    <span style={{ color: "#475569", fontWeight: "500" }}>
                      {selectedLead.request.user.email}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Message Textarea */}
          <div className="mb-4">
            <label
              className="form-label fw-semibold d-flex align-items-center gap-2 mb-2"
              style={{ color: "#2d3748" }}
            >
              <Mail size={18} style={{ color: "#ed1173" }} />
              Personalized Message
            </label>
            <textarea
              className="form-control rounded-3 border-2"
              rows="8"
              style={{
                padding: "14px 16px",
                fontSize: "15px",
                borderColor: "#e2e8f0",
                resize: "vertical",
                lineHeight: "1.6",
              }}
              placeholder="Write a personalized message to your client..."
              value={message}
              onChange={(e) => setMessage(e.target.value)}
            />
            <small className="text-muted mt-1 d-block">
              Tip: Personalized messages get better response rates!
            </small>
          </div>

          {/* Send Button */}
          <button
            className="btn btn-lg w-100 rounded-3 d-flex align-items-center justify-content-center gap-2"
            style={{
              background: "linear-gradient(135deg, #ed1173 0%, #f72585 100%)",
              color: "white",
              border: "none",
              padding: "14px",
              fontWeight: "600",
              fontSize: "16px",
              transition: "transform 0.2s, box-shadow 0.2s",
              boxShadow: "0 4px 12px rgba(237, 17, 115, 0.3)",
            }}
            disabled={loading || !selectedLead}
            onClick={handleSend}
            onMouseEnter={(e) => {
              e.currentTarget.style.transform = "translateY(-2px)";
              e.currentTarget.style.boxShadow =
                "0 6px 16px rgba(237, 17, 115, 0.4)";
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.transform = "translateY(0)";
              e.currentTarget.style.boxShadow =
                "0 4px 12px rgba(237, 17, 115, 0.3)";
            }}
          >
            {loading ? (
              <>
                <div className="spinner-border spinner-border-sm" role="status">
                  <span className="visually-hidden">Sending...</span>
                </div>
                Sending Request...
              </>
            ) : (
              <>
                <Send size={20} />
                Send Review Request
              </>
            )}
          </button>
        </div>
      </div>

      {/* Share URL Card */}
      <div
        className="card border-0 shadow-lg rounded-4"
        style={{ overflow: "hidden" }}
      >
        {/* Card Header */}
        <div className="px-4 py-3 border-1">
          <div className="d-flex align-items-center gap-2">
            <Link2 size={20} />
            <h5 className="mb-0 text-black fw-semibold">
              Share Your Review Link
            </h5>
          </div>
        </div>

        <div className="card-body p-4">
          <p
            className="text-muted mb-3"
            style={{ fontSize: "15px", lineHeight: "1.6" }}
          >
            Share this personalized URL with your past clients via WhatsApp,
            SMS, or social media to collect reviews quickly.
          </p>

          {/* URL Input with Copy Button */}
          <div className="input-group mb-3">
            <input
              type="text"
              className="form-control"
              style={{
                padding: "12px 16px",
                fontSize: "14px",
                backgroundColor: "#f8fafc",
                color: "#475569",
                border: "1px solid #e2e8f0",
              }}
              value={reviewUrl}
              readOnly
            />
            <button
              className={`btn ${
                copied ? "btn-success" : "btn-outline-primary border-none"
              } d-flex align-items-center justify-content-center gap-2 px-3 flex-shrink-0`}
              onClick={copyUrl}
            >
              {copied ? <Check size={16} /> : <Copy size={16} />}
            </button>
          </div>

          {/* Success Message */}
          {copied && (
            <div
              className="alert alert-success d-flex align-items-center gap-2 mb-0"
              style={{ animation: "fadeIn 0.3s ease-in" }}
            >
              <Check size={18} />
              <span>Link copied to clipboard!</span>
            </div>
          )}
        </div>
      </div>

      <style>{`
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

        .form-select:focus,
        .form-control:focus {
          border-color: #ed1173 !important;
          box-shadow: 0 0 0 3px rgba(237, 17, 115, 0.1) !important;
        }

        .btn:disabled {
          opacity: 0.6;
          cursor: not-allowed;
        }
      `}</style>
    </div>
  );
}
