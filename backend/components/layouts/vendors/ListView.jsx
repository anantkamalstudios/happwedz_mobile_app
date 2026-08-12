import React, { useState } from "react";
import { Row, Col, Card } from "react-bootstrap";
import { FaSearch, FaStar, FaHeart, FaRegHeart } from "react-icons/fa";
import { BsLightningCharge } from "react-icons/bs";
import { LuUsers } from "react-icons/lu";
import { FaIndianRupeeSign } from "react-icons/fa6";
import Asideview from "./Asideview";
import QuickInquiryModal from "../QuickInquiryModal";

const ListView = ({ subVendorsData }) => {
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

  const filteredVenues =
    filter === "all"
      ? subVendorsData
      : subVendorsData.filter((venue) => venue.type === filter);

  return (
    <>
      <Row>
        <Col xs={12} md={3} className="mb-4">
          <Asideview />
        </Col>
        <Col key={subVendorsData.id} xs={9} className="mb-4">
          <Card className="venue-card h-100 rounded-4 p-2 shadow-sm">
            {filteredVenues.map((subVendorsData) => (
              <Row>
                <Col xs={12} md={4} className="position-relative">
                  <div className="position-relative">
                    <Card.Img
                      src={subVendorsData.image}
                      alt={subVendorsData.name}
                      className="img-fluid rounded-3"
                      style={{ height: "220px", objectFit: "cover" }}
                    />

                    <button
                      className="btn-glass position-absolute top-0 end-0 m-2 rounded-circle"
                      onClick={() => toggleFavorite(subVendorsData.id)}
                    >
                      {favorites[subVendorsData.id] ? (
                        <FaHeart className="text-danger flip-icon" />
                      ) : (
                        <FaRegHeart className="text-white flip-icon" />
                      )}
                    </button>
                    <div className="price-tag">
                      <FaIndianRupeeSign /> {subVendorsData.price}
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
                      {subVendorsData.name}
                    </Card.Title>
                    <div className="text-muted small mb-2">
                      {(subVendorsData.description || "")
                        .split(" ")
                        .slice(0, 20)
                        .join(" ")}
                      ...
                    </div>

                    <div className="text-muted small mb-2">
                      {subVendorsData.location}
                    </div>

                    <div className="d-flex justify-content-between align-items-center mb-2 flex-wrap">
                      <div className="d-flex align-items-center flex-wrap">
                        <div className="rating-badge me-3 d-flex align-items-center">
                          <FaStar className="text-warning me-1" />
                          <span>{subVendorsData.rating}</span>
                          <span className="text-muted ms-1">
                            ({subVendorsData.reviews})
                          </span>
                        </div>

                        <div className="capacity-badge d-flex align-items-center">
                          <LuUsers className="text-dark me-1" />
                          <span className="text-muted">
                            {subVendorsData.capacity}
                          </span>
                        </div>
                      </div>

                      {subVendorsData.call && (
                        <div className="text-muted small d-flex align-items-center mt-2 mt-md-0">
                          <BsLightningCharge color="orange" className="me-1" />
                          {subVendorsData.call}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="mt-2">
                    <button 
                      className="w-100 details-btn"
                      onClick={() => {
                        setSelectedVendorId(v.vendor_id || v.id);
                        setSelectedVendorName(v.name || "");
                        setShowQuickInquiry(true);
                      }}
                    >
                      ⚡ Quick Inquiry
                    </button>
                  </div>
                </Col>
              </Row>
            ))}
          </Card>
        </Col>
      </Row>
      <QuickInquiryModal
        show={showQuickInquiry}
        handleClose={() => setShowQuickInquiry(false)}
        vendorId={selectedVendorId}
        vendorName={selectedVendorName}
      />
    </>
  );
};

export default ListView;
