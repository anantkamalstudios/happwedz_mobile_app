import { useState } from "react";
import { ChevronLeft, ChevronRight } from "lucide-react";

const DAY_MS = 86400000;
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];

const toKey = (date) => {
  const d = new Date(date);
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
};
const label = (date) => {
  const d = new Date(date);
  return `${WEEKDAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${d.getDate()}`;
};
const startOfDay = (value) => {
  const d = new Date(value);
  d.setHours(0, 0, 0, 0);
  return d;
};

/**
 * Date strip above the results, matching TripJack's behaviour.
 *
 * "Fetch Fare" re-runs the search for that date and replaces the list — it does
 * not display a price in the strip. Showing a price would mean an extra probe
 * search per date on top of the search that loads the results, so the label
 * stays put and one click does one thing.
 */
export default function FareDateStrip({
  searchParams,
  onPickDate,
  pendingDate = null,
  visibleDays = 7,
}) {
  const [offset, setOffset] = useState(0);

  const today = startOfDay(new Date());
  const anchor = searchParams?.departureDate ? startOfDay(searchParams.departureDate) : today;

  // Centre on the selected date, but never open the window on a past day —
  // TripJack's strip starts at today, and the API rejects past travel dates.
  const desiredStart = anchor.getTime() + (offset - Math.floor(visibleDays / 2)) * DAY_MS;
  const start = Math.max(desiredStart, today.getTime());
  const days = Array.from({ length: visibleDays }, (_, i) =>
    startOfDay(new Date(start + i * DAY_MS)),
  );
  const canGoBack = start > today.getTime();

  return (
    <div className="fc-datestrip">
      <button
        className="fc-datestrip-nav"
        onClick={() => setOffset((o) => o - visibleDays)}
        disabled={!canGoBack}
        aria-label="Earlier dates"
      >
        <ChevronLeft size={18} />
      </button>

      <div className="fc-datestrip-days">
        {days.map((day) => {
          const key = toKey(day);
          const isSelected = key === toKey(anchor);
          const isPending = pendingDate === key;

          return (
            <button
              key={key}
              type="button"
              className={`fc-datestrip-day ${isSelected ? "is-selected" : ""}`}
              onClick={() => onPickDate?.(key)}
              disabled={isPending}
            >
              <span className="fc-datestrip-label">{label(day)}</span>
              <span className="fc-datestrip-fetch">
                {isPending ? "Loading…" : "Fetch Fare"}
              </span>
            </button>
          );
        })}
      </div>

      <button
        className="fc-datestrip-nav"
        onClick={() => setOffset((o) => o + visibleDays)}
        aria-label="Later dates"
      >
        <ChevronRight size={18} />
      </button>
    </div>
  );
}
