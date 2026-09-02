import { useState } from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import { FiEdit2 } from 'react-icons/fi';


const inr = (n) =>
  `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

/** Tax components TripJack returns under `afC.TAF`, in display order. */
const TAX_LABELS = {
  YQ: 'Fuel surcharge (YQ)',
  YR: 'Carrier charge (YR)',
  OT: 'Other taxes',
  AGST: 'GST',
  MF: 'Management fee',
  MFT: 'Management fee tax',
  OB: 'Payment fee',
};

/**
 * Fare Summary rail, shared by every step of the booking flow so the pricing a
 * traveller agreed to stays on screen from itinerary through to payment.
 *
 * The markup is folded into "Taxes and fees" and shown again as a deduction
 * under "Amount to Pay", which is how the portal keeps
 * `Base + Taxes === Amount to Pay` true while still disclosing the margin.
 *
 * @param {object}   fare          onward totalPriceList entry
 * @param {object}   [returnFare]  return leg, when present
 * @param {object}   searchParams  carries the pax counts
 * @param {number}   [markup]      agent markup, added to the charged amount only
 * @param {Function} [onMarkupChange] omit to render the markup read-only
 * @param {Array}    [extras]      SSR lines, e.g. [{ label:'Seat Fee', amount }]
 */
export default function FareSummary({
  fare,
  returnFare,
  searchParams = {},
  markup = 0,
  onMarkupChange,
  extras = [],
  children,
}) {
  const [taxOpen, setTaxOpen] = useState(false);
  const [totalOpen, setTotalOpen] = useState(true);
  const [markupOpen, setMarkupOpen] = useState(false);
  const [extrasOpen, setExtrasOpen] = useState(false);
  const [markupDraft, setMarkupDraft] = useState(String(markup || 0));

  const pax = {
    ADULT: Number(searchParams.adults || 1),
    CHILD: Number(searchParams.children || 0),
    INFANT: Number(searchParams.infants || 0),
  };
  const paxLabel = Object.entries(pax)
    .filter(([, n]) => n > 0)
    .map(([t, n]) => `${n} ${t.charAt(0) + t.slice(1).toLowerCase()}${n > 1 ? 's' : ''}`)
    .join(', ');

  // `fd` is keyed by pax type and each amount is per passenger, so multiplying
  // the adult fare alone understates any booking carrying a child or infant.
  const sumFare = (tripFare, key) =>
    Object.entries(pax).reduce((total, [type, count]) => {
      const amount = tripFare?.fd?.[type]?.fC?.[key];
      return total + (amount ? amount * count : 0);
    }, 0);

  const legs = [fare, returnFare].filter(Boolean);
  const markupValue = Number(markup || 0);
  const totalBase = legs.reduce((n, f) => n + sumFare(f, 'BF'), 0);
  const totalTaxes = legs.reduce((n, f) => n + sumFare(f, 'TAF'), 0);
  const netPrice = legs.reduce((n, f) => n + sumFare(f, 'TF'), 0);
  const extrasTotal = extras.reduce((n, e) => n + Number(e.amount || 0), 0);
  const amountToPay = netPrice + markupValue + extrasTotal;

  const taxBreakup = (() => {
    const totals = {};
    for (const leg of legs) {
      for (const [type, count] of Object.entries(pax)) {
        if (!count) continue;
        for (const [code, value] of Object.entries(leg?.fd?.[type]?.afC?.TAF || {})) {
          totals[code] = (totals[code] || 0) + Number(value || 0) * count;
        }
      }
    }
    const rows = Object.entries(totals)
      .filter(([, v]) => v > 0)
      .map(([code, value]) => ({ code, label: TAX_LABELS[code] || code, value }));
    if (markupValue > 0) {
      rows.push({ code: 'MARKUP', label: 'Total Airline Tax', value: markupValue });
    }
    return rows;
  })();

  const commitMarkup = () => {
    onMarkupChange?.(Number(markupDraft) || 0);
    setMarkupOpen(false);
  };

  return (
    <div className="booking-card sticky-summary">
      <h5 className="booking-card-title fare-summary-head">FARE SUMMARY</h5>

      <div className="fare-summary-section">
        <div className="fare-row">
          <span>Base fare <small className="text-muted">({paxLabel})</small></span>
          <span>{inr(totalBase)}</span>
        </div>

        <button
          type="button"
          className="fare-row fare-row-toggle"
          onClick={() => setTaxOpen((v) => !v)}
          disabled={!taxBreakup.length}
        >
          <span>
            Taxes and fees{' '}
            {taxBreakup.length ? (taxOpen ? <ChevronUp size={13} /> : <ChevronDown size={13} />) : null}
          </span>
          <span className="fare-tax-amount">
            {inr(totalTaxes + markupValue)}
            {onMarkupChange && (
              <span
                role="button"
                tabIndex={0}
                className="fare-edit-btn"
                title="Edit markup"
                onClick={(e) => {
                  e.stopPropagation();
                  setMarkupDraft(String(markupValue || 0));
                  setMarkupOpen((v) => !v);
                }}
                onKeyDown={(e) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    e.stopPropagation();
                    setMarkupOpen((v) => !v);
                  }
                }}
              >
                <FiEdit2 size={12} />
              </span>
            )}
          </span>
        </button>

        {markupOpen && (
          <div className="markup-box markup-box-summary" onClick={(e) => e.stopPropagation()}>
            <button type="button" className="markup-close" onClick={() => setMarkupOpen(false)}>×</button>
            <label className="markup-field">
              <span>Markup Price</span>
              <input
                type="number"
                autoFocus
                value={markupDraft}
                onChange={(e) => setMarkupDraft(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') commitMarkup();
                  if (e.key === 'Escape') setMarkupOpen(false);
                }}
              />
            </label>
            <div className="markup-actions">
              <button type="button" onClick={commitMarkup}>Update</button>
            </div>
          </div>
        )}

        {taxOpen && (
          <div className="fare-breakdown">
            {taxBreakup.map((t) => (
              <div key={t.code} className="fare-breakdown-row">
                <span>{t.label}</span><span>{inr(t.value)}</span>
              </div>
            ))}
          </div>
        )}

        {extrasTotal > 0 && (
          <>
            <button
              type="button"
              className="fare-row fare-row-toggle"
              onClick={() => setExtrasOpen((v) => !v)}
            >
              <span>
                Meal, Baggage &amp; Seat{' '}
                {extrasOpen ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
              </span>
              <span>{inr(extrasTotal)}</span>
            </button>
            {extrasOpen && (
              <div className="fare-breakdown">
                {extras
                  .filter((e) => Number(e.amount) > 0)
                  .sort((a, b) => a.label.localeCompare(b.label))
                  .map((e) => (
                    <div key={e.label} className="fare-breakdown-row">
                      <span>{e.label}</span><span>{inr(e.amount)}</span>
                    </div>
                  ))}
              </div>
            )}
          </>
        )}
      </div>

      <div className="fare-grand-total mt-3 pt-3">
        <button type="button" className="fare-total-toggle" onClick={() => setTotalOpen((v) => !v)}>
          <span className="grand-total-label">
            Amount to Pay {totalOpen ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
          </span>
          <span className="grand-total-amount">{inr(amountToPay)}</span>
        </button>
        {totalOpen && (
          <div className="fare-breakdown mt-2">
            <div className="fare-breakdown-row"><span>Commission</span><span>-{inr(0)}</span></div>
            {markupValue > 0 && (
              <div className="fare-breakdown-row"><span>Markup</span><span>-{inr(markupValue)}</span></div>
            )}
            <div className="fare-breakdown-row"><span>TDS</span><span>+{inr(0)}</span></div>
            <div className="fare-breakdown-row is-net">
              <span>Net Price</span><span>{inr(netPrice + extrasTotal)}</span>
            </div>
          </div>
        )}
      </div>

      {children}
    </div>
  );
}
