import React, { useState, useEffect, useCallback } from "react";
import FILTER_CONFIG from "../../data/filtersConfig";
import { Link, useNavigate } from "react-router-dom";
import ErrorState from "../ui/ErrorState";
import { fetchVendorTypesWithSubcategoriesApi } from "../../services/api/vendorTypesWithSubcategoriesApi";

import { IMAGE_BASE_URL } from "../../config/constants";

const WeddingCategories = ({ onSelect }) => {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [expandedIndex, setExpandedIndex] = useState(-1);
  const navigate = useNavigate();

  const toggleExpand = (i) => setExpandedIndex((prev) => (prev === i ? -1 : i));

  const fetchCategories = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      // Shared/deduped fetch — Header and Herosection request the same list.
      const vendorTypes = await fetchVendorTypesWithSubcategoriesApi();
      const apiData = vendorTypes.map((cat) => {
        const imageSrc = cat.hero_image
          ? "https://happywedzbackend.happywedz.com" + cat.hero_image
          : "logo-no-bg.png";
        return {
          id: cat.id,
          title: cat.name,
          subtitle: cat.description,
          imageSrc,
          slug: cat.name.toLowerCase().replace(/\s+/g, "-"),
          items: cat.subcategories.map((sub) => sub.name),
        };
      });
      setCategories(apiData);
    } catch (err) {
      setError("Failed to load categories. Please try again later.");
      console.error(err);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  if (error) {
    return (
      <ErrorState
        title="We couldn’t load the categories"
        message={`${error} Check your connection and try again in a moment.`}
        onRetry={fetchCategories}
      />
    );
  }

  // While loading, render the *real* card markup filled with blanks rather than a
  // separately-authored shimmer component. A parallel skeleton can only ever
  // approximate these heights, and it was off by enough that swapping it for the
  // real grid pushed every section below down by ~190px — by far the largest
  // layout shift on the page. Same JSX in both states means the geometry is
  // identical by construction; `.is-loading` only paints over it.
  const PLACEHOLDER_CATEGORY = {
    title: " ",
    subtitle: "",
    imageSrc: "/logo-no-bg.png",
    slug: "",
    items: [],
  };
  const displayedCategories = loading
    ? Array.from({ length: 6 }, (_, i) => ({
        ...PLACEHOLDER_CATEGORY,
        id: `placeholder-${i}`,
      }))
    : categories.slice(0, 6);

  return (
    <div className={`container py-5 wcg-grid${loading ? " is-loading" : ""}`}
      aria-busy={loading || undefined}
    >
      <div className="d-flex align-items-center justify-content-between mb-3">
        <h2 className="fw-bold mb-0 text-dark fs-28">Explore by Category</h2>
      </div>

      <div className="row g-3 g-md-4">
        {displayedCategories.map((cat, i) => {
          const isExpanded = expandedIndex === i;
          const previewItems = cat.items.slice(0, 3);
          const remaining = Math.max(cat.items.length - previewItems.length, 0);

          return (
            <div key={i} className="col-12 col-sm-6 col-lg-4">
              <div
                className="wcg-card h-100 p-2"
                onClick={loading ? undefined : () => toggleExpand(i)}
                role={loading ? undefined : "button"}
                aria-expanded={isExpanded}
                aria-label={`Open ${cat.title} category`}
              >
                <div className="shadow-sm border-0 rounded-4 overflow-hidden">
                  <div className="ratio ratio-4x3 position-relative">
                    {/* These are full-size CMS uploads (up to 1000x750) shown in
                        a ~320px card — ~700KB across the six of them. Until the
                        backend can serve resized variants, the least it can do
                        is not compete with the hero for bandwidth: low priority
                        keeps them behind the LCP image in the fetch queue. */}
                    <img decoding="async"
                      src={cat.imageSrc}
                      alt={cat.title}
                      loading="lazy"
                      fetchPriority="low"
                      className="card-img-top rounded-4"
                      style={{ objectFit: "cover" }}
                      onError={(e) => {
                        e.currentTarget.src = "logo-no-bg.png";
                        e.currentTarget.style.objectFit = "contain";
                        e.currentTarget.style.padding = "12px";
                        e.currentTarget.style.background = "#fafafa";
                      }}
                    />
                  </div>
                </div>

                <div className="pt-2">
                  <div className="d-flex align-items-center justify-content-between my-2">
                    <div>
                      <div className="fw-semibold text-dark mb-1 fs-16">{cat.title}</div>
                    </div>
                  </div>
                  <div className=" pills d-flex flex-wrap gap-2 mb-3">
                    {previewItems.slice(0, 1).map((it, idx) => (
                      <span
                        key={idx}
                        className="badge rounded-0 px-3 py-2 primary-light-bg text-dark"
                      ></span>
                    ))}

                    {isExpanded && (
                      <div className="wcg-subcats mt-3">
                        <div className="d-flex flex-wrap justify-content-start gap-2">
                          {cat.items.map((it, idx) => (
                            <div key={idx} className="">
                              <Link
                                to={
                                  cat.title.toLowerCase() === "venues"
                                    ? `/venues/${it
                                        .toLowerCase()
                                        .replace(/\s+/g, "-")}`
                                    : `/vendor/${it
                                        .toLowerCase()
                                        .replace(/\s+/g, "-")}`
                                }
                                className="badge rounded-0 primary-light-bg text-dark fs-12 px-3 py-2"
                                style={{ textDecoration: "none" }}
                              >
                                {it}
                              </Link>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  <div className="wcg-actions d-flex justify-content-between align-items-center mb-2">
                    <button
                      type="button"
                      className="btn btn-primary rounded-2 px-3 fs-16"
                      onClick={(e) => {
                        e.stopPropagation();
                        if (onSelect) onSelect(cat);
                        if (cat.title) {
                          const slug = cat.slug;
                          if (FILTER_CONFIG[slug]) {
                            navigate(`/vendor/${slug}`);
                          } else {
                            const encoded = encodeURIComponent(cat.title);
                            navigate(`/vendors/all?vendorType=${encoded}`);
                          }
                        }
                      }}
                    >
                      Explore {cat.title}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};

export default WeddingCategories;
