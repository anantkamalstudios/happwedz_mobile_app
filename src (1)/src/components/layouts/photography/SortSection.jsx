import React from "react";
import { FaFire, FaClock } from "react-icons/fa";
import { Form, Row, Col, Container } from "react-bootstrap";
import { BiSort } from "react-icons/bi";
import { TbArrowsSort } from "react-icons/tb";
import { FiHash } from "react-icons/fi";

const SortSection = ({
  category,
  onCategoryChange,
  onSearchChange,
  sortBy,
  onSortChange,
}) => {
  return (
    <Container>
      <Row className="align-items-center justify-content-between mb-3">
        <Col
          xs={12}
          md="auto"
          className="d-flex flex-wrap align-items-center gap-2 mb-2 mb-md-0"
        >
          <span className="fw-semibold fs-16">Sort by:</span>

          <button
            className={`btn btn-sm d-flex align-items-center gap-1 fs-14 ${
              sortBy === "recent" ? "btn-primary" : "btn-outline-secondary"
            }`}
            onClick={() => onSortChange("recent")}
          >
            <BiSort />
            Recent
          </button>

          <button
            className={`btn btn-sm d-flex align-items-center gap-1 fs-14 ${
              sortBy === "trending" ? "btn-primary" : "btn-outline-secondary"
            }`}
            onClick={() => onSortChange("trending")}
          >
            <TbArrowsSort />
            Trending
          </button>

          <button className="btn btn-sm d-flex align-items-center gap-1 fs-14">
            <FiHash />
            {category}
          </button>
        </Col>

        <Col xs={12} md={6}>
          <Form.Control
            type="search"
            placeholder="Search photos..."
            className="form-control rounded-3 fs-14"
            onChange={(e) => onSearchChange(e.target.value)}
          />
        </Col>
      </Row>
    </Container>
  );
};

export default SortSection;
