import React, { useState } from "react";
import {
  Row,
  Col,
  Card,
  Button,
  Container,
  Form,
  InputGroup,
} from "react-bootstrap";
import {
  FaSearch,
  FaStar,
  FaHeart,
  FaRegHeart,
  FaFilter,
} from "react-icons/fa";
import { BsLightningCharge } from "react-icons/bs";
import { LuUsers } from "react-icons/lu";
import { FaIndianRupeeSign } from "react-icons/fa6";
import Asideview from "./Asideview";
// import { subVenuesData } from "../../../data/subVenuesData";

const GridView = ({ subVenuesData, section }) => {
  const [favorites, setFavorites] = useState({});
  const [filter, setFilter] = useState("all");

  const toggleFavorite = (id) => {
    setFavorites((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const validVenuesData = (subVenuesData || []).filter(
    (v) => v && v.image && String(v.image).trim() !== ""
  );

  const filteredVenues =
    filter === "all"
      ? validVenuesData
      : validVenuesData.filter((venue) => venue.type === filter);

  return (
    <Row>
      <Col xs={12} md={3}>
        <DynamicAside section={section} />
      </Col>
      <Col xs={12} md={9}>
        <Row className="venue-grid">
          {filteredVenues.map((v) => (
            <Col
              key={v.id}
              xs={12}
              sm={6}
              md={4}
              lg={4}
              className="mb-4 rounded-4"
            >
              <Card className="venue-card h-100 rounded-4">
                <div className="card-image-wrapper">
                  <Card.Img
                    variant="top"
                    src={v.image}
                    alt={v.name}
                    className="venue-image"
                    onError={(e) => {
                      e.target.onerror = null;
                      const cardCol = e.target.closest(".col-12, .col-sm-6, .col-lg-4, .col-md-4, .col") || e.target.closest(".card");
                      if (cardCol) {
                        cardCol.style.display = "none";
                      }
                    }}
                  />
                  <button
                    className="btn-glass position-absolute top-0 end-0 m-2 rounded-circle"
                    onClick={() => toggleFavorite(v.id)}
                  >
                    {favorites[v.id] ? (
                      <FaHeart className="text-danger flip-icon" />
                    ) : (
                      <FaRegHeart className="text-white flip-icon" />
                    )}
                  </button>

                  <div className="price-tag">
                    <FaIndianRupeeSign /> {v.price}
                  </div>
                </div>
                <Card.Body className="d-flex flex-column">
                  <Card.Title as="h5" className="venue-name">
                    {v.name}
                  </Card.Title>
                  <div className="text-muted small venue-location">
                    {v.location}
                  </div>

                  <div className="d-flex align-items-center my-2">
                    <div className="rating-badge">
                      <FaStar className="text-warning me-1" />
                      <span>{v.rating}</span>
                      <span className="text-muted ms-1">({v.reviews})</span>
                    </div>
                    <div className="ms-3 capacity-badge">
                      <span className="text-muted">
                        <LuUsers className="text-dark me-1" />
                      </span>{" "}
                      {v.capacity}
                    </div>
                  </div>

                  <div className="mt-auto">
                    <button className="w-100 details-btn">
                      Request Pricing
                    </button>
                  </div>

                  <div
                    className="text-muted small venue-location d-flex justify-content-center mt-2"
                    style={{ minHeight: "20px" }}
                  >
                    {v.call ? (
                      <div className="d-flex align-items-center">
                        <BsLightningCharge color="orange" className="me-1" />{" "}
                        {v.call}
                      </div>
                    ) : (
                      <span>&nbsp;</span>
                    )}
                  </div>
                </Card.Body>
              </Card>
            </Col>
          ))}
        </Row>
      </Col>
    </Row>
  );
};

export default GridView;
