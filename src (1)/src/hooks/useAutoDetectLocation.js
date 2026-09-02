import { useEffect } from "react";
import { useDispatch } from "react-redux";
import {
  setDetectedLocation,
  hasUserChosenLocation,
} from "../redux/locationSlice";
import { detectCurrentCity } from "../utils/detectCurrentCity";
import citiesData from "../data/citiesData";

/** City labels the site serves, used to map a geocoded place onto a real listing. */
const KNOWN_CITIES = (() => {
  const list = new Set();
  Object.values(citiesData).forEach((venues) => {
    venues.forEach((venue) => {
      list.add(venue.replace(/^Wedding Venues\s*/i, "").trim());
    });
  });
  [
    "Delhi NCR",
    "Mumbai",
    "Bangalore",
    "Chennai",
    "Pune",
    "Jaipur",
    "Kolkata",
    "Hyderabad",
    "Ahmedabad",
    "Goa",
    "Udaipur",
    "Nagpur",
    "Dehradun",
    "Thane",
    "Surat",
    "Vadodara",
    "Raipur",
    "Mysore",
    "Hubli",
  ].forEach((city) => list.add(city));
  return Array.from(list);
})();

/**
 * Detect the visitor's city on load and set it as the active location.
 *
 * Runs once per session and only when the visitor has not picked a city by
 * hand — a manual choice always wins. Failures (permission denied, offline,
 * geocoder down) are swallowed: the header simply falls back to "Select
 * Location" and the modal is still there to choose from.
 */
const useAutoDetectLocation = () => {
  const dispatch = useDispatch();

  useEffect(() => {
    if (hasUserChosenLocation()) return;

    // Don't re-prompt on every route change within the same tab
    if (sessionStorage.getItem("location_autodetected") === "1") return;

    let cancelled = false;

    (async () => {
      try {
        const { city } = await detectCurrentCity(KNOWN_CITIES);
        if (cancelled || !city) return;
        sessionStorage.setItem("location_autodetected", "1");
        dispatch(setDetectedLocation(city));
      } catch {
        // Silent by design — auto-detection must never interrupt page load.
        sessionStorage.setItem("location_autodetected", "1");
      }
    })();

    return () => {
      cancelled = true;
    };
  }, [dispatch]);
};

export default useAutoDetectLocation;
