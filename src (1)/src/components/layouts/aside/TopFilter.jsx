import React from "react";
import { Dropdown, Form } from "react-bootstrap";
import { CiFilter } from "react-icons/ci";
import { FaChevronDown } from "react-icons/fa";
import { MdClear, MdCheck } from "react-icons/md";
import ViewSwitcher from "../Main/ViewSwitcher";

const TopFilter = ({
  view,
  setView,
  filters,
  activeFilters,
  appliedFilters = {},
  onToggleFilter,
  onClearFilters,
  onApplyFilters,
  isFilterActive,
  getActiveCount,
  hasPendingChanges = false,
}) => {
  const handleCheckbox = (group, value) => {
    onToggleFilter(group, value);
  };

  const clearFilters = () => onClearFilters();

  // Capitalize helper
  const capitalize = (str) =>
    str.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());

  const renderDropdown = (group, options) => {
    const selectedCount = getActiveCount(group);

    return (
      <Dropdown
        key={group}
        className="main-filter-dropdown filter-dropdown"
        drop="down"
        autoClose="outside"
      >
        <Dropdown.Toggle
          bsPrefix="custom-toggle"
          variant="outline-secondary"
          id={`dropdown-${group}`}
          className="d-flex align-items-center justify-content-between filter-dropdown-toggle"
          style={{
            minWidth: "140px",
            width: "auto",
            border: "1px solid #dee2e6",
            backgroundColor: "#fff",
            padding: "8px 12px",
            fontSize: "14px",
          }}
        >
          <span className="d-flex align-items-center gap-2 me-2 fs-14 text-capitalize text-truncate">
            <CiFilter size={16} className="flex-shrink-0" />
            <span className="text-truncate">{capitalize(group)}</span>
            {selectedCount > 0 && (
              <span className="badge primary-bg rounded-circle fs-10 flex-shrink-0">
                {selectedCount}
              </span>
            )}
          </span>
          <FaChevronDown size={12} className="flex-shrink-0" />
        </Dropdown.Toggle>

        <Dropdown.Menu
          flip={false}
          className="main-filter-dropdown-menu filter-dropdown-menu fs-20"
          style={{
            maxHeight: "300px",
            overflowY: "auto",
            minWidth: "250px",
            padding: "5px 2rem",
            zIndex: 1000,
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
                  label={
                    <span className="fs-14 text-capitalize">
                      {capitalize(option)}
                    </span>
                  }
                  className="mb-0 px-3 py-2 main-filter-checkbox"
                  checked={isFilterActive(group, option)}
                  onChange={() => handleCheckbox(group, option)}
                />
              </Dropdown.Item>
            );
          })}
        </Dropdown.Menu>
      </Dropdown>
    );
  };

  const isAnyFilterSelected =
    activeFilters && Object.keys(activeFilters).length > 0;

  return (
    <div
      className="aside-filters-container topfilter bg-white border-bottom mb-4"
      style={{
        position: "sticky",
        top: "0",
        zIndex: 99,
        backgroundColor: "white",
      }}
    >
      <div className="container-fluid px-2 px-md-3">
        {/* Single Row: Filters + Actions + ViewSwitcher */}
        <div className="row">
          <div className="col-12">
            <div className="d-flex align-items-center justify-content-between flex-wrap gap-2 py-3 topfilter-row">
              <div
                className="d-flex flex-wrap gap-2 align-items-center"
                style={{ flex: "1 1 auto", minWidth: 0 }}
              >
                {Object.entries(filters).map(([group, options]) => (
                  <div key={group} className="filter-item">
                    {renderDropdown(group, options)}
                  </div>
                ))}
              </div>
              {/* Action buttons container - stacks on mobile, row on desktop */}
              <div className="actions-container d-flex flex-column flex-sm-row align-items-stretch align-items-sm-center gap-2 flex-shrink-0">
                {isAnyFilterSelected && (
                  <div className="d-flex gap-2 w-sm-auto w-50">
                    {hasPendingChanges && onApplyFilters && (
                      <button
                        className="btn btn-primary btn-sm d-flex align-items-center justify-content-center col-4 gap-1 px-3 flex-fill flex-sm-grow-0"
                        onClick={onApplyFilters}
                        style={{ whiteSpace: "nowrap" }}
                      >
                        <MdCheck size={18} />
                        <span className="d-none d-sm-inline">Apply</span>
                      </button>
                    )}
                    <button
                      className="btn btn-danger btn-sm d-flex align-items-center justify-content-center gap-1 px-3 flex-fill flex-sm-grow-0"
                      onClick={clearFilters}
                      style={{ whiteSpace: "nowrap" }}
                      title="Clear all filters"
                    >
                      <MdClear size={18} />
                      <span>Clear</span>
                    </button>
                  </div>
                )}
                <div className="w-100 w-sm-auto">
                  <ViewSwitcher view={view} setView={setView} />
                </div>
              </div>
            </div>
            {isAnyFilterSelected && (
              <div className="d-flex flex-wrap gap-2 align-items-center mb-2">
                <small className="text-muted me-1 fw-semibold fs-14 d-none d-sm-inline">
                  Active filters:
                </small>
                {Object.entries(activeFilters).map(([group, values]) =>
                  values.map((value) => (
                    <span
                      key={`${group}-${value}`}
                      className="badge bg-white text-dark border d-flex align-items-center gap-1 fs-12 text-capitalize py-1 px-2"
                      style={{ cursor: "pointer" }}
                    >
                      <span
                        className="text-truncate"
                        style={{ maxWidth: "150px" }}
                      >
                        {capitalize(value)}
                      </span>
                      <button
                        type="button"
                        className="btn-close btn-close-sm ms-1"
                        style={{ fontSize: "0.6rem"  }}
                        onClick={() => handleCheckbox(group, value)}
                        aria-label="Remove filter"
                      ></button>
                    </span>
                  ))
                )}
              </div>
            )}
          </div>
        </div>
      </div>

      <style jsx>{`
        @media (max-width: 576px) {
          .topfilter-filters .filter-item {
            min-width: 0;
          }

          .filter-dropdown-toggle {
            font-size: 12px !important;
            padding: 6px 8px !important;
          }

          .fs-14 {
            font-size: 12px !important;
          }

          .badge.fs-10 {
            font-size: 8px !important;
            padding: 2px 4px !important;
          }

          /* Stack action buttons and viewswitcher on mobile */
          .actions-container {
            width: 100%;
          }

          .actions-container > div {
            width: 100%;
          }
        }

        @media (max-width: 768px) {
          .container-fluid {
            padding-left: 12px !important;
            padding-right: 12px !important;
          }
        }
      `}</style>
    </div>
  );
};

export default TopFilter;
