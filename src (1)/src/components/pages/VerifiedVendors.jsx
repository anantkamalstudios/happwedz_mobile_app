import React, { useState, useEffect, useCallback } from "react";
import { FaStar, FaMapMarkerAlt, FaImages } from "react-icons/fa";

const API_BASE  = "https://happywedz.com/api";
const PAGE_SIZE = 20;

// ── Skeleton card shown while loading ────────────────────────────────────────
function SkeletonCard() {
  return (
    <div className="col-6 col-sm-4 col-md-3 col-lg-3 mb-4">
      <div
        className="rounded-3 overflow-hidden border"
        style={{ background: "#f3f4f6", animation: "pulse 1.4s ease-in-out infinite" }}
      >
        <div style={{ height: "200px", background: "#e5e7eb" }} />
        <div className="p-3">
          <div style={{ height: "14px", background: "#e5e7eb", borderRadius: 6, marginBottom: 8, width: "80%" }} />
          <div style={{ height: "12px", background: "#e5e7eb", borderRadius: 6, width: "55%" }} />
        </div>
      </div>
    </div>
  );
}

// ── Single vendor card ────────────────────────────────────────────────────────
function VendorCard({ vendor }) {
  const [imgHidden, setImgHidden] = useState(false);

  return (
    <div className="col-6 col-sm-4 col-md-3 col-lg-3 mb-4">
      <div
        className="h-100 rounded-3 overflow-hidden border shadow-sm"
        style={{ background: "#fff", transition: "box-shadow 0.2s" }}
        onMouseEnter={e => e.currentTarget.style.boxShadow = "0 4px 18px rgba(0,0,0,0.12)"}
        onMouseLeave={e => e.currentTarget.style.boxShadow = ""}
      >
        {/* Image */}
        <div style={{ position: "relative", height: "200px", background: "#f3f4f6" }}>
          {!imgHidden && vendor.image ? (
            <img
              src={vendor.image}
              alt={vendor.name || "Vendor"}
              onError={() => setImgHidden(true)}
              style={{
                width: "100%",
                height: "100%",
                objectFit: "cover",
                display: "block",
              }}
            />
          ) : (
            <div
              className="d-flex flex-column align-items-center justify-content-center h-100 text-muted"
              style={{ gap: "6px" }}
            >
              <FaImages size={28} />
              <span style={{ fontSize: "12px" }}>No image</span>
            </div>
          )}
        </div>

        {/* Info */}
        <div className="p-3">
          <p
            className="mb-1 fw-semibold"
            style={{ fontSize: "14px", lineHeight: 1.3, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}
            title={vendor.name}
          >
            {vendor.name || "Unnamed Vendor"}
          </p>

          {vendor.city && (
            <p className="mb-1 text-muted d-flex align-items-center gap-1" style={{ fontSize: "12px" }}>
              <FaMapMarkerAlt size={11} />
              {vendor.city}
            </p>
          )}

          {vendor.rating != null && (
            <p className="mb-0 d-flex align-items-center gap-1" style={{ fontSize: "12px", color: "#f59e0b" }}>
              <FaStar size={11} />
              <span style={{ color: "#374151", fontWeight: 600 }}>{vendor.rating.toFixed(1)}</span>
            </p>
          )}
        </div>
      </div>
    </div>
  );
}

// ── Main page component ───────────────────────────────────────────────────────
export default function VerifiedVendors() {
  const [vendors,     setVendors]     = useState([]);
  const [page,        setPage]        = useState(1);
  const [totalPages,  setTotalPages]  = useState(1);
  const [total,       setTotal]       = useState(0);
  const [loading,     setLoading]     = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [error,       setError]       = useState(null);
  const [city,        setCity]        = useState("");
  const [cityInput,   setCityInput]   = useState("");

  const fetchVendors = useCallback(
    async (pageNum, cityFilter, replace) => {
      try {
        replace ? setLoading(true) : setLoadingMore(true);
        setError(null);

        const params = new URLSearchParams({ page: pageNum, limit: PAGE_SIZE });
        if (cityFilter) params.set("city", cityFilter);

        const res  = await fetch(`${API_BASE}/vendor-services/verified-images?${params}`);
        if (!res.ok) throw new Error(`Server error: ${res.status}`);

        const json = await res.json();

        const validList = (json.vendors || []).filter(
          (v) => v && v.image && String(v.image).trim() !== ""
        );
        setVendors((prev) => (replace ? validList : [...prev, ...validList]));
        setPage(json.page);
        setTotalPages(json.totalPages);
        setTotal(json.total);
      } catch (err) {
        setError(err.message || "Failed to load vendors");
      } finally {
        setLoading(false);
        setLoadingMore(false);
      }
    },
    []
  );

  // Initial + city-filter fetch
  useEffect(() => {
    fetchVendors(1, city, true);
  }, [city, fetchVendors]);

  const handleLoadMore = () => {
    if (page < totalPages && !loadingMore) {
      fetchVendors(page + 1, city, false);
    }
  };

  const handleSearch = (e) => {
    e.preventDefault();
    setCity(cityInput.trim());
  };

  return (
    <div className="container py-4">
      {/* Header */}
      <div className="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
        <div>
          <h2 className="fw-bold mb-1" style={{ fontSize: "22px" }}>
            Verified Vendors
          </h2>
          {!loading && (
            <p className="text-muted mb-0" style={{ fontSize: "13px" }}>
              {total.toLocaleString()} vendors with real photos
            </p>
          )}
        </div>

        {/* City filter */}
        <form onSubmit={handleSearch} className="d-flex gap-2" style={{ maxWidth: "300px" }}>
          <input
            type="text"
            className="form-control form-control-sm"
            placeholder="Filter by city…"
            value={cityInput}
            onChange={e => setCityInput(e.target.value)}
          />
          <button type="submit" className="btn btn-sm btn-primary px-3">
            Go
          </button>
          {city && (
            <button
              type="button"
              className="btn btn-sm btn-outline-secondary"
              onClick={() => { setCityInput(""); setCity(""); }}
            >
              ✕
            </button>
          )}
        </form>
      </div>

      {/* Error */}
      {error && (
        <div className="alert alert-danger d-flex align-items-center gap-2" role="alert">
          {error}
          <button
            className="btn btn-sm btn-outline-danger ms-auto"
            onClick={() => fetchVendors(1, city, true)}
          >
            Retry
          </button>
        </div>
      )}

      {/* Grid */}
      <div className="row">
        {loading
          ? Array.from({ length: 8 }).map((_, i) => <SkeletonCard key={i} />)
          : vendors.map(v => <VendorCard key={v.id} vendor={v} />)
        }

        {/* "Load more" skeletons */}
        {loadingMore && Array.from({ length: 4 }).map((_, i) => <SkeletonCard key={`more-${i}`} />)}
      </div>

      {/* Empty state */}
      {!loading && !error && vendors.length === 0 && (
        <div className="text-center py-5 text-muted">
          <FaImages size={40} className="mb-3" style={{ opacity: 0.3 }} />
          <p className="mb-0">No vendors found{city ? ` in "${city}"` : ""}.</p>
        </div>
      )}

      {/* Load More */}
      {!loading && !error && vendors.length > 0 && page < totalPages && (
        <div className="text-center mt-4">
          <button
            className="btn btn-outline-primary px-5 py-2 fw-semibold"
            onClick={handleLoadMore}
            disabled={loadingMore}
          >
            {loadingMore ? "Loading…" : `Load More (${total - vendors.length} remaining)`}
          </button>
        </div>
      )}

      {/* End of list */}
      {!loading && !error && vendors.length > 0 && page >= totalPages && (
        <p className="text-center text-muted mt-4 mb-0" style={{ fontSize: "13px" }}>
          All {total.toLocaleString()} vendors loaded
        </p>
      )}

      {/* Pulse keyframe (inline, runs once) */}
      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50%       { opacity: 0.5; }
        }
      `}</style>
    </div>
  );
}
