import React, { useState, useEffect } from "react";
import { Modal, Button } from "react-bootstrap";
import axios from "axios";
import { useDispatch, useSelector } from "react-redux";
import {
  setLocation,
  setDetectedLocation,
  clearLocation,
} from "../../redux/locationSlice";
import { useNavigate, useLocation, useParams } from "react-router-dom";
import { IoMdArrowDropdown } from "react-icons/io";
import { 
  IoSearchOutline, 
  IoClose, 
  IoLocationSharp, 
  IoGlobeOutline,
  IoArrowForward,
  IoArrowBack,
  IoCheckmark,
  IoFlameOutline,
  IoSparklesOutline,
  IoNavigateOutline,
  IoWarningOutline
} from "react-icons/io5";
import citiesData from "../../data/citiesData";
import {
  detectCurrentCity,
  isAdminAreaName,
} from "../../utils/detectCurrentCity";
import "./LocationModal.css";

const LocationModalWithCategories = () => {
  const [show, setShow] = useState(false);
  const dispatch = useDispatch();
  const selectedLocation = useSelector(
    (state) => state.location.selectedLocation
  );
  const navigate = useNavigate();
  const location = useLocation();
  const { slug, subcategory } = useParams();
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedState, setSelectedState] = useState(null);
  const [detecting, setDetecting] = useState(false);
  const [detectError, setDetectError] = useState("");
  const [apiCities, setApiCities] = useState([]);
  const [detectGuess, setDetectGuess] = useState(null);

  const staticCityData = {
    topCities: [
      "All Cities",
      "Delhi NCR",
      "Mumbai",
      "Bangalore",
      "Chennai",
      "Pune",
      "Jaipur",
      "Kolkata",
      "Hyderabad",
      "Ahmedabad",
      "Goa",
    ],
    popularCities: [
      "Mumbai",
      "Bangalore",
      "Chennai",
      "Pune",
      "Jaipur",
      "Kolkata",
      "Hyderabad",
      "Ahmedabad",
      "Goa",
      "Udaipur",
    ],
    extraCities: [
      "Nagpur",
      "Dehradun",
      "Thane",
      "Surat",
      "Vadodara",
      "Raipur",
      "Mysore",
      "Hubli",
      "Dhitara",
      "Toranagallu",
    ],
    states: Object.keys(citiesData).sort(),
    internationalCities: [
      "Dubai",
      "Thailand",
      "Bali",
      "Abu Dhabi",
    ],
  };

  // Other Cities = every city in citiesData (plus the extras above)
  // that is not already listed under Top or Popular cities
  const otherCities = React.useMemo(() => {
    const listed = new Set([
      ...staticCityData.topCities,
      ...staticCityData.popularCities,
    ]);
    const list = new Set(staticCityData.extraCities);
    Object.values(citiesData).forEach((venues) => {
      venues.forEach((v) => {
        const clean = v.replace(/^Wedding Venues\s*/i, "").trim();
        if (!listed.has(clean)) list.add(clean);
      });
    });
    return Array.from(list)
      .filter((c) => !listed.has(c))
      .sort();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Local Search over all cities in citiesData
  const allLocalCities = React.useMemo(() => {
    const list = new Set();
    Object.values(citiesData).forEach((venues) => {
      venues.forEach((v) => {
        const clean = v.replace(/^Wedding Venues\s*/i, "").trim();
        list.add(clean);
      });
    });
    // Add other static cities
    staticCityData.topCities.forEach(c => { if(c !== "All Cities") list.add(c); });
    staticCityData.popularCities.forEach(c => list.add(c));
    staticCityData.extraCities.forEach(c => list.add(c));
    staticCityData.internationalCities.forEach(c => list.add(c));
    return Array.from(list).sort();
  }, []);

  // Full India city list, fetched once the modal is first opened so the search
  // box covers every city (Dhule, Dhulagari, ...) and not just our curated set.
  useEffect(() => {
    if (!show || apiCities.length) return;

    let cancelled = false;
    axios
      .get("https://countriesnow.space/api/v0.1/countries/cities/q", {
        params: { country: "India" },
      })
      .then((res) => {
        if (cancelled) return;
        const data = res?.data?.data;
        if (Array.isArray(data)) setApiCities(data);
      })
      .catch(() => {
        // Offline / API down - the local list below still works
      });

    return () => {
      cancelled = true;
    };
  }, [show, apiCities.length]);

  // Curated cities first, then everything the API knows about
  const searchableCities = React.useMemo(() => {
    const seen = new Set(allLocalCities.map((c) => c.toLowerCase()));
    const merged = [...allLocalCities];
    apiCities.forEach((city) => {
      const clean = String(city).trim();
      const key = clean.toLowerCase();
      // The API lists administrative areas ("Pune Division") alongside real
      // cities - they aren't places anyone searches for.
      if (isAdminAreaName(clean)) return;
      if (clean && !seen.has(key)) {
        seen.add(key);
        merged.push(clean);
      }
    });
    return merged;
  }, [allLocalCities, apiCities]);

  const MAX_SEARCH_RESULTS = 60;

  const filterCities = React.useMemo(() => {
    const term = searchTerm.trim().toLowerCase();
    if (!term) return [];

    const startsWith = [];
    const contains = [];
    searchableCities.forEach((city) => {
      const lower = city.toLowerCase();
      if (lower.startsWith(term)) startsWith.push(city);
      else if (lower.includes(term)) contains.push(city);
    });

    const sortByName = (a, b) => a.localeCompare(b);
    return [...startsWith.sort(sortByName), ...contains.sort(sortByName)].slice(
      0,
      MAX_SEARCH_RESULTS
    );
  }, [searchTerm, searchableCities]);

  const handleCityClick = (city, { detected = false } = {}) => {
    const cleanCity = city.toLowerCase();
    const cleanCitySlug = cleanCity
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+|-+$/g, "");

    if (city === "All Cities") {
      dispatch(clearLocation());
    } else if (detected) {
      // Geolocated, not hand-picked: keep re-detecting on future visits
      dispatch(setDetectedLocation(city));
    } else {
      dispatch(setLocation(city));
    }
    setShow(false);
    setSearchTerm("");
    setSelectedState(null);
    document.body.style.overflow = "auto";

    const isVenuesPage = location.pathname.includes("/venues") || location.pathname.includes("/wedding-venues");
    const isVendorsPage = location.pathname.startsWith("/vendors/") || location.pathname.startsWith("/vendors");
    const isPhotographyPage = location.pathname.startsWith("/photography/") || location.pathname.startsWith("/photography");

    if (isVenuesPage) {
      navigate(
        city === "All Cities" ? "/venues" : `/wedding-venues/${cleanCitySlug}`
      );
    } else if (isVendorsPage) {
      const activeCat = subcategory || slug || "all";
      navigate(
        city === "All Cities" ? `/vendors/${activeCat}` : `/vendors/${activeCat}/${cleanCitySlug}`
      );
    } else if (isPhotographyPage) {
      const activeCat = subcategory || slug || "all";
      navigate(
        city === "All Cities" ? `/photography/${activeCat}` : `/photography/${activeCat}/${cleanCitySlug}`
      );
    } else {
      navigate(
        city === "All Cities" ? "/vendors/all" : `/vendors/all/${cleanCitySlug}`
      );
    }
  };

  const handleUseCurrentLocation = async () => {
    setDetectError("");
    setDetectGuess(null);
    setDetecting(true);
    try {
      const { city, approximate, coords } = await detectCurrentCity(
        allLocalCities,
        { precise: true }
      );

      // A loose fix means the browser fell back to IP lookup, which points at
      // the ISP's gateway - offer the guess instead of silently applying it.
      if (approximate) {
        setDetectGuess({ city, accuracy: coords?.accuracy });
        return;
      }

      handleCityClick(city, { detected: true });
    } catch (err) {
      setDetectError(err?.message || "We couldn't detect your location.");
    } finally {
      setDetecting(false);
    }
  };

  const handleModalClose = () => {
    setShow(false);
    setSearchTerm("");
    setSelectedState(null);
    setDetectError("");
    setDetectGuess(null);
  };

  return (
    <>
      <div style={{ position: "relative", display: "inline-block" }}>
        <Button
          variant="outline-light"
          className="border-danger rounded-0 text-dark d-flex align-items-center justify-content-between px-2"
          onClick={() => setShow(true)}
          style={{
            minWidth: 130,
            height: 30,
            fontSize: "13px",
            backgroundColor: "#fff",
          }}
        >
          <span className="d-flex align-items-center gap-2">
            {selectedLocation && selectedLocation !== "unknown" ? (
              <span className="fw-medium">{selectedLocation}</span>
            ) : (
              <span className="text-dark fs-14">Select Location</span>
            )}
          </span>
          <IoMdArrowDropdown size={16} color="#000" />
        </Button>
      </div>

      <Modal
        show={show}
        onHide={handleModalClose}
        size="xl"
        centered
        className="hw-location-modal"
        backdrop={true}
        keyboard={true}
      >
        <Modal.Body style={{ padding: 0 }}>
          {/* Header & Search */}
          <div className="hw-location-modal-header">
            <div className="hw-location-header-top">
              <div className="hw-location-title-group">
                <div className="hw-location-title-icon">
                  <IoLocationSharp />
                </div>
                <div>
                  <h5 className="hw-location-title">Select Your City</h5>
                  <p className="hw-location-subtitle">
                    Discover wedding venues, vendors and romantic escapes in your area
                  </p>
                </div>
              </div>
              <button 
                className="hw-location-close-btn" 
                onClick={handleModalClose}
                aria-label="Close"
              >
                <IoClose />
              </button>
            </div>

            <div className="hw-location-search-row">
              <div className="hw-location-search-box">
                <IoSearchOutline className="hw-location-search-icon" />
                <input
                  type="text"
                  placeholder="Search City, State..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="hw-location-search-input"
                  autoFocus
                />
                {searchTerm && (
                  <button 
                    className="hw-location-clear-search"
                    onClick={() => setSearchTerm("")}
                  >
                    <IoClose />
                  </button>
                )}
              </div>

              <button
                type="button"
                className="hw-use-location-btn"
                onClick={handleUseCurrentLocation}
                disabled={detecting}
              >
                <span className="hw-use-location-icon">
                  {detecting ? (
                    <span className="hw-use-location-spinner" />
                  ) : (
                    <IoNavigateOutline />
                  )}
                </span>
                <span className="hw-use-location-title">
                  {detecting ? "Detecting location…" : "Use my current location"}
                </span>
              </button>
            </div>

            {detectError && (
              <div className="hw-use-location-error">
                <IoWarningOutline />
                <span>{detectError}</span>
              </div>
            )}

            {detectGuess && (
              <div className="hw-use-location-confirm">
                <IoWarningOutline />
                <div className="hw-use-location-confirm-text">
                  <strong>Is {detectGuess.city} correct?</strong>
                  <span>
                    Your browser could only place you roughly
                    {typeof detectGuess.accuracy === "number"
                      ? ` (within ~${Math.round(detectGuess.accuracy / 1000)} km)`
                      : ""}
                    , so this may be your internet provider's city rather than
                    yours. Turn on device location for an exact match, or pick a
                    city below.
                  </span>
                </div>
                <button
                  type="button"
                  className="hw-use-location-confirm-btn"
                  onClick={() => {
                    const city = detectGuess.city;
                    setDetectGuess(null);
                    handleCityClick(city, { detected: true });
                  }}
                >
                  Use {detectGuess.city}
                </button>
              </div>
            )}
          </div>

          {/* Body Content */}
          <div className="hw-location-body">
            {searchTerm.trim() ? (
              <div className="hw-location-search-results">
                {filterCities.length === 0 ? (
                  <div className="hw-search-empty">
                    <div className="hw-search-empty-icon">
                      <IoLocationSharp />
                    </div>
                    <div className="fw-bold fs-15 text-dark mb-1">No cities found</div>
                    <div className="fs-13">We couldn't find any results for "{searchTerm}"</div>
                  </div>
                ) : (
                  <div>
                    <div className="text-muted fs-12 fw-bold text-uppercase mb-3">
                      Search Results ({filterCities.length}
                      {filterCities.length === MAX_SEARCH_RESULTS ? "+" : ""})
                    </div>
                    <div className="hw-search-results-grid">
                      {filterCities.map((city) => {
                        const isSelected = selectedLocation === city;
                        return (
                          <div
                            key={city}
                            className={`hw-search-result-chip ${isSelected ? "is-selected" : ""}`}
                            onClick={() => handleCityClick(city)}
                          >
                            <IoLocationSharp style={{ color: "#ed1173" }} />
                            <span>{city}</span>
                            {isSelected && <IoCheckmark className="ms-auto" style={{ color: "#ed1173" }} />}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}
              </div>
            ) : selectedState ? (
              <div className="hw-state-view">
                <div className="hw-state-header">
                  <button
                    className="hw-back-btn"
                    onClick={() => setSelectedState(null)}
                  >
                    <IoArrowBack />
                    <span>Back to States</span>
                  </button>
                  <h5 className="hw-state-title">{selectedState} Venues & Cities</h5>
                </div>
                <div className="hw-state-grid">
                  {(citiesData[selectedState] || []).map((venueText) => {
                    const city = venueText.replace(/^Wedding Venues\s*/i, "").trim();
                    const isSelected = selectedLocation === city;
                    return (
                      <div
                        key={city}
                        className={`hw-state-city-card ${isSelected ? "is-selected" : ""}`}
                        onClick={() => handleCityClick(city)}
                      >
                        <span>{city}</span>
                        {isSelected ? (
                          <IoCheckmark style={{ color: "#ed1173" }} />
                        ) : (
                          <IoArrowForward style={{ color: "#94a3b8", fontSize: "12px" }} />
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="hw-location-grid">
                {/* Column 1: Top Cities */}
                <div className="hw-location-col">
                  <div className="hw-location-col-header">
                    <span className="hw-location-col-badge">
                      <IoFlameOutline />
                    </span>
                    <h6 className="hw-location-col-title">Top Cities</h6>
                  </div>
                  <div className="hw-location-list">
                    {staticCityData.topCities.map((city) => {
                      const isSelected = (city === "All Cities" && !selectedLocation) || selectedLocation === city;
                      return (
                        <div
                          key={city}
                          className={`hw-location-item ${isSelected ? "is-selected" : ""}`}
                          onClick={() => handleCityClick(city)}
                        >
                          <span>{city}</span>
                          {isSelected && <IoCheckmark className="hw-location-check" />}
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Column 2: Popular Cities */}
                <div className="hw-location-col">
                  <div className="hw-location-col-header">
                    <span className="hw-location-col-badge">
                      <IoSparklesOutline />
                    </span>
                    <h6 className="hw-location-col-title">Popular Cities</h6>
                  </div>
                  <div className="hw-location-list">
                    {staticCityData.popularCities.map((city) => {
                      const isSelected = selectedLocation === city;
                      return (
                        <div
                          key={city}
                          className={`hw-location-item ${isSelected ? "is-selected" : ""}`}
                          onClick={() => handleCityClick(city)}
                        >
                          <span>{city}</span>
                          {isSelected && <IoCheckmark className="hw-location-check" />}
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Column 3: Other Cities */}
                <div className="hw-location-col">
                  <div className="hw-location-col-header">
                    <span className="hw-location-col-badge">
                      <IoLocationSharp />
                    </span>
                    <h6 className="hw-location-col-title">Other Cities</h6>
                  </div>
                  <div className="hw-location-list">
                    {otherCities.map((city) => {
                      const isSelected = selectedLocation === city;
                      return (
                        <div
                          key={city}
                          className={`hw-location-item ${isSelected ? "is-selected" : ""}`}
                          onClick={() => handleCityClick(city)}
                        >
                          <span>{city}</span>
                          {isSelected && <IoCheckmark className="hw-location-check" />}
                        </div>
                      );
                    })}
                  </div>
                </div>

                {/* Column 4: States */}
                <div className="hw-location-col">
                  <div className="hw-location-col-header">
                    <span className="hw-location-col-badge">
                      <IoArrowForward />
                    </span>
                    <h6 className="hw-location-col-title">States</h6>
                  </div>
                  <div className="hw-location-list">
                    {staticCityData.states.map((state) => (
                      <div
                        key={state}
                        className="hw-location-item"
                        onClick={() => setSelectedState(state)}
                      >
                        <span>{state}</span>
                        <IoArrowForward className="hw-location-arrow" />
                      </div>
                    ))}
                  </div>
                </div>

                {/* Column 5: International Cities */}
                <div className="hw-location-col">
                  <div className="hw-location-col-header">
                    <span className="hw-location-col-badge">
                      <IoGlobeOutline />
                    </span>
                    <h6 className="hw-location-col-title">International</h6>
                  </div>
                  <div className="hw-location-list">
                    {staticCityData.internationalCities.map((city) => {
                      const isSelected = selectedLocation === city;
                      return (
                        <div
                          key={city}
                          className={`hw-location-item ${isSelected ? "is-selected" : ""}`}
                          onClick={() => handleCityClick(city)}
                        >
                          <span>{city}</span>
                          {isSelected && <IoCheckmark className="hw-location-check" />}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            )}
          </div>
        </Modal.Body>
      </Modal>
    </>
  );
};

export default LocationModalWithCategories;
