import { useState, useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { FiEdit2, FiBriefcase } from "react-icons/fi";
import { MdFlight } from "react-icons/md";
import "./tripjack-styles.css";
import FlightFiltersSidebar from "./FlightFiltersSidebar";
import FlightSearchForm from "./components/FlightSearchForm";
import FlightSearchHeader from "./components/FlightSearchHeader";
import FareDateStrip from "./components/FareDateStrip";
import ShareBy from "./components/ShareBy";
import FareCompare from "./components/FareCompare";
import FlightDetailsPanel from "./components/FlightDetailsPanel";
import { reviewFlight, searchFlights } from "../../../../services/api/flightApi";
import { formatDate } from "../../../../utils/dateFormat";
import {
  getTripDurationMinutes,
  buildTripJackSearchQuery,
} from "../../../../utils/flightSearchUtils";
import {
  isNdcFare,
  deriveFacets,
  filterTrips,
  applyFilterChange,
  clearFilterKey,
  removeFilterChip,
  reconcileFilters,
  countActiveFilters,
  paxFromSearch,
  farePrice,
  EMPTY_FILTERS,
} from "../../../../utils/flightFilters";
import { airlineLogo } from '../../../../utils/airlineLogo';

const useVirtualList = (items, pageSize = 15) => {
  const [visibleCount, setVisibleCount] = useState(pageSize);
  const loaderRef = useRef(null);
  useEffect(() => {
    setVisibleCount(pageSize);
  }, [items, pageSize]);
  useEffect(() => {
    if (!loaderRef.current) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting)
          setVisibleCount((prev) => Math.min(prev + pageSize, items.length));
      },
      { threshold: 0.1 },
    );
    observer.observe(loaderRef.current);
    return () => observer.disconnect();
  }, [items.length, pageSize]);
  return {
    visibleItems: items.slice(0, visibleCount),
    loaderRef,
    hasMore: visibleCount < items.length,
  };
};

const getPrice = (trip, pax) => farePrice(trip?.totalPriceList?.[0], pax);
const formatPrice = (p) =>
  `₹${Number(p).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const getTime = (dtStr) => {
  if (!dtStr) return "--:--";
  const d = new Date(dtStr);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
};
// "Aug 27" — the compact form the portal uses on cards.
const MONTHS_SHORT = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];
const getDateLabel = (dtStr) => {
  const d = new Date(dtStr);
  return Number.isNaN(d.getTime())
    ? formatDate(dtStr)
    : `${MONTHS_SHORT[d.getMonth()]} ${d.getDate()}`;
};
const formatDuration = (mins) =>
  mins ? `${Math.floor(mins / 60)}h ${mins % 60}m` : "";
const getTripDuration = (trip) => formatDuration(getTripDurationMinutes(trip));
const getStopsText = (trip) => {
  const stops = (trip.sI?.length || 1) - 1;
  if (stops === 0) return "Non-Stop";
  if (stops === 1) return "1 Stop";
  return `${stops} Stops`;
};
// TripJack ships ~74 distinct fareIdentifiers. NDC fares are prefixed "NDC_"
// (e.g. "NDC_Value", "NDC_Economy Flex Plus"); everything else is a plain name.
const titleCaseFare = (s) =>
  s
    .replace(/_/g, " ")
    .toLowerCase()
    .replace(/\b\w/g, (c) => c.toUpperCase());
const getFareLabel = (fareIdentifier) => {
  if (!fareIdentifier) return "Published";
  // Keep the NDC marker in the text — "NDC_Value" and the separate "VALUE"
  // fare would otherwise both render as "Value".
  if (isNdcFare(fareIdentifier)) {
    return `NDC ${titleCaseFare(fareIdentifier.replace(/^NDC_/i, ""))}`;
  }
  // Short all-caps acronyms (SME, FLX) read better left alone.
  if (/^[A-Z]{2,4}$/.test(fareIdentifier)) return fareIdentifier;
  return titleCaseFare(fareIdentifier);
};
const getFareBadgeClass = (fareIdentifier) => {
  if (isNdcFare(fareIdentifier)) return "fare-badge badge-ndc";
  const map = {
    PUBLISHED: "badge-published",
    SPECIAL_RETURN: "badge-special",
    SME: "badge-sme",
    PROMO: "badge-promo",
    CORPORATE: "badge-corporate",
    FLEXI: "badge-flexi",
  };
  return `fare-badge ${map[fareIdentifier] || "badge-published"}`;
};
const getFarePrice = (fareOption, pax) => farePrice(fareOption, pax);
const isFareRefundable = (fareOption) =>
  fareOption?.fd?.ADULT?.rT === 1 ? "Refundable" : "Non-Refundable";
const getFareCabin = (fareOption) => fareOption?.fd?.ADULT?.cc || "Economy";
// mI = meal included with this fare (TripJack sets it on ~1 in 3 fares).
const isMealIncluded = (fareOption) => fareOption?.fd?.ADULT?.mI === true;
// bI.iB = checked-in baggage allowance, bI.cB = cabin baggage.
const getCheckinBaggage = (fareOption) => fareOption?.fd?.ADULT?.bI?.iB || "";
const getCabinBaggage = (fareOption) => fareOption?.fd?.ADULT?.bI?.cB || "";
// Everything before the refundability word, which is rendered separately so
// "Non-Refundable" can be called out in red the way TripJack does.
const getFarePrefixText = (fareOption) =>
  [getFareCabin(fareOption), isMealIncluded(fareOption) && "Free Meal"]
    .filter(Boolean)
    .join(", ");
// fC.NF is the net (post-commission) fare; the incentive is what the agency
// earns on top of it. On an account with no commission configured NF === TF and
// the incentive reads 0.00 — which is exactly what the TripJack portal shows.
const getFareNet = (fareOption, pax) =>
  Object.entries(pax || {}).reduce((total, [type, count]) => {
    if (!count) return total;
    const fc = fareOption?.fd?.[type]?.fC;
    return total + Number(fc?.NF ?? fc?.TF ?? 0) * count;
  }, 0) || getFarePrice(fareOption, pax);
const getFareIncentive = (fareOption, pax) =>
  Math.max(0, getFarePrice(fareOption, pax) - getFareNet(fareOption, pax));
// iand = "is arrival next day" on a segment. Report how many calendar days the
// journey lands past its departure date so the traveller isn't caught out.
//
// Only valid for a single continuous journey. A COMBO/multi-city tripInfo holds
// legs that can sit weeks apart, where first-departure → last-arrival is not an
// overnight arrival at all — those return 0 and show nothing.
const getArrivalDayOffset = (trip) => {
  const segs = trip?.sI || [];
  if (!segs.length || !segs.some((s) => s.iand)) return 0;
  for (let i = 1; i < segs.length; i += 1) {
    const gapMs = new Date(segs[i].dt) - new Date(segs[i - 1].at);
    if (!Number.isFinite(gapMs) || gapMs > 86400000) return 0; // stopover, not a layover
  }
  const day = (v) => new Date(String(v).split("T")[0]).getTime();
  const diff = Math.round((day(segs[segs.length - 1].at) - day(segs[0].dt)) / 86400000);
  return Number.isFinite(diff) && diff > 0 ? diff : 0;
};

const SORT_LABELS = {
  duration: "Duration",
  departure: "Departure",
  arrival: "Arrival",
  price: "Price",
};

const ShimmerCard = () => <div className="shimmer-card" />;


export default function FlightSearchResults() {
  const location = useLocation();
  const navigate = useNavigate();
  const { searchParams, initialResults } = location.state || {};

  const [outboundFlights, setOutboundFlights] = useState([]);
  const [returnFlights, setReturnFlights] = useState([]);
  const [filteredOutbound, setFilteredOutbound] = useState([]);
  const [filteredReturn, setFilteredReturn] = useState([]);
  const [selectedOutbound, setSelectedOutbound] = useState(null);
  const [selectedReturn, setSelectedReturn] = useState(null);
  const [sortOutbound, setSortOutbound] = useState("price");
  const [sortReturn, setSortReturn] = useState("price");
  const [filters, setFilters] = useState(EMPTY_FILTERS);
  const [filtersMeta, setFiltersMeta] = useState(null);
  const [expandedFares, setExpandedFares] = useState({});
  const [selectedFareByFlight, setSelectedFareByFlight] = useState({});
  const [modifyOpen, setModifyOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [staleNotice, setStaleNotice] = useState('');
  const [showDetails, setShowDetails] = useState({});
  const [logoLoadError, setLogoLoadError] = useState({});
  const [compareOpen, setCompareOpen] = useState({});
  // "Show Incv" / "Show Net" price toggles, mirroring the TripJack sidebar.
  const [priceView, setPriceView] = useState({ incv: false, net: false });
  // Date currently being re-searched from the strip.
  const [pendingDate, setPendingDate] = useState(null);
  // Agent markup per fare id. TripJack still receives its own session fare —
  // the backend charges `price` via Razorpay and sends `paymentInfos.amount`
  // to TripJack separately — so a markup never breaks fare validation.
  const [markups, setMarkups] = useState({});
  const [markupOpen, setMarkupOpen] = useState(null);
  const [markupDraft, setMarkupDraft] = useState("");

  useEffect(() => {
    if (!searchParams || !initialResults) return navigate("/honeymoon");
    const directTrips = initialResults.direct?.searchResult?.tripInfos || {};
    const connectingTrips =
      initialResults.connecting?.searchResult?.tripInfos || {};
    const onward = [
      ...(directTrips.ONWARD || []),
      ...(connectingTrips.ONWARD || []),
    ];
    const ret = [
      ...(directTrips.RETURN || []),
      ...(connectingTrips.RETURN || []),
    ];
    const stamp = (list, bucket) =>
      list.map((trip, i) => ({ ...trip, _key: `${bucket}-${i}` }));
    const onwardKeyed = stamp(onward, "ONWARD");
    const returnKeyed = stamp(ret, "RETURN");
    setOutboundFlights(onwardKeyed);
    setReturnFlights(returnKeyed);
    setFilteredOutbound(onwardKeyed);
    setFilteredReturn(returnKeyed);
    const facetPax = paxFromSearch(searchParams);
    const outboundFacets = deriveFacets(onwardKeyed, facetPax);
    const returnFacets = deriveFacets(returnKeyed, facetPax);
    setFiltersMeta({ outbound: outboundFacets, return: returnFacets });
    // Filters persist across a date change, so drop any selection the new
    // results can no longer satisfy — otherwise the list silently empties.
    setFilters((prev) => reconcileFilters(prev, outboundFacets, returnFacets).filters);
  }, [searchParams, initialResults, navigate]);

  // `_key` is stamped once on load, so a card keeps its identity (and the
  // user's fare selection) across sorting and filtering.
  const pax = paxFromSearch(searchParams);
  const markupOf = (fare) => Number(markups[fare?.id] || 0);
  const displayFarePrice = (fare) => getFarePrice(fare, pax) + markupOf(fare);
  const displayTripPrice = (trip) => {
    const fare = trip?.totalPriceList?.[0];
    return fare ? displayFarePrice(fare) : 0;
  };

  const openMarkup = (fare) => {
    setMarkupOpen(fare.id);
    setMarkupDraft(String(markupOf(fare) || 0));
  };
  const closeMarkup = () => setMarkupOpen(null);
  const applyMarkup = (fare) => {
    setMarkups((p) => ({ ...p, [fare.id]: Number(markupDraft) || 0 }));
    closeMarkup();
  };
  /** Same markup across every fare on screen, as the portal's "Update All" does. */
  const applyMarkupToAll = () => {
    const value = Number(markupDraft) || 0;
    const next = {};
    for (const trip of [...outboundFlights, ...returnFlights]) {
      for (const fare of trip.totalPriceList || []) {
        if (fare?.id) next[fare.id] = value;
      }
    }
    setMarkups(next);
    closeMarkup();
  };

  const getFlightKey = (flight) => {
    if (flight?._key) return flight._key;
    const first = flight.sI[0];
    const last = flight.sI[flight.sI.length - 1];
    return `${first.fD.aI.code}${first.fD.fN}-${first.da.code}-${last.aa.code}-${first.dt}`;
  };
  const getSelectedFareIndex = (flightId) =>
    selectedFareByFlight[flightId] ?? 0;
  const getSelectedFareOption = (flight) => {
    if (!flight) return null;
    const flightId = flight.id || getFlightKey(flight);
    return (
      flight.totalPriceList?.[getSelectedFareIndex(flightId)] ||
      flight.totalPriceList?.[0] ||
      null
    );
  };

  useEffect(() => {
    const sortList = (list, sortBy) =>
      [...list].sort((a, b) => {
        if (sortBy === "price") return displayTripPrice(a) - displayTripPrice(b);
        if (sortBy === "duration")
          return getTripDurationMinutes(a) - getTripDurationMinutes(b);
        if (sortBy === "departure")
          return new Date(a.sI[0].dt) - new Date(b.sI[0].dt);
        if (sortBy === "arrival")
          return (
            new Date(a.sI[a.sI.length - 1].at) -
            new Date(b.sI[b.sI.length - 1].at)
          );
        return 0;
      });
    const from = searchParams?.from;
    const to = searchParams?.to;
    setFilteredOutbound(
      sortList(
        filterTrips(outboundFlights, filters, { searchFrom: from, searchTo: to, pax }),
        sortOutbound,
      ),
    );
    setFilteredReturn(
      sortList(
        filterTrips(returnFlights, filters, {
          isReturn: true,
          searchFrom: to,
          searchTo: from,
          pax,
        }),
        sortReturn,
      ),
    );
  }, [outboundFlights, returnFlights, sortOutbound, sortReturn, filters, searchParams, markups]);

  // Cheapest / fastest picks for the quick-select bar. Both read from the
  // filtered list so they always describe what is actually on screen.
  const pickBest = (list, score) =>
    list.reduce(
      (best, t) => (best === null || score(t) < score(best) ? t : best),
      null,
    );
  const cheapestOutbound = pickBest(filteredOutbound, displayTripPrice);
  const fastestOutbound = pickBest(filteredOutbound, getTripDurationMinutes);

  const selectFlight = (flight, type) => {
    if (type === "outbound") setSelectedOutbound(flight);
    else setSelectedReturn(flight);
  };

  /**
   * TripJack answers a review against a fare that has gone with errCode 1000,
   * "Requested flight is no longer available". The prices in the list are then
   * stale for the whole search, not just that fare, so the useful response is
   * to re-search rather than to leave the traveller on a dead error.
   */
  const isStaleFare = (payload) => {
    const errs = payload?.errors || payload?.status?.errors || [];
    if (errs.some((e) => String(e?.errCode) === "1000")) return true;
    const text = `${payload?.status?.message || ""} ${errs.map((e) => e?.message || "").join(" ")}`;
    return /no longer available|not available|price.*chang|expired/i.test(text);
  };

  const refreshStaleResults = async () => {
    setStaleNotice("These fares have expired. Refreshing prices…");
    setSelectedOutbound(null);
    setSelectedReturn(null);
    try {
      await rerunSearch({ ...searchParams });
      setStaleNotice("Prices were out of date, so the list has been refreshed. Please pick your flight again.");
    } catch {
      setStaleNotice("These fares have expired and prices could not be refreshed. Please search again.");
    }
  };

  // Review the chosen priceIds with TripJack, then hand off to the booking flow.
  const reviewAndGo = async (outbound, ret) => {
    const priceIds = [];
    const outboundFare = getSelectedFareOption(outbound);
    const returnFare = getSelectedFareOption(ret);
    if (outboundFare?.id) priceIds.push(outboundFare.id);
    if (returnFare?.id) priceIds.push(returnFare.id);
    if (priceIds.length === 0)
      return alert("Unable to get flight pricing information");
    setLoading(true);
    setStaleNotice("");
    try {
      const reviewResponse = await reviewFlight(priceIds);
      if (!reviewResponse?.status?.success) {
        if (isStaleFare(reviewResponse)) return refreshStaleResults();
        return alert(
          reviewResponse?.status?.message || "Failed to validate flight prices",
        );
      }
      navigate("/honeymoon/flights/book", {
        state: {
          outbound,
          return: ret,
          searchParams,
          reviewData: reviewResponse,
          bookingId: reviewResponse?.bookingId,
          priceIds,
          markup: markupOf(outboundFare) + markupOf(returnFare),
        },
      });
    } catch (e) {
      // A gone fare can arrive as a non-2xx rather than a body with success:false.
      if (isStaleFare(e?.response?.data)) return refreshStaleResults();
      alert("Failed to proceed with booking. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  /**
   * Re-run the search and replace the results in place, keeping filters and
   * scroll position. Used both by the date strip and by the stale-fare path,
   * so there is one copy of the query-building rather than two that drift.
   */
  const rerunSearch = async (nextParams) => {
    const base = buildTripJackSearchQuery(nextParams);
    const directQuery = {
      ...base,
      searchModifiers: { ...base.searchModifiers, isDirectFlight: true, isConnectingFlight: false },
    };
    const connectingQuery = {
      ...base,
      searchModifiers: { ...base.searchModifiers, isDirectFlight: false, isConnectingFlight: true },
    };
    const [d, c] = await Promise.allSettled([
      searchFlights(directQuery),
      searchFlights(connectingQuery),
    ]);
    navigate("/honeymoon/flights", {
      replace: true,
      state: {
        searchParams: nextParams,
        initialResults: {
          direct: d.status === "fulfilled" ? d.value : null,
          connecting: c.status === "fulfilled" ? c.value : null,
        },
      },
    });
  };

  // Picking a date on the strip re-runs the search for that day and replaces
  // the results in place, so the user keeps their filters and scroll position.
  const handlePickDate = async (dateKey) => {
    if (!searchParams?.from || !searchParams?.to) return;
    if (dateKey === searchParams.departureDate) return;
    setPendingDate(dateKey);
    setLoading(true);
    try {
      await rerunSearch({ ...searchParams, departureDate: dateKey });
    } catch {
      alert("Could not load fares for that date. Please try again.");
    } finally {
      setPendingDate(null);
      setLoading(false);
    }
  };

  const handleBook = async () => {
    if (!selectedOutbound) return alert("Please select an outbound flight");
    if (searchParams.tripType === "round" && !selectedReturn)
      return alert("Please select a return flight");
    return reviewAndGo(selectedOutbound, selectedReturn);
  };

  // BOOK straight from a card. On a one-way that goes to checkout immediately;
  // on a round trip the other leg is still required, so this selects the flight
  // and books only once both legs are chosen.
  const handleCardBook = async (flight, type) => {
    const picked = { ...flight };
    selectFlight(picked, type);
    if (searchParams.tripType !== "round") return reviewAndGo(picked, null);
    const outbound = type === "outbound" ? picked : selectedOutbound;
    const ret = type === "return" ? picked : selectedReturn;
    if (!outbound || !ret) {
      return alert(
        type === "outbound"
          ? "Outbound selected — now choose your return flight."
          : "Return selected — now choose your outbound flight.",
      );
    }
    return reviewAndGo(outbound, ret);
  };

  // Distinguish "nothing flies" from "your filters removed everything" — the
  // second is actionable and the old copy actively misled.
  const activeFilterCount = countActiveFilters(filters);
  const renderEmpty = (sourceCount) =>
    sourceCount > 0 && activeFilterCount > 0 ? (
      <div className="no-results">
        <div>No flights match your filters.</div>
        <button className="no-results-reset" onClick={() => setFilters(EMPTY_FILTERS)}>
          Clear {activeFilterCount} filter{activeFilterCount > 1 ? "s" : ""}
        </button>
      </div>
    ) : (
      <div className="no-results">No flights found</div>
    );

  const renderFlight = (flight, type, listIndex = 0) => {
    const first = flight.sI[0];
    const last = flight.sI[flight.sI.length - 1];
    const airline = first.fD.aI;
    const flightId = `${type}-${getFlightKey(flight)}`;
    const fares = flight.totalPriceList || [];
    const expanded = expandedFares[flightId];
    const visibleFares = expanded ? fares : fares.slice(0, 2);
    const selectedFareIndex = getSelectedFareIndex(flightId);
    const isSelected =
      type === "outbound"
        ? selectedOutbound?.id === flight.id
        : selectedReturn?.id === flight.id;
    const isDetailsOpen = showDetails[flightId] || false;
    const arrivalDayOffset = getArrivalDayOffset(flight);
    const seatsLeft = fares[selectedFareIndex]?.fd?.ADULT?.sR ?? fares[0]?.fd?.ADULT?.sR ?? null;

    return (
      <div
        key={flightId}
        className={`flight-card ${isSelected ? "flight-card-selected" : ""}`}
      >
        <div className="flight-card-main">
          <div className="fc-airline-col">
          <div className="fc-airline">
            {!logoLoadError[flightId] && (
              <img
                src={airlineLogo(airline.code)}
                alt={airline.name}
                className="fc-airline-logo"
                onError={() =>
                  setLogoLoadError((p) => ({ ...p, [flightId]: true }))
                }
              />
            )}
            {logoLoadError[flightId] && (
              <div className="fc-airline-initials">{airline.code}</div>
            )}
            <div>
              <div className="fc-airline-name">{airline.name}</div>
              <div className="fc-airline-num">
                {flight.sI.map((s) => `${s.fD.aI.code}-${s.fD.fN}`).join(", ")}
              </div>
            </div>
          </div>
          <div className="fc-airline-actions">
            <button
              className="view-details-btn"
              onClick={(e) => {
                e.stopPropagation();
                setShowDetails((p) => ({ ...p, [flightId]: !p[flightId] }));
              }}
            >
              {isDetailsOpen ? "Hide Details -" : "View Details +"}
            </button>
            {seatsLeft != null && (
              <div className={`seats-left ${seatsLeft <= 5 ? "is-low" : ""}`}>
                Seats left: {seatsLeft}
              </div>
            )}
          </div>
          </div>
          <div className="fc-route">
            <div className="fc-point">
              <div className="fc-iata">{first.da.code}</div>
              <div className="fc-time">{getTime(first.dt)}</div>
              <div className="fc-date">{getDateLabel(first.dt)}</div>
            </div>
            <div className="fc-middle">
              <div className="fc-stops-text">{getStopsText(flight)}</div>
              <div className="fc-arrow" />
              <div className="fc-duration">{getTripDuration(flight)}</div>
            </div>
            <div className="fc-point">
              <div className="fc-iata">{last.aa.code}</div>
              <div className="fc-time">{getTime(last.at)}</div>
              <div className="fc-date">{getDateLabel(last.at)}</div>
            </div>
          </div>
          <div className="fc-fares-row">
            <div className="fc-fares">
            {visibleFares.map((fare, idx) => {
              const realIdx = fares.findIndex((f) => f === fare);
              const fareIdx = realIdx === -1 ? idx : realIdx;
              return (
                <div
                  key={`${flightId}-${idx}`}
                  className={`fc-fare-option ${selectedFareIndex === fareIdx ? "fc-fare-option-selected" : ""}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedFareByFlight((p) => ({
                      ...p,
                      [flightId]: fareIdx,
                    }));
                  }}
                >
                  <div className="fc-fare-option-top">
                    <span className="fare-bullet">
                      {selectedFareIndex === fareIdx ? "●" : "○"}
                    </span>
                    <span className="fare-price">
                      {formatPrice(displayFarePrice(fare))}
                    </span>
                    {priceView.incv && (
                      <span className="fare-incv">
                        INC {formatPrice(getFareIncentive(fare, pax))}
                      </span>
                    )}
                    {priceView.net && (
                      <span className="fare-net">
                        NET {formatPrice(getFareNet(fare, pax))}
                      </span>
                    )}
                    <button
                      type="button"
                      className="fare-edit-btn"
                      title="Edit markup"
                      onClick={(e) => {
                        e.stopPropagation();
                        markupOpen === fare.id ? closeMarkup() : openMarkup(fare);
                      }}
                    >
                      <FiEdit2 size={11} />
                    </button>
                    {markupOf(fare) > 0 && (
                      <span className="fare-markup-tag">
                        +{formatPrice(markupOf(fare))}
                      </span>
                    )}
                    {markupOpen === fare.id && (
                      <div className="markup-box" onClick={(e) => e.stopPropagation()}>
                        <button
                          type="button"
                          className="markup-close"
                          onClick={closeMarkup}
                          aria-label="Close"
                        >
                          ×
                        </button>
                        <label className="markup-field">
                          <span>Markup Price</span>
                          <input
                            type="number"
                            autoFocus
                            value={markupDraft}
                            onChange={(e) => setMarkupDraft(e.target.value)}
                            onKeyDown={(e) => {
                              if (e.key === "Enter") applyMarkup(fare);
                              if (e.key === "Escape") closeMarkup();
                            }}
                          />
                        </label>
                        <div className="markup-actions">
                          <button type="button" onClick={() => applyMarkup(fare)}>
                            Update
                          </button>
                          <button type="button" onClick={applyMarkupToAll}>
                            Update All
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                  <div className="fc-fare-option-meta">
                    <span className={getFareBadgeClass(fare?.fareIdentifier)}>
                      {getFareLabel(fare?.fareIdentifier)}
                    </span>
                    {getCheckinBaggage(fare) && (
                      <span
                        className="fare-baggage-chip"
                        title={`Check-in ${getCheckinBaggage(fare)}${getCabinBaggage(fare) ? ` · Cabin ${getCabinBaggage(fare)}` : ""}`}
                      >
                        <FiBriefcase size={10} />
                        {getCheckinBaggage(fare)}
                      </span>
                    )}
                    <span className="fare-cabin-text">
                      {getFarePrefixText(fare)}
                      {getFarePrefixText(fare) && ", "}
                      <span
                        className={
                          isFareRefundable(fare) === "Refundable"
                            ? "fare-refundable"
                            : "fare-non-refundable"
                        }
                      >
                        {isFareRefundable(fare)}
                      </span>
                    </span>
                  </div>
                </div>
              );
            })}
            {fares.length > 2 && (
              <button
                className="more-fares-btn"
                onClick={(e) => {
                  e.stopPropagation();
                  setExpandedFares((p) => ({ ...p, [flightId]: !p[flightId] }));
                }}
              >
                {expanded ? "Show less ▲" : `+${fares.length - 2} more fares ▼`}
              </button>
            )}
          </div>
            <div className="fc-actions">
            <button
              className="fc-book-btn"
              disabled={loading}
              onClick={(e) => {
                e.stopPropagation();
                handleCardBook({ ...flight, id: flightId }, type);
              }}
            >
              {loading ? "…" : "BOOK"}
            </button>
            {fares.length > 1 && (
              <button
                className="fc-compare-btn"
                onClick={(e) => {
                  e.stopPropagation();
                  setCompareOpen((p) => ({ ...p, [flightId]: !p[flightId] }));
                }}
              >
                Compare {compareOpen[flightId] ? "▲" : "▼"}
              </button>
            )}
            </div>
          </div>
        </div>
        {compareOpen[flightId] && (
          <FareCompare
            pax={pax}
            fares={fares}
            selectedIndex={selectedFareIndex}
            onPick={(i) =>
              setSelectedFareByFlight((p) => ({ ...p, [flightId]: i }))
            }
            onBook={() => handleCardBook({ ...flight, id: flightId }, type)}
          />
        )}
        {arrivalDayOffset > 0 && (
          <div className="fc-next-day-notice">
            <MdFlight size={13} />
            Flight Arrives after {arrivalDayOffset} Day{arrivalDayOffset > 1 ? "s" : ""}
          </div>
        )}
        {isDetailsOpen && (
          <FlightDetailsPanel
            flight={flight}
            fare={fares[selectedFareIndex] || fares[0]}
            searchParams={searchParams}
            onClose={() => setShowDetails((p) => ({ ...p, [flightId]: false }))}
          />
        )}
      </div>
    );
  };

  const isRoundTrip = searchParams?.tripType === "round";
  const {
    visibleItems: visibleOut,
    loaderRef: loaderOutRef,
    hasMore: hasMoreOut,
  } = useVirtualList(filteredOutbound, 15);
  const {
    visibleItems: visibleRet,
    loaderRef: loaderRetRef,
    hasMore: hasMoreRet,
  } = useVirtualList(filteredReturn, 15);
  // Without `pax` this falls back to farePrice's single-adult default, which
  // is what made the bar read half the fare on a two-passenger search.
  const totalPrice =
    getFarePrice(getSelectedFareOption(selectedOutbound), pax) +
    getFarePrice(getSelectedFareOption(selectedReturn), pax);

  // The redirect above lives in an effect, and effects run after render — so
  // landing here without router state (a refresh, or Back onto a history entry
  // that carries none) reached the header with no searchParams and threw before
  // the redirect could fire. Bail out of the render instead; the effect still
  // performs the navigation. Placed after every hook, including the two
  // useVirtualList calls, so the hook order stays stable.
  if (!searchParams || !initialResults) return null;

  return (
    <div className="tj-results-page">
      <FlightSearchHeader
        searchParams={searchParams}
        onModify={() => setModifyOpen(!modifyOpen)}
      />
      {modifyOpen && (
        <div className="tj-modify-panel">
          <div className="container">
            <FlightSearchForm />
          </div>
        </div>
      )}
      <div className="container mt-4">
        <div className="row">
          <div className="col-lg-3">
            <FlightFiltersSidebar
              filtersMeta={filtersMeta?.outbound}
              returnFiltersMeta={filtersMeta?.return}
              resultCount={filteredOutbound.length + filteredReturn.length}
              filters={filters}
              onFilterChange={(k, v) => setFilters((p) => applyFilterChange(p, k, v))}
              onClearFilters={() => setFilters(EMPTY_FILTERS)}
              onClearSection={(key) => setFilters((p) => clearFilterKey(p, key))}
              onRemoveChip={(chip) => setFilters((p) => removeFilterChip(p, chip))}
              searchParams={searchParams}
              priceView={priceView}
              onPriceViewChange={(key, value) =>
                setPriceView((p) => ({ ...p, [key]: value }))
              }
            />
          </div>
          <div className="col-lg-9">
            <FareDateStrip
              searchParams={searchParams}
              onPickDate={handlePickDate}
              pendingDate={pendingDate}
            />
            <ShareBy
              searchParams={searchParams}
              resultCount={filteredOutbound.length + filteredReturn.length}
            />

            {staleNotice && (
              <div className="stale-notice" role="status">
                <span>{staleNotice}</span>
                <button type="button" onClick={() => setStaleNotice("")} aria-label="Dismiss">
                  &times;
                </button>
              </div>
            )}
            <div className="row">
              <div className={isRoundTrip ? "col-lg-6" : "col-12"}>
                <div className="tj-flights-column">
                  <div className="fc-quickpicks">
                    <button
                      className={`fc-quickpick ${sortOutbound === "price" ? "active" : ""}`}
                      onClick={() => setSortOutbound("price")}
                      disabled={!cheapestOutbound}
                    >
                      <span className="fc-quickpick-icon">₹</span>
                      <span>
                        <span className="fc-quickpick-title">Cheapest</span>
                        <span className="fc-quickpick-sub">
                          {cheapestOutbound
                            ? `${formatPrice(displayTripPrice(cheapestOutbound))} · ${getTripDuration(cheapestOutbound)}`
                            : "—"}
                        </span>
                      </span>
                    </button>
                    <button
                      className={`fc-quickpick ${sortOutbound === "duration" ? "active" : ""}`}
                      onClick={() => setSortOutbound("duration")}
                      disabled={!fastestOutbound}
                    >
                      <span className="fc-quickpick-icon">⚡</span>
                      <span>
                        <span className="fc-quickpick-title">Fastest</span>
                        <span className="fc-quickpick-sub">
                          {fastestOutbound
                            ? `${formatPrice(displayTripPrice(fastestOutbound))} · ${getTripDuration(fastestOutbound)}`
                            : "—"}
                        </span>
                      </span>
                    </button>
                  </div>
                  <div className="fc-col-headers">
                    <button
                      className="fc-col-head fc-col-sort"
                      onClick={() => setSortOutbound("duration")}
                      title="Sort by duration"
                    >
                      Sort By : {SORT_LABELS[sortOutbound] || "Duration"}
                    </button>
                    <button
                      className="fc-col-head"
                      onClick={() => setSortOutbound("departure")}
                    >
                      Departure
                    </button>
                    <button
                      className="fc-col-head"
                      onClick={() => setSortOutbound("arrival")}
                    >
                      Arrival
                    </button>
                    <button
                      className="fc-col-head"
                      onClick={() => setSortOutbound("price")}
                    >
                      Price
                    </button>
                  </div>
                  <div className="flight-list">
                    {loading ? (
                      [1, 2, 3, 4].map((i) => <ShimmerCard key={i} />)
                    ) : visibleOut.length === 0 ? (
                      renderEmpty(outboundFlights.length)
                    ) : (
                      <>
                        {visibleOut.map((trip, idx) =>
                          renderFlight(trip, "outbound", idx),
                        )}
                        {hasMoreOut && (
                          <div ref={loaderOutRef} className="load-more-trigger">
                            <ShimmerCard />
                          </div>
                        )}
                      </>
                    )}
                  </div>
                </div>
              </div>
              {isRoundTrip && (
                <div className="col-lg-6">
                  <div className="tj-flights-column">
                    <div className="fc-col-headers">
                      <button className="fc-col-head fc-col-sort"
                        onClick={() => setSortReturn("duration")} title="Sort by duration">
                        Sort By : {SORT_LABELS[sortReturn] || "Duration"}
                      </button>
                      <button className="fc-col-head" onClick={() => setSortReturn("departure")}>Departure</button>
                      <button className="fc-col-head" onClick={() => setSortReturn("arrival")}>Arrival</button>
                      <button className="fc-col-head" onClick={() => setSortReturn("price")}>Price</button>
                    </div>
                    <div className="flight-list">
                      {loading ? (
                        [1, 2, 3, 4].map((i) => <ShimmerCard key={i} />)
                      ) : visibleRet.length === 0 ? (
                        renderEmpty(returnFlights.length)
                      ) : (
                        <>
                          {visibleRet.map((trip, idx) =>
                            renderFlight(trip, "return", idx),
                          )}
                          {hasMoreRet && (
                            <div
                              ref={loaderRetRef}
                              className="load-more-trigger"
                            >
                              <ShimmerCard />
                            </div>
                          )}
                        </>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
      {(selectedOutbound || selectedReturn) && (
        <div className="tj-booking-bar">
          <div className="container-fluid">
            <div className="tj-booking-content">
              <div className="tj-booking-total">
                {formatPrice(totalPrice)} total
              </div>
              <button
                className="tj-book-btn"
                onClick={handleBook}
                disabled={loading}
              >
                {loading ? "Processing..." : "BOOK"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
