import { useRef, useEffect } from "react";
import { Users } from "lucide-react";

export default function TravellerSelector({
  adults,
  children,
  cabinClass,
  showDropdown,
  onToggleDropdown,
  onAdultsChange,
  onChildrenChange,
}) {
  const travelersRef = useRef(null);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (travelersRef.current && !travelersRef.current.contains(event.target)) {
        onToggleDropdown(false);
      }
    };

    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, [onToggleDropdown]);

  return (
    <div className="field-box" ref={travelersRef}>
      <div className="field-label">
        <span className="field-label-content">
          <Users size={14} /> Travelers
        </span>
      </div>
      <div className="field-wrapper">
        <div
          className="field-value field-value-clickable"
          onClick={() => onToggleDropdown(!showDropdown)}
        >
          {adults + children} {adults + children === 1 ? "traveler" : "travelers"}
          {adults > 0 && `, ${adults} ${adults === 1 ? "adult" : "adults"}`}
          {children > 0 &&
            `, ${children} ${children === 1 ? "child" : "children"}`}
        </div>
        {showDropdown && (
          <div className="travelers-dropdown">
            <div className="traveler-type">
              <div className="traveler-label">Adults</div>
              <div className="traveler-controls">
                <button
                  className="traveler-button"
                  onClick={() => onAdultsChange(Math.max(1, adults - 1))}
                  disabled={adults <= 1}
                >
                  -
                </button>
                <div className="traveler-count">{adults}</div>
                <button
                  className="traveler-button"
                  onClick={() => onAdultsChange(adults + 1)}
                >
                  +
                </button>
              </div>
            </div>
            <div className="traveler-type">
              <div className="traveler-label">Children</div>
              <div className="traveler-controls">
                <button
                  className="traveler-button"
                  onClick={() => onChildrenChange(Math.max(0, children - 1))}
                  disabled={children <= 0}
                >
                  -
                </button>
                <div className="traveler-count">{children}</div>
                <button
                  className="traveler-button"
                  onClick={() => onChildrenChange(children + 1)}
                >
                  +
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
      <div className="field-sub">{cabinClass}</div>
    </div>
  );
}
