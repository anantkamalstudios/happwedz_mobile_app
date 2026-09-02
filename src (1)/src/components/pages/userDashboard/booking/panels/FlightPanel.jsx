import React, { useCallback, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaPlane, FaEye } from "react-icons/fa";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import InvoiceDownloadButton from "../../../../ui/InvoiceDownloadButton";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";
import { money, dayTime, paxLabel } from "./format";

export default function FlightPanel({ rows, loading, error, onRetry }) {
  const navigate = useNavigate();
  const [filter, setFilter] = useState("all");

  const statusOf = useCallback(
    (booking) => normalizeStatus(booking.booking_status, "flight"),
    []
  );

  const filters = useMemo(
    () => buildStatusFilters("travel", rows, (b) => statusOf(b).key),
    [rows, statusOf]
  );

  const visible = useMemo(
    () => (filter === "all" ? rows : rows.filter((b) => statusOf(b).key === filter)),
    [rows, filter, statusOf]
  );

  if (loading) return <PanelLoading label="Loading your flight bookings…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaPlane />}
          title="No Flight Bookings Found"
          text={
            filter === "all"
              ? "You haven't booked any flights yet."
              : `No ${filter} flight bookings at the moment.`
          }
          ctaLabel="Search Flights"
          onCta={() => navigate("/honeymoon/flights")}
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((booking) => {
            const status = statusOf(booking);

            return (
              <BookingCard
                key={booking.id || booking.order_id}
                typeIcon={<FaPlane size={10} />}
                typeLabel="Flight"
                status={status}
                title={
                  booking.from_iata && booking.to_iata
                    ? `${booking.from_iata} → ${booking.to_iata}`
                    : booking.order_id
                }
                subtitle={
                  [booking.airline, booking.flight_no, booking.cabin_class]
                    .filter(Boolean)
                    .join(" · ") || "View details for flight info"
                }
                rows={[
                  { label: "Depart", value: dayTime(booking.departure) },
                  { label: "Arrive", value: dayTime(booking.arrival) },
                  { label: "PNR / Ref", value: booking.pnr || booking.order_id || "—" },
                  {
                    label: "Travellers",
                    value: `${paxLabel(booking)} · ${
                      booking.trip_type === "round_trip" ? "Round Trip" : "One Way"
                    }`,
                  },
                ]}
                price={money(booking.price)}
                priceNote={
                  booking.booked_at || booking.createdAt
                    ? `Booked ${dayTime(booking.booked_at || booking.createdAt)}`
                    : null
                }
                actions={
                  <>
                    <button
                      type="button"
                      className="hw-bk-btn"
                      onClick={() =>
                        navigate(`/user-dashboard/my-bookings/${booking.order_id}`, {
                          state: { booking },
                        })
                      }
                    >
                      <FaEye size={12} />
                      {status.key === "hold" ? "Pay & Confirm" : "View Details"}
                    </button>
                    {booking.razorpay_order_id && (
                      <InvoiceDownloadButton
                        paymentId={booking.razorpay_order_id}
                        invoiceNumber={booking.order_id}
                        bookingType="flight"
                        className="hw-bk-btn hw-bk-btn--ghost"
                        label="Invoice"
                      />
                    )}
                  </>
                }
              />
            );
          })}
        </div>
      )}
    </>
  );
}
