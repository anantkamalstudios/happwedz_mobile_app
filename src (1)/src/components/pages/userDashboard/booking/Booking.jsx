import React, { useCallback, useEffect, useRef } from "react";
import { useNavigate } from "react-router-dom";
import { FaHotel, FaPlane, FaTaxi, FaShieldAlt } from "react-icons/fa";

import useBookingData from "./useBookingData";
import WeddingServicesPanel from "./panels/WeddingServicesPanel";
import HotelPanel from "./panels/HotelPanel";
import FlightPanel from "./panels/FlightPanel";
import CabPanel from "./panels/CabPanel";
import InsurancePanel from "./panels/InsurancePanel";
import ShopPanel from "./panels/ShopPanel";
import StoreCartSection from "./StoreCartSection";
import "./Booking.css";

const CATEGORIES = [
  { key: "services", label: "Wedding Services" },
  { key: "travel", label: "Honeymoon Travel" },
  { key: "shop", label: "Shop Orders" },
];

const TRAVEL_TABS = [
  { key: "hotels", label: "Hotels", icon: <FaHotel />, Panel: HotelPanel },
  { key: "flights", label: "Flights", icon: <FaPlane />, Panel: FlightPanel },
  { key: "cabs", label: "Cabs", icon: <FaTaxi />, Panel: CabPanel },
  { key: "insurance", label: "Insurance", icon: <FaShieldAlt />, Panel: InsurancePanel },
];

const TRAVEL_KEYS = TRAVEL_TABS.map((tab) => tab.key);
const DEFAULT_SUB = "hotels";

/**
 * The Booking tab.
 *
 * Three horizontal categories in the pink header — Wedding Services (vendor
 * quotation requests), Honeymoon Travel, and Shop Orders — with Travel splitting
 * into a left rail of Hotels / Flights / Cabs / Insurance.
 *
 * Shop Orders come from the store backend, a separate service on its own
 * MongoDB. They arrive here already reshaped into the same row vocabulary as
 * everything else, which is why they slot in as one more category rather than
 * needing a parallel structure.
 *
 * All six lists load together with the tab, because the rail and category
 * badges count them. Panels are presentational: they filter and render the rows
 * handed to them, so switching sub-tabs is instant.
 */
export default function Booking({ category, sub }) {
  const navigate = useNavigate();
  const { state, reload, update } = useBookingData();

  const activeCategory = CATEGORIES.some((c) => c.key === category) ? category : "services";
  const activeSub = TRAVEL_KEYS.includes(sub) ? sub : DEFAULT_SUB;

  // Coming back to Travel should land where you left it, not always on Hotels.
  const lastSub = useRef(DEFAULT_SUB);
  useEffect(() => {
    if (activeCategory === "travel") lastSub.current = activeSub;
  }, [activeCategory, activeSub]);

  // /booking/travel with no sub-tab is a valid link — put the default in the URL
  // so the address bar always describes what is on screen.
  useEffect(() => {
    if (activeCategory === "travel" && !TRAVEL_KEYS.includes(sub)) {
      navigate(`/user-dashboard/booking/travel/${DEFAULT_SUB}`, { replace: true });
    }
  }, [activeCategory, sub, navigate]);

  const goToCategory = useCallback(
    (key) => {
      // Travel is the only category with sub-tabs, so it is the only one that
      // needs a second path segment. The rest map straight to their own key.
      navigate(
        key === "travel"
          ? `/user-dashboard/booking/travel/${lastSub.current}`
          : `/user-dashboard/booking/${key}`
      );
    },
    [navigate]
  );

  const goToSub = useCallback(
    (key) => navigate(`/user-dashboard/booking/travel/${key}`),
    [navigate]
  );

  // A count is shown once that list has resolved. A list that failed to load
  // stays blank rather than claiming zero.
  const countOf = (key) => {
    const slice = state[key];
    return slice.loading || slice.error ? null : slice.rows.length;
  };

  const travelTotal = TRAVEL_KEYS.every((key) => countOf(key) != null)
    ? TRAVEL_KEYS.reduce((sum, key) => sum + countOf(key), 0)
    : null;

  const categoryCount = (key) => {
    if (key === "travel") return travelTotal;
    if (key === "shop") return countOf("orders");
    return countOf("services");
  };

  const activeTab = TRAVEL_TABS.find((tab) => tab.key === activeSub) || TRAVEL_TABS[0];
  const ActivePanel = activeTab.Panel;
  const activeSlice = state[activeTab.key];

  return (
    <div className="user-booking-container">
      {/* The HappyWedz Store basket. Rendered above the quotations rather than
          merged into them: a basket item and a vendor quotation are different
          records, and folding them together would make the All/Replied/Pending
          counts below ambiguous. Renders nothing when the store bridge is
          unreachable, so this section is safe to ship before the store deploys
          cart-bridge.html. */}
      <StoreCartSection />

      <div className="user-booking-header">
        <div className="user-booking-header-content">
          <div className="user-booking-title-section">
            <h3 className="user-booking-main-title">My Bookings</h3>
            <p className="user-booking-subtitle fs-16">
              Manage and track all your service bookings
            </p>
          </div>

          <div className="user-booking-filter-section">
            <div className="hw-bk-cat-tabs" role="tablist" aria-label="Booking category">
              {CATEGORIES.map((cat) => {
                const count = categoryCount(cat.key);
                return (
                  <button
                    key={cat.key}
                    type="button"
                    role="tab"
                    aria-selected={activeCategory === cat.key}
                    className={`hw-bk-cat-tab ${activeCategory === cat.key ? "active" : ""}`}
                    onClick={() => goToCategory(cat.key)}
                  >
                    {cat.label}
                    {count != null && <span className="hw-bk-cat-count">{count}</span>}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {activeCategory !== "travel" ? (
        // Travel is the only category that needs the left rail, so everything
        // else shares the solo stage.
        <div className="hw-bk-stage hw-bk-stage--solo">
          <div>
            {activeCategory === "shop" ? (
              <ShopPanel
                rows={state.orders.rows}
                loading={state.orders.loading}
                error={state.orders.error}
                onRetry={() => reload("orders")}
              />
            ) : (
              <WeddingServicesPanel
                rows={state.services.rows}
                loading={state.services.loading}
                error={state.services.error}
                onRetry={() => reload("services")}
                onUpdate={(updater) => update("services", updater)}
              />
            )}
          </div>
        </div>
      ) : (
        <div className="hw-bk-stage">
          <nav className="hw-bk-rail" role="tablist" aria-label="Travel booking type">
            <div className="hw-bk-rail-label">Travel</div>
            {TRAVEL_TABS.map((tab) => {
              const count = countOf(tab.key);
              return (
                <button
                  key={tab.key}
                  type="button"
                  role="tab"
                  aria-selected={activeSub === tab.key}
                  className={`hw-bk-rail-btn ${activeSub === tab.key ? "active" : ""}`}
                  onClick={() => goToSub(tab.key)}
                >
                  <span className="hw-bk-rail-icon">{tab.icon}</span>
                  <span>{tab.label}</span>
                  {count != null && <span className="hw-bk-rail-count">{count}</span>}
                </button>
              );
            })}
          </nav>

          <div>
            <ActivePanel
              key={activeSub}
              rows={activeSlice.rows}
              loading={activeSlice.loading}
              error={activeSlice.error}
              onRetry={() => reload(activeTab.key)}
            />
          </div>
        </div>
      )}
    </div>
  );
}
