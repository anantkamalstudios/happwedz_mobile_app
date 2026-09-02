import { useCallback, useEffect, useRef, useState } from "react";
import axiosInstance from "../../../../services/api/axiosInstance";
import { getAllHotelBookings } from "../../../../services/api/hotelApi";
import { getMyFlightBookings } from "../../../../services/api/flightApi";
import { getMyInsuranceBookings } from "../../../../services/api/tripSafeApi";

// Absolute, as the original Booking tab had it. axiosInstance's baseURL points
// at the same host in production; leaving it absolute keeps behaviour identical.
export const QUOTATIONS_URL =
  "https://happywedz.com/api/request-pricing/user/quotations";

// The cab list is served off the invoice endpoint, so rows arrive in invoice
// shape and get flattened into the booking shape the card expects.
const fromInvoice = (invoice) => {
  const [pickup, dropoff] = String(invoice.route || "").split(" → ");
  return {
    id: invoice.id,
    tripjackBookingId: invoice.bookingId,
    razorpayOrderId: invoice.orderId,
    route: invoice.route,
    pickupLocation: pickup || "—",
    dropoffLocation: dropoff || "—",
    pickupAt: invoice.pickupTime,
    amount: invoice.amount,
    currency: invoice.currency,
    paymentStatus: invoice.paymentStatus,
    bookingStatus: invoice.bookingStatus,
    passengerName: invoice.passengerName,
    createdAt: invoice.createdAt,
  };
};

const SOURCES = {
  services: {
    error: "Could not load your service bookings.",
    fetch: async () => {
      const res = await axiosInstance.get(QUOTATIONS_URL);
      return res.data?.success ? res.data.quotations || [] : [];
    },
  },
  hotels: {
    error: "Could not load your hotel bookings.",
    fetch: async () => {
      const res = await getAllHotelBookings();
      return Array.isArray(res?.bookings) ? res.bookings : [];
    },
  },
  flights: {
    error: "Could not load your flight bookings.",
    fetch: async () => {
      const res = await getMyFlightBookings();
      return res?.status ? res.data || [] : [];
    },
  },
  cabs: {
    error: "Could not load your cab bookings.",
    fetch: async () => {
      const res = await axiosInstance.get("/tripjack-cabs/invoices");
      return res.data?.status ? (res.data.invoices || []).map(fromInvoice) : [];
    },
  },
  insurance: {
    error: "Could not load your insurance bookings.",
    fetch: async () => {
      const res = await getMyInsuranceBookings();
      return res?.status ? res.bookings || [] : [];
    },
  },
  // Orders placed on the store (store.happywedz.com), a separate service with
  // its own MongoDB. The HappyWedz backend resolves which store customer this
  // user is and reshapes the orders into rows before they get here, so this
  // fetcher looks like the other five even though the data crossed a service
  // and a database engine to arrive.
  //
  // A user who has never shopped comes back { linked: false, orders: [] } — an
  // empty panel, not an error.
  orders: {
    error: "Could not load your shop orders.",
    fetch: async () => {
      const res = await axiosInstance.get("/store/orders/mine");
      return res.data?.success ? res.data.orders || [] : [];
    },
  },
};

export const SOURCE_KEYS = Object.keys(SOURCES);

const initialState = () =>
  SOURCE_KEYS.reduce((acc, key) => {
    acc[key] = { rows: [], loading: true, error: null };
    return acc;
  }, {});

/**
 * Loads all five booking lists once, in parallel, when the Booking tab mounts.
 *
 * Fetching used to live in each panel and run only while that panel was
 * visible, which meant the rail and category badges stayed blank until you had
 * clicked through every sub-tab — and re-fetched every time you switched back.
 * Counts are part of the navigation, so the data they count has to be loaded
 * with the tab, not with the panel.
 */
export default function useBookingData() {
  const [state, setState] = useState(initialState);
  const alive = useRef(true);

  useEffect(() => {
    alive.current = true;
    return () => {
      alive.current = false;
    };
  }, []);

  const load = useCallback((key) => {
    const source = SOURCES[key];
    if (!source) return;

    setState((prev) => ({ ...prev, [key]: { ...prev[key], loading: true, error: null } }));

    source
      .fetch()
      .then((rows) => {
        if (!alive.current) return;
        setState((prev) => ({ ...prev, [key]: { rows, loading: false, error: null } }));
      })
      .catch((err) => {
        if (!alive.current) return;
        console.error(`${key} bookings fetch error:`, err);
        setState((prev) => ({
          ...prev,
          [key]: { rows: [], loading: false, error: source.error },
        }));
      });
  }, []);

  useEffect(() => {
    SOURCE_KEYS.forEach(load);
  }, [load]);

  /** Optimistic in-place edit, so cancelling a quotation need not refetch. */
  const update = useCallback((key, updater) => {
    setState((prev) => ({
      ...prev,
      [key]: { ...prev[key], rows: updater(prev[key].rows) },
    }));
  }, []);

  return { state, reload: load, update };
}
