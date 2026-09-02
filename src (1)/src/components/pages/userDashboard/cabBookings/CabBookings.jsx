import React, { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import axiosInstance from "../../../../services/api/axiosInstance";
import { FaTaxi, FaCheckCircle, FaBan, FaClock, FaEye, FaMapMarkerAlt } from "react-icons/fa";
import Loader from "../../../ui/Loader";
import InvoiceDownloadButton from "../../../ui/InvoiceDownloadButton";
import { formatDateTime } from "../../../../utils/dateFormat";

const statusIcon = (status) => {
  const statusUpper = String(status || "").toUpperCase();
  switch (statusUpper) {
    case "SUCCESS":
    case "CONFIRMED":
      return <FaCheckCircle className="text-success" />;
    case "CANCELLED":
      return <FaBan className="text-danger" />;
    default:
      return <FaClock className="text-warning" />;
  }
};

const fmt = (dateStr) => {
  if (!dateStr) return "—";
  return formatDateTime(dateStr, { fallback: "—" });
};

const countForFilter = (bookings, s) =>
  s === "all" ? bookings.length : bookings.filter((b) => String(b.booking_status || "").toUpperCase() === s.toUpperCase()).length;

const emptyMessage = (filter) => {
  if (filter === "all") return "You haven't booked any cabs yet.";
  return `No ${filter} bookings at the moment.`;
};

export default function CabBookings() {
  const navigate = useNavigate();
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState("all");

  const fetchBookings = () => {
    setLoading(true);
    axiosInstance
      .get("/tripjack-cabs/invoices")
      .then((res) => {
        if (res.data?.status) {
          // Transform invoice data to booking format
          const transformed = (res.data.invoices || []).map((invoice) => ({
            id: invoice.id,
            tripjack_booking_id: invoice.bookingId,
            razorpay_order_id: invoice.orderId,
            pickup_location: invoice.route?.split(" → ")[0] || "—",
            dropoff_location: invoice.route?.split(" → ")[1] || "—",
            route: invoice.route,
            pickup_datetime: invoice.pickupTime,
            total_amount: invoice.amount,
            currency: invoice.currency,
            payment_status: invoice.paymentStatus,
            booking_status: invoice.bookingStatus,
            passenger_name: invoice.passengerName,
            created_at: invoice.createdAt,
          }));
          setBookings(transformed);
        }
      })
      .catch((err) => console.error("Cab bookings fetch error:", err))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchBookings();
  }, []);

  const filtered =
    filter === "all"
      ? bookings
      : bookings.filter((b) => String(b.booking_status || "").toUpperCase() === filter.toUpperCase());

  let content;
  if (loading) {
    content = <div className="user-booking-loading"><Loader /></div>;
  } else if (filtered.length === 0) {
    content = (
      <div className="user-booking-empty">
        <div className="user-booking-empty-icon">
          <FaTaxi size={64} className="text-muted" />
        </div>
        <h3 className="user-booking-empty-title">No Cab Bookings Found</h3>
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
                      <FaTaxi className="text-primary" />
                      <strong className="fs-16">
                        {booking.route || `Cab Booking #${booking.id}`}
                      </strong>
                    </div>
                    <span className="d-flex align-items-center gap-1 fs-14 text-capitalize">
                      {statusIcon(booking.booking_status)}
                      {booking.booking_status}
                    </span>
                  </div>

                  {/* Route Info */}
                  <div className="mb-2">
                    <div className="d-flex align-items-start gap-2 fs-14 text-muted">
                      <FaMapMarkerAlt className="mt-1 flex-shrink-0" />
                      <div>
                        <div><strong>From:</strong> {booking.pickup_location || "—"}</div>
                        <div><strong>To:</strong> {booking.dropoff_location || "—"}</div>
                      </div>
                    </div>
                  </div>

                  {/* Pickup Time */}
                  {booking.pickup_datetime && (
                    <div className="mb-2 fs-14">
                      <strong>Pickup:</strong> {fmt(booking.pickup_datetime)}
                    </div>
                  )}

                  {/* Passenger */}
                  {booking.passenger_name && (
                    <div className="fs-14 mb-2 text-muted">
                      <strong>Passenger:</strong> {booking.passenger_name}
                    </div>
                  )}

                  {/* Price */}
                  <div className="fs-16 fw-bold text-primary mt-2">
                    ₹{Number(booking.total_amount).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
                  </div>

                  {/* Booked On */}
                  <div className="fs-12 text-muted mt-1 mb-3">
                    Booked on {fmt(booking.created_at)}
                  </div>

                  {/* View Details & Invoice */}
                  <div className="mt-auto">
                    <button
                      className="btn btn-outline-primary btn-sm w-100 fs-14 mb-2"
                      onClick={() => navigate(`/user-dashboard/cab-bookings/${booking.id}`, { state: { booking } })}
                    >
                      <FaEye className="me-2" />
                      View Details
                    </button>
                    {booking.razorpay_order_id && (
                      <InvoiceDownloadButton
                        paymentId={booking.razorpay_order_id}
                        invoiceNumber={booking.id}
                        bookingType="cabs"
                        className="btn btn-outline-secondary btn-sm w-100 fs-14"
                        label="Download Invoice"
                      />
                    )}
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
    <div className="container-fluid py-4">
      {/* Page Header */}
      <div className="d-flex align-items-center justify-content-between mb-4">
        <div>
          <h2 className="mb-1 fw-bold">
            <FaTaxi className="me-2 text-primary" />
            My Cab Bookings
          </h2>
          <p className="text-muted mb-0">View and manage your cab rides</p>
        </div>
        <button
          className="btn btn-outline-primary btn-sm"
          onClick={fetchBookings}
          disabled={loading}
          title="Refresh bookings list"
        >
          {loading ? <span className="spinner-border spinner-border-sm me-2" /> : <FaEye className="me-2" />}
          Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="mb-4">
        <div className="btn-group" role="group">
          {["all", "SUCCESS", "PENDING", "CANCELLED"].map((status) => (
            <button
              key={status}
              className={`btn btn-sm ${
                filter === status ? "btn-primary" : "btn-outline-secondary"
              }`}
              onClick={() => setFilter(status)}
            >
              {status === "all" ? "All" : status}
              <span className="ms-2 badge bg-secondary">
                {countForFilter(bookings, status)}
              </span>
            </button>
          ))}
        </div>
      </div>

      {/* Content */}
      {content}
    </div>
  );
}
