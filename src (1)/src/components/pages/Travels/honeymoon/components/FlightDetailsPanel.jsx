import { useState, useEffect } from 'react';
import { X } from 'lucide-react';
import { getFareRule } from '../../../../../services/api/flightApi';
import FareRulesPanel from './FareRulesPanel';
import { airlineLogo } from '../../../../../utils/airlineLogo';

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const inr = (n) =>
  `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

/** "Aug 28, Fri, 08:15" */
const stamp = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${WEEKDAYS[d.getDay()]}, ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

/** "Fri, Aug 28th 2026" */
const longDate = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  const n = d.getDate();
  const ord = n % 10 === 1 && n !== 11 ? 'st' : n % 10 === 2 && n !== 12 ? 'nd' : n % 10 === 3 && n !== 13 ? 'rd' : 'th';
  return `${WEEKDAYS[d.getDay()]}, ${MONTHS[d.getMonth()]} ${n}${ord} ${d.getFullYear()}`;
};

const mins = (m) => `${Math.floor(m / 60)}h ${String(m % 60).padStart(2, '0')}m`;

const PAX_LABEL = { ADULT: 'Adult', CHILD: 'Child', INFANT: 'Infant' };

/**
 * The results card's expanded panel: Flight Details, Fare Details and Fare
 * Rules, matching the portal's three tabs.
 *
 * Fare rules are the only tab that costs a request, so they load on first
 * open of that tab rather than when the panel expands.
 */
export default function FlightDetailsPanel({ flight, fare, searchParams = {}, onClose }) {
  const [tab, setTab] = useState('flight');
  const [rules, setRules] = useState(null);
  const [rulesLoading, setRulesLoading] = useState(false);

  useEffect(() => {
    if (tab !== 'rules' || rules || !fare?.id) return;
    setRulesLoading(true);
    getFareRule(fare.id, 'SEARCH')
      .then(setRules)
      .catch(() => setRules({ error: true }))
      .finally(() => setRulesLoading(false));
  }, [tab, rules, fare?.id]);

  const segs = flight?.sI || [];
  if (!segs.length) return null;
  const first = segs[0];
  const last = segs[segs.length - 1];

  const paxCounts = {
    ADULT: Number(searchParams.adults || 1),
    CHILD: Number(searchParams.children || 0),
    INFANT: Number(searchParams.infants || 0),
  };

  const renderFlight = () => (
    <div className="fdp-flight">
      <div className="fdp-route">
        <strong>{first.da.city}</strong> <span className="fdp-arrow">→</span>{' '}
        <strong>{last.aa.city}</strong>
        <small>{longDate(first.dt)}</small>
      </div>

      {segs.map((seg, i) => (
        <div key={seg.id ?? i}>
          <div className="fdp-seg">
            <div className="fdp-seg-airline">
              <img
                src={airlineLogo(seg.fD.aI.code)}
                alt={seg.fD.aI.name}
                onError={(e) => { e.target.style.visibility = 'hidden'; }}
              />
              <div>
                <div className="fdp-flightno">
                  {seg.fD.aI.code}-{seg.fD.fN}
                  {seg.fD.eT && <span className="fdp-aircraft">✈ {seg.fD.eT}</span>}
                </div>
                <div className="fdp-cabin">{fare?.fd?.ADULT?.cc || 'ECONOMY'}</div>
                {fare?.fd?.ADULT && (
                  <div className="fdp-seats">
                    CB:{fare.fd.ADULT.cB}{' '}
                    <b>{fare.fd.ADULT.sR} seat(s) left</b>
                  </div>
                )}
              </div>
            </div>

            <div className="fdp-seg-point">
              <div className="fdp-time">{stamp(seg.dt)}</div>
              <div>{seg.da.city}, {seg.da.country}</div>
              <div className="fdp-airport">{seg.da.name}</div>
              {seg.da.terminal && <div className="fdp-airport">{seg.da.terminal}</div>}
            </div>

            <div className="fdp-seg-mid">
              <span className="fdp-nonstop">Non-Stop</span>
              <span className="fdp-line" />
              <span className="fdp-dur">{mins(seg.duration || 0)}</span>
            </div>

            <div className="fdp-seg-point">
              <div className="fdp-time">{stamp(seg.at)}</div>
              <div>{seg.aa.city}, {seg.aa.country}</div>
              <div className="fdp-airport">{seg.aa.name}</div>
              {seg.aa.terminal && <div className="fdp-airport">{seg.aa.terminal}</div>}
            </div>

            <div className="fdp-bags">
              <div className="fdp-bags-title">Baggage Information</div>
              <table>
                <thead>
                  <tr><th>Pax Type</th><th>Check In</th><th>Cabin</th></tr>
                </thead>
                <tbody>
                  {Object.entries(paxCounts)
                    .filter(([, n]) => n > 0)
                    .map(([type]) => (
                      <tr key={type}>
                        <td>{PAX_LABEL[type]}</td>
                        <td>{fare?.fd?.[type]?.bI?.iB || 'NA'}</td>
                        <td>{fare?.fd?.[type]?.bI?.cB || 'NA'}</td>
                      </tr>
                    ))}
                </tbody>
              </table>
            </div>
          </div>

          {i < segs.length - 1 && (
            <div className="fdp-layover">
              Require to change Plane
              {seg.cT ? <span>Layover Time - {mins(seg.cT)}</span> : null}
            </div>
          )}
        </div>
      ))}
    </div>
  );

  const renderFare = () => (
    <div className="fdp-fare">
      <table className="fdp-fare-table">
        <thead>
          <tr><th>TYPE</th><th>Fare</th><th>Total</th></tr>
        </thead>
        {Object.entries(paxCounts)
          .filter(([, n]) => n > 0)
          .map(([type, count]) => {
            const fd = fare?.fd?.[type];
            if (!fd) return null;
            return (
              <tbody key={type}>
                <tr className="fdp-fare-group">
                  <td colSpan={3}>
                    Fare Details for {PAX_LABEL[type]} (CB: {fd.cB})
                  </td>
                </tr>
                <tr>
                  <td>Base Price</td>
                  <td>{inr(fd.fC.BF)} x {count}</td>
                  <td>{inr(fd.fC.BF * count)}</td>
                </tr>
                <tr>
                  <td>Taxes and fees</td>
                  <td>{inr(fd.fC.TAF)} x {count}</td>
                  <td>{inr(fd.fC.TAF * count)}</td>
                </tr>
              </tbody>
            );
          })}
        <tfoot>
          <tr>
            <td>Total</td>
            <td />
            <td>
              {inr(
                Object.entries(paxCounts).reduce(
                  (n, [type, count]) => n + (fare?.fd?.[type]?.fC?.TF || 0) * count,
                  0,
                ),
              )}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
  );

  return (
    <div className="fdp">
      <div className="fdp-tabs">
        <button type="button" className={tab === 'flight' ? 'active' : ''} onClick={() => setTab('flight')}>
          Flight Details
        </button>
        <button type="button" className={tab === 'fare' ? 'active' : ''} onClick={() => setTab('fare')}>
          Fare Details
        </button>
        <button type="button" className={tab === 'rules' ? 'active' : ''} onClick={() => setTab('rules')}>
          Fare Rules
        </button>
        <button type="button" className="fdp-close" onClick={onClose} aria-label="Close details">
          <X size={18} />
        </button>
      </div>

      <div className="fdp-body">
        {tab === 'flight' && renderFlight()}
        {tab === 'fare' && renderFare()}
        {tab === 'rules' && (
          rulesLoading ? <p className="ao-muted">Loading fare rules…</p>
            : rules?.error ? <p className="ao-muted">Fare rules unavailable. Please contact support.</p>
            : rules ? <FareRulesPanel data={rules} />
            : null
        )}
      </div>
    </div>
  );
}
