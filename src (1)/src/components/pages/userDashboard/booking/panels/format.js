import { formatDate, formatDateTime } from "../../../../../utils/dateFormat";

/** ₹ 1,24,600.00 — falls back to a dash rather than printing ₹NaN. */
export const money = (value, currency = "INR") => {
  const amount = Number(value);
  if (!Number.isFinite(amount)) return "—";
  try {
    return new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: currency || "INR",
      maximumFractionDigits: 2,
    }).format(amount);
  } catch {
    return `₹ ${amount.toLocaleString("en-IN")}`;
  }
};

export const day = (value) => formatDate(value, "—");

export const dayTime = (value) => formatDateTime(value, { fallback: "—" });

/** Whole nights between two dates, or null when either is unusable. */
export const nightsBetween = (from, to) => {
  const start = new Date(from);
  const end = new Date(to);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return null;
  const nights = Math.round((end - start) / 86400000);
  return nights > 0 ? nights : null;
};

/** "2 Adults · 1 Child" */
export const paxLabel = ({ adults = 0, children = 0, infants = 0 }) =>
  [
    adults > 0 && `${adults} Adult${adults > 1 ? "s" : ""}`,
    children > 0 && `${children} Child${children > 1 ? "ren" : ""}`,
    infants > 0 && `${infants} Infant${infants > 1 ? "s" : ""}`,
  ]
    .filter(Boolean)
    .join(" · ") || "—";
