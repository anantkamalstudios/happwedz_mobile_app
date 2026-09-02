import React, { useState, useEffect } from "react";
import { FaCheck, FaSearch } from "react-icons/fa";
import { useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { Container, Row, Col } from "react-bootstrap";
import axiosInstance from "../../../../services/api/axiosInstance";
import randomColor from "randomcolor";

const Vendors = () => {
  const navigate = useNavigate();
  const [vendors, setVendors] = useState({
    booked: 0,
    total: 25,
    saved: 0,
    hired: 0,
  });

  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchCategories = async () => {
      try {
        const response = await fetch("https://happywedz.com/api/vendor-types");
        const data = await response.json();
        setCategories(data);
      } catch (error) {
        console.error("Error fetching vendor categories:", error);
      }
    };

    fetchCategories();
  }, []);

  useEffect(() => {
    const fetchBookings = async () => {
      try {
        const res = await axiosInstance.get(
          "https://happywedz.com/api/request-pricing/user/quotations"
        );
        if (res.data.success) {
          const bookedCount = res.data.quotations.length;
          setVendors((prev) => ({
            ...prev,
            booked: bookedCount,
          }));
        }
      } catch (err) {
        console.error("Error fetching bookings:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchBookings();
  }, []);

  const handleFindClick = (vendorTypeName) => {
    const encoded = encodeURIComponent(vendorTypeName);
    navigate(`/vendors/all?vendorType=${encoded}`);
  };

  const toSlug = (text) =>
    text
      ?.toLowerCase()
      .replace(/\s+/g, "-")
      .replace(/[^a-z0-9\-]/g, "") || "";

  function getLightColor() {
    return randomColor({ luminosity: "light" });
  }

  return (
    <div className="vendors-container">
      {/* <div className="vendors-header">
        <h3>My Vendors</h3>
        <div className="vendors-stats">
          <div className="stat-box">
            <span className="stat-number">{vendors.booked}</span>
            <span className="stat-label fs-14">
              OF {vendors.total} VENDORS BOOKED
            </span>
          </div>
        </div>
      </div> */}

      <div className="divider"></div>

      <Container className="m-0 p-0">
        <Row className="g-4 justify-content-center">
          {categories.map((category, index) => {
            const bgColor = getLightColor();
            return (
              <Col key={index} md={4} sm={6} xs={12}>
                <div
                  style={{
                    height: "140px",
                    width: "100%",
                    maxWidth: "500px",
                    display: "flex",
                    justifyContent: "space-between",
                    alignItems: "center",
                    backgroundColor: `${bgColor}`,
                    borderRadius: "16px",
                    boxShadow: "0 2px 8px rgba(0, 0, 0, 0.05)",
                    border: "1px solid #e0e0e0",
                    transition: "all 0.3s ease",
                    overflow: "hidden",
                    margin: "0 auto",
                    opacity: "0.7",
                  }}
                >
                  <div
                    style={{
                      width: "45%",
                      height: "100%",
                      position: "relative",
                      overflow: "hidden",
                    }}
                  >
                    <div
                      style={{
                        position: "absolute",
                        inset: "0",
                        clipPath: "ellipse(100% 100% at 0% 50%)",
                      }}
                    >
                      <img
                        src={
                          "https://happywedzbackend.happywedz.com/" +
                          category.hero_image
                        }
                        alt={category.name}
                        loading="lazy"
                        style={{
                          width: "100%",
                          height: "100%",
                          objectFit: "cover",
                          objectPosition: "center",
                          display: "block",
                        }}
                      />
                      <div
                        style={{
                          position: "absolute",
                          inset: "0",
                          backgroundColor: "rgba(0, 0, 0, 0.3)",
                        }}
                      />
                    </div>

                    <h6
                      style={{
                        position: "absolute",
                        top: "50%",
                        left: "50%",
                        transform: "translate(-50%, -50%)",
                        color: "#fff",
                        fontWeight: "600",
                        textAlign: "center",
                        textShadow: "0 2px 4px rgba(0,0,0,0.6)",
                        margin: 0,
                        zIndex: 10,
                        padding: "0 10px",
                        width: "100%",
                      }}
                    >
                      {category.name}
                    </h6>
                  </div>

                  <div
                    style={{
                      flex: 1,
                      display: "flex",
                      justifyContent: "center",
                      alignItems: "center",
                      padding: "0 15px",
                    }}
                  >
                    {category.completed ? (
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "8px",
                          padding: "10px 20px",
                          backgroundColor: "#10b981",
                          color: "#fff",
                          borderRadius: "25px",
                          fontWeight: "500",
                          fontSize: "0.9rem",
                        }}
                      >
                        <FaCheck /> Booked
                      </div>
                    ) : (
                      <button
                        onClick={() => handleFindClick(category.name)}
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "2px",
                          padding: "5px 10px",
                          backgroundColor: "#fff",
                          border: "2px solid #ec4899",
                          color: "#ec4899",
                          borderRadius: "25px",
                          fontSize: "0.7rem",
                          cursor: "pointer",
                          transition: "all 0.2s ease",
                        }}
                        onMouseEnter={(e) => {
                          e.target.style.backgroundColor = "#ec4899";
                          e.target.style.color = "#fff";
                        }}
                        onMouseLeave={(e) => {
                          e.target.style.backgroundColor = "#fff";
                          e.target.style.color = "#ec4899";
                        }}
                      >
                        Find {category.name.replaceAll("And", "&")}
                      </button>
                    )}
                  </div>
                </div>
              </Col>
            );
          })}
        </Row>
      </Container>
    </div>
  );
};

export default Vendors;
