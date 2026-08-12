import React from "react";
import { Container, Row, Col, Card } from "react-bootstrap";
import { FaCheckCircle } from "react-icons/fa";
import { factors, findfactors } from "../../../data/FactorsList";

const FactorsList = () => {
  return (
    <div className="factors-wrapper py-5">
      <Container>
        <div className="text-center mb-5">
          <h2 className="factors-title">
            12 Key Factors Before Choosing Your Wedding Venue
          </h2>
          <p className="factors-subtitle">
            Finding the most perfect venue for your wedding ceremonies and
            celebrations can be overwhelming — but we're here to help you make
            the right choice.
          </p>
        </div>

        <Row className="gy-4">
          {factors.map((item, index) => (
            <Col key={index} md={6}>
              <Card className="factors-card shadow-sm border-0 h-100">
                <Card.Body>
                  <div className="d-flex align-items-start">
                    <FaCheckCircle className="factors-icon me-3" />
                    <div>
                      <h5 className="factors-heading">{item.title}</h5>
                      <p className="factors-content">{item.content}</p>
                    </div>
                  </div>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>

        <div className="mt-5 text-center">
          <h2 className="factors-title">
            How to Find the Perfect Wedding Venue
          </h2>
        </div>
        <Row className="gy-4 mt-3">
          {findfactors.map((item, index) => (
            <Col key={index} md={12}>
              <Card className="factors-info-card shadow-sm border-0">
                <Card.Body>
                  <p className="factors-content">{item.content}</p>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
      </Container>
    </div>
  );
};

export default FactorsList;
