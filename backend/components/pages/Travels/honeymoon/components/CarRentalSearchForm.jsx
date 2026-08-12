import { useEffect, useRef, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Car, Loader2 } from "lucide-react";
import {
  buildCabLocationNode,
  fetchCabPlaceDetails,
  searchCabLocations,
} from "../../../../../services/api/cabApi";
import "./HotelSearchForm.css";

const JOURNEY_TYPES = [
  { value: "airport_transfer", label: "Airport Transfer" },
  { value: "outstation", label: "Outstation" },
];

const TRIP_TYPES = [
  { value: "oneway", label: "One Way" },
  { value: "roundtrip", label: "Round Trip" },
];

const todayIso = () => new Date().toISOString().slice(0, 10);

/** Autocomplete input backed by /tripjack-cabs/search-locations. */
function LocationField({ label, placeholder, value, selected, onChange, onSelect }) {
  const [suggestions, setSuggestions] = useState([]);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const wrapperRef = useRef(null);
  const skipNextFetchRef = useRef(false);

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target)) {
        setOpen(false);
      }
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    if (skipNextFetchRef.current) {
      skipNextFetchRef.current = false;
      return undefined;
    }
    const query = value.trim();
    if (query.length < 2) {
      setSuggestions([]);
      return undefined;
    }

    const controller = new AbortController();
    const timer = setTimeout(() => {
      setLoading(true);
      searchCabLocations(query, { signal: controller.signal })
        .then((places) => {
          setSuggestions(places);
          setOpen(true);
        })
        .catch(() => setSuggestions([]))
        .finally(() => setLoading(false));
    }, 350);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [value]);

  return (
    <div className="hotel-main-field hotel-main-field--destination" ref={wrapperRef}>
      <div className="hotel-main-label">{label}</div>
      <div className="field-wrapper">
        <input
          className="hotel-main-input"
          type="text"
          placeholder={placeholder}
          autoComplete="off"
          value={value}
          onChange={(event) => {
            onChange(event.target.value);
            onSelect(null);
          }}
          onFocus={() => suggestions.length && setOpen(true)}
        />
        {open && (
          <div className="airport-suggestions hotel-airport-suggestions">
            {loading ? (
              <div className="suggestion-item suggestion-loading">
                <Loader2 size={16} className="spin" /> Searching...
              </div>
            ) : suggestions.length ? (
              suggestions.map((place) => (
                <button
                  type="button"
                  key={place.id}
                  className="suggestion-item"
                  onClick={() => {
                    skipNextFetchRef.current = true;
                    onChange(place.displayLabel || place.name);
                    onSelect(place);
                    setOpen(false);
                  }}
                >
                  <div className="suggestion-main">
                    <span className="suggestion-name">
                      {place.displayLabel || place.name}
                    </span>
                  </div>
                </button>
              ))
            ) : (
              <div className="suggestion-item suggestion-empty">No locations found</div>
            )}
          </div>
        )}
      </div>
      {selected ? null : value.trim() ? (
        <div style={{ fontSize: 11, color: "#9ca3af", paddingLeft: 4 }}>
          Pick a suggestion
        </div>
      ) : null}
    </div>
  );
}

export default function CarRentalSearchForm() {
  const navigate = useNavigate();

  const [journeyType, setJourneyType] = useState("airport_transfer");
  const [tripType, setTripType] = useState("oneway");
  const isRoundTrip = tripType === "roundtrip";
  const [originText, setOriginText] = useState("");
  const [originPlace, setOriginPlace] = useState(null);
  const [destText, setDestText] = useState("");
  const [destPlace, setDestPlace] = useState(null);
  const [pickupDate, setPickupDate] = useState("");
  const [pickupTime, setPickupTime] = useState("09:00");
  const [returnDate, setReturnDate] = useState("");
  const [returnTime, setReturnTime] = useState("18:00");
  const [passengers, setPassengers] = useState(1);
  const [luggage, setLuggage] = useState(1);
  const [error, setError] = useState("");
  const [submitting, setSubmitting] = useState(false);

  const handleSearch = async () => {
    if (!originPlace) {
      setError("Please select a pick-up location from the suggestions.");
      return;
    }
    if (!destPlace) {
      setError("Please select a drop-off location from the suggestions.");
      return;
    }
    if (!pickupDate) {
      setError("Please select a pick-up date.");
      return;
    }
    if (isRoundTrip && !returnDate) {
      setError("Please select a return date.");
      return;
    }
    if (
      isRoundTrip &&
      `${returnDate}T${returnTime}` <= `${pickupDate}T${pickupTime}`
    ) {
      setError("Return must be after pick-up.");
      return;
    }

    setError("");
    setSubmitting(true);

    try {
      // Both endpoints resolve a placeId into the lat/long + address that the
      // quotes payload requires for origin and destination.
      const [originDetails, destDetails] = await Promise.all([
        fetchCabPlaceDetails(originPlace.value || originPlace.id),
        fetchCabPlaceDetails(destPlace.value || destPlace.id),
      ]);

      if (!originDetails || !destDetails) {
        setError("Could not resolve the selected locations. Please try again.");
        return;
      }

      const payload = {
        pickupDate: `${pickupDate} ${pickupTime}`,
        ...(isRoundTrip ? { returnDate: `${returnDate} ${returnTime}` } : {}),
        origin: buildCabLocationNode(originPlace, originDetails),
        destination: buildCabLocationNode(destPlace, destDetails),
        journeyType,
        tripType,
        passengers: Number(passengers) || 1,
        quoteFilter: {
          paxCount: Number(passengers) || 1,
          ...(journeyType === "outstation" ? { luggageCount: Number(luggage) || 1 } : {}),
        },
      };

      navigate("/honeymoon/cabs", { state: { payload } });
    } catch (err) {
      console.error("Cab search failed", err);
      setError("Something went wrong while searching for cabs. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="search-card hotel-search-card">
      <div className="hotel-search-stack">
        <div
          style={{ display: "flex", gap: 10, flexWrap: "wrap", padding: "0 4px 12px" }}
        >
          {JOURNEY_TYPES.map((option) => (
            <button
              key={option.value}
              type="button"
              onClick={() => setJourneyType(option.value)}
              style={{
                borderRadius: 999,
                padding: "8px 18px",
                fontWeight: 700,
                fontSize: 13,
                cursor: "pointer",
                border:
                  journeyType === option.value ? "none" : "1px solid #e5e7eb",
                background: journeyType === option.value ? "#ed1173" : "#fff",
                color: journeyType === option.value ? "#fff" : "#374151",
              }}
            >
              {option.label}
            </button>
          ))}
          <span style={{ width: 1, background: "#e5e7eb", margin: "0 4px" }} />
          {TRIP_TYPES.map((option) => (
            <button
              key={option.value}
              type="button"
              onClick={() => setTripType(option.value)}
              style={{
                borderRadius: 999,
                padding: "8px 18px",
                fontWeight: 700,
                fontSize: 13,
                cursor: "pointer",
                border: tripType === option.value ? "none" : "1px solid #e5e7eb",
                background: tripType === option.value ? "#111827" : "#fff",
                color: tripType === option.value ? "#fff" : "#374151",
              }}
            >
              {option.label}
            </button>
          ))}
        </div>

        <div className="hotel-search-main-row">
          <LocationField
            label={journeyType === "airport_transfer" ? "Pick-up (Airport / City)" : "Pick-up"}
            placeholder="Airport, city or landmark"
            value={originText}
            selected={originPlace}
            onChange={setOriginText}
            onSelect={setOriginPlace}
          />

          <LocationField
            label="Drop-off"
            placeholder="Airport, city or landmark"
            value={destText}
            selected={destPlace}
            onChange={setDestText}
            onSelect={setDestPlace}
          />

          <div className="hotel-main-field">
            <div className="hotel-main-label">Pick-up date</div>
            <input
              className="hotel-main-input"
              type="date"
              min={todayIso()}
              value={pickupDate}
              onChange={(event) => setPickupDate(event.target.value)}
            />
          </div>

          <div className="hotel-main-field">
            <div className="hotel-main-label">Pick-up time</div>
            <input
              className="hotel-main-input"
              type="time"
              value={pickupTime}
              onChange={(event) => setPickupTime(event.target.value)}
            />
          </div>

          {isRoundTrip && (
            <>
              <div className="hotel-main-field">
                <div className="hotel-main-label">Return date</div>
                <input
                  className="hotel-main-input"
                  type="date"
                  min={pickupDate || todayIso()}
                  value={returnDate}
                  onChange={(event) => setReturnDate(event.target.value)}
                />
              </div>

              <div className="hotel-main-field">
                <div className="hotel-main-label">Return time</div>
                <input
                  className="hotel-main-input"
                  type="time"
                  value={returnTime}
                  onChange={(event) => setReturnTime(event.target.value)}
                />
              </div>
            </>
          )}

          <div className="hotel-main-field">
            <div className="hotel-main-label">Passengers</div>
            <input
              className="hotel-main-input"
              type="number"
              min={1}
              max={20}
              value={passengers}
              onChange={(event) => setPassengers(event.target.value)}
            />
          </div>

          {journeyType === "outstation" && (
            <div className="hotel-main-field">
              <div className="hotel-main-label">Luggage</div>
              <input
                className="hotel-main-input"
                type="number"
                min={0}
                max={20}
                value={luggage}
                onChange={(event) => setLuggage(event.target.value)}
              />
            </div>
          )}

          <button
            type="button"
            className="hotel-search-submit"
            onClick={handleSearch}
            disabled={submitting}
          >
            {submitting ? (
              <Loader2 size={16} className="spin" style={{ marginRight: 8 }} />
            ) : (
              <Car size={16} style={{ marginRight: 8 }} />
            )}
            {submitting ? "Searching..." : "Search"}
          </button>
        </div>

        {error ? (
          <div style={{ color: "#ed1173", fontWeight: 600, padding: "8px 4px 0" }}>
            {error}
          </div>
        ) : null}
      </div>
    </div>
  );
}
