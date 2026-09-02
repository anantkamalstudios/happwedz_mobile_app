import React, { useCallback, useMemo, useState } from "react";
import { useNavigate } from "react-router-dom";
import { FaShieldAlt, FaEye, FaFileDownload } from "react-icons/fa";
import { downloadTripSafePolicyPdf } from "../../../../../services/api/tripSafeApi";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";
import { money, day } from "./format";

const INSURER_LABELS = {
  ABHI: "Aditya Birla Health Insurance",
};

const insurerLabel = (code) =>
  INSURER_LABELS[String(code || "").toUpperCase()] ||
  (code ? `${code} Insurance` : "Insurance partner");

/**
 * Travel insurance policies.
 *
 * This panel is new — GET /insurance_payment/bookings existed on the backend
 * but nothing in the app had ever called it, so a bought policy was only
 * reachable by its direct detail URL.
 */
export default function InsurancePanel({ rows, loading, error, onRetry }) {
  const navigate = useNavigate();
  const [filter, setFilter] = useState("all");
  const [downloading, setDownloading] = useState({});
  const [downloadError, setDownloadError] = useState(null);

  const statusOf = useCallback(
    (booking) => normalizeStatus(booking.booking_status, "insurance"),
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

  const handlePolicy = async (bookingId) => {
    setDownloading((prev) => ({ ...prev, [bookingId]: true }));
    setDownloadError(null);
    try {
      await downloadTripSafePolicyPdf(bookingId);
    } catch {
      setDownloadError("Could not download that policy. Please try again.");
    } finally {
      setDownloading((prev) => ({ ...prev, [bookingId]: false }));
    }
  };

  if (loading) return <PanelLoading label="Loading your insurance bookings…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      {downloadError && <PanelError message={downloadError} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaShieldAlt />}
          title="No Insurance Bookings Found"
          text={
            filter === "all"
              ? "You haven't bought travel insurance yet."
              : `No ${filter} insurance bookings at the moment.`
          }
          ctaLabel="Explore Travel Insurance"
          onCta={() => navigate("/honeymoon/insurance")}
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((booking) => {
            const status = statusOf(booking);
            const policyId = booking.tripjack_booking_id;
            const travellers = Number(booking.traveller_count) || 0;

            return (
              <BookingCard
                key={booking.id}
                typeIcon={<FaShieldAlt size={10} />}
                typeLabel="Insurance"
                status={status}
                title={booking.plan_label || "Insurance Plan"}
                subtitle={insurerLabel(booking.insurer)}
                rows={[
                  {
                    label: "Cover",
                    value:
                      [booking.coverage_amount, booking.region_name]
                        .filter(Boolean)
                        .join(" · ") || "—",
                  },
                  {
                    label: "Valid",
                    value: `${day(booking.start_date)} – ${day(booking.end_date)}`,
                  },
                  {
                    label: "Travellers",
                    value: travellers ? `${travellers} traveller${travellers > 1 ? "s" : ""}` : "—",
                  },
                  { label: "Policy", value: policyId || "—" },
                ]}
                price={money(booking.amount, booking.currency || "INR")}
                priceNote={booking.paid_at ? `Paid ${day(booking.paid_at)}` : null}
                actions={
                  <>
                    <button
                      type="button"
                      className="hw-bk-btn"
                      disabled={!policyId}
                      onClick={() =>
                        navigate(`/honeymoon/insurance/booking/${policyId}`, {
                          state: { booking },
                        })
                      }
                    >
                      <FaEye size={12} />
                      View Policy
                    </button>
                    {status.key === "confirmed" && policyId && (
                      <button
                        type="button"
                        className="hw-bk-btn hw-bk-btn--ghost"
                        onClick={() => handlePolicy(policyId)}
                        disabled={!!downloading[policyId]}
                      >
                        <FaFileDownload size={12} />
                        {downloading[policyId] ? "Downloading…" : "Policy PDF"}
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
