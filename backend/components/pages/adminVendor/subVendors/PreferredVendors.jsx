import React, { useEffect, useMemo, useRef, useState } from "react";
import axios from "axios";
import { CiLocationOn, CiStar } from "react-icons/ci";
import { FaStar } from "react-icons/fa";

const PreferredVendors = ({ formData, setFormData, onSave, onShowSuccess }) => {
  const [query, setQuery] = useState("");
  const [loading, setLoading] = useState(false);
  const [results, setResults] = useState([]);
  const [selectedVendors, setSelectedVendors] = useState(() => {
    const fromAttrs = formData?.attributes?.preferred_vendors;
    return Array.isArray(fromAttrs) ? fromAttrs : [];
  });
  const debounceRef = useRef(null);

  const performSearch = async (searchQuery) => {
    if (!searchQuery || searchQuery.trim().length < 2) {
      setResults([]);
      return;
    }
    setLoading(true);
    try {
      let apiUrl = `https://happywedz.com/api/vendor-services?search=${encodeURIComponent(
        searchQuery
      )}&limit=10`;
      const { data } = await axios.get(apiUrl);
      const items = data?.data || [];
      setResults(items);
    } catch (e) {
      setResults([]);
    } finally {
      setLoading(false);
    }
  };

  const handleQueryChange = (e) => {
    const value = e.target.value;
    setQuery(value);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => performSearch(value), 400);
  };

  const toggleSelect = (item) => {
    const vid = item?.id ?? item?.vendor_services_id;
    const vendorData = {
      id: vid,
      name:
        item?.attributes?.vendor_name ||
        item?.attributes?.name ||
        item?.vendor?.businessName ||
        `Vendor ${vid}`,
      rating: item?.attributes?.rating || null,
      image:
        item?.attributes?.image ||
        item?.attributes?.profile_image ||
        item?.vendor?.profileImage ||
        null,
      city: item?.attributes?.city || item?.vendor?.city || "",
    };

    setSelectedVendors((prev) => {
      const exists = prev.find((v) => v.id === vid);
      const next = exists
        ? prev.filter((v) => v.id !== vid)
        : [...prev, vendorData];

      // Persist into formData
      setFormData((p) => ({
        ...p,
        attributes: {
          ...(p?.attributes || {}),
          preferred_vendors: next,
        },
        preferredVendors: next,
      }));
      return next;
    });
  };

  const removeVendor = (id) => {
    setSelectedVendors((prev) => {
      const next = prev.filter((v) => v.id !== id);
      setFormData((p) => ({
        ...p,
        attributes: {
          ...(p?.attributes || {}),
          preferred_vendors: next,
        },
        preferredVendors: next,
      }));
      return next;
    });
  };

  const handleSave = async () => {
    setFormData((p) => ({
      ...p,
      attributes: {
        ...(p?.attributes || {}),
        preferred_vendors: selectedVendors,
      },
      preferredVendors: selectedVendors,
    }));
    if (onSave) await onSave();
    if (onShowSuccess) onShowSuccess();
  };

  useEffect(() => {
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, []);

  const isSelected = (id) => selectedVendors.some((v) => v.id === id);

  return (
    <div className="my-5">
      <div className="p-3 border rounded bg-white">
        <h4 className="mb-3 fw-bold">Preferred Vendors</h4>

        <div className="row g-2 align-items-center">
          <div className="col-md-8">
            <input
              type="text"
              className="form-control fs-14"
              placeholder="Search vendors by name, type, etc."
              value={query}
              onChange={handleQueryChange}
            />
          </div>
          <div className="col-md-4 text-md-end">
            <button
              className="btn btn-primary fs-14"
              onClick={handleSave}
              disabled={loading}
            >
              {loading ? "Loading..." : "Save Preferred Vendors"}
            </button>
          </div>
        </div>

        {/* Search Results */}
        <div className="mt-3">
          {loading && results.length === 0 ? (
            <div className="text-muted">Searching...</div>
          ) : results.length === 0 && query.length >= 2 ? (
            <div className="text-muted">No results</div>
          ) : (
            <div className="list-group">
              {results.map((item) => {
                const vid = item?.id ?? item?.vendor_services_id;
                const title =
                  item?.attributes?.vendor_name ||
                  item?.attributes?.name ||
                  item?.vendor?.businessName ||
                  `Vendor ${vid}`;
                const city = item?.attributes?.city || item?.vendor?.city || "";
                const image =
                  item?.attributes?.image ||
                  item?.attributes?.profile_image ||
                  item?.vendor?.profileImage;
                const checked = isSelected(vid);

                return (
                  <label
                    key={vid}
                    className="list-group-item d-flex align-items-center justify-content-between"
                    style={{ cursor: "pointer" }}
                  >
                    <div className="d-flex align-items-center flex-grow-1">
                      <input
                        type="checkbox"
                        className="form-check-input me-3"
                        checked={checked}
                        onChange={() => toggleSelect(item)}
                      />
                      {image && (
                        <img
                          src={image}
                          alt={title}
                          className="me-3"
                          style={{
                            width: "40px",
                            height: "40px",
                            objectFit: "cover",
                            borderRadius: "4px",
                          }}
                          onError={(e) => {
                            e.target.style.display = "none";
                          }}
                        />
                      )}
                      <div>
                        <span className="fw-semibold fs-14">{title}</span>
                        {city && (
                          <span className="text-muted ms-2 fs-14">
                            • {city}
                          </span>
                        )}
                      </div>
                    </div>
                    {item?.attributes?.rating != null && (
                      <span className="badge bg-light text-dark d-flex align-items-center gap-1">
                        <CiStar color="red" /> {item.attributes.rating}
                      </span>
                    )}
                  </label>
                );
              })}
            </div>
          )}
        </div>

        {/* Selected Vendors Display */}
        {selectedVendors.length > 0 && (
          <div className="mt-4">
            <h6 className="fw-semibold mb-3">
              Selected Vendors ({selectedVendors.length})
            </h6>
            <div className="row g-3">
              {selectedVendors.map((vendor) => (
                <div key={vendor.id} className="col-md-6">
                  <div className="card h-100 shadow-sm">
                    <div className="card-body d-flex align-items-center gap-3">
                      <div
                        className="d-flex align-items-center justify-content-center bg-light"
                        style={{
                          width: "60px",
                          height: "60px",
                          borderRadius: "10px",
                          overflow: "hidden",
                          flexShrink: 0,
                        }}
                      >
                        <img
                          src={vendor.image || "/images/noimage.jpeg"}
                          alt={vendor.name}
                          style={{
                            width: "100%",
                            height: "100%",
                            objectFit: "cover",
                          }}
                          onError={(e) => {
                            e.target.onerror = null;
                            e.target.src = "/images/noimage.jpeg";
                          }}
                        />
                      </div>
                      <div className="flex-grow-1">
                        <div className="d-flex align-items-center justify-content-between">
                          <h6 className="mb-1">{vendor.name}</h6>
                          {vendor.rating != null && (
                            <span className="badge bg-light text-dark d-inline-flex align-items-center gap-1">
                              <FaStar color="#f5c518" size={14} />
                              <span className="fw-semibold">
                                {Number(vendor.rating).toFixed(1)}
                              </span>
                            </span>
                          )}
                        </div>
                        {vendor.city && (
                          <small className="text-muted d-block fs-14 d-flex align-items-center gap-1">
                            <CiLocationOn /> {vendor.city}
                          </small>
                        )}
                      </div>
                      <button
                        className="btn btn-sm btn-outline-danger"
                        onClick={() => removeVendor(vendor.id)}
                        title="Remove"
                      >
                        ✕
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default PreferredVendors;
