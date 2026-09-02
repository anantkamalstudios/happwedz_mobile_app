import { useState } from 'react';
import { X, CheckCircle2, XCircle } from 'lucide-react';
import './CabPolicyModal.css';

/**
 * The "Cab policies" dialog: four tabs over what the
 * quote's `policies` block carries.
 *
 * Amendment and baggage come back as free text only on some vendors, so each
 * falls back to our own standing wording rather than showing an empty tab —
 * and the amendment fallback names our contact details, not the supplier's.
 */

const SUPPORT_PHONE = '+91 77700 05377';
const SUPPORT_EMAIL = 'support@happywedz.com';

const TABS = [
  { key: 'inclusions', label: 'Inclusions & Exclusions' },
  { key: 'cancellation', label: 'Cancellation charges' },
  { key: 'amendment', label: 'Amendment Policy' },
  { key: 'baggage', label: 'Baggage' },
];

/** "Within 24 hours before departure" from a { minHours } rule. */
const windowLabel = (rule) => {
  if (rule?.description) return rule.description;
  const h = Number(rule?.minHours);
  if (!Number.isFinite(h)) return 'As per policy';
  return h === 0
    ? 'Within 24 hours before departure'
    : `Upto ${h} hours before departure`;
};

export default function CabPolicyModal({ quote, onClose }) {
  const [tab, setTab] = useState('inclusions');
  const policies = quote?.policies || {};

  const inclusions = policies.inclusions || [];
  const exclusions = policies.exclusions || [];
  const cancellation = policies.cancellationPolicy || [];

  return (
    <div className="cpm-overlay" role="dialog" aria-modal="true" aria-label="Cab policies">
      <div className="cpm-modal">
        <div className="cpm-head">
          <strong>Cab policies</strong>
          <button type="button" onClick={onClose} aria-label="Close"><X size={18} /></button>
        </div>

        <div className="cpm-tabs">
          {TABS.map((t) => (
            <button
              key={t.key}
              type="button"
              className={tab === t.key ? 'is-on' : ''}
              onClick={() => setTab(t.key)}
            >
              {t.label}
            </button>
          ))}
        </div>

        <div className="cpm-body">
          {tab === 'inclusions' && (
            <>
              <div className="cpm-panel">
                <div className="cpm-panel-head is-in">
                  <CheckCircle2 size={16} /> Inclusions
                </div>
                {inclusions.length ? (
                  <ul>{inclusions.map((i) => <li key={i}>{i}</li>)}</ul>
                ) : (
                  <p className="cpm-empty">No inclusions listed for this vehicle.</p>
                )}
              </div>

              <div className="cpm-panel">
                <div className="cpm-panel-head is-ex">
                  <XCircle size={16} /> Exclusions
                </div>
                {exclusions.length ? (
                  <ul>{exclusions.map((i) => <li key={i}>{i}</li>)}</ul>
                ) : (
                  <p className="cpm-empty">No exclusions listed for this vehicle.</p>
                )}
              </div>
            </>
          )}

          {tab === 'cancellation' && (
            cancellation.length ? (
              <table className="cpm-table">
                <thead>
                  <tr><th>Cancellation Time</th><th>Cancellation Fee</th></tr>
                </thead>
                <tbody>
                  {cancellation.map((rule, i) => (
                    <tr key={`${rule.minHours ?? i}-${rule.refundPercentage ?? ''}`}>
                      <td>{windowLabel(rule)}</td>
                      <td>{rule.refundPercentage ?? 0}% Refund</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            ) : (
              <p className="cpm-note">Cancellation terms are confirmed by the operator at booking.</p>
            )
          )}

          {tab === 'amendment' && (
            <p className="cpm-note">
              {policies.amendmentPolicy ||
                `Please contact us at ${SUPPORT_PHONE} or ${SUPPORT_EMAIL} for any amendments or modifications to the booking. Extra charges may apply.`}
            </p>
          )}

          {tab === 'baggage' && (
            <p className="cpm-note">
              {policies.baggagePolicy ||
                'Excess luggage requires guests to either arrange a separate vehicle or upgrade the vehicle in advance.'}
            </p>
          )}
        </div>
      </div>
    </div>
  );
}
