import { useState, useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { FiEdit2 } from "react-icons/fi";
import FlightFiltersSidebar from "./FlightFiltersSidebar";
import FlightSearchForm from "./components/FlightSearchForm";
import FlightSearchHeader from "./components/FlightSearchHeader";
import { reviewFlight, getFareRule } from "../../../../services/api/flightApi";

// ─── Fare Rule display ───────────────────────────────────────────────────────
const policyLabel = (type) => ({ CANCELLATION: "Cancellation", DATECHANGE: "Date Change", NO_SHOW: "No Show", SEAT_CHARGEABLE: "Seat" }[type] || type);
const timeLabel = (policy) => {
  if (policy.pp) return policy.pp.replace(/_/g, " ");
  if (policy.et != null && policy.st != null) return `${policy.st}h – ${policy.et}h before departure`;
  return "As per policy";
};
function FareRuleDisplay({ data }) {
  if (!data) return null;
  const rule = data.farerule || {};
  const routes = Object.keys(rule);
  if (!routes.length) return <p className="text-muted small">No fare rules available.</p>;
  return (
    <div className="fare-rule-content">
      {routes.map((route) => {
        const routeRule = rule[route];
        const { tfr, miscInfo } = routeRule;
        return (
          <div key={route} className="mb-3">
            <div className="fw-semibold fs-13 mb-2">{route.replace("-", " → ")}</div>
            {miscInfo?.length ? (
              <pre className="fare-rule-plain">{miscInfo.join("\n")}</pre>
            ) : tfr ? (
              Object.keys(tfr).map((type) => {
                const policies = Array.isArray(tfr[type]) ? tfr[type] : [tfr[type]];
                return (
                  <div key={type} className="fare-rule-section mb-2">
                    <div className="fare-rule-type-label">{policyLabel(type)}</div>
                    {policies.map((p, i) => (
                      <div key={i} className="fare-rule-row">
                        <span className="fare-rule-time">{timeLabel(p)}</span>
                        <span className="fare-rule-fee">
                          Airline: ₹{Number(p.amount || 0).toLocaleString("en-IN")}
                          {p.additionalFee ? ` + ₹${Number(p.additionalFee).toLocaleString("en-IN")} platform fee` : ""}
                        </span>
                        {p.policyInfo && <span className="fare-rule-info">{p.policyInfo}</span>}
                      </div>
                    ))}
                  </div>
                );
              })
            ) : (
              <p className="text-muted small">Contact support for fare rules.</p>
            )}
          </div>
        );
      })}
    </div>
  );
}

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

const getPrice = (trip) => {
  const fare = trip?.totalPriceList?.[0]?.fd?.ADULT;
  return fare?.fC?.TF || fare?.fC?.NF || 0;
};
const formatPrice = (p) =>
  `₹${Number(p).toLocaleString("en-IN", { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;
const getTime = (dtStr) => {
  if (!dtStr) return "--:--";
  const d = new Date(dtStr);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
};
const getDateLabel = (dtStr) =>
  dtStr
    ? new Date(dtStr).toLocaleDateString("en-IN", {
        day: "numeric",
        month: "short",
      })
    : "";
const formatDuration = (mins) =>
  mins ? `${Math.floor(mins / 60)}h ${mins % 60}m` : "";
const getTripDuration = (trip) => {
  if (trip.totalDuration) return formatDuration(trip.totalDuration);
  return formatDuration(
    trip.sI?.reduce((acc, s) => acc + (s.duration || 0), 0) || 0,
  );
};
const getStopsText = (trip) => {
  const stops = (trip.sI?.length || 1) - 1;
  if (stops === 0) return "Non-Stop";
  if (stops === 1) return "1 Stop";
  return `${stops} Stops`;
};
const getFareLabel = (fareIdentifier) => {
  const map = {
    PUBLISHED: "Published",
    SPECIAL_RETURN: "Special Return",
    SME: "SME",
    PROMO: "Promo",
    CORPORATE: "Corporate",
    FLEXI: "Flexi",
  };
  return map[fareIdentifier] || fareIdentifier || "Published";
};
const getFareBadgeClass = (fareIdentifier) => {
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
const getFarePrice = (fareOption) =>
  fareOption?.fd?.ADULT?.fC?.TF || fareOption?.fd?.ADULT?.fC?.NF || 0;
const isFareRefundable = (fareOption) =>
  fareOption?.fd?.ADULT?.rT === 1 ? "Refundable" : "Non-Refundable";
const getFareCabin = (fareOption) => fareOption?.fd?.ADULT?.cc || "Economy";

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
  const [filters, setFilters] = useState({
    stops: [],
    airlines: [],
    departure_time: [],
    arrival_time: [],
    departure_return_time: [],
    arrival_return_time: [],
    baggage: [],
    price_min: null,
    price_max: null,
  });
  const [filtersMeta, setFiltersMeta] = useState(null);
  const [expandedFares, setExpandedFares] = useState({});
  const [selectedFareByFlight, setSelectedFareByFlight] = useState({});
  const [modifyOpen, setModifyOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const [showDetails, setShowDetails] = useState({});
  const [activeTab, setActiveTab] = useState({});
  const [fareRuleData, setFareRuleData] = useState({});
  const [fareRuleLoading, setFareRuleLoading] = useState({});
  const [logoLoadError, setLogoLoadError] = useState({});

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
    setOutboundFlights(onward);
    setReturnFlights(ret);
    setFilteredOutbound(onward);
    setFilteredReturn(ret);
  }, [searchParams, initialResults, navigate]);

  const getFlightKey = (flight) => {
    const first = flight.sI[0];
    const last = flight.sI[flight.sI.length - 1];
    const fareId = flight?.totalPriceList?.[0]?.id || "fare0";
    return `${first.fD.aI.code}${first.fD.fN}-${first.da.code}-${last.aa.code}-${first.dt}-${fareId}`;
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
        if (sortBy === "price") return getPrice(a) - getPrice(b);
        if (sortBy === "duration")
          return (
            (a.sI || []).reduce((s, seg) => s + (seg.duration || 0), 0) -
            (b.sI || []).reduce((s, seg) => s + (seg.duration || 0), 0)
          );
        if (sortBy === "departure")
          return new Date(a.sI[0].dt) - new Date(b.sI[0].dt);
        if (sortBy === "arrival")
          return (
            new Date(a.sI[a.sI.length - 1].at) -
            new Date(b.sI[b.sI.length - 1].at)
          );
        return 0;
      });
    setFilteredOutbound(sortList(outboundFlights, sortOutbound));
    setFilteredReturn(sortList(returnFlights, sortReturn));
  }, [outboundFlights, returnFlights, sortOutbound, sortReturn, filters]);

  const selectFlight = (flight, type) => {
    if (type === "outbound")
      setSelectedOutbound(selectedOutbound?.id === flight.id ? null : flight);
    else setSelectedReturn(selectedReturn?.id === flight.id ? null : flight);
  };

  const handleBook = async () => {
    if (!selectedOutbound) return alert("Please select an outbound flight");
    if (searchParams.tripType === "round" && !selectedReturn)
      return alert("Please select a return flight");
    const priceIds = [];
    const outboundFare = getSelectedFareOption(selectedOutbound);
    const returnFare = getSelectedFareOption(selectedReturn);
    if (outboundFare?.id) priceIds.push(outboundFare.id);
    if (returnFare?.id) priceIds.push(returnFare.id);
    if (priceIds.length === 0)
      return alert("Unable to get flight pricing information");
    setLoading(true);
    try {
      const reviewResponse = await reviewFlight(priceIds);
      if (!reviewResponse?.status?.success)
        return alert(
          reviewResponse?.status?.message || "Failed to validate flight prices",
        );
      navigate("/honeymoon/flights/book", {
        state: {
          outbound: selectedOutbound,
          return: selectedReturn,
          searchParams,
          reviewData: reviewResponse,
          bookingId: reviewResponse?.bookingId,
        },
      });
    } catch (e) {
      alert("Failed to proceed with booking. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const renderFlight = (flight, type, listIndex = 0) => {
    const first = flight.sI[0];
    const last = flight.sI[flight.sI.length - 1];
    const airline = first.fD.aI;
    const flightId = `${type}-${listIndex}-${flight.id || getFlightKey(flight)}`;
    const fares = flight.totalPriceList || [];
    const expanded = expandedFares[flightId];
    const visibleFares = expanded ? fares : fares.slice(0, 2);
    const selectedFareIndex = getSelectedFareIndex(flightId);
    const isSelected =
      type === "outbound"
        ? selectedOutbound?.id === flight.id
        : selectedReturn?.id === flight.id;
    const currentTab = activeTab[flightId] || "flight";
    const isDetailsOpen = showDetails[flightId] || false;

    return (
      <div
        key={flightId}
        className={`flight-card ${isSelected ? "flight-card-selected" : ""}`}
      >
        <div
          className="flight-card-main"
          onClick={() => selectFlight({ ...flight, id: flightId }, type)}
        >
          <div className="fc-airline">
            {!logoLoadError[flightId] && (
              <img
                src={`https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`}
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
          <div className="fc-route">
            <div className="fc-point">
              <div className="fc-iata">{first.da.code}</div>
              <div className="fc-time">{getTime(first.dt)}</div>
              <div className="fc-date">{getDateLabel(first.dt)}</div>
            </div>
            <div className="fc-middle">
              <div className="fc-duration">{getTripDuration(flight)}</div>
              <div className="fc-line" />
              <div
                className={`fc-stops-badge ${getStopsText(flight) === "Non-Stop" ? "" : "has-stops"}`}
              >
                {getStopsText(flight)}
              </div>
            </div>
            <div className="fc-point">
              <div className="fc-iata">{last.aa.code}</div>
              <div className="fc-time">{getTime(last.at)}</div>
              <div className="fc-date">{getDateLabel(last.at)}</div>
            </div>
          </div>
          <div className="fc-fares">
            {visibleFares.map((fare, idx) => {
              const realIdx = fares.findIndex((f) => f === fare);
              const fareIdx = realIdx === -1 ? idx : realIdx;
              return (
                <div
                  key={`${flightId}-${idx}`}
                  className={`fare-row ${selectedFareIndex === fareIdx ? "fare-row-selected" : ""}`}
                  onClick={(e) => {
                    e.stopPropagation();
                    setSelectedFareByFlight((p) => ({
                      ...p,
                      [flightId]: fareIdx,
                    }));
                    selectFlight({ ...flight, id: flightId }, type);
                  }}
                >
                  <span className="fare-bullet">
                    {selectedFareIndex === fareIdx ? "●" : "○"}
                  </span>
                  <span className="fare-price">
                    {formatPrice(getFarePrice(fare))}
                  </span>
                  <FiEdit2 size={11} className="fare-edit-icon" />
                  <span className={getFareBadgeClass(fare?.fareIdentifier)}>
                    {getFareLabel(fare?.fareIdentifier)}
                  </span>
                  <span className="fare-cabin-text">
                    {getFareCabin(fare)}, {isFareRefundable(fare)}
                  </span>
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
        </div>
        <div className="flight-card-footer">
          <button
            className="view-details-btn"
            onClick={(e) => {
              e.stopPropagation();
              setShowDetails((p) => ({ ...p, [flightId]: !p[flightId] }));
              if (!showDetails[flightId])
                setActiveTab((p) => ({ ...p, [flightId]: "flight" }));
            }}
          >
            {isDetailsOpen ? "Hide Details -" : "View Details +"}
          </button>
          <div className="seats-left">
            Seats left: {flight.totalPriceList[0]?.fd?.ADULT?.sR || 9}
          </div>
        </div>
        {isDetailsOpen && (
          <div className="tj-flight-details-panel">
            <div className="tj-details-tabs">
              <div
                className={`tj-details-tab ${currentTab === "flight" ? "active" : ""}`}
                onClick={() => setActiveTab((p) => ({ ...p, [flightId]: "flight" }))}
              >
                Flight Details
              </div>
              <div
                className={`tj-details-tab ${currentTab === "farerule" ? "active" : ""}`}
                onClick={async () => {
                  setActiveTab((p) => ({ ...p, [flightId]: "farerule" }));
                  if (!fareRuleData[flightId]) {
                    const fareId = fares[selectedFareIndex]?.id || fares[0]?.id;
                    if (!fareId) return;
                    setFareRuleLoading((p) => ({ ...p, [flightId]: true }));
                    try {
                      const data = await getFareRule(fareId, "SEARCH");
                      setFareRuleData((p) => ({ ...p, [flightId]: data }));
                    } catch {
                      setFareRuleData((p) => ({ ...p, [flightId]: null }));
                    } finally {
                      setFareRuleLoading((p) => ({ ...p, [flightId]: false }));
                    }
                  }
                }}
              >
                Fare Rules
              </div>
            </div>
            {currentTab === "farerule" && (
              <div className="tj-details-body p-3">
                {fareRuleLoading[flightId] ? (
                  <div className="text-center py-3">
                    <span className="spinner-border spinner-border-sm me-2" />
                    Loading fare rules…
                  </div>
                ) : fareRuleData[flightId] === null ? (
                  <p className="text-muted small">Fare rules unavailable. Please contact support.</p>
                ) : (
                  <FareRuleDisplay data={fareRuleData[flightId]} />
                )}
              </div>
            )}
          </div>
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
  const totalPrice =
    getFarePrice(getSelectedFareOption(selectedOutbound)) +
    getFarePrice(getSelectedFareOption(selectedReturn));

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
              filtersMeta={filtersMeta}
              filters={filters}
              onFilterChange={(k, v) => setFilters((p) => ({ ...p, [k]: v }))}
              onClearFilters={() =>
                setFilters({
                  stops: [],
                  airlines: [],
                  departure_time: [],
                  arrival_time: [],
                  departure_return_time: [],
                  arrival_return_time: [],
                  baggage: [],
                  price_min: null,
                  price_max: null,
                })
              }
              searchParams={searchParams}
            />
          </div>
          <div className="col-lg-9">
            <div className="row">
              <div className={isRoundTrip ? "col-lg-6" : "col-12"}>
                <div className="tj-flights-column">
                  <div className="tj-sort-tabs">
                    {["duration", "departure", "arrival", "price"].map(
                      (sort) => (
                        <div
                          key={sort}
                          className={`tj-sort-tab ${sortOutbound === sort ? "active" : ""}`}
                          onClick={() => setSortOutbound(sort)}
                        >
                          {sort}
                        </div>
                      ),
                    )}
                  </div>
                  <div className="flight-list">
                    {loading ? (
                      [1, 2, 3, 4].map((i) => <ShimmerCard key={i} />)
                    ) : visibleOut.length === 0 ? (
                      <div className="no-results">No flights found</div>
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
                    <div className="tj-sort-tabs">
                      {["duration", "departure", "arrival", "price"].map(
                        (sort) => (
                          <div
                            key={sort}
                            className={`tj-sort-tab ${sortReturn === sort ? "active" : ""}`}
                            onClick={() => setSortReturn(sort)}
                          >
                            {sort}
                          </div>
                        ),
                      )}
                    </div>
                    <div className="flight-list">
                      {loading ? (
                        [1, 2, 3, 4].map((i) => <ShimmerCard key={i} />)
                      ) : visibleRet.length === 0 ? (
                        <div className="no-results">No flights found</div>
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
