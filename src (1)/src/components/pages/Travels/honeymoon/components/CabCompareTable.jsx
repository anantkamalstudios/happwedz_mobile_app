import { Users, Briefcase, Car, CalendarCheck, Clock, Tag, Check, Info } from 'lucide-react';

/**
 * The portal's inline Compare panel: the quotes that share a vehicle class,
 * side by side over a fixed set of rows.
 *
 * The quotes API returns these grouped (`quotesInfo[].quotes[]`), but our
 * flattener spreads them into one card each — so a class with two vendors
 * showed up as two near-identical cards instead of one card with a comparison.
 */

/** "Upto 4 hours before departure" from the first free-cancellation rule. */
const freeCancellation = (quote) => {
  const rules = quote?.policies?.cancellationPolicy || [];
  const free = rules.find((r) => Number(r?.refundPercentage) === 100);
  if (!free) return 'As per policy';
  if (free.description) return free.description;
  const h = Number(free.minHours);
  return Number.isFinite(h) ? `Upto ${h} hours before departure` : 'As per policy';
};

/** Meet and greet is listed among the inclusions rather than as its own flag. */
const meetAndGreet = (quote) =>
  (quote?.policies?.inclusions || []).some((i) => /meet\s*(and|&)\s*greet/i.test(i));

const ROWS = [
  { key: 'pax', Icon: Users, label: 'Passenger capacity',
    value: (q) => `${q.paxCapacity ?? q.paxCount ?? '-'} pax` },
  { key: 'bags', Icon: Briefcase, label: 'Luggage capacity',
    value: (q) => `${q.luggageCapacity ?? q.luggageCount ?? '-'} bags` },
  { key: 'type', Icon: Car, label: 'Vehicle type',
    value: (q) => q.model || q.similarType || '-' },
  { key: 'cancel', Icon: CalendarCheck, label: 'Free cancellation', value: freeCancellation },
  { key: 'wait', Icon: Clock, label: 'Waiting time',
    value: (q) => q.policies?.waitingTime || '-' },
  { key: 'meet', Icon: Tag, label: 'Meet and greet', value: null },
];

const inr = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { maximumFractionDigits: 0 })}`;

export default function CabCompareTable({ quotes, markupFor, onPolicies, onSelect }) {
  if (!quotes?.length) return null;

  return (
    <div className="cmp">
      <div className="cmp-labels">
        {ROWS.map((row) => (
          <div className="cmp-label" key={row.key}>
            <row.Icon size={15} /> {row.label}
          </div>
        ))}
        <div className="cmp-label is-spacer" />
      </div>

      <div className="cmp-cols">
        {quotes.map((quote) => (
          <div className="cmp-col" key={`${quote.quotationId}-${quote.quoteChildId}`}>
            <div className="cmp-head">
              <strong>{inr(quote.grossFare + (markupFor?.(quote) || 0))}</strong>
              <button type="button" onClick={() => onPolicies(quote)}>View policies</button>
            </div>

            {ROWS.map(({ key, value }) => (
              <div className="cmp-cell" key={key}>
                {key === 'meet' ? (
                  meetAndGreet(quote) ? (
                    <span className="cmp-yes">
                      <Check size={14} /> Included <Info size={12} />
                    </span>
                  ) : (
                    <span className="cmp-no">Not included</span>
                  )
                ) : (
                  <span title={value(quote)}>{value(quote)}</span>
                )}
              </div>
            ))}

            <div className="cmp-cell is-action">
              <button type="button" className="cmp-book" onClick={() => onSelect(quote)}>
                Book cab
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
