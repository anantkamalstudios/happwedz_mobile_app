import React, { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams, useLocation } from "react-router-dom";
import Image360Modal from "../ui/Image360Modal";

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
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!vendorServiceId) {
      setLoading(false);
      return;
    }
    const url = `https://happywedz.com/api/vendor-services/${vendorServiceId}`;
    setLoading(true);
    fetch(url, { mode: "cors" })
      .then((res) => res.json())
      .then((data) => {
        const media = Array.isArray(data?.media) ? data.media : [];
        const normalized = media.filter(Boolean).map((s) =>
          s
            .toString()
            .replace(/^\s*`|`\s*$/g, "")
            .trim()
        );
        setImages(normalized);
        const vendorName =
          data?.attributes?.name ||
          data?.vendor?.vendor_name ||
          data?.attributes?.vendor_name ||
          "Vendor";
        setTitle(`${vendorName} • 360°`);
      })
      .catch(() => setImages([]))
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

  if (!images.length) {
    return (
      <div style={{ padding: 24 }}>
        <p>No 360° images available for this vendor.</p>
        <button onClick={() => navigate(-1)}>Go Back</button>
      </div>
    );
  }

  return (
    <Image360Modal images={images} title={title} onClose={() => navigate(-1)} />
  );
};

export default Vendor360View;
