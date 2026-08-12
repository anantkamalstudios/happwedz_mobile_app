import React from "react";
import { CiCircleList, CiGrid41 } from "react-icons/ci";
import { FaList, FaTh } from "react-icons/fa";
import { FaRegMap } from "react-icons/fa6";

const ViewSwitcher = ({ view, setView }) => {
  return (
    <div className="view-switcher-wrapper rounded-2">
      <div className="view-switcher d-flex" style={{ width: "fit-content" }}>
        <button
          onClick={() => setView("images")}
          className={
            view === "images" ? "switch-btn active fs-14" : "switch-btn fs-14"
          }
        >
          <CiGrid41 className="me-1" /> GRID
        </button>
        <button
          onClick={() => setView("list")}
          className={
            view === "list" ? "switch-btn active fs-14" : "switch-btn fs-14"
          }
        >
          <CiCircleList className="me-1" /> LIST
        </button>
        <button
          onClick={() => setView("map")}
          className={
            view === "map" ? "switch-btn active fs-14" : "switch-btn fs-14"
          }
        >
          <FaRegMap className="me-1" /> MAP
        </button>
      </div>
    </div>
  );
};

export default ViewSwitcher;
