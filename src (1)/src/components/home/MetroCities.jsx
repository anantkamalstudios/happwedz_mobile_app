import React from "react";
import { useNavigate } from "react-router-dom";
import citiesData from "../../data/citiesData";
import { useDispatch } from "react-redux";
import { setLocation } from "../../redux/locationSlice";

const MetroCities = () => {
  const navigate = useNavigate();
  const dispatch = useDispatch();

  const handleCityClick = (cityLabel) => {
    const cleanCityName = cityLabel.replace(/^Wedding Venues\s*/i, "").trim();
    const citySlug = cleanCityName.toLowerCase().replace(/[^a-z0-9\s-]/g, "").replace(/\s+/g, "-").replace(/-+/g, "-").replace(/^-+|-+$/g, "");
    dispatch(setLocation(cleanCityName));
    navigate(`/wedding-venues/${citySlug}`);
  };

  return (
    <div className="container my-5">
      <h4 className="mb-4 text-center fs-20">Wedding Venues By Location</h4>

      <div className="mt-5 metro-cities-container">
        {Object.entries(citiesData).map(([state, venues]) => (
          <div key={state} className="mb-4 break-inside-avoid">
            <p className="fw-bold fs-16">{state}</p>
            <ul className="list-unstyled mt-3">
              {venues.map((venue, index) => (
                <li
                  key={index}
                  className="lh-lg mb-1 fs-14"
                  style={{ fontSize: "15px", cursor: "pointer" }}
                  onClick={() => handleCityClick(venue)}
                >
                  {venue}
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
    </div>
  );
};

export default MetroCities;
