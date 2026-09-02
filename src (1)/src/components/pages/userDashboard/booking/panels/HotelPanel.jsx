import React, { useCallback, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaHotel, FaEye, FaFileDownload } from "react-icons/fa";
import { downloadHotelVoucher } from "../../../../../services/api/hotelApi";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";
import { money, day, nightsBetween } from "./format";

export default function HotelPanel({ rows, loading, error, onRetry }) {
  const navigate = useNavigate();
  const [filter, setFilter] = useState("all");
  const [downloading, setDownloading] = useState({});
  const [downloadError, setDownloadError] = useState(null);

  const statusOf = useCallback((booking) => normalizeStatus(booking.status, "hotel"), []);

  const filters = useMemo(
    () => buildStatusFilters("travel", rows, (b) => statusOf(b).key),
    [rows, statusOf]
  );

  const visible = useMemo(
    () => (filter === "all" ? rows : rows.filter((b) => statusOf(b).key === filter)),
    [rows, filter, statusOf]
  );

  const handleVoucher = async (bookingId) => {
    setDownloading((prev) => ({ ...prev, [bookingId]: true }));
    setDownloadError(null);
    try {
      await downloadHotelVoucher(bookingId);
    } catch {
      setDownloadError("Could not download that voucher. Please try again.");
    } finally {
      setDownloading((prev) => ({ ...prev, [bookingId]: false }));
    }
  };

  if (loading) return <PanelLoading label="Loading your hotel bookings…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      {downloadError && <PanelError message={downloadError} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaHotel />}
          title="No Hotel Bookings Found"
          text={
            filter === "all"
              ? "You haven't booked any hotels yet."
              : `No ${filter} hotel bookings at the moment.`
          }
          ctaLabel="Search Hotels"
          onCta={() => navigate("/honeymoon/hotels")}
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((booking) => {
            const status = statusOf(booking);
            const nights = nightsBetween(booking.checkIn, booking.checkOut);
            const onHold = status.key === "hold";
            const confirmed = status.key === "confirmed";

            return (
              <BookingCard
                key={booking.bookingId}
                typeIcon={<FaHotel size={10} />}
                typeLabel="Hotel"
                status={status}
                title={booking.hotelName || "Booked Hotel"}
                subtitle={`Booking ID ${booking.bookingId}`}
                rows={[
                  {
                    label: "Stay",
                    value: `${day(booking.checkIn)} – ${day(booking.checkOut)}${
                      nights ? ` · ${nights} night${nights > 1 ? "s" : ""}` : ""
                    }`,
                  },
                  { label: "Payment", value: booking.paymentStatus || "PENDING" },
                  { label: "Booked", value: day(booking.createdAt) },
                ]}
                price={money(booking.amount, booking.currency || "INR")}
                actions={
                  <>
                    <button
                      type="button"
                      className="hw-bk-btn"
                      onClick={() =>
                        navigate(`/hotels/booking/${booking.bookingId}`, {
                          state: { booking },
                        })
                      }
                    >
                      <FaEye size={12} />
                      {onHold ? "Confirm & Pay" : "View Details"}
                    </button>
                    {confirmed && (
                      <button
                        type="button"
                        className="hw-bk-btn hw-bk-btn--ghost"
                        onClick={() => handleVoucher(booking.bookingId)}
                        disabled={!!downloading[booking.bookingId]}
                      >
                        <FaFileDownload size={12} />
                        {downloading[booking.bookingId] ? "Downloading…" : "Voucher"}
                      </button>
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
