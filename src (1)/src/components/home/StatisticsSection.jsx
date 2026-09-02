import React from "react";
import { Container, Row, Col } from "react-bootstrap";

const StatisticsSection = () => {
  const stats = [
    {
      number: "50,000+",
      label: "Happy Couples",
      icon: "💕",
      description: "Couples who found their perfect vendors",
    },
    {
      number: "10,000+",
      label: "Verified Vendors",
      icon: "🏆",
      description: "Top-rated wedding professionals",
    },
    {
      number: "500+",
      label: "Cities Covered",
      icon: "🌍",
      description: "Wedding destinations across India",
    },
    {
      number: "4.8/5",
      label: "Average Rating",
      icon: "⭐",
      description: "Based on 100,000+ reviews",
    },
  ];

  return (
    <section
      className="py-5"
      style={{
        background: "linear-gradient(135deg, #f8f9fa 0%, #ffffff 100%)",
      }}
    >
      <Container>
        <div className="text-center mb-5">
          <h2 className="fw-bold text-dark mb-3">
            Trusted by Thousands of Couples
          </h2>
          <p className="text-muted lead">
            Join the community of happy couples who found their dream wedding
            vendors
          </p>
        </div>

        <Row className="g-4">
          {stats.map((stat, index) => (
            <Col key={index} md={6} lg={3} className="text-center">
              <div className="stat-card p-4 h-100">
                <div className="stat-icon mb-3" style={{ fontSize: "3rem" }}>
                  {stat.icon}
                </div>
                <div
                  className="stat-number fw-bold text-primary mb-2"
                  style={{ fontSize: "2.5rem" }}
                >
                  {stat.number}
                </div>
                <div
                  className="stat-label fw-semibold text-dark mb-2"
                  style={{ fontSize: "1.1rem" }}
                >
                  {stat.label}
                </div>
                <div className="stat-description text-muted small">
                  {stat.description}
                </div>
              </div>
            </Col>
          ))}
        </Row>
      </Container>

      <style>{`
        .stat-card {
          background: #fff;
          border-radius: 16px;
          box-shadow: 0 4px 20px rgba(0, 0, 0, 0.08);
          transition: all 0.3s ease;
          border: 1px solid rgba(232, 53, 129, 0.1);
        }
        .stat-card:hover {
          transform: translateY(-5px);
          box-shadow: 0 8px 30px rgba(232, 53, 129, 0.15);
        }
        .stat-number {
          background: linear-gradient(135deg, #e83581, #ff6b9d);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
          background-clip: text;
        }
      `}</style>
    </section>
  );
};

export default StatisticsSection;
