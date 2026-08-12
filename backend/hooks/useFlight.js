import { useState, useCallback } from 'react';
import {
  searchFlights,
  reviewFlight,
  getFareRule,
  getSeatMap,
  bookFlight,
  getBookingDetails,
  getAmendmentCharges,
  submitAmendment,
  pollAmendment,
} from '../services/api/flightApi';

// ─── Helpers ─────────────────────────────────────────────────────────────────

/**
 * Build a dedup key for a trip segment so we don't show the same flight twice
 * when merging direct + connecting results.
 */
const tripSignature = (trip) => {
  const first = trip?.sI?.[0];
  const last = trip?.sI?.[trip.sI.length - 1];
  if (!first || !last) return JSON.stringify(trip);
  return `${first.fD?.aI?.code}${first.fD?.fN}-${first.da?.code}-${last.aa?.code}-${first.dt}`;
};

const dedupeTrips = (trips) => {
  const seen = new Set();
  return trips.filter((trip) => {
    const key = tripSignature(trip);
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
};

const extractTripInfos = (response) =>
  response?.data?.searchResult?.tripInfos ||
  response?.searchResult?.tripInfos ||
  {};

// ─── useFlightSearch ──────────────────────────────────────────────────────────

/**
 * Fires direct + connecting searches in parallel, merges ONWARD/RETURN/COMBO.
 *
 * Usage:
 *   const { search, data, loading, error, reset } = useFlightSearch();
 *   search(searchQuery);  // searchQuery is a TripJack-shaped object
 *
 * data shape:
 *   { ONWARD: [], RETURN: [], COMBO: [], raw: { direct, connecting } }
 */
export const useFlightSearch = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const reset = useCallback(() => {
    setData(null);
    setError(null);
    setLoading(false);
  }, []);

  const search = useCallback(async (searchQuery) => {
    setLoading(true);
    setError(null);
    setData(null);

    // Fire both direct-only and connecting-only in parallel
    const directQuery = {
      ...searchQuery,
      searchModifiers: { isDirectFlight: true, isConnectingFlight: false },
    };
    const connectingQuery = {
      ...searchQuery,
      searchModifiers: { isDirectFlight: false, isConnectingFlight: true },
    };

    const [directResult, connectingResult] = await Promise.allSettled([
      searchFlights(directQuery),
      searchFlights(connectingQuery),
    ]);

    const directInfos =
      directResult.status === 'fulfilled'
        ? extractTripInfos(directResult.value)
        : {};
    const connectingInfos =
      connectingResult.status === 'fulfilled'
        ? extractTripInfos(connectingResult.value)
        : {};

    // Both failed → surface error
    if (
      directResult.status === 'rejected' &&
      connectingResult.status === 'rejected'
    ) {
      setError(directResult.reason?.message || 'Flight search failed');
      setLoading(false);
      return;
    }

    const merge = (key) =>
      dedupeTrips([
        ...(directInfos[key] || []),
        ...(connectingInfos[key] || []),
      ]);

    setData({
      ONWARD: merge('ONWARD'),
      RETURN: merge('RETURN'),
      COMBO: merge('COMBO'),
      raw: {
        direct: directResult.status === 'fulfilled' ? directResult.value : null,
        connecting:
          connectingResult.status === 'fulfilled' ? connectingResult.value : null,
      },
    });
    setLoading(false);
  }, []);

  return { search, data, loading, error, reset };
};

// ─── useFlightReview ──────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { review, data, loading, error } = useFlightReview();
 *   review(['priceId1', 'priceId2']);
 */
export const useFlightReview = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const review = useCallback(async (priceIds) => {
    setLoading(true);
    setError(null);
    try {
      const result = await reviewFlight(priceIds);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Price review failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { review, data, loading, error };
};

// ─── useFareRule ──────────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { fetchFareRule, data, loading, error } = useFareRule();
 *   fetchFareRule('priceId', 'SEARCH');
 */
export const useFareRule = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchFareRule = useCallback(async (id, flowType) => {
    setLoading(true);
    setError(null);
    try {
      const result = await getFareRule(id, flowType);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Fare rules fetch failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { fetchFareRule, data, loading, error };
};

// ─── useSeatMap ───────────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { fetchSeatMap, data, loading, error } = useSeatMap();
 *   fetchSeatMap('bookingId');
 */
export const useSeatMap = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetchSeatMap = useCallback(async (bookingId) => {
    setLoading(true);
    setError(null);
    try {
      const result = await getSeatMap(bookingId);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Seat map fetch failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { fetchSeatMap, data, loading, error };
};

// ─── useFlightBook ────────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { book, data, loading, error } = useFlightBook();
 *   book(payload);
 */
export const useFlightBook = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const book = useCallback(async (payload) => {
    setLoading(true);
    setError(null);
    try {
      const result = await bookFlight(payload);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Booking failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { book, data, loading, error };
};

// ─── useBookingDetails ────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { fetch, data, loading, error } = useBookingDetails();
 *   fetch('bookingId');
 */
export const useBookingDetails = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const fetch = useCallback(async (bookingId) => {
    setLoading(true);
    setError(null);
    try {
      const result = await getBookingDetails(bookingId);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Booking details fetch failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { fetch, data, loading, error };
};

// ─── useAmendment ─────────────────────────────────────────────────────────────

/**
 * Usage:
 *   const { getCharges, submit, poll, data, loading, error } = useAmendment();
 *   getCharges(payload);
 *   submit(payload);
 *   poll('amendmentId');
 */
export const useAmendment = () => {
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const getCharges = useCallback(async (payload) => {
    setLoading(true);
    setError(null);
    try {
      const result = await getAmendmentCharges(payload);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Amendment charges fetch failed');
    } finally {
      setLoading(false);
    }
  }, []);

  const submit = useCallback(async (payload) => {
    setLoading(true);
    setError(null);
    try {
      const result = await submitAmendment(payload);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Amendment submission failed');
    } finally {
      setLoading(false);
    }
  }, []);

  const poll = useCallback(async (amendmentId) => {
    setLoading(true);
    setError(null);
    try {
      const result = await pollAmendment(amendmentId);
      setData(result);
    } catch (err) {
      setError(err?.message || 'Amendment poll failed');
    } finally {
      setLoading(false);
    }
  }, []);

  return { getCharges, submit, poll, data, loading, error };
};
