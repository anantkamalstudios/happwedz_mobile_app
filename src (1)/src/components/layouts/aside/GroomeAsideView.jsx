import React, { useState } from "react";
import { Row, Col, Form, Dropdown } from "react-bootstrap";
import { FaChevronDown } from "react-icons/fa";
import { MdClear } from "react-icons/md";
import { CiFilter } from "react-icons/ci";
import ViewSwitcher from "../Main/ViewSwitcher";
const FILTER_OPTIONS = {
  BridalMehndi: [
    "Under ₹25,000",
    "₹25,000 - ₹49,999",
    "₹50,000 - ₹74,999",
    "₹75,000 - ₹99,999",
    "₹1,00,000 - ₹1,24,999",
    "₹2,00,000 and more",
  ],
};

const Asideview = ({ view, setView }) => {
  const [selectedFilters, setSelectedFilters] = useState({});
  const [toggleSwitches, setToggleSwitches] = useState({
    deals: false,
    awardWinners: false,
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

  const clearFilters = () => {
    setSelectedFilters({});
    setToggleSwitches({ deals: false, awardWinners: false });
  };

  const isAnyFilterSelected =
    Object.values(selectedFilters).some(Boolean) ||
    Object.values(toggleSwitches).some(Boolean);

  const getSelectedCount = (group) => {
    return Object.keys(selectedFilters).filter(
      (key) => key.startsWith(group) && selectedFilters[key]
    ).length;
  };

  const renderDropdownCheckboxList = (group, options, title) => {
    const selectedCount = getSelectedCount(group);
    const safeOptions = Array.isArray(options) ? options : [];

    return (
      <Dropdown className="main-filter-dropdown filter-dropdown">
        <Dropdown.Toggle
          bsPrefix="custom-toggle"
          variant="outline-secondary"
          id={`dropdown-${group}`}
          className="d-flex align-items-center justify-content-between main-filter-dropdown-toggle filter-dropdown-toggle rounded-0"
          style={{ minWidth: "180px" }}
        >
          <span className="d-flex align-items-center gap-2 me-2 fs-14">
            <CiFilter size={16} />
            {title}
            {selectedCount > 0 && (
              <span className="badge primary-bg rounded-circle">
                {selectedCount}
              </span>
            )}
          </span>
          <FaChevronDown size={12} />
        </Dropdown.Toggle>

        <Dropdown.Menu
          className="main-filter-dropdown-menu filter-dropdown-menu"
          style={{
            maxHeight: "300px",
            overflowY: "auto",
            minWidth: "250px",
            padding: "5px 2rem",
          }}
        >
          {safeOptions.map((option) => {
            const key = `${group}-${option}`;
            return (
              <Dropdown.Item
                key={key}
                as="div"
                className="p-0"
                onClick={(e) => e.stopPropagation()}
              >
                <Form.Check
                  type="checkbox"
                  id={key}
                  label={option}
                  className="mb-0 px-3 py-2 main-filter-checkbox "
                  checked={!!selectedFilters[key]}
                  onChange={() => handleCheckbox(group, option)}
                />
              </Dropdown.Item>
            );
          })}
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  return (
    <div className="horizontal-filters-container bg-white border-bottom py-3 mb-4">
      <div className="container-fluid">
        <Row className="align-items-center">
          {/* Filter dropdowns */}
          <Col xs={12} md={8} className="mb-3 mb-md-0">
            <div className="d-flex flex-wrap gap-3 align-items-center justify-content-md-start justify-content-center">
              {renderDropdownCheckboxList(
                "BridalMehndi",
                FILTER_OPTIONS.BridalMehndi,
                "Bridal Mehndi"
              )}
              {/* {renderDropdownCheckboxList(
                "Services",
                FILTER_OPTIONS.Services,
                "Services"
              )}
              {renderDropdownCheckboxList(
                "Pre_Wedding_Package",
                FILTER_OPTIONS.Pre_Wedding_Package,
                "Pre Wedding Package"
              )}
              {renderDropdownCheckboxList(
                "One_Day_Wedding_Package",
                FILTER_OPTIONS.One_Day_Wedding_Package,
                "1 Day Wedding Package"
              )}
              {renderDropdownCheckboxList(
                "Three_Day_Wedding_Package",
                FILTER_OPTIONS.Three_Day_Wedding_Package,
                "3 Day Wedding Package"
              )} */}
            </div>
          </Col>

          {/* Clear & View Switcher */}
          <Col xs={12} md={4} className="mt-3 mt-md-0">
            <div className="d-flex flex-column flex-md-row justify-content-md-end justify-content-center align-items-center gap-2 w-100">
              {isAnyFilterSelected && (
                <button
                  className="btn btn-outline-danger btn-sm d-flex flex-row align-items-center text-center gap-1 mb-2 mb-md-0"
                  onClick={clearFilters}
                >
                  <MdClear size={20} />
                  Clear All
                </button>
              )}
              <div className="d-flex justify-content-md-end justify-content-center w-75">
                <ViewSwitcher view={view} setView={setView} />
              </div>
            </div>
          </Col>
        </Row>

        {/* Active filters */}
        {isAnyFilterSelected && (
          <Row className="mt-3">
            <Col xs={12}>
              <div className="d-flex flex-wrap gap-2 align-items-center">
                <small className="text-muted me-2">Active filters:</small>
                {Object.entries(selectedFilters)
                  .filter(([key, selected]) => selected)
                  .map(([key]) => {
                    const [group, value] = key.split("-");
                    return (
                      <span
                        key={key}
                        className="badge bg-light text-dark border d-flex align-items-center gap-1"
                      >
                        {value}
                        <button
                          type="button"
                          className="btn-close btn-close-sm"
                          style={{ fontSize: "0.6rem" }}
                          onClick={() => handleCheckbox(group, value)}
                        ></button>
                      </span>
                    );
                  })}
              </div>
            </Col>
          </Row>
        )}
      </div>
    </div>
  );
};

export default Asideview;
