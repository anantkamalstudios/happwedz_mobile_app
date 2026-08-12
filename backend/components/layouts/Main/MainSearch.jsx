import React, { useMemo, useState, useEffect, useRef } from "react";
import { Row, Col, Form, Button } from "react-bootstrap";
import { CiSearch } from "react-icons/ci";
import { FaSearch, FaStar } from "react-icons/fa";
import { Link, useParams, useLocation } from "react-router-dom";
import axios from "axios";
import { useSelector } from "react-redux";

const MainSearch = ({ title = "Wedding Venues", onSearch }) => {
  const { slug: routeSlug, subcategory, city: routeCity } = useParams();
  const location = useLocation();
  const isNestedVendor = location.pathname.startsWith("/vendors/");
  const isNestedPhotography = location.pathname.startsWith("/photography/");
  const slug = (isNestedVendor || isNestedPhotography) ? subcategory : routeSlug;
  const [keyword, setKeyword] = useState("");
  const [place, setPlace] = useState("");
  const [cities, setCities] = useState([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [searchResults, setSearchResults] = useState([]);
  const [loadingSearch, setLoadingSearch] = useState(false);
  const [showResults, setShowResults] = useState(false);
  const debounceTimer = useRef(null);
  const searchRef = useRef(null);
  const { section } = useParams();
  const [heroInfo, setHeroInfo] = useState([]);
  const cleanMediaUrl = (m) => {
    if (!m) return null;
    if (typeof m === "string") return m.replace(/[`"']/g, "").trim();
    if (typeof m === "object" && m.url) return String(m.url).trim();
    return null;
  };

  useEffect(() => {
    const fetchHeroInfo = async () => {
      try {
        const response = await axios.get("/api/hero-sections");
        const dataInfo = response.data;

        const pathSegments = location.pathname.split("/").filter(Boolean);

        // 1) Detect base section from main route (/vendor, /venue, /photography etc.)
        const baseSectionRaw = pathSegments[0]?.toLowerCase();

        const baseSection = (() => {
          if (baseSectionRaw === "vendor") return "vendors";
          if (baseSectionRaw === "venue") return "venues";

          if (
            ["photographer", "photography", "photos", "photo"].includes(
              baseSectionRaw
            )
          )
            return "photography";

          return baseSectionRaw;
        })();

        // Helper to normalize all possible inputs
        const normalizeType = (t) => {
          const v = (t || "").toLowerCase();

          if (v.includes("venue")) return "venues";
          if (v.includes("vendor")) return "vendors";
          if (
            v.includes("photo") ||
            v.includes("graphy") ||
            v.includes("photographer")
          )
            return "photography";

          return v || null;
        };

        // 2) Derive final section priority
        const effectiveSection = (() => {
          const sec = section?.toLowerCase();

          if (["venue", "venues"].includes(sec)) return "venues";
          if (["vendor", "vendors"].includes(sec)) return "vendors";
          if (["photography", "photographer", "photo", "photos"].includes(sec))
            return "photography";

          // Check pathname fallbacks
          if (
            location.pathname.includes("/venues") ||
            location.pathname.includes("/venue") ||
            location.pathname.includes("/wedding-venues")
          )
            return "venues";

          if (
            location.pathname.includes("/vendors") ||
            location.pathname.includes("/vendor")
          )
            return "vendors";

          if (
            location.pathname.includes("/photography") ||
            location.pathname.includes("/photo") ||
            location.pathname.includes("/photographer")
          )
            return "photography";

          return baseSection || null;
        })();

        // 3) Match API item
        let matched = dataInfo.find(
          (item) => normalizeType(item?.navbar?.type) === effectiveSection
        );

        // fallback partial include
        if (!matched && effectiveSection) {
          matched = dataInfo.find((item) =>
            (item?.navbar?.type || "").toLowerCase().includes(effectiveSection)
          );
        }

        setHeroInfo(matched || null);
      } catch (error) {
        console.error("Error fetching hero info:", error);
      }
    };

    fetchHeroInfo();
  }, [section, location.pathname]);

  const searchParams = new URLSearchParams(location.search);
  const vendorType = searchParams.get("vendorType");

  const reduxLocation = useSelector((state) => state.location.selectedLocation);
  const cityParam = searchParams.get("city");
  
  const formatCityName = (cityStr) => {
    if (!cityStr) return "";
    const decoded = decodeURIComponent(cityStr);
    return decoded
      .split(/[\s-]+/)
      .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join(" ");
  };

  const city = (isNestedVendor || isNestedPhotography) ? formatCityName(routeCity) : (cityParam || reduxLocation || null);
  const isVenuePage = location.pathname.includes("/venues") || location.pathname.includes("/wedding-venues");

  const dynamicTitle = useMemo(() => {
    if (vendorType) {
      const formattedVendorType = vendorType
        .split(" ")
        .map(
          (word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
        )
        .join(" ");

      if (city) {
        return `${formattedVendorType} in ${city}`;
      }
      return formattedVendorType;
    }

    if (slug && slug.toLowerCase() !== "all") {
      const formattedSlug = slug
        .replace(/-/g, " ")
        .split(" ")
        .map(
          (word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
        )
        .join(" ");

      if (city) {
        return `${formattedSlug} in ${city}`;
      }
      return formattedSlug;
    }

    if (slug && slug.toLowerCase() === "all") {
      const pathSegments = location.pathname
        .split("/")
        .filter((segment) => segment);
      if (pathSegments.length >= 1) {
        const category = pathSegments[0];
        const formattedCategory = category
          .split(" ")
          .map(
            (word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
          )
          .join(" ");
        return city
          ? `${formattedCategory} in ${city}`
          : `All ${formattedCategory}`;
      }
    }

    if (city && !vendorType && !slug) {
      if (isVenuePage) {
        return `Wedding Venues in ${city}`;
      }
      return `Wedding Vendors in ${city}`;
    }

    return title || "Plan your perfect day";
  }, [vendorType, city, title, slug, location.pathname, isVenuePage]);

  const placeholders = useMemo(() => {
    const section = (title || "").toLowerCase();
    let keywordPh = "";
    let subtitle = "";

    const effectiveVendorType =
      vendorType || (slug && slug !== "all" ? slug.replace(/-/g, " ") : null);

    if (effectiveVendorType && city) {
      const formattedVendorType = effectiveVendorType.toLowerCase();
      const formattedCity =
        city.charAt(0).toUpperCase() + city.slice(1).toLowerCase();

      switch (true) {
        case formattedVendorType.includes("venue") ||
          formattedVendorType.includes("resort"):
          keywordPh = "Banquet halls, resorts, lawns";
          subtitle = `Discover the perfect wedding venues in ${formattedCity} for your special day`;
          break;
        case formattedVendorType.includes("photographer"):
          keywordPh = "Photographers, shoots, poses";
          subtitle = `Find the best wedding photographers in ${formattedCity} to capture your memories`;
          break;
        case formattedVendorType.includes("makeup"):
          keywordPh = "Makeup artists, bridal looks";
          subtitle = `Get the perfect bridal makeup in ${formattedCity} for your wedding day`;
          break;
        case formattedVendorType.includes("catering"):
          keywordPh = "Caterers, food services";
          subtitle = `Delicious wedding catering options in ${formattedCity} for your guests`;
          break;
        case formattedVendorType.includes("decoration") ||
          formattedVendorType.includes("decorator"):
          keywordPh = "Decorators, wedding themes";
          subtitle = `Beautiful wedding decorations in ${formattedCity} to make your day magical`;
          break;
        default:
          keywordPh = "Find Best Options";
          subtitle = `Discover the best ${effectiveVendorType.toLowerCase()} services in ${formattedCity}`;
      }
    } else {
      switch (true) {
        case section.includes("venue"):
          keywordPh = "Banquet halls, resorts, lawns";
          subtitle = city
            ? `Banquet halls, lawns and resorts in ${city} — compare price per plate and capacity`
            : "Banquet halls, lawns and resorts — compare price per plate and capacity";
          break;
        case section.includes("vendor"):
          keywordPh = "Decor, catering, planners";
          subtitle = city
            ? `Everything you need in ${city} – from planners to caterers – to make your day hassle-free`
            : "Everything you need – from planners to caterers – to make your day hassle-free";
          break;
        case section.includes("photo"):
        case section.includes("photography"):
          keywordPh = "Photographers, shoots, poses";
          subtitle = city
            ? `Capture your special moments in ${city} with the best wedding photographers`
            : "Capture your special moments with the best wedding photographers";
          break;
        case section.includes("invite"):
        case section.includes("e-invite"):
          keywordPh = "Wedding cards, digital invites";
          subtitle = city
            ? `Send beautiful invites to your loved ones in ${city} – traditional or digital`
            : "Send beautiful invites to your loved ones – traditional or digital";
          break;
        default:
          keywordPh = "Find Best Options";
          subtitle = city
            ? `Plan your dream wedding in ${city} with the best options available`
            : "Plan your dream wedding with the best options available";
      }
    }

    const placePh = "City or locality";
    return { keywordPh, placePh, subtitle };
  }, [title, vendorType, city, slug]);

  const handleSubmit = (e) => {
    e.preventDefault();
    if (onSearch) onSearch({ keyword, place });
  };

  const performSearch = async (searchQuery) => {
    if (!searchQuery || searchQuery.length < 2) {
      setSearchResults([]);
      setShowResults(false);
      return;
    }
    setLoadingSearch(true);
    try {
      let apiUrl = `https://happywedz.com/api/vendor-services?search=${encodeURIComponent(
        searchQuery
      )}&limit=10`;

      if (city) {
        apiUrl += `&city=${encodeURIComponent(city)}`;
      }

      if (isVenuePage) {
        apiUrl += `&vendorType=Venues`;
      } else if (vendorType) {
        apiUrl += `&vendorType=${encodeURIComponent(vendorType)}`;
      } else if (slug && slug.toLowerCase() !== "all") {
        const subCategory = slug
          .replace(/-{2,}/g, " / ")
          .replace(/-/g, " ")
          .replace(/\s*\/\s*/g, " / ")
          .replace(/\s{2,}/g, " ")
          .replace(/\b\w/g, (l) => l.toUpperCase())
          .trim();
        apiUrl += `&subCategory=${encodeURIComponent(subCategory)}`;
      }
      const response = await axios.get(apiUrl);
      const results = response.data?.data || [];
      
      // Deduplicate results to avoid duplicate vendor items caused by sub-vendor master profiles joins
      const uniqueResults = [];
      const seenIds = new Set();
      const seenNames = new Set();

      results.forEach((item) => {
        if (!item) return;
        const id = item.id;
        const name = (item.attributes?.name || item.vendor?.businessName || "").trim().toLowerCase();
        const city = (item.attributes?.city || item.vendor?.city || "").trim().toLowerCase();
        const nameKey = `${name}|${city}`;

        if (id && !seenIds.has(id)) {
          if (!name || !seenNames.has(nameKey)) {
            seenIds.add(id);
            if (name) seenNames.add(nameKey);
            uniqueResults.push(item);
          }
        }
      });

      setSearchResults(uniqueResults);
      setShowResults(uniqueResults.length > 0);
    } catch {
      setSearchResults([]);
      setShowResults(false);
    } finally {
      setLoadingSearch(false);
    }
  };

  const handleKeywordChange = (e) => {
    const value = e.target.value;
    setKeyword(value);
    if (debounceTimer.current) clearTimeout(debounceTimer.current);
    debounceTimer.current = setTimeout(() => {
      performSearch(value);
    }, 500);
  };

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (searchRef.current && !searchRef.current.contains(event.target)) {
        setShowResults(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
      if (debounceTimer.current) clearTimeout(debounceTimer.current);
    };
  }, []);

  useEffect(() => {
    axios
      .post("https://countriesnow.space/api/v0.1/countries/cities", {
        country: "India",
      })
      .then((res) => {
        if (res.data && res.data.data) setCities(res.data.data);
        else setCities([]);
      })
      .catch(() => setCities([]));
  }, []);

  const filteredCities = cities.filter((city) =>
    city.toLowerCase().startsWith(searchTerm.toLowerCase())
  );

  return (
    <section
      className="position-relative"
      style={{
        overflow: "visible",
        background:
          "linear-gradient(135deg, rgba(255, 114, 134, 0.08) 0%, rgba(137, 62, 247, 0.08) 100%)",

        position: "relative",
      }}
    >
      <style>
        {`
          .search-input-focus {
            transition: all 0.3s ease;
          }
          
          .search-input-focus:focus-within {
            box-shadow: 0 8px 16px rgba(195, 17, 98, 0.15);
            border-color: #C31162 !important;
          }

          .search-btn-hover {
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
          }

          .search-btn-hover::before {
            content: '';
            position: absolute;
            top: 50%;
            left: 50%;
            width: 0;
            height: 0;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            transform: translate(-50%, -50%);
            transition: width 0.6s, height 0.6s;
          }

          .search-btn-hover:hover::before {
            width: 300px;
            height: 300px;
          }

          .search-btn-hover:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 20px rgba(195, 17, 98, 0.4);
          }

          .dropdown-results {
            animation: slideDown 0.3s ease-out;
          }

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

          .result-item-hover {
            transition: all 0.2s ease;
            cursor: pointer;
          }

          .result-item-hover:hover {
            background: linear-gradient(to right, rgba(195, 17, 98, 0.05), transparent);
            transform: translateX(4px);
          }

          .result-item-hover:hover .result-image {
            transform: scale(1.05);
          }

          .result-image {
            transition: transform 0.3s ease;
          }

          .custom-scrollbar::-webkit-scrollbar {
            width: 6px;
          }

          .custom-scrollbar::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 10px;
          }

          .custom-scrollbar::-webkit-scrollbar-thumb {
            background: #C31162;
            border-radius: 10px;
          }

          .custom-scrollbar::-webkit-scrollbar-thumb:hover {
            background: #A10F4F;
          }
        `}
      </style>

      <div className="container py-4 py-md-5" style={{ height: "330px" }}>
        <Row className="align-items-center g-4 g-lg-5">
          <Col xs={12} lg={6}>
            <div className="pe-lg-4">
              <h1 className="mb-3 fs-24 fw-bold">{dynamicTitle}</h1>
              <p className="text-muted mb-4 fs-16">{placeholders.subtitle}</p>
              {/* <p className="text-muted mb-4">{heroInfo?.subtitle}</p> */}

              <Form
                onSubmit={handleSubmit}
                className="w-100 position-relative"
                ref={searchRef}
              >
                <div
                  className="d-flex flex-column flex-md-row align-items-stretch gap-3 p-2"
                  style={{
                    maxWidth: 680,
                    overflow: "visible",
                    position: "relative",
                  }}
                >
                  <div
                    className="search-input-focus d-flex align-items-center flex-grow-1 px-3 py-1 bg-white position-relative"
                    style={{
                      border: "2px solid #e5e7eb",
                      borderRadius: "12px",
                      boxShadow: "0 2px 4px rgba(0,0,0,0.04)",
                    }}
                  >
                    <FaSearch
                      className="me-2"
                      style={{ color: "#9ca3af", fontSize: "1rem" }}
                    />
                    <Form.Control
                      value={keyword}
                      onChange={handleKeywordChange}
                      type="text"
                      placeholder={placeholders.keywordPh}
                      className="border-0 shadow-none"
                      style={{ background: "transparent", fontSize: "0.95rem" }}
                      onFocus={() =>
                        keyword.length >= 2 && setShowResults(true)
                      }
                    />
                  </div>
                  <Button
                    type="submit"
                    className="search-btn-hover d-flex align-items-center justify-content-center gap-2 border-0"
                    style={{
                      whiteSpace: "nowrap",
                      backgroundColor: "#C31162",
                      color: "#fff",
                      padding: "0.75rem 2rem",
                      borderRadius: "12px",
                      fontWeight: 600,
                      fontSize: "0.95rem",
                    }}
                  >
                    <CiSearch size={20} />
                    Search
                  </Button>
                </div>

                {showResults && (
                  <div
                    className="dropdown-results position-absolute bg-white shadow-lg rounded-3 mt-2 custom-scrollbar"
                    style={{
                      top: "100%",
                      left: 0,
                      right: 0,
                      maxWidth: 680,
                      maxHeight: "400px",
                      overflowY: "auto",
                      overflowX: "hidden",
                      zIndex: 1100,
                      border: "1px solid #e5e7eb",
                    }}
                  >
                    {loadingSearch ? (
                      <div className="p-4 text-center">
                        <div
                          className="spinner-border spinner-border-sm me-2"
                          role="status"
                          style={{ color: "#C31162" }}
                        >
                          <span className="visually-hidden">Loading...</span>
                        </div>
                        <span style={{ color: "#6b7280", fontSize: "0.9rem" }}>
                          Searching...
                        </span>
                      </div>
                    ) : searchResults.length > 0 ? (
                      <div>
                        {searchResults.map((result) => (
                          <Link
                            key={result.id}
                            to={`/details/info/${result.slug || result.id}`}
                            className="result-item-hover d-block text-decoration-none border-bottom"
                            style={{ color: "inherit" }}
                            onClick={() => setShowResults(false)}
                          >
                            <div className="d-flex align-items-center gap-3 p-3">
                              <div
                                className="flex-shrink-0 overflow-hidden"
                                style={{ borderRadius: "10px" }}
                              >
                                <img
                                  src={
                                    result.attributes?.image_url ||
                                    cleanMediaUrl(result.media?.[0]) ||
                                    "/images/imageNotFound.jpg"
                                  }
                                  alt={result.attributes?.name || "Vendor"}
                                  className="result-image"
                                  style={{
                                    width: "64px",
                                    height: "64px",
                                    objectFit: "cover",
                                  }}
                                  onError={(e) => {
                                    e.target.onerror = null;
                                    e.target.src = "/images/imageNotFound.jpg";
                                  }}
                                />
                              </div>
                              <div className="flex-grow-1 overflow-hidden">
                                <h6
                                  className="mb-1 fw-semibold text-truncate"
                                  style={{
                                    fontSize: "0.95rem",
                                    color: "#1f2937",
                                  }}
                                >
                                  {result.attributes?.name ||
                                    result.vendor?.businessName ||
                                    "Vendor"}
                                </h6>
                                <div className="d-flex align-items-center gap-2 mb-1">
                                  <FaStar size={13} className="text-warning" />
                                  <span
                                    style={{
                                      fontSize: "0.85rem",
                                      color: "#6b7280",
                                    }}
                                  >
                                    <strong style={{ color: "#374151" }}>
                                      {result.attributes?.rating || 0}
                                    </strong>{" "}
                                    ({result.attributes?.review_count || 0}{" "}
                                    reviews)
                                  </span>
                                </div>
                                <p
                                  className="mb-0 d-flex align-items-center gap-1"
                                  style={{
                                    fontSize: "0.85rem",
                                    color: "#9ca3af",
                                  }}
                                >
                                  <svg
                                    width="12"
                                    height="12"
                                    viewBox="0 0 24 24"
                                    fill="none"
                                    stroke="currentColor"
                                    strokeWidth="2"
                                  >
                                    <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                                    <circle cx="12" cy="10" r="3" />
                                  </svg>
                                  {result.attributes?.city ||
                                    result.vendor?.city ||
                                    "Location"}
                                </p>
                              </div>
                            </div>
                          </Link>
                        ))}
                      </div>
                    ) : (
                      <div className="p-4 text-center">
                        <svg
                          width="48"
                          height="48"
                          viewBox="0 0 24 24"
                          fill="none"
                          stroke="#d1d5db"
                          strokeWidth="2"
                          className="mx-auto mb-2"
                        >
                          <circle cx="11" cy="11" r="8" />
                          <path d="m21 21-4.35-4.35" />
                        </svg>
                        <p
                          className="mb-0"
                          style={{ color: "#6b7280", fontSize: "0.9rem" }}
                        >
                          No results found for "<strong>{keyword}</strong>"
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </Form>
            </div>
          </Col>
          <Col xs={12} lg={6} className="position-static">
            <div
              className="d-none d-lg-block position-absolute top-0 end-0 h-100"
              style={{
                width: "40%",
                zIndex: 1,
                paddingTop: "1rem",
                paddingBottom: "1rem",
              }}
            >
              <div
                className="bg-white shadow rounded-start-4 overflow-hidden w-100 h-100"
                style={{
                  aspectRatio: "1/1",
                }}
              >
                <img
                  src={
                    "https://happywedzbackend.happywedz.com/uploads/herosection/" +
                    heroInfo?.image
                  }
                  alt="Search showcase"
                  className="w-100 h-100"
                  style={{ objectFit: "cover" }}
                  onError={(e) => {
                    e.currentTarget.src = "logo-no-bg.png";
                    e.currentTarget.style.objectFit = "cover";
                  }}
                />
              </div>
            </div>
          </Col>
        </Row>
      </div>
    </section>
  );
};

export default MainSearch;
