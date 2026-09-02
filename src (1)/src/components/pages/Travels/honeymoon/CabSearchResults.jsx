import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import {
  Briefcase,
  Crosshair,
  Loader2,
  MapPin,
  Users,
  Pencil,
  Zap,
  CreditCard,
  Headphones,
  ShieldCheck,
  ChevronDown,
  ChevronUp,
} from "lucide-react";
import { fetchCabQuotes, flattenCabQuotes } from "../../../../services/api/cabApi";
import {
  saveBookingDraft,
  readBookingDraft,
  clearBookingDraft,
  loginRedirect,
} from "../../../../utils/bookingDraft";
import CabPolicyModal from "./components/CabPolicyModal";
import CabLocationField from "./components/CabLocationField";
import CabDateTimeField from "./components/CabDateTimeField";
import CabPaxField from "./components/CabPaxField";
import CabMarkupPopover from "./components/CabMarkupPopover";
import CabCompareTable from "./components/CabCompareTable";
import "./index.css";
import "./components/CabResults.css";

/** Standing reassurance panel beside the results, as the portal shows it. */
const WHY_BOOK = [
  { Icon: Zap, title: "Instant confirmation", sub: "Get booking confirmed instantly" },
  { Icon: CreditCard, title: "All-Inclusive Pricing", sub: "No hidden charges or surprises" },
  { Icon: Headphones, title: "24/7 Customer Support", sub: "Round the clock assistance" },
  { Icon: ShieldCheck, title: "Reliable Rides", sub: "Verified Drivers and Clean Vehicles" },
];

const formatFare = (value) =>
  `₹${Number(value || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;

/** Mirrors the QuoteCard grid so the layout doesn't shift when results land. */
function QuoteCardSkeleton() {
  return (
    <div className="cab-quote-card cab-skeleton-card" aria-hidden="true">
      <div className="cab-quote-media">
        <div className="cab-skeleton cab-skeleton-image" />
      </div>

      <div className="cab-quote-body">
        <div className="cab-skeleton cab-skeleton-line cab-skeleton-line--title" />
        <div className="cab-skeleton cab-skeleton-line cab-skeleton-line--sub" />
        <div className="cab-skeleton-meta-row">
          <div className="cab-skeleton cab-skeleton-pill" />
          <div className="cab-skeleton cab-skeleton-pill" />
          <div className="cab-skeleton cab-skeleton-pill" />
        </div>
        <div className="cab-skeleton cab-skeleton-line cab-skeleton-line--short" />
      </div>

      <div className="cab-quote-fare">
        <div className="cab-skeleton cab-skeleton-line cab-skeleton-line--price" />
        <div className="cab-skeleton cab-skeleton-line cab-skeleton-line--tax" />
        <div className="cab-skeleton cab-skeleton-button" />
      </div>
    </div>
  );
}

function QuoteCard({
  quote, siblings = [], onSelect, onPolicies, markup, onMarkup, onMarkupAll,
  isRoundTrip, markupFor,
}) {
  const [fareOpen, setFareOpen] = useState(false);
  const [editing, setEditing] = useState(false);
  const [compareOpen, setCompareOpen] = useState(false);

  const fwdMarkup = Number(markup?.forward || 0);
  const retMarkup = Number(markup?.back || 0);

  // A roundtrip quote covers both legs and the portal splits it evenly on
  // hover; the booking response echoes only the onward leg at exactly half,
  // which is the same split.
  const legFare = isRoundTrip ? quote.grossFare / 2 : quote.grossFare;
  const total = quote.grossFare + fwdMarkup + retMarkup;

  return (
    <div className="cabx-card">
      <div className="cabx-media">
        {quote.image ? (
          <img src={quote.image} alt={quote.label || quote.vehicleType} />
        ) : (
          <span className="cabx-media-fallback">{quote.vehicleType}</span>
        )}
      </div>

      <div className="cabx-main">
        <h3 className="cabx-name">{quote.label || quote.vehicleType}</h3>
        <p className="cabx-model">{quote.model || quote.similarType || ""}</p>

        <div className="cabx-chips">
          <span className="cabx-chip">
            <Users size={12} /> {quote.paxCapacity ?? quote.paxCount ?? "-"} seats
          </span>
          <span className="cabx-chip">
            <Briefcase size={12} /> {quote.luggageCapacity ?? quote.luggageCount ?? "-"} bags
          </span>
        </div>

        <button type="button" className="cabx-policies" onClick={() => onPolicies(quote)}>
          View policies
        </button>
      </div>

      <div className="cabx-fare">
        <div className="cabx-price-row">
          <span
            className="cabx-price"
            onMouseEnter={() => setFareOpen(true)}
            onMouseLeave={() => setFareOpen(false)}
          >
            {formatFare(total)}
          </span>
          <button
            type="button"
            className="cabx-edit"
            onClick={() => setEditing((v) => !v)}
            aria-label="Edit markup"
            title="Edit markup"
          >
            <Pencil size={15} />
          </button>

          {fareOpen && (
            <div className="cabx-fare-pop">
              {isRoundTrip ? (
                <>
                  <div><span>Forward Trip</span><span>{formatFare(legFare + fwdMarkup)}</span></div>
                  <div><span>Return Trip</span><span>{formatFare(legFare + retMarkup)}</span></div>
                </>
              ) : (
                <>
                  <div><span>Base Fare</span><span>{formatFare(quote.netFare)}</span></div>
                  <div><span>Taxes</span><span>{formatFare(quote.totalTax)}</span></div>
                  {fwdMarkup > 0 && (
                    <div><span>Markup</span><span>{formatFare(fwdMarkup)}</span></div>
                  )}
                </>
              )}
              <div className="is-total"><span>Total Fare</span><span>{formatFare(total)}</span></div>
            </div>
          )}

          {editing && (
            <CabMarkupPopover
              value={markup}
              isRoundTrip={isRoundTrip}
              onApply={(next) => { onMarkup(next); setEditing(false); }}
              onApplyAll={(next) => { onMarkupAll(next); setEditing(false); }}
              onClose={() => setEditing(false)}
            />
          )}
        </div>

        <div className="cabx-tax">Inc. GST</div>

        <button type="button" className="cabx-book" onClick={() => onSelect(quote)}>
          Book Cab
        </button>

        {/* Only offered when this class actually has another quote to compare. */}
        {siblings.length > 1 && (
          <button
            type="button"
            className="cabx-compare"
            onClick={() => setCompareOpen((v) => !v)}
            aria-expanded={compareOpen}
          >
            Compare {compareOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
          </button>
        )}
      </div>

      {compareOpen && siblings.length > 1 && (
        <div className="cabx-compare-panel">
          <CabCompareTable
            quotes={siblings}
            markupFor={markupFor}
            onPolicies={onPolicies}
            onSelect={onSelect}
          />
        </div>
      )}
    </div>
  );
}

export default function CabSearchResults() {
  const navigate = useNavigate();
  const location = useLocation();
  const payload = location.state?.payload || null;
  const { user, isAuthenticated } = useSelector((state) => state.auth);

  // Identity of the current search — changes whenever any field that affects
  // the quotes does.
  const searchKey = JSON.stringify({
    o: payload?.origin?.lat,
    d: payload?.destination?.lat,
    p: payload?.pickupDate,
    r: payload?.returnDate,
    j: payload?.journeyType,
    t: payload?.tripType,
    x: payload?.passengers,
    b: payload?.quoteFilter?.luggageCount,
  });

  const [loading, setLoading] = useState(Boolean(payload));
  const [data, setData] = useState(null);
  const [error, setError] = useState("");
  const [policyQuote, setPolicyQuote] = useState(null);
  // Agent markup per quote, keyed by the quotation ids the card is drawn from.
  // { [quoteKey]: { forward, back } } — Update All writes the same pair to every row.
  const [markups, setMarkups] = useState({});
  const keyOf = (q) => `${q.quotationId}-${q.quoteChildId}`;

  // The bar edits a copy of the search; nothing re-runs until Update Search.
  // `pickupDate` arrives as "YYYY-MM-DD HH:mm", so it splits on the space.
  const splitStamp = (value, fallbackTime) => {
    const [date = "", time = fallbackTime] = String(value || "").split(" ");
    return { date, time: time || fallbackTime };
  };
  const [fromText, setFromText] = useState(payload?.origin?.displayAddress || "");
  const [fromPlace, setFromPlace] = useState(payload?.origin || null);
  const [toText, setToText] = useState(payload?.destination?.displayAddress || "");
  const [toPlace, setToPlace] = useState(payload?.destination || null);
  const [editPickup, setEditPickup] = useState(() => splitStamp(payload?.pickupDate, "09:00"));
  const [editReturn, setEditReturn] = useState(() =>
    payload?.returnDate ? splitStamp(payload.returnDate, "18:00") : { date: "", time: "18:00" },
  );
  const [editPax, setEditPax] = useState(payload?.passengers || 1);
  const isRoundTrip = String(payload?.tripType || "") === "roundtrip";
  const [editBags, setEditBags] = useState(payload?.quoteFilter?.luggageCount || 1);

  /**
   * Re-run the search in place. Origin and destination are only replaced when a
   * suggestion was actually picked — typing over the field without choosing one
   * would otherwise send a location with no coordinates.
   */
  const applySearch = () => {
    const isRound = Boolean(editReturn.date);
    navigate("/honeymoon/cabs", {
      replace: true,
      state: {
        payload: {
          ...payload,
          ...(fromPlace?.lat ? { origin: fromPlace } : {}),
          ...(toPlace?.lat ? { destination: toPlace } : {}),
          pickupDate: `${editPickup.date} ${editPickup.time}`,
          ...(isRound
            ? { returnDate: `${editReturn.date} ${editReturn.time}` }
            : { returnDate: undefined }),
          tripType: isRound ? "roundtrip" : "oneway",
          passengers: editPax,
          quoteFilter: { ...payload.quoteFilter, paxCount: editPax, luggageCount: editBags },
        },
      },
    });
  };

  useEffect(() => {
    if (!payload) return undefined;

    const controller = new AbortController();
    setLoading(true);
    setError("");

    fetchCabQuotes(payload, { signal: controller.signal })
      .then((result) => setData(result))
      .catch((err) => {
        if (err?.code === "ERR_CANCELED" || err?.name === "CanceledError") return;
        // Upstream failures arrive as HTTP 200 with status:false, so prefer the
        // supplier's own message over a generic one.
        setError(
          err?.isApiFailure && err.message
            ? err.message
            : "We couldn't load cab options for this route. Please try again.",
        );
      })
      .finally(() => setLoading(false));

    return () => controller.abort();
    // Keyed on the search itself, not on mount: Update Search navigates with
    // fresh state but does not remount this screen, so an empty dependency list
    // left the results frozen on the original query.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchKey]);

  const quotes = useMemo(() => flattenCabQuotes(data?.quotesInfo), [data]);

  /**
   * The API groups quotes by vehicle class and our flattener spreads them out,
   * which turned one class offered by two vendors into two near-identical
   * cards. Regrouped here so each class gets a single card with the cheaper
   * quote on it and the rest behind Compare, as the portal does.
   */
  const groups = useMemo(() => {
    const byClass = new Map();
    for (const q of quotes) {
      const key = `${q.vehicleType || ""}|${q.vehicleCategory || ""}|${q.label || ""}`;
      if (!byClass.has(key)) byClass.set(key, []);
      byClass.get(key).push(q);
    }
    return Array.from(byClass.values())
      .map((list) => list.slice().sort((a, b) => a.grossFare - b.grossFare))
      .sort((a, b) => a[0].grossFare - b[0].grossFare);
  }, [quotes]);
  const journeyInfo = data?.journeyInfo;
  const route = data?.routeDetails;

  const goToBooking = (quote) => {
    // The markup set on the card has to travel with the quote — the review page
    // starts at zero otherwise and the traveller sees a different total there.
    const m = markups[keyOf(quote)];
    navigate("/honeymoon/cabs/book", {
      state: {
        quote,
        journeyInfo,
        routeDetails: route,
        searchPayload: payload,
        markup: Number(m?.forward || 0) + Number(m?.back || 0),
      },
    });
  };

  const handleSelectQuote = (quote) => {
    if (!isAuthenticated || !user?.id) {
      // Park the chosen quote so signing in resumes the booking instead of
      // dropping the user back on an undifferentiated list of quotes.
      saveBookingDraft({
        kind: "cab",
        meta: { quote, journeyInfo, routeDetails: route, searchPayload: payload },
      });
      navigate(...loginRedirect(location, "cab"));
      return;
    }

    goToBooking(quote);
  };

  // Returning from login with a parked quote: pick the booking back up.
  useEffect(() => {
    if (!isAuthenticated || !user?.id) return;
    const draft = readBookingDraft({ kind: "cab" });
    if (!draft?.meta?.quote) return;
    clearBookingDraft();
    navigate("/honeymoon/cabs/book", { state: draft.meta });
  }, [isAuthenticated, user?.id, navigate]);

  if (!payload) {
    return (
      <div className="cab-results-page">
        <div className="container cab-results-empty">
          <h2>No search found</h2>
          <p>Start a new cab search to see available options.</p>
          <button type="button" onClick={() => navigate("/honeymoon?tab=car-rental")}>
            Search cabs
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="cab-results-page">
      {/* Editable search bar, as the portal keeps one above the results — the
          same controls as the home form so a change can be applied in place
          instead of sending the traveller back a page. */}
      <div className="cabx-bar">
        <div className="container cabx-bar-inner">
          {/* From and To share one bordered box, split by a divider, as the
              portal groups them. */}
          <div className="cabx-bar-pair">
            <CabLocationField
              variant="bar"
              label="From"
              icon={<Crosshair size={12} />}
              placeholder="Where from?"
              value={fromText}
              selected={fromPlace}
              onChange={setFromText}
              onSelect={setFromPlace}
            />
            <CabLocationField
              variant="bar"
              label="To"
              icon={<MapPin size={12} />}
              placeholder="Where to?"
              value={toText}
              selected={toPlace}
              onChange={setToText}
              onSelect={setToPlace}
            />
          </div>

          <div className="cabx-bar-box">
            <CabDateTimeField
              variant="bar"
              label="Pickup date &amp; time"
              date={editPickup.date}
              time={editPickup.time}
              onApply={(d, t) => setEditPickup({ date: d, time: t })}
              onClear={() => setEditPickup({ date: "", time: "09:00" })}
            />
          </div>

          <div className="cabx-bar-box">
            <CabDateTimeField
              variant="bar"
              label="Return date &amp; time"
              date={editReturn.date}
              time={editReturn.time}
              minDate={editPickup.date || undefined}
              onApply={(d, t) => setEditReturn({ date: d, time: t })}
              onClear={() => setEditReturn({ date: "", time: "18:00" })}
            />
          </div>

          <div className="cabx-bar-box">
            <span className="cabx-bar-label"><Users size={12} /> Pax &amp; Bags</span>
            <CabPaxField
              variant="bar"
              passengers={editPax}
              bags={editBags}
              onPassengersChange={setEditPax}
              onBagsChange={setEditBags}
            />
          </div>


          <button type="button" className="cabx-update" onClick={applySearch}>
            Update Search
          </button>
        </div>
      </div>

      <div className="container cabx-crumbs">
        <button type="button" onClick={() => navigate("/honeymoon?tab=car-rental")}>Home</button>
        <span>/</span>
        <span>Cabs</span>
      </div>


      <div className="container cabx-body">
        {/* The portal keeps a standing reassurance panel beside the results. */}
        <aside className="cabx-aside">
          <h4>Why book with us?</h4>
          <ul>
            {WHY_BOOK.map((item) => (
              <li key={item.title}>
                <span className="cabx-aside-icon"><item.Icon size={16} /></span>
                <span className="cabx-aside-text">
                  <strong>{item.title}</strong>
                  <small>{item.sub}</small>
                </span>
              </li>
            ))}
          </ul>
        </aside>

        <div className="cabx-list-col">
          {loading ? (
            <>
              <div className="cabx-count">
                <Loader2 size={15} className="spin" /> Finding the best cabs for your route...
              </div>
              <div className="cabx-list">
                {Array.from({ length: 4 }).map((_, index) => (
                  <QuoteCardSkeleton key={index} />
                ))}
              </div>
            </>
          ) : error ? (
            <div className="cabx-state cabx-state--error">{error}</div>
          ) : quotes.length === 0 ? (
            <div className="cabx-state">No cabs available for this route.</div>
          ) : (
            <>
              <div className="cabx-count">
                Showing {groups.length} cab{groups.length > 1 ? "s" : ""} from{" "}
                <strong>{route?.origin?.city || payload.origin.displayAddress}</strong> to{" "}
                <strong>{route?.destination?.city || payload.destination.displayAddress}</strong>
              </div>
              <div className="cabx-list">
                {groups.map((group) => {
                  const quote = group[0];
                  return (
                  <QuoteCard
                    key={keyOf(quote)}
                    quote={quote}
                    siblings={group}
                    markupFor={(q) => markups[keyOf(q)]?.forward || 0}
                    isRoundTrip={isRoundTrip}
                    markup={markups[keyOf(quote)]}
                    onMarkup={(value) =>
                      setMarkups((prev) => ({ ...prev, [keyOf(quote)]: value }))
                    }
                    onMarkupAll={(value) =>
                      setMarkups(Object.fromEntries(quotes.map((q) => [keyOf(q), value])))
                    }
                    onPolicies={setPolicyQuote}
                    onSelect={handleSelectQuote}
                  />
                  );
                })}
              </div>
            </>
          )}
        </div>
      </div>

      {policyQuote && (
        <CabPolicyModal quote={policyQuote} onClose={() => setPolicyQuote(null)} />
      )}

    </div>
  );
}
