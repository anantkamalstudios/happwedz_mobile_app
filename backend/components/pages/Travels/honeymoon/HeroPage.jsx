import { useEffect, useState } from "react";
import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { Shield } from "lucide-react";
import FightIcon from "../../../../assets/trevel_icon/airplane.png";
import HotelIcon from "../../../../assets/trevel_icon/hotel.png";
import CarIcon from "../../../../assets/trevel_icon/sedan.png";
import ActivityIcon from "../../../../assets/trevel_icon/checklist.png";
import CruiseIcon from "../../../../assets/trevel_icon/cruise-ship.png";
import FlightSearchForm from "./components/FlightSearchForm";
import HotelSearchForm from "./components/HotelSearchForm";
import CarRentalSearchForm from "./components/CarRentalSearchForm";
import InsuranceSearchPanel from "./InsuranceSearchPanel";
import UpcomingBookings from "./components/UpcomingBookings";
import { getRecentHotelBookings } from "../../../../services/api/hotelApi";
import "./index.css";

const TAB_PARAM_MAP = {
  hotels: "Hotels",
  flights: "Flights",
  insurance: "Insurance",
  "car-rental": "Car rental",
};

const formatSelectedDate = (dateValue) => {
  if (!dateValue) return "";
  const date = new Date(dateValue);
  if (Number.isNaN(date.getTime())) return dateValue;
  return date.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
};

const mapBookingStatusLabel = (status) => {
  const normalized = String(status || "").toUpperCase();
  if (normalized === "PAYMENT_SUCCESS") return "Awaiting Confirmation";
  if (normalized === "SUCCESS") return "Confirmed";
  if (normalized === "ON_HOLD") return "On Hold";
  if (normalized === "PAYMENT_PENDING") return "Payment Pending";
  if (["IN_PROGRESS", "PENDING"].includes(normalized)) return "Processing";
  if (["FAILED", "ABORTED"].includes(normalized)) return "Failed";
  if (normalized === "CANCELLED") return "Cancelled";
  return normalized || "PENDING";
};

const getBookingStatusColor = (status) => {
  const normalized = String(status || "").toUpperCase();
  if (["SUCCESS", "ON_HOLD"].includes(normalized)) return "#22c55e";
  if (["PAYMENT_SUCCESS", "IN_PROGRESS", "PENDING", "PAYMENT_PENDING"].includes(normalized)) return "#f59e0b";
  if (["FAILED", "ABORTED", "CANCELLED"].includes(normalized)) return "#ef4444";
  return "#ffffff";
};

export default function FlightHero() {
  const navigate = useNavigate();
  const user = useSelector((state) => state.auth.user);
  const isAuthenticated = useSelector((state) => state.auth.isAuthenticated);
  const [searchParams, setSearchParams] = useSearchParams();
  const tabParam = (searchParams.get("tab") || "").toLowerCase();
  const activeTab = TAB_PARAM_MAP[tabParam] || "Flights";

  const setActiveTab = (label) => {
    const paramKey = Object.keys(TAB_PARAM_MAP).find(
      (key) => TAB_PARAM_MAP[key] === label,
    );
    setSearchParams(paramKey ? { tab: paramKey } : {}, { replace: true });
  };

  const [recentHotelBookings, setRecentHotelBookings] = useState([]);
  const [recentHotelBookingsLoading, setRecentHotelBookingsLoading] = useState(false);

  const heroTitle =
    activeTab === "Flights"
      ? "Book Cheap Flight Tickets With Ease"
      : activeTab === "Insurance"
        ? "Travel Insurance For Your Trip"
        : activeTab === "Car rental"
          ? "Rent A Car For Your Honeymoon Trip"
          : "Book your stay with India's largest network of Hotels.";

  const heroSubtitle =
    activeTab === "Flights"
      ? "Discover your next dream destination"
      : activeTab === "Insurance"
        ? "Compare international, student & multi-trip plans"
        : activeTab === "Car rental"
          ? "Pick up a car at the airport, station or in the city"
          : "Search city stays, romantic escapes, and premium honeymoon-friendly hotels.";

  useEffect(() => {
    let active = true;
    if (!isAuthenticated || !user?.id) {
      setRecentHotelBookings([]);
      return undefined;
    }

    if (activeTab !== "Hotels") {
      return undefined;
    }

    setRecentHotelBookingsLoading(true);
    getRecentHotelBookings({ limit: 3 })
      .then((response) => {
        if (active) {
          setRecentHotelBookings(Array.isArray(response?.bookings) ? response.bookings : []);
        }
      })
      .catch((error) => {
        console.error("Unable to load recent hotel bookings", error);
        if (active) {
          setRecentHotelBookings([]);
        }
      })
      .finally(() => {
        if (active) {
          setRecentHotelBookingsLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [activeTab, isAuthenticated, user?.id]);

  return (
    <>
    <div className="flight-hero">
      <nav className="navbar-custom">
        <div className="container">
          <div className="navbar-content">
            <div className="nav-tabs">
              {[
                {
                  icon: { src: HotelIcon, alt: "Hotels" },
                  label: "Hotels",
                  onClick: () => setActiveTab("Hotels"),
                },
                {
                  icon: { src: FightIcon, alt: "Flights" },
                  label: "Flights",
                  onClick: () => setActiveTab("Flights"),
                },
                {
                  lucide: Shield,
                  label: "Insurance",
                  onClick: () => setActiveTab("Insurance"),
                },

                {
                  icon: { src: CarIcon, alt: "Car rental" },
                  label: "Car rental",
                  onClick: () => setActiveTab("Car rental"),
                },
                {
                  icon: { src: ActivityIcon, alt: "Activities" },
                  label: "Activities",
                  onClick: () => navigate("/travels"),
                },
              ].map((tab) => (
                <button
                  key={tab.label}
                  type="button"
                  className={`nav-tab ${activeTab === tab.label ? "active" : ""}`}
                  onClick={tab.onClick}
                >
                  <span>
                    {tab.lucide ? (
                      <tab.lucide size={18} />
                    ) : typeof tab.icon === "object" ? (
                      <img src={tab.icon.src} alt={tab.icon.alt} />
                    ) : (
                      tab.icon
                    )}
                  </span>{" "}
                  {tab.label}
                </button>
              ))}
            </div>

            <div className="navbar-recommended">
              <span className="navbar-recommended-label">Recommended</span>
              <div
                className="navbar-recommended-pill"
                onClick={() => navigate("/honeymoon/hotels")}
                role="button"
                tabIndex={0}
                onKeyDown={(e) =>
                  e.key === "Enter" && navigate("/honeymoon/hotels")
                }
              >
                <span>🏨</span>
                <span>Recommended hotel</span>
              </div>
              <div className="navbar-recommended-pill">
                <span>✨</span>
                <span>Recommended activity</span>
              </div>
            </div>
          </div>
        </div>
      </nav>

      <div className="container hero-container">
        <span className="plane-icon">✈️</span>

        <div className="row align-items-start">
          <div className="col-12 hero-header">
            <h1 className="hero-title">{heroTitle}</h1>
            <p className="hero-subtitle">{heroSubtitle}</p>

            <div className="stats-row">
              {[
                ["100+", "Airlines"],
                ["20k+", "Travelers"],
                ["10+", "Countries"],
              ].map(([n, l]) => (
                <div key={l} className="stat-item">
                  <div className="stat-num">{n}</div>
                  <div className="stat-label">{l}</div>
                </div>
              ))}
            </div>
          </div>

          <div className="col-12">
            {activeTab === "Flights" ? (
              <FlightSearchForm />
            ) : activeTab === "Insurance" ? (
              <InsuranceSearchPanel formatSelectedDate={formatSelectedDate} />
            ) : activeTab === "Car rental" ? (
              <CarRentalSearchForm />
            ) : (
              <>
                <HotelSearchForm />
                {isAuthenticated ? (
                  <div
                    className="mt-4"
                    style={{
                      background: "rgba(255, 255, 255, 0.16)",
                      border: "1px solid rgba(255, 255, 255, 0.28)",
                      borderRadius: "18px",
                      padding: "1rem",
                    }}
                  >
                    <div className="d-flex justify-content-between align-items-center gap-3 flex-wrap mb-3">
                      <div>
                        <div className="fw-bold text-white">Recent Hotel Bookings</div>
                        <div style={{ color: "rgba(255,255,255,0.8)", fontSize: "0.92rem" }}>
                          Latest bookings from your account
                        </div>
                      </div>
                      <Link
                        to="/hotels/all-booking"
                        style={{
                          background: "#ffffff",
                          color: "#1f2937",
                          borderRadius: "999px",
                          padding: "0.5rem 0.9rem",
                          fontWeight: 700,
                          textDecoration: "none",
                        }}
                      >
                        All Bookings
                      </Link>
                    </div>

                    {recentHotelBookingsLoading ? (
                      <div style={{ color: "rgba(255,255,255,0.8)" }}>Loading bookings...</div>
                    ) : recentHotelBookings.length === 0 ? (
                      <div style={{ color: "rgba(255,255,255,0.8)" }}>No hotel bookings yet.</div>
                    ) : (
                      <div className="row g-3">
                        {recentHotelBookings.map((booking) => (
                          <div className="col-md-4" key={booking.bookingId}>
                            <div
                              style={{
                                background: "rgba(14, 23, 38, 0.45)",
                                borderRadius: "14px",
                                padding: "0.8rem",
                                height: "100%",
                              }}
                            >
                              <div className="fw-semibold text-white">{booking.hotelName || "Booked Hotel"}</div>
                              <div style={{ color: "rgba(255,255,255,0.75)", fontSize: "0.88rem" }}>{booking.bookingId}</div>
                              <div className="mt-2 d-flex justify-content-between">
                                <span style={{ color: "rgba(255,255,255,0.8)", fontSize: "0.86rem" }}>
                                  {booking.checkIn || "Not available"} to {booking.checkOut || "Not available"}
                                </span>
                                <span className="text-white fw-semibold" style={{ fontSize: "0.86rem" }}>
                                  <span style={{ color: getBookingStatusColor(booking.status) }}>
                                    {mapBookingStatusLabel(booking.status)}
                                  </span>
                                </span>
                              </div>
                            </div>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                ) : null}
              </>
            )}
          </div>
        </div>
      </div>
    </div>

    {activeTab === "Flights" && (
      <div className="ub-section">
        <UpcomingBookings />
      </div>
    )}
    </>
  );
}
