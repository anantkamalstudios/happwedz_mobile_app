import React, { useState, useEffect } from "react";
import { useLocation, useNavigate, useParams } from "react-router-dom";
import { getFareRule, createFlightPaymentOrder, verifyAndBookFlight } from "../../../../services/api/flightApi";
import {
  FaPlane, FaTicketAlt, FaCheckCircle, FaBan,
  FaClock, FaArrowLeft, FaUsers, FaEnvelope, FaPhone,
  FaChevronDown, FaChevronUp, FaCreditCard,
} from "react-icons/fa";
import CancellationModal from "./CancellationModal";

const loadRazorpay = () =>
  new Promise((resolve) => {
    if (window.Razorpay) return resolve(true);
    const s = document.createElement("script");
    s.src = "https://checkout.razorpay.com/v1/checkout.js";
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.body.appendChild(s);
  });

const policyLabel = (type) => ({ CANCELLATION: "Cancellation", DATECHANGE: "Date Change", NO_SHOW: "No Show", SEAT_CHARGEABLE: "Seat" }[type] || type);
const timeLabel = (p) => {
  if (p.pp) return p.pp.replace(/_/g, " ");
  if (p.et != null && p.st != null) return `${p.st}h – ${p.et}h before departure`;
  return "As per policy";
};
function FareRuleDisplay({ data }) {
  const rule = data?.farerule || {};
  const routes = Object.keys(rule);
  if (!routes.length) return <p className="text-muted small mb-0">No fare rules available.</p>;
  return (
    <div>
      {routes.map((route) => {
        const { tfr, miscInfo } = rule[route];
        return (
          <div key={route} className="mb-3">
            <div className="fw-semibold fs-14 mb-2">{route.replace("-", " → ")}</div>
            {miscInfo?.length ? (
              <pre style={{ fontSize: 12, whiteSpace: "pre-wrap", maxHeight: 180, overflowY: "auto" }}>{miscInfo.join("\n")}</pre>
            ) : tfr ? (
              Object.keys(tfr).map((type) => {
                const policies = Array.isArray(tfr[type]) ? tfr[type] : [tfr[type]];
                return (
                  <div key={type} className="mb-2">
                    <div className="fw-medium fs-13 text-secondary mb-1">{policyLabel(type)}</div>
                    {policies.map((p, i) => (
                      <div key={i} className="d-flex flex-wrap gap-3 fs-13 py-1 border-bottom">
                        <span className="text-muted">{timeLabel(p)}</span>
                        <span>Airline fee: <strong>₹{Number(p.amount || 0).toLocaleString("en-IN")}</strong></span>
                        {p.additionalFee ? <span>Platform fee: <strong>₹{Number(p.additionalFee).toLocaleString("en-IN")}</strong></span> : null}
                        {p.policyInfo ? <span className="text-muted fst-italic">{p.policyInfo}</span> : null}
                      </div>
                    ))}
                  </div>
                );
              })
            ) : (
              <p className="text-muted small mb-0">Contact support for fare rules.</p>
            )}
          </div>
        );
      })}
    </div>
  );
}

const fmt = (dateStr) => {
  if (!dateStr) return "—";
  return new Date(dateStr).toLocaleString("en-IN", {
    day: "numeric", month: "short", year: "numeric",
    hour: "2-digit", minute: "2-digit", hour12: false,
  });
};

const StatusBadge = ({ status }) => {
  const map = {
    confirmed: { icon: <FaCheckCircle />, cls: "text-success", label: "Confirmed" },
    cancelled: { icon: <FaBan />, cls: "text-danger", label: "Cancelled" },
  };
  const s = map[status] || { icon: <FaClock />, cls: "text-warning", label: status };
  return (
    <span className={`d-flex align-items-center gap-1 fw-semibold fs-16 ${s.cls}`}>
      {s.icon} {s.label}
    </span>
  );
};

export default function FlightBookingDetail() {
  const { orderId } = useParams();
  const { state } = useLocation();
  const navigate = useNavigate();

  const [booking, setBooking] = useState(state?.booking || null);
  const [cancelModalOpen, setCancelModalOpen] = useState(false);
  const [cancelRequested, setCancelRequested] = useState(false);
  const [fareRuleOpen, setFareRuleOpen] = useState(false);
  const [fareRuleData, setFareRuleData] = useState(null);
  const [fareRuleLoading, setFareRuleLoading] = useState(false);
  const [liveDataLoading, setLiveDataLoading] = useState(false);
  const [paying, setPaying] = useState(false);

  // Pay for a HELD booking → Razorpay → confirm-book (tickets the held PNR).
  const payConfirm = async () => {
    setPaying(true);
    try {
      const ready = await loadRazorpay();
      if (!ready) throw new Error("Razorpay failed to load");

      const order = await createFlightPaymentOrder({
        provider: "tripjack",
        offer_id: booking.order_id,
        price: booking.amount_paid || booking.price,
        trip_type: booking.trip_type,
        from: booking.from_iata,
        to: booking.to_iata,
        departure: booking.departure,
        arrival: booking.arrival,
        flight_no: booking.flight_no,
        airline: booking.airline,
        cabin_class: booking.cabin_class,
        passengers: [],
        contact: { email: booking.contact_email, phone: booking.contact_phone },
        is_hold_confirm: true,
        booking_payload: { bookingId: booking.order_id },
      });

      const rzpOrderId = order?.razorpay_order_id;
      const key = order?.key_id || import.meta.env.VITE_RAZORPAY_KEY_ID || "";
      if (!rzpOrderId || !key) throw new Error("Could not start payment");

      const rzp = new window.Razorpay({
        key,
        amount: order.amount,
        currency: order.currency || "INR",
        name: "HappyWedz",
        description: "Confirm held flight booking",
        order_id: rzpOrderId,
        prefill: { email: booking.contact_email || "", contact: booking.contact_phone || "" },
        theme: { color: "#ed1173" },
        handler: async (rzpRes) => {
          try {
            const res = await verifyAndBookFlight({
              razorpay_order_id: rzpRes.razorpay_order_id,
              razorpay_payment_id: rzpRes.razorpay_payment_id,
              razorpay_signature: rzpRes.razorpay_signature,
            });
            setBooking((prev) => ({
              ...prev,
              booking_status: "confirmed",
              pnr: res?.pnr || prev.pnr,
            }));
          } catch (err) {
            alert(err.response?.data?.message || "Could not confirm the booking.");
          } finally {
            setPaying(false);
          }
        },
        modal: { ondismiss: () => setPaying(false) },
      });
      rzp.open();
    } catch (err) {
      alert(err.message || "Could not start payment.");
      setPaying(false);
    }
  };

  // If the booking stored in DB is missing flight details (old bookings before the fix),
  // fetch live data from TripJack booking-details and patch the display.
  useEffect(() => {
    const b = state?.booking;
    if (!b || b.provider !== "tripjack" || !b.order_id) return;
    if (b.airline && b.departure && b.from_iata) return; // data already present, skip

    setLiveDataLoading(true);
    import("../../../../services/api/axiosInstance").then(({ default: axiosInstance }) => {
      axiosInstance
        .post("/tj/oms/booking-details", { bookingId: b.order_id })
        .then((res) => {
          const data = res.data || {};
          const airInfo = data?.itemInfos?.AIR || {};
          const tripInfos = Array.isArray(airInfo.tripInfos) ? airInfo.tripInfos : [];
          const travellerInfos = Array.isArray(airInfo.travellerInfos) ? airInfo.travellerInfos : [];

          const firstTrip = tripInfos[0] || {};
          const segs = Array.isArray(firstTrip.sI) ? firstTrip.sI : [];
          const firstSeg = segs[0] || {};
          const lastSeg = segs[segs.length - 1] || firstSeg;

          const pnrMap = travellerInfos[0]?.pnrDetails || {};
          const pnr = Object.values(pnrMap)[0] || null;

          setBooking((prev) => ({
            ...prev,
            from_iata: firstSeg.da?.code || prev.from_iata || "",
            to_iata:   lastSeg.aa?.code  || prev.to_iata  || "",
            airline:   firstSeg.fD?.aI?.name || prev.airline || "",
            flight_no: firstSeg.fD?.aI?.code && firstSeg.fD?.fN
              ? `${firstSeg.fD.aI.code}-${firstSeg.fD.fN}`
              : prev.flight_no || "",
            departure: firstSeg.dt || prev.departure || "",
            arrival:   lastSeg.at || prev.arrival   || "",
            trip_type: tripInfos.length > 1 ? "round_trip" : prev.trip_type || "one_way",
            pnr: pnr || prev.pnr || null,
          }));
        })
        .catch(() => { /* silent — DB data stays as fallback */ })
        .finally(() => setLiveDataLoading(false));
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const handleToggleFareRule = async () => {
    setFareRuleOpen((prev) => !prev);
    if (!fareRuleOpen && !fareRuleData && booking?.order_id) {
      setFareRuleLoading(true);
      try {
        const data = await getFareRule(booking.order_id, "BOOKING_DETAIL");
        setFareRuleData(data);
      } catch {
        setFareRuleData({ error: true });
      } finally {
        setFareRuleLoading(false);
      }
    }
  };

  // Called by CancellationModal when the amendment is submitted.
  // Do NOT close the modal here — the user still needs to see the "THANK YOU" step
  // and click "Done" to close it themselves.
  const handleCancelled = (result) => {
    if (result === "cancelled") {
      setBooking((prev) => ({ ...prev, booking_status: "cancelled" }));
    } else {
      setCancelRequested(true);
    }
  };

  // If no booking passed via state, redirect back to list
  if (!booking) {
    navigate("/user-dashboard/my-bookings", { replace: true });
    return null;
  }

  const isCancelled = booking.booking_status === "cancelled";
  const isOnHold = booking.booking_status === "on_hold";

  return (
    <div className="container py-4" style={{ maxWidth: 720 }}>
      {/* Back */}
      <button
        className="btn btn-link ps-0 mb-3 fs-16 text-decoration-none"
        onClick={() => navigate("/user-dashboard/my-bookings")}
      >
        <FaArrowLeft className="me-2" />
        Back to My Bookings
      </button>

      <div className="card shadow-sm">
        <div className="card-body p-4">

          {/* Header */}
          <div className="d-flex justify-content-between align-items-start mb-4">
            <div>
              <h4 className="mb-1 fw-bold">
                <FaPlane className="me-2 text-primary" />
                {booking.from_iata && booking.to_iata
                  ? `${booking.from_iata} → ${booking.to_iata}`
                  : liveDataLoading
                    ? <span className="text-muted fs-16 fw-normal">Loading flight info…</span>
                    : "—"}
              </h4>
              <span className="text-muted fs-14 text-capitalize">
                {booking.trip_type === "round_trip" ? "Round Trip" : "One Way"} · {booking.cabin_class}
              </span>
            </div>
            <StatusBadge status={booking.booking_status} />
          </div>

          <hr />

          {/* Flight Info */}
          <h6 className="fw-semibold mb-3">Flight Details</h6>
          <div className="row g-3 mb-4">
            <div className="col-6">
              <div className="text-muted fs-13">Airline</div>
              <div className="fs-15 fw-medium">{booking.airline || "—"}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Flight No.</div>
              <div className="fs-15 fw-medium">{booking.flight_no || "—"}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Departure</div>
              <div className="fs-15 fw-medium">{fmt(booking.departure)}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Arrival</div>
              <div className="fs-15 fw-medium">{fmt(booking.arrival)}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Provider</div>
              <div className="fs-15 fw-medium text-capitalize">{booking.provider || "—"}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Booked On</div>
              <div className="fs-15 fw-medium">{fmt(booking.booked_at || booking.createdAt)}</div>
            </div>
          </div>

          <hr />

          {/* Booking Reference */}
          <h6 className="fw-semibold mb-3">
            <FaTicketAlt className="me-2 text-secondary" />
            Booking Reference
          </h6>
          <div className="row g-3 mb-4">
            <div className="col-6">
              <div className="text-muted fs-13">PNR</div>
              <div className="fs-15 fw-bold">{booking.pnr || "—"}</div>
            </div>
            <div className="col-6">
              <div className="text-muted fs-13">Order ID</div>
              <div className="fs-15 fw-medium" style={{ wordBreak: "break-all" }}>
                {booking.order_id || "—"}
              </div>
            </div>
          </div>

          <hr />

          {/* Passengers */}
          <h6 className="fw-semibold mb-3">
            <FaUsers className="me-2 text-secondary" />
            Passengers
          </h6>
          <div className="row g-3 mb-4">
            {booking.adults > 0 && (
              <div className="col-4">
                <div className="text-muted fs-13">Adults</div>
                <div className="fs-15 fw-medium">{booking.adults}</div>
              </div>
            )}
            {booking.children > 0 && (
              <div className="col-4">
                <div className="text-muted fs-13">Children</div>
                <div className="fs-15 fw-medium">{booking.children}</div>
              </div>
            )}
            {booking.infants > 0 && (
              <div className="col-4">
                <div className="text-muted fs-13">Infants</div>
                <div className="fs-15 fw-medium">{booking.infants}</div>
              </div>
            )}
          </div>

          <hr />

          {/* Contact */}
          <h6 className="fw-semibold mb-3">Contact Info</h6>
          <div className="row g-3 mb-4">
            <div className="col-sm-6">
              <div className="d-flex align-items-center gap-2 fs-15">
                <FaEnvelope className="text-muted" />
                {booking.contact_email || "—"}
              </div>
            </div>
            <div className="col-sm-6">
              <div className="d-flex align-items-center gap-2 fs-15">
                <FaPhone className="text-muted" />
                {booking.contact_phone || "—"}
              </div>
            </div>
          </div>

          <hr />

          {/* Price */}
          <div className="d-flex justify-content-between align-items-center mb-4">
            <span className="fs-16 fw-semibold">{isOnHold ? "Amount Due" : "Total Amount Paid"}</span>
            <span className="fs-20 fw-bold text-primary">
              ₹{Number(booking.price).toLocaleString("en-IN", { minimumFractionDigits: 2 })}
            </span>
          </div>

          {/* Fare Rules */}
          <div className="mb-4">
            <button
              type="button"
              className="btn btn-link p-0 fs-14 text-decoration-none d-flex align-items-center gap-2"
              onClick={handleToggleFareRule}
            >
              {fareRuleOpen ? <FaChevronUp /> : <FaChevronDown />}
              View Fare Rules (Cancellation &amp; Date Change policy)
            </button>
            {fareRuleOpen && (
              <div className="mt-2 p-3 rounded" style={{ background: "#f8f9fa" }}>
                {fareRuleLoading && (
                  <div className="text-center py-2">
                    <span className="spinner-border spinner-border-sm me-2" />
                    Loading fare rules…
                  </div>
                )}
                {!fareRuleLoading && fareRuleData?.error && (
                  <p className="text-muted small mb-0">Fare rules unavailable. Please contact support.</p>
                )}
                {!fareRuleLoading && !fareRuleData?.error && (
                  <FareRuleDisplay data={fareRuleData} />
                )}
              </div>
            )}
          </div>

          {/* Cancellation requested banner */}
          {!isCancelled && cancelRequested && (
            <div className="alert alert-info mb-0 fs-14">
              Your cancellation request has been submitted and is being processed.
              The refund will be confirmed shortly.
            </div>
          )}

          {/* On-hold banner */}
          {isOnHold && !cancelRequested && (
            <div className="alert alert-warning mb-3 fs-14">
              <FaClock className="me-2" />
              This fare is on hold. Pay before the deadline to confirm your ticket.
            </div>
          )}

          {/* Action buttons */}
          {!isCancelled && !cancelRequested && (
            <div className="d-flex justify-content-end gap-2">
              {isOnHold && (
                <button
                  className="btn btn-primary px-4"
                  onClick={payConfirm}
                  disabled={paying}
                >
                  <FaCreditCard className="me-2" />
                  {paying ? "Processing…" : "Pay & Confirm"}
                </button>
              )}
              <button
                className="btn btn-danger px-4"
                onClick={() => setCancelModalOpen(true)}
              >
                <FaBan className="me-2" />
                Cancel Booking
              </button>
            </div>
          )}

          {isCancelled && (
            <div className="alert alert-danger mb-0 fs-14">
              This booking has been cancelled.
            </div>
          )}
        </div>
      </div>

      {/* Cancellation multi-step modal */}
      {cancelModalOpen && (
        <CancellationModal
          booking={booking}
          onClose={() => setCancelModalOpen(false)}
          onCancelled={handleCancelled}
        />
      )}
    </div>
  );
}
