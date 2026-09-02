import React, { useState, useEffect, useRef, useMemo } from "react";
import axios from "axios";
import {
  FaMapMarkerAlt,
  FaSearch,
  FaChevronDown,
  FaChevronUp,
} from "react-icons/fa";
import { BsExclamationTriangle } from "react-icons/bs";
import { API_BASE_URL } from "../../../config/constants";
import { useFilter } from "../../../context/realWedding.context.jsx";

const RealWeddings = ({ onPostClick }) => {
  const {
    searchTerm,
    setSearchTerm,
    selectCity,
    setSelectCity,
    selectedCulture,
    setSelectedCulture,
    selectedTheme,
    setSelectedTheme,
    cities,
    cultures,
    themes,
    clearFilters,
  } = useFilter();

  const token = localStorage.getItem("token");
  const [weddings, setWeddings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [isCityDropdownOpen, setIsCityDropdownOpen] = useState(false);
  const [isThemeDropdownOpen, setIsThemeDropdownOpen] = useState(false);
  const [isCultureDropdownOpen, setIsCultureDropdownOpen] = useState(false);
  const [citySearchTerm, setCitySearchTerm] = useState("");
  const filterRef = useRef(null);
  const cityDropdownRef = useRef(null);
  const themeDropdownRef = useRef(null);
  const cultureDropdownRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (
        cityDropdownRef.current &&
        !cityDropdownRef.current.contains(event.target)
      ) {
        setIsCityDropdownOpen(false);
      }
      if (
        themeDropdownRef.current &&
        !themeDropdownRef.current.contains(event.target)
      ) {
        setIsThemeDropdownOpen(false);
      }
      if (
        cultureDropdownRef.current &&
        !cultureDropdownRef.current.contains(event.target)
      ) {
        setIsCultureDropdownOpen(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => {
      document.removeEventListener("mousedown", handleClickOutside);
    };
  }, []);

  const filteredCities = useMemo(() => {
    return cities.filter((city) =>
      city.toLowerCase().includes(citySearchTerm.toLowerCase())
    );
  }, [cities, citySearchTerm]);

  const handleCitySelect = (selected) => {
    setSelectCity(selected);
    setCurrentPage(1);
    setIsCityDropdownOpen(false);
    setCitySearchTerm("");
  };

  const handleThemeSelect = (selected) => {
    setSelectedTheme(selected);
    setCurrentPage(1);
    setIsThemeDropdownOpen(false);
  };

  const handleCultureSelect = (selected) => {
    setSelectedCulture(selected);
    setCurrentPage(1);
    setIsCultureDropdownOpen(false);
  };

  const itemsPerPage = 6;

  useEffect(() => {
    const parseJSON = (value, fallback = []) => {
      if (!value) return fallback;
      if (Array.isArray(value)) return value;
      try {
        const parsed = JSON.parse(value);
        return Array.isArray(parsed) ? parsed : fallback;
      } catch (err) {
        return fallback;
      }
    };

    const normalizeWedding = (wedding) => ({
      id: wedding.id,
      title: wedding.title,
      slug: wedding.slug,
      city: wedding.city || "",
      culture: (() => {
        const cultures = parseJSON(
          wedding.cultures ?? wedding.culture,
          wedding.cultures && typeof wedding.cultures === "string"
            ? wedding.cultures.split(",")
            : []
        );
        if (Array.isArray(cultures) && cultures.length > 0) {
          return cultures[0];
        }
        return typeof wedding.culture === "string" ? wedding.culture : "";
      })(),
      themes: parseJSON(wedding.themes, []),
      brideName: wedding.bride_name || wedding.brideName || "",
      brideBio: wedding.bride_bio || wedding.brideBio || "",
      groomName: wedding.groom_name || wedding.groomName || "",
      groomBio: wedding.groom_bio || wedding.groomBio || "",
      weddingDate: wedding.wedding_date || wedding.weddingDate || "",
      story: wedding.story || "",
      coverPhoto: wedding.cover_photo || wedding.coverPhoto || "",
      highlightPhotos: parseJSON(
        wedding.highlight_photos || wedding.highlightPhotos,
        []
      ),
      allPhotos: parseJSON(wedding.all_photos || wedding.allPhotos, []),
      events: parseJSON(wedding.events, []),
      vendors: parseJSON(wedding.vendors, []),
      specialMoments: wedding.special_moments || wedding.specialMoments || "",
      brideOutfit: wedding.bride_outfit || wedding.brideOutfit || "",
      groomOutfit: wedding.groom_outfit || wedding.groomOutfit || "",
      photographer: wedding.photographer || "",
      makeup: wedding.makeup || "",
      decor: wedding.decor || "",
      status: wedding.status,
    });

    const fetchWeddings = async () => {
      try {
        setLoading(true);
        const response = await axios.get(
          "https://happywedz.com/api/realwedding/public/"
        );

        const dataArray = response.data.weddings || response.data;

        if (Array.isArray(dataArray)) {
          const normalized = dataArray.map(normalizeWedding);
          setWeddings(normalized);
        } else {
          setWeddings([]);
        }
        setError(null);
      } catch (err) {
        setError("Failed to fetch wedding stories. Please try again later.");
        console.error("Error fetching weddings:", err);
      } finally {
        setLoading(false);
      }
    };
    fetchWeddings();
  }, []);

  const scrollToFilters = () => {
    if (filterRef.current) {
      filterRef.current.scrollIntoView({ behavior: "smooth", block: "start" });
    }
  };

  const filteredWeddings = useMemo(() => {
    return weddings.filter((wedding) => {
      const isPublished = wedding.status === "published";
      if (!isPublished) return false;

      const searchLower = (searchTerm || "").toLowerCase();
      const matchesSearch =
        searchLower === "" ||
        wedding.title?.toLowerCase().includes(searchLower) ||
        wedding.brideName?.toLowerCase().includes(searchLower) ||
        wedding.groomName?.toLowerCase().includes(searchLower) ||
        wedding.city?.toLowerCase().includes(searchLower);

      const cityMatch =
        selectCity === "All Cities" ||
        (wedding.city &&
          wedding.city.toLowerCase() === selectCity.toLowerCase());

      const cultureMatch =
        selectedCulture === "All Cultures" ||
        (wedding.culture &&
          wedding.culture.toLowerCase() === selectedCulture.toLowerCase());

      const themeMatch =
        selectedTheme === "All Themes" ||
        (Array.isArray(wedding.themes)
          ? wedding.themes.some(
              (t) => String(t || "").toLowerCase() === selectedTheme.toLowerCase()
            )
          : String(wedding.themes || "").toLowerCase() ===
            selectedTheme.toLowerCase());

      return matchesSearch && cityMatch && cultureMatch && themeMatch;
    });
  }, [weddings, searchTerm, selectCity, selectedCulture, selectedTheme]);

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm, selectCity, selectedCulture, selectedTheme]);

  // Clear filters will use the one from context

  const indexOfLast = currentPage * itemsPerPage;
  const indexOfFirst = indexOfLast - itemsPerPage;
  const currentWeddings = filteredWeddings.slice(indexOfFirst, indexOfLast);
  const totalPages = Math.ceil(filteredWeddings.length / itemsPerPage);

  const WeddingCard = ({ wedding }) => (
    <div
      className="col-lg-4 col-md-6"
      onClick={() => onPostClick && onPostClick(wedding)}
    >
      <div className="wedding-card h-100 shadow-sm rounded-3 overflow-hidden">
        <div className="position-relative">
          <img
            src={wedding.coverPhoto}
            alt={wedding.title}
            className="img-fluid"
            style={{ width: "100%", height: "400px", objectFit: "cover" }}
          />
          <div
            className="position-absolute bottom-0 end-0 text-white p-5 "
            style={{ background: "rgba(195, 17, 98, 0.7)" }}
          >
            {wedding.highlightPhotos?.length || 0} Photos
          </div>
        </div>
        <div className="p-2">
          <div className="d-flex align-items-center text-center justify-content-center">
            <span className="fw-bold mb-0 fs-22">{wedding.brideName}</span>
            <span className=" mb-0 mx-2 fs-18">And</span>
            <span className="fw-bold mb-0 fs-22">{wedding.groomName}</span>
          </div>
          <h5 className="mt-3 d-flex align-items-center primary-text justify-content-center">
            <FaMapMarkerAlt className="me-1" />
            {wedding.city}
          </h5>
        </div>
      </div>
    </div>
  );

  return (
    <div className="real-weddings">
      {/* Hero Section */}
      <section
        className="hero-section text-center text-white d-flex align-items-center"
        style={{
          backgroundImage: "url('/images/real_wedding_hero.png')",
          backgroundSize: "cover",
          backgroundPosition: "center",
          minHeight: "350px",
          position: "relative",
        }}
      >
        <div
          style={{
            position: "absolute",
            inset: 0,
            backgroundColor: "rgba(253, 7, 130, 0.2)",
          }}
        />
        <div className="container position-relative">
          <h1 className="fw-bold">Real Weddings, Real Love</h1>
          <p className="lead mb-4">
            Because every love story deserves to be shared.
          </p>
        </div>
      </section>

      <section
        ref={filterRef}
        className="d-flex justify-content-center align-items-center w-100"
        style={{
          padding: "40px 30px",
          backgroundColor: "#f8f8f8",
        }}
      >
        <div
          className="container d-flex justify-content-center align-items-stretch"
          style={{
            display: "flex",
            gap: "12px",
            width: "100%",
            padding: "0",
            flexWrap: "wrap",
          }}
        >
          <div className="d-flex flex-wrap gap-3 justify-content-center">
            {/* Custom City Dropdown */}
            <div
              style={{
                flex: "1 1 220px",
                minWidth: "220px",
                maxWidth: "300px",
                width: "100%",
                position: "relative",
              }}
              ref={cityDropdownRef}
              onClick={scrollToFilters}
            >
              <button
                onClick={(e) => {
                  setTimeout(scrollToFilters, 50);
                  e.stopPropagation();
                  setIsCityDropdownOpen(!isCityDropdownOpen);
                }}
                style={{
                  width: "100%",
                  backgroundColor: "#fff",
                  border: "1px solid #C31162",
                  color: "#C31162",
                  fontSize: "14px",
                  padding: "10px 16px",
                  height: "45px",
                  borderRadius: "4px",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  textAlign: "left",
                }}
              >
                <span
                  style={{
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                >
                  {selectCity}
                </span>
                {isCityDropdownOpen ? <FaChevronUp /> : <FaChevronDown />}
              </button>

              {isCityDropdownOpen && (
                <div
                  style={{
                    position: "absolute",
                    top: "calc(100% + 5px)",
                    left: 0,
                    right: 0,
                    backgroundColor: "#fff",
                    border: "1px solid #C31162",
                    borderRadius: "4px",
                    boxShadow: "0 4px 8px rgba(0,0,0,0.1)",
                    zIndex: 1000,
                    maxHeight: "300px",
                    display: "flex",
                    flexDirection: "column",
                  }}
                >
                  <div
                    style={{
                      padding: "8px",
                      borderBottom: "1px solid #f0f0f0",
                    }}
                  >
                    <div style={{ position: "relative" }}>
                      <FaSearch
                        style={{
                          position: "absolute",
                          left: "12px",
                          top: "50%",
                          transform: "translateY(-50%)",
                          color: "#999",
                          fontSize: "14px",
                        }}
                      />
                      <input
                        type="text"
                        value={citySearchTerm}
                        onChange={(e) => setCitySearchTerm(e.target.value)}
                        placeholder="Search cities..."
                        style={{
                          width: "100%",
                          padding: "8px 12px 8px 32px",
                          border: "1px solid #ddd",
                          borderRadius: "4px",
                          fontSize: "14px",
                          outline: "none",
                        }}
                        onClick={(e) => e.stopPropagation()}
                        autoFocus
                      />
                    </div>
                  </div>
                  <div
                    style={{
                      overflowY: "auto",
                      maxHeight: "250px",
                      overflowX: "hidden",
                    }}
                  >
                    <div
                      onClick={() => handleCitySelect("All Cities")}
                      style={{
                        padding: "10px 16px",
                        cursor: "pointer",
                        backgroundColor:
                          selectCity === "All Cities"
                            ? "#f8e3ee"
                            : "transparent",
                        color: selectCity === "All Cities" ? "#C31162" : "#333",
                        fontWeight:
                          selectCity === "All Cities" ? "500" : "normal",
                        "&:hover": {
                          backgroundColor: "#f9f9f9",
                        },
                      }}
                    >
                      All Cities
                    </div>
                    {filteredCities.length > 0 ? (
                      filteredCities.map((city) => (
                        <div
                          key={city}
                          onClick={() => handleCitySelect(city)}
                          style={{
                            padding: "10px 16px",
                            cursor: "pointer",
                            backgroundColor:
                              selectCity === city ? "#f8e3ee" : "transparent",
                            color: selectCity === city ? "#C31162" : "#333",
                            fontWeight: selectCity === city ? "500" : "normal",
                            "&:hover": {
                              backgroundColor: "#f9f9f9",
                            },
                          }}
                        >
                          {city}
                        </div>
                      ))
                    ) : (
                      <div
                        style={{
                          padding: "10px 16px",
                          color: "#666",
                          fontStyle: "italic",
                        }}
                      >
                        No cities found
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>

            {/* Culture Dropdown */}
            <div
              style={{
                flex: "1 1 220px",
                minWidth: "220px",
                maxWidth: "300px",
                width: "100%",
                position: "relative",
              }}
              ref={cultureDropdownRef}
            >
              <button
                onClick={() => {
                  setIsCultureDropdownOpen(!isCultureDropdownOpen);
                  scrollToFilters();
                }}
                style={{
                  width: "100%",
                  backgroundColor: "#fff",
                  border: "1px solid #C31162",
                  color: "#C31162",
                  fontSize: "14px",
                  padding: "10px 16px",
                  height: "45px",
                  borderRadius: "4px",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  textAlign: "left",
                }}
              >
                <span
                  style={{
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                >
                  {selectedCulture}
                </span>
                {isCultureDropdownOpen ? <FaChevronUp /> : <FaChevronDown />}
              </button>

              {isCultureDropdownOpen && (
                <div
                  style={{
                    position: "absolute",
                    top: "calc(100% + 5px)",
                    left: 0,
                    right: 0,
                    backgroundColor: "#fff",
                    border: "1px solid #C31162",
                    borderRadius: "4px",
                    boxShadow: "0 4px 8px rgba(0,0,0,0.1)",
                    zIndex: 1000,
                    maxHeight: "300px",
                    overflowY: "auto",
                  }}
                >
                  <div
                    onClick={() => handleCultureSelect("All Cultures")}
                    style={{
                      padding: "10px 16px",
                      cursor: "pointer",
                      backgroundColor:
                        selectedCulture === "All Cultures"
                          ? "#f8e3ee"
                          : "transparent",
                      color:
                        selectedCulture === "All Cultures" ? "#C31162" : "#333",
                      fontWeight:
                        selectedCulture === "All Cultures" ? "500" : "normal",
                      "&:hover": {
                        backgroundColor: "#f9f9f9",
                      },
                    }}
                  >
                    All Cultures
                  </div>
                  {cultures.map((culture) => (
                    <div
                      key={culture.id}
                      onClick={() => handleCultureSelect(culture.name)}
                      style={{
                        padding: "10px 16px",
                        cursor: "pointer",
                        backgroundColor:
                          selectedCulture === culture.name
                            ? "#f8e3ee"
                            : "transparent",
                        color:
                          selectedCulture === culture.name ? "#C31162" : "#333",
                        fontWeight:
                          selectedCulture === culture.name ? "500" : "normal",
                        "&:hover": {
                          backgroundColor: "#f9f9f9",
                        },
                      }}
                    >
                      {culture.name}
                    </div>
                  ))}
                </div>
              )}
            </div>

            {/* Theme Dropdown */}
            <div
              style={{
                flex: "1 1 220px",
                minWidth: "220px",
                maxWidth: "300px",
                width: "100%",
                position: "relative",
              }}
              ref={themeDropdownRef}
            >
              <button
                onClick={() => {
                  setIsThemeDropdownOpen(!isThemeDropdownOpen);
                  scrollToFilters();
                }}
                style={{
                  width: "100%",
                  backgroundColor: "#fff",
                  border: "1px solid #C31162",
                  color: "#C31162",
                  fontSize: "14px",
                  padding: "10px 16px",
                  height: "45px",
                  borderRadius: "4px",
                  cursor: "pointer",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "space-between",
                  textAlign: "left",
                }}
              >
                <span
                  style={{
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                    whiteSpace: "nowrap",
                  }}
                >
                  {selectedTheme}
                </span>
                {isThemeDropdownOpen ? <FaChevronUp /> : <FaChevronDown />}
              </button>

              {isThemeDropdownOpen && (
                <div
                  style={{
                    position: "absolute",
                    top: "calc(100% + 5px)",
                    left: 0,
                    right: 0,
                    backgroundColor: "#fff",
                    border: "1px solid #C31162",
                    borderRadius: "4px",
                    boxShadow: "0 4px 8px rgba(0,0,0,0.1)",
                    zIndex: 1000,
                    maxHeight: "300px",
                    overflowY: "auto",
                  }}
                >
                  <div
                    onClick={() => handleThemeSelect("All Themes")}
                    style={{
                      padding: "10px 16px",
                      cursor: "pointer",
                      backgroundColor:
                        selectedTheme === "All Themes"
                          ? "#f8e3ee"
                          : "transparent",
                      color:
                        selectedTheme === "All Themes" ? "#C31162" : "#333",
                      fontWeight:
                        selectedTheme === "All Themes" ? "500" : "normal",
                      "&:hover": {
                        backgroundColor: "#f9f9f9",
                      },
                    }}
                  >
                    All Themes
                  </div>
                  {themes.map((theme) => (
                    <div
                      key={theme}
                      onClick={() => handleThemeSelect(theme)}
                      style={{
                        padding: "10px 16px",
                        cursor: "pointer",
                        backgroundColor:
                          selectedTheme === theme ? "#f8e3ee" : "transparent",
                        color: selectedTheme === theme ? "#C31162" : "#333",
                        fontWeight: selectedTheme === theme ? "500" : "normal",
                        "&:hover": {
                          backgroundColor: "#f9f9f9",
                        },
                      }}
                    >
                      {theme}
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Search Input with Button */}

          <div
            style={{
              flex: "1 1 300px",
              minWidth: "260px",
              maxWidth: "640px",
              width: "100%",
              display: "flex",
              gap: "0",
              position: "relative",
              zIndex: 1,
            }}
          >
            <input
              type="text"
              className="form-control"
              placeholder="Search by name and location..."
              style={{
                backgroundColor: "#fff",
                border: "1px solid #C31162",
                color: "#333",
                fontSize: "14px",
                padding: "10px 15px",
                height: "45px",
                borderRadius: "4px 0 0 4px",
                flex: 1,
                outline: "none",
                boxSizing: "border-box",
              }}
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setCurrentPage(1);
              }}
              onClick={scrollToFilters}
            />
            <button
              type="button"
              style={{
                backgroundColor: "#C31162",
                border: "1px solid #C31162",
                borderLeft: "none",
                color: "#fff",
                fontSize: "14px",
                padding: "10px 25px",
                height: "45px",
                borderRadius: "0 4px 4px 0",
                cursor: "pointer",
                whiteSpace: "nowrap",
                fontWeight: "500",
                flexShrink: 0,
                boxSizing: "border-box",
              }}
              onClick={scrollToFilters}
            >
              Find Vendor
            </button>
          </div>
        </div>
      </section>

      {/* Gallery Section */}
      <section className="gallery-section py-5">
        <div className="container">
          <div className="d-flex justify-content-between align-items-center m-2">
            <p className="mb-4">
              Showing {filteredWeddings.length} results in All Cities
            </p>
            <div className="d-flex gap-2">
              {(searchTerm !== "" ||
                selectCity !== "All Cities" ||
                selectedCulture !== "All Cultures" ||
                selectedTheme !== "All Themes") && (
                <button
                  className="btn btn-outline-secondary px-4"
                  onClick={clearFilters}
                >
                  Clear filters
                </button>
              )}
            </div>
          </div>
          <div className="row justify-content-center">
            {loading ? (
              <div className="col-12 text-center py-5">
                <div
                  className="spinner-border text-pink mb-3"
                  role="status"
                ></div>
                <p className="text-secondary fs-5">
                  Fetching beautiful weddings...
                </p>
              </div>
            ) : error ? (
              <div className="col-12 d-flex flex-column align-items-center py-5">
                <div
                  className="rounded-circle bg-light shadow-sm d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <BsExclamationTriangle size={40} />
                </div>
                <h5 className="text-danger fw-semibold mb-2">
                  Oops! Something went wrong
                </h5>
                <p className="text-muted">
                  {error || "Unable to load weddings right now."}
                </p>
              </div>
            ) : currentWeddings.length === 0 ? (
              <div className="col-12 d-flex flex-column align-items-center py-5">
                <div
                  className="rounded-circle bg-light shadow-sm d-flex align-items-center justify-content-center mb-3"
                  style={{ width: "80px", height: "80px" }}
                >
                  <i className="bi bi-heart text-pink fs-1"></i>
                </div>
                <h5 className="text-secondary fw-semibold mb-2">
                  No Weddings Found
                </h5>
                <p className="text-muted mb-3">
                  No items match the selected filters.
                </p>
              </div>
            ) : (
              currentWeddings.map((w) => <WeddingCard key={w.id} wedding={w} />)
            )}
          </div>

          {totalPages > 1 && (
            <nav className="d-flex justify-content-center mt-4">
              <ul className="pagination flex-wrap" style={{ gap: "8px" }}>
                <li
                  className={`page-item ${currentPage === 1 ? "disabled" : ""}`}
                >
                  <button
                    className="page-link"
                    style={{
                      color: "black",
                      borderRadius: "6px",
                      minWidth: "40px",
                      minHeight: "40px",
                    }}
                    onClick={() => setCurrentPage(currentPage - 1)}
                    disabled={currentPage === 1}
                  >
                    «
                  </button>
                </li>

                {Array.from({ length: totalPages }, (_, i) => i + 1)
                  .filter(
                    (page) =>
                      page <= 2 ||
                      page > totalPages - 2 ||
                      (page >= currentPage - 1 && page <= currentPage + 1)
                  )
                  .map((page, idx, arr) => {
                    const prevPage = arr[idx - 1];
                    const showEllipsis = prevPage && page - prevPage > 1;
                    return (
                      <React.Fragment key={page}>
                        {showEllipsis && (
                          <li className="page-item disabled">
                            <span
                              className="page-link"
                              style={{ color: "black", border: "none" }}
                            >
                              …
                            </span>
                          </li>
                        )}
                        <li
                          className={`page-item ${
                            currentPage === page ? "active" : ""
                          }`}
                        >
                          <button
                            className="page-link"
                            style={{
                              color: "black",
                              borderRadius: "6px",
                              minWidth: "40px",
                              minHeight: "40px",
                            }}
                            onClick={() => setCurrentPage(page)}
                          >
                            {page}
                          </button>
                        </li>
                      </React.Fragment>
                    );
                  })}

                {/* Next Button */}
                <li
                  className={`page-item ${
                    currentPage === totalPages ? "disabled" : ""
                  }`}
                >
                  <button
                    className="page-link"
                    style={{
                      color: "black",
                      borderRadius: "6px",
                      minWidth: "40px",
                      minHeight: "40px",
                    }}
                    onClick={() => setCurrentPage(currentPage + 1)}
                    disabled={currentPage === totalPages}
                  >
                    »
                  </button>
                </li>
              </ul>
            </nav>
          )}
        </div>
      </section>
    </div>
  );
};

export default RealWeddings;
