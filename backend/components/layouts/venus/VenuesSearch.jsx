import React from "react";
import { Container, Row, Col, Form, Button, InputGroup } from "react-bootstrap";
import { CiSearch } from "react-icons/ci";
import { FaMapMarkerAlt, FaSearch } from "react-icons/fa";

const VenueSearch = ({ title }) => {
  return (
    <section className="bg-white position-relative overflow-hidden">
      <Row className="position-relative align-items-center">
        <Col
          xs={12}
          md={5}
          className="z-1 rounded-end-pill position-relative"
          style={{
            borderTopLeftRadius: "200px",
            borderBottomLeftRadius: "200px",
            background: "#fff",
            padding: "2rem 2rem",
          }}
        >
          <h1
            className="text-center mb-4"
            style={{
              fontSize: "2rem",
              fontWeight: "bold",
              color: "#333",
            }}
          >
            {title ?? "Wedding Venues"}
          </h1>

          <div
            className="search-bar p-3"
            style={{
              backgroundColor: "#f8f9fa",
              borderRadius: "50px",
              boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
            }}
          >
            <Form>
              <Row className="align-items-center">
                <Col xs={12} md={5} className="mb-2 mb-md-0">
                  <div className="d-flex align-items-center">
                    <FaSearch className="me-2" style={{ color: "#6c757d" }} />
                    <Form.Control
                      type="text"
                      placeholder="Venues"
                      style={{
                        border: "none",
                        backgroundColor: "transparent",
                        boxShadow: "none",
                      }}
                    />
                  </div>
                </Col>

                <Col xs={12} md={5} className="mb-2 mb-md-0">
                  <div className="d-flex align-items-center">
                    <FaMapMarkerAlt
                      className="me-2"
                      style={{ color: "#6c757d" }}
                    />
                    <Form.Control
                      type="text"
                      placeholder="Location"
                      style={{
                        border: "none",
                        backgroundColor: "transparent",
                        boxShadow: "none",
                      }}
                    />
                  </div>
                </Col>

                <Col xs={12} md={2}>
                  <Button
                    variant="link"
                    className="w-100 p-0 border-0 shadow-none"
                  >
                    <CiSearch className="top-venues-search" size={20} />
                  </Button>
                </Col>
              </Row>
            </Form>
          </div>
        </Col>

        <Col
          md={7}
          className="d-none d-md-flex align-items-center justify-content-center"
        >
          <img
            src="/images/venues/hero_img.png"
            alt="Wedding Table"
            className="img-fluid"
            style={{
              maxHeight: "300px",
              width: "100%",
              objectFit: "contain",
            }}
          />
        </Col>
      </Row>
    </section>
  );
};

export default VenueSearch;
