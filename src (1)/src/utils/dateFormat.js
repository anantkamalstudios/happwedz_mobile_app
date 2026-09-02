// Central date formatting helpers.
// Every user-facing date in the app renders as DD/MM/YYYY.
// Time parts are preserved where they were shown before.

const pad = (n) => String(n).padStart(2, "0");

const WEEKDAYS_SHORT = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const WEEKDAYS_LONG = [
  "Sunday",
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
];

/**
 * Parse anything we get from the API / pickers into a local Date.
 * Plain date strings (YYYY-MM-DD, DD/MM/YYYY, DD-MM-YYYY) are read as local
 * dates so they never shift a day due to UTC parsing.
 * Returns null when the value is empty or unparseable.
 */
export const toDate = (value) => {
  if (value === null || value === undefined || value === "") return null;
  if (value instanceof Date) return isNaN(value.getTime()) ? null : value;

  // dayjs / moment objects
  if (typeof value === "object" && typeof value.toDate === "function") {
    const d = value.toDate();
    return d instanceof Date && !isNaN(d.getTime()) ? d : null;
  }

  if (typeof value === "number") {
    const d = new Date(value);
    return isNaN(d.getTime()) ? null : d;
  }

  if (typeof value === "string") {
    const str = value.trim();
    if (!str) return null;

    // YYYY-MM-DD (optionally with a time part)
    const iso = str.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?)?/);
    if (iso && !/[zZ]|[+-]\d{2}:?\d{2}$/.test(str)) {
      return new Date(
        Number(iso[1]),
        Number(iso[2]) - 1,
        Number(iso[3]),
        Number(iso[4] || 0),
        Number(iso[5] || 0),
        Number(iso[6] || 0)
      );
    }

    // DD/MM/YYYY or DD-MM-YYYY
    const dmy = str.match(/^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$/);
    if (dmy) {
      return new Date(Number(dmy[3]), Number(dmy[2]) - 1, Number(dmy[1]));
    }

    const d = new Date(str);
    return isNaN(d.getTime()) ? null : d;
  }

  return null;
};

/** DD/MM/YYYY */
export const formatDate = (value, fallback = "") => {
  const d = toDate(value);
  if (!d) return fallback;
  return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()}`;
};

/** h:mm AM/PM (or h:mm:ss AM/PM with { seconds: true }) */
export const formatTime = (value, { seconds = false, fallback = "" } = {}) => {
  const d = toDate(value);
  if (!d) return fallback;
  const hours24 = d.getHours();
  const hours12 = hours24 % 12 || 12;
  const suffix = hours24 < 12 ? "AM" : "PM";
  const base = `${hours12}:${pad(d.getMinutes())}`;
  return seconds
    ? `${base}:${pad(d.getSeconds())} ${suffix}`
    : `${base} ${suffix}`;
};

/** HH:mm on a 24 hour clock */
export const formatTime24 = (value, fallback = "") => {
  const d = toDate(value);
  if (!d) return fallback;
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

/** DD/MM/YYYY, h:mm AM/PM */
export const formatDateTime = (value, { seconds = false, fallback = "" } = {}) => {
  const d = toDate(value);
  if (!d) return fallback;
  return `${formatDate(d)}, ${formatTime(d, { seconds })}`;
};

/** Mon, DD/MM/YYYY  —  use { long: true } for "Monday, DD/MM/YYYY" */
export const formatDateWithWeekday = (value, { long = false, fallback = "" } = {}) => {
  const d = toDate(value);
  if (!d) return fallback;
  const names = long ? WEEKDAYS_LONG : WEEKDAYS_SHORT;
  return `${names[d.getDay()]}, ${formatDate(d)}`;
};

/**
 * YYYY-MM-DD in local time. For API payloads and <input type="date"> values
 * only — never for display.
 */
export const toApiDate = (value) => {
  const d = toDate(value);
  if (!d) return "";
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};

export default formatDate;
