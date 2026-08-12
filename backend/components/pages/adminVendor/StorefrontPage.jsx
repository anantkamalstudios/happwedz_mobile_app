// src/components/pages/StorefrontPage.js
import React, { useState } from "react";
import {
  Container,
  Row,
  Col,
  Card,
  ProgressBar,
  Button,
  Form,
} from "react-bootstrap";
import {
  FiCheckCircle,
  FiEdit,
  FiImage,
  FiDollarSign,
  FiCalendar,
  FiMail,
} from "react-icons/fi";

const StorefrontPage = () => {
  const [completedItems, setCompletedItems] = useState([1, 3]); // Example completed items

  const checklistItems = [
    {
      id: 1,
      title: "Business Information",
      icon: <FiEdit />,
      description: "Add your business name, description and contact details",
    },
    {
      id: 2,
      title: "Profile Photos",
      icon: <FiImage />,
      description: "Upload high-quality photos of your work",
    },
    {
      id: 3,
      title: "Services & Pricing",
      icon: <FiDollarSign />,
      description: "List your services with clear pricing",
    },
    {
      id: 4,
      title: "Availability Calendar",
      icon: <FiCalendar />,
      description: "Set your availability for bookings",
    },
    {
      id: 5,
      title: "Testimonials",
      icon: <FiMail />,
      description: "Add client reviews and testimonials",
    },
  ];

  const completionPercentage = Math.round(
    (completedItems.length / checklistItems.length) * 100
  );

  const toggleCompletion = (id) => {
    if (completedItems.includes(id)) {
      setCompletedItems(completedItems.filter((itemId) => itemId !== id));
    } else {
      setCompletedItems([...completedItems, id]);
    }
  };

  return (
    <div className="storefront-page">
      <div className="page-header mb-4">
        <h2 className="page-title">Storefront Checklist</h2>
        <p className="text-muted">
          Complete these steps to optimize your storefront
        </p>
      </div>

      <Card className="mb-4">
        <Card.Body>
          <div className="d-flex justify-content-between align-items-center mb-3">
            <div>
              <h5 className="mb-0">Profile Completion</h5>
              <p className="text-muted mb-0">
                Your profile is {completionPercentage}% complete
              </p>
            </div>
            <div className="display-5 fw-bold text-primary">
              {completionPercentage}%
            </div>
          </div>
          <ProgressBar
            now={completionPercentage}
            variant="primary"
            className="mb-4"
            style={{ height: "10px" }}
          />

          <div className="d-flex justify-content-end">
            <Button variant="outline-primary" className="me-2">
              Preview Storefront
            </Button>
            <Button variant="primary">Publish Changes</Button>
          </div>
        </Card.Body>
      </Card>

      <Row className="g-4">
        {checklistItems.map((item) => (
          <Col md={6} key={item.id}>
            <Card
              className={`checklist-item ${
                completedItems.includes(item.id) ? "completed" : ""
              }`}
            >
              <Card.Body>
                <div className="d-flex align-items-start">
                  <div className="check-icon me-3">
                    {completedItems.includes(item.id) ? (
                      <div className="completed-circle">
                        <FiCheckCircle size={24} className="text-success" />
                      </div>
                    ) : (
                      <div className="incomplete-circle">
                        <FiCheckCircle size={24} className="text-muted" />
                      </div>
                    )}
                  </div>
                  <div className="flex-grow-1">
                    <h5 className="mb-1">{item.title}</h5>
                    <p className="text-muted mb-2">{item.description}</p>
                    <Button
                      variant={
                        completedItems.includes(item.id)
                          ? "outline-success"
                          : "primary"
                      }
                      size="sm"
                      onClick={() => toggleCompletion(item.id)}
                    >
                      {completedItems.includes(item.id)
                        ? "Completed"
                        : "Mark as Complete"}
                    </Button>
                  </div>
                </div>
              </Card.Body>
            </Card>
          </Col>
        ))}
      </Row>

      <Card className="mt-4">
        <Card.Header className="bg-light">
          <h5 className="mb-0">Profile Preview</h5>
        </Card.Header>
        <Card.Body>
          <Row className="g-4">
            <Col md={4}>
              <div className="profile-preview-card border rounded p-3 text-center">
                <div className="avatar-placeholder mx-auto mb-3"></div>
                <h4>Your Business Name</h4>
                <div className="rating mb-3">
                  <div className="stars">
                    {[...Array(5)].map((_, i) => (
                      <span key={i} className="star filled">
                        ★
                      </span>
                    ))}
                  </div>
                  <span className="ms-2">(24 reviews)</span>
                </div>
                <p className="text-muted">
                  Your business description will appear here...
                </p>
                <div className="d-grid gap-2">
                  <Button variant="outline-primary">Contact Vendor</Button>
                  <Button variant="primary">Check Availability</Button>
                </div>
              </div>
            </Col>
            <Col md={8}>
              <div className="preview-section mb-4">
                <h5 className="border-bottom pb-2">Gallery</h5>
                <div className="d-flex flex-wrap gap-3 mt-3">
                  {[...Array(4)].map((_, i) => (
                    <div key={i} className="gallery-preview-item"></div>
                  ))}
                </div>
              </div>

              <div className="preview-section mb-4">
                <h5 className="border-bottom pb-2">Services & Pricing</h5>
                <div className="mt-3">
                  {[...Array(3)].map((_, i) => (
                    <div
                      key={i}
                      className="d-flex justify-content-between border-bottom py-2"
                    >
                      <div>Service {i + 1}</div>
                      <div>₹ 50,000 - ₹ 1,20,000</div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="preview-section">
                <h5 className="border-bottom pb-2">Reviews</h5>
                <div className="mt-3">
                  {[...Array(2)].map((_, i) => (
                    <div key={i} className="border-bottom py-3">
                      <div className="d-flex justify-content-between">
                        <div className="fw-bold">Sarah Johnson</div>
                        <div className="text-warning">★★★★★</div>
                      </div>
                      <p className="mb-0 mt-2">
                        "Amazing service! Highly recommended."
                      </p>
                    </div>
                  ))}
                </div>
              </div>
            </Col>
          </Row>
        </Card.Body>
      </Card>
    </div>
  );
};

export default StorefrontPage;
