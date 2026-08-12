import React, { useState, useEffect, useRef } from "react";
import { Container, Row, Col, Form, Button } from "react-bootstrap";
import { useNavigate, Link } from "react-router-dom";
import { useSelector, useDispatch } from "react-redux";
import { MdExpandMore, MdExpandLess, MdClose } from "react-icons/md";
import { CiLocationOn, CiSearch } from "react-icons/ci";
import { FaSearch, FaStar } from "react-icons/fa";
import axiosInstance from "../../services/api/axiosInstance";
import { setLocation } from "../../redux/locationSlice";
import { useHome } from "../../hooks/useHome";

// The default hero background is set in CSS (`.hero-search--default` in
// App.critical.css) rather than from JS, so the preload scanner and the media
// queries agree on which of hero-768/1280/2000.webp to fetch. Keep those rules
// in sync with the <link rel="preload"> tags in index.html.

const RotatingWordHeadline = ({
  words = ["Unique", "Dreamy", "Perfect"],
  titleTemplate = "Find Your _ Wedding Vendor",
}) => {
  const [index, setIndex] = useState(0);
  const [animating, setAnimating] = useState(true);
  useEffect(() => {
    const cycle = setInterval(() => {
      setAnimating(false);
      setTimeout(() => {
        setIndex((i) => (i + 1) % words.length);
        setAnimating(true);
      }, 300);
    }, 2800);
    return () => clearInterval(cycle);
  }, [words.length]);
  const parts = titleTemplate.split("_");
  // The rotating word swaps every 2.8s for the life of the page. Words of
  // different widths re-flow the headline — and can rewrap it to a second line —
  // which registers as a layout shift every single cycle. Reserving the width of
  // the longest word up front makes every rotation dimensionally identical.
  const widestWord = words.reduce(
    (longest, w) => (w.length > longest.length ? w : longest),
    "",
  );
  return (
    <h1 className="display-5 fw-bold" style={{ minHeight: "1.2em", whiteSpace: "nowrap", fontSize: "clamp(1.5rem, 3.8vw, 3rem)" }}>
      <span style={{ whiteSpace: "nowrap" }}>
        {parts[0]}
        <span
          style={{
            display: "inline-block",
            transition: "opacity .3s, transform .3s",
            opacity: animating ? 1 : 0,
            transform: animating ? "scale(1)" : "scale(0.95)",
            color: "#e83581",
            verticalAlign: "bottom",
          }}
        >
          {words[index]}
        </span>
        {parts[1] || " Wedding Vendor"}
      </span>
    </h1>
  );
};

const Herosection = () => {
  const dispatch = useDispatch();
  const navigate = useNavigate();
  const reduxLocation = useSelector((s) => s.location.selectedLocation);
  const {
    heroData,
    vendorCategories,
    cities,
    ensureCities,
    _loadingHero,
    _loadingCities,
    getCurrentBackgroundImage,
  } = useHome();

  const [selectedCategory, setSelectedCategory] = useState("All Categories");
  const [selectedCity, setSelectedCity] = useState("");
  const [showDropdown, setShowDropdown] = useState(false);
  const dropdownRef = useRef(null);
  const buttonRef = useRef(null);

  const [showCityDropdown, setShowCityDropdown] = useState(false);
  const [citySearch, setCitySearch] = useState("");
  const [showCategoryDropdown, setShowCategoryDropdown] = useState(false);
  const cityDropdownRef = useRef(null);
  const cityInputRef = useRef(null);
  const categoryDropdownRef = useRef(null);
  const categoryButtonRef = useRef(null);

  // Vendor Search States
  const [vendorQuery, setVendorQuery] = useState("");
  const [vendorLoading, setVendorLoading] = useState(false);
  const [vendorResults, setVendorResults] = useState([]);
  const [showVendorDropdown, setShowVendorDropdown] = useState(false);
  const vendorDebounceRef = useRef(null);
  const vendorDropdownRef = useRef(null);
  const vendorInputRef = useRef(null);

  const toSlug = (t) =>
    t?.replace(/\s+/g, "-").replace(/[^A-Za-z0-9-]/g, "") || "";
  const formatName = (n) => n.replace(/\band\b/gi, "&");

  const cleanMediaUrl = (m) => {
    if (!m) return null;
    if (typeof m === "string") return m.replace(/[`"']/g, "").trim();
    if (typeof m === "object" && m.url) return String(m.url).trim();
    return null;
  };

  const getVendorImage = (vendor) =>
    vendor?.attributes?.image_url ||
    cleanMediaUrl(vendor?.media?.[0]) ||
    vendor?.attributes?.image ||
    vendor?.attributes?.profile_image ||
    "/images/imageNotFound.jpg";

  const getVendorName = (vendor) =>
    vendor?.attributes?.name ||
    vendor?.attributes?.vendor_name ||
    vendor?.vendor?.businessName ||
    "Vendor";

  useEffect(() => {
    const handleOutside = (e) => {
      if (
        dropdownRef.current &&
        !dropdownRef.current.contains(e.target) &&
        buttonRef.current &&
        !buttonRef.current.contains(e.target)
      )
        setShowDropdown(false);
    };
    if (showDropdown) document.addEventListener("mousedown", handleOutside);
    return () => document.removeEventListener("mousedown", handleOutside);
  }, [showDropdown]);

  useEffect(() => {
    const handleOutside = (e) => {
      if (
        cityDropdownRef.current &&
        !cityDropdownRef.current.contains(e.target) &&
        cityInputRef.current &&
        !cityInputRef.current.contains(e.target)
      )
        setShowCityDropdown(false);
    };
    if (showCityDropdown) document.addEventListener("mousedown", handleOutside);
    return () => document.removeEventListener("mousedown", handleOutside);
  }, [showCityDropdown]);

  useEffect(() => {
    const handleOutside = (e) => {
      if (
        categoryDropdownRef.current &&
        !categoryDropdownRef.current.contains(e.target) &&
        categoryButtonRef.current &&
        !categoryButtonRef.current.contains(e.target)
      )
        setShowCategoryDropdown(false);
    };
    if (showCategoryDropdown)
      document.addEventListener("mousedown", handleOutside);
    return () => document.removeEventListener("mousedown", handleOutside);
  }, [showCategoryDropdown]);

  // Vendor Search - Click Outside Handler
  useEffect(() => {
    const handleOutside = (e) => {
      if (
        vendorDropdownRef.current &&
        !vendorDropdownRef.current.contains(e.target)
      )
        setShowVendorDropdown(false);
    };
    if (showVendorDropdown)
      document.addEventListener("mousedown", handleOutside);
    return () => document.removeEventListener("mousedown", handleOutside);
  }, [showVendorDropdown]);

  // Vendor Search - same API as /vendors (MainSearch)
  const performVendorSearch = async (searchQuery) => {
    const q = searchQuery?.trim();
    if (!q || q.length < 2) {
      setVendorResults([]);
      setShowVendorDropdown(false);
      return;
    }
    setVendorLoading(true);
    setShowVendorDropdown(true);
    try {
      const params = new URLSearchParams({
        search: q,
        limit: "10",
      });
      if (
        reduxLocation &&
        reduxLocation !== "null" &&
        reduxLocation.trim() !== ""
      ) {
        params.set("city", reduxLocation.trim());
      }
      const { data } = await axiosInstance.get(
        `/vendor-services?${params.toString()}`,
      );
      const items = Array.isArray(data?.data) ? data.data : [];
      setVendorResults(items);
      setShowVendorDropdown(true);
    } catch (e) {
      console.error("Vendor search error:", e);
      setVendorResults([]);
    } finally {
      setVendorLoading(false);
    }
  };

  // Vendor Search - Debounced Input Handler
  const handleVendorQueryChange = (e) => {
    const value = e.target.value;
    setVendorQuery(value);

    // Show dropdown immediately if user is typing
    if (value.trim().length >= 2) {
      setShowVendorDropdown(true);
    } else {
      setShowVendorDropdown(false);
    }

    if (vendorDebounceRef.current) clearTimeout(vendorDebounceRef.current);
    vendorDebounceRef.current = setTimeout(() => performVendorSearch(value), 400);
  };

  // Vendor Search - Cleanup
  useEffect(() => {
    return () => {
      if (vendorDebounceRef.current) clearTimeout(vendorDebounceRef.current);
    };
  }, []);


  const getVendorDetailPath = (vendor) => {
    const target =
      vendor?.slug ?? vendor?.id ?? vendor?.vendor_services_id ?? null;
    return target ? `/details/info/${target}` : null;
  };

  const handleVendorSelect = (vendor) => {
    const path = getVendorDetailPath(vendor);
    if (!path) return;
    setShowVendorDropdown(false);
    setVendorQuery("");
    setVendorResults([]);
    navigate(path);
  };

  const handleVendorSearchSubmit = (e) => {
    e.preventDefault();
    const q = vendorQuery.trim();
    if (q.length < 2) return;
    const params = new URLSearchParams({ search: q });
    if (
      reduxLocation &&
      reduxLocation !== "null" &&
      reduxLocation.trim() !== ""
    ) {
      params.set("city", reduxLocation.trim());
    }
    setShowVendorDropdown(false);
    navigate(`/vendors/all?${params.toString()}`);
  };

  const renderVendorLiveSearch = () => (
    <div ref={vendorDropdownRef} className="position-relative mb-3">
      <Form onSubmit={handleVendorSearchSubmit}>
        <div
          className="d-flex flex-column flex-md-row align-items-stretch gap-2 gap-md-3"
          style={{ maxWidth: 680, margin: "0 auto" }}
        >
          <div
            className="d-flex align-items-center flex-grow-1 px-3 py-2 bg-white"
            ref={vendorInputRef}
            style={{
              border: "2px solid #e5e7eb",
              borderRadius: "12px",
              boxShadow: "0 2px 4px rgba(0,0,0,0.08)",
            }}
          >
            <FaSearch className="me-2 text-secondary flex-shrink-0" size={14} />
            <input
              type="text"
              className="form-control border-0 shadow-none p-0"
              value={vendorQuery}
              onChange={handleVendorQueryChange}
              placeholder="Decor, catering, planners..."
              style={{ background: "transparent", fontSize: "0.95rem" }}
              onFocus={() =>
                vendorQuery.trim().length >= 2 && setShowVendorDropdown(true)
              }
              autoComplete="off"
            />
          </div>
          {/* <Button
            type="submit"
            className="d-flex align-items-center justify-content-center gap-2 border-0 fw-semibold"
            style={{
              backgroundColor: "#C31162",
              borderRadius: "12px",
              padding: "0.75rem 1.5rem",
              whiteSpace: "nowrap",
            }}
          >
            <CiSearch size={20} />
            Search
          </Button> */}
        </div>

        {showVendorDropdown && vendorQuery.trim().length >= 2 && (
          <div
            className="hero-vendor-search-dropdown bg-white shadow-lg rounded-3 mt-2"
            style={{
              position: "absolute",
              top: "100%",
              left: "50%",
              transform: "translateX(-50%)",
              width: "100%",
              maxWidth: 680,
              maxHeight: "400px",
              overflowY: "auto",
              zIndex: 1100,
              border: "1px solid #e5e7eb",
              animation: "slideDown 0.3s ease-out",
            }}
          >
            {vendorLoading ? (
              <div className="p-4 text-center text-muted">
                <span
                  className="spinner-border spinner-border-sm me-2"
                  style={{ color: "#C31162" }}
                />
                Searching...
              </div>
            ) : vendorResults.length > 0 ? (
              vendorResults.map((vendor, idx) => (
                <Link
                  key={vendor?.id ?? vendor?.vendor_services_id ?? `vendor-${idx}`}
                  to={getVendorDetailPath(vendor) ?? "#"}
                  className="d-block text-decoration-none text-dark border-bottom hero-vendor-result-item"
                  onClick={() => {
                    setShowVendorDropdown(false);
                    setVendorQuery("");
                    setVendorResults([]);
                  }}
                >
                  <div className="d-flex align-items-center gap-3 p-3">
                    <img loading="lazy" decoding="async"
                      src={getVendorImage(vendor)}
                      alt={getVendorName(vendor)}
                      style={{
                        width: 64,
                        height: 64,
                        objectFit: "cover",
                        borderRadius: 10,
                        flexShrink: 0,
                      }}
                      onError={(e) => {
                        e.target.onerror = null;
                        e.target.src = "/images/imageNotFound.jpg";
                      }}
                    />
                    <div className="flex-grow-1 overflow-hidden">
                      <div className="fw-semibold fs-16 mb-1 text-truncate">
                        {getVendorName(vendor)}
                      </div>
                      <div className="d-flex align-items-center gap-2 mb-1 small text-muted">
                        <FaStar size={12} className="text-warning" />
                        <span>
                          <strong>{vendor?.attributes?.rating || 0}</strong> (
                          {vendor?.attributes?.review_count || 0} reviews)
                        </span>
                      </div>
                      <p className="mb-0 small text-muted d-flex align-items-center gap-1">
                        <CiLocationOn size={14} />
                        {vendor?.attributes?.city ||
                          vendor?.vendor?.city ||
                          "Location"}
                      </p>
                    </div>
                  </div>
                </Link>
              ))
            ) : (
              <div className="p-4 text-center text-muted small">
                No vendors found for &quot;{vendorQuery.trim()}&quot;
              </div>
            )}
          </div>
        )}
      </Form>
    </div>
  );

  const filteredCities = (Array.isArray(cities) ? cities : []).filter((city) =>
    city.toLowerCase().includes(citySearch.toLowerCase())
  );

  // Clear location handler
  const handleClearLocation = (e) => {
    e.stopPropagation(); // Prevent dropdown toggle
    dispatch(setLocation("")); // Clear Redux state with empty string
  };

  const handleSearch = (e) => {
    e.preventDefault();
    if (selectedCity) dispatch(setLocation(selectedCity));
    if (selectedCategory === "All Categories") navigate("/vendors");
    else {
      const formatted = selectedCategory
        .toLowerCase()
        .split(" ")
        .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
        .join(" ");
      const cityParam = selectedCity
        ? `&city=${encodeURIComponent(selectedCity)}`
        : "";
      navigate(
        `/vendors/all?vendorType=${encodeURIComponent(formatted)}${cityParam}`
      );
    }
  };

  // null until a CMS carousel frame has been fetched and decoded off-screen.
  // Until then the default image comes from `.hero-search--default`, whose
  // media queries let mobile take the 768px file instead of the 1280px one.
  const cmsBgImage = getCurrentBackgroundImage();

  return (
    <section
      className={`hero-search position-relative text-white${
        cmsBgImage ? "" : " hero-search--default"
      }`}
      style={{
        ...(cmsBgImage ? { backgroundImage: `url(${cmsBgImage})` } : null),
        backgroundPosition: "center",
        backgroundSize: "cover",
        paddingTop: "120px",
        paddingBottom: "80px",
      }}
    >
      <div className="overlay" />
      <Container className="py-5 position-relative" style={{ zIndex: 2 }}>
        <Row className="justify-content-center text-center">
          <Col lg={10}>
            <RotatingWordHeadline
              words={
                Array.isArray(heroData?.typewriter_words)
                  ? heroData.typewriter_words
                  : ["Dream"]
              }
              titleTemplate={
                heroData?.title || "Discover Your _ Wedding Vendor"
              }
            />
            <p className="lead mb-4 fs-20">
              {heroData?.subtitle ||
                "Discover top-rated wedding vendors with countless reliable reviews."}
            </p>
          </Col>
        </Row>
        <Row className="justify-content-center mt-4">
          <Col xs={12} md={10} className="position-relative">
            {renderVendorLiveSearch()}
            {reduxLocation && reduxLocation !== "null" && reduxLocation.trim() !== "" ? (
              <div className="position-relative">
                <button
                  ref={buttonRef}
                  className="btn-light w-100 fw-semibold d-flex justify-content-between align-items-center"
                  onClick={() => setShowDropdown(!showDropdown)}
                  style={{
                    fontSize: "16px",
                    padding: "1rem 2rem",
                    backgroundColor: "white",
                    border: "2px solid #e83581",
                    color: "#e83581",
                    borderRadius: "8px",
                  }}
                >
                  <span>Find Vendors in {reduxLocation}</span>
                  <div className="d-flex align-items-center gap-2">
                    <MdClose
                      size={24}
                      onClick={handleClearLocation}
                      style={{
                        cursor: "pointer",
                        padding: "2px",
                        borderRadius: "50%",
                        transition: "background-color 0.2s",
                      }}
                      onMouseEnter={(e) => {
                        e.currentTarget.style.backgroundColor = "rgba(232, 53, 129, 0.1)";
                      }}
                      onMouseLeave={(e) => {
                        e.currentTarget.style.backgroundColor = "transparent";
                      }}
                      title="Clear location and show search"
                    />
                    {showDropdown ? (
                      <MdExpandLess size={24} />
                    ) : (
                      <MdExpandMore size={24} />
                    )}
                  </div>
                </button>
                {showDropdown && (
                  <div
                    ref={dropdownRef}
                    className="vendor-dropdown-menu"
                    style={{
                      position: "absolute",
                      top: "calc(100% + 8px)",
                      left: 0,
                      right: 0,
                      backgroundColor: "white",
                      borderRadius: "12px",
                      fontSize: "14px",
                      boxShadow: "0 8px 24px rgba(0, 0, 0, 0.15)",
                      maxHeight: "500px",
                      overflowY: "auto",
                      zIndex: 1000,
                      animation: "slideDown 0.3s ease-out",
                    }}
                  >
                    <div
                      style={{
                        padding: "1.5rem",
                        columnCount: 4,
                        columnGap: "1.5rem",
                      }}
                      className="dropdown-grid"
                    >
                      {(vendorCategories || []).map((cat, i) => (
                        <div
                          key={cat.id || i}
                          style={{
                            breakInside: "avoid",
                            marginBottom: "1.5rem",
                          }}
                        >
                          <div
                            className="fw-bold text-uppercase mb-2"
                            style={{ color: "#e83581", fontSize: "14px" }}
                          >
                            {cat.name}
                          </div>
                          {Array.isArray(cat.subcategories) &&
                            cat.subcategories.map((sub, j) => (
                              <li
                                key={sub.id || j}
                                className="mb-1"
                                style={{ listStyle: "none" }}
                              >
                                <Link
                                  to={`/vendors/${toSlug(sub.name)}`}
                                  className="fs-14 py-1"
                                  style={{
                                    fontSize: "14px",
                                    color: "#333",
                                    textDecoration: "none",
                                    display: "block",
                                    transition: "color 0.2s",
                                  }}
                                  onClick={() => setShowDropdown(false)}
                                >
                                  {formatName(sub.name)}
                                </Link>
                              </li>
                            ))}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            ) : (
              <>
                <div className="d-none mb-3 p-3 position-relative" aria-hidden="true">
                  <div
                    style={{
                      position: "relative",
                      display: "flex",
                      alignItems: "center",
                    }}
                  >
                    <CiSearch
                      size={20}
                      style={{
                        position: "absolute",
                        left: "1rem",
                        color: "#666",
                        zIndex: 1,
                      }}
                    />
                    <input
                      type="text"
                      className="form-control"
                      value={vendorQuery}
                      onChange={handleVendorQueryChange}
                      placeholder="Search for specific vendors (e.g., photographer name, makeup artist...)"
                      style={{
                        fontSize: "14px",
                        padding: "0.75rem 1rem 0.75rem 2.5rem",
                        backgroundColor: "white",
                        borderRadius: "6px",
                        border: "1px solid #ddd",
                      }}
                    />
                  </div>

                  {/* Vendor Search Results Dropdown */}
                  {showVendorDropdown && vendorQuery.trim().length >= 2 && (
                    <div
                      style={{
                        position: "absolute",
                        top: "calc(100% + 8px)",
                        left: 0,
                        right: 0,
                        backgroundColor: "white",
                        borderRadius: "8px",
                        boxShadow: "0 8px 24px rgba(0, 0, 0, 0.15)",
                        maxHeight: "400px",
                        overflowY: "auto",
                        zIndex: 1000,
                        animation: "slideDown 0.3s ease-out",
                      }}
                    >
                      {vendorLoading ? (
                        <div
                          style={{
                            padding: "1.5rem",
                            textAlign: "center",
                            color: "#e83581",
                            fontWeight: "500",
                          }}
                        >
                          <div
                            className="spinner-border spinner-border-sm me-2"
                            role="status"
                            style={{
                              borderColor: "#e83581",
                              borderRightColor: "transparent"
                            }}
                          >
                            <span className="visually-hidden">Loading...</span>
                          </div>
                          Searching...
                        </div>
                      ) : vendorResults.length === 0 ? (
                        <div
                          style={{
                            padding: "1.5rem",
                            textAlign: "center",
                            color: "#666",
                          }}
                        >
                          No vendors found
                        </div>
                      ) : (
                        <div style={{ padding: "0.5rem 0" }}>
                          {vendorResults.map((vendor) => {
                            const vendorId =
                              vendor?.id ?? vendor?.vendor_services_id;
                            const vendorName =
                              vendor?.attributes?.vendor_name ||
                              vendor?.attributes?.name ||
                              vendor?.vendor?.businessName ||
                              `Vendor ${vendorId}`;
                            const city =
                              vendor?.attributes?.city ||
                              vendor?.vendor?.city ||
                              "";
                            const image =
                              vendor?.attributes?.image ||
                              vendor?.attributes?.profile_image ||
                              vendor?.vendor?.profileImage;
                            const rating = vendor?.attributes?.rating;

                            return (
                              <div
                                key={vendorId}
                                onClick={() => handleVendorSelect(vendor)}
                                style={{
                                  padding: "0.75rem 1rem",
                                  cursor: "pointer",
                                  borderBottom: "1px solid #eee",
                                  display: "flex",
                                  alignItems: "center",
                                  gap: "0.75rem",
                                  transition: "background-color 0.2s",
                                }}
                                onMouseEnter={(e) =>
                                (e.currentTarget.style.backgroundColor =
                                  "#f5f5f5")
                                }
                                onMouseLeave={(e) =>
                                (e.currentTarget.style.backgroundColor =
                                  "white")
                                }
                              >
                                {image && (
                                  <img loading="lazy" decoding="async"
                                    src={image}
                                    alt={vendorName}
                                    style={{
                                      width: "50px",
                                      height: "50px",
                                      objectFit: "cover",
                                      borderRadius: "6px",
                                      flexShrink: 0,
                                    }}
                                    onError={(e) => {
                                      e.target.style.display = "none";
                                    }}
                                  />
                                )}
                                <div style={{ flex: 1 }}>
                                  <div
                                    style={{
                                      fontWeight: "600",
                                      fontSize: "14px",
                                      color: "#333",
                                      marginBottom: "0.25rem",
                                    }}
                                  >
                                    {vendorName}
                                  </div>
                                  {city && (
                                    <div
                                      style={{
                                        fontSize: "12px",
                                        color: "#666",
                                        display: "flex",
                                        alignItems: "center",
                                        gap: "0.25rem",
                                      }}
                                    >
                                      <CiLocationOn size={14} /> {city}
                                    </div>
                                  )}
                                </div>
                                {rating != null && (
                                  <div
                                    style={{
                                      display: "flex",
                                      alignItems: "center",
                                      gap: "0.25rem",
                                      fontSize: "12px",
                                      color: "#666",
                                      backgroundColor: "#f8f9fa",
                                      padding: "0.25rem 0.5rem",
                                      borderRadius: "4px",
                                    }}
                                  >
                                    <FaStar color="#e83581" size={14} />
                                    {rating}
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  )}
                </div>

                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: "1rem",
                    margin: "1.5rem 0",
                  }}
                >
                  <div
                    style={{
                      flex: 1,
                      height: "1px",
                      backgroundColor: "rgba(255, 255, 255, 0.3)",
                    }}
                  />
                  <span
                    style={{
                      fontSize: "14px",
                      color: "rgba(255, 255, 255, 0.8)",
                      fontWeight: "500",
                    }}
                  >
                    OR BROWSE BY CATEGORY
                  </span>
                  <div
                    style={{
                      flex: 1,
                      height: "1px",
                      backgroundColor: "rgba(255, 255, 255, 0.3)",
                    }}
                  />
                </div>

                {/* Category + City Search Form */}
                <Form className="search-form" onSubmit={handleSearch}>
                  <Row className="g-3">
                    <Col xs={12} md={5} className="position-relative">
                      <button
                        ref={categoryButtonRef}
                        type="button"
                        className="btn-light w-100 fw-semibold d-flex justify-content-between align-items-center"
                        onClick={() =>
                          setShowCategoryDropdown(!showCategoryDropdown)
                        }
                        style={{
                          fontSize: "14px",
                          padding: "0.75rem 1rem",
                          backgroundColor: "white",
                          border: "1px solid #ddd",
                          color: "#333",
                          borderRadius: "6px",
                        }}
                      >
                        <span style={{ fontSize: "14px" }}>
                          {selectedCategory}
                        </span>
                        {showCategoryDropdown ? (
                          <MdExpandLess size={18} />
                        ) : (
                          <MdExpandMore size={18} />
                        )}
                      </button>
                      {showCategoryDropdown && (
                        <div
                          ref={categoryDropdownRef}
                          style={{
                            position: "absolute",
                            top: "calc(100% + 4px)",
                            left: 0,
                            right: 0,
                            fontSize: "14px",
                            backgroundColor: "white",
                            borderRadius: "6px",
                            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.1)",
                            maxHeight: "300px",
                            overflowY: "auto",
                            zIndex: 999,
                            border: "1px solid #ddd",
                          }}
                        >
                          <div style={{ padding: "0.5rem 0" }}>
                            <div
                              style={{
                                fontSize: "14px",
                                padding: "0.75rem 1rem",
                                color: "#333",
                                cursor: "pointer",
                                borderBottom: "1px solid #eee",
                              }}
                              onClick={() => {
                                setSelectedCategory("All Categories");
                                setShowCategoryDropdown(false);
                              }}
                              onMouseEnter={(e) =>
                                (e.target.style.backgroundColor = "#f5f5f5")
                              }
                              onMouseLeave={(e) =>
                                (e.target.style.backgroundColor = "white")
                              }
                            >
                              All Categories
                            </div>
                            {(vendorCategories || []).map((cat) => (
                              <div
                                key={cat.id}
                                style={{
                                  fontSize: "14px",
                                  padding: "0.75rem 1rem",
                                  color: "#333",
                                  cursor: "pointer",
                                  borderBottom: "1px solid #eee",
                                }}
                                onClick={() => {
                                  setSelectedCategory(cat.name);
                                  setShowCategoryDropdown(false);
                                }}
                                onMouseEnter={(e) =>
                                  (e.target.style.backgroundColor = "#f5f5f5")
                                }
                                onMouseLeave={(e) =>
                                  (e.target.style.backgroundColor = "white")
                                }
                              >
                                {cat.name}
                              </div>
                            ))}
                          </div>
                        </div>
                      )}
                    </Col>
                    <Col xs={12} md={5} className="position-relative">
                      <div
                        ref={cityInputRef}
                        style={{
                          position: "relative",
                          display: "flex",
                          alignItems: "center",
                        }}
                      >
                        <input
                          type="text"
                          className="form-control fw-bold"
                          value={citySearch}
                          onChange={(e) => {
                            setCitySearch(e.target.value);
                            setShowCityDropdown(true);
                          }}
                          placeholder="Search city..."
                          style={{
                            fontSize: "14px",
                            padding: "0.75rem 1rem",
                            paddingRight: "2.5rem",
                            borderRadius: "6px",
                            border: "1px solid #ddd",
                          }}
                          onFocus={() => {
                            ensureCities();
                            setShowCityDropdown(true);
                          }}
                        />
                        <button
                          type="button"
                          onClick={() => {
                            ensureCities();
                            setShowCityDropdown(!showCityDropdown);
                          }}
                          style={{
                            position: "absolute",
                            right: "8px",
                            background: "none",
                            border: "none",
                            cursor: "pointer",
                            padding: "0",
                          }}
                        >
                          {showCityDropdown ? (
                            <MdExpandLess size={18} />
                          ) : (
                            <MdExpandMore size={18} />
                          )}
                        </button>
                      </div>
                      {showCityDropdown && (
                        <div
                          ref={cityDropdownRef}
                          style={{
                            position: "absolute",
                            top: "calc(100% + 4px)",
                            left: 0,
                            right: 0,
                            backgroundColor: "white",
                            borderRadius: "6px",
                            boxShadow: "0 4px 12px rgba(0, 0, 0, 0.1)",
                            maxHeight: "300px",
                            overflowY: "auto",
                            zIndex: 999,
                            fontSize: "14px",
                            border: "1px solid #ddd",
                          }}
                        >
                          <div style={{ padding: "0.5rem 0" }}>
                            {filteredCities.length > 0 ? (
                              filteredCities.map((city) => (
                                <div
                                  key={city}
                                  style={{
                                    padding: "0.75rem 1rem",
                                    color: "#333",
                                    cursor: "pointer",
                                    borderBottom: "1px solid #eee",
                                  }}
                                  onClick={() => {
                                    setCitySearch(city);
                                    setSelectedCity(city);
                                    setShowCityDropdown(false);
                                  }}
                                  onMouseEnter={(e) =>
                                    (e.target.style.backgroundColor = "#f5f5f5")
                                  }
                                  onMouseLeave={(e) =>
                                    (e.target.style.backgroundColor = "white")
                                  }
                                >
                                  {city}
                                </div>
                              ))
                            ) : (
                              <div
                                style={{
                                  padding: "1rem",
                                  color: "#999",
                                  textAlign: "center",
                                }}
                              >
                                No cities found
                              </div>
                            )}
                          </div>
                        </div>
                      )}
                    </Col>
                    <Col xs={12} md={2} className="d-grid">
                      <Button
                        variant="none"
                        className="btn-primary fw-semibold fs-12"
                        type="submit"
                      >
                        FIND VENDOR
                      </Button>
                    </Col>
                  </Row>
                </Form>
              </>
            )}
          </Col>
        </Row>
        {heroData?.description && (
          <Row className="justify-content-center mt-3">
            <Col lg={10} className="text-center">
              <p
                className="small text-white-50 mb-0"
                style={{ fontSize: "14px" }}
              >
                {heroData.description}
              </p>
            </Col>
          </Row>
        )}
      </Container>
      <style>{`
        .hero-search .overlay {
          position: absolute;
          inset: 0;
          background: rgba(0,0,0,0.45);
          z-index: 1;
        }
        .search-form .form-control,
        .search-form .form-select {
          border-radius: 6px;
        }
        .form-control:focus {
          border-color: #ddd;
          box-shadow: none;
          outline: none;
        }
        .btn-find {
          background: #e83581;
          border: none;
          color: #fff;
          border-radius: 6px;
          min-width: 160px;
          white-space: nowrap;
        }
        .btn-find:hover {
          background-color:rgb(238, 83, 148);
          color: #000;
        }
        .popular-searches a:hover {
          text-decoration: underline;
        }

        /* Dropdown animation */
        @keyframes slideDown {
          from {
            opacity: 0;
            transform: translateY(-10px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }


        .vendor-dropdown-menu::-webkit-scrollbar {
          width: 8px;
        }

        .vendor-dropdown-menu::-webkit-scrollbar-track {
          background: #f1f1f1;
          border-radius: 10px;
        }

        .vendor-dropdown-menu::-webkit-scrollbar-thumb {
          background: #e83581;
          border-radius: 10px;
        }

        .vendor-dropdown-menu::-webkit-scrollbar-thumb:hover {
          background: #d91d6e;
        }

        .dropdown-link:hover {
          color: #e83581 !important;
          padding-left: 4px;
        }

        .hero-vendor-result-item:hover {
          background: linear-gradient(to right, rgba(195, 17, 98, 0.06), transparent);
        }

        .hero-vendor-search-dropdown::-webkit-scrollbar {
          width: 6px;
        }

        .hero-vendor-search-dropdown::-webkit-scrollbar-thumb {
          background: #C31162;
          border-radius: 10px;
        }

        /* Responsive grid */
        @media (max-width: 1200px) {
          .dropdown-grid {
            column-count: 3 !important;
          }
        }

        @media (max-width: 768px) {
          .dropdown-grid {
            column-count: 2 !important;
          }
          .vendor-dropdown-menu {
            max-height: 400px !important;
          }
        }

        @media (max-width: 576px) {
          .dropdown-grid {
            column-count: 1 !important;
          }
          .vendor-dropdown-menu {
            max-height: 350px !important;
          }
        }

        @media (max-width: 991px) {
          .hero-search {
            padding-top: 80px;
            padding-bottom: 60px;
          }
          .display-5 {
            font-size: 2rem;
          }
        }
      `}</style>
    </section>
  );
};

export default Herosection;
