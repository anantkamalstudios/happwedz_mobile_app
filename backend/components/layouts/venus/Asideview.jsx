import React, { useState } from "react";
import { Col, Form } from "react-bootstrap";
import { MdClear } from "react-icons/md";
import {
  FaTags,
  FaTrophy,
  FaChevronDown,
  FaChevronRight,
} from "react-icons/fa";

import FILTER_OPTIONS from "../../../data/asideview";
const Asideview = () => {
  const [selectedFilters, setSelectedFilters] = useState({});
  const [toggleSwitches, setToggleSwitches] = useState({
    deals: false,
    awardWinners: false,
  });
  const [sectionState, setSectionState] = useState({
    venueTypes: true,
    specialFilters: true,
    perPlate: true,
    capacity: true,
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
              onClick={() => toggleSection("venueTypes")}
            >
              {renderIcon(sectionState.venueTypes)} Wedding Venues
            </h6>
          </div>
          {sectionState.venueTypes &&
            renderCheckboxList("venue", FILTER_OPTIONS.venueTypes)}
        </div>

        <div className="filter-section">
          <h6
            className="section-header"
            onClick={() => toggleSection("specialFilters")}
          >
            {renderIcon(sectionState.specialFilters)} Special Filters
          </h6>
          {sectionState.specialFilters && (
            <div className="mt-3">
              <div className="d-flex justify-content-between align-items-center mb-3 filter-toggle">
                <div className="d-flex align-items-center gap-2">
                  <FaTags color="#e83e8ce6" />
                  <span>Deals</span>
                </div>
                <Form.Check
                  type="switch"
                  id="switch-deals"
                  checked={toggleSwitches.deals}
                  onChange={() => handleSwitch("deals")}
                />
              </div>
              <div className="d-flex justify-content-between align-items-center filter-toggle">
                <div className="d-flex align-items-center gap-2">
                  <FaTrophy color="#e83e8ce6" />
                  <span>Award Winners</span>
                </div>
                <Form.Check
                  type="switch"
                  id="switch-awardWinners"
                  checked={toggleSwitches.awardWinners}
                  onChange={() => handleSwitch("awardWinners")}
                />
              </div>
            </div>
          )}
        </div>

        <div className="filter-section">
          <h6
            className="section-header"
            onClick={() => toggleSection("perPlate")}
          >
            {renderIcon(sectionState.perPlate)} Per Plate (Veg)
          </h6>
          {sectionState.perPlate &&
            renderCheckboxList("plate", FILTER_OPTIONS.perPlate)}
        </div>

        <div className="filter-section">
          <h6
            className="section-header"
            onClick={() => toggleSection("capacity")}
          >
            {renderIcon(sectionState.capacity)} Capacity
          </h6>
          {sectionState.capacity &&
            renderCheckboxList("capacity", FILTER_OPTIONS.capacity)}
        </div>
      </div>
    </Col>
  );
};

export default Asideview;
