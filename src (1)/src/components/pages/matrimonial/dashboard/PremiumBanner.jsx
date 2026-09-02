import React from "react";

const PremiumBanner = () => {
  return (
    <div className="matrimonial-premium-banner">
      <h3 className="matrimonial-premium-title">
        You are missing out on the premium benefits!
      </h3>
      <ul className="matrimonial-premium-features">
        <li>Get upto 3x more profile views</li>
        <li>Unlimited voice & video calls</li>
        <li>Get access to contact details</li>
        <li>Perform unlimited searches</li>
        <li>Flat 46% OFF till 21 Aug</li>
      </ul>
      <button className="matrimonial-btn matrimonial-btn-primary">
        Upgrade now <i className="fas fa-arrow-right"></i>
      </button>
    </div>
  );
};

export default PremiumBanner;
