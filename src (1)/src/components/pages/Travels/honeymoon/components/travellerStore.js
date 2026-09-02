/**
 * Storage helpers for the Passenger Details traveller picker.
 *
 * The list itself is derived server-side from past bookings, so the panel's
 * "Add this to My Travellers List" checkbox works as a suppression switch:
 * unticking someone keeps them out of the picker on later bookings. That
 * preference is per browser — it is a convenience, never booking data.
 */
export const SUPPRESS_STORE = 'hw_traveller_hidden';

export const loadSuppressed = () => {
  try {
    return new Set(JSON.parse(localStorage.getItem(SUPPRESS_STORE) || '[]'));
  } catch {
    return new Set();
  }
};

export const saveSuppressed = (set) => {
  try {
    localStorage.setItem(SUPPRESS_STORE, JSON.stringify(Array.from(set)));
  } catch {
    // Private windows and blocked site data must not break the form.
  }
};

/** Same identity rule the backend dedupes on. */
export const travellerKey = (first, last, dob) =>
  `${String(first || '').trim()}|${String(last || '').trim()}|${dob || ''}`.toUpperCase();
