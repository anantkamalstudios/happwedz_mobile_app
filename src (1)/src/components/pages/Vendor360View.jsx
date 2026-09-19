import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams, useLocation } from "react-router-dom";
import Image360Modal from "../ui/Image360Modal";
import { get360Assets } from "../../utils/view360Helper";
import { API_BASE_URL } from "../../config/constants";

const Vendor360View = () => {
  const { id: paramId } = useParams();
  const location = useLocation();
  const navigate = useNavigate();

  const vendorServiceId = useMemo(() => {
    const fromState = location.state?.serviceId;
    const fromQuery = new URLSearchParams(location.search).get("id");
    return Number(paramId || fromState || fromQuery || 0) || 0;
  }, [paramId, location.state, location.search]);

  const [title, setTitle] = useState("360° View");
  const [images, setImages] = useState([]);
  const [videos, setVideos] = useState([]);
  const [tourUrl, setTourUrl] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!vendorServiceId) {
      setLoading(false);
      return;
    }
    const url = `${API_BASE_URL}/vendor-services/${vendorServiceId}`;
    setLoading(true);
    fetch(url, { mode: "cors" })
      .then((res) => res.json())
      .then((data) => {
        // Only what the vendor uploaded under 360° — never the regular gallery
        const assets = get360Assets(data);
        setImages(assets.images);
        setVideos(assets.videos);
        setTourUrl(assets.url);
        const vendorName =
          data?.attributes?.name ||
          data?.vendor?.vendor_name ||
          data?.attributes?.vendor_name ||
          "Vendor";
        setTitle(`${vendorName} • 360°`);
      })
      .catch(() => {
        setImages([]);
        setVideos([]);
        setTourUrl(null);
      })
      .finally(() => setLoading(false));
  }, [vendorServiceId]);

  if (!vendorServiceId) {
    return (
      <div style={{ padding: 24 }}>
        <p>Invalid or missing vendor service id.</p>
        <button onClick={() => navigate(-1)}>Go Back</button>
      </div>
    );
  }

  if (loading) {
    return (
      <div
        style={{
          minHeight: "60vh",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
        }}
      >
        <span>Loading 360° view…</span>
      </div>
    );
  }

  if (images.length > 0) {
    return (
      <Image360Modal
        images={images}
        title={title}
        onClose={() => navigate(-1)}
      />
    );
  }

  // The link can point anywhere the vendor chose, so the frame gets no
  // top-level navigation: it cannot redirect this page away.
  if (tourUrl) {
    return (
      <div
        style={{
          position: "fixed",
          inset: 0,
          background: "#000",
          zIndex: 1080,
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div
          className="d-flex align-items-center justify-content-between gap-2 px-3 py-2"
          style={{ color: "#fff" }}
        >
          <span className="fw-semibold text-truncate">{title}</span>
          <div className="d-flex align-items-center gap-2 flex-shrink-0">
            <a
              href={tourUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="btn btn-sm btn-outline-light"
            >
              Open in new tab
            </a>
            <button
              type="button"
              className="btn btn-sm btn-light rounded-circle"
              aria-label="Close 360° view"
              onClick={() => navigate(-1)}
            >
              ✕
            </button>
          </div>
        </div>
        <iframe
          key={tourUrl}
          src={tourUrl}
          title={title}
          className="flex-grow-1 w-100 border-0 bg-white"
          allow="fullscreen; autoplay; gyroscope; accelerometer; xr-spatial-tracking"
          allowFullScreen
          sandbox="allow-scripts allow-same-origin allow-popups allow-forms allow-presentation"
        />
        <small className="text-center px-3 py-1" style={{ color: "#bbb" }}>
          If this stays blank, the site doesn't allow being shown here. Use
          "Open in new tab".
        </small>
      </div>
    );
  }

  if (videos.length > 0) {
    return (
      <div
        style={{
          position: "fixed",
          inset: 0,
          background: "#000",
          zIndex: 1080,
          display: "flex",
          flexDirection: "column",
        }}
      >
        <div
          className="d-flex align-items-center justify-content-between px-3 py-2"
          style={{ color: "#fff" }}
        >
          <span className="fw-semibold text-truncate">{title}</span>
          <button
            type="button"
            className="btn btn-sm btn-light rounded-circle"
            aria-label="Close 360° view"
            onClick={() => navigate(-1)}
          >
            ✕
          </button>
        </div>
        <div className="flex-grow-1 d-flex align-items-center justify-content-center px-3 pb-3">
          <video
            key={videos[0]}
            src={videos[0]}
            controls
            autoPlay
            playsInline
            style={{ maxWidth: "100%", maxHeight: "100%" }}
          />
        </div>
      </div>
    );
  }

  return (
    <div style={{ padding: 24 }}>
      <p>No 360° content available for this vendor.</p>
      <button onClick={() => navigate(-1)}>Go Back</button>
    </div>
  );
};

export default Vendor360View;
