import { useState } from "react";
import { FaPlane } from "react-icons/fa";
import { cancelFlightBooking } from "../../../../../services/api/flightApi";
import "./CancellationModal.css";

const REASON_GROUPS = [
  {
    group: "Normal Cancellations",
    items: [
      { id: "Travel Plan is Cancelled (Normal Cancellation)", title: "Travel Plan is Cancelled (Normal Cancellation)", desc: "Change in travel plans. Airline charges will apply as per standard airline cancellation policy." },
      { id: "Airline confirmed, refund already processed (offline)", title: "Airline confirmed, refund is already processed", desc: "You have already cancelled your booking offline by directly contacting airline - Tripjack to credit the refund." },
    ],
  },
  {
    group: "Full Refund Cancellations",
    items: [
      { id: "Flight cancelled by the airline, process full refund", title: "Flight cancelled by the airline, process full refund", desc: "Airline cancelled the flight, eligible for full refund as per airline policy." },
      { id: "Airline changed the flight timing, process full refund", title: "Airline changed the flight timing, process full refund", desc: "Eligible for full refund as per Airline Policy. (e.g., 10AM → 6PM)." },
      { id: "Process full refund under DGCA airline policy", title: "Process full refund under DGCA airline policy", desc: "" },
      { id: "Airline confirmed, full refund already processed", title: "Airline confirmed, refund is already processed", desc: "Airline has confirmed and processed full refund to Tripjack." },
    ],
  },
  {
    group: "Void Booking",
    items: [{ id: "Void this booking, process full refund", title: "Void this booking, process full refund", desc: "" }],
  },
  {
    group: "No Show Booking",
    items: [{ id: "Passenger(s) was no-show for the flight", title: "Passenger(s) was no-show for the flight", desc: "Raise amendment after 24 hours of the flight's departure time. Requests made earlier may not be processed." }],
  },
  {
    group: "Other Reason",
    items: [
      { id: "Passenger is medically unfit for travel", title: "Passenger is medically unfit for travel", desc: "Cancel due to illness or medical emergency, attach medical proof/Death Certificate. (As per airline approval)." },
      { id: "Unable to travel due to personal loss or bereavement", title: "Unable to travel due to personal loss or bereavement", desc: "Family bereavement or serious personal emergency; supporting proof required." },
      { id: "Refund under airline empowerment policy", title: "Refund under airline empowerment policy", desc: "Airline has approved refund beyond standard rules. Dependent on Airline Policy." },
    ],
  },
];

const buildPax = (details, fallbackName) => {
  const air = details?.itemInfos?.AIR || {};
  const tv = Array.isArray(air.travellerInfos) ? air.travellerInfos : [];
  const tripPax = [];
  (air.tripInfos || []).forEach((t) => (t.sI || []).forEach((s) => (s.bI?.ti || []).forEach((x) => tripPax.push(x))));
  const count = Math.max(tv.length, tripPax.length, 1);
  const out = [];
  for (let i = 0; i < count; i += 1) {
    const a = tv[i] || {};
    const b = tripPax[i] || {};
    let fN = a.fN || b.fN || "";
    let lN = a.lN || b.lN || "";
    if (!fN && !lN && i === 0 && fallbackName) {
      const parts = fallbackName.split(" ");
      fN = parts[0] || "";
      lN = parts.slice(1).join(" ");
    }
    out.push({
      ti: a.ti || b.ti || "",
      fN, lN,
      pt: a.pt || b.pt || "ADULT",
    });
  }
  return out;
};

export default function CancellationModal({ orderId, details, onClose, onDone }) {
  const air = details?.itemInfos?.AIR || {};
  const seg0 = air.tripInfos?.[0]?.sI?.[0];
  const segLast = air.tripInfos?.[0]?.sI?.slice(-1)[0];
  const fallbackName = details?._fallbackName;
  const pax = buildPax(details, fallbackName);

  const [selectedPax, setSelectedPax] = useState(new Set(pax.map((_, i) => i)));
  const [reason, setReason] = useState("");
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState(null);
  const [error, setError] = useState(null);

  const allSelected = selectedPax.size === pax.length;
  const togglePax = (i) => {
    setSelectedPax((s) => {
      const n = new Set(s);
      n.has(i) ? n.delete(i) : n.add(i);
      return n;
    });
  };
  const toggleAll = () => setSelectedPax(allSelected ? new Set() : new Set(pax.map((_, i) => i)));

  const proceed = async () => {
    if (selectedPax.size === 0) return setError("Please select at least one passenger.");
    if (!reason) return setError("Please select a cancellation reason.");
    if (!window.confirm("Confirm cancellation request? This will raise a cancellation with the airline.")) return;
    setSubmitting(true);
    setError(null);
    try {
      const res = await cancelFlightBooking(orderId, { remarks: reason });
      setResult(res);
      // Notify parent immediately so it can start polling amendment details.
      // The modal stays open briefly showing the success message; parent closes it
      // via onDone → handleCancelDone → setCancelOpen(false).
      onDone?.(res);
    } catch (e) {
      setError(e.response?.data?.message || "Cancellation failed. Please try again.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="cm-overlay" onClick={onClose}>
      <div className="cm-modal" onClick={(e) => e.stopPropagation()}>
        <div className="cm-head">
          <div><span className="cm-muted">Type :</span> <strong>CANCELLATION</strong></div>
          <div><span className="cm-muted">Booking ID :</span> <strong className="cm-blue">{orderId}</strong></div>
          <button className="cm-x" onClick={onClose}>✕</button>
        </div>

        {result ? (
          <div className="cm-body">
            <div className={result.status ? "cm-ok" : "cm-err"}>
              {result.message || (result.status ? "Cancellation request submitted." : "Cancellation failed.")}
            </div>
            <div className="cm-footer">
              <button className="cm-proceed" onClick={onClose}>Done</button>
            </div>
          </div>
        ) : (
          <div className="cm-body">
            {/* 01 Flight Details */}
            <div className="cm-step-title">01. Flight Details</div>
            <div className="cm-flight-card">
              <div className="cm-flight-head">
                <FaPlane className="cm-plane" />
                <div>
                  <div className="cm-airline">{seg0?.fD?.aI?.name || "Flight"}</div>
                  <div className="cm-flightno">{seg0?.fD?.aI?.code}-{seg0?.fD?.fN}</div>
                </div>
                <div className="cm-route">
                  <strong>{seg0?.da?.code}</strong> <FaPlane className="cm-plane sm" /> <strong>{segLast?.aa?.code}</strong>
                </div>
              </div>
              <div className="cm-pax-section">
                <div className="cm-pax-head">
                  <span>Passenger Details :</span>
                  <button className="cm-selectall" onClick={toggleAll}>
                    {allSelected ? "Unselect All" : "Select All Passenger"}
                  </button>
                </div>
                {pax.map((p, i) => (
                  <label key={i} className="cm-pax-row">
                    <input type="checkbox" checked={selectedPax.has(i)} onChange={() => togglePax(i)} />
                    <span>{`${p.ti} ${p.fN} ${p.lN}`.trim().toUpperCase()} ({p.pt[0]})</span>
                  </label>
                ))}
              </div>
            </div>

            {/* 02 Reason */}
            <div className="cm-step-title">02. Select Cancellation Reason</div>
            {REASON_GROUPS.map((g) => (
              <div key={g.group} className="cm-reason-group">
                <div className="cm-reason-group-title">{g.group}</div>
                <div className="cm-reason-items">
                  {g.items.map((it) => (
                    <label key={it.id} className={`cm-reason ${reason === it.id ? "active" : ""}`}>
                      <input type="radio" name="cm-reason" checked={reason === it.id} onChange={() => setReason(it.id)} />
                      <div>
                        <div className="cm-reason-title">{it.title}</div>
                        {it.desc && <div className="cm-reason-desc">{it.desc}</div>}
                      </div>
                    </label>
                  ))}
                </div>
              </div>
            ))}

            {error && <div className="cm-err">{error}</div>}

            <div className="cm-footer">
              <button className="cm-back" onClick={onClose}>Go Back</button>
              <button className="cm-proceed" onClick={proceed} disabled={submitting}>
                {submitting ? "Processing…" : "PROCEED TO CANCELLATION →"}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
