import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axiosInstance from "../../../../services/api/axiosInstance";
import { FaPlane, FaTicketAlt, FaBan, FaClock, FaCheckCircle, FaEye } from "react-icons/fa";
import Loader from "../../../ui/Loader";

const statusIcon = (status) => {
  switch (status) {
    case "confirmed": return <FaCheckCircle className="text-success" />;
    case "cancelled": return <FaBan className="text-danger" />;
    default: return <FaClock className="text-warning" />;
  }
};

const fmt = (dateStr) => {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString("en-IN", {
    day: "numeric", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
};

const countForFilter = (bookings, s) =>
  s === "all" ? bookings.length : bookings.filter((b) => b.booking_status === s).length;

const emptyMessage = (filter) => {
  if (filter === "all") return "You haven't booked any flights yet.";
  return `No ${filter} bookings at the moment.`;
};

export default function FlightBookings() {
  const navigate = useNavigate();
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");

  useEffect(() => {
    axiosInstance
      .get("/tj/my-bookings")
      .then((res) => {
        if (res.data?.status) setBookings(res.data.data || []);
      })
      .catch((err) => console.error("Flight bookings fetch error:", err))
      .finally(() => setLoading(false));
  }, []);

  const filtered =
    filter === "all" ? bookings : bookings.filter((b) => b.booking_status === filter);

  const goToDetail = (booking) => {
    navigate(`/user-dashboard/my-bookings/${booking.order_id}`, { state: { booking } });
  };

  let content;
  if (loading) {
    content = <div className="user-booking-loading"><Loader /></div>;
  } else if (filtered.length === 0) {
    content = (
      <div className="user-booking-empty">
        <div className="user-booking-empty-icon">
          <FaPlane size={64} className="text-muted" />
        </div>
        <h3 className="user-booking-empty-title">No Flight Bookings Found</h3>
        <p className="user-booking-empty-text">{emptyMessage(filter)}</p>
      </div>
    );
  } else {
    content = (
      <div className="user-booking-grid-container">
        <div className="row g-4">
          {filtered.map((booking) => (
            <div key={booking.id} className="col-md-6 col-xl-4">
              <div className="card user-booking-card h-100">
                <div className="card-body user-booking-card-body d-flex flex-column">

                  {/* Header */}
                  <div className="d-flex justify-content-between align-items-center mb-3">
                    <div className="d-flex align-items-center gap-2">
                      <FaPlane className="text-primary" />
                      <strong className="fs-16">
                        {booking.from_iata && booking.to_iata
                          ? `${booking.from_iata} → ${booking.to_iata}`
                          : booking.order_id}
                      </strong>
                    </div>
                    <span className="d-flex align-items-center gap-1 fs-14 text-capitalize">
                      {statusIcon(booking.booking_status)}
                      {booking.booking_status}
                    </span>
                  </div>

                  {/* Flight Info */}
                  <div className="mb-2">
                    <span className="fs-14 text-muted">
                      {[booking.airline, booking.flight_no, booking.cabin_class].filter(Boolean).join(" · ") || "View details for flight info"}
                    </span>
                  </div>
                  {booking.departure && (
                    <div className="mb-2 fs-14">
                      <strong>Depart:</strong> {fmt(booking.departure)}
                    </div>
                  )}
                  {booking.arrival && (
                    <div className="mb-2 fs-14">
                      <strong>Arrive:</strong> {fmt(booking.arrival)}
                    </div>
                  )}

                  {/* Booking Ref */}
                  <div className="d-flex align-items-center gap-2 mb-2">
                    <FaTicketAlt className="text-secondary" />
                    <span className="fs-14">
                      <strong>PNR / Ref:</strong> {booking.pnr || booking.order_id || "—"}
                    </span>
                  </div>

                  {/* Passengers */}
                  <div className="fs-14 mb-2 text-muted">
                    {booking.adults > 0 && `${booking.adults} Adult`}
                    {booking.children > 0 && `, ${booking.children} Child`}
                    {booking.infants > 0 && `, ${booking.infants} Infant`}
                    {" · "}
                    {booking.trip_type === "round_trip" ? "Round Trip" : "One Way"}
                  </div>

                  {/* Price */}
                  <div className="fs-16 fw-bold text-primary mt-2">
                    ₹{Number(booking.price).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                  </div>

                  {/* Booked On */}
                  <div className="fs-12 text-muted mt-1 mb-3">
                    Booked on {fmt(booking.booked_at || booking.createdAt)}
                  </div>

                  {/* View Details */}
                  <div className="mt-auto">
                    <button
                      className="btn btn-outline-primary btn-sm w-100 fs-14"
                      onClick={() => goToDetail(booking)}
                    >
                      <FaEye className="me-2" />
                      View Details
                    </button>
                  </div>

                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="user-booking-container">
      <div className="user-booking-header">
        <div className="user-booking-header-content">
          <div className="user-booking-title-section">
            <h3 className="user-booking-main-title">My Flight Bookings</h3>
            <p className="user-booking-subtitle fs-16">All your flight booking history</p>
          </div>

          <div className="user-booking-filter-section">
            <div className="user-booking-filter-tabs">
              {["all", "confirmed", "cancelled"].map((s) => (
                <button
                  key={s}
                  className={`user-booking-filter-tab fs-16 ${filter === s ? "active" : ""}`}
                  onClick={() => setFilter(s)}
                >
                  {s.charAt(0).toUpperCase() + s.slice(1)} ({countForFilter(bookings, s)})
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      {content}
    </div>
  );
}
