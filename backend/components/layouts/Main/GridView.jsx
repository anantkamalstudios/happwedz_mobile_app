import React, { useState, useEffect } from "react";
import { Row, Col, Card, Container } from "react-bootstrap";
import { FaStar, FaHeart, FaRegHeart } from "react-icons/fa";
import { FaMapMarkerAlt } from "react-icons/fa";
import { TbView360Number } from "react-icons/tb";
import { useDispatch, useSelector } from "react-redux";
import { Link, useNavigate } from "react-router-dom";
import { toggleWishlist } from "../../../redux/authSlice";
import QuickInquiryModal from "../QuickInquiryModal";
import { trackView } from "../../../services/localStorageService";
import { prioritizeRecentlyViewed, isRecentlyViewed } from "../../../utils/recentlyViewedHelper";

const extractMainCity = (rawCity) => {
  if (!rawCity) return "all";
  let cleaned = rawCity.replace(/\bdistricts?\b/i, "").trim();
  const parts = cleaned.split(",");
  if (parts.length > 1) {
    return parts[parts.length - 1].trim();
  }
  return cleaned;
};

const slugifyCity = (city) => {
  if (!city) return "all";
  return city
    .toString()
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
};

const cleanVenueSlug = (name) => {
  if (!name) return "";
  return name
    .toString()
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s-]/g, "")
    .replace(/\s+/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-+|-+$/g, "");
};

const isValidImage = (url) => {
  if (!url || typeof url !== "string") return false;
  const lower = url.toLowerCase().trim();
  if (
    !lower ||
    lower.includes("imagenotfound") ||
    lower.includes("image_not_found") ||
    lower.includes("no-image") ||
    lower.includes("no_image") ||
    lower.includes("placeholder")
  ) {
    return false;
  }
  return true;
};

const GridView = ({ subVenuesData, handleShow, colLg, fluid, currentCity }) => {
  const [favorites, setFavorites] = useState({});
  const [wishlistIds, setWishlistIds] = useState(new Set());
  const [showQuickInquiry, setShowQuickInquiry] = useState(false);
  const [selectedVendorId, setSelectedVendorId] = useState(null);
  const [selectedVendorName, setSelectedVendorName] = useState("");
  const [displayData, setDisplayData] = useState([]);
  const dispatch = useDispatch();
  const { token } = useSelector((state) => state.auth);
  const navigate = useNavigate();

  // Reorder: recently viewed first, then rest
  useEffect(() => {
    const validWithImages = (subVenuesData || []).filter(
      (item) => item && isValidImage(item.image)
    );
    if (validWithImages.length > 0) {
      const reordered = prioritizeRecentlyViewed(validWithImages);
      setDisplayData(reordered);
    } else {
      setDisplayData([]);
    }
  }, [subVenuesData]);

  // Fetch wishlist on component mount to initialize favorites
  useEffect(() => {
    if (!token) {
      setFavorites({});
      setWishlistIds(new Set());
      return;
    }

    const fetchWishlist = async () => {
      try {
        const res = await fetch(`https://happywedz.com/api/wishlist`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        const data = await res.json();

        if (data.success && data.data && data.data.length > 0) {
          const ids = new Set(data.data.map((item) => item.vendor_services_id));
          setWishlistIds(ids);
          // Initialize favorites state from fetched wishlist
          const favoritesObj = {};
          ids.forEach((id) => {
            favoritesObj[id] = true;
          });
          setFavorites(favoritesObj);
        } else {
          setWishlistIds(new Set());
          setFavorites({});
        }
      } catch (error) {
        console.error("Error fetching wishlist:", error);
        setWishlistIds(new Set());
        setFavorites({});
      }
    };

    fetchWishlist();
  }, [token, subVenuesData]);

  const isFavorite = (vendorId) => {
    return favorites[vendorId] === true || wishlistIds.has(vendorId);
  };

  const toggleFavorite = async (venue, e) => {
    e.preventDefault();
    e.stopPropagation();

    // Optimistically update UI
    const wasFavorite = isFavorite(venue.id);
    setFavorites((prev) => ({
      ...prev,
      [venue.id]: !wasFavorite,
    }));

    // Update wishlistIds set
    setWishlistIds((prev) => {
      const newSet = new Set(prev);
      if (wasFavorite) {
        newSet.delete(venue.id);
      } else {
        newSet.add(venue.id);
      }
      return newSet;
    });

    dispatch(toggleWishlist(venue));

    // Track wishlist interaction when adding
    if (!wasFavorite && token) {
      try {
        await fetch(`https://happywedz.com/api/interactions/add`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            vendor_subcategory_data_id: venue.id,
            action: "wishlist",
          }),
        });
      } catch (error) {
        console.error("Error tracking wishlist interaction:", error);
      }
    }
  };

  const handleCardClick = async (venue) => {
    // Track to localStorage on click (works without auth)
    trackView({
      id: venue.id,
      name: venue.name,
      category: venue.vendor_type || venue.category,
      type: venue.vendor_type || 'vendor',
      location: venue.city || venue.address || venue.location,
      image: venue.image,
      price_range: venue.starting_price || venue.vegPrice || venue.nonVegPrice,
      slug: venue.slug || venue.id
    });

    if (token) {
      try {
        await fetch(`https://happywedz.com/api/interactions/add`, {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            vendor_subcategory_data_id: venue.id,
            action: "click",
          }),
        });
      } catch (error) {
        console.error("Error tracking click:", error);
      }
    }
    const mainCity = extractMainCity(currentCity || venue.city || venue.location);
    const citySlug = slugifyCity(mainCity);
    const cleanedSlug = cleanVenueSlug(venue.name);
    const isVenue = window.location.pathname.includes("/venues") || window.location.pathname.includes("/wedding-venues");
    if (isVenue) {
      navigate(`/wedding-venues/${citySlug}/${cleanedSlug}`);
    } else {
      const pathSegments = window.location.pathname.split("/");
      const categorySlug = pathSegments[2] || (venue.category ? venue.category.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "") : "all");
      navigate(`/vendors/${categorySlug}/${citySlug || "all"}/${cleanedSlug}`);
    }
  };

  return (
    <Container fluid={fluid}>
      <Row>
        {displayData && displayData.length > 0 ? (
          displayData.map((venue) => {
            const wasViewed = isRecentlyViewed(venue.id);
            return (
            <Col key={venue.id} xs={12} sm={6} lg={colLg || 4} className="mb-4 d-flex">
              <Card
                className="border-0 main-grid-cards rounded-4 overflow-hidden p-2 h-100 d-flex flex-column w-100"
                onClick={() => handleCardClick(venue)}
                style={{ cursor: "pointer" }}
              >
                <div className="position-relative flex-shrink-0" style={{ height: "240px" }}>
                  <Card.Img
                    key={`${venue.id}-${venue.image}`}
                    variant="top"
                    src={venue.image || "/images/imageNotFound.jpg"}
                    loading="eager"
                    alt={`${venue.name}${venue.vendor_type || venue.category ? ` - ${venue.vendor_type || venue.category}` : ""}${venue.city ? ` in ${extractMainCity(venue.city) || venue.city}` : ""}`}
                    style={{
                      objectFit: "cover",
                      height: "100%",
                      width: "100%",
                      borderRadius: "15px",
                      display: "block",
                    }}
                    onError={(e) => {
                      e.target.onerror = null;
                      const cardCol = e.target.closest(".col-12, .col-sm-6, .col-lg-4, .col-md-4, .col") || e.target.closest(".card");
                      if (cardCol) {
                        cardCol.style.display = "none";
                      }
                    }}
                  />

                  {/* Recently Viewed Badge */}
                  {wasViewed && (
                    <div
                      style={{
                        position: "absolute",
                        bottom: "10px",
                        left: "10px",
                        background: "rgba(231, 76, 60, 0.92)",
                        color: "white",
                        padding: "4px 10px",
                        borderRadius: "20px",
                        fontSize: "11px",
                        fontWeight: "600",
                        display: "flex",
                        alignItems: "center",
                        gap: "4px",
                        backdropFilter: "blur(4px)",
                        zIndex: 2,
                      }}
                    >
                      👁️ Recently Viewed
                    </div>
                  )}

                  {((venue.vendor_type || "").toLowerCase().includes("venue") ||
                    venue.vegPrice !== null ||
                    venue.nonVegPrice !== null) && (
                    <button
                      className="btn btn-light position-absolute rounded-circle border-0 shadow-sm"
                      style={{
                        top: "12px",
                        left: "12px",
                        width: "36px",
                        height: "36px",
                        padding: "0",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                      onClick={(e) => {
                        e.stopPropagation();
                      }}
                    >
                      <TbView360Number className="text-dark" size={18} />
                    </button>
                  )}

                  <button
                    className="btn btn-light position-absolute rounded-circle border-0 shadow-sm"
                    style={{
                      top: "12px",
                      right: "12px",
                      width: "36px",
                      height: "36px",
                      padding: "0",
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                    onClick={(e) => toggleFavorite(venue, e)}
                  >
                    {isFavorite(venue.id) ? (
                      <FaHeart className="text-danger" size={18} />
                    ) : (
                      <FaRegHeart className="text-dark" size={18} />
                    )}
                  </button>
                </div>

                {/* Card Body */}
                <Card.Body className="p-3 d-flex flex-column flex-grow-1 justify-content-between">
                  <Link
                    className="text-decoration-none d-flex flex-column flex-grow-1 justify-content-between"
                  >
                    <div>
                      {/* Title and Rating Row */}
                      <div className="d-flex justify-content-between align-items-start mb-2">
                        <Card.Title
                          className="mb-0 fw-bold text-dark fs-18 flex-grow-1 pe-2"
                          style={{
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                            minHeight: "44px",
                            maxHeight: "44px",
                            lineHeight: "1.25",
                          }}
                          title={venue.name || "Venue Name"}
                        >
                          {venue.name || "Venue Name"}
                        </Card.Title>
                        <div className="d-flex align-items-center gap-1 flex-shrink-0">
                          <FaStar size={14} className="text-warning" />
                          <span
                            className="fw-semibold text-dark"
                            style={{ fontSize: "13px" }}
                          >
                            {venue.rating || "0.0"}
                          </span>
                          <span
                            className="text-muted"
                            style={{ fontSize: "12px" }}
                          >
                            ({venue.review_count || "0"})
                          </span>
                        </div>
                      </div>

                      {/* subtitle */}
                      {(venue.subtitle || venue.tagline) && (
                        <div
                          className="text-muted mb-2 text-truncate"
                          style={{ fontSize: "13px", height: "20px" }}
                        >
                          {venue.subtitle || venue.tagline}
                        </div>
                      )}

                      {/* Location */}
                      <div
                        className="text-muted mb-3 d-flex align-items-center text-truncate"
                        style={{ fontSize: "13px", height: "22px" }}
                      >
                        <FaMapMarkerAlt className="me-1 flex-shrink-0" />
                        <span className="text-truncate">
                          {venue.city || venue.address || "Location not available"}
                        </span>
                      </div>
                    </div>

                    <div>
                      {/* Price Row */}
                      <div className="d-flex justify-content-between align-items-center mb-3" style={{ minHeight: "38px" }}>
                        {venue.vegPrice || venue.nonVegPrice ? (
                          <>
                            {venue.vegPrice !== null &&
                              venue.vegPrice !== undefined && (
                                <div className="d-flex flex-column">
                                  <span
                                    className="text-muted"
                                    style={{ fontSize: "12px" }}
                                  >
                                    Veg
                                  </span>
                                  <span
                                    className="fw-bold text-dark"
                                    style={{ fontSize: "15px" }}
                                  >
                                    ₹ {String(venue.vegPrice.replace("Rs.", ""))}
                                  </span>
                                </div>
                              )}
                            {venue.nonVegPrice !== null &&
                              venue.nonVegPrice !== undefined && (
                                <div className="d-flex flex-column text-end">
                                  <span
                                    className="text-muted"
                                    style={{ fontSize: "12px" }}
                                  >
                                    Non-Veg
                                  </span>
                                  <span
                                    className="fw-bold text-dark"
                                    style={{ fontSize: "15px" }}
                                  >
                                    ₹{" "}
                                    {String(venue.nonVegPrice.replace("Rs.", ""))}
                                  </span>
                                </div>
                              )}
                          </>
                        ) : (
                          <div>
                            <span
                              className="fw-bold text-dark"
                              style={{ fontSize: "15px" }}
                            >
                              {venue.starting_price
                                ? `₹ ${String(
                                    venue.starting_price.replace("Rs.", "")
                                  )}`
                                : "Contact for pricing"}
                            </span>
                          </div>
                        )}
                      </div>

                      {/* Bottom Info Pills */}
                      <div className="d-flex gap-2 flex-wrap mb-3" style={{ minHeight: "30px" }}>
                        {venue.capacity && (
                          <span
                            className="badge px-3 py-2"
                            style={{
                              backgroundColor: "#ffe5f0",
                              color: "#c2185b",
                              fontSize: "12px",
                              fontWeight: "500",
                              border: "none",
                            }}
                          >
                            {venue.capacity}
                          </span>
                        )}

                        {venue.rooms !== null && venue.rooms !== undefined && (
                          <span
                            className="badge px-3 py-2"
                            style={{
                              backgroundColor: "#ffe5f0",
                              color: "#c2185b",
                              fontSize: "12px",
                              fontWeight: "500",
                              border: "none",
                            }}
                          >
                            {venue.rooms} Rooms
                          </span>
                        )}

                        {venue.more && (
                          <span
                            className="badge px-3 py-2"
                            style={{
                              backgroundColor: "#ffe5f0",
                              color: "#c2185b",
                              fontSize: "12px",
                              fontWeight: "500",
                              border: "none",
                            }}
                          >
                            + {venue.more} more
                          </span>
                        )}
                      </div>
                    </div>
                  </Link>

                  {/* Quick Inquiry Button */}
                  <button
                    className="quick-inquiry-btn mt-auto w-100"
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedVendorId(venue.vendor_id || venue.id);
                      setSelectedVendorName(venue.name || "");
                      setShowQuickInquiry(true);
                    }}
                    onMouseEnter={(e) => e.stopPropagation()}
                    onMouseLeave={(e) => e.stopPropagation()}
                    onMouseOver={(e) => e.stopPropagation()}
                    onMouseOut={(e) => e.stopPropagation()}
                  >
                    ⚡ Quick Inquiry
                  </button>
                </Card.Body>
              </Card>
            </Col>
            );
          })
        ) : (
          <Col xs={12} className="text-center py-5">
            <p className="text-muted">No venues available</p>
          </Col>
        )}
      </Row>
      <QuickInquiryModal
        show={showQuickInquiry}
        handleClose={() => setShowQuickInquiry(false)}
        vendorId={selectedVendorId}
        vendorName={selectedVendorName}
      />
    </Container>
  );
};

export default GridView;
