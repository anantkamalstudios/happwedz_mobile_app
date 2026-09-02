// import React, { useState } from "react";
// import { Col, Form } from "react-bootstrap";
// import {
//   FaTags,
//   FaTrophy,
//   FaChevronDown,
//   FaChevronRight,
// } from "react-icons/fa";

// import FILTER_OPTIONS from "../../../data/asideview";
// import { CiFilter } from "react-icons/ci";
// const VendorAsideview = () => {
//   const [showMobileFilters, setShowMobileFilters] = useState(false);
//   const [selectedFilters, setSelectedFilters] = useState({});
//   const [toggleSwitches, setToggleSwitches] = useState({
//     deals: false,
//     awardWinners: false,
//   });
//   const [sectionState, setSectionState] = useState({
//     venueTypes: true,
//     specialFilters: true,
//     perPlate: true,
//     capacity: true,
//   });

//   const handleCheckbox = (group, value) => {
//     const key = `${group}-${value}`;
//     setSelectedFilters((prev) => ({
//       ...prev,
//       [key]: !prev[key],
//     }));
//   };

//   const handleSwitch = (key) => {
//     setToggleSwitches((prev) => ({
//       ...prev,
//       [key]: !prev[key],
//     }));
//   };

//   const toggleSection = (key) => {
//     setSectionState((prev) => ({
//       ...prev,
//       [key]: !prev[key],
//     }));
//   };

//   const clearFilters = () => {
//     setSelectedFilters({});
//     setToggleSwitches({ deals: false, awardWinners: false });
//   };

//   const isAnyFilterSelected =
//     Object.values(selectedFilters).some(Boolean) ||
//     Object.values(toggleSwitches).some(Boolean);

//   const renderIcon = (isOpen) =>
//     isOpen ? <FaChevronDown size={12} /> : <FaChevronRight size={12} />;

//   const renderCheckboxList = (group, options) => (
//     <div className="venue-type-checkboxes">
//       {options.map((option) => {
//         const key = `${group}-${option}`;
//         return (
//           <Form.Check
//             key={key}
//             type="checkbox"
//             id={key}
//             label={option}
//             className="mb-2 filter-checkbox"
//             checked={!!selectedFilters[key]}
//             onChange={() => handleCheckbox(group, option)}
//           />
//         );
//       })}
//     </div>
//   );

//   return (
//     <>
//       <div className="d-lg-none mb-3 text-end">
//         <button
//           className="btn btn-sm bg-white border rounded-3 border-dark text-dark gap-2"
//           onClick={() => setShowMobileFilters(!showMobileFilters)}
//         >
//           <CiFilter size={18} />
//           {showMobileFilters ? "Hide Filters" : "Show Filters"}
//         </button>
//       </div>

//       <Col
//         xs={12}
//         lg="auto"
//         className={`venue-filter-container ${
//           showMobileFilters ? "d-block" : "d-none"
//         } d-lg-block aside-rubik`}
//       >
//         <div className="filter-sidebar show shadow-lg rounded">
//           {/* Venue Types */}
//           <div className="filter-section">
//             <div className="d-flex justify-content-between align-items-center mb-2">
//               <h6
//                 className="section-header m-0"
//                 onClick={() => toggleSection("venueTypes")}
//               >
//                 {renderIcon(sectionState.venueTypes)} Wedding Venues
//               </h6>
//               {isAnyFilterSelected && (
//                 <button
//                   className="btn btn-sm btn-outline-secondary"
//                   onClick={clearFilters}
//                 >
//                   Clear Filters
//                 </button>
//               )}
//             </div>
//             {sectionState.venueTypes &&
//               renderCheckboxList("venue", FILTER_OPTIONS.venueTypes)}
//           </div>

//           {/* Special Filters */}
//           <div className="filter-section">
//             <h6
//               className="section-header"
//               onClick={() => toggleSection("specialFilters")}
//             >
//               {renderIcon(sectionState.specialFilters)} Special Filters
//             </h6>
//             {sectionState.specialFilters && (
//               <div className="mt-3">
//                 {/* Deals */}
//                 <div className="d-flex justify-content-between align-items-center mb-3 filter-toggle">
//                   <div className="d-flex align-items-center gap-2">
//                     <FaTags />
//                     <span>Deals</span>
//                   </div>
//                   <Form.Check
//                     type="switch"
//                     id="switch-deals"
//                     checked={toggleSwitches.deals}
//                     onChange={() => handleSwitch("deals")}
//                   />
//                 </div>

//                 {/* Award Winners */}
//                 <div className="d-flex justify-content-between align-items-center filter-toggle">
//                   <div className="d-flex align-items-center gap-2">
//                     <FaTrophy />
//                     <span>Award Winners</span>
//                   </div>
//                   <Form.Check
//                     type="switch"
//                     id="switch-awardWinners"
//                     checked={toggleSwitches.awardWinners}
//                     onChange={() => handleSwitch("awardWinners")}
//                   />
//                 </div>
//               </div>
//             )}
//           </div>

//           {/* Per Plate */}
//           <div className="filter-section">
//             <h6
//               className="section-header"
//               onClick={() => toggleSection("perPlate")}
//             >
//               {renderIcon(sectionState.perPlate)} Per Plate (Veg)
//             </h6>
//             {sectionState.perPlate &&
//               renderCheckboxList("plate", FILTER_OPTIONS.perPlate)}
//           </div>

//           {/* Capacity */}
//           <div className="filter-section">
//             <h6
//               className="section-header"
//               onClick={() => toggleSection("capacity")}
//             >
//               {renderIcon(sectionState.capacity)} Capacity
//             </h6>
//             {sectionState.capacity &&
//               renderCheckboxList("capacity", FILTER_OPTIONS.capacity)}
//           </div>
//         </div>
//       </Col>
//     </>
//   );
// };

// export default VendorAsideview;

import React, { useState } from "react";
import { Row, Col, Form, Dropdown } from "react-bootstrap";
import { MdClear } from "react-icons/md";
import { CiFilter } from "react-icons/ci";
import { FaChevronDown } from "react-icons/fa";
import ViewSwitcher from "../Main/ViewSwitcher";
import FILTER_OPTIONS from "../../../data/asideview";

const VendorAsideview = ({ view, setView }) => {
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

    return (
      <Dropdown className="main-filter-dropdown filter-dropdown">
        <Dropdown.Toggle
          bsPrefix="custom-toggle"
          variant="outline-secondary"
          id={`dropdown-${group}`}
          className="d-flex align-items-center justify-content-between main-filter-dropdown-toggle filter-dropdown-toggle rounded-0"
          style={{ minWidth: "180px" }}
        >
          <span className="d-flex align-items-center gap-2 me-2  fs-14">
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
          {options.map((option) => {
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
                  className="mb-0 px-3 py-2 main-filter-checkbox"
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
                "Types",
                FILTER_OPTIONS.vendorTypes,
                "Types"
              )}
              {renderDropdownCheckboxList(
                "vendorPricing",
                FILTER_OPTIONS.vendorPricing,
                "Vendor Pricing"
              )}
              {renderDropdownCheckboxList(
                "location",
                FILTER_OPTIONS.location,
                "Location"
              )}
              {renderDropdownCheckboxList(
                "experience",
                FILTER_OPTIONS.experience,
                "Experience"
              )}
              {renderDropdownCheckboxList(
                "Services",
                FILTER_OPTIONS.services,
                "Services"
              )}
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

export default VendorAsideview;
