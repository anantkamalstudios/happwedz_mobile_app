import { useEffect, useMemo, useState } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { useSelector } from "react-redux";
import { toast } from "react-toastify";
import {
  ArrowRight,
  Briefcase,
  Clock,
  Loader2,
  MapPin,
  Route,
  Users,
} from "lucide-react";
import { fetchCabQuotes, flattenCabQuotes } from "../../../../services/api/cabApi";
import "./index.css";

const formatFare = (value) =>
  `₹${Number(value || 0).toLocaleString("en-IN", { maximumFractionDigits: 0 })}`;

const formatPickupDateTime = (value) => {
  if (!value) return "";
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
};

const formatDuration = (minutes) => {
  const total = Number(minutes) || 0;
  if (!total) return "";
  const hours = Math.floor(total / 60);
  const mins = total % 60;
  return hours ? `${hours}h ${mins}m` : `${mins} min`;
};

const titleCase = (value) =>
  String(value || "")
    .replace(/_/g, " ")
    .toLowerCase()
    .replace(/\b\w/g, (char) => char.toUpperCase());

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

function QuoteCard({ quote, onSelect }) {
  const [showPolicies, setShowPolicies] = useState(false);
  const { policies } = quote;

  return (
    <div className="cab-quote-card">
      <div className="cab-quote-media">
        {quote.image ? (
          <img src={quote.image} alt={quote.label} loading="lazy" />
        ) : (
          <div className="cab-quote-media-fallback">{quote.vehicleType}</div>
        )}
      </div>

      <div className="cab-quote-body">
        <div className="cab-quote-title-row">
          <div>
            <div className="cab-quote-title">{quote.label || quote.vehicleType}</div>
            <div className="cab-quote-sub">{quote.model || quote.similarType}</div>
          </div>
          <span className="cab-quote-category">{quote.vehicleCategory}</span>
        </div>

        <div className="cab-quote-meta">
          <span>
            <Users size={14} /> {quote.paxCount || quote.paxCapacity} pax
          </span>
          <span>
            <Briefcase size={14} /> {quote.luggageCount || quote.luggageCapacity} bags
          </span>
          {policies?.waitingTime ? (
            <span>
              <Clock size={14} /> {policies.waitingTime}
            </span>
          ) : null}
        </div>

        {quote.benefits?.length ? (
          <div className="cab-quote-benefits">
            {quote.benefits.map((benefit) => (
              <span key={benefit} className="cab-quote-chip">
                {benefit}
              </span>
            ))}
          </div>
        ) : null}

        <button
          type="button"
          className="cab-quote-policy-toggle"
          onClick={() => setShowPolicies((prev) => !prev)}
        >
          {showPolicies ? "Hide details" : "Inclusions & cancellation"}
        </button>

        {showPolicies ? (
          <div className="cab-quote-policies">
            {policies?.inclusions?.length ? (
              <div>
                <div className="cab-policy-heading">Inclusions</div>
                <ul>
                  {policies.inclusions.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            ) : null}
            {policies?.exclusions?.length ? (
              <div>
                <div className="cab-policy-heading">Exclusions</div>
                <ul>
                  {policies.exclusions.map((item) => (
                    <li key={item}>{item}</li>
                  ))}
                </ul>
              </div>
            ) : null}
            {policies?.cancellationPolicy?.length ? (
              <div>
                <div className="cab-policy-heading">Cancellation</div>
                <ul>
                  {policies.cancellationPolicy.map((rule) => (
                    <li key={`${rule.minHours}-${rule.refundPercentage}`}>
                      {rule.description} — {rule.refundPercentage}% refund
                    </li>
                  ))}
                </ul>
              </div>
            ) : null}
          </div>
        ) : null}
      </div>

      <div className="cab-quote-fare">
        <div className="cab-quote-price">{formatFare(quote.grossFare)}</div>
        <div className="cab-quote-tax">incl. tax {formatFare(quote.totalTax)}</div>
        <button
          type="button"
          className="cab-quote-book"
          onClick={() => onSelect(quote)}
        >
          Select <ArrowRight size={15} />
        </button>
      </div>
    </div>
  );
}

export default function CabSearchResults() {
  const navigate = useNavigate();
  const location = useLocation();
  const payload = location.state?.payload || null;
  const { user, isAuthenticated } = useSelector((state) => state.auth);

  const [loading, setLoading] = useState(Boolean(payload));
  const [data, setData] = useState(null);
  const [error, setError] = useState("");

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
    // payload comes from navigation state and is stable for this screen.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const quotes = useMemo(() => flattenCabQuotes(data?.quotesInfo), [data]);
  const journeyInfo = data?.journeyInfo;
  const route = data?.routeDetails;

  const handleSelectQuote = (quote) => {
    if (!isAuthenticated || !user?.id) {
      toast.error("Please login before booking a cab.");
      navigate("/customer-login");
      return;
    }

    navigate("/honeymoon/cabs/book", {
      state: { quote, journeyInfo, routeDetails: route, searchPayload: payload },
    });
  };

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
      <div className="cab-results-header">
        <div className="container">
          <div className="cab-route-line">
            <span>
              <MapPin size={16} /> {route?.origin?.displayAddress || payload.origin.displayAddress}
            </span>
            <ArrowRight size={16} />
            <span>
              <MapPin size={16} />{" "}
              {route?.destination?.displayAddress || payload.destination.displayAddress}
            </span>
          </div>
          <div className="cab-route-meta">
            <span>{formatPickupDateTime(journeyInfo?.pickupDateTime || payload.pickupDate)}</span>
            {payload.returnDate ? (
              <span>Return {formatPickupDateTime(payload.returnDate)}</span>
            ) : null}
            <span>{titleCase(journeyInfo?.journeyType || payload.journeyType)}</span>
            <span>{titleCase(journeyInfo?.tripType || payload.tripType)}</span>
            {journeyInfo?.distance ? (
              <span>
                <Route size={14} /> {journeyInfo.distance}
              </span>
            ) : null}
            {journeyInfo?.duration ? (
              <span>
                <Clock size={14} /> {formatDuration(journeyInfo.duration)}
              </span>
            ) : null}
          </div>
          <button
            type="button"
            className="cab-modify-search"
            onClick={() => navigate("/honeymoon?tab=car-rental")}
          >
            Modify search
          </button>
        </div>
      </div>

      <div className="container cab-results-body">
        {loading ? (
          <>
            <div className="cab-results-count cab-results-count--loading">
              <Loader2 size={16} className="spin" /> Finding the best cabs for your route...
            </div>
            <div className="cab-quote-list">
              {Array.from({ length: 4 }).map((_, index) => (
                <QuoteCardSkeleton key={index} />
              ))}
            </div>
          </>
        ) : error ? (
          <div className="cab-results-state cab-results-error">{error}</div>
        ) : quotes.length === 0 ? (
          <div className="cab-results-state">No cabs available for this route.</div>
        ) : (
          <>
            <div className="cab-results-count">
              {quotes.length} option{quotes.length > 1 ? "s" : ""} available
            </div>
            <div className="cab-quote-list">
              {quotes.map((quote) => (
                <QuoteCard
                  key={`${quote.quotationId}-${quote.quoteChildId}`}
                  quote={quote}
                  onSelect={handleSelectQuote}
                />
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
