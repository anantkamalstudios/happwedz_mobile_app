import React, { useState, useEffect } from "react";
import { FiChevronRight } from "react-icons/fi";
import "../../../../Matrimonial.css";

const MembersPlan = () => {
  const plans = [
    {
      id: 1,
      name: "Free",
      price: "₹0",
      duration: "Forever",
      features: ["Basic profile", "Limited searches", "10 interest requests"],
    },
    {
      id: 2,
      name: "Gold",
      price: "₹3,999",
      duration: "3 Months",
      features: [
        "Unlimited searches",
        "Unlimited interests",
        "Priority listing",
        "Profile highlight",
      ],
    },
    {
      id: 3,
      name: "Platinum",
      price: "₹6,999",
      duration: "6 Months",
      features: [
        "All Gold features",
        "Verified badge",
        "Profile boost",
        "Matchmaking assistance",
        "Privacy control",
      ],
    },
  ];

  useEffect(() => {
    const scrollContainer = document.querySelector(
      ".success-stories-container"
    );
    let scrollAmount = 0;

    const autoScroll = setInterval(() => {
      if (scrollContainer) {
        scrollAmount += 1;
        if (scrollAmount >= scrollContainer.scrollWidth / 2) {
          scrollAmount = 0;
        }
        scrollContainer.scrollTo({
          left: scrollAmount,
          behavior: "smooth",
        });
      }
    }, 50);

    return () => clearInterval(autoScroll);
  }, []);

  return (
    <div className="matrimonial-container">
      <div className="membership-section">
        <div className="container">
          <h2>Choose Your Membership Plan</h2>
          <p className="subtitle">
            Find the perfect plan to meet your matchmaking needs
          </p>

          <div className="plans-container">
            {plans.map((plan) => (
              <div
                key={plan.id}
                className={`plan-card ${
                  plan.name === "Gold" ? "recommended" : ""
                }`}
              >
                {plan.name === "Gold" && (
                  <div className="recommended-badge">Most Popular</div>
                )}
                <h3>{plan.name} Plan</h3>
                <div className="price">
                  {plan.price} <span>/{plan.duration}</span>
                </div>
                <ul className="features">
                  {plan.features.map((feature, index) => (
                    <li key={index}>
                      <FiChevronRight className="feature-icon" size={20} />{" "}
                      {feature}
                    </li>
                  ))}
                </ul>
                <button className="select-plan-btn">Select Plan</button>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MembersPlan;
