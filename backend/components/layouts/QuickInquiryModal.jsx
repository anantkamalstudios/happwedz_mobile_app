import React, { useState } from "react";
import { Modal, Button, Form, Row, Col } from "react-bootstrap";
import { FaPaperPlane, FaUser, FaPhone, FaCalendar } from "react-icons/fa";
import EventDatePicker from "./DayPicker";
import Swal from "sweetalert2";
import messagesApi from "../../services/api/messagesApi";

const QuickInquiryModal = ({ show, handleClose, vendorId, vendorName }) => {
  const [formData, setFormData] = useState({
    name: "",
    phone: "",
    eventDate: "",
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // Validate required fields
    const { name, phone, eventDate } = formData;
    if (!name || !phone || !eventDate) {
      setError("Please fill in all fields.");
      return;
    }

    // Validate phone number (basic validation)
    if (phone.length < 10) {
      setError("Please enter a valid phone number.");
      return;
    }

    // Validate vendorId
    if (!vendorId) {
      console.error("QuickInquiryModal Error: vendorId prop is missing.");
      setError("Could not identify the vendor. Please try again.");
      return;
    }

    setSubmitting(true);
    setError(null);

    // Split name into firstName and lastName
    const nameParts = name.trim().split(" ");
    const firstName = nameParts[0] || "";
    const lastName = nameParts.slice(1).join(" ") || "";

    // Build payload for guest user
    const payload = {
      vendorId: vendorId,
      firstName: firstName,
      lastName: lastName,
      email: `guest_${Date.now()}@happywedz.com`, // Temporary email for guest
      phone: phone,
      eventDate: eventDate,
      message: "Quick inquiry from listing page",
      isGuestInquiry: true, // Flag to identify guest inquiries
    };

    try {
      const apiUrl = import.meta.env.VITE_API_URL|| "https://happywedz.com";
      const response = await fetch(
        `${apiUrl}/request-pricing`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify(payload),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        throw new Error(result.message || "Something went wrong.");
      }

      // Try to create conversation (optional, may fail for guest users)
      try {
        const createdRequestId =
          result?.data?.id || result?.request?.id || result?.id || null;
        if (createdRequestId) {
          await messagesApi.createConversation({
            vendorId,
            requestId: createdRequestId,
          });
        }
      } catch (convErr) {
        console.warn("createConversation warning:", convErr?.message || convErr);
      }

      Swal.fire({
        icon: "success",
        title: "Inquiry Sent!",
        text: `${vendorName || "The vendor"} will contact you soon at ${phone}`,
        timer: 3000,
        showConfirmButton: false,
      });

      // Reset form
      setFormData({
        name: "",
        phone: "",
        eventDate: "",
      });

      handleClose();
    } catch (err) {
      setError(err.message);
      console.error("Failed to send quick inquiry:", err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="quick-inquiry-modal">
      <style>{`
        .quick-inquiry-modal .modal-content {
          border-radius: 20px;
          border: none;
          box-shadow: 0 20px 60px rgba(0, 0, 0, 0.2);
          overflow: hidden;
        }

        .quick-inquiry-modal .modal-header {
          background: linear-gradient(135deg, #e83e8c 0%, #c2185b 100%);
          color: white;
          border-radius: 0;
          padding: 1.75rem 2rem;
          border: none;
          position: relative;
        }

        .quick-inquiry-modal .modal-header::after {
          content: '';
          position: absolute;
          bottom: 0;
          left: 0;
          right: 0;
          height: 4px;
          background: linear-gradient(90deg, rgba(255,255,255,0.3) 0%, rgba(255,255,255,0.1) 100%);
        }

        .quick-inquiry-modal .modal-header .btn-close {
          filter: brightness(0) invert(1);
          opacity: 0.9;
          transition: opacity 0.2s;
        }

        .quick-inquiry-modal .modal-header .btn-close:hover {
          opacity: 1;
        }

        .quick-inquiry-modal .modal-title {
          font-weight: 700;
          font-size: 1.5rem;
          letter-spacing: -0.5px;
          display: flex;
          align-items: center;
          gap: 0.75rem;
        }

        .quick-inquiry-modal .modal-body {
          padding: 2.5rem 2rem;
          background: #ffffff;
        }

        .quick-inquiry-modal .form-label {
          font-weight: 600;
          color: #2d3748;
          margin-bottom: 0.625rem;
          display: flex;
          align-items: center;
          gap: 0.5rem;
          font-size: 0.9rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
        }

        .quick-inquiry-modal .form-label svg {
          color: #e83e8c;
        }

        .quick-inquiry-modal .form-control {
          border-radius: 12px;
          border: 2px solid #e2e8f0;
          padding: 0.875rem 1.125rem;
          transition: all 0.3s ease;
          font-size: 1rem;
          background: #f8fafc;
        }

        .quick-inquiry-modal .form-control:focus {
          border-color: #e83e8c;
          box-shadow: 0 0 0 4px rgba(232, 62, 140, 0.1);
          background: #ffffff;
          outline: none;
        }

        .quick-inquiry-modal .form-control::placeholder {
          color: #a0aec0;
        }

        .quick-inquiry-modal .form-text {
          font-size: 0.8rem;
          color: #718096;
          margin-top: 0.375rem;
          display: flex;
          align-items: center;
          gap: 0.25rem;
        }

        .quick-inquiry-modal .submit-btn {
          background: linear-gradient(135deg, #e83e8c 0%, #c2185b 100%);
          border: none;
          border-radius: 12px;
          padding: 1rem 2rem;
          font-weight: 700;
          font-size: 1.05rem;
          transition: all 0.3s ease;
          box-shadow: 0 8px 20px rgba(232, 62, 140, 0.3);
          letter-spacing: 0.3px;
        }

        .quick-inquiry-modal .submit-btn:hover:not(:disabled) {
          transform: translateY(-3px);
          box-shadow: 0 12px 28px rgba(232, 62, 140, 0.4);
          background: linear-gradient(135deg, #f04a9a 0%, #d01f66 100%);
        }

        .quick-inquiry-modal .submit-btn:active:not(:disabled) {
          transform: translateY(-1px);
        }

        .quick-inquiry-modal .submit-btn:disabled {
          opacity: 0.65;
          cursor: not-allowed;
          transform: none;
        }

        .quick-inquiry-modal .vendor-badge {
          background: linear-gradient(135deg, #fff5f9 0%, #ffe5f0 100%);
          padding: 1rem 1.25rem;
          border-radius: 12px;
          margin-bottom: 1.75rem;
          border-left: 5px solid #e83e8c;
          box-shadow: 0 2px 8px rgba(232, 62, 140, 0.08);
        }

        .quick-inquiry-modal .vendor-badge small {
          color: #718096;
          font-size: 0.75rem;
          text-transform: uppercase;
          letter-spacing: 0.5px;
          font-weight: 600;
        }

        .quick-inquiry-modal .vendor-badge strong {
          color: #c2185b;
          font-size: 1.1rem;
          display: block;
          margin-top: 0.25rem;
        }

        .quick-inquiry-modal .info-text {
          font-size: 0.875rem;
          color: #4a5568;
          margin-top: 1.25rem;
          padding: 1rem 1.25rem;
          background: linear-gradient(135deg, #f7fafc 0%, #edf2f7 100%);
          border-radius: 12px;
          text-align: center;
          border: 1px solid #e2e8f0;
        }

        .quick-inquiry-modal .info-text small {
          display: flex;
          align-items: center;
          justify-content: center;
          gap: 0.5rem;
          font-weight: 500;
        }

        .quick-inquiry-modal .alert {
          border-radius: 12px;
          border: none;
          padding: 1rem 1.25rem;
          margin-bottom: 1.5rem;
          font-weight: 500;
        }

        .quick-inquiry-modal .alert-danger {
          background: #fff5f5;
          color: #c53030;
          border-left: 4px solid #fc8181;
        }

        .quick-inquiry-modal .form-group {
          margin-bottom: 1.5rem;
        }

        @keyframes slideIn {
          from {
            opacity: 0;
            transform: translateY(-20px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .quick-inquiry-modal .modal-content {
          animation: slideIn 0.3s ease-out;
        }
      `}</style>

      <Modal show={show} onHide={handleClose} size="md" centered className="quick-inquiry-modal">
        <Modal.Header closeButton>
          <Modal.Title>
            <FaPaperPlane />
            Quick Inquiry
          </Modal.Title>
        </Modal.Header>

        <Modal.Body>
          {vendorName && (
            <div className="vendor-badge">
              <small>Inquiring about:</small>
              <strong>{vendorName}</strong>
            </div>
          )}

          <Form onSubmit={handleSubmit}>
            {error && (
              <div className="alert alert-danger" role="alert">
                ⚠️ {error}
              </div>
            )}

            {/* Name */}
            <Form.Group className="mb-3">
              <Form.Label>
                <FaUser size={15} />
                Your Name
              </Form.Label>
              <Form.Control
                type="text"
                name="name"
                placeholder="Enter your full name"
                value={formData.name}
                onChange={handleChange}
                required
              />
            </Form.Group>

            {/* Phone */}
            <Form.Group className="mb-3">
              <Form.Label>
                <FaPhone size={15} />
                Phone Number
              </Form.Label>
              <Form.Control
                type="tel"
                name="phone"
                placeholder="+91 98765 43210"
                value={formData.phone}
                onChange={handleChange}
                required
              />
              <Form.Text className="text-muted">
                📱 We'll share this with the vendor to contact you
              </Form.Text>
            </Form.Group>

            {/* Event Date */}
            <Form.Group className="mb-3">
              <Form.Label>
                <FaCalendar size={15} />
                Event Date
              </Form.Label>
              <EventDatePicker formData={formData} setFormData={setFormData} />
            </Form.Group>

            <div className="info-text">
              <small>
                ✨ No account needed! The vendor will contact you directly.
              </small>
            </div>

            {/* Submit Button */}
            <Button
              type="submit"
              className="w-100 mt-3 submit-btn"
              disabled={submitting}
            >
              {submitting ? (
                <>
                  <span
                    className="spinner-border spinner-border-sm me-2"
                    role="status"
                    aria-hidden="true"
                  ></span>
                  Sending...
                </>
              ) : (
                <>
                  <FaPaperPlane className="me-2" />
                  Send Quick Inquiry
                </>
              )}
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default QuickInquiryModal;
