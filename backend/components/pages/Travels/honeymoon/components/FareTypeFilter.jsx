import { useState } from "react";
import "./Filters.css";

const FARE_TYPES = [
  { id: "REGULAR", label: "Regular", info: null },
  {
    id: "STUDENT",
    label: "Student",
    info:
      "Only students above 12 years of age are eligible for special fares and/or additional baggage allowances. Carrying valid student ID cards and student visas (where applicable) is mandatory, else the passenger may be denied boarding or asked to pay for extra baggage.",
  },
  {
    id: "SENIOR_CITIZEN",
    label: "Senior Citizen",
    info:
      "Only senior citizens above the age of 61 years can avail this special fare. It is mandatory to produce proof of Date of Birth at the airport, without which prevailing fares will be charged.",
  },
];

export default function FareTypeFilter({ value, onChange }) {
  const [hovered, setHovered] = useState(null);

  return (
    <div className="filter-group filter-group-fare">
      <label className="filter-label">Fare Type</label>
      <div className="filter-checkbox-group filter-checkbox-group-fare">
        {FARE_TYPES.map((fare) => (
          <label key={fare.id} className="filter-checkbox-label">
            <input
              type="checkbox"
              className="filter-checkbox"
              checked={value === fare.id}
              onChange={() => onChange(fare.id)}
            />
            <span className="filter-checkbox-text">{fare.label}</span>
            {fare.info && (
              <span
                className="fare-info-wrapper"
                onMouseEnter={() => setHovered(fare.id)}
                onMouseLeave={() => setHovered(null)}
              >
                <span className="fare-info-icon">i</span>
                {hovered === fare.id && (
                  <span className="fare-info-tooltip">{fare.info}</span>
                )}
              </span>
            )}
          </label>
        ))}
      </div>
    </div>
  );
}
