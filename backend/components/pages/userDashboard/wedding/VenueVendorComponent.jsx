import React, { useEffect, useMemo, useState } from "react";
import { FaAngleLeft, FaAngleRight } from "react-icons/fa";
import { IoLocationOutline } from "react-icons/io5";
import {
  FaCaretDown,
  FaCircleArrowLeft,
  FaCircleArrowRight,
} from "react-icons/fa6";
import useApiData from "../../../../hooks/useApiData";
import { Swiper, SwiperSlide } from "swiper/react"; //
import { Navigation, Autoplay } from "swiper/modules";
import "swiper/css";
import { Link, useNavigate } from "react-router-dom";
import { FaStar } from "react-icons/fa";
import { MdLocationOn } from "react-icons/md";

const toSlug = (text) =>
  (text || "")
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9\-]/g, "");

const VenueVendorComponent = ({ type = "vendor" }) => {
  const navigate = useNavigate();
  const isVendorBox = type === "vendor";
  const [dropdownOpen, setDropdownOpen] = useState(false);
  const [categories, setCategories] = useState([]);
  const [loadingCategories, setLoadingCategories] = useState(false);
  const [selectedSlug, setSelectedSlug] = useState(null);
  const [selectedLabel, setSelectedLabel] = useState("");

  const BACKEND_BASE_URL = "https://happywedzbackend.happywedz.com";
  const buildImageUrl = (path) => {
    if (!path) return null;
    if (typeof path !== "string") return null;
    if (path.startsWith("http")) return path;
    const clean = path.replace(/^\/?uploads\/?/, "");
    return `${BACKEND_BASE_URL}/uploads/${clean}`;
  };

  useEffect(() => {
    if (!isVendorBox) return;
    const fetchCategories = async () => {
      try {
        setLoadingCategories(true);
        const res = await fetch(
          "https://happywedz.com/api/vendor-subcategories"
        );
        const data = await res.json();
        const cats = Array.isArray(data) ? data : [];
        setCategories(cats);
        if (cats.length > 0) {
          setSelectedSlug(toSlug(cats[0].name));
          setSelectedLabel(cats[0].name);
        }
      } catch (e) {
        console.error("Failed to load vendor subcategories", e);
        setCategories([]);
      } finally {
        setLoadingCategories(false);
      }
    };
    fetchCategories();
  }, [isVendorBox]);

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (!e.target.closest(".col-md-5")) {
        setDropdownOpen(false);
      }
    };

    if (dropdownOpen) {
      document.addEventListener("mousedown", handleClickOutside);
    }

    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [dropdownOpen]);

  const { data: vendorItems, loading: loadingVendors } = useApiData(
    isVendorBox ? "vendors" : null,
    isVendorBox ? selectedSlug : null,
    null,
    null
  );

  return (
    <div
      style={{
        maxWidth: "100%",
        boxShadow:
          " rgba(50, 50, 93, 0.25) 0px 2px 5px -1px, rgba(0, 0, 0, 0.3) 0px 1px 3px -1px",
        flex: 1,
        padding: "2rem",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          display: "flex",
          flexDirection: "column",
          gap: "10px",
          flex: 1,
        }}
      >
        <h3 className="fw-bold dark-pink-text text-center">
          {isVendorBox ? "Book all your Vendors" : "Find the perfect Venue"}
        </h3>

        <div className="row align-items-center gy-2">
          <div className="col-12 col-md-7">
            <span className="fs-16 text-center text-md-start d-block">
              Here are some gems we recommand for you
            </span>
          </div>

          {isVendorBox && (
            <div className="col-12 col-md-5">
              <div
                style={{
                  width: "100%",
                  position: "relative",
                  paddingBottom: "0.25rem",
                }}
              >
                {/* Custom Select Button */}
                <div
                  onClick={() => setDropdownOpen(!dropdownOpen)}
                  style={{
                    width: "100%",
                    padding: "8px 28px 8px 8px",
                    fontSize: "14px",
                    background: "transparent",
                    outline: "none",
                    border: "none",
                    borderBottom: "2px solid #C31162",
                    cursor: "pointer",
                    userSelect: "none",
                  }}
                >
                  {selectedLabel || categories[0]?.name || "Select"}
                </div>

                {/* Dropdown Icon */}
                <span
                  style={{
                    position: "absolute",
                    right: "6px",
                    top: "44%",
                    transform: "translateY(-50%)",
                    pointerEvents: "none",
                    fontSize: "14px",
                    color: "#000",
                  }}
                >
                  <FaCaretDown size={12} />
                </span>

                {/* Dropdown Menu - ALWAYS OPENS DOWNWARD */}
                {dropdownOpen && (
                  <div
                    style={{
                      position: "absolute",
                      top: "100%",
                      left: 0,
                      right: 0,
                      backgroundColor: "#fff",
                      border: "1px solid #ddd",
                      borderRadius: "4px",
                      maxHeight: "200px",
                      overflowY: "auto",
                      zIndex: 1000,
                      marginTop: "4px",
                      boxShadow: "0 2px 8px rgba(0,0,0,0.15)",
                    }}
                  >
                    {categories.map((cat) => (
                      <div
                        key={cat.id}
                        onClick={() => {
                          const slug = toSlug(cat.name);
                          setSelectedSlug(slug);
                          setSelectedLabel(cat.name);
                          setDropdownOpen(false);
                        }}
                        style={{
                          padding: "8px 12px",
                          cursor: "pointer",
                          fontSize: "14px",
                          backgroundColor:
                            selectedSlug === toSlug(cat.name)
                              ? "#f0f0f0"
                              : "transparent",
                        }}
                        onMouseEnter={(e) => {
                          e.target.style.backgroundColor = "#f5f5f5";
                        }}
                        onMouseLeave={(e) => {
                          e.target.style.backgroundColor =
                            selectedSlug === toSlug(cat.name)
                              ? "#f0f0f0"
                              : "transparent";
                        }}
                      >
                        {cat.name}
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        {isVendorBox ? (
          <div style={{ position: "relative" }}>
            <Swiper
              modules={[Navigation, Autoplay]}
              spaceBetween={16}
              slidesPerView={2}
              autoplay={{ delay: 3500, disableOnInteraction: false }}
              loop={true}
              breakpoints={{
                576: { slidesPerView: 1, spaceBetween: 16 },
                768: { slidesPerView: 2, spaceBetween: 16 },
                992: { slidesPerView: 2, spaceBetween: 16 },
                1200: { slidesPerView: 2, spaceBetween: 16 },
              }}
            >
              {(selectedSlug ? vendorItems : []).map((item, idx) => (
                <SwiperSlide key={item.id || idx}>
                  <Link
                    to={`/details/info/${item.id}`}
                    className="text-decoration-none d-block"
                    style={{ color: "inherit", height: "100%" }}
                  >
                    <div
                      className="card border-0 shadow-sm overflow-hidden"
                      style={{
                        borderRadius: "12px",
                        height: "330px",
                        display: "flex",
                        flexDirection: "column",
                      }}
                    >
                      <div
                        style={{
                          height: "180px",
                          overflow: "hidden",
                          position: "relative",
                        }}
                      >
                        <img
                          src={
                            buildImageUrl(item.image) ||
                            "/images/imageNotFound.jpg"
                          }
                          className="card-img-top w-100"
                          alt={item.name || "Vendor"}
                          style={{ height: "100%", objectFit: "cover" }}
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "/images/imageNotFound.jpg";
                          }}
                        />
                      </div>
                      <div
                        className="card-body p-3"
                        style={{
                          flex: 1,
                          display: "flex",
                          flexDirection: "column",
                        }}
                      >
                        <h6
                          className="card-title fw-semibold"
                          style={{
                            lineHeight: "1.3",
                            height: "42px",
                            overflow: "hidden",
                            display: "-webkit-box",
                            WebkitLineClamp: 2,
                            WebkitBoxOrient: "vertical",
                          }}
                        >
                          {item.name || "Name"}
                        </h6>

                        <div
                          className="d-flex align-items-center mb-2"
                          style={{ gap: "6px", height: "20px" }}
                        >
                          <FaStar
                            style={{ color: "#FFA500", fontSize: "14px" }}
                          />
                          <span
                            className="fw-semibold"
                            style={{ fontSize: "14px", color: "#333" }}
                          >
                            {(item.rating || 0).toFixed
                              ? (item.rating || 0).toFixed(1)
                              : item.rating || 0}
                          </span>
                          <span
                            className="text-muted"
                            style={{ fontSize: "13px" }}
                          >
                            ({item.review_count || 0} Reviews)
                          </span>
                        </div>

                        <div
                          className="d-flex align-items-start"
                          style={{ gap: "6px" }}
                        >
                          <MdLocationOn
                            style={{
                              color: "#666",
                              fontSize: "16px",
                              marginTop: "2px",
                              flexShrink: 0,
                            }}
                          />
                          <p
                            className="mb-0 text-muted small"
                            style={{
                              color: "#666",
                              fontSize: "13px",
                              lineHeight: "1.4",
                              overflow: "hidden",
                              display: "-webkit-box",
                              WebkitLineClamp: 2,
                              WebkitBoxOrient: "vertical",
                            }}
                          >
                            {(item.location || "")
                              .split(" ")
                              .slice(0, 1)
                              .join(" ")}
                            {item.location?.split(" ").length > 1 && "..."}
                          </p>
                        </div>
                      </div>
                    </div>
                  </Link>
                </SwiperSlide>
              ))}
            </Swiper>

            {/* Empty state when no category selected */}
            {!selectedSlug && (
              <div
                className="text-muted"
                style={{ position: "absolute", bottom: 0, fontSize: "14px" }}
              >
                {loadingCategories
                  ? "Loading categories..."
                  : "Choose a category to see recommendations."}
              </div>
            )}
          </div>
        ) : (
          <div style={{ marginTop: "1.4rem" }}>
            <VenueSwiper />
          </div>
        )}

        <div className="d-flex justify-content-end mt-3 mt-md-4">
          <button
            className="btn fs-14 w-100 w-md-auto"
            style={{ background: "#C31162", color: "#fff" }}
            disabled={isVendorBox ? !selectedSlug || loadingVendors : false}
            onClick={() => {
              if (isVendorBox) {
                if (selectedSlug) navigate(`/vendors/${selectedSlug}`);
              } else {
                navigate("/venues");
              }
            }}
          >
            {isVendorBox
              ? loadingVendors
                ? "Loading..."
                : selectedLabel
                ? `Search ${selectedLabel}`
                : "Search Vendors"
              : "Search Venues"}
          </button>
        </div>
        {/* {isVendorBox && (
        )} */}
      </div>
    </div>
  );
};

export default VenueVendorComponent;

const VenueSwiper = () => {
  const [venues, setVenues] = useState([]);
  const [loading, setLoading] = useState(false);
  const BACKEND_BASE_URL = "https://happywedzbackend.happywedz.com";

  const truncateWords = (str, numWords) => {
    if (!str) return "";
    const words = str.split(" ");
    return words.length > numWords
      ? words.slice(0, numWords).join(" ") + "..."
      : str;
  };

  const buildImageUrl = (path) => {
    if (!path) return null;
    if (typeof path !== "string") return null;
    if (path.startsWith("http")) return path;
    const clean = path.replace(/^\/?uploads\/?/, "");
    return `${BACKEND_BASE_URL}/uploads/${clean}`;
  };

  const cleanMediaUrl = (m) => {
    if (!m) return null;
    if (typeof m === "string") return m.replace(/[`"']/g, "").trim();
    if (typeof m === "object" && m.url) return String(m.url).trim();
    return null;
  };

  useEffect(() => {
    const fetchVenues = async () => {
      try {
        setLoading(true);
        const response = await fetch(
          "https://happywedz.com/api/vendor-services?vendorType=Venues&page=1&limit=9"
        );
        const result = await response.json();

        const venueData =
          result.data?.map((item) => ({
            id: item.id,
            name:
              item.attributes?.vendor_name ||
              item.vendor?.businessName ||
              "Venue",
            image:
              item.attributes?.image_url ||
              cleanMediaUrl(item.media?.[0]) ||
              null,
            rating: item.attributes?.rating || 0,
            review_count: item.attributes?.review_count || 0,
            location: item.attributes?.city || item.vendor?.city || "Location",
            city: item.attributes?.city || item.vendor?.city || "",
          })) || [];
        setVenues(venueData);
      } catch (error) {
        console.error("Error fetching venues:", error);
        setVenues([]);
      } finally {
        setLoading(false);
      }
    };
    fetchVenues();
  }, []);

  if (loading) {
    return (
      <div className="text-muted" style={{ fontSize: "14px" }}>
        Loading venues...
      </div>
    );
  }

  return (
    <Swiper
      modules={[Navigation, Autoplay]}
      spaceBetween={16}
      slidesPerView={2}
      autoplay={{ delay: 3500, disableOnInteraction: false }}
      loop={venues.length > 2}
      breakpoints={{
        576: { slidesPerView: 1, spaceBetween: 16 },
        768: { slidesPerView: 2, spaceBetween: 16 },
        992: { slidesPerView: 2, spaceBetween: 16 },
        1200: { slidesPerView: 2, spaceBetween: 16 },
      }}
    >
      {venues.map((venue) => (
        <SwiperSlide key={venue.id} style={{ height: "auto" }}>
          <Link
            to={`/details/info/${venue.id}`}
            className="text-decoration-none d-block"
            style={{ color: "inherit", height: "100%" }}
          >
            <div
              className="card border-0 shadow-sm overflow-hidden"
              style={{
                borderRadius: "12px",
                height: "310px",
                display: "flex",
                flexDirection: "column",
              }}
            >
              <div
                style={{
                  height: "180px",
                  overflow: "hidden",
                  position: "relative",
                  flexShrink: 0,
                }}
              >
                <img
                  src={
                    buildImageUrl(venue.image) || "/images/imageNotFound.jpg"
                  }
                  className="card-img-top w-100"
                  alt={venue.name}
                  style={{ height: "100%", objectFit: "cover" }}
                  onError={(e) => {
                    e.target.onerror = null;
                    e.target.src = "/images/imageNotFound.jpg";
                  }}
                />
              </div>
              <div
                className="card-body p-3"
                style={{ flex: 1, display: "flex", flexDirection: "column" }}
              >
                <h6
                  className="card-title  fw-semibold"
                  style={{
                    fontSize: "16px",
                    lineHeight: "1.3",
                    height: "42px",
                    overflow: "hidden",
                    display: "-webkit-box",
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: "vertical",
                  }}
                >
                  {truncateWords(venue.name, 3)}
                </h6>

                <div
                  className="d-flex align-items-center mb-2"
                  style={{ gap: "6px", height: "20px" }}
                >
                  <FaStar style={{ color: "#FFA500", fontSize: "14px" }} />
                  <span
                    className="fw-semibold"
                    style={{ fontSize: "14px", color: "#333" }}
                  >
                    {(venue.rating || 0).toFixed
                      ? (venue.rating || 0).toFixed(1)
                      : venue.rating || 0}
                  </span>
                  <span className="text-muted" style={{ fontSize: "13px" }}>
                    ({venue.review_count || 0} Reviews)
                  </span>
                </div>

                <div
                  className="d-flex align-items-start"
                  style={{ gap: "6px" }}
                >
                  <MdLocationOn
                    style={{
                      color: "#666",
                      fontSize: "16px",
                      marginTop: "2px",
                      flexShrink: 0,
                    }}
                  />
                  <p
                    className="mb-0 text-muted small"
                    style={{
                      color: "#666",
                      fontSize: "13px",
                      lineHeight: "1.4",
                      overflow: "hidden",
                      display: "-webkit-box",
                      WebkitLineClamp: 2,
                      WebkitBoxOrient: "vertical",
                    }}
                  >
                    {(venue.location || "").split(" ").slice(0, 1).join(" ")}
                    {venue.location?.split(" ").length > 1 && "..."}
                  </p>
                </div>
              </div>
            </div>
          </Link>
        </SwiperSlide>
      ))}
    </Swiper>
  );
};
