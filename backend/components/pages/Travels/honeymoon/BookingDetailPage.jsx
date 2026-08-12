import { useState, useEffect, useCallback } from "react";
import { useParams, useNavigate } from "react-router-dom";
import { FaPlane, FaArrowLeft, FaChevronDown, FaChevronUp } from "react-icons/fa";
import {
  getBookingDetails,
  getFlightBookingRecord,
  getFareRule,
  getFlightCancelCharges,
  pollAmendment,
} from "../../../../services/api/flightApi";
import CancellationModal from "./components/CancellationModal";
import "./BookingDetailPage.css";

// ── formatting helpers ───────────────────────────────────────────────────────
const fmtMoney = (v) =>
  v == null || v === "" ? "—" : `₹${Number(v).toLocaleString("en-IN", { minimumFractionDigits: 2 })}`;
const fmtTime = (v) => {
  if (!v) return "—";
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? "—" : d.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: false });
};
const fmtDate = (v) => {
  if (!v) return "—";
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? "—" : d.toLocaleDateString("en-US", { day: "numeric", month: "short", year: "numeric" });
};
const fmtDateTime = (v) => {
  if (!v) return "—";
  const d = new Date(v);
  return Number.isNaN(d.getTime()) ? "—" : `${fmtDate(v)} ${fmtTime(v)}`;
};
const joinValues = (obj) =>
  obj && typeof obj === "object" ? Object.values(obj).filter(Boolean).join(", ") : obj || "";

const statusClass = (s) => {
  const v = String(s || "").toUpperCase();
  if (["SUCCESS", "CONFIRMED", "VOUCHERED"].includes(v)) return "ok";
  if (["ON_HOLD", "PENDING", "PAYMENT_SUCCESS", "IN_PROGRESS"].includes(v)) return "warn";
  if (["FAILED", "CANCELLED", "ABORTED", "UNCONFIRMED"].includes(v)) return "bad";
  return "";
};

const Field = ({ label, value }) => (
  <div className="bd-field">
    <div className="bd-field-label">{label}</div>
    <div className="bd-field-value">{value ?? "—"}</div>
  </div>
);

const FR_LABELS = {
  CANCELLATION: "Cancellation",
  DATECHANGE: "Date Change",
  NO_SHOW: "No Show",
  SEAT_CHARGEABLE: "Seat",
};

// Render TripJack fare rules (tfr categories or plain-text miscInfo) as readable tables.
const FareRulesView = ({ data }) => {
  const fr = data?.farerule || data || {};
  const routeKeys = Object.keys(fr).filter(
    (k) => fr[k] && typeof fr[k] === "object" && (fr[k].tfr || fr[k].miscInfo)
  );
  if (!routeKeys.length) return <div className="bd-muted">No structured fare rules available.</div>;

  return (
    <div className="bd-farerules">
      {routeKeys.map((rk) => {
        const node = fr[rk];
        const tfr = node.tfr || {};
        const misc = node.miscInfo;
        return (
          <div key={rk} className="bd-fr-route">
            <div className="bd-fr-route-title">{rk}</div>
            {misc &&
              (Array.isArray(misc) ? misc : [misc]).map((m, i) => (
                <div key={i} className="bd-fr-misc">{typeof m === "string" ? m : m.mi || JSON.stringify(m)}</div>
              ))}
            {Object.keys(tfr).map((cat) => (
              <div key={cat} className="bd-fr-cat">
                <div className="bd-fr-cat-title">{FR_LABELS[cat] || cat}</div>
                <div className="bd-table-scroll">
                  <table className="bd-table">
                    <thead>
                      <tr><th>Airline Fee</th><th>HappyWedz Fee</th><th>When</th><th>Policy</th></tr>
                    </thead>
                    <tbody>
                      {(tfr[cat] || []).map((p, i) => (
                        <tr key={i}>
                          <td>{p.amount != null ? fmtMoney(p.amount) : "—"}</td>
                          <td>{p.additionalFee != null ? fmtMoney(p.additionalFee) : "—"}</td>
                          <td>
                            {p.pp
                              ? p.pp.replace(/_/g, " ")
                              : p.st != null && p.et != null
                              ? `${p.st}–${p.et} hrs before departure`
                              : "—"}
                          </td>
                          <td className="bd-fr-policy">{(p.policyInfo || "").replace(/__nls__/g, " ")}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            ))}
          </div>
        );
      })}
    </div>
  );
};

const Section = ({ title, right, children, defaultOpen = true, onFirstOpen }) => {
  const [open, setOpen] = useState(defaultOpen);
  const [opened, setOpened] = useState(defaultOpen);
  const toggle = () => {
    setOpen((o) => {
      const next = !o;
      if (next && !opened) {
        setOpened(true);
        onFirstOpen?.();
      }
      return next;
    });
  };
  return (
    <div className="bd-section">
      <div className="bd-section-head" onClick={toggle}>
        <h3>{title}</h3>
        <div className="bd-section-head-right" onClick={(e) => e.stopPropagation()}>
          {right}
          <button className="bd-collapse" onClick={toggle}>
            {open ? <FaChevronUp /> : <FaChevronDown />}
          </button>
        </div>
      </div>
      {open && <div className="bd-section-body">{children}</div>}
    </div>
  );
};

export default function BookingDetailPage() {
  const { orderId } = useParams();
  const navigate = useNavigate();

  const [details, setDetails] = useState(null); // TripJack booking-details
  const [record, setRecord] = useState(null); // our DB record
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  const [fareRule, setFareRule] = useState(null);
  const [fareRuleLoading, setFareRuleLoading] = useState(false);

  const [cancelOpen, setCancelOpen] = useState(false);
  const [quote, setQuote] = useState({ loading: false, data: null, error: null });
  const [amendInfo, setAmendInfo] = useState("");
  const [amendment, setAmendment] = useState({ loading: false, data: null, cancelResult: null });

  // Called when CancellationModal completes — store result + poll for amendment details.
  const handleCancelDone = async (cancelResult) => {
    setCancelOpen(false);
    setAmendment({ loading: true, data: null, cancelResult });
    const amendmentId = cancelResult?.amendment_id;
    if (!amendmentId) {
      setAmendment({ loading: false, data: null, cancelResult });
      return;
    }
    try {
      const res = await pollAmendment(amendmentId);
      setAmendment({ loading: false, data: res, cancelResult });
    } catch {
      setAmendment({ loading: false, data: null, cancelResult });
    }
  };

  useEffect(() => {
    let active = true;
    (async () => {
      const [d, r] = await Promise.allSettled([
        getBookingDetails(orderId, true),
        getFlightBookingRecord(orderId),
      ]);
      if (!active) return;
      if (d.status === "fulfilled") setDetails(d.value);
      if (r.status === "fulfilled" && r.value?.status) {
        setRecord(r.value);
        // If a previous cancellation was raised, auto-load amendment details.
        const prevAmendmentId = r.value?.amendment_id;
        if (prevAmendmentId) {
          setAmendment((a) => ({ ...a, loading: true, cancelResult: { amendment_id: prevAmendmentId, amendment_status: r.value?.amendment_status } }));
          try {
            const amRes = await pollAmendment(prevAmendmentId);
            if (active) setAmendment({ loading: false, data: amRes, cancelResult: { amendment_id: prevAmendmentId, amendment_status: r.value?.amendment_status } });
          } catch {
            if (active) setAmendment({ loading: false, data: null, cancelResult: { amendment_id: prevAmendmentId, amendment_status: r.value?.amendment_status } });
          }
        }
      }
      if (d.status !== "fulfilled" && r.status !== "fulfilled") {
        setError("Could not load this booking.");
      }
      setLoading(false);
    })();
    return () => {
      active = false;
    };
  }, [orderId]);

  const loadFareRule = useCallback(async () => {
    if (fareRule || fareRuleLoading) return;
    setFareRuleLoading(true);
    try {
      const res = await getFareRule(orderId, "BOOKING_DETAIL");
      setFareRule(res);
    } catch {
      setFareRule({ error: true });
    } finally {
      setFareRuleLoading(false);
    }
  }, [orderId, fareRule, fareRuleLoading]);

  // "Get Cancel Quotation" — preview charges without raising the amendment.
  const getQuote = async () => {
    setQuote({ loading: true, data: null, error: null });
    try {
      const res = await getFlightCancelCharges(orderId);
      setQuote({ loading: false, data: res, error: null });
    } catch (e) {
      setQuote({ loading: false, data: null, error: e.response?.data?.message || "Could not fetch charges." });
    }
  };

  if (loading) {
    return <div className="bd-page"><div className="bd-loading">Loading booking…</div></div>;
  }
  if (error) {
    return (
      <div className="bd-page">
        <button className="bd-back" onClick={() => navigate(-1)}><FaArrowLeft /> Back</button>
        <div className="bd-loading">{error}</div>
      </div>
    );
  }

  // ── derive data (defensive) ────────────────────────────────────────────────
  const order = details?.order || {};
  const air = details?.itemInfos?.AIR || {};
  const tripInfos = Array.isArray(air.tripInfos) ? air.tripInfos : [];
  const travellerInfos = Array.isArray(air.travellerInfos) ? air.travellerInfos : [];
  const totalPriceInfo = air.totalPriceInfo || details?.totalPriceInfo || {};
  const fc = totalPriceInfo.fc || totalPriceInfo.totalFareDetail?.fC || {};
  const afc = totalPriceInfo.afc || totalPriceInfo.totalFareDetail?.afC || {};
  const flexFee = afc?.TAF?.FTC ?? afc?.FTC ?? 0;

  const bk = record?.booking || {};
  const pay = record?.payment || null;
  const contact = record?.contact || {};
  const passengers = record?.passengers || [];

  const orderStatus = order.status || details?.status?.status || bk.booking_status || "—";
  const amount = order.amount ?? pay?.amount ?? bk.price;

  // flight (prefer TripJack segments, fall back to our DB)
  const segments = tripInfos[0]?.sI || [];
  const first = segments[0];
  const last = segments[segments.length - 1];
  const fareType = tripInfos[0]?.totalPriceList?.[0]?.fareIdentifier || bk.fare_type || "";

  const emails = contact.email ? [contact.email] : (order.deliveryInfo?.emails || []);
  const contacts = contact.phone ? [contact.phone] : (order.deliveryInfo?.contacts || []);

  return (
    <div className="bd-page">
      <button className="bd-back" onClick={() => navigate(-1)}><FaArrowLeft /> Back to bookings</button>

      {/* ── Cart Information ── */}
      <Section
        title={`Cart Information : ${orderId}`}
        right={<span className={`bd-status ${statusClass(orderStatus)}`}>{orderStatus}</span>}
      >
        <div className="bd-grid">
          <Field label="Booking Id" value={orderId} />
          <Field label="Amount" value={fmtMoney(amount)} />
          <Field label="Status" value={orderStatus} />
          <Field label="Order Type" value="Air" />
          <Field label="Channel Type" value="API" />
          <Field label="Flow Type" value="Online" />
          <Field label="Booking Date" value={fmtDateTime(bk.booked_at)} />
          <Field label="Contact Email" value={emails[0] || "—"} />
        </div>
        {order.orderNote && <div className="bd-note">Note: {order.orderNote}</div>}
      </Section>

      {/* ── Booking Details (flight + passengers + fares) ── */}
      <Section title="Booking Details">
        {first ? (
          <div className="bd-flight">
            <div className="bd-flight-airline">
              <FaPlane />
              <div>
                <div className="bd-flight-name">{first.fD?.aI?.name || bk.airline || "—"}</div>
                <div className="bd-flight-no">{first.fD?.aI?.code}-{first.fD?.fN}</div>
              </div>
            </div>
            <div className="bd-flight-route">
              <div className="bd-leg">
                <div className="bd-leg-city">{first.da?.city || first.da?.code}</div>
                <div className="bd-leg-time">{fmtTime(first.dt)}, {fmtDate(first.dt)}</div>
                {first.da?.terminal && <div className="bd-leg-term">Terminal {first.da.terminal}</div>}
              </div>
              <div className="bd-leg-mid">
                {segments.length - 1 === 0 ? "Non-Stop" : `${segments.length - 1} Stop(s)`}
                <span className="bd-leg-arrow">→</span>
              </div>
              <div className="bd-leg">
                <div className="bd-leg-city">{last.aa?.city || last.aa?.code}</div>
                <div className="bd-leg-time">{fmtTime(last.at)}, {fmtDate(last.at)}</div>
                {last.aa?.terminal && <div className="bd-leg-term">Terminal {last.aa.terminal}</div>}
              </div>
            </div>
          </div>
        ) : (
          <div className="bd-flight bd-flight-fallback">
            <FaPlane /> {bk.airline} {bk.flight_no} · {bk.from_iata} → {bk.to_iata} · {fmtDateTime(bk.departure)}
          </div>
        )}

        {/* passengers */}
        <div className="bd-pax-list">
          {(passengers.length ? passengers : travellerInfos).map((p, i) => {
            const ti = travellerInfos[i] || {};
            const name = `${p.lN || p.last_name || ti.lN || ""}/${p.fN || p.first_name || ti.fN || ""} ${p.ti || ti.ti || ""}`.trim();
            return (
              <div key={i} className="bd-pax">
                <div className="bd-pax-head">
                  <strong>{i + 1}. {name || "Passenger"}</strong>
                  <span className="bd-pax-type">{p.pt || ti.pt || "ADULT"}</span>
                </div>
                <div className="bd-grid">
                  <Field label="DOB" value={p.dob || ti.dob || "—"} />
                  <Field label="Fare Type" value={fareType || "—"} />
                  <Field label="Airline PNR" value={joinValues(ti.pnrDetails) || bk.pnr || "—"} />
                  <Field label="GDS PNR" value={joinValues(ti.gdsPnrs) || "—"} />
                  <Field label="Ticket Number" value={joinValues(ti.ticketNumberDetails) || "—"} />
                  <Field label="Document ID" value={ti.di || p.di || "—"} />
                  <Field label="PAN Number" value={ti.pan || p.pan || "—"} />
                </div>
              </div>
            );
          })}
        </div>

        {/* fare summary */}
        <div className="bd-fare">
          <div className="bd-fare-title">Fare Summary</div>
          <div className="bd-grid">
            <Field label="Base Fare" value={fmtMoney(fc.BF)} />
            <Field label="Taxes" value={fmtMoney(fc.TAF)} />
            <Field label="Net Fare" value={fmtMoney(fc.NF)} />
            <Field label="Gross Fare" value={fmtMoney(fc.TF)} />
            <Field label="Commission" value={fmtMoney(fc.NCM ?? 0)} />
            <Field label="TJ Flex Fee" value={fmtMoney(flexFee)} />
          </div>
        </div>
      </Section>

      {/* ── Payment Process (our Razorpay) ── */}
      <Section title="Payment Process">
        {pay ? (
          <div className="bd-table-scroll">
            <table className="bd-table">
              <thead>
                <tr>
                  <th>Created On</th><th>Medium</th><th>Booking Id</th><th>Amount Paid</th>
                  <th>Status</th><th>Payment Id</th><th>Razorpay Order</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>{fmtDateTime(pay.created_at)}</td>
                  <td>Razorpay</td>
                  <td>{orderId}</td>
                  <td>{fmtMoney(pay.amount)}</td>
                  <td><span className={`bd-status sm ${statusClass(pay.payment_status === "paid" ? "SUCCESS" : pay.payment_status)}`}>{pay.payment_status || "—"}</span></td>
                  <td>{pay.razorpay_payment_id || "—"}</td>
                  <td>{pay.razorpay_order_id || "—"}</td>
                </tr>
              </tbody>
            </table>
          </div>
        ) : (
          <div className="bd-muted">No payment record found.</div>
        )}
      </Section>

      {/* ── User Information ── */}
      <Section title="User Information">
        <div className="bd-grid">
          <Field label="Contact's Email" value={emails.join(", ") || "—"} />
          <Field label="Pax Contact" value={contacts.join(", ") || "—"} />
        </div>
      </Section>

      {/* ── Fare Rules (lazy) ── */}
      <Section title="Fare Rules" defaultOpen={false} onFirstOpen={loadFareRule}>
        {fareRuleLoading && <div className="bd-muted">Loading fare rules…</div>}
        {fareRule && !fareRule.error && <FareRulesView data={fareRule} />}
        {fareRule?.error && <div className="bd-muted">Could not load fare rules.</div>}
        {!fareRule && !fareRuleLoading && (
          <button className="bd-btn-link" onClick={loadFareRule}>Load fare rules</button>
        )}
      </Section>

      {/* ── Cancellation (only API-supported amendment) ── */}
      <Section title="Cart Amendments">
        <div className="bd-amend-grid">
          {/* Cancellation — the only API-supported amendment */}
          <div className="bd-amend-card">
            <div className="bd-amend-title">📅 Cancellation</div>
            <div className="bd-amend-desc">Check cancellation charges and refund eligibility before proceeding.</div>
            <div className="bd-amend-actions">
              <button className="bd-amend-btn" onClick={() => setCancelOpen(true)}>Raise Request</button>
              <button className="bd-amend-link" onClick={getQuote} disabled={quote.loading}>
                {quote.loading ? "Loading…" : "Get Cancel Quotation"}
              </button>
            </div>
          </div>

          {[
            { title: "📅 Reissue", desc: "Modify your booking details or change flight dates easily." },
            { title: "📅 Ancillary Services", desc: "Add extra baggage, meals, seat selection, and more to enhance your journey." },
            { title: "📅 Miscellaneous", desc: "Manage additional services related to your booking effortlessly." },
            { title: "📅 Fare Change", desc: "Handle services regarding change of fare details while booking tickets." },
          ].map((c) => (
            <div key={c.title} className="bd-amend-card disabled">
              <div className="bd-amend-title">{c.title}</div>
              <div className="bd-amend-desc">{c.desc}</div>
              <div className="bd-amend-actions">
                <button
                  className="bd-amend-btn"
                  onClick={() => setAmendInfo(`${c.title.replace(/^📅 /, "")} is not available online via the API — please contact support to raise this request.`)}
                >
                  Raise Request
                </button>
              </div>
            </div>
          ))}
        </div>

        {quote.data && (
          <div className="bd-quote-box">
            <div className="bd-fare-title">Cancellation Quotation</div>
            {quote.data.available === false ? (
              <div className="bd-muted">{quote.data.message || "Charges not available — please contact support."}</div>
            ) : (
              <div className="bd-grid">
                <Field label="Cancellation Charges" value={fmtMoney(quote.data.amendment_charges)} />
                <Field label="Refund Amount" value={fmtMoney(quote.data.refund_amount)} />
                <Field label="Total Fare" value={fmtMoney(quote.data.total_fare)} />
              </div>
            )}
          </div>
        )}
        {quote.error && <div className="bd-err-box">{quote.error}</div>}
        {amendInfo && <div className="bd-err-box" style={{ background: "#fff4e0", color: "#b9750a" }}>{amendInfo}</div>}

        {/* ── Amendment Information — inside Cart Amendments, shown when a cancellation exists ── */}
        {(amendment.cancelResult || amendment.loading) && (
          <div className="bd-amend-info-section">
            <div className="bd-amend-info-title">Amendment Information</div>
            {amendment.loading ? (
              <div className="bd-muted">Loading amendment details…</div>
            ) : (
              <div className="bd-amend-info">
                <div className="bd-amend-info-bar" />
                <div className="bd-amend-info-body">
                  <div className="bd-grid">
                    <Field label="Amendment Type" value={amendment.cancelResult?.amendment_id ? "CANCELLATION" : "—"} />
                    <Field label="Amendment Id" value={amendment.data?.amendmentId || amendment.cancelResult?.amendment_id || "—"} />
                    <Field label="Remarks" value={amendment.data?.remarks || amendment.cancelResult?.remarks || "—"} />
                  </div>
                  <div className="bd-amend-status-row">
                    {(() => {
                      const st = amendment.data?.amendmentStatus || amendment.cancelResult?.amendment_status;
                      return (
                        <div>
                          <div className="bd-field-label">Status</div>
                          {st ? (
                            <span className={`bd-status ${statusClass(st)}`}>{st}</span>
                          ) : (
                            <span className="bd-muted">—</span>
                          )}
                        </div>
                      );
                    })()}
                    {amendment.data?.amendmentCharges != null && (
                      <Field label="Amendment Charges" value={fmtMoney(amendment.data.amendmentCharges)} />
                    )}
                    {amendment.data?.refundableAmount != null && (
                      <Field label="Refundable Amount" value={fmtMoney(amendment.data.refundableAmount)} />
                    )}
                    {amendment.data?.totalFare != null && (
                      <Field label="Total Fare" value={fmtMoney(amendment.data.totalFare)} />
                    )}
                  </div>
                </div>
              </div>
            )}
          </div>
        )}
      </Section>

      {cancelOpen && (
        <CancellationModal
          orderId={orderId}
          details={{ ...details, _fallbackName: passengers[0] ? `${passengers[0].fN || ""} ${passengers[0].lN || ""}`.trim() : (bk.airline ? "" : "") }}
          onClose={() => setCancelOpen(false)}
          onDone={handleCancelDone}
        />
      )}
    </div>
  );
}
