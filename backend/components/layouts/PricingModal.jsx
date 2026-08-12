import React, { useState, useEffect } from "react";
import { Modal, Button, Form, Row, Col, Image } from "react-bootstrap";
import { FaPaperPlane } from "react-icons/fa";
import { useSelector } from "react-redux";
import { useNavigate } from "react-router-dom";
import EventDatePicker from "./DayPicker";
import Swal from "sweetalert2";
import messagesApi from "../../services/api/messagesApi";

const PricingModal = ({ show, handleClose, vendorId }) => {
  const { user, token } = useSelector((state) => state.auth);
  const navigate = useNavigate();
  const [vendorDetails, setVendorDetails] = useState(null);

  const [formData, setFormData] = useState({
    firstName: "",
    lastName: "",
    email: "",
    phone: "",
    eventDate: "",
    message: "",
  });

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (vendorId && show) {
      const fetchVendorDetails = async () => {
        try {
          const response = await fetch(
            `https://happywedz.com/api/vendor-services/${vendorId}`
          );
          const result = await response.json();
          if (result.success) {
            setVendorDetails(result.data);
          }
        } catch (err) {
          console.error("Failed to fetch vendor details:", err);
        }
      };
      fetchVendorDetails();
    } else {
      setVendorDetails(null);
    }
  }, [vendorId, show]);

  useEffect(() => {
    if (user) {
      setFormData((prev) => ({
        ...prev,
        firstName: user.firstName || "",
        lastName: user.lastName || "",
        email: user.email || "",
        phone: user.phone || "",
      }));
    } else {
      // Reset form if logged out
      setFormData({
        firstName: "",
        lastName: "",
        email: "",
        phone: "",
        eventDate: new Date(),
        message: "",
      });
    }
  }, [user, show]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();

    // 1. Check login state
    if (!token || !user) {
      handleClose();
      navigate("/customer-login");
      return;
    }

    // 2. Validate required fields
    const { firstName, lastName, email, phone, eventDate } = formData;
    if (!firstName || !lastName || !email || !phone || !eventDate) {
      setError("Please fill in all required fields.");
      return;
    }

    // 3. Validate vendorId
    if (!vendorId) {
      console.error("PricingModal Error: vendorId prop is missing.");
      setError("Could not identify the vendor. Please try again.");
      return;
    }

    setSubmitting(true);
    setError(null);

    // 4. Build payload
    const payload = {
      ...formData,
      vendorId: vendorId,
      userId: user.id,
    };

    try {
      const response = await fetch(
        "https://happywedz.com/api/request-pricing",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            ...(token && { Authorization: `Bearer ${token}` }),
          },
          body: JSON.stringify(payload),
        }
      );

      const result = await response.json();

      if (!response.ok) {
        if (result.message?.toLowerCase().includes("token")) {
          setError("Your session has expired. Please login again.");
          handleClose();
          navigate("/customer-login");
          return;
        }
        throw new Error(result.message || "Something went wrong.");
      }
      // Try to create or ensure a conversation exists for this vendor/user
      try {
        const createdRequestId =
          result?.data?.id || result?.request?.id || result?.id || null;
        await messagesApi.createConversation({
          vendorId,
          ...(createdRequestId ? { requestId: createdRequestId } : {}),
        });
      } catch (convErr) {
        // Non-fatal: if conversation already exists or API returns a soft error, we ignore
        console.warn(
          "createConversation warning:",
          convErr?.message || convErr
        );
      }

      Swal.fire({
        icon: "Success",
        text: "Request sent successfully!",
        timer: 1500,
      });
      handleClose();
    } catch (err) {
      setError(err.message);
      console.error("Failed to send pricing request:", err);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="pricing-model">
      <Modal show={show} onHide={handleClose} size="lg" centered>
        <Modal.Header closeButton>
          <div className="d-flex align-items-center w-100">
            <div className="d-flex flex-column">
              <h5 className="mb-1">Request Pricing</h5>
              <p className="mb-0 text-muted" style={{ fontSize: "12px" }}>
                Please provide your details below to request pricing from this
                vendor.
              </p>
            </div>
          </div>
        </Modal.Header>

        <Modal.Body>
          <Form onSubmit={handleSubmit} className="custom-form">
            {error && (
              <div className="alert alert-danger" role="alert">
                {error}
              </div>
            )}

            {/* First/Last Name */}
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>First Name *</Form.Label>
                  <Form.Control
                    type="text"
                    name="firstName"
                    placeholder="John"
                    value={formData.firstName}
                    onChange={handleChange}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Last Name *</Form.Label>
                  <Form.Control
                    type="text"
                    name="lastName"
                    placeholder="Doe"
                    value={formData.lastName}
                    onChange={handleChange}
                  />
                </Form.Group>
              </Col>
            </Row>

            {/* Email / Phone */}
            <Row>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Email *</Form.Label>
                  <Form.Control
                    type="email"
                    name="email"
                    placeholder="john@example.com"
                    value={formData.email}
                    onChange={handleChange}
                  />
                </Form.Group>
              </Col>
              <Col md={6}>
                <Form.Group className="mb-3">
                  <Form.Label>Phone *</Form.Label>
                  <Form.Control
                    type="tel"
                    name="phone"
                    placeholder="+91 98765 43210"
                    value={formData.phone}
                    onChange={handleChange}
                  />
                </Form.Group>
              </Col>
            </Row>

            {/* Event Date */}
            <EventDatePicker formData={formData} setFormData={setFormData} />

            {/* Message */}
            <Form.Group className="mb-3">
              <Form.Label>Message (Optional)</Form.Label>
              <Form.Control
                as="textarea"
                rows={3}
                name="message"
                placeholder="Tell us about your event requirements..."
                value={formData.message}
                onChange={handleChange}
              />
            </Form.Group>

            {/* Submit Button */}
            <Button
              type="submit"
              variant="primary"
              className="w-100"
              disabled={submitting}
            >
              {submitting ? (
                "Sending..."
              ) : (
                <>
                  <FaPaperPlane className="me-2" /> Send Request
                </>
              )}
            </Button>
          </Form>
        </Modal.Body>
      </Modal>
    </div>
  );
};

export default PricingModal;
