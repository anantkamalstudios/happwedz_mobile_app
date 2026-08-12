import React from "react";
import { Container, Row, Col, Form, Button } from "react-bootstrap";

const FindVendors = () => {
  return (
    <div
      className="hero-section"
      style={{
        backgroundImage:
          "linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url(https://cdn1.weddingwire.in/assets/img/listing-sector-banner/1.avif)",
        backgroundSize: "cover",
        backgroundPosition: "center",
        padding: "100px 0",
        color: "white",
        textAlign: "center",
      }}
    >
      <Container>
        <Row className="justify-content-center">
          <Col lg={8}>
            <h1
              className="mb-3"
              style={{
                fontSize: "2.5rem",
                fontWeight: "700",
                lineHeight: "1.2",
              }}
            >
              Find your wedding venue
            </h1>
            <p
              className="mb-5"
              style={{
                fontSize: "1.2rem",
                opacity: "0.9",
              }}
            >
              Search through a vast selection of venues to find the place that
              perfectly matches your wedding vision.
            </p>
          </Col>
        </Row>
      </Container>
    </div>
  );
};

export default FindVendors;
