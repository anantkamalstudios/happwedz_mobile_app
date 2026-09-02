import React, { useState } from "react";
import { Row, Col, Card } from "react-bootstrap";
import { FaSearch, FaStar, FaHeart, FaRegHeart } from "react-icons/fa";
import { BsLightningCharge } from "react-icons/bs";
import { LuUsers } from "react-icons/lu";
import { FaIndianRupeeSign } from "react-icons/fa6";
import Asideview from "./Asideview";
import DynamicAside from "../aside/DynamicAside";

const ListView = ({ subVenuesData, section }) => {
  const [favorites, setFavorites] = useState({});
  const [filter, setFilter] = useState("all");

  const toggleFavorite = (id) => {
    setFavorites((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const filteredVenues =
    filter === "all"
      ? subVenuesData
      : subVenuesData.filter((venue) => venue.type === filter);

  return (
    <>
      <Row>
        <Col xs={12} md={3} className="mb-4">
          <DynamicAside section={section} />
        </Col>
        <Col key={subVenuesData.id} xs={9} className="mb-4">
          <Card className="venue-card h-100 rounded-4 p-2 shadow-sm">
            {filteredVenues.map((subVenuesData) => (
              <Row>
                <Col xs={12} md={4} className="position-relative">
                  <div className="position-relative">
                    <Card.Img
                      src={subVenuesData.image}
                      alt={subVenuesData.name}
                      className="img-fluid rounded-3"
                      style={{ height: "220px", objectFit: "cover" }}
                    />

                    <button
                      className="btn-glass position-absolute top-0 end-0 m-2 rounded-circle"
                      onClick={() => toggleFavorite(subVenuesData.id)}
                    >
                      {favorites[subVenuesData.id] ? (
                        <FaHeart className="text-danger flip-icon" />
                      ) : (
                        <FaRegHeart className="text-white flip-icon" />
                      )}
                    </button>
                    <div className="price-tag">
                      <FaIndianRupeeSign /> {subVenuesData.price}
                    </div>
                  </div>
                </Col>
                <Col
                  xs={12}
                  md={8}
                  className="d-flex flex-column justify-content-between p-3"
                >
                  <div>
                    <Card.Title as="h5" className="venue-name mb-1">
                      {subVenuesData.name}
                    </Card.Title>
                    <div className="text-muted small mb-2">
                      {(subVenuesData.description || "")
                        .split(" ")
                        .slice(0, 20)
                        .join(" ")}
                      ...
                    </div>

                    <div className="text-muted small mb-2">
                      {subVenuesData.location}
                    </div>

                    <div className="d-flex justify-content-between align-items-center mb-2 flex-wrap">
                      <div className="d-flex align-items-center flex-wrap">
                        <div className="rating-badge me-3 d-flex align-items-center">
                          <FaStar className="text-warning me-1" />
                          <span>{subVenuesData.rating}</span>
                          <span className="text-muted ms-1">
                            ({subVenuesData.reviews})
                          </span>
                        </div>

                        <div className="capacity-badge d-flex align-items-center">
                          <LuUsers className="text-dark me-1" />
                          <span className="text-muted">
                            {subVenuesData.capacity}
                          </span>
                        </div>
                      </div>

                      {subVenuesData.call && (
                        <div className="text-muted small d-flex align-items-center mt-2 mt-md-0">
                          <BsLightningCharge color="orange" className="me-1" />
                          {subVenuesData.call}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="mt-2">
                    <button className="w-100 details-btn">
                      Request Pricing
                    </button>
                  </div>
                </Col>
              </Row>
            ))}
          </Card>
        </Col>
      </Row>
    </>
  );
};

export default ListView;
