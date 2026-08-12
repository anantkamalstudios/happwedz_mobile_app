import { useState, useEffect } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import FlightFiltersSidebar from './FlightFiltersSidebar';
import FlightSearchHeader from './components/FlightSearchHeader';
import './tripjack-styles.css';

export default function MultiCityResults() {
  const location = useLocation();
  const navigate = useNavigate();
  
  const { searchParams, initialResults, searchQuery } = location.state || {};
  
  const [routeFlights, setRouteFlights] = useState({});
  const [filteredRouteFlights, setFilteredRouteFlights] = useState({});
  const [activeTab, setActiveTab] = useState(0);
  const [selectedFlightsPerRoute, setSelectedFlightsPerRoute] = useState({});
  const [showDetails, setShowDetails] = useState({});
  const [loading, setLoading] = useState(false);
  const [filters, setFilters] = useState({
    stops: [],
    airlines: [],
    departure_time: [],
    arrival_time: [],
    baggage: [],
    price_min: null,
    price_max: null,
  });
  const [filtersMeta, setFiltersMeta] = useState(null);

  useEffect(() => {
    const loadResults = async () => {
      if (!searchParams) {
        navigate('/honeymoon');
        return;
      }

      if (initialResults) {
        processResults(initialResults);
        return;
      }

      const fallbackRouteInfos = (searchParams?.legs || searchParams?.routes || []).map((leg) => ({
        fromCityOrAirport: { code: leg.fromCode },
        toCityOrAirport: { code: leg.toCode },
        travelDate: leg.date,
      }));

      const queryToUse = searchQuery || {
        cabinClass: (searchParams?.cabinClass || 'ECONOMY').toUpperCase(),
        paxInfo: { ADULT: searchParams?.adults || 1, CHILD: searchParams?.children || 0, INFANT: 0 },
        routeInfos: fallbackRouteInfos,
        searchModifiers: { isDirectFlight: false, isConnectingFlight: true },
      };

      if (!queryToUse?.routeInfos?.length) {
        setRouteFlights({});
        setFilteredRouteFlights({});
        return;
      }

      setLoading(true);
      try {
        const { searchFlights } = await import('../../../../services/api/flightApi');
        const result = await searchFlights(queryToUse);
        processResults(result);
      } catch (error) {
        console.error('Error loading multicity flights:', error);
        setRouteFlights({});
        setFilteredRouteFlights({});
      } finally {
        setLoading(false);
      }
    };

    loadResults();
  }, [searchParams, initialResults, searchQuery, navigate]);

  const processResults = (results) => {
    // Support both direct API payload and wrapped payload from the form
    const normalizedResults = results?.searchResult
      ? results
      : (results?.connecting?.searchResult ? results.connecting : null);
    const tripInfos = normalizedResults?.searchResult?.tripInfos || {};

    // TripJack returns multi-city results bucketed BY ROUTE:
    //  - Domestic  → numeric keys "0","1",… one bucket per route info (each an
    //    independent one-way with its own priceId). A flight may itself be
    //    connecting (multiple segments) — that's ONE flight for that route.
    //  - International → "COMBO": one combined itinerary (single priceId) covering
    //    all routes; selecting it books everything.
    const flightsByRoute = {};
    const mapItin = (it) => ({ ...it, id: it.totalPriceList?.[0]?.id || it.sI?.[0]?.id });

    const numericKeys = Object.keys(tripInfos).filter((k) => /^\d+$/.test(k));
    if (numericKeys.length) {
      numericKeys.forEach((k) => {
        flightsByRoute[Number(k)] = (tripInfos[k] || []).map(mapItin);
      });
    } else if (Array.isArray(tripInfos.COMBO)) {
      flightsByRoute[0] = tripInfos.COMBO.map((it) => ({ ...mapItin(it), _combo: true }));
    } else if (Array.isArray(tripInfos.ONWARD)) {
      flightsByRoute[0] = tripInfos.ONWARD.map(mapItin);
    }

    setRouteFlights(flightsByRoute);
    setFilteredRouteFlights(flightsByRoute);
    computeFiltersMeta(flightsByRoute);
  };

  const getRouteList = () => searchParams?.routes || searchParams?.legs || [];

  const computeFiltersMeta = (flightsByRoute) => {
    const allFlights = [];
    Object.values(flightsByRoute).forEach(flights => {
      allFlights.push(...flights);
    });
    
    const stopsMap = new Map();
    const airlinesMap = new Map();
    let minPrice = Infinity;
    let maxPrice = 0;

    allFlights.forEach(flight => {
      const stops = flight.sI.length - 1;
      const airline = flight.sI[0].fD.aI;
      const price = flight.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0;

      if (!stopsMap.has(stops)) {
        stopsMap.set(stops, { value: stops, count: 0, min_price: Infinity });
      }
      const stopData = stopsMap.get(stops);
      stopData.count++;
      stopData.min_price = Math.min(stopData.min_price, price);

      if (!airlinesMap.has(airline.code)) {
        airlinesMap.set(airline.code, {
          code: airline.code,
          name: airline.name,
          logo: `https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`,
          count: 0,
          min_price: Infinity,
        });
      }
      const airlineData = airlinesMap.get(airline.code);
      airlineData.count++;
      airlineData.min_price = Math.min(airlineData.min_price, price);

      minPrice = Math.min(minPrice, price);
      maxPrice = Math.max(maxPrice, price);
    });

    setFiltersMeta({
      stops: Array.from(stopsMap.values()),
      airlines: Array.from(airlinesMap.values()),
      price: { min: minPrice, max: maxPrice },
    });
  };

  useEffect(() => {
    applyFilters();
  }, [filters, routeFlights]);

  useEffect(() => {
    const current = filteredRouteFlights?.[activeTab] || [];
    if (current.length > 0) return;
    const firstNonEmpty = Object.keys(filteredRouteFlights).find((k) => (filteredRouteFlights[k] || []).length > 0);
    if (firstNonEmpty !== undefined) {
      setActiveTab(Number(firstNonEmpty));
    }
  }, [filteredRouteFlights, activeTab]);

  const applyFilters = () => {
    const filtered = {};
    Object.keys(routeFlights).forEach(routeIdx => {
      filtered[routeIdx] = filterFlights(routeFlights[routeIdx]);
    });
    setFilteredRouteFlights(filtered);
  };

  const filterFlights = (flights) => {
    return flights.filter(flight => {
      const stops = flight.sI.length - 1;
      const airline = flight.sI[0].fD.aI.code;
      const price = flight.totalPriceList[0]?.fd?.ADULT?.fC?.TF || 0;
      const depHour = parseInt(flight.sI[0].dt.split('T')[1].split(':')[0]);

      if (filters.stops.length > 0 && !filters.stops.includes(stops)) return false;
      if (filters.airlines.length > 0 && !filters.airlines.includes(airline)) return false;
      if (filters.price_min && price < filters.price_min) return false;
      if (filters.price_max && price > filters.price_max) return false;
      
      if (filters.departure_time.length > 0) {
        const inRange = filters.departure_time.some(range => {
          const [start, end] = range.split('-').map(Number);
          return depHour >= start && depHour < end;
        });
        if (!inRange) return false;
      }

      return true;
    });
  };

  const handleFilterChange = (filterType, value) => {
    setFilters(prev => {
      const newFilters = { ...prev };
      
      if (['stops', 'airlines', 'departure_time', 'arrival_time', 'baggage'].includes(filterType)) {
        if (newFilters[filterType].includes(value)) {
          newFilters[filterType] = newFilters[filterType].filter(v => v !== value);
        } else {
          newFilters[filterType] = [...newFilters[filterType], value];
        }
      } else {
        newFilters[filterType] = value;
      }
      
      return newFilters;
    });
  };

  const clearFilters = () => {
    setFilters({
      stops: [],
      airlines: [],
      departure_time: [],
      arrival_time: [],
      baggage: [],
      price_min: null,
      price_max: null,
    });
  };

  const formatTime = (dateStr) => {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  };

  const formatDate = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { day: '2-digit', month: 'short' });
  };

  const formatDateShort = (dateStr) => {
    const date = new Date(dateStr);
    return date.toLocaleDateString('en-US', { day: '2-digit', month: '2-digit', year: 'numeric' });
  };

  const formatDuration = (minutes) => {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return `${h}h ${m > 0 ? m + 'm' : ''}`;
  };

  const handleSelectFlight = (routeIndex, flight) => {
    const selectedId = selectedFlightsPerRoute[routeIndex]?.totalPriceList?.[0]?.id;
    const thisId = flight.totalPriceList?.[0]?.id;
    setSelectedFlightsPerRoute((prev) => {
      const next = { ...prev };
      if (selectedId === thisId) {
        delete next[routeIndex]; // clicking the selected flight deselects it
      } else {
        next[routeIndex] = flight; // one flight per route
      }
      return next;
    });
  };

  const getTotalPrice = () => {
    // Sum the selected flight per route, de-duping by priceId (COMBO shares one id).
    const seen = new Map();
    Object.values(selectedFlightsPerRoute).forEach((flight) => {
      const priceId = flight.totalPriceList?.[0]?.id;
      const price = flight.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || 0;
      if (priceId && !seen.has(priceId)) seen.set(priceId, price);
    });
    return Array.from(seen.values()).reduce((sum, p) => sum + p, 0);
  };

  const canBook = () => {
    const requiredRoutes = Object.keys(routeFlights).filter((k) => (routeFlights[k] || []).length > 0);
    return requiredRoutes.every((k) => !!selectedFlightsPerRoute[k]);
  };

  const handleBook = async () => {
    if (!canBook()) {
      alert('Please select flights for all routes');
      return;
    }

    // One priceId per route bucket, in route order. COMBO (intl) shares one
    // priceId across routes, so de-dupe.
    const routeKeys = Object.keys(routeFlights)
      .filter((k) => (routeFlights[k] || []).length > 0)
      .map(Number)
      .sort((a, b) => a - b);
    const priceIds = [];
    const seen = new Set();
    for (const k of routeKeys) {
      const priceId = selectedFlightsPerRoute[k]?.totalPriceList?.[0]?.id;
      if (priceId && !seen.has(priceId)) {
        seen.add(priceId);
        priceIds.push(priceId);
      }
    }

    if (!priceIds.length) {
      alert('Please select flights for all routes before booking.');
      return;
    }

    setLoading(true);
    try {
      const { reviewFlight } = await import('../../../../services/api/flightApi');
      // Send priceIds array matching the number of routes
      const reviewResponse = await reviewFlight(priceIds);
      
      if (!reviewResponse?.status?.success) {
        const errorMsg = reviewResponse?.errors?.[0]?.message || 
                        reviewResponse?.status?.message || 
                        'Failed to validate flight prices';
        alert(errorMsg);
        return;
      }

      // Get the full itinerary for navigation
      const firstSelectedFlight = Object.values(selectedFlightsPerRoute)[0];
      const fullItinerary = firstSelectedFlight?._fullItinerary || firstSelectedFlight;

      navigate('/honeymoon/flights/book', {
        state: {
          outbound: fullItinerary,
          multiCity: Object.values(selectedFlightsPerRoute),
          searchParams,
          reviewData: reviewResponse,
          bookingId: reviewResponse?.bookingId,
        },
      });
    } catch (error) {
      console.error('Error reviewing flight:', error);
      const errorMessage = error.response?.data?.errors?.[0]?.message || 
                          error.response?.data?.message || 
                          'Failed to proceed with booking. Please try again.';
      alert(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  const renderFlightCard = (flight, routeIndex) => {
    const firstSeg = flight.sI?.[0];
    const lastSeg = flight.sI?.[flight.sI.length - 1];
    if (!firstSeg) return null;

    const airline = firstSeg.fD.aI;
    // Whole-journey duration & stops (a flight for one route may be connecting).
    const duration = flight.sI.reduce((s, sg) => s + (sg.duration || 0), 0);
    const stops = flight.sI.length - 1;
    const price = flight.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || 0;
    const fareType = flight.totalPriceList?.[0]?.fareIdentifier || 'PUBLISHED';
    const cabinClass = flight.totalPriceList?.[0]?.fd?.ADULT?.cc || 'ECONOMY';

    // Check if this itinerary is selected (compare by priceId)
    const selectedPriceId = selectedFlightsPerRoute[routeIndex]?.totalPriceList?.[0]?.id;
    const thisPriceId = flight.totalPriceList?.[0]?.id;
    const isSelected = selectedPriceId === thisPriceId;

    const detailKey = `${routeIndex}-${flight.id || firstSeg.id}`;
    return (
      <div
        key={flight.id || Math.random()}
        className={`tj-flight-card ${isSelected ? 'selected' : ''}`}
        onClick={() => handleSelectFlight(routeIndex, flight)}
        style={{ cursor: 'pointer', marginBottom: '15px' }}
      >
        <div className="row align-items-center">
          {/* Airline Info */}
          <div className="col-md-2">
            <div className="d-flex align-items-center">
              <img
                src={`https://airhex.com/images/airline-logos/alt/${airline.code.toLowerCase()}.png`}
                alt={airline.name}
                style={{ width: '40px', height: '40px', marginRight: '10px', objectFit: 'contain' }}
                onError={(e) => { 
                  e.target.style.display = 'none';
                  if (e.target.nextSibling) e.target.nextSibling.style.display = 'flex';
                }}
              />
              <div style={{ width: '40px', height: '40px', marginRight: '10px', borderRadius: '6px', background: '#ed1173', color: '#fff', fontSize: '12px', fontWeight: '700', alignItems: 'center', justifyContent: 'center', display: 'none' }}>
                {airline.code}
              </div>
              <div>
                <div style={{ fontWeight: '600', fontSize: '14px' }}>{airline.name}</div>
                <div style={{ fontSize: '12px', color: '#666' }}>{airline.code}-{firstSeg.fD.fN}</div>
              </div>
            </div>
          </div>

          {/* Departure */}
          <div className="col-md-2 text-center">
            <div style={{ fontSize: '18px', fontWeight: '600' }}>{firstSeg.da.code}</div>
            <div style={{ fontSize: '16px', fontWeight: '700' }}>{formatTime(firstSeg.dt)}</div>
            <div style={{ fontSize: '12px', color: '#666' }}>{formatDate(firstSeg.dt)}</div>
          </div>

          {/* Duration & Stops */}
          <div className="col-md-2 text-center">
            <div style={{ fontSize: '12px', color: '#666' }}>{stops === 0 ? 'Non-Stop' : `${stops} Stop${stops > 1 ? 's' : ''}`}</div>
            <div style={{ fontSize: '14px', fontWeight: '500', margin: '5px 0' }}>{formatDuration(duration)}</div>
            <div style={{ height: '2px', background: '#ddd', margin: '5px 0' }}></div>
          </div>

          {/* Arrival */}
          <div className="col-md-2 text-center">
            <div style={{ fontSize: '18px', fontWeight: '600' }}>{lastSeg.aa.code}</div>
            <div style={{ fontSize: '16px', fontWeight: '700' }}>{formatTime(lastSeg.at)}</div>
            <div style={{ fontSize: '12px', color: '#666' }}>{formatDate(lastSeg.at)}</div>
          </div>

          {/* Price */}
          <div className="col-md-2 text-center">
            <div style={{ fontSize: '18px', fontWeight: '700', color: '#ff6b35' }}>
              ₹{Number(price).toLocaleString('en-IN')}
            </div>
            <div style={{ fontSize: '11px', color: '#666' }}>
              <span style={{ 
                background: fareType === 'PUBLISHED' ? '#4CAF50' : '#FF9800',
                color: 'white',
                padding: '2px 6px',
                borderRadius: '3px',
                fontSize: '10px'
              }}>
                {fareType}
              </span>
            </div>
            <div style={{ fontSize: '11px', color: '#666', marginTop: '2px' }}>
              {cabinClass}, Refundable
            </div>
          </div>

          {/* Action */}
          <div className="col-md-2 text-center">
            <button
              className="btn btn-sm"
              style={{
                background: isSelected ? '#4CAF50' : '#ff6b35',
                color: 'white',
                padding: '8px 20px',
                border: 'none',
                borderRadius: '4px',
                fontWeight: '600'
              }}
              onClick={(e) => {
                e.stopPropagation();
                handleSelectFlight(routeIndex, flight);
              }}
            >
              {isSelected ? 'DESELECT' : 'SELECT'}
            </button>
          </div>
        </div>
        {isSelected && (
          <div style={{
            background: '#e8f5e9',
            padding: '8px 15px',
            marginTop: '10px',
            borderRadius: '4px',
            fontSize: '12px',
            color: '#2e7d32',
            fontWeight: '500'
          }}>
            ✓ This flight is selected
          </div>
        )}
        <div className="d-flex justify-content-between align-items-center mt-2">
          <button
            className="view-details-btn"
            onClick={(e) => {
              e.stopPropagation();
              setShowDetails((prev) => ({ ...prev, [detailKey]: !prev[detailKey] }));
            }}
          >
            {showDetails[detailKey] ? 'Hide Details -' : 'View Details +'}
          </button>
          <div className="seats-left">Seats left: {flight.totalPriceList?.[0]?.fd?.ADULT?.sR || 0}</div>
        </div>
        {showDetails[detailKey] && (
          <div className="tj-flight-details-panel mt-2">
            {flight.sI?.map((seg, idx) => (
              <div key={`${detailKey}-${idx}`} className="tj-segment-detail">
                <div><strong>Flight:</strong> {seg.fD?.aI?.name} {seg.fD?.fN}</div>
                <div><strong>From:</strong> {seg.da?.city} ({seg.da?.code}) - {formatTime(seg.dt)}</div>
                <div><strong>To:</strong> {seg.aa?.city} ({seg.aa?.code}) - {formatTime(seg.at)}</div>
                <div><strong>Duration:</strong> {formatDuration(seg.duration)}</div>
              </div>
            ))}
          </div>
        )}
      </div>
    );
  };

  const getCheapestPrice = (routeIdx) => {
    const flights = filteredRouteFlights[routeIdx] || [];
    if (flights.length === 0) return 0;
    return Math.min(...flights.map(f => f.totalPriceList?.[0]?.fd?.ADULT?.fC?.TF || Infinity));
  };

  const getFastestDuration = (routeIdx) => {
    const flights = filteredRouteFlights[routeIdx] || [];
    if (flights.length === 0) return 0;
    return Math.min(...flights.map(f => f.sI?.[0]?.duration || Infinity));
  };

  return (
    <div className="tj-results-wrapper">
      <FlightSearchHeader searchParams={searchParams} />

      <div className="container mt-4">
        <div className="row">
          {/* Sidebar Filters */}
          <div className="col-lg-3">
            <FlightFiltersSidebar
              filtersMeta={filtersMeta}
              filters={filters}
              onFilterChange={handleFilterChange}
              onClearFilters={clearFilters}
              searchParams={{
                from: getRouteList()?.[activeTab]?.from || 'Origin',
                to: getRouteList()?.[activeTab]?.to || 'Destination',
                tripType: 'multi'
              }}
            />
          </div>

          {/* Main Content */}
          <div className="col-lg-9">
            {/* Route Tabs */}
            <div className="row mb-3">
              <div className="col-12">
                <div style={{ 
                  background: '#2c3e50', 
                  padding: '15px', 
                  borderRadius: '8px',
                  display: 'flex',
                  gap: '10px',
                  alignItems: 'center',
                  flexWrap: 'wrap'
                }}>
                  {getRouteList().map((route, idx) => {
                    const routeFlightsList = filteredRouteFlights[idx] || [];
                    const isActive = activeTab === idx;
                    const isSelected = !!selectedFlightsPerRoute[idx];
                    
                    return (
                      <div
                        key={idx}
                        onClick={() => setActiveTab(idx)}
                        style={{
                          background: isActive ? '#ff6b35' : isSelected ? '#4CAF50' : '#34495e',
                          color: 'white',
                          padding: '12px 20px',
                          borderRadius: '6px',
                          cursor: 'pointer',
                          flex: '1',
                          minWidth: '200px',
                          textAlign: 'center',
                          transition: 'all 0.3s',
                          border: isActive ? '2px solid #fff' : '2px solid transparent'
                        }}
                      >
                        <div style={{ fontSize: '16px', fontWeight: '600' }}>
                          {route.fromCode} → {route.toCode}
                        </div>
                        <div style={{ fontSize: '12px', marginTop: '4px' }}>
                          {route.from} → {route.to}
                        </div>
                        <div style={{ fontSize: '11px', marginTop: '4px', opacity: 0.9 }}>
                          {formatDateShort(route.date)}
                        </div>
                        {isSelected && (
                          <div style={{ fontSize: '10px', marginTop: '4px', fontWeight: '600' }}>
                            ✓ Flight Selected
                          </div>
                        )}
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Quick Stats */}
            <div className="row mb-3">
              <div className="col-12">
                <div style={{ 
                  background: '#f8f9fa', 
                  padding: '15px', 
                  borderRadius: '6px',
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center'
                }}>
                  <div>
                    <span style={{ fontSize: '14px', color: '#666' }}>
                      Showing {filteredRouteFlights[activeTab]?.length || 0} flights for{' '}
                      <strong>{getRouteList()?.[activeTab]?.fromCode} → {getRouteList()?.[activeTab]?.toCode}</strong>
                    </span>
                  </div>
                  <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
                    <div>
                      <span style={{ fontSize: '12px', color: '#666' }}>Cheapest: </span>
                      <span style={{ fontSize: '14px', fontWeight: '600', color: '#4CAF50' }}>
                        ₹{getCheapestPrice(activeTab).toLocaleString('en-IN')}
                      </span>
                    </div>
                    <div>
                      <span style={{ fontSize: '12px', color: '#666' }}>Fastest: </span>
                      <span style={{ fontSize: '14px', fontWeight: '600', color: '#2196F3' }}>
                        {formatDuration(getFastestDuration(activeTab))}
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            </div>

            {/* Sort Options */}
            <div className="row mb-3">
              <div className="col-12">
                <div style={{ 
                  display: 'flex', 
                  gap: '10px', 
                  padding: '10px 0',
                  borderBottom: '1px solid #ddd'
                }}>
                  <span style={{ fontSize: '14px', fontWeight: '600', marginRight: '10px' }}>Sort By:</span>
                  <button style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#ff6b35', 
                    fontSize: '14px',
                    cursor: 'pointer',
                    fontWeight: '500'
                  }}>
                    Duration
                  </button>
                  <span style={{ color: '#ddd' }}>|</span>
                  <button style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#666', 
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}>
                    Departure
                  </button>
                  <span style={{ color: '#ddd' }}>|</span>
                  <button style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#666', 
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}>
                    Arrival
                  </button>
                  <span style={{ color: '#ddd' }}>|</span>
                  <button style={{ 
                    background: 'none', 
                    border: 'none', 
                    color: '#666', 
                    fontSize: '14px',
                    cursor: 'pointer'
                  }}>
                    Price
                  </button>
                </div>
              </div>
            </div>

            {/* Flight List */}
            <div className="row">
              <div className="col-12">
                {loading ? (
                  <div className="text-center py-5">
                    <div className="spinner-border text-primary" role="status">
                      <span className="visually-hidden">Loading...</span>
                    </div>
                  </div>
                ) : (filteredRouteFlights[activeTab] || []).length === 0 ? (
                  <div className="text-center py-5">
                    <h4>No flights found</h4>
                    <p>Try adjusting your search criteria</p>
                  </div>
                ) : (
                  (filteredRouteFlights[activeTab] || []).map(flight => renderFlightCard(flight, activeTab))
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Booking Bar */}
      {Object.keys(selectedFlightsPerRoute).length > 0 && (
        <div style={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          background: '#1a1a1a',
          padding: '15px 0',
          boxShadow: '0 -2px 10px rgba(0,0,0,0.1)',
          zIndex: 1000
        }}>
          <div className="container">
            <div className="row align-items-center">
              <div className="col-md-8">
                <div style={{ display: 'flex', gap: '20px', alignItems: 'center', color: 'white', flexWrap: 'wrap' }}>
                  {Object.entries(selectedFlightsPerRoute).map(([routeIdx, flight]) => {
                    const route = getRouteList()?.[routeIdx];
                    const firstSeg = flight.sI?.[0];
                    const lastSeg = flight.sI?.[flight.sI.length - 1];
                    const airline = firstSeg?.fD?.aI;

                    return (
                      <div key={routeIdx} style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                        <img
                          src={`https://airhex.com/images/airline-logos/alt/${airline?.code.toLowerCase()}.png`}
                          alt={airline?.name}
                          style={{ width: '30px', height: '30px', objectFit: 'contain' }}
                          onError={(e) => {
                            e.target.style.display = 'none';
                            if (e.target.nextSibling) e.target.nextSibling.style.display = 'flex';
                          }}
                        />
                        <div style={{ width: '30px', height: '30px', borderRadius: '5px', background: '#ed1173', color: '#fff', fontSize: '10px', fontWeight: '700', alignItems: 'center', justifyContent: 'center', display: 'none' }}>
                          {airline?.code}
                        </div>
                        <div>
                          <div style={{ fontSize: '12px', fontWeight: '600' }}>
                            {airline?.name} {airline?.code}-{firstSeg?.fD?.fN}
                          </div>
                          <div style={{ fontSize: '11px', opacity: 0.8 }}>
                            {formatTime(firstSeg?.dt)} {route?.fromCode} → {formatTime(lastSeg?.at)} {route?.toCode}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
              <div className="col-md-4 text-end">
                <div style={{ display: 'flex', justifyContent: 'flex-end', alignItems: 'center', gap: '20px' }}>
                  <div style={{ color: 'white' }}>
                    <div style={{ fontSize: '12px', opacity: 0.8 }}>Total Price</div>
                    <div style={{ fontSize: '24px', fontWeight: '700', color: '#ff6b35' }}>
                      ₹{getTotalPrice().toLocaleString('en-IN')}
                    </div>
                  </div>
                  <button
                    onClick={handleBook}
                    disabled={!canBook() || loading}
                    style={{
                      background: canBook() ? '#ff6b35' : '#666',
                      color: 'white',
                      border: 'none',
                      padding: '12px 40px',
                      borderRadius: '6px',
                      fontSize: '16px',
                      fontWeight: '600',
                      cursor: canBook() ? 'pointer' : 'not-allowed',
                      transition: 'all 0.3s'
                    }}
                  >
                    {loading ? 'Processing...' : canBook() ? 'BOOK' : `Select ${Object.keys(routeFlights).length - Object.keys(selectedFlightsPerRoute).length} more`}
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
