import React from "react";
import Skeleton from "react-loading-skeleton";
import "react-loading-skeleton/dist/skeleton.css";

const ShimmerAccordian = ({ count = 5 }) => {
  return (
    <div className="faq-section container my-5">
      <div className="text-center mb-4">
        <Skeleton width={300} height={32} className="mx-auto" />
      </div>
      <div className="accordion">
        {Array.from({ length: count }).map((_, index) => (
          <div key={index} className="faq-card mb-3">
            <div className="faq-header d-flex justify-content-between align-items-center">
              <Skeleton width="80%" height={20} />
              <Skeleton width={24} height={24} circle />
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default ShimmerAccordian;
