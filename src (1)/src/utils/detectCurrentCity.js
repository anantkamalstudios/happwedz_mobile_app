/**
 * Detect the visitor's current city from the browser's geolocation.
 *
 * Uses the same OpenStreetMap / Nominatim service the map view already relies on,
 * then maps the reverse-geocoded place onto a city the site actually serves.
 */

/** Cities/districts that HappyWedz groups under the "Delhi NCR" listing. */
const DELHI_NCR_ALIASES = [
  "delhi",
  "new delhi",
  "old delhi",
  "central delhi",
  "south delhi",
  "north delhi",
  "east delhi",
  "west delhi",
  "gurugram",
  "gurgaon",
  "noida",
  "greater noida",
  "gautam buddha nagar",
  "ghaziabad",
  "faridabad",
  "sonipat",
  "bahadurgarh",
];

/** Reverse-geocoded names that differ from the label used on the site. */
const CITY_ALIASES = {
  bengaluru: "Bangalore",
  "bengaluru urban": "Bangalore",
  mumbai: "Mumbai",
  "mumbai suburban": "Mumbai",
  "greater mumbai": "Mumbai",
  "navi mumbai": "Mumbai",
  kalyan: "Thane",
  "pune city": "Pune",
  "pimpri-chinchwad": "Pune",
  chennai: "Chennai",
  kolkata: "Kolkata",
  mysuru: "Mysore",
  hubballi: "Hubli",
  nasik: "Nashik",
  "nashik road": "Nashik",
  vadodara: "Vadodara",
  puducherry: "Pondicherry",
  panaji: "Goa",
  "north goa": "Goa",
  "south goa": "Goa",
};

const normalize = (value) =>
  (value || "")
    .toString()
    .toLowerCase()
    .replace(/\bdistricts?\b/gi, "")
    .replace(/\bdivision\b/gi, "")
    .replace(/\btehsil\b/gi, "")
    .replace(/\bcity\b/gi, "")
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();

/**
 * Administrative wrappers Nominatim and the city API return as if they were
 * places: "Pune Division", "Nashik District", "Nashik Subdistrict". Never show
 * these to the visitor - strip down to the bare place name.
 */
const ADMIN_SUFFIX = /\s*\b(sub[-\s]?district|district|division|tehsil|taluka|subdivision|municipal corporation|metropolitan region|urban agglomeration)\b\s*$/i;

export const stripAdminSuffix = (value) => {
  let out = (value || "").toString().trim();
  let previous;
  do {
    previous = out;
    out = out.replace(ADMIN_SUFFIX, "").trim();
  } while (out !== previous && out);
  return out || (value || "").toString().trim();
};

/** True for names that are only an administrative wrapper, e.g. "Pune Division". */
export const isAdminAreaName = (value) =>
  ADMIN_SUFFIX.test((value || "").toString().trim());

const titleCase = (value) =>
  (value || "")
    .toString()
    .trim()
    .split(/\s+/)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");

/** A fix this tight is unambiguous at city level - stop refining and use it. */
const GOOD_ENOUGH_ACCURACY_M = 1500;

/**
 * Stop waiting once no better reading has arrived for this long. Refinement is
 * driven by GPS/Wi-Fi converging; when the only source is IP lookup there is
 * nothing to converge on and every extra second is dead time.
 */
const STALL_MS = 2500;

/** Hard ceiling, only reached while readings are still genuinely improving. */
const REFINE_WINDOW_MS = 10000;

const toCoords = (position) => ({
  lat: position.coords.latitude,
  lng: position.coords.longitude,
  accuracy: position.coords.accuracy,
});

const describeError = (error) => {
  if (error.code === error.PERMISSION_DENIED) {
    return new Error(
      "Location access is blocked. Allow it in your browser settings, or pick a city below."
    );
  }
  if (error.code === error.TIMEOUT) {
    return new Error("Locating you took too long. Please try again.");
  }
  return new Error("We couldn't get your location. Please pick a city below.");
};

/**
 * Ask the browser where we are. Rejects with a message safe to show the user.
 *
 * `precise` is used for the explicit "Use my current location" click. The first
 * callback from a high-accuracy request is routinely a coarse Wi-Fi or IP fix
 * that the device then refines over the next few seconds - taking it at face
 * value is how someone in Nashik ends up pinned to their ISP's city. So we
 * watch instead of asking once, keep the tightest reading, and stop as soon as
 * it is good enough or the refine window closes.
 *
 * Passive auto-detection on page load stays cheap and cache-friendly.
 */
const getCoordinates = ({ precise = false } = {}) =>
  new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("Your browser doesn't support location detection."));
      return;
    }

    if (!precise) {
      navigator.geolocation.getCurrentPosition(
        (position) => resolve(toCoords(position)),
        (error) => reject(describeError(error)),
        { enableHighAccuracy: false, timeout: 12000, maximumAge: 5 * 60 * 1000 }
      );
      return;
    }

    let best = null;
    let watchId = null;
    let stallTimer = null;
    let ceilingTimer = null;
    let settled = false;

    const stop = () => {
      if (watchId !== null) navigator.geolocation.clearWatch(watchId);
      if (stallTimer !== null) clearTimeout(stallTimer);
      if (ceilingTimer !== null) clearTimeout(ceilingTimer);
    };

    const settle = () => {
      if (settled) return;
      settled = true;
      stop();
      if (best) resolve(toCoords(best));
      else reject(new Error("Locating you took too long. Please try again."));
    };

    /** Restarted on every improvement, so we only wait while progress is real. */
    const armStallTimer = () => {
      if (stallTimer !== null) clearTimeout(stallTimer);
      stallTimer = setTimeout(settle, STALL_MS);
    };

    watchId = navigator.geolocation.watchPosition(
      (position) => {
        const improved = !best || position.coords.accuracy < best.coords.accuracy;
        const isFirst = !best;
        if (improved) best = position;
        if (best.coords.accuracy <= GOOD_ENOUGH_ACCURACY_M) {
          settle();
          return;
        }
        // Both clocks start at the first fix, never before: until the visitor
        // answers the permission prompt no callback fires at all, and timing out
        // a dialog that is still on screen would reject a grant about to happen.
        if (isFirst) ceilingTimer = setTimeout(settle, REFINE_WINDOW_MS);
        if (improved) armStallTimer();
      },
      (error) => {
        // A later error doesn't invalidate a reading we already have
        if (best) {
          settle();
          return;
        }
        if (settled) return;
        settled = true;
        stop();
        reject(describeError(error));
      },
      { enableHighAccuracy: true, timeout: 20000, maximumAge: 0 }
    );

    // No timers here - a pending permission prompt has no deadline of ours.
    // navigator's own `timeout` below covers "nothing ever arrives".
  });

/** Upper bound on the reverse-geocode request. */
const GEOCODE_TIMEOUT_MS = 6000;

/** Turn coordinates into an ordered list of place names, most specific first. */
const reverseGeocode = async ({ lat, lng }, { precise = false } = {}) => {
  // zoom 12 resolves the actual town/suburb; zoom 10 can stop at the district
  const zoom = precise ? 12 : 10;
  const url =
    `https://nominatim.openstreetmap.org/reverse?format=jsonv2` +
    `&lat=${lat}&lon=${lng}&zoom=${zoom}&addressdetails=1&accept-language=en`;

  // Nominatim is a free shared service and can stall; don't let it hold the
  // button hostage after we already have coordinates.
  const controller = new AbortController();
  const abortTimer = setTimeout(() => controller.abort(), GEOCODE_TIMEOUT_MS);

  let res;
  try {
    res = await fetch(url, { signal: controller.signal });
  } catch {
    throw new Error("Location lookup timed out. Please pick a city below.");
  } finally {
    clearTimeout(abortTimer);
  }
  if (!res.ok) throw new Error("Location lookup failed. Please pick a city below.");

  const data = await res.json();
  const address = data?.address || {};

  const ordered = [
    address.city,
    address.town,
    address.municipality,
    address.village,
    address.city_district,
    address.suburb,
    address.county,
    address.state_district,
    address.state,
    address.country,
  ].filter(Boolean);

  // "Pune Division" / "Nashik District" are containers, not places the visitor
  // is in - keep them as a last resort, never ahead of a real settlement name.
  const settlements = ordered.filter((name) => !isAdminAreaName(name));
  const adminAreas = ordered.filter((name) => isAdminAreaName(name));
  return [...settlements, ...adminAreas];
};

/**
 * Match a reverse-geocoded place name against the cities the site serves.
 * @param {string[]} candidates - place names, most specific first
 * @param {string[]} knownCities - city labels shown in the location modal
 * @returns {string|null} the site's label for the city, or null when unmatched
 */
export const matchKnownCity = (candidates = [], knownCities = []) => {
  const knownByNormalized = new Map();
  knownCities.forEach((city) => {
    // "Pune Division" normalizes to "pune" and would otherwise shadow "Pune"
    if (isAdminAreaName(city)) return;
    const key = normalize(city);
    // First entry wins, so curated labels beat anything appended later
    if (key && !knownByNormalized.has(key)) knownByNormalized.set(key, city);
  });

  for (const candidate of candidates) {
    const key = normalize(candidate);
    if (!key) continue;

    if (DELHI_NCR_ALIASES.includes(key)) return "Delhi NCR";

    const aliased = CITY_ALIASES[key];
    if (aliased) return aliased;

    if (knownByNormalized.has(key)) return knownByNormalized.get(key);
  }

  // Looser pass: "Pune Metropolitan Region" should still resolve to "Pune"
  for (const candidate of candidates) {
    const key = normalize(candidate);
    if (key.length < 4) continue;
    for (const [knownKey, knownCity] of knownByNormalized) {
      if (knownKey.length < 4) continue;
      if (key.includes(knownKey) || knownKey.includes(key)) return knownCity;
    }
  }

  return null;
};

/**
 * Detect the visitor's city.
 * @param {string[]} knownCities - city labels the site serves, used for matching
 * @returns {Promise<{ city: string, matched: boolean, coords: {lat:number,lng:number} }>}
 * @throws {Error} with a message intended for display
 */
/**
 * Above this radius the browser almost certainly fell back to IP lookup, which
 * resolves to the ISP's gateway - often a different city entirely. Better to
 * say we don't know than to silently pin the visitor to the wrong city.
 */
const IP_FALLBACK_ACCURACY_M = 50000;

/**
 * Wi-Fi and GPS fixes land well inside this. A reading looser than this came
 * from IP lookup, which resolves to the ISP's gateway and is routinely a
 * different city - so the result is offered for confirmation, not applied.
 */
const COARSE_ACCURACY_M = 5000;

export const detectCurrentCity = async (knownCities = [], options = {}) => {
  const coords = await getCoordinates(options);

  if (
    options.precise &&
    typeof coords.accuracy === "number" &&
    coords.accuracy > IP_FALLBACK_ACCURACY_M
  ) {
    throw new Error(
      "Your browser could only place you within a very wide area, so we can't tell your city. Turn on device location (GPS/Wi-Fi) or pick a city below."
    );
  }

  const candidates = await reverseGeocode(coords, options);

  if (candidates.length === 0) {
    throw new Error("We couldn't identify your city. Please pick one below.");
  }

  // Anything looser than this is very likely an IP-derived fix pointing at the
  // ISP's gateway, so the city is a guess the visitor should get to confirm.
  const approximate =
    typeof coords.accuracy !== "number" ||
    coords.accuracy > COARSE_ACCURACY_M;

  const matched = matchKnownCity(candidates, knownCities);
  if (matched) return { city: matched, matched: true, approximate, coords };

  // Unknown to our list - still usable, listings filter on the city name.
  // Strip the administrative wrapper so the header reads "Pune", not
  // "Pune Division".
  return {
    city: titleCase(stripAdminSuffix(candidates[0])),
    matched: false,
    approximate,
    coords,
  };
};

export default detectCurrentCity;
