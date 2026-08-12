import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { Calendar, Users } from "lucide-react";
import useAirportSearch from "../../../../../hooks/useAirportSearch";
import { buildTripJackSearchQuery } from "../../../../../utils/flightSearchUtils";
import "../tripjack-styles.css";
import { MdFlightLand, MdFlightTakeoff } from "react-icons/md";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { IoIosSwap } from "react-icons/io";
import PreferredAirline from "./PreferredAirline";
import FareTypeFilter from "./FareTypeFilter";
import AdditionalFilters from "./AdditionalFilters";

// Persist the search bar so coming back from results keeps everything filled in.
const STORAGE_KEY = "hw_flightSearchForm";
const RECENT_KEY = "hw_flightRecentSearches";
const loadSaved = () => {
  try {
    return JSON.parse(sessionStorage.getItem(STORAGE_KEY)) || {};
  } catch {
    return {};
  }
};

// Keep a short history of searches for the "Recent Searches" tab.
const saveRecentSearch = (entry) => {
  try {
    const list = JSON.parse(localStorage.getItem(RECENT_KEY) || "[]");
    const key = (e) => `${e.from}-${e.to}-${e.departureDate}-${e.returnDate || ""}`;
    const deduped = [entry, ...list.filter((e) => key(e) !== key(entry))].slice(0, 6);
    localStorage.setItem(RECENT_KEY, JSON.stringify(deduped));
  } catch {
    // ignore
  }
};

export default function FlightSearchForm() {
  const navigate = useNavigate();
  const saved = loadSaved();

  const [tripType, setTripType] = useState(saved.tripType || "round");
  const [departureDate, setDepartureDate] = useState(saved.departureDate || "");
  const [returnDate, setReturnDate] = useState(saved.returnDate || "");
  const [cabinClass, setCabinClass] = useState(saved.cabinClass || "Economy");
  const [paxType, setPaxType] = useState(saved.paxType || "REGULAR");
  const [adults, setAdults] = useState(saved.adults || 1);
  const [children, setChildren] = useState(saved.children || 0);
  const [infants, setInfants] = useState(saved.infants || 0);
  const [showTravelersDropdown, setShowTravelersDropdown] = useState(false);
  const [loading, setLoading] = useState(false);
  const [preferredAirline, setPreferredAirline] = useState(
    Array.isArray(saved.preferredAirline) ? saved.preferredAirline : []
  );
  const [directFlight, setDirectFlight] = useState(saved.directFlight || false);

  const cabinClasses = ["Economy", "Premium Economy", "Business", "First"];

  const [multiCityLegs, setMultiCityLegs] = useState(
    Array.isArray(saved.multiCityLegs) && saved.multiCityLegs.length >= 2
      ? saved.multiCityLegs
      : [
          { from: "", fromCode: "", to: "", toCode: "", date: "" },
          { from: "", fromCode: "", to: "", toCode: "", date: "" },
        ]
  );

  const fromSearch = useAirportSearch(350);
  const toSearch = useAirportSearch(350);
  const legFromSearches = [useAirportSearch(350), useAirportSearch(350), useAirportSearch(350), useAirportSearch(350), useAirportSearch(350)];
  const legToSearches = [useAirportSearch(350), useAirportSearch(350), useAirportSearch(350), useAirportSearch(350), useAirportSearch(350)];
  const [fromCode, setFromCode] = useState(saved.fromCode || "");
  const [toCode, setToCode] = useState(saved.toCode || "");

  // Restore From/To display text once on mount (the text lives inside the typeahead
  // hook). setQuerySilent avoids firing a search / showing a suggestions dropdown.
  useEffect(() => {
    if (saved.fromText) fromSearch.setQuerySilent(saved.fromText);
    if (saved.toText) toSearch.setQuerySilent(saved.toText);
    if (Array.isArray(saved.multiCityLegs)) {
      saved.multiCityLegs.forEach((leg, i) => {
        if (leg?.from && legFromSearches[i]) legFromSearches[i].setQuerySilent(leg.from);
        if (leg?.to && legToSearches[i]) legToSearches[i].setQuerySilent(leg.to);
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Save a snapshot whenever any field changes.
  useEffect(() => {
    const snapshot = {
      tripType, departureDate, returnDate, cabinClass, paxType,
      adults, children, infants, preferredAirline, directFlight,
      fromCode, toCode,
      fromText: fromSearch.query, toText: toSearch.query,
      multiCityLegs,
    };
    try {
      sessionStorage.setItem(STORAGE_KEY, JSON.stringify(snapshot));
    } catch {
      // ignore quota / serialization errors
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tripType, departureDate, returnDate, cabinClass, paxType, adults, children, infants, preferredAirline, directFlight, fromCode, toCode, fromSearch.query, toSearch.query, multiCityLegs]);

  // Prefill the form from elsewhere (Book Return / Recent Searches → "Search again").
  useEffect(() => {
    const handler = (e) => {
      const s = e.detail || {};
      if (s.tripType) setTripType(s.tripType);
      if (s.from != null) setFromCode(s.from);
      if (s.to != null) setToCode(s.to);
      if (s.fromText != null) fromSearch.setQuerySilent(s.fromText);
      if (s.toText != null) toSearch.setQuerySilent(s.toText);
      if (s.departureDate != null) setDepartureDate(s.departureDate);
      if (s.returnDate != null) setReturnDate(s.returnDate);
      if (s.adults != null) setAdults(s.adults);
      if (s.children != null) setChildren(s.children);
      if (s.infants != null) setInfants(s.infants);
      if (s.cabinClass) setCabinClass(s.cabinClass);
      if (s.paxType) setPaxType(s.paxType);
      if (Array.isArray(s.preferredAirline)) setPreferredAirline(s.preferredAirline);
      if (s.directFlight != null) setDirectFlight(s.directFlight);
    };
    window.addEventListener("hw:prefillSearch", handler);
    return () => window.removeEventListener("hw:prefillSearch", handler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Run a search immediately from saved params (Recent Searches → "Search again").
  useEffect(() => {
    const runHandler = (e) => {
      const r = e.detail || {};
      if ((r.tripType || "oneway") === "multicity") return; // multicity not supported here
      runSearch({
        ...r,
        adults: r.adults ?? 1,
        children: r.children ?? 0,
        infants: r.infants ?? 0,
        cabinClass: r.cabinClass || "Economy",
        tripType: r.tripType || "oneway",
        paxType: r.paxType || "REGULAR",
        preferredAirline: Array.isArray(r.preferredAirline) ? r.preferredAirline : [],
        directFlight: !!r.directFlight,
      });
    };
    window.addEventListener("hw:runSearch", runHandler);
    return () => window.removeEventListener("hw:runSearch", runHandler);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const parseDateValue = (dateStr) => (dateStr ? new Date(dateStr) : null);
  // Format using LOCAL date parts (not toISOString, which shifts to UTC and can
  // roll the date back a day in +offset timezones like IST).
  const formatDateValue = (dateObj) => {
    if (!dateObj) return "";
    const y = dateObj.getFullYear();
    const m = String(dateObj.getMonth() + 1).padStart(2, "0");
    const d = String(dateObj.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  };

  const updateMultiCityLeg = (index, field, value) => {
    const updated = [...multiCityLegs];
    updated[index][field] = value;
    setMultiCityLegs(updated);
  };
  const addMultiCityLeg = () => {
    if (multiCityLegs.length < 5) setMultiCityLegs([...multiCityLegs, { from: "", fromCode: "", to: "", toCode: "", date: "" }]);
  };
  const removeMultiCityLeg = (index) => {
    if (multiCityLegs.length > 2) setMultiCityLegs(multiCityLegs.filter((_, i) => i !== index));
  };
  const selectMultiCityAirport = (index, type, airport) => {
    const updated = [...multiCityLegs];
    if (type === "from") {
      updated[index].fromCode = airport.iata;
      updated[index].from = `${airport.city} (${airport.iata})`;
      legFromSearches[index].setQuery(updated[index].from);
      legFromSearches[index].setSuggestions([]);
    } else {
      updated[index].toCode = airport.iata;
      updated[index].to = `${airport.city} (${airport.iata})`;
      legToSearches[index].setQuery(updated[index].to);
      legToSearches[index].setSuggestions([]);
    }
    setMultiCityLegs(updated);
  };

  const handleMultiCitySearch = async () => {
    const validLegs = multiCityLegs.filter((l) => l.fromCode && l.toCode && l.date);
    if (validLegs.length < 2) {
      alert("Please fill at least 2 legs with origin, destination and date");
      return;
    }

    const isAscending = validLegs.every((leg, idx) => {
      if (idx === 0) return true;
      return new Date(leg.date).getTime() >= new Date(validLegs[idx - 1].date).getTime();
    });
    if (!isAscending) {
      alert("Travel dates must be in ascending order. Next date cannot be earlier than previous leg.");
      return;
    }
    const searchModifiers = { isDirectFlight: false, isConnectingFlight: true };
    if (paxType && paxType !== "REGULAR") searchModifiers.pft = paxType;

    const mcQuery = {
      cabinClass: cabinClass.toUpperCase().replace(/\s+/g, "_"),
      paxInfo: { ADULT: adults, CHILD: children, INFANT: infants },
      routeInfos: validLegs.map((leg) => ({
        fromCityOrAirport: { code: leg.fromCode },
        toCityOrAirport: { code: leg.toCode },
        travelDate: leg.date,
      })),
      searchModifiers,
    };

    const airlineCodes = (Array.isArray(preferredAirline) ? preferredAirline : [preferredAirline])
      .map((c) => String(c || "").trim().toUpperCase())
      .filter(Boolean);
    if (airlineCodes.length) mcQuery.preferredAirline = airlineCodes.slice(0, 10).map((code) => ({ code }));

    const searchQuery = { searchQuery: mcQuery };
    setLoading(true);
    try {
      const { searchFlights } = await import("../../../../../services/api/flightApi");
      const result = await searchFlights(searchQuery.searchQuery);
      navigate("/honeymoon/flights/multicity", {
        state: {
          searchParams: { tripType: "multicity", adults, children, infants, cabinClass, legs: validLegs },
          searchQuery: searchQuery.searchQuery,
          initialResults: { direct: null, connecting: result },
        },
      });
    } catch (err) {
      console.error(err);
      alert("Search failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  // Core one-way/round search — runs with explicit params (so "Search again" can
  // trigger it directly without first repopulating the form and waiting for state).
  const runSearch = async (p) => {
    const from = p.from;
    const to = p.to;
    if (!from || !to || !p.departureDate) return alert("Please fill in all required fields");
    if (p.tripType === "round" && !p.returnDate) return alert("Please select return date for round trip");

    const searchQuery = buildTripJackSearchQuery({
      from, to,
      departureDate: p.departureDate, returnDate: p.returnDate,
      adults: p.adults, children: p.children, infants: p.infants,
      cabinClass: p.cabinClass, tripType: p.tripType, paxType: p.paxType,
      preferredAirline: p.preferredAirline, directFlight: p.directFlight,
    });
    const searchParams = {
      from, to,
      departureDate: p.departureDate, returnDate: p.returnDate,
      adults: p.adults, children: p.children, infants: p.infants,
      cabinClass: p.cabinClass, tripType: p.tripType, paxType: p.paxType,
      preferredAirline: p.preferredAirline, directFlight: p.directFlight,
    };

    saveRecentSearch({
      tripType: p.tripType, from, to, fromText: p.fromText || from, toText: p.toText || to,
      departureDate: p.departureDate, returnDate: p.returnDate,
      adults: p.adults, children: p.children, infants: p.infants,
      cabinClass: p.cabinClass, paxType: p.paxType,
      preferredAirline: p.preferredAirline, directFlight: p.directFlight, ts: Date.now(),
    });

    setLoading(true);
    try {
      const { searchFlights } = await import("../../../../../services/api/flightApi");
      // Spread the base searchModifiers so pft (Student/Senior) + preferredAirline survive the direct/connecting split.
      const directQuery = { ...searchQuery, searchModifiers: { ...searchQuery.searchModifiers, isDirectFlight: true, isConnectingFlight: false } };

      if (p.directFlight) {
        // Direct Flight checked → only non-stop results (docs §Search Modifiers).
        const [d] = await Promise.allSettled([searchFlights(directQuery)]);
        navigate("/honeymoon/flights", { state: { searchParams, initialResults: { direct: d.status === "fulfilled" ? d.value : null, connecting: null } } });
      } else {
        const connectingQuery = { ...searchQuery, searchModifiers: { ...searchQuery.searchModifiers, isDirectFlight: false, isConnectingFlight: true } };
        const [d, c] = await Promise.allSettled([searchFlights(directQuery), searchFlights(connectingQuery)]);
        navigate("/honeymoon/flights", { state: { searchParams, initialResults: { direct: d.status === "fulfilled" ? d.value : null, connecting: c.status === "fulfilled" ? c.value : null } } });
      }
    } catch (err) {
      console.error("Error searching flights:", err);
      alert("Error searching flights. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleSearchFlights = () => {
    if (tripType === "multicity") return handleMultiCitySearch();
    const from = fromCode || fromSearch.query;
    const to = toCode || toSearch.query;
    return runSearch({
      from, to, fromText: fromSearch.query, toText: toSearch.query,
      departureDate, returnDate, adults, children, infants,
      cabinClass, tripType, paxType, preferredAirline, directFlight,
    });
  };

  const totalPax = adults + children + infants;

  // Shared passenger + class popup (TripJack-style: Adult / Children / Infant counters + cabin class).
  // Constraints per docs: total ≤ 9, infants ≤ adults (1 infant per adult lap).
  const renderTravelersDropdown = () => (
    <div className="tj-travelers-dropdown" onClick={(e) => e.stopPropagation()}>
      <div className="tj-traveler-row">
        <span>Adults<small style={{ display: "block", color: "#8c95a8", fontWeight: 400 }}>Age 12+</small></span>
        <div className="tj-counter">
          <button onClick={(e) => { e.stopPropagation(); setAdults(Math.max(1, adults - 1)); }}>-</button>
          <span>{adults}</span>
          <button onClick={(e) => { e.stopPropagation(); if (totalPax < 9) setAdults(adults + 1); }}>+</button>
        </div>
      </div>
      <div className="tj-traveler-row">
        <span>Children<small style={{ display: "block", color: "#8c95a8", fontWeight: 400 }}>Age 2-12</small></span>
        <div className="tj-counter">
          <button onClick={(e) => { e.stopPropagation(); setChildren(Math.max(0, children - 1)); }}>-</button>
          <span>{children}</span>
          <button onClick={(e) => { e.stopPropagation(); if (totalPax < 9) setChildren(children + 1); }}>+</button>
        </div>
      </div>
      <div className="tj-traveler-row">
        <span>Infants<small style={{ display: "block", color: "#8c95a8", fontWeight: 400 }}>Age 0-2</small></span>
        <div className="tj-counter">
          <button onClick={(e) => { e.stopPropagation(); setInfants(Math.max(0, infants - 1)); }}>-</button>
          <span>{infants}</span>
          <button onClick={(e) => { e.stopPropagation(); if (infants < adults && totalPax < 9) setInfants(infants + 1); }}>+</button>
        </div>
      </div>

      <div className="tj-cabin-class-group">
        <div className="tj-cabin-class-label">Select Class</div>
        {cabinClasses.map((c) => (
          <label key={c} className="tj-cabin-class-option" onClick={(e) => e.stopPropagation()}>
            <input
              type="radio"
              name="cabinClass"
              checked={cabinClass === c}
              onChange={(e) => { e.stopPropagation(); setCabinClass(c); }}
            />
            <span>{c}</span>
          </label>
        ))}
      </div>

      <button
        type="button"
        className="tj-pax-done-btn"
        onClick={(e) => { e.stopPropagation(); setShowTravelersDropdown(false); }}
      >
        DONE
      </button>
    </div>
  );

  return (
    <div className="tj-flight-search-wrapper">
      <div className="tj-trip-type-tabs">
        <div className={`tj-trip-tab ${tripType === "oneway" ? "active" : ""}`} onClick={() => setTripType("oneway")}>ONE WAY</div>
        <div className={`tj-trip-tab ${tripType === "round" ? "active" : ""}`} onClick={() => setTripType("round")}>ROUND TRIP</div>
        <div className={`tj-trip-tab ${tripType === "multicity" ? "active" : ""}`} onClick={() => setTripType("multicity")}>MULTI CITY</div>
      </div>

      <div className="tj-search-card">
        {tripType === "multicity" ? (
          <div className="tj-multicity-wrapper">
            {multiCityLegs.map((leg, index) => (
              <div key={index} className="tj-multicity-row">
                <div className="tj-search-row">
                  <div className="tj-field-group tj-from-field">
                    <MdFlightTakeoff className="tj-field-icon" size={18} />
                    <div className="tj-field-content">
                      <div className="tj-field-label">From</div>
                      <input className="tj-field-input" placeholder="Where from?" value={legFromSearches[index].query} onChange={(e) => { legFromSearches[index].setQuery(e.target.value); updateMultiCityLeg(index, "fromCode", ""); updateMultiCityLeg(index, "from", e.target.value); }} onBlur={() => setTimeout(() => legFromSearches[index].setSuggestions([]), 300)} />
                      <div className="tj-field-sublabel">{leg.fromCode || "City / Airport"}</div>
                    </div>
                    {legFromSearches[index].suggestions.length > 0 && <div className="tj-suggestions-dropdown">{legFromSearches[index].suggestions.map((loc, idx) => <div key={idx} className="tj-suggestion-item" onMouseDown={(e) => e.preventDefault()} onClick={() => selectMultiCityAirport(index, "from", loc)}><div className="tj-suggestion-main"><span className="tj-suggestion-iata">{loc.iata}</span><span className="tj-suggestion-name">{loc.name}</span></div><div className="tj-suggestion-city">{loc.city}, {loc.country}</div></div>)}</div>}
                  </div>

                  <div className="tj-swap-btn me-2" onClick={() => {
                    const fromText = legFromSearches[index].query;
                    const toText = legToSearches[index].query;
                    const fromIata = multiCityLegs[index].fromCode;
                    const toIata = multiCityLegs[index].toCode;
                    legFromSearches[index].setQuery(toText);
                    legToSearches[index].setQuery(fromText);
                    updateMultiCityLeg(index, "from", toText);
                    updateMultiCityLeg(index, "to", fromText);
                    updateMultiCityLeg(index, "fromCode", toIata);
                    updateMultiCityLeg(index, "toCode", fromIata);
                  }}><IoIosSwap /></div>

                  <div className="tj-field-group tj-to-field">
                    <MdFlightLand className="tj-field-icon" size={18} />
                    <div className="tj-field-content">
                      <div className="tj-field-label">To</div>
                      <input className="tj-field-input" placeholder="Where to?" value={legToSearches[index].query} onChange={(e) => { legToSearches[index].setQuery(e.target.value); updateMultiCityLeg(index, "toCode", ""); updateMultiCityLeg(index, "to", e.target.value); }} onBlur={() => setTimeout(() => legToSearches[index].setSuggestions([]), 300)} />
                      <div className="tj-field-sublabel">{leg.toCode || "City / Airport"}</div>
                    </div>
                    {legToSearches[index].suggestions.length > 0 && <div className="tj-suggestions-dropdown">{legToSearches[index].suggestions.map((loc, idx) => <div key={idx} className="tj-suggestion-item" onMouseDown={(e) => e.preventDefault()} onClick={() => selectMultiCityAirport(index, "to", loc)}><div className="tj-suggestion-main"><span className="tj-suggestion-iata">{loc.iata}</span><span className="tj-suggestion-name">{loc.name}</span></div><div className="tj-suggestion-city">{loc.city}, {loc.country}</div></div>)}</div>}
                  </div>

                  <div className="tj-field-group tj-date-field">
                    <Calendar className="tj-field-icon" size={18} />
                    <div className="tj-field-content">
                      <div className="tj-field-label">Depart</div>
                      <DatePicker
                        selected={parseDateValue(leg.date)}
                        onChange={(date) => updateMultiCityLeg(index, "date", formatDateValue(date))}
                        className="tj-field-input tj-date-picker"
                        dateFormat="dd-MM-yyyy"
                        minDate={
                          index > 0 && multiCityLegs[index - 1]?.date
                            ? parseDateValue(multiCityLegs[index - 1].date)
                            : new Date()
                        }
                        placeholderText="dd-mm-yyyy"
                      />
                      <div className="tj-field-sublabel">Travel Date</div>
                    </div>
                  </div>

                  {index === 0 && (
                    <>
                      <div className="tj-field-group tj-pax-field" onClick={() => setShowTravelersDropdown(!showTravelersDropdown)}>
                        <Users className="tj-field-icon" size={18} />
                        <div className="tj-field-content">
                          <div className="tj-field-label">Passengers & Class</div>
                          <div className="tj-field-input">{totalPax} Passenger{totalPax > 1 ? "s" : ""}</div>
                          <div className="tj-field-sublabel">{cabinClass}</div>
                        </div>
                        {showTravelersDropdown && renderTravelersDropdown()}
                      </div>
                      <button className="tj-search-btn" onClick={handleSearchFlights} disabled={loading}>{loading ? "Searching..." : "Search"}</button>
                    </>
                  )}
                </div>

                {/* Add/Remove Buttons - Outside search row but inside map */}
                {index === 1 && multiCityLegs.length < 5 && (
                  <div className="mt-3 text-center">
                    <button className="tj-add-route-btn border mb-2" type="button" onClick={addMultiCityLeg}>
                      + ADD ANOTHER CITY
                    </button>
                  </div>
                )}
                {index > 1 && (
                  <div className="mt-3 text-center">
                    <button className="tj-remove-route-btn" type="button" onClick={() => removeMultiCityLeg(index)}>
                      REMOVE
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="tj-search-row">
            <div className="tj-field-group tj-from-field">
              <MdFlightTakeoff className="tj-field-icon" size={18} />
              <div className="tj-field-content">
                <div className="tj-field-label">From</div>
                <input className="tj-field-input" placeholder="Where from?" value={fromSearch.query} onChange={(e) => { fromSearch.setQuery(e.target.value); setFromCode(""); }} onBlur={() => setTimeout(() => fromSearch.setSuggestions([]), 300)} />
                <div className="tj-field-sublabel">{fromCode || "City / Airport"}</div>
              </div>
              {fromSearch.suggestions.length > 0 && <div className="tj-suggestions-dropdown">{fromSearch.suggestions.map((loc, idx) => <div key={idx} className="tj-suggestion-item" onMouseDown={(e) => e.preventDefault()} onClick={() => { setFromCode(loc.iata); fromSearch.setQuery(`${loc.city} (${loc.iata})`); fromSearch.setSuggestions([]); }}><div className="tj-suggestion-main"><span className="tj-suggestion-iata">{loc.iata}</span><span className="tj-suggestion-name">{loc.name}</span></div><div className="tj-suggestion-city">{loc.city}, {loc.country}</div></div>)}</div>}
            </div>

            <div className="tj-swap-btn me-2" onClick={() => { const a = fromCode; const b = toCode; const qa = fromSearch.query; const qb = toSearch.query; setFromCode(b); setToCode(a); fromSearch.setQuery(qb); toSearch.setQuery(qa); }}><IoIosSwap /></div> 
            <div className="tj-field-group tj-to-field">
              <MdFlightLand className="tj-field-icon" size={18} />
              <div className="tj-field-content">
                <div className="tj-field-label">To</div>
                <input className="tj-field-input" placeholder="Where to?" value={toSearch.query} onChange={(e) => { toSearch.setQuery(e.target.value); setToCode(""); }} onBlur={() => setTimeout(() => toSearch.setSuggestions([]), 300)} />
                <div className="tj-field-sublabel">{toCode || "City / Airport"}</div>
              </div>
              {toSearch.suggestions.length > 0 && <div className="tj-suggestions-dropdown">{toSearch.suggestions.map((loc, idx) => <div key={idx} className="tj-suggestion-item" onMouseDown={(e) => e.preventDefault()} onClick={() => { setToCode(loc.iata); toSearch.setQuery(`${loc.city} (${loc.iata})`); toSearch.setSuggestions([]); }}><div className="tj-suggestion-main"><span className="tj-suggestion-iata">{loc.iata}</span><span className="tj-suggestion-name">{loc.name}</span></div><div className="tj-suggestion-city">{loc.city}, {loc.country}</div></div>)}</div>}
            </div>

            <div className="tj-field-group tj-date-field">
              <Calendar className="tj-field-icon" size={18} />
              <div className="tj-field-content">
                <div className="tj-field-label">Departure</div>
                <DatePicker selected={parseDateValue(departureDate)} onChange={(date) => setDepartureDate(formatDateValue(date))} className="tj-field-input tj-date-picker" dateFormat="dd-MM-yyyy" minDate={new Date()} placeholderText="dd-mm-yyyy" />
                <div className="tj-field-sublabel">Depart</div>
              </div>
            </div>

            {tripType === "round" && (
              <div className="tj-field-group tj-date-field">
                <Calendar className="tj-field-icon" size={18} />
                <div className="tj-field-content">
                  <div className="tj-field-label">Return</div>
                  <DatePicker selected={parseDateValue(returnDate)} onChange={(date) => setReturnDate(formatDateValue(date))} className="tj-field-input tj-date-picker" dateFormat="dd-MM-yyyy" minDate={parseDateValue(departureDate) || new Date()} placeholderText="dd-mm-yyyy" />
                  <div className="tj-field-sublabel">Return</div>
                </div>
              </div>
            )}

            <div className="tj-field-group tj-pax-field" onClick={() => setShowTravelersDropdown(!showTravelersDropdown)}>
              <Users className="tj-field-icon" size={18} />
              <div className="tj-field-content">
                <div className="tj-field-label">Passengers & Class</div>
                <div className="tj-field-input">{totalPax} Passenger{totalPax > 1 ? "s" : ""}</div>
                <div className="tj-field-sublabel">{cabinClass}</div>
              </div>
              {showTravelersDropdown && renderTravelersDropdown()}
            </div>
            <button className="tj-search-btn" onClick={handleSearchFlights} disabled={loading}>{loading ? "Searching..." : "Search"}</button>
          </div>
        )}

        <div className="tj-options-row">
          <PreferredAirline 
            value={preferredAirline} 
            onChange={setPreferredAirline} 
          />
          
          <FareTypeFilter 
            value={paxType} 
            onChange={setPaxType} 
          />
          
          <AdditionalFilters
            directFlight={directFlight}
            onDirectFlightChange={setDirectFlight}
          />
        </div>
      </div>
    </div>
  );
}
