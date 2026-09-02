import { airlineLogo } from './airlineLogo';
/**
 * Facet derivation and filtering for TripJack flight results.
 *
 * Everything here works off the raw `tripInfos` entries returned by
 * /fms/v1/air-search-all — no extra API call is needed to populate the sidebar.
 *
 * Two of these filters are fare-level rather than flight-level: a single flight
 * routinely carries both Standard and NDC fares, and baggage allowance varies
 * per fare family. Those narrow a trip's `totalPriceList` and only drop the
 * trip when nothing survives.
 *
 * Airport and terminal facets are keyed "DEP|CODE" / "ARR|CODE|Terminal 2" so
 * the sidebar can group them by direction the way the TripJack portal does,
 * and so a departure terminal never matches an arrival one.
 */

/** NDC fare families are prefixed "NDC_" (e.g. "NDC_Value"). */
export const isNdcFare = (fareIdentifier) => /^NDC_/i.test(fareIdentifier || '');

export const FARE_TYPES = [
  { value: 'STANDARD', label: 'Standard' },
  { value: 'NDC', label: 'NDC' },
];

export const CANCELLATION_TYPES = [
  { value: 'REFUNDABLE', label: 'Refundable' },
  { value: 'NON_REFUNDABLE', label: 'Non-Refundable' },
];

export const TIME_SLOTS = ['00-06', '06-12', '12-18', '18-24'];

export const DEP = 'DEP';
export const ARR = 'ARR';

/** Filter keys that hold an array of selected values (toggled, not replaced). */
export const ARRAY_FILTER_KEYS = [
  'stops',
  'airlines',
  'fareTypes',
  'cancellationTypes',
  'terminals',
  'airports',
  'layoverAirports',
  'departure_time',
  'arrival_time',
  'departure_return_time',
  'arrival_return_time',
];

export const EMPTY_FILTERS = {
  stops: [],
  airlines: [],
  fareTypes: [],
  cancellationTypes: [],
  terminals: [],
  airports: [],
  layoverAirports: [],
  departure_time: [],
  arrival_time: [],
  departure_return_time: [],
  arrival_return_time: [],
  // Free-text flight numbers ("123", "6E-123") rather than a picked facet.
  flightNumbers: [],
  // Exact time windows from "Select Specific Timeframe" — "HH:MM" or null.
  departure_from: null,
  departure_to: null,
  arrival_from: null,
  arrival_to: null,
  baggageOnly: false,
  hideNearbyAirports: false,
  price_min: null,
  price_max: null,
  duration_max: null,
  layover_max: null,
};

// ── Trip accessors ──────────────────────────────────────────────────────────

const segsOf = (trip) => trip?.sI || [];
const firstSeg = (trip) => segsOf(trip)[0] || null;
const lastSeg = (trip) => segsOf(trip)[segsOf(trip).length - 1] || null;

const fareCancellationType = (fare) =>
  fare?.fd?.ADULT?.rT === 1 ? 'REFUNDABLE' : 'NON_REFUNDABLE';

/** One adult's share of a fare — the raw per-passenger amount TripJack quotes. */
const adultFarePrice = (fare) => fare?.fd?.ADULT?.fC?.TF || fare?.fd?.ADULT?.fC?.NF || 0;

export const SINGLE_ADULT = { ADULT: 1, CHILD: 0, INFANT: 0 };

/** Pax counts in the shape the fare helpers expect. */
export const paxFromSearch = (searchParams = {}) => ({
  ADULT: Number(searchParams.adults || 1),
  CHILD: Number(searchParams.children || 0),
  INFANT: Number(searchParams.infants || 0),
});

/**
 * What this fare costs for the whole party.
 *
 * `fd` is keyed by passenger type and every amount is per passenger, so a fare
 * read straight off `fd.ADULT` prices the trip for one adult no matter who is
 * actually travelling — which is why a 2-adult search used to show half the
 * price the portal did.
 */
export const farePrice = (fare, pax = SINGLE_ADULT) =>
  Object.entries(pax).reduce((total, [type, count]) => {
    if (!count) return total;
    const fc = fare?.fd?.[type]?.fC;
    const amount = fc?.TF ?? fc?.NF;
    // Fall back to the adult fare when a type is missing from the fare block.
    return total + (amount != null ? amount : adultFarePrice(fare)) * count;
  }, 0);

const fareCheckinBaggage = (fare) => fare?.fd?.ADULT?.bI?.iB || '';

/** "0 Kg" / "0 Piece" means the fare carries no checked bag. */
const fareHasCheckinBaggage = (fare) => {
  const allowance = fareCheckinBaggage(fare).trim();
  return !!allowance && !/^0\s*(kg|kilogram|piece)/i.test(allowance);
};

/** Cheapest fare on a trip, used for price filtering and "from" labels. */
export const tripBestPrice = (trip, pax = SINGLE_ADULT) => {
  const prices = (trip?.totalPriceList || []).map((f) => farePrice(f, pax)).filter((n) => n > 0);
  return prices.length ? Math.min(...prices) : 0;
};

export const tripFlightNumbers = (trip) =>
  segsOf(trip)
    .map((s) => (s?.fD?.aI?.code && s?.fD?.fN ? `${s.fD.aI.code}-${s.fD.fN}` : null))
    .filter(Boolean);

export const tripDuration = (trip) =>
  segsOf(trip).reduce((n, s) => n + (s?.duration || 0) + (s?.cT || 0), 0);

/** Longest single connection on the trip, in minutes. */
export const tripMaxLayover = (trip) => {
  const segs = segsOf(trip);
  const layovers = segs.slice(0, -1).map((s) => s?.cT || 0);
  return layovers.length ? Math.max(...layovers) : 0;
};

/** Origin and final destination — this is where nearby airports show up. */
export const tripEndpointAirports = (trip) =>
  [...new Set([firstSeg(trip)?.da?.code, lastSeg(trip)?.aa?.code].filter(Boolean))];

export const tripLayoverAirports = (trip) =>
  [...new Set(segsOf(trip).slice(0, -1).map((s) => s?.aa?.code).filter(Boolean))];

/** "DEP|BOM" / "ARR|PNQ" — direction-qualified so groups can't cross-match. */
export const airportKey = (direction, code) => `${direction}|${code}`;
/** "DEP|BOM|Terminal 2" */
export const terminalKey = (direction, code, terminal) => `${direction}|${code}|${terminal}`;

export const parseKey = (key) => {
  const [direction, code, terminal] = String(key).split('|');
  return { direction, code, terminal };
};

const tripAirline = (trip) => firstSeg(trip)?.fD?.aI || null;

export { airlineLogo };

const minutesOfDay = (dateStr) => {
  const d = new Date(dateStr);
  return Number.isNaN(d.getTime()) ? null : d.getHours() * 60 + d.getMinutes();
};

const hhmmToMinutes = (value) => {
  if (!value) return null;
  const [h, m] = String(value).split(':').map(Number);
  return Number.isFinite(h) && Number.isFinite(m) ? h * 60 + m : null;
};

export const slotForHour = (hour) => {
  if (hour < 6) return '00-06';
  if (hour < 12) return '06-12';
  if (hour < 18) return '12-18';
  return '18-24';
};

const matchesSlots = (dateStr, slots) => {
  if (!slots?.length) return true;
  const mins = minutesOfDay(dateStr);
  if (mins == null) return true;
  return slots.includes(slotForHour(Math.floor(mins / 60)));
};

/** Inclusive window; a window that wraps past midnight is treated as spanning it. */
const matchesWindow = (dateStr, from, to) => {
  const start = hhmmToMinutes(from);
  const end = hhmmToMinutes(to);
  if (start == null && end == null) return true;
  const mins = minutesOfDay(dateStr);
  if (mins == null) return true;
  if (start != null && end != null) {
    return start <= end ? mins >= start && mins <= end : mins >= start || mins <= end;
  }
  if (start != null) return mins >= start;
  return mins <= end;
};

/** Normalise "6E-123", "6e 123" and "123" to a comparable form. */
const normaliseFlightNo = (value) => String(value || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

const matchesFlightNumbers = (trip, terms) => {
  if (!terms?.length) return true;
  const wanted = terms.map(normaliseFlightNo).filter(Boolean);
  if (!wanted.length) return true;
  const have = segsOf(trip).flatMap((s) => {
    const code = s?.fD?.aI?.code || '';
    const num = s?.fD?.fN || '';
    return [normaliseFlightNo(`${code}${num}`), normaliseFlightNo(num)];
  });
  // Substring match so the list narrows as you type: "SG", "SG-25" and "252"
  // all reach SG-252. Requiring a whole flight number would mean the filter
  // shows nothing until the very last character is entered.
  return wanted.some((w) => have.some((h) => h.includes(w)));
};

const tripStops = (trip) => Math.max(0, (segsOf(trip).length || 1) - 1);
/** The Stops rail caps at "3+", so anything above 3 folds into that bucket. */
const stopsBucket = (trip) => Math.min(tripStops(trip), 3);

// ── Facets ──────────────────────────────────────────────────────────────────

/**
 * Build every sidebar facet from the full (unfiltered) result set, so counts
 * stay stable as the user narrows down rather than collapsing to zero.
 *
 * @param {Array} trips - raw tripInfos entries
 * @returns {object|null} facets, or null when there is nothing to describe
 */
export const deriveFacets = (trips = [], pax = SINGLE_ADULT) => {
  if (!trips.length) return null;

  const stops = new Map();
  const airlines = new Map();
  const departure = new Map();
  const arrival = new Map();
  const depAirports = new Map();
  const arrAirports = new Map();
  const depTerminals = new Map();
  const arrTerminals = new Map();
  const layovers = new Map();
  const cancellation = new Map();
  const fareTypeCounts = { STANDARD: 0, NDC: 0 };
  let baggageCount = 0;
  let priceMin = Infinity;
  let priceMax = 0;
  let durationMin = Infinity;
  let durationMax = 0;
  let layoverMin = Infinity;
  let layoverMax = 0;
  let route = '';
  let fromCity = '';
  let toCity = '';

  const bump = (map, key, price, extra) => {
    if (key == null) return;
    const entry = map.get(key) || { count: 0, min_price: Infinity, ...extra };
    entry.count += 1;
    if (price > 0) entry.min_price = Math.min(entry.min_price, price);
    map.set(key, entry);
  };

  for (const trip of trips) {
    const price = tripBestPrice(trip, pax);
    if (price > 0) {
      priceMin = Math.min(priceMin, price);
      priceMax = Math.max(priceMax, price);
    }

    bump(stops, stopsBucket(trip), price);

    const airline = tripAirline(trip);
    if (airline?.code) {
      bump(airlines, airline.code, price, { code: airline.code, name: airline.name });
    }

    const from = firstSeg(trip);
    const to = lastSeg(trip);
    if (from?.dt) bump(departure, slotForHour(Math.floor(minutesOfDay(from.dt) / 60)), price);
    if (to?.at) bump(arrival, slotForHour(Math.floor(minutesOfDay(to.at) / 60)), price);

    if (from?.da?.code) {
      route = route || `${from.da.cityCode || from.da.code}-${to?.aa?.cityCode || to?.aa?.code}`;
      fromCity = fromCity || from.da.city || from.da.code;
      toCity = toCity || to?.aa?.city || to?.aa?.code || '';
      bump(depAirports, airportKey(DEP, from.da.code), price, {
        code: from.da.code,
        name: from.da.name,
        city: from.da.city,
      });
      if (from.da.terminal) {
        bump(depTerminals, terminalKey(DEP, from.da.code, from.da.terminal), price, {
          code: from.da.code,
          terminal: from.da.terminal,
        });
      }
    }
    if (to?.aa?.code) {
      bump(arrAirports, airportKey(ARR, to.aa.code), price, {
        code: to.aa.code,
        name: to.aa.name,
        city: to.aa.city,
      });
      if (to.aa.terminal) {
        bump(arrTerminals, terminalKey(ARR, to.aa.code, to.aa.terminal), price, {
          code: to.aa.code,
          terminal: to.aa.terminal,
        });
      }
    }

    for (const seg of segsOf(trip).slice(0, -1)) {
      if (seg?.aa?.code) {
        bump(layovers, seg.aa.code, price, { code: seg.aa.code, name: seg.aa.name });
      }
    }

    for (const fare of trip?.totalPriceList || []) {
      if (isNdcFare(fare?.fareIdentifier)) fareTypeCounts.NDC += 1;
      else fareTypeCounts.STANDARD += 1;
      bump(cancellation, fareCancellationType(fare), farePrice(fare, pax));
    }
    if ((trip?.totalPriceList || []).some(fareHasCheckinBaggage)) baggageCount += 1;

    const dur = tripDuration(trip);
    if (dur > 0) {
      durationMin = Math.min(durationMin, dur);
      durationMax = Math.max(durationMax, dur);
    }
    const lay = tripMaxLayover(trip);
    if (lay > 0) {
      layoverMin = Math.min(layoverMin, lay);
      layoverMax = Math.max(layoverMax, lay);
    }
  }

  const asList = (map, byCount = false) => {
    const list = [...map.entries()].map(([value, entry]) => ({
      value,
      ...entry,
      min_price: entry.min_price === Infinity ? null : entry.min_price,
    }));
    return byCount
      ? list.sort((a, b) => b.count - a.count)
      : list.sort((a, b) => (a.value > b.value ? 1 : -1));
  };

  const airlineList = asList(airlines, true).map((a) => ({ ...a, logo: airlineLogo(a.code) }));
  const stopList = asList(stops);
  const departureList = asList(departure);

  const stopLabel = (v) => (v === 0 ? 'Non-stop' : v === 3 ? '3+ Stops' : `${v} Stop`);
  const popular = [
    ...[...stopList].sort((a, b) => b.count - a.count).slice(0, 1)
      .map((s) => ({ key: 'stops', value: s.value, label: stopLabel(s.value) })),
    ...[...departureList].sort((a, b) => b.count - a.count).slice(0, 2)
      .map((s) => ({ key: 'departure_time', value: s.value, label: `Departure: ${s.value}` })),
    ...airlineList.slice(0, 3)
      .map((a) => ({ key: 'airlines', value: a.code, label: a.name })),
  ];

  return {
    route,
    fromCity,
    toCity,
    stops: stopList,
    airlines: airlineList,
    departureSlots: departureList,
    arrivalSlots: asList(arrival),
    departureAirports: asList(depAirports, true),
    arrivalAirports: asList(arrAirports, true),
    departureTerminals: asList(depTerminals, true),
    arrivalTerminals: asList(arrTerminals, true),
    layoverAirports: asList(layovers, true),
    fareTypes: FARE_TYPES.map((t) => ({ ...t, count: fareTypeCounts[t.value] })).filter(
      (t) => t.count > 0,
    ),
    cancellationTypes: CANCELLATION_TYPES.map((c) => ({
      ...c,
      count: cancellation.get(c.value)?.count || 0,
    })).filter((c) => c.count > 0),
    baggage: { count: baggageCount },
    priceMin: priceMin === Infinity ? 0 : Math.floor(priceMin),
    priceMax: Math.ceil(priceMax),
    durationMin: durationMin === Infinity ? 0 : durationMin,
    durationMax,
    layoverMin: layoverMin === Infinity ? 0 : layoverMin,
    layoverMax,
    popular,
  };
};

// ── Filtering ───────────────────────────────────────────────────────────────

/**
 * Apply the sidebar filters to a list of trips.
 *
 * Fare-level filters narrow each trip's `totalPriceList`, so the returned trips
 * are shallow copies carrying only the fares that matched.
 *
 * @param {Array}  trips
 * @param {object} filters
 * @param {object} [options]
 * @param {boolean} [options.isReturn]   - use the return-leg time filter keys
 * @param {string}  [options.searchFrom] - origin code, for Hide Nearby Airports
 * @param {string}  [options.searchTo]   - destination code, same
 * @returns {Array} filtered trips
 */
export const filterTrips = (
  trips = [],
  filters = {},
  { isReturn = false, searchFrom = null, searchTo = null, pax = SINGLE_ADULT } = {},
) => {
  const {
    stops = [],
    airlines = [],
    fareTypes = [],
    cancellationTypes = [],
    flightNumbers = [],
    terminals = [],
    airports = [],
    layoverAirports = [],
    baggageOnly = false,
    hideNearbyAirports = false,
    price_min: priceMin = null,
    price_max: priceMax = null,
    duration_max: durationMax = null,
    layover_max: layoverMax = null,
  } = filters;

  const depSlots = isReturn ? filters.departure_return_time : filters.departure_time;
  const arrSlots = isReturn ? filters.arrival_return_time : filters.arrival_time;
  const searchedCodes = [searchFrom, searchTo]
    .filter(Boolean)
    .map((c) => String(c).toUpperCase());

  // Direction-qualified selections only constrain their own direction, so a
  // chosen departure terminal never rejects a trip on its arrival terminal.
  const wantedDepAirports = airports.filter((k) => k.startsWith(`${DEP}|`));
  const wantedArrAirports = airports.filter((k) => k.startsWith(`${ARR}|`));
  const wantedDepTerminals = terminals.filter((k) => k.startsWith(`${DEP}|`));
  const wantedArrTerminals = terminals.filter((k) => k.startsWith(`${ARR}|`));

  const out = [];
  for (const trip of trips) {
    const segs = segsOf(trip);
    if (!segs.length) continue;
    const from = segs[0];
    const to = segs[segs.length - 1];

    if (stops.length && !stops.includes(stopsBucket(trip))) continue;
    if (airlines.length && !airlines.includes(tripAirline(trip)?.code)) continue;
    if (!matchesSlots(from.dt, depSlots)) continue;
    if (!matchesSlots(to.at, arrSlots)) continue;
    if (!matchesWindow(from.dt, filters.departure_from, filters.departure_to)) continue;
    if (!matchesWindow(to.at, filters.arrival_from, filters.arrival_to)) continue;
    if (!matchesFlightNumbers(trip, flightNumbers)) continue;

    if (wantedDepAirports.length && !wantedDepAirports.includes(airportKey(DEP, from.da?.code))) {
      continue;
    }
    if (wantedArrAirports.length && !wantedArrAirports.includes(airportKey(ARR, to.aa?.code))) {
      continue;
    }
    if (
      wantedDepTerminals.length &&
      !wantedDepTerminals.includes(terminalKey(DEP, from.da?.code, from.da?.terminal))
    ) {
      continue;
    }
    if (
      wantedArrTerminals.length &&
      !wantedArrTerminals.includes(terminalKey(ARR, to.aa?.code, to.aa?.terminal))
    ) {
      continue;
    }
    if (layoverAirports.length) {
      const l = tripLayoverAirports(trip);
      if (!layoverAirports.some((x) => l.includes(x))) continue;
    }
    if (hideNearbyAirports && searchedCodes.length) {
      if (tripEndpointAirports(trip).some((code) => !searchedCodes.includes(code))) continue;
    }
    if (durationMax != null && tripDuration(trip) > durationMax) continue;
    if (layoverMax != null && segs.length > 1 && tripMaxLayover(trip) > layoverMax) continue;

    // Fare-level narrowing.
    let fares = trip.totalPriceList || [];
    if (fareTypes.length) {
      fares = fares.filter((f) =>
        fareTypes.includes(isNdcFare(f?.fareIdentifier) ? 'NDC' : 'STANDARD'),
      );
    }
    if (cancellationTypes.length) {
      fares = fares.filter((f) => cancellationTypes.includes(fareCancellationType(f)));
    }
    if (baggageOnly) fares = fares.filter(fareHasCheckinBaggage);
    if (priceMin != null) fares = fares.filter((f) => farePrice(f, pax) >= priceMin);
    if (priceMax != null) fares = fares.filter((f) => farePrice(f, pax) <= priceMax);
    if (!fares.length) continue;

    out.push(
      fares.length === (trip.totalPriceList || []).length
        ? trip
        : { ...trip, totalPriceList: fares },
    );
  }
  return out;
};

// ── Filter state helpers ────────────────────────────────────────────────────

/** Toggle for array-valued filters, plain assignment for the rest. */
export const applyFilterChange = (filters, key, value) => {
  if (!ARRAY_FILTER_KEYS.includes(key)) return { ...filters, [key]: value };
  const current = filters[key] || [];
  return {
    ...filters,
    [key]: current.includes(value)
      ? current.filter((v) => v !== value)
      : [...current, value],
  };
};

/**
 * Drop selections that cannot match the new result set.
 *
 * Filters survive a date change on purpose, but a value that made sense
 * yesterday can be impossible today — pick a date with no non-stop flights
 * while `stops: [0]` is active and every result vanishes with no explanation.
 *
 * Free-text flight numbers are left alone: an entry that matches nothing is the
 * user's own search term, not stale state.
 */
export const reconcileFilters = (filters = {}, outboundFacets, returnFacets) => {
  const facets = [outboundFacets, returnFacets].filter(Boolean);
  if (!facets.length) return { filters, dropped: [] };

  const allowed = (...picks) => {
    const values = new Set();
    for (const f of facets) {
      for (const pick of picks) for (const item of pick(f) || []) values.add(item.value);
    }
    return values;
  };

  const SOURCES = {
    stops: [(f) => f.stops],
    airlines: [(f) => f.airlines],
    fareTypes: [(f) => f.fareTypes],
    cancellationTypes: [(f) => f.cancellationTypes],
    terminals: [(f) => f.departureTerminals, (f) => f.arrivalTerminals],
    airports: [(f) => f.departureAirports, (f) => f.arrivalAirports],
    layoverAirports: [(f) => f.layoverAirports],
    departure_time: [(f) => f.departureSlots],
    arrival_time: [(f) => f.arrivalSlots],
    departure_return_time: [(f) => f.departureSlots],
    arrival_return_time: [(f) => f.arrivalSlots],
  };

  const next = { ...filters };
  const dropped = [];

  for (const [key, picks] of Object.entries(SOURCES)) {
    const selected = filters[key];
    if (!Array.isArray(selected) || !selected.length) continue;
    const valid = allowed(...picks);
    const kept = selected.filter((v) => valid.has(v));
    if (kept.length !== selected.length) {
      next[key] = kept;
      dropped.push(key);
    }
  }

  const minOf = (take) => Math.min(...facets.map(take).filter((n) => n != null));
  const maxOf = (take) => Math.max(...facets.map(take).filter((n) => n != null));

  // A cap below the new floor (or a floor above the new ceiling) excludes
  // everything — release it rather than showing an empty list.
  if (next.price_max != null && next.price_max < minOf((f) => f.priceMin)) {
    next.price_max = null;
    dropped.push('price_max');
  }
  if (next.price_min != null && next.price_min > maxOf((f) => f.priceMax)) {
    next.price_min = null;
    dropped.push('price_min');
  }
  if (next.duration_max != null && next.duration_max < minOf((f) => f.durationMin)) {
    next.duration_max = null;
    dropped.push('duration_max');
  }
  const layFloor = minOf((f) => f.layoverMin);
  if (next.layover_max != null && layFloor > 0 && next.layover_max < layFloor) {
    next.layover_max = null;
    dropped.push('layover_max');
  }

  return { filters: dropped.length ? next : filters, dropped };
};

/** Clear one section without disturbing the rest — powers the CLEAR links. */
export const clearFilterKey = (filters, key) => {
  const next = { ...filters };
  if (key === 'timeframe') {
    next.departure_from = null;
    next.departure_to = null;
    next.arrival_from = null;
    next.arrival_to = null;
    return next;
  }
  next[key] = Array.isArray(EMPTY_FILTERS[key]) ? [] : EMPTY_FILTERS[key];
  return next;
};

export const countActiveFilters = (filters = {}) =>
  ARRAY_FILTER_KEYS.reduce((n, key) => n + (filters[key]?.length || 0), 0) +
  (filters.flightNumbers?.filter(Boolean).length || 0) +
  (filters.baggageOnly ? 1 : 0) +
  (filters.hideNearbyAirports ? 1 : 0) +
  (filters.price_min != null || filters.price_max != null ? 1 : 0) +
  (filters.duration_max != null ? 1 : 0) +
  (filters.layover_max != null ? 1 : 0) +
  (filters.departure_from || filters.departure_to ? 1 : 0) +
  (filters.arrival_from || filters.arrival_to ? 1 : 0);

/** minutes -> "3h 50m", for the duration sliders. */
export const formatMinutes = (mins) =>
  `${Math.floor((mins || 0) / 60)}h ${String((mins || 0) % 60).padStart(2, '0')}m`;

/** "14:30" options at 30-minute steps, for the timeframe pickers. */
export const TIME_OPTIONS = Array.from({ length: 48 }, (_, i) => {
  const h = Math.floor(i / 2);
  const m = i % 2 === 0 ? '00' : '30';
  return `${String(h).padStart(2, '0')}:${m}`;
});

// ── Applied-filter chips ────────────────────────────────────────────────────

const STOP_LABEL = (v) => (v === 0 ? 'Non-stop' : v === 3 ? '3+ Stops' : `${v} Stop`);

const findLabel = (list, value, fallback) =>
  list?.find((i) => i.value === value)?.label || fallback;

/**
 * Flatten the active filters into removable chips for the "Applied Filters"
 * rail, in the same order the sidebar presents them.
 *
 * @param {object} filters
 * @param {object|null} meta - facets, used to turn keys back into readable names
 * @returns {Array<{id:string,label:string,key:string,value:*}>}
 */
export const describeFilters = (filters = {}, meta = null) => {
  const chips = [];
  const push = (key, value, label) => chips.push({ id: `${key}:${value}`, key, value, label });

  for (const v of filters.stops || []) push('stops', v, `Stops: ${STOP_LABEL(v)}`);
  for (const v of filters.airlines || []) {
    push('airlines', v, `Airline: ${meta?.airlines?.find((a) => a.value === v)?.name || v}`);
  }
  for (const v of filters.fareTypes || []) {
    push('fareTypes', v, `Fare Type: ${findLabel(meta?.fareTypes, v, v)}`);
  }
  for (const v of filters.cancellationTypes || []) {
    push('cancellationTypes', v, `Cancellation: ${findLabel(meta?.cancellationTypes, v, v)}`);
  }
  for (const v of filters.terminals || []) {
    const { code, terminal } = parseKey(v);
    push('terminals', v, `Terminal: ${code} ${terminal}`);
  }
  for (const v of filters.airports || []) {
    const { code } = parseKey(v);
    push('airports', v, `Airport: ${code}`);
  }
  for (const v of filters.layoverAirports || []) push('layoverAirports', v, `Layover: ${v}`);
  for (const v of filters.departure_time || []) push('departure_time', v, `Departure: ${v}`);
  for (const v of filters.arrival_time || []) push('arrival_time', v, `Arrival: ${v}`);
  for (const v of filters.departure_return_time || []) {
    push('departure_return_time', v, `Return departure: ${v}`);
  }
  for (const v of filters.arrival_return_time || []) {
    push('arrival_return_time', v, `Return arrival: ${v}`);
  }
  for (const v of (filters.flightNumbers || []).filter(Boolean)) {
    push('flightNumbers', v, `Flight Number: ${v}`);
  }

  if (filters.departure_from || filters.departure_to) {
    push('timeframe:departure', 'departure',
      `Departure ${filters.departure_from || '…'} – ${filters.departure_to || '…'}`);
  }
  if (filters.arrival_from || filters.arrival_to) {
    push('timeframe:arrival', 'arrival',
      `Arrival ${filters.arrival_from || '…'} – ${filters.arrival_to || '…'}`);
  }
  if (filters.baggageOnly) push('baggageOnly', true, 'CheckIn Baggage');
  if (filters.hideNearbyAirports) push('hideNearbyAirports', true, 'Hide Nearby Airports');
  if (filters.price_min != null || filters.price_max != null) {
    const lo = filters.price_min != null ? `₹${Number(filters.price_min).toLocaleString('en-IN')}` : '₹0';
    const hi = filters.price_max != null ? `₹${Number(filters.price_max).toLocaleString('en-IN')}` : 'any';
    push('price', 'range', `Price: ${lo} – ${hi}`);
  }
  if (filters.duration_max != null) {
    push('duration_max', 'max', `Duration ≤ ${formatMinutes(filters.duration_max)}`);
  }
  if (filters.layover_max != null) {
    push('layover_max', 'max', `Layover ≤ ${formatMinutes(filters.layover_max)}`);
  }
  return chips;
};

/** Remove exactly one chip, leaving every other selection intact. */
export const removeFilterChip = (filters, chip) => {
  const next = { ...filters };
  if (chip.key === 'price') {
    next.price_min = null;
    next.price_max = null;
  } else if (chip.key === 'timeframe:departure') {
    next.departure_from = null;
    next.departure_to = null;
  } else if (chip.key === 'timeframe:arrival') {
    next.arrival_from = null;
    next.arrival_to = null;
  } else if (chip.key === 'flightNumbers') {
    next.flightNumbers = (filters.flightNumbers || []).filter((v) => v !== chip.value);
  } else if (Array.isArray(filters[chip.key])) {
    next[chip.key] = filters[chip.key].filter((v) => v !== chip.value);
  } else {
    next[chip.key] = EMPTY_FILTERS[chip.key];
  }
  return next;
};
