import { useState } from 'react';
import { X, Plane, ChevronDown, ChevronUp } from 'lucide-react';
import { airlineLogo } from '../../../../../utils/airlineLogo';

/**
 * The portal's PRINT TICKET dialog: pick which PNRs to print, one pricing
 * mode, and a set of content toggles. Submitting hands the chosen options to
 * the caller, which applies them to the ticket and opens the print dialog.
 *
 * The portal drives the same options through query params on its print route
 * (`?showPrice=1&agentDetails=true&gst=true&…`); ours are passed straight to
 * the ticket component instead, which keeps the booking data in memory rather
 * than refetching it.
 */

const OTHER_OPTIONS = [
  { key: 'agentDetails', label: 'With Agency' },
  { key: 'gst', label: 'With GST' },
  { key: 'isOldPrintCopy', label: 'Old Print Copy' },
  { key: 'passportInfo', label: 'Passport Info' },
  { key: 'agentNotes', label: 'Agent Notes' },
  { key: 'showRefundable', label: 'Show Refundable/Non-Refundable' },
  { key: 'showContact', label: 'Show Contact Details' },
];

export default function PrintTicketModal({ pnrs = [], segments = [], onClose, onSubmit }) {
  const [selected, setSelected] = useState(() => pnrs.map((p) => p.code));
  const [pricing, setPricing] = useState('withPrice');
  const [expanded, setExpanded] = useState(null);
  const [flags, setFlags] = useState({
    agentDetails: true,
    gst: true,
    isOldPrintCopy: false,
    passportInfo: true,
    agentNotes: false,
    showRefundable: true,
    showContact: true,
  });

  const toggleFlag = (key) => setFlags((p) => ({ ...p, [key]: !p[key] }));
  const togglePnr = (code) =>
    setSelected((p) => (p.includes(code) ? p.filter((c) => c !== code) : [...p, code]));

  // Nothing to print until a PNR is ticked. A booking with no PNR at all is a
  // different case — blocking there would make the ticket unprintable, so the
  // gate only applies when there is something to choose.
  const canSubmit = pnrs.length === 0 || selected.length > 0;

  const submit = () => {
    if (!canSubmit) return;
    onSubmit({
      ...flags,
      selectedPnrs: selected,
      showPrice: pricing !== 'withoutPrice',
      hideMarkup: pricing === 'hideMarkup',
    });
  };

  return (
    <div className="pt-overlay" role="dialog" aria-modal="true" aria-label="Print ticket">
      <div className="pt-modal">
        <div className="pt-head">
          <span className="pt-title">🎟 PRINT TICKET</span>
          <button type="button" onClick={onClose} aria-label="Close"><X size={18} /></button>
        </div>

        <div className="pt-body">
          <div className="pt-card">
            <div className="pt-card-title">Select PNR to Print</div>
            <div className="pt-selectrow">
              <button type="button" className="pt-link" onClick={() => setSelected(pnrs.map((p) => p.code))}>
                Select All
              </button>
              <button type="button" className="pt-link is-clear" onClick={() => setSelected([])}>
                Clear All
              </button>
            </div>

            {pnrs.length === 0 && (
              <p className="pt-empty">No airline PNR yet — the ticket will print without one.</p>
            )}

            {pnrs.map((p) => (
              <div className="pt-pnr" key={p.code}>
                <label className="pt-check">
                  <input
                    type="checkbox"
                    checked={selected.includes(p.code)}
                    onChange={() => togglePnr(p.code)}
                  />
                  <span className="pt-pnr-chip"><Plane size={12} /> {p.code}</span>
                </label>
                <button
                  type="button"
                  className="pt-link pt-expand"
                  onClick={() => setExpanded(expanded === p.code ? null : p.code)}
                >
                  View Flight Details {expanded === p.code ? <ChevronUp size={13} /> : <ChevronDown size={13} />}
                </button>

                {expanded === p.code && (
                  <div className="pt-segs">
                    {segments.map((s) => (
                      <div className="pt-seg" key={s.id}>
                        <img
                          src={airlineLogo(s.airlineCode)}
                          alt={s.airline}
                          onError={(e) => { e.target.style.visibility = 'hidden'; }}
                        />
                        <div className="pt-seg-air">
                          <strong>{s.airline}</strong>
                          <small>{s.airlineCode}-{s.flightNo}</small>
                        </div>
                        <div className="pt-seg-pt">
                          <strong>{s.from}</strong>
                          <small>({s.depart})</small>
                        </div>
                        <Plane size={13} className="pt-seg-icon" />
                        <div className="pt-seg-pt">
                          <strong>{s.to}</strong>
                          <small>({s.arrive})</small>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>

          <div className="pt-card">
            <div className="pt-card-title">
              Select Desire Pricing Option <small>( you can select only one option )</small>
            </div>
            <div className="pt-radios">
              {[
                ['withPrice', 'With Price'],
                ['withoutPrice', 'Without Price'],
                ['hideMarkup', 'Hide Markup'],
              ].map(([value, label]) => (
                <label className="pt-radio" key={value}>
                  <input
                    type="radio"
                    name="pt-pricing"
                    checked={pricing === value}
                    onChange={() => setPricing(value)}
                  />
                  <span>{label}</span>
                </label>
              ))}
            </div>

            <div className="pt-card-title pt-sub">Select Other Options</div>
            <div className="pt-flags">
              {OTHER_OPTIONS.map((o) => (
                <label className="pt-check" key={o.key}>
                  <input type="checkbox" checked={flags[o.key]} onChange={() => toggleFlag(o.key)} />
                  <span>{o.label}</span>
                </label>
              ))}
            </div>
          </div>
        </div>

        <div className="pt-foot">
          <button
            type="button"
            className="pt-submit"
            onClick={submit}
            disabled={!canSubmit}
            title={canSubmit ? undefined : 'Select at least one PNR to print'}
          >
            SUBMIT
          </button>
          {!canSubmit && (
            <p className="pt-hint">Select at least one PNR to continue.</p>
          )}
        </div>
      </div>
    </div>
  );
}
