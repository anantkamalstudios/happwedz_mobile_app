import React, { useState, useEffect } from "react";
import { Modal, Button, Form } from "react-bootstrap";
import axios from "axios";
import { useDispatch, useSelector } from "react-redux";
import { setLocation, clearLocation } from "../../redux/locationSlice";
import { useNavigate, useLocation, useParams } from "react-router-dom";
import { IoMdArrowDropdown } from "react-icons/io";
import citiesData from "../../data/citiesData";

const LocationModalWithCategories = () => {
  const [show, setShow] = useState(false);
  const dispatch = useDispatch();
  const selectedLocation = useSelector(
    (state) => state.location.selectedLocation
  );
  const navigate = useNavigate();
  const location = useLocation();
  const { section, slug, subcategory } = useParams();
  const [searchTerm, setSearchTerm] = useState("");
  const [selectedState, setSelectedState] = useState(null);

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
      "Goa"
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
    otherCities: [
      "Nagpur",
      "Dehradun",
      "Thane",
      "Surat",
      "Vadodara",
      "Raipur",
      "Mysore",
      "Hubli",
    ],
    states: Object.keys(citiesData).sort(),
    internationalCities: ["Dubai", "Thailand", "Bali", "Abu Dhabi"],
  };

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
    staticCityData.otherCities.forEach(c => list.add(c));
    return Array.from(list).sort();
  }, []);

  const filterCities = searchTerm.trim()
    ? allLocalCities.filter((city) =>
        city.toLowerCase().includes(searchTerm.toLowerCase())
      )
    : [];

  const handleCityClick = (city) => {
    const cleanCity = city.toLowerCase();
    const cleanCitySlug = cleanCity
      .replace(/[^a-z0-9\s-]/g, "")
      .replace(/\s+/g, "-")
      .replace(/-+/g, "-")
      .replace(/^-+|-+$/g, "");

    if (city === "All Cities") {
      dispatch(clearLocation());
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

  const handleModalClose = () => {
    setShow(false);
    setSearchTerm("");
    setSelectedState(null);
  };

  return (
    <>
      <div style={{ position: "relative", display: "inline-block" }}>
        <Button
          variant="outline-light"
          className="border-danger rounded-0 text-dark d-flex align-items-center justify-content-between px-3"
          onClick={() => setShow(true)}
          style={{
            minWidth: 180,
            height: 40,
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
          <IoMdArrowDropdown size={25} color="#000" />
        </Button>
      </div>

      <Modal
        show={show}
        onHide={handleModalClose}
        size="xl"
        className="location-model-modal-dialog-centered"
        backdrop={true}
        keyboard={true}
        style={{ top: "2rem" }}
      >
        <Modal.Body style={{ padding: 0 }}>
          <div style={{ padding: "1rem 1rem 0rem 1rem" }}>
            <Form.Control
              type="text"
              placeholder="Search City..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="p-2 fs-14"
            />
          </div>

          <div
            style={{
              maxHeight: "400px",
              overflowY: "auto",
              overflowX: "hidden",
            }}
          >
            {searchTerm.trim() ? (
              filterCities.length === 0 ? (
                <div className="text-center text-muted py-3">
                  No cities found.
                </div>
              ) : (
                <div className="d-flex flex-wrap justify-content-center p-3">
                  {filterCities.map((city) => (
                    <div
                      key={city}
                      className="p-2 text-start"
                      style={{ minWidth: "150px" }}
                    >
                      <a
                        href="#"
                        className="text-dark d-block text-decoration-none fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          handleCityClick(city);
                        }}
                      >
                        {city}
                      </a>
                    </div>
                  ))}
                </div>
              )
            ) : selectedState ? (
              <div className="p-4">
                <div className="d-flex align-items-center gap-3 mb-4">
                  <Button
                    variant="outline-dark"
                    size="sm"
                    onClick={() => setSelectedState(null)}
                    style={{ borderRadius: "20px" }}
                  >
                    ← Back to States
                  </Button>
                  <h5 className="mb-0 fw-bold primary-text">{selectedState} Venues</h5>
                </div>
                <div className="row g-3">
                  {(citiesData[selectedState] || []).map((venueText) => {
                    const city = venueText.replace(/^Wedding Venues\s*/i, "").trim();
                    return (
                      <div key={city} className="col-6 col-md-3">
                        <a
                          href="#"
                          className="text-dark text-decoration-none d-block fs-14 p-2 border rounded hover-bg-light"
                          onClick={(e) => {
                            e.preventDefault();
                            handleCityClick(city);
                          }}
                        >
                          {city}
                        </a>
                      </div>
                    );
                  })}
                </div>
              </div>
            ) : (
              <div className="location-columns-wrapper">
                {/* Top Cities */}
                <div className="location-column">
                  <h6 className="primary-text fw-bold mb-3 mt-2">Top Cities</h6>
                  {staticCityData.topCities.map((city) => (
                    <div key={city} className="mb-2">
                      <a
                        href="#"
                        className="text-dark text-decoration-none d-block fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          handleCityClick(city);
                        }}
                      >
                        {city}
                      </a>
                    </div>
                  ))}
                </div>

                {/* Popular Cities */}
                <div className="location-column bg-light">
                  <h6 className="primary-text fw-bold mb-3 mt-2">
                    Popular Cities
                  </h6>
                  {staticCityData.popularCities.map((city) => (
                    <div key={city} className="mb-2">
                      <a
                        href="#"
                        className="text-dark text-decoration-none d-block fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          handleCityClick(city);
                        }}
                      >
                        {city}
                      </a>
                    </div>
                  ))}
                </div>

                {/* Other Cities */}
                <div className="location-column">
                  <h6 className="primary-text fw-bold mb-3 mt-2">
                    Other Cities
                  </h6>
                  {staticCityData.otherCities.map((city) => (
                    <div key={city} className="mb-2">
                      <a
                        href="#"
                        className="text-dark text-decoration-none d-block fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          handleCityClick(city);
                        }}
                      >
                        {city}
                      </a>
                    </div>
                  ))}
                </div>

                {/* States & International */}
                <div className="location-column bg-light">
                  <h6 className="primary-text fw-bold mb-3 mt-2">States</h6>
                  {staticCityData.states.map((state) => (
                    <div key={state} className="mb-2">
                      <a
                        href="#"
                        className="text-dark text-decoration-none d-block fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          setSelectedState(state);
                        }}
                      >
                        {state}
                      </a>
                    </div>
                  ))}

                  <h6 className="primary-text fw-bold mb-3 mt-3">
                    International Cities
                  </h6>
                  {staticCityData.internationalCities.map((city) => (
                    <div key={city} className="mb-2">
                      <a
                        href="#"
                        className="text-dark text-decoration-none d-block fs-14"
                        onClick={(e) => {
                          e.preventDefault();
                          handleCityClick(city);
                        }}
                      >
                        {city}
                      </a>
                    </div>
                  ))}
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
