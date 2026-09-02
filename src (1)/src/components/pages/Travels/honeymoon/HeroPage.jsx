import { useEffect, useState } from "react";
import { useNavigate, Link, useSearchParams } from "react-router-dom";
import { useSelector } from "react-redux";
import { Shield, Building2, Plane, Car, FileText, Sparkles, Users, Globe } from "lucide-react";
import flightHeroVideo from "../../../../assets/travelbackground/make_this_image_live_just_show.mp4";
import FlightSearchForm from "./components/FlightSearchForm";
import HotelSearchForm from "./components/HotelSearchForm";
import CarRentalSearchForm from "./components/CarRentalSearchForm";
import InsuranceSearchPanel from "./InsuranceSearchPanel";
import UpcomingBookings from "./components/UpcomingBookings";
import { getRecentHotelBookings } from "../../../../services/api/hotelApi";
import { formatDate } from "../../../../utils/dateFormat";
import "./index.css";

const TAB_PARAM_MAP = {
  hotels: "Hotels",
  flights: "Flights",
  insurance: "Insurance",
  "car-rental": "Car rental",
};

const formatSelectedDate = (dateValue) => {
  if (!dateValue) return "";
  return formatDate(dateValue, dateValue);
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

  const renderHeroTitle = () => {
    if (activeTab === "Flights") {
      return (
        <>
          Book Cheap Flight <span className="hero-title-highlight">Tickets With Ease</span>
        </>
      );
    }
    if (activeTab === "Insurance") {
      return (
        <>
          Travel Insurance <span className="hero-title-highlight">For Your Trip</span>
        </>
      );
    }
    if (activeTab === "Car rental") {
      return (
        <>
          Rent A Car For Your <span className="hero-title-highlight">Honeymoon Trip</span>
        </>
      );
    }
    return (
      <>
        Book your stay with <span className="hero-title-highlight">India’s largest network</span> of Hotels.
      </>
    );
  };

  const heroSubtitle =
    activeTab === "Flights"
      ? "Discover your next dream destination"
      : activeTab === "Insurance"
        ? "Compare international, student & multi-trip plans"
        : activeTab === "Car rental"
          ? "Pick up a car at the airport, station or in the city"
          : "Search city stays, romantic escapes, and premium honeymoon-friendly hotels.";

  const statsData = [
    {
      icon: Plane,
      num: "100+",
      label: "AIRLINES",
    },
    {
      icon: Users,
      num: "20K+",
      label: "TRAVELERS",
    },
    {
      icon: Globe,
      num: "10+",
      label: "COUNTRIES",
    },
  ];

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
      <video
        className="flight-hero-video"
        autoPlay
        loop
        muted
        playsInline
      >
        <source src={flightHeroVideo} type="video/mp4" />
      </video>
      <div className="flight-hero-overlay" />
      <nav className="navbar-custom">
        <div className="container">
          <div className="navbar-content">
            <div className="nav-tabs">
              {[
                {
                  lucide: Building2,
                  label: "Hotels",
                  onClick: () => setActiveTab("Hotels"),
                },
                {
                  lucide: Plane,
                  label: "Flights",
                  onClick: () => setActiveTab("Flights"),
                },
                {
                  lucide: Shield,
                  label: "Insurance",
                  onClick: () => setActiveTab("Insurance"),
                },
                {
                  lucide: Car,
                  label: "Car rental",
                  onClick: () => setActiveTab("Car rental"),
                },
                {
                  lucide: FileText,
                  label: "Activities",
                  onClick: () => navigate("/travels"),
                },
              ].map((tab) => {
                const Icon = tab.lucide;
                return (
                  <button
                    key={tab.label}
                    type="button"
                    className={`nav-tab ${activeTab === tab.label ? "active" : ""}`}
                    onClick={tab.onClick}
                  >
                    <Icon size={16} className="nav-tab-icon" />
                    <span>{tab.label}</span>
                  </button>
                );
              })}
            </div>

            <div className="navbar-recommended">
              <div
                className="navbar-recommended-pill"
                onClick={() => navigate("/honeymoon/hotels")}
                role="button"
                tabIndex={0}
                onKeyDown={(e) =>
                  e.key === "Enter" && navigate("/honeymoon/hotels")
                }
              >
                <Building2 size={13} className="rec-icon rec-icon-hotel" />
                <span>Recommended hotel</span>
              </div>
              <div
                className="navbar-recommended-pill"
                onClick={() => navigate("/travels")}
                role="button"
                tabIndex={0}
                onKeyDown={(e) =>
                  e.key === "Enter" && navigate("/travels")
                }
              >
                <Sparkles size={13} className="rec-icon rec-icon-activity" />
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
            <h1 className="hero-title">{renderHeroTitle()}</h1>
            <p className="hero-subtitle">{heroSubtitle}</p>

            <div className="stats-row">
              {statsData.map((item) => {
                const Icon = item.icon;
                return (
                  <div key={item.label} className="stat-item">
                    <div className="stat-icon-badge">
                      <Icon size={20} className="stat-icon" />
                    </div>
                    <div className="stat-text-stack">
                      <div className="stat-num">{item.num}</div>
                      <div className="stat-label">{item.label}</div>
                    </div>
                  </div>
                );
              })}
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
                        to="/user-dashboard/booking/travel/hotels"
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
