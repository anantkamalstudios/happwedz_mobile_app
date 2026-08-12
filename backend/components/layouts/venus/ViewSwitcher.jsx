import React, { useState } from "react";
import { FaList, FaTh, FaMapMarkerAlt } from "react-icons/fa";

const ViewSwitcher = ({ view, setView }) => {
  return (
    <div className="col-3 col-lg-3 ms-auto py-4">
      <div className="view-switcher-wrapper">
        <div className="view-switcher">
          <button
            onClick={() => setView("list")}
            className={
              view === "list switch-btn" ? "active switch-btn" : "switch-btn"
            }
          >
            <FaList className="me-1" /> List
          </button>
          <button
            onClick={() => setView("images")}
            className={
              view === "images switch-btn" ? "active switch-btn" : " switch-btn"
            }
          >
            <FaTh className="me-1" /> Images
          </button>
          <button
            onClick={() => setView("map")}
            className={
              view === "map switch-btn" ? "active switch-btn" : " switch-btn"
            }
          >
            <FaMapMarkerAlt className="me-1" /> Map
          </button>
        </div>
      </div>
    </div>
  );
};

export default ViewSwitcher;
