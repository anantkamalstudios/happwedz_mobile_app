
import React, { useState, useEffect } from "react";
import { useToast } from "../../layouts/toasts/Toast";

const API_BASE_URL = "https://happywedz.com";

const QuotationModal = ({ show, onClose, lead, vendorToken }) => {
  const [submitting, setSubmitting] = useState(false);
  const [formData, setFormData] = useState({
    price: "",
    servicesIncluded: "", // Holds the single service string from the input
    date: "",
    message: "",
  });
  const [quotationsList, setQuotationsList] = useState([]);
  const [loadingHistory, setLoadingHistory] = useState(false);
  const { addToast } = useToast();

  useEffect(() => {
    // Scroll lock logic for the modal
    document.body.style.overflow = show ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [show]);

  useEffect(() => {
    if (show && lead?.request?.user?.id && vendorToken) {
      fetchHistory();
    } else {
      setQuotationsList([]);
    }
  }, [show, lead, vendorToken]);

  const fetchHistory = async () => {
    setLoadingHistory(true);
    try {
      const response = await fetch(
        `${API_BASE_URL}/api/request-pricing/vendor/quotation-history?userId=${lead.request.user.id}`,
        {
          headers: {
            Authorization: `Bearer ${vendorToken}`,
          },
        }
      );
      const data = await response.json();
      if (data.quotations && Array.isArray(data.quotations)) {
        setQuotationsList(data.quotations);
      } else {
        setQuotationsList([]);
      }
    } catch (err) {
      console.error("Error fetching quotation history:", err);
    } finally {
      setLoadingHistory(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((p) => ({ ...p, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!lead || !lead.request) return;

    setSubmitting(true);

    try {
      if (!vendorToken) throw new Error("Authentication token not found.");

      // CRITICAL FIX: Sending 'services' as an array of strings
      const payload = {
        price: formData.price,
        servicesIncluded: [formData.servicesIncluded.trim()],
        validTill: formData.date,
        message: formData.message,
        userId: lead.request.user?.id,
      };

      const response = await fetch(
        `${API_BASE_URL}/api/request-pricing/requests/${lead.request.id}/quotation`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${vendorToken}`,
          },
          body: JSON.stringify(payload),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || "Failed to send quotation.");
      }

      addToast("Quotation sent successfully!", "success");
      onClose();

      // OPTIONAL: If the quote API doesn't change the lead status to 'replied',
      // you might need to call the 'replied' action here:
      /*
      if (lead.request.status !== 'replied') {
          await fetch(`${API_BASE_URL}/api/inbox/${lead.id}/replied`, { 
              method: "PATCH", 
              headers: { Authorization: `Bearer ${vendorToken}` } 
          });
      }
      */
    } catch (err) {
      addToast(`Error: ${err.message}`, "error");
    } finally {
      setSubmitting(false);
    }
  };

  if (!show) {
    return null;
  }

  return (
    <>
      <div className="custom-backdrop" onClick={onClose}></div>
      <div className="custom-modal" role="dialog" aria-modal="true">
        <div
          className="modal-content custom-modal-card"
          style={{ borderRadius: "15px" }}
          onClick={(e) => e.stopPropagation()}
        >
          <div className="modal-header custom-modal-header">
            <div className="text-center w-100 mb-4">
              <h5 className="modal-title mb-0 text-danger">Quotations</h5>
              <small className="text-light d-block text-dark">
                {quotationsList.length > 0
                  ? "Previous Quotations"
                  : "Fill up details"}
              </small>
            </div>
            <button
              type="button"
              className="close-circle"
              onClick={onClose}
              aria-label="Close"
            >
              &times;
            </button>
          </div>

          {loadingHistory ? (
            <div className="d-flex justify-content-center py-5">
              <div className="spinner-border text-danger" role="status">
                <span className="visually-hidden">Loading...</span>
              </div>
            </div>
          ) : quotationsList.length > 0 ? (
            <div className="modal-body">
              <div className="alert alert-info mb-3">
                <h6 className="alert-heading fw-bold mb-1">History</h6>
                <p className="mb-0 small">
                  You have sent {quotationsList.length} quotation(s) to this
                  user.
                </p>
              </div>

              <div
                className="quotations-list mb-3"
                style={{ maxHeight: "400px", overflowY: "auto" }}
              >
                {quotationsList.map((q, index) => (
                  <div
                    key={index}
                    className="card bg-light border-0 mb-3 shadow-sm"
                  >
                    <div className="card-header bg-transparent border-0 pb-0 d-flex justify-content-between align-items-center">
                      <span className="badge bg-secondary">
                        Quote #{quotationsList.length - index}
                      </span>
                      <small className="text-muted">
                        {/* If we had a createdAt, we'd use it here. 
                            For now, relying on validTill or just order. */}
                        {q.quote?.createdAt
                          ? new Date(q.quote.createdAt).toLocaleDateString()
                          : ""}
                      </small>
                    </div>
                    <div className="card-body">
                      <div className="row g-2">
                        <div className="col-6">
                          <span className="fw-bold text-muted small text-uppercase d-block">
                            Price
                          </span>
                          <span className="fs-5 fw-bold text-dark">
                            ₹{q.quote?.price}
                          </span>
                        </div>
                        <div className="col-6 text-end">
                          <span className="fw-bold text-muted small text-uppercase d-block">
                            Valid Until
                          </span>
                          <span className="text-dark">
                            {q.quote?.validTill}
                          </span>
                        </div>
                      </div>

                      <div className="mt-2">
                        <span className="fw-bold text-muted small text-uppercase d-block">
                          Services
                        </span>
                        <span className="text-dark">
                          {Array.isArray(q.quote?.servicesIncluded)
                            ? q.quote.servicesIncluded.join(", ")
                            : q.quote?.servicesIncluded}
                        </span>
                      </div>

                      <div className="mt-2">
                        <span className="fw-bold text-muted small text-uppercase d-block">
                          Message
                        </span>
                        <div
                          className="text-dark small bg-white p-2 rounded"
                          style={{ whiteSpace: "pre-wrap" }}
                        >
                          {q.quote?.message}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="d-grid gap-2">
                <button
                  className="btn btn-outline-secondary"
                  onClick={() => setQuotationsList([])}
                >
                  Send New Quotation
                </button>
              </div>
            </div>
          ) : (
            <form onSubmit={handleSubmit}>
              <div className="modal-body">
                <div className="mb-3">
                  <label className="form-label">Price</label>
                  <input
                    name="price"
                    value={formData.price}
                    onChange={handleChange}
                    type="number"
                    className="form-control"
                    placeholder="0"
                    required
                  />
                </div>

                <div className="mb-3">
                  <label className="form-label">Services</label>
                  <input
                    name="servicesIncluded"
                    value={formData.servicesIncluded}
                    onChange={handleChange}
                    type="text"
                    className="form-control"
                    placeholder="e.g., Photography, Videography, Album"
                    required
                  />
                  <div className="form-text">Enter service details.</div>
                </div>

                <div className="mb-3">
                  <label className="form-label">Valid Till Date</label>
                  <input
                    name="date"
                    value={formData.date}
                    onChange={handleChange}
                    type="date"
                    className="form-control"
                    required
                  />
                </div>

                <div className="mb-3">
                  <label className="form-label">Message</label>
                  <textarea
                    name="message"
                    value={formData.message}
                    onChange={handleChange}
                    className="form-control"
                    rows="5"
                    maxLength="2000"
                    placeholder="Your Message"
                  />
                  <div className="form-text text-end">Max. 2000 characters</div>
                </div>
              </div>

              <div className="modal-footer border-0 p-3">
                <button
                  type="submit"
                  className="btn btn-pink w-100"
                  disabled={submitting}
                >
                  {submitting ? "Sending..." : "Send"}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </>
  );
};

export default QuotationModal;
