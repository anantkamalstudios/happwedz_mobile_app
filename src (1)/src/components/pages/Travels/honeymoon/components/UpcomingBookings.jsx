import { useState, useEffect, useMemo } from "react";
import { useNavigate } from "react-router-dom";
import { FaWhatsapp, FaPlane, FaChevronUp, FaChevronDown } from "react-icons/fa";
import { getMyFlightBookings, getBookingDetails, createFlightPaymentOrder, verifyAndBookFlight, releaseHeldBooking } from "../../../../../services/api/flightApi";
import PassengerSummaryModal from "./PassengerSummaryModal";
import { formatDate } from "../../../../../utils/dateFormat";
import "./UpcomingBookings.css";

const PAGE_SIZE = 5;

const loadRazorpay = () =>
  new Promise((resolve) => {
    if (window.Razorpay) return resolve(true);
    const s = document.createElement("script");
    s.src = "https://checkout.razorpay.com/v1/checkout.js";
    s.onload = () => resolve(true);
    s.onerror = () => resolve(false);
    document.body.appendChild(s);
  });

const parseDate = (val) => {
  if (!val) return null;
  const d = new Date(val);
  return Number.isNaN(d.getTime()) ? null : d;
};

const formatTravelDate = (val) => formatDate(val, "—");

export default function UpcomingBookings() {
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState("upcoming");
  const [collapsed, setCollapsed] = useState(false);
  const [bookings, setBookings] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [recent, setRecent] = useState([]);
  const [summary, setSummary] = useState({ open: false, loading: false, booking: null, details: null, error: null });
  const [paying, setPaying] = useState(null); // order_id currently being paid/confirmed

  useEffect(() => {
    let active = true;
    (async () => {
      try {
        const res = await getMyFlightBookings();
        if (!active) return;
        setBookings(Array.isArray(res?.data) ? res.data : []);
      } catch (err) {
        if (!active) return;
        // 401 → not logged in; just show nothing rather than an error wall
        if (err?.response?.status === 401) setBookings([]);
        else setError("Could not load your bookings.");
      } finally {
        if (active) setLoading(false);
      }
    })();
    return () => {
      active = false;
    };
  }, []);

  useEffect(() => {
    try {
      setRecent(JSON.parse(localStorage.getItem("hw_flightRecentSearches") || "[]"));
    } catch {
      setRecent([]);
    }
  }, [activeTab]);

  // Upcoming = travel date today-or-later, OR no parseable date yet (don't hide).
  const upcoming = useMemo(() => {
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    return bookings
      .filter((b) => {
        const d = parseDate(b.departure);
        return !d || d.getTime() >= startOfToday.getTime();
      })
      .sort((a, b) => {
        const da = parseDate(a.departure);
        const db = parseDate(b.departure);
        if (!da && !db) return 0;
        if (!da) return 1;
        if (!db) return -1;
        return da.getTime() - db.getTime();
      });
  }, [bookings]);

  const totalPages = Math.max(1, Math.ceil(upcoming.length / PAGE_SIZE));
  const pageRows = upcoming.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE);

  const openDetail = (orderId) => {
    if (!orderId) return;
    navigate(`/honeymoon/flights/my-booking/${encodeURIComponent(orderId)}`);
  };

  const openSummary = async (b) => {
    setSummary({ open: true, loading: true, booking: b, details: null, error: null });
    try {
      const details = await getBookingDetails(b.order_id, true);
      setSummary((s) => ({ ...s, loading: false, details }));
    } catch {
      setSummary((s) => ({ ...s, loading: false, error: "Could not load passenger details." }));
    }
  };

  // Pay & confirm a HELD booking → Razorpay → confirm-book (tickets the held PNR).
  const payConfirm = async (b) => {
    setPaying(b.order_id);
    try {
      const ready = await loadRazorpay();
      if (!ready) throw new Error("Razorpay failed to load");

      const order = await createFlightPaymentOrder({
        provider: "tripjack",
        offer_id: b.order_id,
        price: b.amount_paid || b.price,
        trip_type: b.trip_type,
        from: b.from_iata,
        to: b.to_iata,
        departure: b.departure,
        arrival: b.arrival,
        flight_no: b.flight_no,
        airline: b.airline,
        cabin_class: b.cabin_class,
        passengers: [],
        contact: { email: b.contact_email, phone: b.contact_phone },
        is_hold_confirm: true,
        booking_payload: { bookingId: b.order_id },
      });

      const orderId = order?.razorpay_order_id;
      const key = order?.key_id || import.meta.env.VITE_RAZORPAY_KEY_ID || "";
      if (!orderId || !key) throw new Error("Could not start payment");

      const rzp = new window.Razorpay({
        key,
        amount: order.amount,
        currency: order.currency || "INR",
        name: "HappyWedz",
        description: "Confirm held flight booking",
        order_id: orderId,
        prefill: { name: b.passenger_name || "", email: b.contact_email || "", contact: b.contact_phone || "" },
        theme: { color: "#ed1173" },
        handler: async (rzpRes) => {
          try {
            await verifyAndBookFlight({
              razorpay_order_id: rzpRes.razorpay_order_id,
              razorpay_payment_id: rzpRes.razorpay_payment_id,
              razorpay_signature: rzpRes.razorpay_signature,
            });
            // refresh the list so the booking flips to confirmed
            const res = await getMyFlightBookings();
            setBookings(Array.isArray(res?.data) ? res.data : []);
          } catch (err) {
            alert(err.response?.data?.message || "Could not confirm the booking.");
          } finally {
            setPaying(null);
          }
        },
        modal: { ondismiss: () => setPaying(null) },
      });
      rzp.open();
    } catch (err) {
      alert(err.message || "Could not start payment.");
      setPaying(null);
    }
  };

  // Release a HELD booking (unhold) — frees the blocked seat.
  const releaseHold = async (b) => {
    if (!window.confirm("Release this held seat? This cannot be undone.")) return;
    setPaying(b.order_id);
    try {
      const res = await releaseHeldBooking(b.order_id);
      if (res?.status) {
        const list = await getMyFlightBookings();
        setBookings(Array.isArray(list?.data) ? list.data : []);
      } else {
        alert(res?.message || "Could not release the hold.");
      }
    } catch (err) {
      alert(err.response?.data?.message || "Could not release the hold.");
    } finally {
      setPaying(null);
    }
  };

  const bookReturn = (b) => {
    if (!b.from_iata || !b.to_iata) return;
    window.dispatchEvent(
      new CustomEvent("hw:prefillSearch", {
        detail: {
          tripType: "oneway",
          from: b.to_iata,
          to: b.from_iata,
          fromText: b.to_iata,
          toText: b.from_iata,
        },
      })
    );
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const shareWithCustomer = () => {
    const lines = upcoming
      .slice(0, 10)
      .map(
        (b) =>
          `• ${b.passenger_name || "Guest"} — ${b.order_id || ""} (${formatTravelDate(b.departure)})`
      )
      .join("\n");
    const text = encodeURIComponent(`Your upcoming flight bookings:\n${lines}`);
    window.open(`https://wa.me/?text=${text}`, "_blank", "noopener");
  };

  return (
    <div className="ub-wrapper">
      <div className="ub-tabs-row">
        <div className="ub-tabs">
          <button
            className={`ub-tab ${activeTab === "upcoming" ? "active" : ""}`}
            onClick={() => {
              setActiveTab("upcoming");
              setCollapsed(false);
            }}
          >
            Upcoming Bookings {collapsed ? <FaChevronDown size={11} /> : <FaChevronUp size={11} />}
          </button>
          <span className="ub-tab-divider" />
          <button
            className={`ub-tab ${activeTab === "recent" ? "active" : ""}`}
            onClick={() => setActiveTab("recent")}
          >
            Recent Searches <FaChevronDown size={11} />
          </button>
        </div>

        {activeTab === "upcoming" && upcoming.length > 0 && (
          <button className="ub-share-btn" onClick={shareWithCustomer}>
            <FaWhatsapp size={15} /> SHARE WITH CUSTOMER
          </button>
        )}
      </div>

      {activeTab === "upcoming" && !collapsed && (
        <div className="ub-card">
          {loading ? (
            <div className="ub-empty">Loading your bookings…</div>
          ) : error ? (
            <div className="ub-empty">{error}</div>
          ) : upcoming.length === 0 ? (
            <div className="ub-empty">
              <FaPlane className="ub-empty-icon" />
              No upcoming bookings yet. Search and book a flight to see it here.
            </div>
          ) : (
            <>
              <div className="ub-table-scroll">
                <table className="ub-table">
                  <thead>
                    <tr>
                      <th>BOOKING ID</th>
                      <th>PASSENGER NAME</th>
                      <th>TRAVEL DATE</th>
                      <th>BOOKING SUMMARY</th>
                      <th>OTHER TRAVEL OPTIONS</th>
                    </tr>
                  </thead>
                  <tbody>
                    {pageRows.map((b) => (
                      <tr key={b.id || b.order_id}>
                        <td>
                          <button className="ub-link" onClick={() => openDetail(b.order_id)}>
                            {b.order_id || "—"}
                          </button>
                          {b.booking_status === "on_hold" && <span className="ub-hold-badge">ON HOLD</span>}
                        </td>
                        <td>{b.passenger_name || "—"}</td>
                        <td>{formatTravelDate(b.departure)}</td>
                        <td>
                          <button className="ub-link" onClick={() => openSummary(b)}>
                            View Summary
                          </button>
                        </td>
                        <td>
                          {b.booking_status === "on_hold" ? (
                            <div className="d-flex gap-2 align-items-center">
                              <button
                                className="ub-pay-btn"
                                onClick={() => payConfirm(b)}
                                disabled={paying === b.order_id}
                              >
                                {paying === b.order_id ? "Processing…" : "Pay & Confirm"}
                              </button>
                              <button
                                className="ub-link ub-release-btn"
                                onClick={() => releaseHold(b)}
                                disabled={paying === b.order_id}
                              >
                                Release
                              </button>
                            </div>
                          ) : b.from_iata && b.to_iata ? (
                            <button className="ub-return-btn" onClick={() => bookReturn(b)}>
                              ↩ Book Return
                            </button>
                          ) : (
                            <span className="ub-muted">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {totalPages > 1 && (
                <div className="ub-pagination">
                  <button disabled={page <= 1} onClick={() => setPage((p) => p - 1)}>
                    ‹ Prev
                  </button>
                  <span className="ub-page-num">{page}</span>
                  <button disabled={page >= totalPages} onClick={() => setPage((p) => p + 1)}>
                    Next ›
                  </button>
                </div>
              )}
            </>
          )}
        </div>
      )}

      {activeTab === "recent" && (
        <div className="ub-card">
          {recent.length === 0 ? (
            <div className="ub-empty">No recent searches.</div>
          ) : (
            <div className="ub-recent-list">
              {recent.map((r, i) => (
                <div key={i} className="ub-recent-item">
                  <div className="ub-recent-route">
                    <FaPlane size={12} /> {r.fromText || r.from} → {r.toText || r.to}
                  </div>
                  <div className="ub-recent-meta">
                    {formatTravelDate(r.departureDate)}
                    {r.returnDate ? ` – ${formatTravelDate(r.returnDate)}` : ""} ·{" "}
                    {(r.adults || 1) + (r.children || 0) + (r.infants || 0)} pax · {r.cabinClass || "Economy"}
                  </div>
                  <button
                    className="ub-link"
                    onClick={() => {
                      window.dispatchEvent(new CustomEvent("hw:runSearch", { detail: r }));
                    }}
                  >
                    Search again
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {summary.open && (
        <PassengerSummaryModal
          state={summary}
          onClose={() => setSummary({ open: false, loading: false, booking: null, details: null, error: null })}
          onViewFull={(orderId) => {
            setSummary({ open: false, loading: false, booking: null, details: null, error: null });
            openDetail(orderId);
          }}
        />
      )}
    </div>
  );
}
