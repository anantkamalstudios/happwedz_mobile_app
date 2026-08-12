import React, { useState } from "react";
import { Col, Form } from "react-bootstrap";
import { MdClear } from "react-icons/md";
import {
  FaTags,
  FaTrophy,
  FaChevronDown,
  FaChevronRight,
} from "react-icons/fa";

// import FILTER_OPTIONS from "../../../data/asideview";

const FILTER_OPTIONS = {
  One_Day_Wedding_Package: [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹2,00,000 and more",
  ],
  Three_Day_Wedding_Package: [
    "Under ₹70,000",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,49,999",
    "₹1,50,000 - ₹1,99,999",
    "₹2,00,000 - ₹2,49,999",
    "₹2,50,000 - ₹2,99,999",
    "₹3,00,000 - ₹3,99,999",
    "₹4,00,000 and more",
  ],
  Pre_Wedding_Package: [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹1,25,000 - ₹1,49,999",
    "₹2,00,000 and more",
  ],
  Services: [
    "Traditional",
    "Candid",
    "Cinematographic",
    "Drone Shoots",
    "Photobooth",
    "Live Screening",
  ],
  Occasion: [
    "Wedding & engagement",
    "Engagement photography",
    "Mehndi & sangeet",
    "Couple pre-wedding",
    "Parties",
    "Corporate events",
    "Maternity shoot",
    "Baby shoot",
  ],
};

const Asideview = () => {
  const [selectedFilters, setSelectedFilters] = useState({});
  const [toggleSwitches, setToggleSwitches] = useState({
    deals: false,
    awardWinners: false,
  });
  const [sectionState, setSectionState] = useState({
    One_Day_Wedding_Package: true,
    Three_Day_Wedding_Package: true,
    Pre_Wedding_Package: true,
    Services: true,
    Occasion: true,
  });

  const handleCheckbox = (group, value) => {
    const key = `${group}-${value}`;
    setSelectedFilters((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const handleSwitch = (key) => {
    setToggleSwitches((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const toggleSection = (key) => {
    setSectionState((prev) => ({
      ...prev,
      [key]: !prev[key],
    }));
  };

  const clearFilters = () => {
    setSelectedFilters({});
    setToggleSwitches({ deals: false, awardWinners: false });
  };

  const isAnyFilterSelected =
    Object.values(selectedFilters).some(Boolean) ||
    Object.values(toggleSwitches).some(Boolean);

  const renderIcon = (isOpen) =>
    isOpen ? <FaChevronDown size={12} /> : <FaChevronRight size={12} />;

  const renderCheckboxList = (group, options) => (
    <div className="venue-type-checkboxes">
      {options.map((option) => {
        const key = `${group}-${option}`;
        return (
          <Form.Check
            key={key}
            type="checkbox"
            id={key}
            label={option}
            className="mb-2 filter-checkbox"
            checked={!!selectedFilters[key]}
            onChange={() => handleCheckbox(group, option)}
          />
        );
      })}
    </div>
  );

  return (
    <Col xs={12} lg="auto" className="venue-filter-container">
      <div className="filter-sidebar show shadow-lg rounded">
        {isAnyFilterSelected && (
          <div className="clear-filters-wrapper d-flex justify-content-between align-items-center mb-4 p-2 bg-light rounded">
            <span className="text-muted small">Filters applied</span>
            <button
              className="btn btn-sm clear-btn-filter d-flex align-items-center gap-1"
              onClick={clearFilters}
            >
              <MdClear />
              Clear All
            </button>
          </div>
        )}
        <div className="filter-section">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h6
              className="section-header m-0"
              onClick={() => toggleSection("One_Day_Wedding_Package")}
            >
              {renderIcon(sectionState.One_Day_Wedding_Package)} 1 Day Wedding
              Package
            </h6>
          </div>
          {sectionState.One_Day_Wedding_Package &&
            renderCheckboxList("venue", FILTER_OPTIONS.One_Day_Wedding_Package)}
        </div>

        <div className="filter-section">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h6
              className="section-header m-0"
              onClick={() => toggleSection("Three_Day_Wedding_Package")}
            >
              {renderIcon(sectionState.Three_Day_Wedding_Package)} 3 Day Wedding
              Package
            </h6>
          </div>
          {sectionState.Three_Day_Wedding_Package &&
            renderCheckboxList(
              "venue",
              FILTER_OPTIONS.Three_Day_Wedding_Package
            )}
        </div>

        <div className="filter-section">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h6
              className="section-header m-0"
              onClick={() => toggleSection("Services")}
            >
              {renderIcon(sectionState.Services)} Services
            </h6>
          </div>
          {sectionState.Services &&
            renderCheckboxList("venue", FILTER_OPTIONS.Services)}
        </div>

        <div className="filter-section">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h6
              className="section-header m-0"
              onClick={() => toggleSection("Pre_Wedding_Package")}
            >
              {renderIcon(sectionState.Pre_Wedding_Package)} Pre Wedding Package
            </h6>
          </div>
          {sectionState.Pre_Wedding_Package &&
            renderCheckboxList("venue", FILTER_OPTIONS.Pre_Wedding_Package)}
        </div>

        <div className="filter-section">
          <div className="d-flex justify-content-between align-items-center mb-2">
            <h6
              className="section-header m-0"
              onClick={() => toggleSection("Occasion")}
            >
              {renderIcon(sectionState.Occasion)} Occasion
            </h6>
          </div>
          {sectionState.Occasion &&
            renderCheckboxList("venue", FILTER_OPTIONS.Occasion)}
        </div>
      </div>
    </Col>
  );
};

export default Asideview;
