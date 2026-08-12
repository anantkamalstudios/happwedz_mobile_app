import axiosInstance from './axiosInstance';

const LEGACY_BASE_URL = 'https://happywedz.com/api/Flight_booking';
// const LEGACY_BASE_URL = 'http://localhost:4000/Flight_booking';

const isTripJackSearchQuery = (payload) =>
  Boolean(payload?.routeInfos || payload?.searchModifiers);

// --- Location search (TripJack) ---

export const searchLocations = async (q, signal) => {
  const response = await axiosInstance.get('/tj/meta/locations', {
    params: { q },
    signal,
  });
  return response.data;
};

/** Legacy airport search; hooks use searchLocations */
export const searchAirports = async (keyword, signal) => {
  try {
    const response = await axiosInstance.get(`${LEGACY_BASE_URL}/airports`, {
      params: { keyword },
      signal,
    });
    return response.data;
  } catch (error) {
    console.error('Error searching airports:', error);
    throw error;
  }
};

// --- Flight search ---

export const searchFlights = async (searchQueryOrParams, signal) => {
  if (isTripJackSearchQuery(searchQueryOrParams)) {
    const response = await axiosInstance.post(
      '/tj/fms/search',
      { searchQuery: searchQueryOrParams },
      signal ? { signal } : undefined
    );
    return response.data;
  }

  try {
    const response = await axiosInstance.post(
      `${LEGACY_BASE_URL}/search`,
      searchQueryOrParams,
      signal ? { signal } : undefined
    );
    return response.data;
  } catch (error) {
    console.error('Error searching flights:', error);
    throw error;
  }
};

// --- TripJack FMS ---

export const reviewFlight = async (priceIds) => {
  const response = await axiosInstance.post('/tj/fms/review', { priceIds });
  return response.data;
};

export const getFareRule = async (id, flowType) => {
  const response = await axiosInstance.post('/tj/fms/farerule', { id, flowType });
  return response.data;
};

export const getSeatMap = async (bookingId) => {
  const response = await axiosInstance.post('/tj/fms/seat', { bookingId });
  return response.data;
};

// --- TripJack OMS ---

/**
 * Book flight (instant ticket) — POST /tj/oms/book
 * @param {object} payload  TripJack booking payload (includes paymentInfos)
 */
export const bookFlight = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/book', payload);
  return response.data;
};

/**
 * Hold / Block itinerary — POST /tj/oms/hold (book WITHOUT paymentInfos)
 * @param {object} payload  bookingId + travellerInfo + deliveryInfo
 */
export const holdFlight = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/hold', payload);
  return response.data;
};

/**
 * Post-hold fare confirmation — POST /tj/oms/fare-validate
 * @param {object} payload
 */
export const fareValidate = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/fare-validate', payload);
  return response.data;
};

/**
 * Pre-book fare validation (TJ 2.0 instant) — POST /tj/oms/book-fare-validate
 * @param {object} payload
 */
export const bookFareValidate = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/book-fare-validate', payload);
  return response.data;
};

/**
 * Confirm booking — POST /tj/oms/confirm-book
 * @param {object} payload
 */
export const confirmBook = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/confirm-book', payload);
  return response.data;
};

/**
 * Booking details — POST /tj/oms/booking-details
 * @param {string} bookingId
 * @param {boolean} requirePaxPricing  include traveller-level pricing (default true)
 */
export const getBookingDetails = async (bookingId, requirePaxPricing = true) => {
  const response = await axiosInstance.post('/tj/oms/booking-details', { bookingId, requirePaxPricing });
  return response.data;
};

export const getAmendmentCharges = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/amendment/charges', payload);
  return response.data;
};

export const submitAmendment = async (payload) => {
  const response = await axiosInstance.post('/tj/oms/amendment/submit', payload);
  return response.data;
};

export const pollAmendment = async (amendmentId) => {
  const response = await axiosInstance.post('/tj/oms/amendment/poll', { amendmentId });
  return response.data;
};

// --- Legacy helpers ---

export const getFlightDetails = async (offerId) => {
  const response = await axiosInstance.get(`${LEGACY_BASE_URL}/flight/${offerId}`);
  return response.data;
};

export const verifyOffer = async (provider, offerId) => {
  const response = await axiosInstance.post(`${LEGACY_BASE_URL}/verify`, {
    provider,
    offer_id: offerId,
  });
  return response.data;
};

export const cancelBooking = async (bookingId) => {
  const response = await axiosInstance.post(
    `${LEGACY_BASE_URL}/booking/${bookingId}/cancel`
  );
  return response.data;
};

export const getPopularRoutes = async () => {
  const response = await axiosInstance.get(`${LEGACY_BASE_URL}/popular-routes`);
  return response.data;
};

export const getFlightDeals = async () => {
  const response = await axiosInstance.get(`${LEGACY_BASE_URL}/deals`);
  return response.data;
};

// --- Payment ---

export const createFlightPaymentOrder = async (bookingData) => {
  const paymentPayload = {
    offer_id: bookingData.offer_id,
    provider: bookingData.provider,
    amount: bookingData.price,
    trip_type: bookingData.trip_type,
    from: bookingData.from,
    to: bookingData.to,
    departure: bookingData.departure,
    arrival: bookingData.arrival,
    flight_no: bookingData.flight_no,
    airline: bookingData.airline,
    cabin_class: bookingData.cabin_class,
    passengers: bookingData.passengers,
    contact: bookingData.contact,
    booking_payload: bookingData.booking_payload,
    // true when paying for a previously HELD booking → backend tickets via confirm-book
    is_hold_confirm: bookingData.is_hold_confirm === true,
  };

  const response = await axiosInstance.post(
    '/flight_payment/create_order',
    paymentPayload
  );
  return response.data;
};

/**
 * HOLD a fare (block the seat without payment) — POST /flight_payment/hold
 * @param {object} holdData  same shape as createFlightPaymentOrder's bookingData
 */
export const holdFlightBooking = async (holdData) => {
  const payload = {
    provider: holdData.provider,
    amount: holdData.price,
    trip_type: holdData.trip_type,
    from: holdData.from,
    to: holdData.to,
    departure: holdData.departure,
    arrival: holdData.arrival,
    flight_no: holdData.flight_no,
    airline: holdData.airline,
    cabin_class: holdData.cabin_class,
    passengers: holdData.passengers,
    contact: holdData.contact,
    booking_payload: holdData.booking_payload,
  };
  const response = await axiosInstance.post('/flight_payment/hold', payload);
  return response.data;
};

/**
 * Verify Razorpay payment and book flight
 * @param {object} payload
 */
export const verifyAndBookFlight = async (payload) => {
  const response = await axiosInstance.post('/flight_payment/verify_and_book', payload);
  return response.data;
};

// ─── My Bookings (logged-in user) ────────────────────────────────────────────

/**
 * Get the logged-in user's flight bookings — GET /tj/my-bookings
 * Returns rows enriched with passenger_name, passenger_count, payment_status, amount_paid.
 */
export const getMyFlightBookings = async () => {
  const response = await axiosInstance.get('/tj/my-bookings');
  return response.data;
};

/**
 * Our DB record for one booking (booking date + Razorpay payment) — GET /tj/booking-record/:orderId
 */
export const getFlightBookingRecord = async (orderId) => {
  const response = await axiosInstance.get(`/tj/booking-record/${encodeURIComponent(orderId)}`);
  return response.data;
};

// ─── Cancellation ────────────────────────────────────────────────────────────

/**
 * Preview cancellation charges/refund (does NOT cancel) — POST /tj/oms/cancel-charges
 */
export const getFlightCancelCharges = async (orderId) => {
  const response = await axiosInstance.post('/tj/oms/cancel-charges', {
    provider: 'tripjack',
    order_id: orderId,
  });
  return response.data;
};

/**
 * Cancel a booking (amendment submit + poll) — POST /tj/oms/cancel
 */
export const cancelFlightBooking = async (orderId, opts = {}) => {
  const response = await axiosInstance.post('/tj/oms/cancel', {
    provider: 'tripjack',
    order_id: orderId,
    ...opts,
  });
  return response.data;
};

/**
 * Release a HELD booking (unhold) — POST /tj/oms/release-hold
 */
export const releaseHeldBooking = async (orderId) => {
  const response = await axiosInstance.post('/tj/oms/release-hold', { order_id: orderId });
  return response.data;
};
