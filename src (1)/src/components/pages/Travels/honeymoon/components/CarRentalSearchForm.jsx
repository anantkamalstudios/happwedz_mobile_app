import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { Car, Loader2, MapPin, ArrowLeftRight, Search } from "lucide-react";
import {
  buildCabLocationNode,
  fetchCabPlaceDetails,
} from "../../../../../services/api/cabApi";
import CabLocationField from "./CabLocationField";
import CabDateTimeField from "./CabDateTimeField";
import CabPaxField from "./CabPaxField";
import "./HotelSearchForm.css";
import "./CabSearchForm.css";

const JOURNEY_TYPES = [
  { value: "airport_transfer", label: "Airport Transfers" },
  { value: "outstation", label: "Outstation" },
  { value: "local", label: "Local" },
];

export default function CarRentalSearchForm() {
  const navigate = useNavigate();

  const [journeyType, setJourneyType] = useState("airport_transfer");
  // The portal has no one-way/round-trip switch: a return date makes it a
  // roundtrip and clearing it makes it one way, so the two can never disagree.
  const [returnDate, setReturnDate] = useState("");
  const isRoundTrip = Boolean(returnDate);
  const tripType = isRoundTrip ? "roundtrip" : "oneway";
  const [originText, setOriginText] = useState("");
  const [originPlace, setOriginPlace] = useState(null);
  const [destText, setDestText] = useState("");
  const [destPlace, setDestPlace] = useState(null);
  const [pickupDate, setPickupDate] = useState("");
  const [pickupTime, setPickupTime] = useState("09:00");
  const [returnTime, setReturnTime] = useState("18:00");
  const [passengers, setPassengers] = useState(1);
  const [luggage, setLuggage] = useState(1);

  /**
   * The two timing rules the cabs API enforces, per its documentation:
   * a pickup must be at least 2 hours out, and on a roundtrip the return must
   * be at least 30 minutes after it. Checked live inside each picker so the
   * message appears where the time is being set, and again on submit in case a
   * pickup change invalidates a return that was already applied.
   */
  const MIN_LEAD_MS = 2 * 60 * 60 * 1000;
  const MIN_GAP_MS = 30 * 60 * 1000;
  const at = (d, t) => new Date(`${d}T${t || '00:00'}:00`);

  const validatePickup = (d, t) => {
    const when = at(d, t);
    if (Number.isNaN(when.getTime())) return null;
    if (when.getTime() - Date.now() < MIN_LEAD_MS) {
      return 'Pickup time must be at least 2 hours from now';
    }
    return null;
  };

  const validateReturn = (d, t) => {
    if (!pickupDate) return 'Select a pickup date and time first';
    const when = at(d, t);
    const from = at(pickupDate, pickupTime);
    if (Number.isNaN(when.getTime()) || Number.isNaN(from.getTime())) return null;
    if (when.getTime() - from.getTime() < MIN_GAP_MS) {
      return 'Return time must be atleast 30 minutes after pickup time';
    }
    return null;
  };

  /** Swap pick-up and drop-off, text and resolved place together. */
  const swapEnds = () => {
    setOriginText(destText);
    setDestText(originText);
    setOriginPlace(destPlace);
    setDestPlace(originPlace);
  };
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
    // Re-run the picker's own rules here: changing the pickup after a return
    // was applied can leave a pair that was valid when set and is not now.
    const pickupProblem = validatePickup(pickupDate, pickupTime);
    if (pickupProblem) {
      setError(pickupProblem);
      return;
    }
    if (isRoundTrip) {
      const returnProblem = validateReturn(returnDate, returnTime);
      if (returnProblem) {
        setError(returnProblem);
        return;
      }
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
    <div className="cab-search-card">
      {/* Journey type is a radio group in the portal, not pills — the three
          options are mutually exclusive and each reshapes the search. */}
      <div className="cab-journey-row" role="radiogroup" aria-label="Journey type">
        {JOURNEY_TYPES.map((option) => (
          <label key={option.value} className="cab-journey">
            <input
              type="radio"
              name="cab-journey"
              checked={journeyType === option.value}
              onChange={() => setJourneyType(option.value)}
            />
            <span>{option.label}</span>
          </label>
        ))}
      </div>

      <div className="cab-fields">
        {/* Pick-up and drop-off share one bordered box with the swap between
            them, so the pair reads as a single route control. */}
        <div className="cab-route">
          <CabLocationField
            icon={<Car size={15} />}
            placeholder="Where from?"
            value={originText}
            selected={originPlace}
            onChange={setOriginText}
            onSelect={setOriginPlace}
          />
          <button
            type="button"
            className="cab-swap"
            onClick={swapEnds}
            aria-label="Swap pick-up and drop-off"
          >
            <ArrowLeftRight size={15} />
          </button>
          <CabLocationField
            icon={<MapPin size={15} />}
            placeholder="Where to?"
            value={destText}
            selected={destPlace}
            onChange={setDestText}
            onSelect={setDestPlace}
          />
        </div>

        <CabDateTimeField
          placeholder="Pick-up date and time"
          date={pickupDate}
          time={pickupTime}
          validate={validatePickup}
          onApply={(d, t) => { setPickupDate(d); setPickupTime(t); }}
        />

        <CabDateTimeField
          placeholder="Select return date and time"
          date={returnDate}
          time={returnTime}
          minDate={pickupDate || undefined}
          clearable
          validate={validateReturn}
          onApply={(d, t) => { setReturnDate(d); setReturnTime(t); }}
          onClear={() => setReturnDate("")}
        />
      </div>

      <div className="cab-actions">
        <CabPaxField
          passengers={passengers}
          bags={luggage}
          onPassengersChange={setPassengers}
          onBagsChange={setLuggage}
        />

        <button
          type="button"
          className="cab-search-btn"
          onClick={handleSearch}
          disabled={submitting}
        >
          {submitting ? <Loader2 size={15} className="spin" /> : <Search size={15} />}
          {submitting ? "Searching…" : "Search Cabs"}
        </button>
      </div>

      {error && <p className="cab-error">{error}</p>}
    </div>
  );

}
