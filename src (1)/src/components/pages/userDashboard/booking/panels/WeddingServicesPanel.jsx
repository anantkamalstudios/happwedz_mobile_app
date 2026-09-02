import React, { useCallback, useMemo, useState } from "react";
import {
  FaUser,
  FaEnvelope,
  FaPhone,
  FaCalendarAlt,
  FaMapMarkerAlt,
  FaBan,
  FaChevronDown,
  FaChevronUp,
  FaStore,
} from "react-icons/fa";
import Swal from "sweetalert2";
import axiosInstance from "../../../../../services/api/axiosInstance";
import { normalizeStatus, buildStatusFilters } from "../../../../../utils/bookingStatus";
import { QUOTATIONS_URL } from "../useBookingData";
import BookingCard from "../BookingCard";
import { StatusPills, PanelLoading, PanelEmpty, PanelError } from "./PanelChrome";

/**
 * Vendor quotation requests — every vendor category, not just venues.
 * Photographers, decorators, caterers and banquet halls all land here.
 */
export default function WeddingServicesPanel({ rows, loading, error, onRetry, onUpdate }) {
  const [filter, setFilter] = useState("all");
  const [expanded, setExpanded] = useState({});
  const [cancelling, setCancelling] = useState({});

  const statusOf = useCallback((item) => normalizeStatus(item.status, "quotation"), []);

  const filters = useMemo(
    () => buildStatusFilters("quotation", rows, (item) => statusOf(item).key),
    [rows, statusOf]
  );

  const visible = useMemo(
    () => (filter === "all" ? rows : rows.filter((item) => statusOf(item).key === filter)),
    [rows, filter, statusOf]
  );

  const toggle = (id) => setExpanded((prev) => ({ ...prev, [id]: !prev[id] }));

  const handleCancel = async (requestId) => {
    const confirmed = await Swal.fire({
      title: "Cancel Quotation?",
      text: "Are you sure you want to cancel this quotation request? This action cannot be undone.",
      icon: "warning",
      showCancelButton: true,
      confirmButtonColor: "#d33",
      cancelButtonColor: "#3085d6",
      confirmButtonText: "Yes, cancel it",
      cancelButtonText: "No, keep it",
    });

    if (!confirmed.isConfirmed) return;

    setCancelling((prev) => ({ ...prev, [requestId]: true }));

    try {
      const res = await axiosInstance.delete(`${QUOTATIONS_URL}/${requestId}`);

      if (!res.data?.success) {
        throw new Error(res.data?.message || "Failed to cancel quotation");
      }

      onUpdate?.((current) =>
        current.map((item) =>
          (item.requestId || item.id) === requestId ? { ...item, status: "cancelled" } : item
        )
      );
      Swal.fire("Cancelled!", "Your quotation request has been cancelled.", "success");
    } catch (err) {
      console.error("Error cancelling booking:", err);
      Swal.fire(
        "Error",
        err.response?.data?.message || "Failed to cancel quotation. Please try again.",
        "error"
      );
    } finally {
      setCancelling((prev) => ({ ...prev, [requestId]: false }));
    }
  };

  if (loading) return <PanelLoading label="Loading your service bookings…" />;

  return (
    <>
      {error && <PanelError message={error} onRetry={onRetry} />}
      <StatusPills filters={filters} active={filter} onChange={setFilter} />

      {visible.length === 0 ? (
        <PanelEmpty
          icon={<FaStore />}
          title="No Service Bookings Found"
          text={
            filter === "all"
              ? "You haven't requested a quotation from any vendor yet."
              : `No ${filter} requests at the moment.`
          }
        />
      ) : (
        <div className="hw-bk-grid">
          {visible.map((item) => {
            const status = statusOf(item);
            const requestId = item.requestId || item.id;
            const isOpen = !!expanded[item.id];
            const busy = !!cancelling[requestId];

            return (
              <BookingCard
                key={item.id}
                typeIcon={<FaStore size={10} />}
                typeLabel="Vendor"
                status={status}
                thumb={item.vendor?.profileImage || "/images/imageNotFound.jpg"}
                title={item.vendor?.businessName || "Unknown Vendor"}
                subtitle={
                  <>
                    <FaMapMarkerAlt size={11} />{" "}
                    {[item.vendor?.city, item.vendor?.state].filter(Boolean).join(", ") || "Unknown"}
                  </>
                }
                rows={[
                  { label: "Event date", value: item.eventDate || "—" },
                  {
                    label: "Quote",
                    value: item.quote?.price ? `₹ ${item.quote.price}` : "Awaiting vendor reply",
                  },
                ]}
                actions={
                  <>
                    <button
                      type="button"
                      className="hw-bk-btn hw-bk-btn--ghost"
                      onClick={() => toggle(item.id)}
                    >
                      {isOpen ? <FaChevronUp size={12} /> : <FaChevronDown size={12} />}
                      {isOpen ? "Show Less" : "Show More"}
                    </button>
                    {status.key !== "cancelled" && (
                      <button
                        type="button"
                        className="hw-bk-btn hw-bk-btn--danger"
                        onClick={() => handleCancel(requestId)}
                        disabled={busy}
                      >
                        <FaBan size={12} />
                        {busy ? "Cancelling…" : "Cancel"}
                      </button>
                    )}
                  </>
                }
              >
                {isOpen && (
                  <div className="hw-bk-expand">
                    <div>
                      <p className="hw-bk-expand-title">Booking Details</p>
                      <dl className="hw-bk-rows">
                        <div className="hw-bk-row">
                          <dt><FaUser size={11} /></dt>
                          <dd>{[item.firstName, item.lastName].filter(Boolean).join(" ") || "—"}</dd>
                        </div>
                        <div className="hw-bk-row">
                          <dt><FaEnvelope size={11} /></dt>
                          <dd>{item.email || "—"}</dd>
                        </div>
                        <div className="hw-bk-row">
                          <dt><FaPhone size={11} /></dt>
                          <dd>{item.phone || "—"}</dd>
                        </div>
                        <div className="hw-bk-row">
                          <dt><FaCalendarAlt size={11} /></dt>
                          <dd>{item.eventDate || "—"}</dd>
                        </div>
                      </dl>
                    </div>

                    <div>
                      <p className="hw-bk-expand-title">Quotation Details</p>
                      <dl className="hw-bk-quote">
                        <div className="hw-bk-row">
                          <dt>Quote Price</dt>
                          <dd>{item.quote?.price ? `₹ ${item.quote.price}` : "Not provided"}</dd>
                        </div>
                        <div className="hw-bk-row">
                          <dt>Valid Till</dt>
                          <dd>{item.quote?.validTill || "N/A"}</dd>
                        </div>
                        {item.quote?.message && (
                          <p className="hw-bk-quote-msg">{item.quote.message}</p>
                        )}
                      </dl>
                    </div>
                  </div>
                )}
              </BookingCard>
            );
          })}
        </div>
      )}
    </>
  );
}
