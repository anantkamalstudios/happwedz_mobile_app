import { useState, useEffect } from "react";
import {
  FaCalendarAlt,
  FaCameraRetro,
  FaChevronLeft,
  FaGem,
  FaLandmark,
  FaMapMarkerAlt,
  FaPaintBrush,
  FaTag,
} from "react-icons/fa";
import { Container, Row, Col, Card } from "react-bootstrap";
import { FaUserEdit } from "react-icons/fa";
import { FaRegStar } from "react-icons/fa6";
import {
  FaPalette,
  FaStar,
  FaTshirt,
  FaUserTie,
  FaFemale,
} from "react-icons/fa";
import DOMPurify from "dompurify";
import { useNavigate } from "react-router-dom";
import axios from "axios";
import { useSelector } from "react-redux";

export default function WeddingPage({ post, onBackClick }) {
  const navigate = useNavigate();
  const reduxLocation = useSelector((state) => state.location.selectedLocation);
  const [loadingVendor, setLoadingVendor] = useState(null);

  const vendorTypeIcons = {
    photographers: <FaCameraRetro />,
    venues: <FaLandmark />,
    "bridal makeup": <FaPaintBrush />,
    "bridal wear": <FaTshirt />,
    jewellery: <FaGem />,
    default: <FaTag />,
  };

  const iconStyle = {
    fontSize: "1.8rem",
    color: "#C31162",
    marginRight: "1rem",
  };

  // Search for vendor and navigate to detail page
  const handleVendorClick = async (vendor) => {
    if (!vendor || !vendor.name) return;

    setLoadingVendor(vendor.name);
    try {
      let apiUrl = `https://happywedz.com/api/vendor-services?search=${encodeURIComponent(
        vendor.name
      )}&limit=10`;

      // Add city if available
      if (reduxLocation || post.city) {
        const city = reduxLocation || post.city;
        apiUrl += `&city=${encodeURIComponent(city)}`;
      }

      // Add vendor type if available
      if (vendor.type) {
        const vendorTypeMap = {
          photographers: "Photographers",
          photography: "Photographers",
          venues: "Venues",
          venue: "Venues",
          "bridal makeup": "Bridal Makeup",
          makeup: "Bridal Makeup",
          "bridal wear": "Bridal Wear",
          jewellery: "Jewellery",
          jewelry: "Jewellery",
        };

        const vendorType = vendorTypeMap[vendor.type.toLowerCase()] || vendor.type;
        apiUrl += `&vendorType=${encodeURIComponent(vendorType)}`;
      }

      const response = await axios.get(apiUrl);
      const results = response.data?.data || [];

      if (results.length > 0) {
        // Find the best match (exact name match or first result)
        const exactMatch = results.find(
          (r) =>
            r.attributes?.name?.toLowerCase() === vendor.name.toLowerCase() ||
            r.vendor?.businessName?.toLowerCase() === vendor.name.toLowerCase()
        );

        const selectedVendor = exactMatch || results[0];
        const vendorId = selectedVendor.id || selectedVendor.attributes?.id;

        if (vendorId) {
          navigate(`/details/info/${vendorId}`);
        } else {
          console.error("Vendor ID not found");
        }
      } else {
        // If no results found, try searching without filters
        const fallbackUrl = `https://happywedz.com/api/vendor-services?search=${encodeURIComponent(
          vendor.name
        )}&limit=5`;
        const fallbackResponse = await axios.get(fallbackUrl);
        const fallbackResults = fallbackResponse.data?.data || [];

        if (fallbackResults.length > 0) {
          const selectedVendor = fallbackResults[0];
          const vendorId = selectedVendor.id || selectedVendor.attributes?.id;
          if (vendorId) {
            navigate(`/details/info/${vendorId}`);
          }
        } else {
          console.error("No vendor found");
        }
      }
    } catch (error) {
      console.error("Error searching for vendor:", error);
    } finally {
      setLoadingVendor(null);
    }
  };
  useEffect(() => {
    window.scrollTo({ top: 0, behavior: "smooth" });
  }, []);
  const [isMobile, setIsMobile] = useState(
    typeof window !== "undefined" ? window.innerWidth <= 768 : false
  );

  useEffect(() => {
    const onResize = () => setIsMobile(window.innerWidth <= 768);
    onResize();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, []);
  return (
    <div>
      {/* Hero Section - FIXED */}
      <div
        className="position-relative text-center text-white"
        style={{
          backgroundImage: `url(${post.coverPhoto})`,
          backgroundSize: "cover",
          backgroundPosition: "center",
          height: isMobile ? "320px" : "500px",
        }}
      >
        {/* Back Button - FIXED positioning */}
        <button
          className="btn btn-light position-absolute d-flex align-items-center justify-content-center"
          onClick={onBackClick}
          aria-label="Back"
          style={{
            top: isMobile ? "1rem" : "2rem",
            left: isMobile ? "1rem" : "2rem",
            height: isMobile ? "40px" : "50px",
            width: isMobile ? "40px" : "50px",
            borderRadius: "50%",
            zIndex: 10,
            fontSize: isMobile ? "0.9rem" : "1rem",
          }}
        >
          <FaChevronLeft />
        </button>

        {/* Content Overlay - FIXED */}
        <div
          className="position-absolute top-50 start-50 translate-middle d-flex flex-column align-items-center justify-content-center"
          style={{
            borderRadius: "10px",
            width: isMobile ? "90%" : "70%",
            maxWidth: "900px",
            minHeight: isMobile ? "180px" : "300px",
            padding: isMobile ? "1rem 0.75rem" : "2rem",
            backgroundColor: "rgba(0, 0, 0, 0.35)",
            backdropFilter: "blur(4px)",
            gap: isMobile ? "0.5rem" : "1rem",
          }}
        >
          <h2
            className="fw-bold display-5 text-white"
            style={{
              color: "#fff",
              fontSize: isMobile ? "1.6rem" : "3.5rem",
              letterSpacing: "1px",
              wordSpacing: "3px",
              fontWeight: "600",
              margin: 0,
              textAlign: "center",
              padding: isMobile ? "0 0.5rem" : "0",
            }}
          >
            {post.brideName} and {post.groomName}
          </h2>
          <p
            className="mb-0"
            style={{
              fontSize: isMobile ? "0.85rem" : "1.75rem",
              fontWeight: isMobile ? "400" : "normal",
              textAlign: "center",
            }}
          >
            {post.weddingDate} – {post.city}
          </p>

          {/* Story Preview - FIXED responsive text */}
          {post.story && (
            <p
              className="mb-0"
              style={{
                fontSize: isMobile ? "0.8rem" : "1rem",
                lineHeight: "1.4",
                textAlign: "center",
                padding: isMobile ? "0 0.5rem" : "0",
              }}
            >
              <span
                dangerouslySetInnerHTML={{
                  __html: DOMPurify.sanitize(
                    post?.story?.slice(0, isMobile ? 80 : 100) || ""
                  ),
                }}
              />
              <button
                type="button"
                className="btn p-0 ms-2 text-white text-decoration-underline"
                onClick={() =>
                  document
                    .getElementById("love-story")
                    ?.scrollIntoView({ behavior: "smooth" })
                }
                style={{
                  fontSize: isMobile ? "0.8rem" : "1rem",
                  background: "none",
                  border: "none",
                  cursor: "pointer",
                }}
              >
                Read More
              </button>
            </p>
          )}
        </div>
      </div>

      {/* Couples Bio */}
      <Container className="my-5">
        <h3
          className="text-center mb-4"
          style={{ color: "#C31162", fontWeight: 600 }}
        >
          Couple Bio
        </h3>

        <Row className="align-items-start">
          {/* Groom Bio */}
          <Col md={6} className="mb-4 mb-md-0">
            <div
              className="p-4 rounded shadow-sm h-100"
              style={{
                backgroundColor: "#fffafc",
                border: "1px solid #C3116230",
              }}
            >
              <div className="d-flex align-items-center justify-content-center mb-3">
                <FaUserEdit
                  size={22}
                  color="#C31162"
                  className="me-2"
                  style={{ minWidth: "22px" }}
                />
                <h5 className="mb-0" style={{ color: "#C31162" }}>
                  {post.groomName}
                </h5>
              </div>
              <p className="mb-0 text-muted" style={{ lineHeight: "1.6" }}>
                {post.groomBio}
              </p>
            </div>
          </Col>

          {/* Bride Bio */}
          <Col md={6}>
            <div
              className="p-4 rounded shadow-sm h-100"
              style={{
                backgroundColor: "#fffafc",
                border: "1px solid #C3116230",
              }}
            >
              <div className="d-flex align-items-center justify-content-center mb-3">
                <FaUserEdit
                  size={22}
                  color="#C31162"
                  className="me-2"
                  style={{ minWidth: "22px" }}
                />
                <h5 className="mb-0" style={{ color: "#C31162" }}>
                  {post.brideName}
                </h5>
              </div>
              <p className="mb-0 text-muted" style={{ lineHeight: "1.6" }}>
                {post.brideBio}
              </p>
            </div>
          </Col>
        </Row>
      </Container>

      {/* Photo Gallery */}
      <div className="container my-5">
        <h3 className="mb-3 fw-semibold">Photo Gallery</h3>

        <div
          className="p-2 mb-3"
          style={{ backgroundColor: "#f8d7da", borderRadius: "6px" }}
        >
          <span className="fw-semibold text-danger">Top Photos</span>
        </div>

        <div className="row g-3">
          {post.highlightPhotos && post.highlightPhotos.length > 0 ? (
            post.highlightPhotos.map((src, i) => (
              <div className="col-6 col-md-3" key={i}>
                <img
                  src={src}
                  className="img-fluid rounded"
                  loading="lazy"
                  style={{
                    objectFit: "contain",
                    width: "100%",
                    height: "200px",
                  }}
                  alt="highlight"
                />
              </div>
            ))
          ) : (
            <p className="text-muted">No highlight photos available</p>
          )}
        </div>
      </div>

      {/* Love story */}
      <Container className="my-5" id="love-story">
        <style>
          {`
            @keyframes gradientMove {
              0% { background-position: 0% 50%; }
              50% { background-position: 100% 50%; }
              100% { background-position: 0% 50%; }
            }
          `}
        </style>

        <h3
          className="text-center mb-4"
          style={{ color: "#C31162", fontWeight: 600 }}
        >
          Their Love Story
        </h3>

        <div
          className="mx-auto text-center"
          style={{
            position: "relative",
            maxWidth: "800px",
            borderRadius: "16px",
            padding: "2rem",
            background: "#fff",
            boxShadow: "0 6px 18px rgba(0,0,0,0.1)",
            zIndex: 1,
          }}
        >
          <div
            className="primary-light-bg text-black"
            style={{
              content: "",
              position: "absolute",
              inset: "-3px",
              borderRadius: "18px",
              padding: "3px",
              backgroundSize: "400% 400%",
              animation: "gradientMove 6s ease infinite",
              zIndex: -1,
            }}
          ></div>

          <div
            className="mb-0 text-justify"
            style={{ fontSize: "1.1rem", lineHeight: "1.8" }}
            dangerouslySetInnerHTML={{
              __html: DOMPurify.sanitize(
                post.story
                  ? post.story
                    .replace(
                      /<\/?(span|font|style|script|div|pre)[^>]*>/gi,
                      ""
                    )
                    .replace(/<(p|br|hr|h[1-6])\b[^>]*>/gi, "")
                    .replace(/<\/(p|br|hr|h[1-6])>/gi, "")
                  : ""
              ),
            }}
          ></div>
        </div>
      </Container>

      {/* Highlights */}
      <Container className="my-4">
        <h2
          style={{
            color: "#C31162",
            fontWeight: "bold",
            textAlign: "center",
            marginBottom: "30px",
          }}
        >
          Highlights
        </h2>
        <Row>
          {post.highlightPhotos.map((photo, index) => (
            <Col key={index} md={4} className="mb-4">
              <Card
                style={{
                  border: "none",
                  boxShadow: "0 4px 8px rgba(0,0,0,0.1)",
                }}
              >
                <Card.Img
                  variant="top"
                  src={photo}
                  loading="lazy"
                  alt={`Highlight ${index + 1}`}
                  style={{
                    width: "100%",
                    height: "250px",
                    objectFit: "contain",
                    borderRadius: "10px",
                  }}
                />
              </Card>
            </Col>
          ))}
        </Row>
      </Container>

      {/* Events */}
      <Container className="my-5">
        <h3
          className="text-center mb-4"
          style={{ color: "#C31162", fontWeight: 600 }}
        >
          Wedding Events
        </h3>

        <Row className="g-4">
          {post.events?.map((event, index) => (
            <Col md={4} key={index}>
              <div className="card shadow-sm h-100">
                <div className="card-body">
                  <h5
                    className="card-title d-flex align-items-center"
                    style={{ color: "#C31162" }}
                  >
                    <FaRegStar className="me-2" /> {event.name}
                  </h5>
                  <p className="card-text mb-2 d-flex align-items-center">
                    <FaCalendarAlt color="#C31162" className="me-2" />
                    {event.date}
                  </p>
                  <p className="card-text d-flex align-items-center">
                    <FaMapMarkerAlt color="#C31162" className="me-2" />
                    {event.venue}
                  </p>
                </div>
              </div>
            </Col>
          ))}
        </Row>
      </Container>

      {/* Special highlighted */}
      <Container className="my-5">
        <h3
          className="text-center mb-4"
          style={{ color: "#C31162", fontWeight: 600 }}
        >
          Special Highlights
        </h3>

        <div className="d-flex flex-wrap justify-content-center gap-2 mb-5">
          {post.themes?.map((theme, index) => (
            <span
              key={index}
              className="badge d-flex align-items-center px-3 py-2"
              style={{
                backgroundColor: "#fff0f6",
                color: "#C31162",
                fontSize: "0.95rem",
                border: "1px solid #C31162",
                borderRadius: "20px",
              }}
            >
              <FaPalette className="me-2" /> {theme}
            </span>
          ))}
        </div>

        <Row className="g-4">
          <Col md={6}>
            <div
              className="p-4 rounded shadow-sm h-100"
              style={{
                backgroundColor: "#fffafc",
                border: "1px solid #C3116230",
              }}
            >
              <h5
                className="mb-3 d-flex align-items-center"
                style={{ color: "#C31162" }}
              >
                <FaStar className="me-2" /> Special Moments
              </h5>
              <p className="mb-0 text-muted" style={{ lineHeight: "1.6" }}>
                {post.specialMoments || "Their most cherished wedding moments"}
              </p>
            </div>
          </Col>

          <Col md={6}>
            <div
              className="p-4 rounded shadow-sm h-100"
              style={{
                backgroundColor: "#fffafc",
                border: "1px solid #C3116230",
              }}
            >
              <h5
                className="mb-3 d-flex align-items-center"
                style={{ color: "#C31162" }}
              >
                <FaTshirt className="me-2" /> Outfit Details
              </h5>

              <div className="mb-3">
                <h6
                  className="mb-1 d-flex align-items-center"
                  style={{ color: "#C31162" }}
                >
                  <FaUserTie className="me-2" /> Groom
                </h6>
                <p className="mb-0 text-muted">
                  {post.groomOutfit || "Groom outfit details here."}
                </p>
              </div>

              <div>
                <h6
                  className="mb-1 d-flex align-items-center"
                  style={{ color: "#C31162" }}
                >
                  <FaFemale className="me-2" /> Bride
                </h6>
                <p className="mb-0 text-muted">
                  {post.brideOutfit || "Bride outfit details here."}
                </p>
              </div>
            </div>
          </Col>
        </Row>
      </Container>

      {/* Tagged Vendors */}
      <Container className="container mb-5">
        <h4 className="mb-4 fw-semibold">Tagged Vendors</h4>
        <Row className="g-4">
          {post.vendors && post.vendors.length > 0 ? (
            post.vendors.map((vendor, i) => {
              const typeKey = vendor.type?.toLowerCase() || "";
              const icon = vendorTypeIcons[typeKey] || vendorTypeIcons.default;
              const isLoading = loadingVendor === vendor.name;

              return (
                <Col xs={12} md={6} lg={4} key={i}>
                  <Card
                    className="border-0 shadow-sm h-100"
                    style={{
                      cursor: isLoading ? "wait" : "pointer",
                      transition: "all 0.3s ease",
                      opacity: isLoading ? 0.7 : 1,
                    }}
                    onClick={() => !isLoading && handleVendorClick(vendor)}
                    onMouseEnter={(e) => {
                      if (!isLoading) {
                        e.currentTarget.style.transform = "translateY(-4px)";
                        e.currentTarget.style.boxShadow =
                          "0 8px 16px rgba(195, 17, 98, 0.2)";
                      }
                    }}
                    onMouseLeave={(e) => {
                      e.currentTarget.style.transform = "translateY(0)";
                      e.currentTarget.style.boxShadow = "0 2px 4px rgba(0,0,0,0.1)";
                    }}
                  >
                    <Card.Body className="d-flex align-items-center">
                      <div style={iconStyle}>{icon}</div>
                      <div className="flex-grow-1">
                        <Card.Title
                          style={{ fontSize: "1.1rem", marginBottom: "0.2rem" }}
                        >
                          {vendor.name}
                          {isLoading && (
                            <span
                              className="spinner-border spinner-border-sm ms-2"
                              role="status"
                              style={{
                                width: "0.8rem",
                                height: "0.8rem",
                                borderWidth: "0.15rem",
                                color: "#C31162",
                              }}
                            >
                              <span className="visually-hidden">Loading...</span>
                            </span>
                          )}
                        </Card.Title>
                        <Card.Text className="text-muted small mb-0">
                          {vendor.type}
                        </Card.Text>
                      </div>
                    </Card.Body>
                  </Card>
                </Col>
              );
            })
          ) : (
            <p className="text-muted">No vendors tagged</p>
          )}
        </Row>
      </Container>
    </div>
  );
}
