import React, { useState } from "react";
import { Container, Row, Col, Form, Button } from "react-bootstrap";

const NewsletterSection = () => {
  const [email, setEmail] = useState("");
  const [isSubscribed, setIsSubscribed] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (email) {
      setIsSubscribed(true);
      setEmail("");
      setTimeout(() => setIsSubscribed(false), 3000);
    }
  };

  return (
    <section
      className="py-5"
      style={{
        background:
          "linear-gradient(135deg, #e83581 0%, #ff6b9d 50%, #ff8fab 100%)",
        position: "relative",
        overflow: "hidden",
      }}
    >
      {/* Background Pattern */}
      <div
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          background: `
            radial-gradient(circle at 20% 80%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
            radial-gradient(circle at 80% 20%, rgba(255, 255, 255, 0.1) 0%, transparent 50%),
            radial-gradient(circle at 40% 40%, rgba(255, 255, 255, 0.05) 0%, transparent 50%)
          `,
          pointerEvents: "none",
        }}
      />

      <Container className="position-relative" style={{ zIndex: 2 }}>
        <Row className="justify-content-center text-center">
          <Col lg={8}>
            <div className="newsletter-content text-white">
              <h2 className="fw-bold mb-3">Stay Updated with Wedding Trends</h2>
              <p className="lead mb-4 opacity-90">
                Get the latest wedding inspiration, vendor recommendations, and
                exclusive offers delivered to your inbox
              </p>

              <Form onSubmit={handleSubmit} className="newsletter-form">
                <Row className="g-3 justify-content-center">
                  <Col md={6} lg={5}>
                    <Form.Control
                      type="email"
                      placeholder="Enter your email address"
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      className="form-control-lg"
                      required
                      style={{
                        border: "none",
                        borderRadius: "50px",
                        padding: "12px 20px",
                        fontSize: "16px",
                      }}
                    />
                  </Col>
                  <Col md={4} lg={3}>
                    <Button
                      type="submit"
                      className="btn btn-light btn-lg w-100"
                      style={{
                        borderRadius: "50px",
                        fontWeight: "600",
                        color: "#e83581",
                      }}
                    >
                      {isSubscribed ? "✓ Subscribed!" : "Subscribe"}
                    </Button>
                  </Col>
                </Row>
              </Form>

              {isSubscribed && (
                <div className="mt-3">
                  <small className="text-white opacity-75">
                    🎉 Thank you for subscribing! Check your email for
                    confirmation.
                  </small>
                </div>
              )}

              <div className="newsletter-benefits mt-4">
                <Row className="g-3 text-center">
                  <Col md={4}>
                    <div className="benefit-item">
                      <div className="benefit-icon mb-2">📧</div>
                      <small className="opacity-90">Weekly Inspiration</small>
                    </div>
                  </Col>
                  <Col md={4}>
                    <div className="benefit-item">
                      <div className="benefit-icon mb-2">🎁</div>
                      <small className="opacity-90">Exclusive Offers</small>
                    </div>
                  </Col>
                  <Col md={4}>
                    <div className="benefit-item">
                      <div className="benefit-icon mb-2">💡</div>
                      <small className="opacity-90">Planning Tips</small>
                    </div>
                  </Col>
                </Row>
              </div>

              <div className="newsletter-trust mt-4">
                <small className="opacity-75">
                  🔒 We respect your privacy. Unsubscribe anytime.
                </small>
              </div>
            </div>
          </Col>
        </Row>
      </Container>

      <style>{`
        .newsletter-form .form-control:focus {
          box-shadow: 0 0 0 0.2rem rgba(255, 255, 255, 0.25);
          border-color: transparent;
        }
        .newsletter-form .btn-light:hover {
          background-color: #f8f9fa;
          transform: translateY(-1px);
          box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
        }
        .benefit-item {
          padding: 1rem;
          background: rgba(255, 255, 255, 0.1);
          border-radius: 12px;
          backdrop-filter: blur(10px);
          transition: all 0.3s ease;
        }
        .benefit-item:hover {
          background: rgba(255, 255, 255, 0.15);
          transform: translateY(-2px);
        }
        .benefit-icon {
          font-size: 1.5rem;
        }
        @media (max-width: 768px) {
          .newsletter-form .form-control,
          .newsletter-form .btn {
            border-radius: 12px !important;
          }
        }
      `}</style>
    </section>
  );
};

export default NewsletterSection;
