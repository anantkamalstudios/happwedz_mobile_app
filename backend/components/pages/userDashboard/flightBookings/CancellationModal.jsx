import React, { useState, useEffect, useCallback } from "react";
import axiosInstance from "../../../../services/api/axiosInstance";

const REASONS = [
  {
    category: "Normal Cancellations",
    color: "#e67e22",
    reasons: [
      "Travel Plan is Cancelled (Normal Cancellation)",
      "Airline confirmed, refund is already processed",
    ],
  },
  {
    category: "Full Refund Cancellations",
    color: "#27ae60",
    reasons: [
      "Flight cancelled by the airline, process full refund",
      "Airline changed the flight timing, process full refund",
      "Process full refund under DGCA airline policy",
      "Airline confirmed, refund is already processed (Full Refund)",
    ],
  },
  {
    category: "Void Booking",
    color: "#8e44ad",
    reasons: ["Void this booking, process full refund"],
  },
  {
    category: "No Show Booking",
    color: "#7f8c8d",
    reasons: ["Passenger(s) was no-show for the flight"],
  },
  {
    category: "Other Reason",
    color: "#555",
    reasons: [
      "Passenger is medically unfit for travel",
      "Unable to travel due to personal loss or bereavement",
      "Refund under airline empowerment policy",
    ],
  },
];

const fmtTime = (dt) => {
  if (!dt) return "--:--";
  const d = new Date(dt);
  return `${String(d.getHours()).padStart(2, "0")}:${String(d.getMinutes()).padStart(2, "0")}`;
};
const fmtDate = (dt) =>
  dt
    ? new Date(dt).toLocaleDateString("en-IN", {
        weekday: "short", day: "numeric", month: "short", year: "numeric",
      })
    : "";
const fmtDur = (mins) =>
  mins ? `${Math.floor(mins / 60)}h ${mins % 60}m` : "";
const paxLabel = (pt) => ({ ADULT: "A", CHILD: "C", INFANT: "I" }[pt] || "A");
const money = (n) =>
  `₹${Number(n || 0).toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;

export default function CancellationModal({ booking, onClose, onCancelled }) {
  const [step, setStep] = useState("loading");
  const [tripInfos, setTripInfos] = useState([]);
  const [travellerInfos, setTravellerInfos] = useState([]);
  const [selected, setSelected] = useState({}); // tripIdx → Set<paxIdx>
  const [reason, setReason] = useState("");
  const [chargesData, setChargesData] = useState(null);
  const [amendmentId, setAmendmentId] = useState(null);
  const [errorMsg, setErrorMsg] = useState("");

  // Load booking details from TripJack on mount
  useEffect(() => {
    (async () => {
      try {
        const res = await axiosInstance.post("/tj/oms/booking-details", {
          bookingId: booking.order_id,
        });
        const data = res.data || {};

        if (data?.order?.status === "CANCELLED") {
          setErrorMsg("This booking is already cancelled.");
          setStep("error");
          return;
        }

        const airInfo = data?.itemInfos?.AIR || {};
        const trips = Array.isArray(airInfo.tripInfos) ? airInfo.tripInfos : [];
        const travellers = Array.isArray(airInfo.travellerInfos) ? airInfo.travellerInfos : [];

        if (!trips.length || !travellers.length) {
          setErrorMsg("Could not load booking details. Please try again.");
          setStep("error");
          return;
        }

        setTripInfos(trips);
        setTravellerInfos(travellers);
        // Pre-select all passengers for every trip
        const init = {};
        trips.forEach((_, ti) => {
          init[ti] = new Set(travellers.map((__, pi) => pi));
        });
        setSelected(init);
        setStep("select");
      } catch (err) {
        setErrorMsg(err.response?.data?.message || err.message || "Failed to load booking.");
        setStep("error");
      }
    })();
  }, [booking.order_id]);

  const togglePax = (tripIdx, paxIdx) => {
    setSelected((prev) => {
      const s = new Set(prev[tripIdx] || []);
      if (s.has(paxIdx)) s.delete(paxIdx);
      else s.add(paxIdx);
      return { ...prev, [tripIdx]: s };
    });
  };

  const selectAll = (tripIdx) => {
    setSelected((prev) => ({
      ...prev,
      [tripIdx]: new Set(travellerInfos.map((_, pi) => pi)),
    }));
  };

  const buildTrips = useCallback(() => {
    return tripInfos
      .map((trip, ti) => {
        const segs = trip.sI || [];
        const first = segs[0] || {};
        const last = segs[segs.length - 1] || first;
        const sel = selected[ti] || new Set();
        return {
          src: first.da?.code || "",
          dest: last.aa?.code || "",
          departureDate: (first.dt || "").split("T")[0],
          travellers: travellerInfos
            .filter((_, pi) => sel.has(pi))
            .map((t) => ({ fn: t.fN || t.fn || "", ln: t.lN || t.ln || "" })),
        };
      })
      .filter((t) => t.src && t.dest && t.departureDate && t.travellers.length > 0);
  }, [tripInfos, travellerInfos, selected]);

  const handleGetCharges = async () => {
    setStep("getting-charges");
    try {
      const res = await axiosInstance.post("/tj/oms/cancel-charges", {
        provider: booking.provider,
        order_id: booking.order_id,
        trips: buildTrips(),
        remarks: reason,
      });
      const d = res.data || {};

      // 2512 = "Previous amendment in progress" — hard block, cannot cancel again
      if (d.err_code === "2512" || d.message?.toLowerCase().includes("amendment in progress")) {
        setErrorMsg(
          "A cancellation for this booking is already in progress. Please check back later or contact support."
        );
        setStep("error");
        return;
      }

      // Any other error (e.g. 2563 "charges not available") is non-blocking —
      // the actual submit-amendment will still work, just without a refund preview.
      setChargesData(d);
      setStep("charges");
    } catch (err) {
      setErrorMsg(err.response?.data?.message || "Failed to get cancellation charges.");
      setStep("error");
    }
  };

  const handleSubmit = async () => {
    setStep("submitting");
    try {
      const res = await axiosInstance.post("/tj/oms/cancel", {
        provider: booking.provider,
        order_id: booking.order_id,
        trips: buildTrips(),
        remarks: reason,
        skipCharges: true,
        charges: chargesData,
      });
      const d = res.data || {};
      if (!d.status) {
        setErrorMsg(d.message || "Cancellation failed. Please try again.");
        setStep("error");
        return;
      }
      setAmendmentId(d.amendment_id);
      setStep("done");
      onCancelled(d.cancelled ? "cancelled" : "requested");
    } catch (err) {
      setErrorMsg(err.response?.data?.message || "Cancellation failed. Please try again.");
      setStep("error");
    }
  };

  const anySelected = Object.values(selected).some((s) => s.size > 0);
  const canProceed = anySelected && reason.trim().length > 0;

  // ── Trip card ──────────────────────────────────────────────────────────────
  const renderTripCard = (trip, ti) => {
    const segs = trip.sI || [];
    const first = segs[0] || {};
    const last = segs[segs.length - 1] || first;
    const airline = first.fD?.aI || {};
    const duration = segs.reduce((s, seg) => s + (seg.duration || 0), 0);
    const flightNums = segs.map((s) => `${s.fD?.aI?.code || ""}-${s.fD?.fN || ""}`).join(", ");
    const stops = segs.length - 1;
    const sel = selected[ti] || new Set();

    return (
      <div key={ti} className="border rounded p-3 mb-3">
        <div className="d-flex align-items-start gap-3 mb-3">
          <img
            src={`https://airlines.airhex.com/airlines-logo/${(airline.code || "").toLowerCase()}.png`}
            alt={airline.name}
            style={{ width: 40, height: 40, objectFit: "contain", flexShrink: 0 }}
            onError={(e) => { e.target.style.display = "none"; }}
          />
          <div>
            <div className="fw-semibold fs-15">{airline.name} · {flightNums}</div>
            <div className="fs-13 text-muted">
              <strong>{first.da?.code}</strong> ({fmtTime(first.dt)}) → <strong>{last.aa?.code}</strong> ({fmtTime(last.at)})
              <span className="ms-2">{fmtDur(duration)}</span>
              <span className="ms-2">· {stops === 0 ? "Non-Stop" : `${stops} Stop${stops > 1 ? "s" : ""}`}</span>
            </div>
            <div className="fs-12 text-muted">{fmtDate(first.dt)}</div>
          </div>
        </div>

        <div className="d-flex align-items-center justify-content-between mb-2">
          <span className="fs-13 fw-medium">Passenger Details :</span>
          <button
            type="button"
            className="btn btn-sm btn-outline-primary py-0 px-2 fs-12"
            onClick={() => selectAll(ti)}
          >
            Select All Passenger
          </button>
        </div>

        {travellerInfos.map((t, pi) => (
          <div
            key={pi}
            className="d-flex align-items-center gap-2 py-1 ps-1"
            style={{ cursor: "pointer" }}
            onClick={() => togglePax(ti, pi)}
          >
            <input
              type="checkbox"
              checked={sel.has(pi)}
              onChange={() => {}}
              style={{ cursor: "pointer", accentColor: "#e67e22", width: 16, height: 16 }}
            />
            <span className="fs-14">
              {t.ti ? `${t.ti}. ` : ""}
              {t.fN || t.fn} {t.lN || t.ln} ({paxLabel(t.pt)})
            </span>
          </div>
        ))}
      </div>
    );
  };

  // ── Step bodies ────────────────────────────────────────────────────────────
  const renderBody = () => {
    if (step === "loading" || step === "getting-charges" || step === "submitting") {
      const msgs = {
        loading: "Loading booking details…",
        "getting-charges": "Getting cancellation charges…",
        submitting: "Processing your cancellation…",
      };
      return (
        <div className="text-center py-5">
          <div className="spinner-border text-warning mb-3" />
          <div className="text-muted">{msgs[step]}</div>
        </div>
      );
    }

    if (step === "select") {
      return (
        <>
          <div className="mb-1">
            <div className="fw-semibold fs-14 mb-2 text-secondary">01. Flight Details</div>
            {tripInfos.map((trip, ti) => renderTripCard(trip, ti))}
          </div>
          <div>
            <div className="fw-semibold fs-14 mb-3 text-secondary">02. Select Cancellation Reason From Below</div>
            {REASONS.map((group) => (
              <div key={group.category} className="mb-3">
                <div className="fw-medium fs-13 mb-2" style={{ color: group.color }}>
                  {group.category}
                </div>
                <div className="row g-2">
                  {group.reasons.map((r) => (
                    <div key={r} className="col-md-6">
                      <div
                        className={`p-2 rounded border fs-13 ${reason === r ? "border-warning bg-warning bg-opacity-10" : "border-light"}`}
                        style={{ cursor: "pointer" }}
                        onClick={() => setReason(r)}
                      >
                        <input
                          type="radio"
                          className="me-2"
                          checked={reason === r}
                          onChange={() => setReason(r)}
                          style={{ accentColor: "#e67e22" }}
                        />
                        {r}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </>
      );
    }

    if (step === "charges") {
      const refund = chargesData?.refund_amount;
      const charge = chargesData?.amendment_charges;
      const chargesAvailable = chargesData?.available && refund != null;

      return (
        <div>
          {chargesAvailable ? (
            <>
              <div
                className="rounded p-3 mb-2 d-flex justify-content-between align-items-center"
                style={{ background: "#fff8f0", border: "1px solid #f0c080" }}
              >
                <span className="fs-15 fw-medium">Approximate Refund Amount:</span>
                <strong className="fs-18" style={{ color: "#27ae60" }}>
                  {money(refund)}
                </strong>
              </div>
              {charge > 0 && (
                <div className="d-flex justify-content-between fs-13 text-muted mb-3 px-1">
                  <span>Cancellation charges:</span>
                  <span>{money(charge)}</span>
                </div>
              )}
            </>
          ) : (
            <div
              className="rounded p-3 mb-3 fs-14 text-muted"
              style={{ background: "#f8f9fa", border: "1px solid #dee2e6" }}
            >
              <strong className="d-block mb-1">Refund charges not available right now.</strong>
              {chargesData?.message || "The refund amount will be confirmed after cancellation. TripJack support will process it as per the airline policy."}
            </div>
          )}

          <ul className="text-muted fs-13 ps-4 mb-0" style={{ lineHeight: 1.7 }}>
            <li>Once cancelled, we'll coordinate with the airline and process the refund as per their policy.</li>
            <li>Until the refund is received, the request will remain in "Pending with supplier" status.</li>
          </ul>
          <p className="mt-3 fs-14 fw-medium">
            Do you want to cancel the booking and proceed?
          </p>
        </div>
      );
    }

    if (step === "confirm") {
      return (
        <div className="text-center py-4">
          <p className="fs-16 mb-1">Booking will be auto cancelled.</p>
          <p className="fs-15 text-muted">Are you sure?</p>
        </div>
      );
    }

    if (step === "done") {
      return (
        <div className="text-center py-4">
          <div
            className="d-inline-flex flex-column align-items-center rounded px-5 py-3 mb-4"
            style={{ background: "#f0f8ff", border: "1px solid #cce0ff" }}
          >
            <span className="text-muted fs-13 mb-1">Your Amendment ID:</span>
            <span className="fw-bold fs-20" style={{ color: "#e67e22" }}>
              {amendmentId || "—"}
            </span>
          </div>
          <p className="fs-15 fw-semibold text-success">Your Booking has been cancelled Successfully.</p>
        </div>
      );
    }

    if (step === "error") {
      return (
        <div className="text-center py-4">
          <p className="text-danger fs-15">{errorMsg}</p>
        </div>
      );
    }

    return null;
  };

  // ── Footer buttons ─────────────────────────────────────────────────────────
  const renderFooter = () => {
    if (["loading", "getting-charges", "submitting"].includes(step)) return null;

    if (step === "select") {
      return (
        <div className="d-flex justify-content-between w-100">
          <button className="btn btn-outline-secondary" onClick={onClose}>
            Go Back
          </button>
          <button
            className="btn px-4 text-white"
            style={{ background: "#e67e22", borderColor: "#e67e22" }}
            disabled={!canProceed}
            onClick={handleGetCharges}
          >
            PROCEED TO CANCELLATION →
          </button>
        </div>
      );
    }

    if (step === "charges") {
      return (
        <div className="d-flex justify-content-between w-100">
          <button className="btn btn-outline-secondary" onClick={() => setStep("select")}>
            CLOSE
          </button>
          <button
            className="btn px-4 text-white"
            style={{ background: "#e67e22", borderColor: "#e67e22" }}
            onClick={() => setStep("confirm")}
          >
            PROCEED TO REFUND
          </button>
        </div>
      );
    }

    if (step === "confirm") {
      return (
        <div className="d-flex justify-content-between w-100">
          <button className="btn btn-outline-secondary" onClick={() => setStep("charges")}>
            Back
          </button>
          <button className="btn btn-danger px-4" onClick={handleSubmit}>
            Proceed
          </button>
        </div>
      );
    }

    if (step === "done") {
      return (
        <button className="btn btn-primary w-100" onClick={onClose}>
          Done
        </button>
      );
    }

    if (step === "error") {
      return (
        <div className="d-flex gap-2 w-100">
          <button className="btn btn-outline-secondary flex-grow-1" onClick={onClose}>
            Close
          </button>
          {!errorMsg.includes("already cancelled") && !errorMsg.includes("already in progress") && (
            <button
              className="btn btn-primary flex-grow-1"
              onClick={() => { setStep("loading"); setErrorMsg(""); }}
            >
              Try Again
            </button>
          )}
        </div>
      );
    }

    return null;
  };

  const stepTitle = {
    loading: null,
    select: null,
    "getting-charges": null,
    charges: "CANCELLATION & REFUND DETAILS",
    confirm: null,
    submitting: null,
    done: "THANK YOU",
    error: null,
  }[step];

  const footer = renderFooter();

  return (
    <div
      style={{
        position: "fixed", top: 0, left: 0, right: 0, bottom: 0,
        backgroundColor: "rgba(0,0,0,0.55)",
        zIndex: 1055,
        display: "flex", alignItems: "flex-start", justifyContent: "center",
        overflowY: "auto", padding: "2rem 1rem",
      }}
      onClick={(e) => {
        if (e.target === e.currentTarget && !["submitting", "getting-charges"].includes(step))
          onClose();
      }}
    >
      <div
        style={{
          background: "#fff", borderRadius: 8, width: "100%", maxWidth: 740,
          boxShadow: "0 8px 32px rgba(0,0,0,0.18)",
        }}
      >
        {/* Header */}
        <div
          className="d-flex justify-content-between align-items-center px-4 py-3 border-bottom"
          style={{ background: "#fff8f0", borderRadius: "8px 8px 0 0" }}
        >
          <div>
            <span className="fw-bold fs-14 me-3" style={{ color: "#e67e22" }}>
              Type : CANCELLATION
            </span>
            <span className="text-muted fs-13">Booking ID : </span>
            <span className="fw-semibold fs-13" style={{ color: "#e67e22" }}>
              {booking.order_id}
            </span>
          </div>
          {!["submitting", "getting-charges", "loading"].includes(step) && (
            <button
              type="button"
              className="btn-close"
              onClick={onClose}
              aria-label="Close"
            />
          )}
        </div>

        {stepTitle && (
          <div className="px-4 pt-3 pb-1">
            <h5 className="fw-bold mb-0" style={{ color: "#e67e22" }}>{stepTitle}</h5>
          </div>
        )}

        {/* Body */}
        <div className="px-4 py-3" style={{ maxHeight: "62vh", overflowY: "auto" }}>
          {renderBody()}
        </div>

        {/* Footer */}
        {footer && (
          <div className="px-4 py-3 border-top d-flex">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}
