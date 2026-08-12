import React, { useEffect, useMemo, useRef, useState } from "react";
import "leaflet/dist/leaflet.css";
import { MapContainer, TileLayer, Marker, Popup, useMap } from "react-leaflet";
import L from "leaflet";
import { useNavigate } from "react-router-dom";
delete L.Icon.Default.prototype._getIconUrl;

L.Icon.Default.mergeOptions({
  iconRetinaUrl:
    "https://unpkg.com/leaflet@1.9.4/dist/images/marker-icon-2x.png",
  iconUrl: "/images/location.png",
  shadowUrl: "https://unpkg.com/leaflet@1.9.4/dist/images/marker-shadow.png",
});

const DEFAULT_CENTER = [22.3511148, 78.6677428];
const DEFAULT_ZOOM = 5;

function FitBounds({ points }) {
  const map = useMap();
  useEffect(() => {
    if (!points || points.length === 0) return;
    const bounds = L.latLngBounds(points.map((p) => [p.lat, p.lng]));
    if (bounds.isValid()) {
      map.fitBounds(bounds, { padding: [32, 32] });
    }
  }, [points, map]);
  return null;
}

const geocodeCache = new Map();

async function geocodeLocation(query) {
  const key = (query || "").trim().toLowerCase();
  if (!key) return null;
  if (geocodeCache.has(key)) return geocodeCache.get(key);
  try {
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(
      key
    )}`;
    const res = await fetch(url, {
      headers: {
        "User-Agent": "HappyWedz/1.0 (contact: info@happywedz.example)",
      },
    });
    const data = await res.json();
    const first = Array.isArray(data) && data.length > 0 ? data[0] : null;
    const result = first
      ? { lat: parseFloat(first.lat), lng: parseFloat(first.lon) }
      : null;
    geocodeCache.set(key, result);
    return result;
  } catch (e) {
    return null;
  }
}

const MapView = ({ subVenuesData = [], section, onClose }) => {
  const [points, setPoints] = useState([]);
  const [loading, setLoading] = useState(true);
  const isMounted = useRef(true);
  const navigate = useNavigate();

  useEffect(() => {
    const handler = (e) => {
      if (e.key === "Escape") {
        if (onClose) onClose();
        else navigate(-1);
      }
    };
    window.addEventListener("keydown", handler);
    return () => window.removeEventListener("keydown", handler);
  }, [onClose, navigate]);

  useEffect(() => {
    isMounted.current = true;
    const run = async () => {
      setLoading(true);
      const validVenues = (subVenuesData || []).filter(
        (v) => v && v.image && String(v.image).trim() !== ""
      );
      const tasks = validVenues.map(async (v) => {
        if (v.lat && v.lng) return { ...v, lat: v.lat, lng: v.lng };
        const q =
          typeof v.location === "string"
            ? v.location
            : v.location?.address ||
              v.location?.city ||
              v.address ||
              v.city ||
              v.name;
        const coords = await geocodeLocation(q);
        if (coords) return { ...v, ...coords };
        return null;
      });
      const results = (await Promise.all(tasks)).filter(Boolean);
      if (isMounted.current) setPoints(results);
      setLoading(false);
    };
    run();
    return () => {
      isMounted.current = false;
    };
  }, [subVenuesData]);

  const center = useMemo(() => {
    if (points.length > 0) return [points[0].lat, points[0].lng];
    return DEFAULT_CENTER;
  }, [points]);

  return (
    <div
      className="position-fixed top-0 start-0"
      style={{ height: "100vh", width: "100vw", zIndex: 1040 }}
    >
      <button
        className="btn btn-light position-absolute top-0 end-0 m-3 shadow-sm rounded-pill"
        style={{ zIndex: 2000 }}
        onClick={() => (onClose ? onClose() : navigate(-1))}
      >
        Close Map
      </button>
      {loading && (
        <div className="position-absolute top-0 start-0 m-3 text-muted small">
          Loading map…
        </div>
      )}
      <MapContainer
        center={center}
        zoom={DEFAULT_ZOOM}
        scrollWheelZoom={true}
        style={{ height: "100%", width: "100%", zIndex: 1000 }}
      >
        <TileLayer
          attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
          url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
        />

        <FitBounds points={points} />

        {points.map((v) => (
          <Marker key={v.id || v.slug || v.name} position={[v.lat, v.lng]}>
            <Popup maxWidth={320} className="small">
              <div className="d-flex gap-3" style={{ minWidth: 220 }}>
                <div className="flex-shrink-0">
                  <img
                    src={v.image}
                    alt={v.name}
                    style={{
                      width: 80,
                      height: 80,
                      objectFit: "cover",
                      borderRadius: 8,
                    }}
                    onError={(e) => {
                      e.currentTarget.src = "/images/location.png";
                      e.currentTarget.style.objectFit = "contain";
                      e.currentTarget.style.background = "#fafafa";
                    }}
                  />
                </div>
                <div className="flex-grow-1">
                  <div className="fw-semibold mb-1">{v.name}</div>
                  <div className="text-muted mb-1" style={{ lineHeight: 1.2 }}>
                    {v.address || v.location || v.city}
                  </div>
                  <div className="d-flex align-items-center gap-2 mb-2">
                    {v.rating && (
                      <span className="badge bg-success">{v.rating}★</span>
                    )}
                    {(v.starting_price || v.vegPrice || v.nonVegPrice) && (
                      <span className="badge bg-light text-muted border">
                        {v.starting_price || v.vegPrice || v.nonVegPrice}
                      </span>
                    )}
                  </div>
                  <button
                    className="btn btn-sm btn-primary rounded-pill px-3"
                    onClick={() => navigate(`/details/info/${v.id}`)}
                  >
                    View Details
                  </button>
                </div>
              </div>
            </Popup>
          </Marker>
        ))}
      </MapContainer>
      {points.length === 0 && !loading && (
        <div className="position-absolute bottom-0 start-0 m-3 text-muted small bg-white bg-opacity-75 px-2 py-1 rounded">
          No mappable venues for this selection.
        </div>
      )}
    </div>
  );
};

export default MapView;
