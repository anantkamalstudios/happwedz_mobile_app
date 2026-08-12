import { useEffect, useMemo, useState } from "react";
import { Container } from "react-bootstrap";
import { Link, useNavigate } from "react-router-dom";
import { getAllHotelBookings } from "../../../../services/api/hotelApi";

const STATUS_OPTIONS = [
  { label: "All", value: "" },
  { label: "Pending", value: "PENDING" },
  { label: "Success", value: "SUCCESS" },
  { label: "On Hold", value: "ON_HOLD" },
  { label: "Failed", value: "FAILED" },
  { label: "Cancelled", value: "CANCELLED" },
  { label: "Payment Pending", value: "PAYMENT_PENDING" },
  { label: "Payment Failed", value: "PAYMENT_FAILED" },
  { label: "Book Failed After Payment", value: "BOOK_FAILED_AFTER_PAYMENT" },
];

function getStatusMeta(status) {
  const normalized = String(status || "").toUpperCase();
  if (normalized === "PAYMENT_SUCCESS") {
    return { label: "Payment Success - Pending Voucher", color: "#b26a00", bg: "#fff7e6" };
  }
  if (normalized === "SUCCESS") return { label: "Booking Confirmed", color: "#166534", bg: "#eafaf1" };
  if (normalized === "ON_HOLD") return { label: "Booking On Hold", color: "#1d4ed8", bg: "#e8f0ff" };
  if (["IN_PROGRESS", "PENDING", "PAYMENT_PENDING"].includes(normalized)) {
    return { label: "Booking Processing", color: "#b26a00", bg: "#fff7e6" };
  }
  if (["FAILED", "ABORTED"].includes(normalized)) return { label: "Booking Failed", color: "#b91c1c", bg: "#fdecec" };
  if (normalized === "CANCELLED") return { label: "Cancelled", color: "#7f1d1d", bg: "#fef2f2" };
  return { label: normalized || "PENDING", color: "#334155", bg: "#f1f5f9" };
}

function formatAmount(amount, currency = "INR") {
  const value = Number(amount || 0);
  if (!Number.isFinite(value) || value <= 0) return "Amount unavailable";
  return new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency,
    maximumFractionDigits: 2,
  }).format(value);
}

function formatDate(value) {
  if (!value) return "Not available";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return String(value);
  return date.toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

function isOnHoldStatus(status) {
  return String(status || "").toUpperCase() === "ON_HOLD";
}

export default function HotelBookingsPage() {
  const navigate = useNavigate();
  const [statusFilter, setStatusFilter] = useState("");
  const [loading, setLoading] = useState(false);
  const [bookings, setBookings] = useState([]);
  const [refreshKey, setRefreshKey] = useState(0);

  useEffect(() => {
    let active = true;
    setLoading(true);
    getAllHotelBookings(statusFilter ? { status: statusFilter } : {})
      .then((response) => {
        if (active) {
          setBookings(Array.isArray(response?.bookings) ? response.bookings : []);
        }
      })
      .catch((error) => {
        console.error("Unable to load hotel bookings", error);
        if (active) {
          setBookings([]);
        }
      })
      .finally(() => {
        if (active) {
          setLoading(false);
        }
      });

    return () => {
      active = false;
    };
  }, [statusFilter, refreshKey]);

  const filteredCountLabel = useMemo(() => {
    if (!statusFilter) return `${bookings.length} bookings`;
    const selected = STATUS_OPTIONS.find((option) => option.value === statusFilter);
    return `${bookings.length} ${selected?.label?.toLowerCase() || "filtered"} bookings`;
  }, [bookings.length, statusFilter]);

  return (
    <section
      style={{
        minHeight: "100vh",
        background:
          "linear-gradient(180deg, #f6ebe1 0%, #fbf7f2 32%, #ffffff 100%)",
        padding: "120px 0 64px",
      }}
    >
      <Container>
        <div
          style={{
            background: "#132238",
            color: "#fff",
            borderRadius: "28px",
            padding: "2rem",
            marginBottom: "1.5rem",
          }}
        >
          <div className="d-flex justify-content-between align-items-end gap-3 flex-wrap">
            <div>
              <div style={{ letterSpacing: "0.08em", textTransform: "uppercase", color: "#f4c8d8", fontSize: "0.82rem" }}>
                TripJack Hotel History
              </div>
              <h1 style={{ margin: "0.35rem 0 0.5rem", fontSize: "2.25rem", lineHeight: 1.1 }}>
                All Hotel Bookings
              </h1>
              <div style={{ color: "rgba(255,255,255,0.72)" }}>{filteredCountLabel}</div>
            </div>

            <div className="d-flex align-items-center gap-3 flex-wrap">
              <select
                value={statusFilter}
                onChange={(event) => setStatusFilter(event.target.value)}
                style={{
                  borderRadius: "999px",
                  padding: "0.8rem 1rem",
                  border: "none",
                  minWidth: 220,
                }}
              >
                {STATUS_OPTIONS.map((option) => (
                  <option key={option.value || "all"} value={option.value}>
                    {option.label}
                  </option>
                ))}
              </select>
              <button
                type="button"
                onClick={() => setRefreshKey((current) => current + 1)}
                style={{
                  color: "#132238",
                  background: "#fff",
                  borderRadius: "999px",
                  padding: "0.8rem 1rem",
                  fontWeight: 700,
                  border: "none",
                }}
              >
                Refresh
              </button>
              <Link
                to="/"
                style={{
                  color: "#132238",
                  background: "#fff",
                  borderRadius: "999px",
                  padding: "0.8rem 1rem",
                  fontWeight: 700,
                  textDecoration: "none",
                }}
              >
                Back Home
              </Link>
            </div>
          </div>
        </div>

        {loading ? (
          <div style={{ color: "#334155", fontWeight: 600 }}>Loading hotel bookings...</div>
        ) : bookings.length === 0 ? (
          <div
            style={{
              background: "#fff",
              borderRadius: "24px",
              padding: "2rem",
              boxShadow: "0 20px 40px rgba(15, 23, 42, 0.06)",
            }}
          >
            No hotel bookings found for this account.
          </div>
        ) : (
          <div className="d-grid gap-3">
            {bookings.map((booking) => {
              const statusMeta = getStatusMeta(booking.status);
              return (
              <div
                key={booking.bookingId}
                style={{
                  background: "#fff",
                  borderRadius: "24px",
                  padding: "1.35rem 1.5rem",
                  boxShadow: "0 20px 40px rgba(15, 23, 42, 0.06)",
                }}
              >
                <div className="d-flex justify-content-between gap-3 flex-wrap">
                  <div>
                    <div style={{ fontSize: "1.1rem", fontWeight: 700, color: "#132238" }}>
                      {booking.hotelName || "Booked Hotel"}
                    </div>
                    <div style={{ color: "#64748b", marginTop: "0.25rem" }}>
                      Booking ID: {booking.bookingId}
                    </div>
                    <div style={{ color: "#64748b", marginTop: "0.35rem" }}>
                      Stay: {formatDate(booking.checkIn)} to {formatDate(booking.checkOut)}
                    </div>
                    <div style={{ color: "#64748b", marginTop: "0.35rem" }}>
                      Created: {formatDate(booking.createdAt)}
                    </div>
                  </div>

                  <div className="text-md-end">
                    <div
                      style={{
                        fontWeight: 700,
                        color: statusMeta.color,
                        background: statusMeta.bg,
                        borderRadius: "999px",
                        padding: "0.3rem 0.7rem",
                        display: "inline-block",
                      }}
                    >
                      {statusMeta.label}
                    </div>
                    <div style={{ color: "#475569", marginTop: "0.25rem" }}>
                      Payment: {booking.paymentStatus || "PENDING"}
                    </div>
                    <div style={{ fontWeight: 700, color: "#132238", marginTop: "0.75rem" }}>
                      {formatAmount(booking.amount, booking.currency || "INR")}
                    </div>
                    {String(booking.status || "").toUpperCase() === "PAYMENT_SUCCESS" ? (
                      <button
                        type="button"
                        onClick={() => setRefreshKey((current) => current + 1)}
                        style={{
                          marginTop: "0.75rem",
                          border: "1px solid #f59e0b",
                          color: "#b26a00",
                          background: "#fff",
                          borderRadius: "999px",
                          padding: "0.35rem 0.8rem",
                          fontWeight: 600,
                        }}
                      >
                        Refresh Status
                      </button>
                    ) : null}
                    <button
                      type="button"
                      onClick={() =>
                        navigate(`/hotels/booking/${booking.bookingId}`, {
                          state: { booking },
                        })
                      }
                      style={{
                        marginTop: "0.75rem",
                        marginLeft: "0.5rem",
                        border: isOnHoldStatus(booking.status) ? "1px solid #1d4ed8" : "1px solid #132238",
                        color: isOnHoldStatus(booking.status) ? "#1d4ed8" : "#132238",
                        background: "#fff",
                        borderRadius: "999px",
                        padding: "0.35rem 0.8rem",
                        fontWeight: 600,
                      }}
                    >
                      {isOnHoldStatus(booking.status) ? "Proceed To Confirm & Payment" : "View Details"}
                    </button>
                  </div>
                </div>
              </div>
              );
            })}
          </div>
        )}
      </Container>
    </section>
  );
}
