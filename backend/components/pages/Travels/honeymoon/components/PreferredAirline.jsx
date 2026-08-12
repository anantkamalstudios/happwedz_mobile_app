import { useState, useRef, useEffect, useMemo } from "react";
import { MdFlight } from "react-icons/md";
import "./Filters.css";

// Airline list (IATA code → name). The TripJack search API has no "list airlines"
// endpoint — `preferredAirline` is just a filter field — so this list is static,
// the same way TripJack's own portal hardcodes it. Search filters it client-side.
export const AIRLINES = [
  { code: "6E", name: "IndiGo" },
  { code: "SG", name: "SpiceJet" },
  { code: "AI", name: "Air India" },
  { code: "QP", name: "Akasa Air" },
  { code: "IX", name: "AI Express" },
  { code: "EK", name: "Emirates" },
  { code: "EY", name: "Etihad Airways" },
  { code: "SQ", name: "Singapore Airlines" },
  { code: "QR", name: "Qatar Airways" },
  { code: "TK", name: "Turkish Airlines" },
  { code: "LH", name: "Lufthansa" },
  { code: "BA", name: "British Airways" },
  { code: "CX", name: "Cathay Pacific" },
  { code: "TG", name: "Thai Airways" },
  { code: "MH", name: "Malaysia Airlines" },
  { code: "UL", name: "SriLankan Airlines" },
  { code: "WY", name: "Oman Air" },
  { code: "SV", name: "Saudia" },
  { code: "G9", name: "Air Arabia" },
  { code: "FZ", name: "Flydubai" },
];

const MAX_AIRLINES = 10; // TripJack limit

/**
 * Multi-select Preferred Airline.
 * @param {string[]} value  Array of selected IATA codes
 * @param {(codes: string[]) => void} onChange
 */
export default function PreferredAirline({ value = [], onChange }) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const ref = useRef(null);

  // Always work with an array (tolerate an old string value from persisted state)
  const selectedCodes = Array.isArray(value) ? value : value ? [value] : [];

  useEffect(() => {
    const handleClickOutside = (e) => {
      if (ref.current && !ref.current.contains(e.target)) {
        setOpen(false);
        setQuery("");
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return AIRLINES;
    return AIRLINES.filter(
      (a) => a.name.toLowerCase().includes(q) || a.code.toLowerCase().includes(q)
    );
  }, [query]);

  const toggle = (code) => {
    if (selectedCodes.includes(code)) {
      onChange(selectedCodes.filter((c) => c !== code));
    } else if (selectedCodes.length < MAX_AIRLINES) {
      onChange([...selectedCodes, code]);
    }
  };

  const triggerLabel = () => {
    if (selectedCodes.length === 0) return "Select Preferred Airline";
    const first = AIRLINES.find((a) => a.code === selectedCodes[0]);
    const firstName = first ? first.name : selectedCodes[0];
    if (selectedCodes.length === 1) return firstName;
    return `${firstName} +${selectedCodes.length - 1}`;
  };

  return (
    <div className="filter-group filter-group-airline" ref={ref}>
      <label className="filter-label">Preferred Airline</label>
      <div className="airline-combobox">
        <div
          className="filter-select-wrapper airline-combobox-trigger"
          onClick={() => setOpen((o) => !o)}
        >
          <MdFlight className="filter-icon" />
          <span className={`airline-combobox-value ${selectedCodes.length ? "" : "placeholder"}`}>
            {triggerLabel()}
          </span>
        </div>

        {open && (
          <div className="airline-dropdown">
            <input
              type="text"
              className="airline-search-input"
              placeholder="Search airline…"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />

            {selectedCodes.length > 0 && (
              <div className="airline-clear-row" onClick={() => onChange([])}>
                Clear all ({selectedCodes.length}/{MAX_AIRLINES})
              </div>
            )}

            <div className="airline-options">
              {filtered.map((a) => {
                const checked = selectedCodes.includes(a.code);
                const disabled = !checked && selectedCodes.length >= MAX_AIRLINES;
                return (
                  <label
                    key={a.code}
                    className={`airline-option ${checked ? "active" : ""} ${disabled ? "disabled" : ""}`}
                  >
                    <input
                      type="checkbox"
                      checked={checked}
                      disabled={disabled}
                      onChange={() => toggle(a.code)}
                    />
                    <span className="airline-option-name">{a.name}</span>
                    <span className="airline-option-code">{a.code}</span>
                  </label>
                );
              })}
              {filtered.length === 0 && (
                <div className="airline-option airline-option-empty">No airline found</div>
              )}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
