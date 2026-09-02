/**
 * One status vocabulary for five booking sources.
 *
 * Quotations, flights, cabs, hotels and insurance each report status in their
 * own casing and their own words — `pending` / `SUCCESS` / `on_hold` /
 * `ON_HOLD` / `BOOK_FAILED_AFTER_PAYMENT`. Every row the Booking tab renders
 * runs through normalizeStatus() first, so one filter row and one status pill
 * can drive all five panels.
 */

// Display states. `tone` picks the pill colour in Booking.css.
export const STATUS_META = {
  confirmed: { label: "Confirmed", tone: "ok" },
  booked: { label: "Booked", tone: "ok" },
  replied: { label: "Replied", tone: "ok" },
  // Shop orders move Pending → Processing → Delivered. Delivered is its own
  // state rather than "Confirmed": a confirmed order and one already in your
  // hands are not the same news.
  delivered: { label: "Delivered", tone: "ok" },
  pending: { label: "Pending", tone: "warn" },
  processing: { label: "Processing", tone: "info" },
  hold: { label: "On Hold", tone: "info" },
  cancelled: { label: "Cancelled", tone: "stop" },
  failed: { label: "Failed", tone: "stop" },
  unknown: { label: "Unknown", tone: "muted" },
};

// Raw provider value (upper-cased) → display state.
const MAPS = {
  quotation: {
    PENDING: "pending",
    REPLIED: "replied",
    BOOKED: "booked",
    ACCEPTED: "booked",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
    REJECTED: "cancelled",
  },
  flight: {
    CONFIRMED: "confirmed",
    SUCCESS: "confirmed",
    TICKETED: "confirmed",
    ON_HOLD: "hold",
    HOLD: "hold",
    PENDING: "pending",
    IN_PROGRESS: "pending",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
    FAILED: "failed",
    ABORTED: "failed",
  },
  cab: {
    SUCCESS: "confirmed",
    CONFIRMED: "confirmed",
    PENDING: "pending",
    IN_PROGRESS: "pending",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
    FAILED: "failed",
  },
  hotel: {
    SUCCESS: "confirmed",
    CONFIRMED: "confirmed",
    ON_HOLD: "hold",
    PAYMENT_SUCCESS: "pending",
    PAYMENT_PENDING: "pending",
    IN_PROGRESS: "pending",
    PENDING: "pending",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
    FAILED: "failed",
    ABORTED: "failed",
    PAYMENT_FAILED: "failed",
    BOOK_FAILED_AFTER_PAYMENT: "failed",
  },
  insurance: {
    SUCCESS: "confirmed",
    CONFIRMED: "confirmed",
    ISSUED: "confirmed",
    PENDING: "pending",
    PAYMENT_PENDING: "pending",
    IN_PROGRESS: "pending",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
    FAILED: "failed",
  },
  // The store's Order.status enum is exactly ["Pending", "Processing",
  // "Delivered", "Cancel"] — note "Cancel", not "Cancelled". The other two
  // spellings are here so a later widening of that enum still lands somewhere
  // sensible rather than falling through to "unknown".
  shop: {
    PENDING: "pending",
    PROCESSING: "processing",
    DELIVERED: "delivered",
    CANCEL: "cancelled",
    CANCELLED: "cancelled",
    CANCELED: "cancelled",
  },
};

// Where the generic display label loses information the user needs.
const LABEL_OVERRIDES = {
  hotel: {
    PAYMENT_SUCCESS: "Awaiting Voucher",
    BOOK_FAILED_AFTER_PAYMENT: "Failed After Payment",
    PAYMENT_FAILED: "Payment Failed",
  },
  insurance: {
    SUCCESS: "Policy Issued",
    ISSUED: "Policy Issued",
  },
  flight: {
    ON_HOLD: "Seat Held",
  },
};

const titleCase = (value) =>
  String(value)
    .toLowerCase()
    .split(/[\s_-]+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");

/**
 * @param {string} raw    provider status, any casing
 * @param {string} source one of: quotation | flight | cab | hotel | insurance
 * @returns {{key: string, label: string, tone: string, raw: string}}
 */
export const normalizeStatus = (raw, source) => {
  const value = String(raw || "").trim().toUpperCase();
  const key = MAPS[source]?.[value] || (value ? "unknown" : "pending");
  const meta = STATUS_META[key] || STATUS_META.unknown;
  const label =
    LABEL_OVERRIDES[source]?.[value] ||
    (key === "unknown" && value ? titleCase(value) : meta.label);

  return { key, label, tone: meta.tone, raw: value };
};

// Pills shown even at zero, so the row does not jump around as data loads.
const CANONICAL_FILTERS = {
  quotation: ["pending", "replied", "booked", "cancelled"],
  travel: ["confirmed", "pending", "hold", "cancelled"],
  shop: ["pending", "processing", "delivered", "cancelled"],
};

/**
 * Build the status filter row for a panel: the canonical pills for that panel
 * plus any extra state the data actually contains (a failed hotel booking, say),
 * each with its count.
 *
 * @param {string}   set      "quotation" or "travel"
 * @param {Array}    items    rows already rendered by the panel
 * @param {Function} getKey   row → normalized status key
 */
export const buildStatusFilters = (set, items, getKey) => {
  const counts = new Map();
  items.forEach((item) => {
    const key = getKey(item);
    counts.set(key, (counts.get(key) || 0) + 1);
  });

  const canonical = CANONICAL_FILTERS[set] || CANONICAL_FILTERS.travel;
  const extra = [...counts.keys()].filter((key) => !canonical.includes(key));

  return [
    { key: "all", label: "All", count: items.length },
    ...[...canonical, ...extra].map((key) => ({
      key,
      label: STATUS_META[key]?.label || titleCase(key),
      count: counts.get(key) || 0,
    })),
  ];
};

export default normalizeStatus;
