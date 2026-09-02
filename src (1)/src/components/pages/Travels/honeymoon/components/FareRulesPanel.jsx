import { useState } from 'react';

/**
 * Fare-rule panel, laid out like the portal's: a route tab, one tab per fee
 * type, and a Time Frame column against each slab's charge and policy.
 *
 * Shared by the results card's "Fare Rules" tab and the itinerary step.
 */
const RULE_TABS = [
  { key: 'CANCELLATION', label: 'Cancellation Fee' },
  { key: 'DATECHANGE', label: 'Date Change Fee' },
  { key: 'NO_SHOW', label: 'No Show Fee', note: '( Post Departure )' },
  { key: 'SEAT_CHARGEABLE', label: 'Seat Chargeable Fee' },
];

/** `st`/`et` are hours before departure: 4 / 8760 reads "4 hrs to 365 days". */
const timeFrame = (slab) => {
  const unit = (h) => (h >= 24 ? `${Math.round(h / 24)} days` : `${h} hrs`);
  return `${unit(Number(slab?.st ?? 0))} to ${unit(Number(slab?.et ?? 0))}`;
};

/** policyInfo packs its lines with __nls__ separators. */
const policyLines = (text) =>
  String(text || '')
    .split(/__nls__/i)
    .map((line) => line.replace(/__[a-z]+__/gi, ' ').replace(/\s+/g, ' ').trim())
    .filter(Boolean);

const money = (n) => `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2 })}`;

export default function FareRulesPanel({ data }) {
  const routes = data?.fareRule || data?.farerule || {};
  const routeKeys = Object.keys(routes);
  const [route, setRoute] = useState(routeKeys[0] || '');
  const [detailed, setDetailed] = useState(false);

  const tfr = routes[route]?.tfr || {};
  const available = RULE_TABS.filter((t) => (tfr[t.key] || []).length);
  const [type, setType] = useState(available[0]?.key || 'CANCELLATION');

  if (!routeKeys.length) return <p className="text-muted small mb-0">No fare rules available.</p>;

  const activeType = available.some((t) => t.key === type) ? type : available[0]?.key;
  const slabs = tfr[activeType] || [];
  const misc = (routes[route]?.miscInfo || []).flatMap(policyLines);

  return (
    <div className="fr-panel">
      <div className="fr-head">
        <div className="fr-routes">
          {routeKeys.map((key) => (
            <button
              key={key}
              type="button"
              className={`fr-route ${key === route ? 'active' : ''}`}
              onClick={() => setRoute(key)}
            >
              {key}
            </button>
          ))}
        </div>
        {misc.length > 0 && (
          <button type="button" className="fr-detailed" onClick={() => setDetailed((v) => !v)}>
            Detailed Rules
          </button>
        )}
      </div>

      <p className="fr-hint">* To view charges, click on the below fee sections.</p>

      {detailed && misc.length > 0 ? (
        <div className="fr-detailed-body">
          {misc.map((line, i) => <p key={i}>{line}</p>)}
        </div>
      ) : (
        <div className="fr-table">
          <div className="fr-tabs">
            <div className="fr-tab fr-tab-frame">
              Time Frame
              <small>( From First Scheduled Flight Departure )</small>
            </div>
            {available.map((t) => (
              <button
                key={t.key}
                type="button"
                className={`fr-tab ${t.key === activeType ? 'active' : ''}`}
                onClick={() => setType(t.key)}
              >
                {t.label}
                {t.note && <small>{t.note}</small>}
              </button>
            ))}
          </div>

          {slabs.map((slab, i) => (
            <div key={i} className="fr-row">
              <div className="fr-frame">{timeFrame(slab)}</div>
              <div className="fr-detail">
                {(slab.amount != null || slab.additionalFee != null) && (
                  <div className="fr-fee">
                    {money(slab.amount)}
                    {slab.additionalFee != null ? ` + ${money(slab.additionalFee)}` : ''}
                  </div>
                )}
                {policyLines(slab.policyInfo).map((line, j) => (
                  <div key={j} className="fr-policy">{line}</div>
                ))}
                {slab.amount == null && !policyLines(slab.policyInfo).length && (
                  <div className="fr-policy text-muted">As per airline policy.</div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      <ul className="fr-notes">
        <li>
          The airline fee is indicative, which will depend upon the time of cancellation /
          re-issue as per the airline fare rules.
        </li>
        <li>Mentioned fees are Per Pax Per Sector</li>
        <li>Apart from airline charges, GST + RAF + applicable charges if any, will be charged.</li>
        <li>For more clarity, Please check Detailed Rules</li>
      </ul>
    </div>
  );
}

