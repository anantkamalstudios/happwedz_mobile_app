import React from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

const ShimmerRegion = () => {
  return (
    <div className="container">
      <div className="venue-region-section px-4 my-5">
        <Skeleton height={30} width={200} className="mb-4" />

        <div
          className="d-flex flex-row gap-3"
          style={{
            overflowX: "auto",
            overflowY: "hidden",
            WebkitOverflowScrolling: "touch",
          }}
        >
          {[...Array(6)].map((_, i) => (
            <div
              key={i}
              className="text-center region-slide-card flex-shrink-0"
              style={{ width: "150px" }}
            >
              <div className="region-img-wrapper mb-2">
                <Skeleton
                  circle
                  height={100}
                  width={100}
                  style={{ margin: "15px auto" }}
                />
              </div>
              <Skeleton width={80} height={12} style={{ margin: "0 auto" }} />
              <Skeleton width={60} height={10} style={{ margin: "5px auto" }} />
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default ShimmerRegion;
