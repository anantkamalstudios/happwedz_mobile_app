import { FaTimes } from "react-icons/fa";
import "./PassengerSummaryModal.css";

const joinKeyed = (obj) =>
  obj && typeof obj === "object"
    ? Object.entries(obj).map(([k, v]) => `${k}: ${v}`)
    : [];

// Build passenger rows defensively from the TripJack booking-details response.
const buildPaxRows = (details, fallbackName) => {
  const air = details?.itemInfos?.AIR || {};
  const order = details?.order || {};
  const status = order.status || details?.status?.status || "CONFIRMED";
  const travellerInfos = Array.isArray(air.travellerInfos) ? air.travellerInfos : [];

  // Names/DOB may live on travellerInfos or inside tripInfos[].sI[].bI.ti[]
  const tripPax = [];
  (air.tripInfos || []).forEach((t) =>
    (t.sI || []).forEach((s) => (s.bI?.ti || []).forEach((ti) => tripPax.push(ti)))
  );

  const count = Math.max(travellerInfos.length, tripPax.length, 1);
  const rows = [];
  for (let i = 0; i < count; i += 1) {
    const tv = travellerInfos[i] || {};
    const tp = tripPax[i] || {};
    const ti = tv.ti || tp.ti || "";
    let fN = tv.fN || tp.fN || "";
    let lN = tv.lN || tp.lN || "";
    if (!fN && !lN && i === 0 && fallbackName) {
      const parts = fallbackName.split(" ");
      fN = parts[0] || "";
      lN = parts.slice(1).join(" ");
    }
    const pt = tv.pt || tp.pt || "ADULT";
    rows.push({
      name: `${ti} ${fN} ${lN}`.trim().toUpperCase() + ` (${(pt[0] || "A")})`,
      dob: tv.dob || tp.dob || "",
      passport: tv.pNum || tp.pNum || "",
      pnr: joinKeyed(tv.pnrDetails),
      ticket: joinKeyed(tv.ticketNumberDetails),
      status,
      ssr: "NA",
    });
  }
  return rows;
};

const statusClass = (s) => {
  const v = String(s || "").toUpperCase();
  if (["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(v)) return "ok";
  if (["ON_HOLD", "PENDING", "PAYMENT_SUCCESS"].includes(v)) return "warn";
  if (["FAILED", "CANCELLED", "ABORTED"].includes(v)) return "bad";
  return "";
};

export default function PassengerSummaryModal({ state, onClose, onViewFull }) {
  const { loading, error, details, booking } = state;
  const rows = details ? buildPaxRows(details, booking?.passenger_name) : [];

  return (
    <div className="psm-overlay" onClick={onClose}>
      <div className="psm-modal" onClick={(e) => e.stopPropagation()}>
        <button className="psm-close" onClick={onClose}><FaTimes /></button>

        <h3 className="psm-title">Passenger Details {rows.length ? `(${rows.length})` : ""}</h3>

        {loading ? (
          <div className="psm-empty">Loading…</div>
        ) : error ? (
          <div className="psm-empty">{error}</div>
        ) : (
          <div className="psm-table-scroll">
            <table className="psm-table">
              <thead>
                <tr>
                  <th>Sr.</th>
                  <th>Name, DOB &amp; Passport</th>
                  <th>PNR, Ticket No. &amp; Status</th>
                  <th>Meal, Baggage, Seat &amp; Other Preference</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={i}>
                    <td>{i + 1}</td>
                    <td>
                      <div className="psm-name">{r.name}</div>
                      <div className="psm-sub">
                        {r.dob || "—"}{r.passport ? `, ${r.passport}` : ""}
                      </div>
                    </td>
                    <td>
                      {r.pnr.length ? (
                        r.pnr.map((p, j) => {
                          const [seg, code] = p.split(": ");
                          return (
                            <div key={j} className="psm-pnr">
                              <span className="psm-seg">{seg}</span>:{" "}
                              <span className="psm-code">{code}</span>
                            </div>
                          );
                        })
                      ) : (
                        <div className="psm-sub">No PNR</div>
                      )}
                      {r.ticket.map((t, j) => (
                        <div key={j} className="psm-sub">Ticket {t}</div>
                      ))}
                      <span className={`psm-status ${statusClass(r.status)}`}>{r.status}</span>
                    </td>
                    <td className="psm-sub">{r.ssr}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {booking?.order_id && (
          <div className="psm-footer">
            <button className="psm-link" onClick={() => onViewFull(booking.order_id)}>
              View full booking →
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
