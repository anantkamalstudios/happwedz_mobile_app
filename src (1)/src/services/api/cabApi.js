import axiosInstance from "./axiosInstance";

/**
 * These endpoints report upstream failures (invalid API key, supplier errors)
 * as HTTP 200 with `status: false` / `success: false`, so a non-throwing
 * response still has to be checked or the caller reads it as an empty result.
 */
const unwrap = (body, fallbackMessage) => {
  const ok = body?.success ?? body?.status;
  if (ok === false) {
    const error = new Error(
      body?.message || body?.details?.message || fallbackMessage,
    );
    error.apiErrorCode = body?.details?.errorCode;
    error.isApiFailure = true;
    throw error;
  }
  return body?.data;
};

const getErrorMessage = (error, fallback) => {
  if (typeof error === "string" && error.trim()) return error;
  if (typeof error?.response?.data?.message === "string" && error.response.data.message.trim()) {
    return error.response.data.message;
  }
  if (typeof error?.message === "string" && error.message.trim()) return error.message;
  return fallback;
};

/**
 * Google Places autocomplete for cab pickup / drop inputs.
 * Response shape: { status, message, data: { places: [{ id, displayLabel, name, value, order }] } }
 */
export const searchCabLocations = async (input, options = {}) => {
  try {
    const response = await axiosInstance.post(
      "tripjack-cabs/search-locations",
      { input },
      { signal: options?.signal },
    );
    const places = unwrap(response?.data, "Could not fetch locations")?.places;
    return Array.isArray(places) ? places : [];
  } catch (error) {
    if (error?.code === "ERR_CANCELED" || error?.name === "CanceledError") throw error;
    console.error(getErrorMessage(error, "Error fetching cab locations"));
    throw error;
  }
};

/**
 * Resolves a Google place id into coordinates + address, which the quotes
 * payload needs for both origin and destination.
 * Response shape: { data: { location: { lat, lng }, address: { city, country, postalCode } } }
 */
export const fetchCabPlaceDetails = async (placeId, options = {}) => {
  try {
    const response = await axiosInstance.post(
      "tripjack-cabs/lat-long",
      { placeId },
      { signal: options?.signal },
    );
    return unwrap(response?.data, "Could not resolve this location") || null;
  } catch (error) {
    if (error?.code === "ERR_CANCELED" || error?.name === "CanceledError") throw error;
    console.error(getErrorMessage(error, "Error fetching place details"));
    throw error;
  }
};

/**
 * Builds the origin/destination node the quotes endpoint expects from a
 * selected suggestion plus its resolved place details.
 */
export const buildCabLocationNode = (suggestion, details) => ({
  type: "location",
  displayAddress: suggestion?.displayLabel || suggestion?.name || "",
  lat: String(details?.location?.lat ?? ""),
  long: String(details?.location?.lng ?? ""),
  address: {
    ...(details?.address?.subLocality ? { subLocality: details.address.subLocality } : {}),
    city: details?.address?.city || "",
    country: details?.address?.country || "",
    postalCode: details?.address?.postalCode || "",
  },
});

/**
 * journeyType: "airport_transfer" | "outstation"; tripType: "oneway" | "roundtrip".
 * Response shape: { success, data: { journeyInfo, routeDetails, quotesInfo: [...] } }
 */
export const fetchCabQuotes = async (payload, options = {}) => {
  try {
    const response = await axiosInstance.post("tripjack-cabs/quotes", payload, {
      signal: options?.signal,
    });
    return unwrap(response?.data, "Could not fetch cab quotes") || null;
  } catch (error) {
    if (error?.code === "ERR_CANCELED" || error?.name === "CanceledError") throw error;
    console.error(getErrorMessage(error, "Error fetching cab quotes"));
    throw error;
  }
};

/**
 * Creates the cab booking. Returns the booking object from
 * { success, message, data: { id, status, totalPrice, journey, ... } }.
 */
export const createCabBooking = async (payload, options = {}) => {
  try {
    const response = await axiosInstance.post("tripjack-cabs/book", payload, {
      signal: options?.signal,
    });
    return unwrap(response?.data, "Could not create the booking") || null;
  } catch (error) {
    console.error(getErrorMessage(error, "Error creating cab booking"));
    throw error;
  }
};

/**
 * Amount actually due for a booking. For round trips the summary also carries
 * the paired onward/return booking ids.
 * Response: { data: { amountPayable, onwardBookingId, returnBookingId } }
 */
export const fetchCabPaymentSummary = async (bookingId, options = {}) => {
  try {
    const response = await axiosInstance.get(
      `tripjack-cabs/payment/summary/${bookingId}`,
      { signal: options?.signal },
    );
    return unwrap(response?.data, "Could not fetch payment summary") || null;
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching payment summary"));
    throw error;
  }
};

/**
 * Loads the Razorpay checkout script once. Resolves true when available.
 */
export const loadRazorpayScript = () => {
  if (typeof window === "undefined") return Promise.resolve(false);
  if (window.Razorpay) return Promise.resolve(true);

  return new Promise((resolve) => {
    const src = "https://checkout.razorpay.com/v1/checkout.js";
    const existing = document.querySelector(`script[src="${src}"]`);
    if (existing) {
      existing.addEventListener("load", () => resolve(true), { once: true });
      existing.addEventListener("error", () => resolve(false), { once: true });
      return;
    }
    const script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.onload = () => resolve(true);
    script.onerror = () => resolve(false);
    document.body.appendChild(script);
  });
};

/**
 * Creates a Razorpay order to collect the fare from the customer.
 * Response: { keyId, razorpayOrderId, amount (paise), currency, bookingId }
 */
/**
 * @param amount          what the customer pays, markup included
 * @param supplierAmount  what TripJack is owed for the quote, markup excluded
 *
 * These are separate because the settlement call validates against the quote:
 * sending the marked-up figure is rejected with "Net Payable Amount is <quote>".
 */
export const createCabPaymentOrder = async (
  { bookingId, amount, supplierAmount },
  options = {},
) => {
  try {
    const response = await axiosInstance.post(
      "tripjack-cabs/payment/create-order",
      { bookingId, amount, supplierAmount },
      { signal: options?.signal },
    );
    return response?.data || null;
  } catch (error) {
    console.error(getErrorMessage(error, "Error creating cab payment order"));
    throw error;
  }
};

/**
 * Verifies the Razorpay payment; the backend then settles with TripJack from
 * the agent wallet (a slow write), so this allows extra time.
 * Response: { status, bookingId, paymentId, settlement, bookingDetails }
 */
export const verifyCabPayment = async (payload, options = {}) => {
  try {
    const response = await axiosInstance.post(
      "tripjack-cabs/payment/verify",
      payload,
      { signal: options?.signal, timeout: 90000 },
    );
    return response?.data || null;
  } catch (error) {
    console.error(getErrorMessage(error, "Error verifying cab payment"));
    throw error;
  }
};

/**
 * Post-payment order view. Accepts one id or an array.
 * Response: { data: [{ order, bookingUser, itemInfos: { CAB: {...} } }] }
 */
export const fetchCabBookingDetails = async (bookingIds, options = {}) => {
  const ids = Array.isArray(bookingIds) ? bookingIds.join(",") : bookingIds;
  try {
    const response = await axiosInstance.get("tripjack-cabs/booking/details", {
      params: { bookingIds: ids },
      signal: options?.signal,
    });
    const list = unwrap(response?.data, "Could not fetch booking details");
    return Array.isArray(list) ? list : [];
  } catch (error) {
    console.error(getErrorMessage(error, "Error fetching booking details"));
    throw error;
  }
};

/** Normalises one entry of the booking-details list into a flat view model. */
export const normalizeCabBookingDetail = (entry) => {
  const order = entry?.order || {};
  const cab = entry?.itemInfos?.CAB || {};
  const journey = cab.journeyInfo || {};
  return {
    bookingId: order.bookingId,
    status: order.status,
    paymentStatus: order.paymentStatus,
    rideStatus: order.rideStatus,
    trackingLink: order.trackingLink,
    helpline: order.helpline,
    timeToTravel: order.timeToTravel,
    serviceRequest: order.serviceRequest,
    tripType: order.tripType,
    policies: order.policies || {},
    passenger: cab.paxDetails || {},
    vehicle: cab.vehicleDetail || {},
    journey: {
      journeyType: journey.journeyType,
      source: journey.source,
      destination: journey.destination,
      pickupDate: journey.pickupDate,
      returnDate: journey.returnDate,
      duration: journey.duration,
      distance: journey.distance,
      flightNumber: journey.flightDetails?.number || "",
    },
    pricing: cab.pricing || {},
    contacts: order.deliveryInfo || {},
  };
};

/**
 * Maps a selected quote plus the quotes-response context into the /book payload.
 * Note the endpoint expects `routeDetail` (singular) while the quotes response
 * returns `routeDetails`.
 */
export const buildCabBookingPayload = ({
  journeyInfo,
  routeDetails,
  quote,
  passenger,
  serviceRequest = "",
  agentEmail,
  agentPhone,
  agentId,
}) => ({
  journeyInfo,
  routeDetail: routeDetails,
  addons: [],
  quotationInfo: {
    vehicleType: quote.vehicleType,
    vehicleCategory: quote.vehicleCategory,
    quoteId: quote.quotationId,
    childQuoteId: quote.quoteChildId,
    paxCount: quote.paxCount,
    luggageCount: quote.luggageCount,
    vendorId: quote.vendorId,
  },
  pricingInfo: {
    netAmount: String(quote.netFare),
    addonsPrice: "0.00",
    tjTaxAmount: String(quote.totalTax),
    agentMarkup: 0,
    agentMarkupSplitup: {
      onwardJourneyMarkup: 0,
      returnJourneyMarkup: 0,
    },
    grossAmount: String(quote.grossFare),
    tjManagementFee: "0.00",
  },
  passengerDetail: {
    firstName: passenger.firstName,
    lastName: passenger.lastName,
    email: passenger.email,
    phone: passenger.phone,
    ...(passenger.flightNumber
      ? { flightDetails: { number: passenger.flightNumber } }
      : {}),
  },
  serviceRequest,
  consent: "yes",
  agentEmail,
  agentPhone,
  agentId,
  vendorId: quote.vendorId,
});

/** Flattens quotesInfo groups into one sorted list of bookable options. */
export const flattenCabQuotes = (quotesInfo) => {
  if (!Array.isArray(quotesInfo)) return [];
  return quotesInfo
    .flatMap((group) =>
      (Array.isArray(group?.quotes) ? group.quotes : []).map((quote) => ({
        // group-level vehicle info
        vehicleType: group.vehicleType,
        vehicleCategory: group.vehicleCategory,
        label: group.label,
        paxCapacity: group.paxCapacity,
        luggageCapacity: group.luggageCapacity,
        image: Array.isArray(group.vehicleImages) ? group.vehicleImages[0] : null,
        similarType: group.similarType,
        // quote-level info
        vendorId: quote.vendorId,
        quotationId: quote.quotationId,
        quoteChildId: quote.quoteChildId,
        // fareBreakup.totalFare is the NET (pre-tax) amount; the bookable
        // gross the /book endpoint validates against is net + tax.
        netFare: quote?.fareBreakup?.totalFare ?? 0,
        totalTax: quote?.fareBreakup?.totalTax ?? 0,
        grossFare:
          (quote?.fareBreakup?.totalFare ?? 0) + (quote?.fareBreakup?.totalTax ?? 0),
        benefits: Array.isArray(quote.benefits) ? quote.benefits : [],
        policies: quote.policies || {},
        paxCount: quote.paxCount,
        luggageCount: quote.luggageCount,
        model: quote.model || group.similarType || "",
      })),
    )
    .sort((a, b) => a.grossFare - b.grossFare);
};
