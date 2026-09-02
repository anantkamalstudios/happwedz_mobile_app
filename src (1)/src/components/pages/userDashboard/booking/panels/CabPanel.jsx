import React, { useCallback, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaTaxi, FaEye } from "react-icons/fa";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import InvoiceDownloadButton from "../../../../ui/InvoiceDownloadButton";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";
import { money, dayTime } from "./format";

export default function CabPanel({ rows, loading, error, onRetry }) {
  const navigate = useNavigate();
  const [filter, setFilter] = useState("all");

  const statusOf = useCallback((booking) => normalizeStatus(booking.bookingStatus, "cab"), []);

  const filters = useMemo(
    () => buildStatusFilters("travel", rows, (b) => statusOf(b).key),
    [rows, statusOf]
  );

  const visible = useMemo(
    () => (filter === "all" ? rows : rows.filter((b) => statusOf(b).key === filter)),
    [rows, filter, statusOf]
  );

  if (loading) return <PanelLoading label="Loading your cab bookings…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaTaxi />}
          title="No Cab Bookings Found"
          text={
            filter === "all"
              ? "You haven't booked any cabs yet."
              : `No ${filter} cab bookings at the moment.`
          }
          ctaLabel="Book a Cab"
          onCta={() => navigate("/honeymoon/cabs")}
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((booking) => (
            <BookingCard
              key={booking.id}
              typeIcon={<FaTaxi size={10} />}
              typeLabel="Cab"
              status={statusOf(booking)}
              title={booking.route || `Cab Booking #${booking.id}`}
              subtitle={booking.tripjackBookingId ? `Ref ${booking.tripjackBookingId}` : null}
              rows={[
                { label: "From", value: booking.pickupLocation },
                { label: "To", value: booking.dropoffLocation },
                { label: "Pickup", value: dayTime(booking.pickupAt) },
                { label: "Passenger", value: booking.passengerName || "—" },
              ]}
              price={money(booking.amount, booking.currency)}
              priceNote={booking.createdAt ? `Booked ${dayTime(booking.createdAt)}` : null}
              actions={
                <>
                  <button
                    type="button"
                    className="hw-bk-btn"
                    onClick={() =>
                      navigate(`/user-dashboard/cab-bookings/${booking.id}`, {
                        state: { booking },
                      })
                    }
                  >
                    <FaEye size={12} />
                    View Details
                  </button>
                  {booking.razorpayOrderId && (
                    <InvoiceDownloadButton
                      paymentId={booking.razorpayOrderId}
                      invoiceNumber={booking.id}
                      bookingType="cabs"
                      className="hw-bk-btn hw-bk-btn--ghost"
                      label="Invoice"
                    />
                  )}
                </>
              }
            />
          ))}
        </div>
      )}
    </>
  );
}
