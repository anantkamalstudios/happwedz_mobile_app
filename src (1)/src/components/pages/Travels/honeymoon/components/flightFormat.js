/**
 * Date, duration and baggage formatting shared by the itinerary and review
 * steps. Kept out of the component file so fast refresh still works there.
 */
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

export const formatDuration = (minutes) =>
  `${Math.floor(minutes / 60)}h ${String(minutes % 60).padStart(2, '0')}m`;

/** "Aug 28, Fri, 08:15" */
export const stamp = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${WEEKDAYS[d.getDay()]}, ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

/** "Fri, Aug 28th 2026" */
export const longDate = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  const n = d.getDate();
  const ord = n % 10 === 1 && n !== 11 ? 'st' : n % 10 === 2 && n !== 12 ? 'nd' : n % 10 === 3 && n !== 13 ? 'rd' : 'th';
  return `${WEEKDAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${n}${ord} ${d.getFullYear()}`;
};

/** "01/08/2014" — the review table's date format. */
export const shortDob = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return value || '';
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
};

/** Airborne time plus every connection — never the sum of `duration` alone. */
export const journeyMinutes = (trip) =>
  (trip?.sI || []).reduce((n, x) => n + (x.duration || 0) + (x.cT || 0), 0);

/** "(Adult) Check-in : 15 Kg, Cabin : 7 Kg" — the portal's per-leg line. */
export const baggageLine = (tripFare) => {
  const bags = tripFare?.fd?.ADULT?.bI;
  if (!bags?.iB && !bags?.cB) return '';
  return `(Adult) Check-in : ${bags.iB || 'NA'}, Cabin : ${bags.cB || 'NA'}`;
};
