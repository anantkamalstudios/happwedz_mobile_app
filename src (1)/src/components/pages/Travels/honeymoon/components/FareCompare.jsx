import { useState, useEffect, useRef } from 'react';
import { ChevronLeft, ChevronRight, Tag, Briefcase, Calendar, MapPin, Utensils } from 'lucide-react';
import { getFareRule } from '../../../../../services/api/flightApi';

const PER_PAGE = 3;

const money = (n) =>
  `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

/** Fare for the whole party — `fd` amounts are per passenger. */
const farePrice = (f, pax) =>
  Object.entries(pax || { ADULT: 1 }).reduce((total, [type, count]) => {
    if (!count) return total;
    const fc = f?.fd?.[type]?.fC;
    return total + Number(fc?.TF ?? fc?.NF ?? f?.fd?.ADULT?.fC?.TF ?? 0) * count;
  }, 0);
const fareLabel = (id) => {
  if (!id) return 'Published';
  if (/^NDC_/i.test(id)) return `NDC ${id.replace(/^NDC_/i, '')}`;
  if (/^[A-Z]{2,4}$/.test(id)) return id;
  return id.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
};

/**
 * `st`/`et` are hours before departure. TripJack renders the outer bounds as
 * "4 hrs to 365 days", so anything past a day is expressed in days.
 */
const windowLabel = (slabs) => {
  if (!slabs?.length) return '';
  const start = Math.min(...slabs.map((s) => Number(s.st ?? 0)));
  const end = Math.max(...slabs.map((s) => Number(s.et ?? 0)));
  const asUnit = (h) => (h >= 24 ? `${Math.round(h / 24)} days` : `${h} hrs`);
  return `${asUnit(start).replace(' days', ' days').replace(/^0 hrs$/, '0 hrs')} to ${asUnit(end)}`;
};

/** Flatten every route's slabs for one policy type — fees are per pax per sector. */
/** The API returns `fareRule`; older notes used `farerule`. Accept both. */
const ruleRoutes = (ruleData) => ruleData?.fareRule || ruleData?.farerule || {};

const slabsOf = (ruleData, type) => {
  const rule = ruleRoutes(ruleData);
  const out = [];
  for (const route of Object.keys(rule)) {
    const tfr = rule[route]?.tfr || {};
    const list = Array.isArray(tfr[type]) ? tfr[type] : tfr[type] ? [tfr[type]] : [];
    out.push(...list);
  }
  return out;
};

const clean = (text) =>
  String(text || '').replace(/__[a-z]+__/gi, ' ').replace(/\s+/g, ' ').trim();

/**
 * Structured slabs are not always available. Depending on the airline and the
 * flowType, /fms/v2/farerule answers with free-text `miscInfo` instead of a
 * `tfr` breakdown — so fall back to the prose rather than showing "NA" over
 * rules that do exist.
 */
const miscOf = (ruleData, keyword) => {
  const rule = ruleRoutes(ruleData);
  const lines = [];
  for (const route of Object.keys(rule)) {
    for (const line of rule[route]?.miscInfo || []) {
      const text = clean(line);
      if (text && (!keyword || new RegExp(keyword, 'i').test(text))) lines.push(text);
    }
  }
  return lines.join(' ');
};

const feeText = (slab) => {
  if (!slab) return null;
  const base = slab.amount != null ? money(slab.amount) : null;
  const extra = slab.additionalFee != null ? money(slab.additionalFee) : null;
  if (!base && !extra) return null;
  return `${base || money(0)}${extra ? ` + ${extra}` : ''}`;
};

/**
 * Fare-family comparison drawer, matching the portal's layout: a labelled rail
 * on the left and one card per fare, paged three at a time.
 *
 * Cancellation and date-change fees are not in the search response — they come
 * from /fms/v2/farerule, fetched once per fare when the drawer opens.
 */
export default function FareCompare({ fares, selectedIndex, onPick, onBook, pax }) {
  const [rules, setRules] = useState({});
  const [start, setStart] = useState(0);

  // Keyed on the ids, not the array — the parent rebuilds `totalPriceList` when
  // filters change, and depending on the reference would refetch every rule and
  // trip the BFF rate limiter. `requested` makes each id a one-shot.
  const fareIds = fares.map((f) => f?.id).filter(Boolean).join('|');
  const requested = useRef(new Set());

  // Guard on unmount only, never per-effect-run. A per-run `cancelled` flag
  // deadlocks against `requested`: StrictMode's mount→cleanup→mount cancels the
  // first run's in-flight request, the second run skips it as already
  // requested, and the reply is discarded — leaving the cell on "Loading…".
  const mounted = useRef(true);
  useEffect(() => {
    // Must re-arm on every mount: StrictMode runs mount → cleanup → mount, and
    // a cleanup-only effect would leave this false for the rest of the session.
    mounted.current = true;
    return () => { mounted.current = false; };
  }, []);

  useEffect(() => {
    const load = async (id) => {
      if (requested.current.has(id)) return;
      requested.current.add(id);
      setRules((p) => ({ ...p, [id]: { loading: true } }));
      try {
        const data = await getFareRule(id, 'SEARCH');
        if (mounted.current) setRules((p) => ({ ...p, [id]: { data } }));
      } catch (err) {
        // Allow a retry on the next open rather than caching the failure.
        requested.current.delete(id);
        if (mounted.current) setRules((p) => ({ ...p, [id]: { error: true } }));
        console.warn('[FareCompare] fare rule fetch failed', id, err?.message || err);
      }
    };
    fareIds.split('|').filter(Boolean).forEach(load);
  }, [fareIds]);

  // Window slides by one so the middle cards stay on screen while paging.
  const maxStart = Math.max(0, fares.length - PER_PAGE);
  const offset = Math.min(start, maxStart);
  const shown = fares.slice(offset, offset + PER_PAGE);

  // Row windows are taken from the first fare that has rules, so the left rail
  // reads "4 hrs to 365 days" rather than staying blank while others load.
  const anyRule = fares.map((f) => rules[f.id]?.data).find(Boolean);
  const cancelWindow = windowLabel(slabsOf(anyRule, 'CANCELLATION'));
  const changeWindow = windowLabel(slabsOf(anyRule, 'DATECHANGE'));

  const cell = (fare, i) => {
    const idx = offset + i;
    const state = rules[fare.id] || {};
    const isSel = idx === selectedIndex;
    const bag = fare?.fd?.ADULT?.bI || {};
    const cancel = slabsOf(state.data, 'CANCELLATION')[0];
    const change = slabsOf(state.data, 'DATECHANGE')[0];
    const seat = slabsOf(state.data, 'SEAT_CHARGEABLE')[0];
    const key = `${fare.id}`;

    const policy = (slab, label, keyword) => {
      if (state.loading) return <span className="fcmp-muted">Loading…</span>;
      if (state.error) return <span className="fcmp-muted">Unavailable</span>;

      const fee = feeText(slab);
      // Prefer the slab's own note; otherwise fall back to the free-text rules.
      const info = clean(slab?.policyInfo) || miscOf(state.data, keyword);
      if (!fee && !info) return <span className="fcmp-muted">NA</span>;

      const excerpt = info.length > 30 ? `${info.slice(0, 30)}…` : info;

      return (
        <>
          {fee && <div className="fcmp-fee">{fee}</div>}
          {info ? (
            <div className="fcmp-policy" tabIndex={0}>
              <span className="fcmp-excerpt">
                {fee ? '| ' : ''}{excerpt}
              </span>
              <span className="fcmp-more">See More</span>
              {/* Kept in the DOM so the transition plays on the way out too. */}
              <span className="fcmp-pop" role="tooltip">{info}</span>
            </div>
          ) : null}
        </>
      );
    };

    return (
      <div key={fare.id || idx} className={`fcmp-col ${isSel ? 'is-selected' : ''}`}>
        <button
          type="button"
          className="fcmp-cell fcmp-head"
          onClick={(e) => { e.stopPropagation(); onPick(idx); }}
          title="Select this fare"
        >
          <span className="fcmp-radio">{isSel ? '●' : '○'}</span>
          {fareLabel(fare?.fareIdentifier)}
        </button>
        <div className="fcmp-cell fcmp-price">{money(farePrice(fare, pax))}</div>
        <div className="fcmp-cell fcmp-bags">
          <div>
            <div className="fcmp-bag-label">Check In Bag</div>
            <div className="fcmp-bag-value">{bag.iB || 'NA'}</div>
          </div>
          <div>
            <div className="fcmp-bag-label">Cabin Bag</div>
            <div className="fcmp-bag-value">{bag.cB || 'NA'}</div>
          </div>
        </div>
        <div className="fcmp-cell">{policy(cancel, 'cancel', 'cancel|refund')}</div>
        <div className="fcmp-cell">{policy(change, 'change', 'change|reissue|re-issue')}</div>
        <div className="fcmp-cell fcmp-centre">
          {clean(seat?.policyInfo) || <span className="fcmp-muted">NA</span>}
        </div>
        <div className="fcmp-cell fcmp-centre">
          {fare?.fd?.ADULT?.mI === true ? 'Included' : 'Chargeable'}
        </div>
        <div className="fcmp-cell fcmp-action">
          <button
            type="button"
            className="fcmp-book"
            onClick={(e) => {
              e.stopPropagation();
              onPick(idx);
              onBook?.(idx);
            }}
          >
            BOOK NOW
          </button>
        </div>
      </div>
    );
  };

  return (
    <div className="fc-compare-panel">
      <div className="fcmp-grid">
        <div className="fcmp-rail">
          <div className="fcmp-cell fcmp-rail-head">Services (Per Pax)</div>
          <div className="fcmp-cell"><Tag size={13} /> Fares</div>
          <div className="fcmp-cell fcmp-rail-bags">
            <span><Briefcase size={13} /> Baggage Info</span>
            <small>Adult (Age 12+)</small>
          </div>
          <div className="fcmp-cell">
            <span><Calendar size={13} /> Cancellation Fee</span>
            {cancelWindow && <small>✈ {cancelWindow}</small>}
          </div>
          <div className="fcmp-cell">
            <span><Calendar size={13} /> Date Change Fee</span>
            {changeWindow && <small>✈ {changeWindow}</small>}
          </div>
          <div className="fcmp-cell"><MapPin size={13} /> Seat Charge</div>
          <div className="fcmp-cell"><Utensils size={13} /> Meals</div>
          <div className="fcmp-cell" />
        </div>

        {shown.map(cell)}
      </div>

      {fares.length > PER_PAGE && (
        <>
          <button
            type="button"
            className="fcmp-nav fcmp-nav-prev"
            onClick={() => setStart((v) => Math.max(0, v - 1))}
            disabled={offset === 0}
            aria-label="Previous fare"
          >
            <ChevronLeft size={16} />
          </button>
          <button
            type="button"
            className="fcmp-nav fcmp-nav-next"
            onClick={() => setStart((v) => Math.min(maxStart, v + 1))}
            disabled={offset >= maxStart}
            aria-label="Next fare"
          >
            <ChevronRight size={16} />
          </button>
        </>
      )}

      <ul className="fcmp-notes">
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
