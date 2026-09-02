import { createSlice } from "@reduxjs/toolkit";

const invalidKeywords = [
  "hotel", "banquet", "lawn", "resort", "hall", "planner", 
  "photographer", "makeup", "decorator", "mehendi", "mandapam", 
  "vendor", "star", "venue", "catering", "chaat", "jewellery", 
  "lehenga", "sherwani", "invitation", "favor", "sangeet", "dj", "suite"
];

const isInvalidCity = (val) => {
  if (!val || typeof val !== "string") return true;
  const lower = val.toLowerCase();
  return invalidKeywords.some((kw) => lower.includes(kw));
};

const STORAGE_KEY = "location";
const STORAGE_VERSION_KEY = "location_version";
/** "user" = picked by hand, "auto" = geolocated. Only "user" blocks re-detection. */
const STORAGE_SOURCE_KEY = "location_source";

/**
 * Bump this whenever previously stored locations can no longer be trusted.
 *
 * v2: until the setBrowsingLocation fix, merely opening a city URL
 * (/wedding-venues/pune, a Pune card on the /venues page, a shared link)
 * silently overwrote the saved city. Every existing visitor can therefore be
 * pinned to a city they never chose, so the stored value is cleared once.
 */
const STORAGE_VERSION = "2";

const readStorage = (key) => {
  try {
    return localStorage.getItem(key);
  } catch {
    return null;
  }
};

const writeStorage = (key, value) => {
  try {
    localStorage.setItem(key, value);
  } catch {
    /* storage unavailable (private mode, quota) - selection just won't persist */
  }
};

const removeStorage = (key) => {
  try {
    localStorage.removeItem(key);
  } catch {
    /* nothing to do */
  }
};

const getInitialLocation = () => {
  // One-time reset of values written by the old URL-overwrites-your-city bug
  if (readStorage(STORAGE_VERSION_KEY) !== STORAGE_VERSION) {
    removeStorage(STORAGE_KEY);
    removeStorage(STORAGE_SOURCE_KEY);
    writeStorage(STORAGE_VERSION_KEY, STORAGE_VERSION);
    return null;
  }

  const saved = readStorage(STORAGE_KEY);
  if (saved && !isInvalidCity(saved)) {
    return saved;
  }
  if (saved) {
    removeStorage(STORAGE_KEY);
  }
  return null;
};

/** True once the visitor has picked a city by hand - auto-detection must not override it. */
export const hasUserChosenLocation = () =>
  readStorage(STORAGE_SOURCE_KEY) === "user" && !!readStorage(STORAGE_KEY);

const initialState = {
  selectedLocation: getInitialLocation(),
};

const locationSlice = createSlice({
  name: "location",
  initialState,
  reducers: {
    setLocation: (state, action) => {
      if (action.payload && !isInvalidCity(action.payload)) {
        state.selectedLocation = action.payload;
        writeStorage(STORAGE_KEY, action.payload);
        writeStorage(STORAGE_SOURCE_KEY, "user");
      } else if (!action.payload) {
        state.selectedLocation = null;
        removeStorage(STORAGE_KEY);
        removeStorage(STORAGE_SOURCE_KEY);
      }
    },
    /**
     * Apply a geolocated city. Persisted so every page of the session agrees,
     * but tagged "auto" so the next visit re-detects instead of going stale -
     * and so it never shadows a city the visitor picked themselves.
     */
    setDetectedLocation: (state, action) => {
      if (action.payload && !isInvalidCity(action.payload)) {
        state.selectedLocation = action.payload;
        writeStorage(STORAGE_KEY, action.payload);
        writeStorage(STORAGE_SOURCE_KEY, "auto");
      }
    },
    /**
     * Reflect the city currently being browsed (derived from the URL slug).
     *
     * Deliberately does NOT touch localStorage: landing on /wedding-venues/pune
     * from a search result or shared link should not make Pune the visitor's
     * saved city forever. Only an explicit pick via setLocation persists.
     */
    setBrowsingLocation: (state, action) => {
      if (action.payload && !isInvalidCity(action.payload)) {
        state.selectedLocation = action.payload;
      }
    },
    clearLocation: (state) => {
      state.selectedLocation = null;
      removeStorage(STORAGE_KEY);
      writeStorage(STORAGE_SOURCE_KEY, "user");
    },
  },
});

export const {
  setLocation,
  setBrowsingLocation,
  setDetectedLocation,
  clearLocation,
} = locationSlice.actions;
export default locationSlice.reducer;
