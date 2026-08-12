import React from "react";
import { FontAwesomeIcon } from "@fortawesome/react-fontawesome";
import { CiHeart } from "react-icons/ci";
import { FaIndianRupeeSign } from "react-icons/fa6";
import { CiLocationOn } from "react-icons/ci";
import { LuUsers } from "react-icons/lu";

import {
  faHeart,
  faMapMarkerAlt,
  faUser,
  faRupeeSign,
} from "@fortawesome/free-solid-svg-icons";

const VenueCard = ({ venue }) => {
  return (
    <div className="card h-100 border-0 shadow-sm rounded-4 venue-card">
      <div className="position-relative">
        <img
          src={venue.image}
          className="card-img-top rounded-top-4"
          alt={venue.name}
          style={{ height: "200px", objectFit: "cover" }}
        />
        <button className="btn-glass position-absolute top-0 end-0 m-2 rounded-circle">
          <CiHeart size={30} className="text-white flip-icon" />
        </button>
      </div>

      <div className="card-body p-3">
        <h6
          className="card-title fw-semibold text-dark mb-1"
          style={{ fontSize: "1rem" }}
        >
          {venue.name}
        </h6>
        <p className="text-muted mb-2 small">
          <CiLocationOn className="text-dark me-2" />
          {venue.location}
        </p>

        <div className="d-flex justify-content-between text-muted small mb-2">
          <span>
            <LuUsers className="text-dark me-2" />
            {venue.capacity} guests
          </span>
          <span className="text-primary fw-semibold">
            <FaIndianRupeeSign />
            {venue.price}
          </span>
        </div>

        <div className="d-grid mt-3">
          <button className="custom-btn-quote-sm">Get Best Quote</button>
        </div>
      </div>
    </div>
  );
};

export default VenueCard;
