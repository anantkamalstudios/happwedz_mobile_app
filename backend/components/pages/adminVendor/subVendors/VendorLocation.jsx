import React, { useState, useEffect, useRef, useCallback } from "react";
import axios from "axios";
import "leaflet/dist/leaflet.css";
import {
  MapContainer,
  TileLayer,
  Marker,
  useMapEvents,
  useMap,
} from "react-leaflet";
import L from "leaflet";

delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "/images/location.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

const NOMINATIM_HEADERS = {
  "User-Agent": "HappyWedz/1.0 (vendor location)",
  Accept: "application/json",
};

async function searchLocations(query) {
  const q = query?.trim();
  if (!q || q.length < 3) return [];
  const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
    q,
  )}&limit=6&addressdetails=1`;
  const res = await fetch(url, { headers: NOMINATIM_HEADERS });
  if (!res.ok) return [];
  const data = await res.json();
  return Array.isArray(data) ? data : [];
}

function MapRecenter({ center, zoom }) {
  const map = useMap();
  useEffect(() => {
    if (center && center[0] != null && center[1] != null) {
      map.setView(center, zoom);
    }
  }, [center, zoom, map]);
  return null;
}

const VendorLocation = ({ formData, setFormData, onSave }) => {
  const city =
    (formData.location && formData.location.city) || formData.city || "";
  const location = formData.location || {
    address: "",
    state: "",
    country: "India",
    pincode: "",
    latitude: "",
    longitude: "",
    landmark: "",
    serviceAreas: [],
  };

  const [countries, setCountries] = useState([]);
  const [selectedCountry, setSelectedCountry] = useState(
    location.country || "India",
  );
  const [cities, setCities] = useState([]);
  const [cityInput, setCityInput] = useState(city || "");
  const [showSuggestions, setShowSuggestions] = useState(false);

  const [locationSearch, setLocationSearch] = useState("");
  const [searchResults, setSearchResults] = useState([]);
  const [searchLoading, setSearchLoading] = useState(false);
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const searchDebounceRef = useRef(null);
  const searchWrapRef = useRef(null);

  const [markerPos, setMarkerPos] = useState(() => {
    const lat = parseFloat(location.latitude);
    const lng = parseFloat(location.longitude);
    return isFinite(lat) && isFinite(lng) ? { lat, lng } : null;
  });

  useEffect(() => {
    const nextCity =
      (formData.location && formData.location.city) || formData.city || "";
    setCityInput(nextCity);
  }, [formData.location?.city, formData.city]);

  useEffect(() => {
    axios.get("https://restcountries.com/v3.1/all?fields=name").then((res) => {
      const sorted = res.data
        .map((c) => c.name.common)
        .sort((a, b) => a.localeCompare(b));
      setCountries(sorted);
    });
  }, []);

  useEffect(() => {
    if (!selectedCountry) return;
    axios
      .post("https://countriesnow.space/api/v0.1/countries/cities", {
        country: selectedCountry,
      })
      .then((res) => {
        setCities(res.data?.data || []);
      })
      .catch(() => setCities([]));
    handleInputChange("country", selectedCountry);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCountry]);

  useEffect(() => {
    const lat = parseFloat(location.latitude);
    const lng = parseFloat(location.longitude);
    if (isFinite(lat) && isFinite(lng)) setMarkerPos({ lat, lng });
  }, [location.latitude, location.longitude]);

  useEffect(() => {
    const onDocClick = (e) => {
      if (searchWrapRef.current && !searchWrapRef.current.contains(e.target)) {
        setShowSearchDropdown(false);
      }
    };
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, []);

  const venueIdentity = (prev) => {
    const vm = prev.venue_master || prev.attributes?.venue_master;
    return vm?.identity || {};
  };

  const exactLocationText =
    location.exact_location_text ??
    venueIdentity(formData).exact_location_text ??
    "";
  const mapPinUrl =
    location.map_pin_url ?? venueIdentity(formData).map_pin_url ?? "";

  const patchVenueIdentityFields = (fields) => {
    setFormData((prev) => {
      const nextLocation = { ...(prev.location || {}), ...fields };
      const vm = prev.venue_master || prev.attributes?.venue_master;
      if (!vm) {
        return { ...prev, location: nextLocation };
      }
      const nextVm = {
        ...vm,
        identity: { ...(vm.identity || {}), ...fields },
      };
      return {
        ...prev,
        location: nextLocation,
        venue_master: nextVm,
        attributes: { ...(prev.attributes || {}), venue_master: nextVm },
      };
    });
  };

  const applyCoordinates = useCallback((lat, lng, extras = {}) => {
    setMarkerPos({ lat, lng });
    setFormData((prev) => ({
      ...prev,
      ...(extras.city ? { city: extras.city } : {}),
      location: {
        ...(prev.location || {}),
        latitude: String(lat),
        longitude: String(lng),
        ...(extras.address != null ? { address: extras.address } : {}),
        ...(extras.city != null ? { city: extras.city } : {}),
        ...(extras.state != null ? { state: extras.state } : {}),
        ...(extras.pincode != null ? { pincode: extras.pincode } : {}),
        ...(extras.country != null ? { country: extras.country } : {}),
      },
    }));
    if (extras.city) setCityInput(extras.city);
    if (extras.country) setSelectedCountry(extras.country);
  }, [setFormData]);

  const handleInputChange = (field, value) => {
    setFormData((prev) => ({
      ...prev,
      ...(field === "city" ? { city: value } : {}),
      location: {
        ...prev.location,
        [field]: value,
      },
    }));
  };

  const runLocationSearch = (query) => {
    if (searchDebounceRef.current) clearTimeout(searchDebounceRef.current);
    const q = query.trim();
    if (q.length < 3) {
      setSearchResults([]);
      setShowSearchDropdown(false);
      return;
    }
    searchDebounceRef.current = setTimeout(async () => {
      setSearchLoading(true);
      setShowSearchDropdown(true);
      try {
        const results = await searchLocations(q);
        setSearchResults(results);
      } catch {
        setSearchResults([]);
      } finally {
        setSearchLoading(false);
      }
    }, 450);
  };

  const selectSearchResult = (item) => {
    const lat = parseFloat(item.lat);
    const lng = parseFloat(item.lon);
    if (!isFinite(lat) || !isFinite(lng)) return;

    const addr = item.address || {};
    const display = item.display_name || "";
    const cityName =
      addr.city ||
      addr.town ||
      addr.village ||
      addr.state_district ||
      addr.county ||
      "";
    const stateName = addr.state || "";
    const pincode = addr.postcode || "";
    const countryName = addr.country || selectedCountry || "India";
    const street = [addr.house_number, addr.road, addr.suburb]
      .filter(Boolean)
      .join(", ");

    setLocationSearch(display);
    setShowSearchDropdown(false);
    setSearchResults([]);

    applyCoordinates(lat, lng, {
      address: street || display.split(",")[0] || location.address,
      city: cityName,
      state: stateName,
      pincode,
      country: countryName,
    });

    patchVenueIdentityFields({
      exact_location_text: display,
      map_pin_url: `https://www.google.com/maps?q=${lat},${lng}`,
    });
  };

  const DEFAULT_CENTER = [22.3511148, 78.6677428];
  const DEFAULT_ZOOM = 5;
  const SELECTED_ZOOM = 15;

  const mapCenter = markerPos
    ? [markerPos.lat, markerPos.lng]
    : DEFAULT_CENTER;
  const mapZoom = markerPos ? SELECTED_ZOOM : DEFAULT_ZOOM;

  const ClickMarker = () => {
    useMapEvents({
      click(e) {
        const { lat, lng } = e.latlng;
        applyCoordinates(lat, lng);
        patchVenueIdentityFields({
          map_pin_url: `https://www.google.com/maps?q=${lat},${lng}`,
        });
      },
    });
    return markerPos ? (
      <Marker position={[markerPos.lat, markerPos.lng]} />
    ) : null;
  };

  const filteredCities = cities.filter((c) =>
    c.toLowerCase().includes(cityInput.toLowerCase()),
  );

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Location & Service Areas</h4>

        {/* Search + map at top */}
        <div className="col-12 mb-3 position-relative" ref={searchWrapRef}>
          <label className="form-label fs-16 fw-semibold">
            Search location
          </label>
          <div className="d-flex flex-column flex-sm-row gap-2">
            <input
              type="text"
              className="form-control fs-14 flex-grow-1"
              value={locationSearch}
              onChange={(e) => {
                setLocationSearch(e.target.value);
                runLocationSearch(e.target.value);
              }}
              onFocus={() =>
                locationSearch.trim().length >= 3 && setShowSearchDropdown(true)
              }
              placeholder="Search venue, area, city, landmark…"
              autoComplete="off"
            />
            <button
              type="button"
              className="btn btn-primary fs-14 flex-shrink-0"
              style={{ minWidth: "100px" }}
              disabled={searchLoading || locationSearch.trim().length < 3}
              onClick={() => runLocationSearch(locationSearch)}
            >
              {searchLoading ? "Searching…" : "Search"}
            </button>
          </div>
          {showSearchDropdown && (
            <ul
              className="list-group position-absolute w-100 shadow-sm mt-1"
              style={{
                maxHeight: "220px",
                overflowY: "auto",
                zIndex: 1100,
              }}
            >
              {searchLoading ? (
                <li className="list-group-item text-muted fs-14">
                  Searching…
                </li>
              ) : searchResults.length > 0 ? (
                searchResults.map((item) => (
                  <li
                    key={item.place_id || `${item.lat}-${item.lon}`}
                    className="list-group-item list-group-item-action fs-14"
                    style={{ cursor: "pointer" }}
                    onMouseDown={(e) => e.preventDefault()}
                    onClick={() => selectSearchResult(item)}
                  >
                    {item.display_name}
                  </li>
                ))
              ) : locationSearch.trim().length >= 3 ? (
                <li className="list-group-item text-muted fs-14">
                  No locations found
                </li>
              ) : null}
            </ul>
          )}
          <p className="text-muted fs-12 mt-1 mb-0">
            Pick a result or click on the map below to set your pin.
          </p>
        </div>

        <div className="col-12 mb-4">
          <div
            className="border rounded overflow-hidden"
            style={{ height: 340, zIndex: 1 }}
          >
            <MapContainer
              center={mapCenter}
              zoom={mapZoom}
              scrollWheelZoom
              style={{ height: "100%", width: "100%" }}
            >
              <TileLayer
                attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>'
                url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
              />
              <MapRecenter center={mapCenter} zoom={mapZoom} />
              <ClickMarker />
            </MapContainer>
          </div>
          {markerPos && (
            <p className="text-muted fs-12 mt-2 mb-0">
              Pin: {markerPos.lat.toFixed(6)}, {markerPos.lng.toFixed(6)}
            </p>
          )}
        </div>

        <div className="row">
          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">Address *</label>
            <input
              type="text"
              className="form-control fs-14"
              value={location.address}
              onChange={(e) => handleInputChange("address", e.target.value)}
              placeholder="Enter address"
            />
          </div>

          <div className="col-md-6 mb-3">
            <label className="form-label fs-16 fw-semibold">Country *</label>
            <select
              className="form-select fs-14"
              value={selectedCountry}
              onChange={(e) => {
                setSelectedCountry(e.target.value);
                setCityInput("");
                handleInputChange("city", "");
              }}
            >
              {countries.length > 0 ? (
                countries.map((country, idx) => (
                  <option key={idx} value={country}>
                    {country}
                  </option>
                ))
              ) : (
                <option>Loading countries...</option>
              )}
            </select>
          </div>

          <div className="col-md-6 mb-3 position-relative">
            <label className="form-label fs-16 fw-semibold">City *</label>
            <input
              type="text"
              className="form-control fs-14"
              value={cityInput}
              onChange={(e) => {
                setCityInput(e.target.value);
                handleInputChange("city", e.target.value);
                setShowSuggestions(true);
              }}
              onBlur={() => setTimeout(() => setShowSuggestions(false), 200)}
              placeholder="Enter city"
              autoComplete="off"
            />
            {showSuggestions && cityInput && filteredCities.length > 0 && (
              <ul
                className="list-group position-absolute w-100 shadow-sm"
                style={{ maxHeight: "200px", overflowY: "auto", zIndex: 1000 }}
              >
                {filteredCities.slice(0, 15).map((c, idx) => (
                  <li
                    key={idx}
                    className="list-group-item list-group-item-action"
                    onClick={() => {
                      setCityInput(c);
                      handleInputChange("city", c);
                      setShowSuggestions(false);
                    }}
                    style={{ cursor: "pointer" }}
                  >
                    {c}
                  </li>
                ))}
              </ul>
            )}
          </div>

          <div className="col-md-4 mb-3">
            <label className="form-label fs-16 fw-semibold">State *</label>
            <input
              type="text"
              className="form-control fs-14"
              value={location.state}
              onChange={(e) => handleInputChange("state", e.target.value)}
              placeholder="Enter state"
            />
          </div>

          <div className="col-md-4 mb-3">
            <label className="form-label fs-16 fw-semibold">Pincode *</label>
            <input
              type="text"
              className="form-control fs-14"
              value={location.pincode}
              onChange={(e) => handleInputChange("pincode", e.target.value)}
              placeholder="Enter pincode"
            />
          </div>

          <div className="col-md-4 mb-3">
            <label className="form-label fs-16 fw-semibold">Landmark</label>
            <input
              type="text"
              className="form-control fs-14"
              value={location.landmark}
              onChange={(e) => handleInputChange("landmark", e.target.value)}
              placeholder="Enter nearby landmark"
            />
          </div>

          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Exact location (text)
            </label>
            <input
              type="text"
              className="form-control fs-14"
              value={exactLocationText}
              onChange={(e) =>
                patchVenueIdentityFields({
                  exact_location_text: e.target.value,
                })
              }
              placeholder="Building name, sector, landmark details"
            />
          </div>

          <div className="col-12 mb-3">
            <label className="form-label fs-16 fw-semibold">
              Google Map link / pin URL
            </label>
            <input
              type="url"
              className="form-control fs-14"
              value={mapPinUrl}
              onChange={(e) =>
                patchVenueIdentityFields({ map_pin_url: e.target.value })
              }
              placeholder="https://maps.google.com/…"
            />
            {mapPinUrl ? (
              <a
                href={mapPinUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="fs-14 d-inline-block mt-1"
              >
                Open map link
              </a>
            ) : null}
          </div>
        </div>

        <button
          className="btn btn-primary mt-2 fs-14"
          type="button"
          onClick={() => onSave?.()}
        >
          Save Location Details
        </button>
      </div>
    </div>
  );
};

export default VendorLocation;
