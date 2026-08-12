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
import QuickInquiryModal from "../QuickInquiryModal";
// import { subVenuesData } from "../../../data/subVendorsData";

const GridView = ({ subVendorsData }) => {
  const [favorites, setFavorites] = useState({});
  const [filter, setFilter] = useState("all");
  const [showQuickInquiry, setShowQuickInquiry] = useState(false);
  const [selectedVendorId, setSelectedVendorId] = useState(null);
  const [selectedVendorName, setSelectedVendorName] = useState("");

  const toggleFavorite = (id) => {
    setFavorites((prev) => ({
      ...prev,
      [id]: !prev[id],
    }));
  };

  const validVendorsData = (subVendorsData || []).filter(
    (v) => v && v.image && String(v.image).trim() !== ""
  );

  const filteredVenues =
    filter === "all"
      ? validVendorsData
      : validVendorsData.filter((venue) => venue.type === filter);

  // Debug: Log to see if data is coming through
  console.log("GridView - filteredVenues:", filteredVenues);
  console.log("GridView - showQuickInquiry:", showQuickInquiry);

  return (
    <Row>
      {/* Left Sidebar */}
      <Col xs={12} md={3}>
        <Asideview />
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
                  
                  {/* Price tag: show venue veg/non-veg or starting price for other vendors */}
                  <div className="price-tag">
                    {v.vegPrice || v.nonVegPrice ? (
                      <>
                        {v.vegPrice && (
                          <span>
                            <FaIndianRupeeSign /> {String(v.vegPrice)}
                          </span>
                        )}
                        {v.nonVegPrice && v.vegPrice && <span className="ms-2">|</span>}
                        {v.nonVegPrice && (
                          <span className="ms-2">
                            <FaIndianRupeeSign /> {String(v.nonVegPrice)}
                          </span>
                        )}
                      </>
                    ) : v.starting_price ? (
                      <span>
                        <FaIndianRupeeSign /> {String(v.starting_price)}
                      </span>
                    ) : (
                      <span>Contact for pricing</span>
                    )}
                  </div>
                </div>
                <Card.Body className="d-flex flex-column">
                  <Card.Title as="h5" className="venue-name">
                    {v.name}
                  </Card.Title>
                  <div className="text-muted small venue-location">{v.city || v.location}</div>

                  <div className="d-flex align-items-center my-2">
                    <div className="rating-badge">
                      <FaStar className="text-warning me-1" />
                      <span>{v.rating}</span>
                      <span className="text-muted ms-1">({v.review_count || v.reviews})</span>
                    </div>
                    <div className="ms-3 capacity-badge">
                      <span className="text-muted">
                        <LuUsers className="text-dark me-1" />
                      </span>{" "}
                      {v.capacity}
                    </div>
                  </div>

                  {/* Quick Inquiry Button at Bottom */}
                  <button
                    className="w-100 mt-3"
                    style={{
                      backgroundColor: '#e83e8c',
                      color: 'white',
                      border: 'none',
                      borderRadius: '8px',
                      padding: '10px 20px',
                      fontWeight: '600',
                      fontSize: '14px',
                      cursor: 'pointer',
                      boxShadow: '0 4px 12px rgba(232, 62, 140, 0.3)',
                      transition: 'all 0.3s ease'
                    }}
                    onClick={(e) => {
                      e.stopPropagation();
                      console.log("Quick Inquiry clicked!", v);
                      setSelectedVendorId(v.vendor_id || v.id);
                      setSelectedVendorName(v.name || "");
                      setShowQuickInquiry(true);
                    }}
                    onMouseEnter={(e) => {
                      e.target.style.backgroundColor = '#c2185b';
                      e.target.style.transform = 'translateY(-2px)';
                      e.target.style.boxShadow = '0 6px 16px rgba(232, 62, 140, 0.4)';
                    }}
                    onMouseLeave={(e) => {
                      e.target.style.backgroundColor = '#e83e8c';
                      e.target.style.transform = 'translateY(0)';
                      e.target.style.boxShadow = '0 4px 12px rgba(232, 62, 140, 0.3)';
                    }}
                  >
                    ⚡ Quick Inquiry
                  </button>

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
      <QuickInquiryModal
        show={showQuickInquiry}
        handleClose={() => setShowQuickInquiry(false)}
        vendorId={selectedVendorId}
        vendorName={selectedVendorName}
      />
    </Row>
  );
};

export default GridView;
