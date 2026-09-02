import React from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

const ShimmerMasonry = () => {
  return (
    <div className="container">
      <div className="row g-3">
        {/* Left Column */}
        <div className="col-12 col-md-4">
          <Skeleton height={420} borderRadius="0.75rem" />
          <div className="mt-3">
            <Skeleton height={220} borderRadius="0.75rem" />
          </div>
        </div>

        {/* Middle Column */}
        <div className="col-12 col-md-4">
          <Skeleton height={250} borderRadius="0.75rem" />
          <div className="mt-3">
            <Skeleton height={360} borderRadius="0.75rem" />
          </div>
        </div>

        {/* Right Column */}
        <div className="col-12 col-md-4">
          <Skeleton height={500} borderRadius="0.75rem" />
          <div className="mt-3">
            <Skeleton height={260} borderRadius="0.75rem" />
          </div>
        </div>
      </div>
    </div>
  );
};
export default ShimmerMasonry;
