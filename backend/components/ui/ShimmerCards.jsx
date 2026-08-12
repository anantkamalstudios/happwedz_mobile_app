import React from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

/**
 * Loading placeholder for the WeddingCategories grid.
 *
 * This mirrors the real card in src/components/home/WeddingCategories.jsx
 * *element for element and class for class*, with the text swapped for
 * <Skeleton>. That is deliberate and worth preserving: the previous version
 * approximated the layout with hardcoded pixel heights, so the placeholder and
 * the real grid were about 16px per card apart. Six cards over two rows meant
 * the swap dropped everything below it — the CTA panel, every section after —
 * by ~32px, which was the largest remaining layout shift on the home page.
 *
 * Because the skeletons now sit *inside* the real elements, the box heights come
 * from the same CSS as the real card and cannot drift apart. If you change the
 * card markup over there, change it here too.
 */
const ShimmerCards = ({ count = 6 }) => {
  return (
    <div className="container py-5 wcg-grid">
      <div className="d-flex align-items-center justify-content-between mb-3">
        <h2 className="fw-bold mb-0 text-dark fs-28">
          <Skeleton width={220} />
        </h2>
      </div>

      <div className="row g-3 g-md-4">
        {Array.from({ length: count }).map((_, i) => (
          <div key={i} className="col-12 col-sm-6 col-lg-4">
            <div className="wcg-card h-100 p-2">
              <div className="shadow-sm border-0 rounded-4 overflow-hidden">
                <div className="ratio ratio-4x3 position-relative">
                  <Skeleton height="100%" borderRadius="1rem" />
                </div>
              </div>

              <div className="pt-2">
                <div className="d-flex align-items-center justify-content-between my-2">
                  <div>
                    <div className="fw-semibold text-dark mb-1 fs-16">
                      <Skeleton width={140} />
                    </div>
                  </div>
                </div>

                {/* The real card renders a single empty badge here, so this row
                    is padding-only. Matching it means matching the emptiness. */}
                <div className="pills d-flex flex-wrap gap-2 mb-3">
                  <span className="badge rounded-0 px-3 py-2 primary-light-bg text-dark"></span>
                </div>

                <div className="wcg-actions d-flex justify-content-between align-items-center mb-2">
                  <button
                    type="button"
                    className="btn btn-primary rounded-2 px-3 fs-16"
                    disabled
                    aria-hidden="true"
                    style={{ opacity: 0.35, pointerEvents: "none" }}
                  >
                    &nbsp;
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ShimmerCards;
