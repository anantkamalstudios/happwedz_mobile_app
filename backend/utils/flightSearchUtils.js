/**
 * Build TripJack-shaped search query from form inputs
 * @param {object} params
 * @param {string} params.from - Origin airport code
 * @param {string} params.to - Destination airport code
 * @param {string} params.departureDate - Departure date (YYYY-MM-DD)
 * @param {string} params.returnDate - Return date (YYYY-MM-DD) for round trips
 * @param {number} params.adults - Number of adults
 * @param {number} params.children - Number of children
 * @param {number} params.infants - Number of infants
 * @param {string} params.cabinClass - Cabin class (Economy, Premium Economy, Business, First)
 * @param {string} params.tripType - Trip type (oneway, round)
 * @param {string} params.paxType - Passenger type (REGULAR, STUDENT, SENIOR_CITIZEN)
 * @param {string|string[]} params.preferredAirline - IATA airline code(s) to prefer (max 10)
 * @param {boolean} params.directFlight - Restrict to direct (non-stop) flights only
 * @returns {object} TripJack search query object
 */
export const buildTripJackSearchQuery = ({
  from,
  to,
  departureDate,
  returnDate,
  adults = 1,
  children = 0,
  infants = 0,
  cabinClass = 'Economy',
  tripType = 'oneway',
  paxType = 'REGULAR',
  preferredAirline = '',
  directFlight = false,
}) => {
  const routeInfos = [
    {
      fromCityOrAirport: {
        code: from,
      },
      toCityOrAirport: {
        code: to,
      },
      travelDate: departureDate,
    },
  ];

  if (tripType === 'round' && returnDate) {
    routeInfos.push({
      fromCityOrAirport: {
        code: to,
      },
      toCityOrAirport: {
        code: from,
      },
      travelDate: returnDate,
    });
  }

  const paxInfo = {
    ADULT: adults.toString(),
    CHILD: children.toString(),
    INFANT: infants.toString(),
  };

  // searchModifiers — per TripJack docs: pft (fare type) lives HERE, not at root.
  const searchModifiers = {
    isDirectFlight: !!directFlight,
    isConnectingFlight: false,
  };

  // pft: REGULAR (default) / STUDENT / SENIOR_CITIZEN — docs §Search Modifiers
  if (paxType && paxType !== 'REGULAR') {
    searchModifiers.pft = paxType;
  }

  const searchQuery = {
    cabinClass: cabinClass.toUpperCase().replace(/\s+/g, '_'),
    paxInfo,
    routeInfos,
    searchModifiers,
  };

  // preferredAirline — array of { code }, max 10 (docs §Preferred Carrier)
  const airlineCodes = (Array.isArray(preferredAirline) ? preferredAirline : [preferredAirline])
    .map((c) => String(c || '').trim().toUpperCase())
    .filter(Boolean);
  if (airlineCodes.length) {
    searchQuery.preferredAirline = airlineCodes.slice(0, 10).map((code) => ({ code }));
  }

  return searchQuery;
};

/**
 * Map TripJack flight response to display format
 * @param {object} flight - TripJack flight object
 * @returns {object} Mapped flight object for UI
 */
export const mapTripJackFlight = (flight) => {
  if (!flight || !flight.sI || flight.sI.length === 0) {
    return null;
  }

  const firstSegment = flight.sI[0];
  const lastSegment = flight.sI[flight.sI.length - 1];
  const airline = firstSegment.fD.aI;
  const stops = flight.sI.length - 1;
  const duration = flight.sI.reduce((sum, seg) => sum + seg.duration, 0);

  const fares = flight.totalPriceList.map((fare) => ({
    id: fare.id,
    price: fare.fd.ADULT.fC.TF,
    currency: 'INR',
    fareType: fare.fareIdentifier,
    cabinClass: fare.fd.ADULT.cc,
    refundable: fare.fd.ADULT.rT === 1,
    seatsAvailable: fare.fd.ADULT.sR || 9,
    baggage: fare.fd.ADULT.bI,
  }));

  return {
    id: flight.id || `${airline.code}${firstSegment.fD.fN}-${firstSegment.da.code}-${lastSegment.aa.code}-${firstSegment.dt}`,
    airline: {
      code: airline.code,
      name: airline.name,
      logo: `https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`,
    },
    flightNumber: firstSegment.fD.fN,
    departure: {
      airport: firstSegment.da.code,
      city: firstSegment.da.city,
      terminal: firstSegment.da.terminal,
      time: firstSegment.dt,
    },
    arrival: {
      airport: lastSegment.aa.code,
      city: lastSegment.aa.city,
      terminal: lastSegment.aa.terminal,
      time: lastSegment.at,
    },
    duration,
    stops,
    segments: flight.sI.map((seg) => ({
      airline: seg.fD.aI,
      flightNumber: seg.fD.fN,
      departure: {
        airport: seg.da.code,
        city: seg.da.city,
        terminal: seg.da.terminal,
        time: seg.dt,
      },
      arrival: {
        airport: seg.aa.code,
        city: seg.aa.city,
        terminal: seg.aa.terminal,
        time: seg.at,
      },
      duration: seg.duration,
    })),
    fares,
    rawData: flight,
  };
};

/**
 * Format price in Indian Rupees
 * @param {number} price - Price value
 * @returns {string} Formatted price string
 */
export const formatPrice = (price) => {
  return `₹${Number(price).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;
};

/**
 * Format duration in hours and minutes
 * @param {number} minutes - Duration in minutes
 * @returns {string} Formatted duration string
 */
export const formatDuration = (minutes) => {
  const hours = Math.floor(minutes / 60);
  const mins = minutes % 60;
  return `${hours}h ${mins}m`;
};

/**
 * Format time from ISO string
 * @param {string} dateStr - ISO date string
 * @returns {string} Formatted time string (HH:MM)
 */
export const formatTime = (dateStr) => {
  return new Date(dateStr).toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
};

/**
 * Format date from ISO string
 * @param {string} dateStr - ISO date string
 * @returns {string} Formatted date string
 */
export const formatDate = (dateStr) => {
  return new Date(dateStr).toLocaleDateString('en-US', {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
};

/**
 * Get stops badge text
 * @param {number} stops - Number of stops
 * @returns {string} Stops badge text
 */
export const getStopsBadgeText = (stops) => {
  if (stops === 0) return 'Non-Stop';
  return `${stops} Stop${stops > 1 ? 's' : ''}`;
};

/**
 * Get fare type badge class
 * @param {string} fareType - Fare identifier
 * @returns {string} CSS class name
 */
export const getFareBadgeClass = (fareType) => {
  const typeMap = {
    PUBLISHED: 'published',
    SME: 'sme',
    SPECIAL_RETURN: 'special',
    PROMO: 'promo',
  };
  return typeMap[fareType] || 'published';
};

/**
 * Get fare type display name
 * @param {string} fareType - Fare identifier
 * @returns {string} Display name
 */
export const getFareDisplayName = (fareType) => {
  const nameMap = {
    PUBLISHED: 'Published',
    SME: 'SME',
    SPECIAL_RETURN: 'Special Return',
    PROMO: 'Promo',
  };
  return nameMap[fareType] || fareType;
};
