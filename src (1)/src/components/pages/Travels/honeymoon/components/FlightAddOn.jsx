import { useState, useEffect, useRef, useMemo } from 'react';
import { Plane, Armchair, Utensils, Luggage } from 'lucide-react';
import { getSeatMap } from '../../../../../services/api/flightApi';

const inr = (n) =>
  `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

/**
 * Group the seat prices on a map into legend bands.
 *
 * Free seats always stand alone; the rest are split wherever the jump to the
 * next price more than doubles, which is what separates "extra legroom" from
 * "front row" without hardcoding thresholds that vary per aircraft.
 */
const priceBands = (amounts) => {
  const distinct = [...new Set(amounts.filter((n) => n > 0))].sort((a, b) => a - b);
  const bands = [{ min: 0, max: 0 }];
  const groups = Math.min(4, distinct.length);
  for (let i = 0; i < groups; i += 1) {
    const chunk = distinct.slice(
      Math.floor((i * distinct.length) / groups),
      Math.floor(((i + 1) * distinct.length) / groups),
    );
    if (chunk.length) bands.push({ min: chunk[0], max: chunk[chunk.length - 1] });
  }
  return bands;
};

const bandLabel = (b) => (b.max === 0 ? inr(0) : b.min === b.max ? inr(b.min) : `${inr(b.min)} – ${inr(b.max)}`);
const bandOf = (amount, bands) => bands.findIndex((b) => amount >= b.min && amount <= b.max);

/** The portal's own bag glyph, from the CDN that serves its airline logos. */
const BAG_ICON = 'https://static.tripjack.com/img/Bag_Icon_New.svg';

/** Legs a passenger can buy add-ons for, with their SSR menus. */
const segmentsOf = (reviewData) => {
  const trips = Array.isArray(reviewData?.tripInfos)
    ? reviewData.tripInfos
    : Object.values(reviewData?.tripInfos || {}).flat();
  return trips.flatMap((t) =>
    (t?.sI || []).map((s) => ({
      id: String(s.id),
      from: s.da?.code,
      to: s.aa?.code,
      meals: s.ssrInfo?.MEAL || [],
      baggage: s.ssrInfo?.BAGGAGE || [],
      // On a connecting journey the bag is checked through, so TripJack prices
      // excess baggage on the first leg only and returns amount:null on the
      // rest. Buying against one of those legs is rejected with error 1129
      // ("Baggage not allowed for connecting segment"). A null amount on a
      // MEAL just means it is free, so this test is baggage-only.
      baggageSellable: (s.ssrInfo?.BAGGAGE || []).some((b) => b.amount != null),
    })),
  );
};

function SegmentTabs({ segments, active, onPick, countFor }) {
  return (
    <div className="ao-segtabs">
      {segments.map((seg) => (
        <button
          key={seg.id}
          type="button"
          className={`ao-segtab ${seg.id === active ? 'active' : ''}`}
          onClick={() => onPick(seg.id)}
        >
          <span>{seg.from} <Plane size={11} /> {seg.to}</span>
          <small>{countFor(seg.id)}</small>
        </button>
      ))}
    </div>
  );
}

/** − 0 + stepper shared by the meal and baggage cards. */
function Stepper({ qty, onChange, canAdd = true }) {
  return (
    <div className="ao-stepper">
      <button type="button" onClick={() => onChange(Math.max(0, qty - 1))} disabled={qty === 0}>−</button>
      <span>{qty}</span>
      <button type="button" onClick={() => onChange(qty + 1)} disabled={!canAdd || qty >= 1}>+</button>
    </div>
  );
}

/**
 * "Flight Add On" — seats, meals and baggage, chosen per passenger per segment.
 *
 * Keeping the segment in the key is what stops a seat picked on the second leg
 * from replacing the first; the previous standalone seat step keyed selections
 * by passenger alone and silently lost every leg but the last.
 */
export default function FlightAddOn({ reviewData, bookingId, passengers = [], value, onChange }) {
  const segments = useMemo(() => segmentsOf(reviewData), [reviewData]);
  const fsc = reviewData?.conditions?.fsc;
  const allowSeat = fsc?.issi !== false;
  const allowMeal = fsc?.ismi !== false;
  const allowBag = fsc?.isbi !== false;

  const [seatMap, setSeatMap] = useState(null);
  const [seatError, setSeatError] = useState(null);
  const [seatLoading, setSeatLoading] = useState(false);
  const [activePax, setActivePax] = useState(0);
  const [addonOpen, setAddonOpen] = useState(true);
  const [seatSeg, setSeatSeg] = useState(segments[0]?.id || '');
  const [mealSeg, setMealSeg] = useState(segments[0]?.id || '');
  const bagSegments = segments.filter((s) => s.baggageSellable);
  const [bagSeg, setBagSeg] = useState(bagSegments[0]?.id || '');
  const [bandFilter, setBandFilter] = useState([]);
  const requested = useRef(false);
  const mounted = useRef(true);

  useEffect(() => {
    mounted.current = true;
    return () => { mounted.current = false; };
  }, []);

  useEffect(() => {
    if (!allowSeat || !bookingId || requested.current) return;
    requested.current = true;
    setSeatLoading(true);
    getSeatMap(bookingId)
      .then((res) => {
        if (!mounted.current) return;
        if (res?.status?.success) setSeatMap(res.tripSeatMap?.tripSeat || {});
        else setSeatError(res?.errors?.[0]?.message || 'Seat selection is not available for this flight.');
      })
      .catch((err) => {
        requested.current = false;
        if (mounted.current) setSeatError('Could not load the seat map.');
        console.warn('[FlightAddOn] seat map failed', err?.message || err);
      })
      .finally(() => mounted.current && setSeatLoading(false));
  }, [allowSeat, bookingId]);

  useEffect(() => {
    if (!segments.length) return;
    setSeatSeg((v) => v || segments[0].id);
    setMealSeg((v) => v || segments[0].id);
    setBagSeg((v) => (v && bagSegments.some((s) => s.id === v) ? v : bagSegments[0]?.id || ''));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [segments]);

  const sel = value || { seats: {}, meals: {}, baggage: {} };
  const patch = (next) => onChange?.({ ...sel, ...next });

  const seatFor = (pax, segId) => sel.seats?.[pax]?.[segId] || null;
  const pickSeat = (seat, segId) => {
    const taken = Object.entries(sel.seats || {}).some(
      ([idx, bySeg]) => Number(idx) !== activePax && bySeg?.[segId]?.code === seat.seatNo,
    );
    if (seat.isBooked || taken) return;
    const current = seatFor(activePax, segId);
    const paxSeats = { ...(sel.seats?.[activePax] || {}) };
    if (current?.code === seat.seatNo) delete paxSeats[segId];
    else paxSeats[segId] = { code: seat.seatNo, amount: Number(seat.amount) || 0 };
    patch({ seats: { ...sel.seats, [activePax]: paxSeats } });
  };

  const ssrQty = (kind, pax, segId, code) => sel[kind]?.[pax]?.[segId]?.[code]?.qty || 0;
  /** The single choice this passenger has made on this leg, if any. */
  const ssrChosen = (kind, pax, segId) =>
    Object.values(sel[kind]?.[pax]?.[segId] || {}).find((i) => i.qty > 0) || null;

  const setSsrQty = (kind, segId, item, qty) => {
    const forPax = { ...(sel[kind]?.[activePax] || {}) };
    // Replacing the selection rather than appending keeps it to one per leg.
    const forSeg = qty > 0 ? {} : { ...(forPax[segId] || {}) };
    if (qty > 0) {
      forSeg[item.code] = { code: item.code, amount: Number(item.amount) || 0, desc: item.desc, qty: 1 };
    } else {
      delete forSeg[item.code];
    }
    forPax[segId] = forSeg;
    patch({ [kind]: { ...sel[kind], [activePax]: forPax } });
  };

  /** Passengers who have chosen on this leg, over the total — the "1/1" badge. */
  const ssrCount = (kind, segId) => {
    const total = passengers.length || 1;
    const done = Array.from({ length: total }, (_, i) => ssrChosen(kind, i, segId)).filter(Boolean).length;
    return `${done}/${total}`;
  };
  const seatCount = (segId) => {
    const total = passengers.length || 1;
    const done = Array.from({ length: total }, (_, i) => seatFor(i, segId)).filter(Boolean).length;
    return `${done}/${total}`;
  };

  const seatTotal = Object.values(sel.seats || {}).reduce(
    (n, bySeg) => n + Object.values(bySeg || {}).reduce((m, s) => m + (s.amount || 0), 0), 0);
  const ssrTotal = (kind) =>
    Object.values(sel[kind] || {}).reduce((n, bySeg) =>
      n + Object.values(bySeg || {}).reduce((m, byCode) =>
        m + Object.values(byCode || {}).reduce((k, i) => k + (i.amount || 0) * (i.qty || 0), 0), 0), 0);

  const paxName = (p, i) =>
    `${(p.type || 'ADULT').toUpperCase()}-${i + 1}`;

  const segMeta = segments.find((s) => s.id === seatSeg);
  const seatsForSeg = seatMap?.[seatSeg];
  const bands = useMemo(
    () => priceBands((seatsForSeg?.sInfo || []).map((s) => s.amount)),
    [seatsForSeg],
  );

  if (!segments.length) return null;

  const renderSeatGrid = () => {
    if (seatLoading) return <p className="ao-muted">Loading seat map…</p>;
    if (seatError) return <p className="ao-muted">{seatError}</p>;
    if (!seatsForSeg) return <p className="ao-muted">Seat selection is not available for this leg.</p>;

    const { sData, sInfo } = seatsForSeg;
    const byPos = new Map(sInfo.map((s) => [`${s.seatPosition.row}-${s.seatPosition.column}`, s]));
    const rows = Array.from({ length: sData.row }, (_, i) => i + 1);
    // Columns present in the data; the missing index is the aisle.
    const used = [...new Set(sInfo.map((s) => s.seatPosition.column))].sort((a, b) => a - b);
    const aisleAt = Array.from({ length: sData.column }, (_, i) => i + 1).find((c) => !used.includes(c));
    const letterFor = (col) => {
      const any = sInfo.find((s) => s.seatPosition.column === col);
      return any ? any.seatNo.replace(/^[0-9]+/, '') : '';
    };
    // Rendered nose-left: seat letters run down the page, rows across it.
    const displayCols = [...used].sort((a, b) => b - a);

    const visible = (seat) =>
      !bandFilter.length || bandFilter.includes(bandOf(seat.amount, bands));

    const renderRowOfSeats = (col) => (
      <div key={col} className="ao-seatrow">
        <span className="ao-seatrow-label">{letterFor(col)}</span>
        {rows.map((r) => {
          const seat = byPos.get(`${r}-${col}`);
          if (!seat) return <span key={r} className="ao-seat is-empty" />;
          const mine = seatFor(activePax, seatSeg)?.code === seat.seatNo;
          const takenByOther = Object.entries(sel.seats || {}).some(
            ([idx, bySeg]) => Number(idx) !== activePax && bySeg?.[seatSeg]?.code === seat.seatNo,
          );
          const band = bandOf(seat.amount, bands);
          return (
            <button
              key={r}
              type="button"
              className={`ao-seat band-${band} ${seat.isBooked ? 'is-booked' : ''} ${mine ? 'is-mine' : ''} ${takenByOther ? 'is-taken' : ''} ${visible(seat) ? '' : 'is-dimmed'}`}
              disabled={seat.isBooked || takenByOther}
              title={`${seat.seatNo} · ${seat.amount > 0 ? inr(seat.amount) : 'Free'}${seat.isLegroom ? ' · Extra legroom' : ''}`}
              onClick={() => pickSeat(seat, seatSeg)}
            >
              {seat.seatNo}
            </button>
          );
        })}
      </div>
    );

    const bodyHeight = displayCols.length * 30 + 26;

    return (
      <div className="ao-seatmap">
        <div className="ao-aircraft" style={{ '--ao-body-h': `${bodyHeight}px` }}>
          <div className="ao-nose">
            <img src="/images/aircraft/head.png" alt="" />
          </div>
          <div className="ao-deck">
            {displayCols.filter((c) => c > aisleAt).map(renderRowOfSeats)}
            <div className="ao-seatrow ao-aisle">
              <span className="ao-seatrow-label" />
              {rows.map((r) => <span key={r} className="ao-rownum">{r}</span>)}
            </div>
            {displayCols.filter((c) => c < aisleAt).map(renderRowOfSeats)}
          </div>
          <div className="ao-tail">
            <img src="/images/aircraft/tail.png" alt="" />
          </div>
        </div>
      </div>
    );
  };

  const ssrSection = (kind, label, Icon, seg, setSeg, items, total, segs = segments) => {
    const active = segs.find((s) => s.id === seg);
    const list = active ? items(active) : [];
    const chosen = ssrChosen(kind, activePax, seg);
    return (
      <div className="ao-block">
        <div className="ao-block-head"><Icon size={14} /> SELECT {label}</div>
        {kind === 'baggage' && segments.length > segs.length && (
          <p className="ao-bagnote">
            Your bag is checked through to the final destination, so extra
            baggage is bought once and covers the whole journey.
          </p>
        )}
        <SegmentTabs segments={segs} active={seg} onPick={setSeg} countFor={(id) => ssrCount(kind, id)} />
        {list.length === 0 ? (
          <p className="ao-muted">No {label.toLowerCase()} options on this leg.</p>
        ) : (
          <div className="ao-cards">
            {list.map((item) => (
              <div
                key={item.code}
                className={`ao-card ${kind === 'baggage' ? 'has-icon' : ''} ${chosen && chosen.code !== item.code ? 'is-locked' : ''} ${chosen?.code === item.code ? 'is-chosen' : ''}`}
              >
                {kind === 'baggage' && (
                  <div className="ao-card-icon">
                    <img
                      src={BAG_ICON}
                      alt=""
                      aria-hidden="true"
                      onError={(e) => { e.target.style.display = 'none'; }}
                    />
                  </div>
                )}
                <div className="ao-card-body">
                  <div className="ao-card-name">{item.desc || item.code}</div>
                  <div className="ao-card-foot">
                    <span className="ao-card-price">
                      {Number(item.amount) > 0 ? inr(item.amount) : 'FREE'}
                    </span>
                    <Stepper
                      qty={ssrQty(kind, activePax, seg, item.code)}
                      canAdd={!chosen || chosen.code === item.code}
                      onChange={(q) => setSsrQty(kind, seg, item, q)}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
        <div className="ao-paxchip">
          <strong>{paxName(passengers[activePax] || {}, activePax)}</strong>
          <span>{chosen ? `${label}: ${(chosen.desc || chosen.code).toUpperCase()}` : `SELECT ${label}`}</span>
        </div>
        <div className="ao-total">Total {label.charAt(0) + label.slice(1).toLowerCase()} Fee : {inr(total)}</div>
      </div>
    );
  };

  return (
    <div className="ao-panel">
      {/* The portal collapses this whole block behind one accordion header. */}
      <button
        type="button"
        className={`ao-head${addonOpen ? ' is-open' : ''}`}
        onClick={() => setAddonOpen((v) => !v)}
        aria-expanded={addonOpen}
      >
        <span><Plane size={14} /> Flight Add On</span>
        <i className="ao-head-caret" aria-hidden="true" />
      </button>

      {!addonOpen ? null : (
      <>

      {passengers.length > 1 && (
        <div className="ao-paxtabs">
          {passengers.map((p, i) => (
            <button
              key={i}
              type="button"
              className={`ao-paxtab ${i === activePax ? 'active' : ''}`}
              onClick={() => setActivePax(i)}
            >
              {paxName(p, i)}
            </button>
          ))}
        </div>
      )}

      {allowSeat && (
        <div className="ao-block">
          <div className="ao-block-head"><Armchair size={14} /> SELECT SEAT</div>
          <SegmentTabs
            segments={segments}
            active={seatSeg}
            onPick={setSeatSeg}
            countFor={seatCount}
          />
          <div className="ao-legend">
            <span className="ao-legend-title">SEAT STATUS:</span>
            <span><i className="ao-key is-mine" /> Selected</span>
            <span><i className="ao-key is-booked" /> Booked</span>
          </div>
          {bands.length > 1 && (
            <div className="ao-legend">
              <span className="ao-legend-title">SEAT ATTRIBUTES:</span>
              {bands.map((b, i) => (
                <label key={i} className="ao-band">
                  <i className={`ao-key band-${i}`} />
                  {bandLabel(b)}
                  <input
                    type="checkbox"
                    checked={bandFilter.includes(i)}
                    onChange={() =>
                      setBandFilter((f) => (f.includes(i) ? f.filter((x) => x !== i) : [...f, i]))
                    }
                  />
                </label>
              ))}
            </div>
          )}
          {renderSeatGrid()}
          <div className="ao-paxchip">
            <strong>{paxName(passengers[activePax] || {}, activePax)}</strong>
            <span>{seatFor(activePax, seatSeg)?.code || 'SELECT SEAT'}</span>
          </div>
          <div className="ao-total">Total Seat Fee : {inr(seatTotal)}</div>
          <p className="ao-note">
            * Conditions apply. We will try our best to accommodate your seat preferences, however due
            to operational considerations we cannot guarantee this selection. The seat map shown may not
            be an exact replica of the flight layout.
          </p>
        </div>
      )}

      {allowMeal && ssrSection('meals', 'MEAL', Utensils, mealSeg, setMealSeg, (s) => s.meals, ssrTotal('meals'))}
      {allowBag && bagSegments.length > 0 &&
        ssrSection('baggage', 'BAGGAGE', Luggage, bagSeg, setBagSeg, (s) => s.baggage, ssrTotal('baggage'), bagSegments)}
      </>
      )}
    </div>
  );
}

/**
 * Flatten the selections into the ssr arrays /oms/v1/air/book expects.
 *
 * `reviewData` is optional but worth passing: it lets the baggage array be
 * filtered to the legs TripJack actually prices, so a selection left over from
 * before that rule was enforced can never reach the book call and trip error
 * 1129.
 */
export const ssrForTraveller = (value, paxIndex, reviewData) => {
  const seats = Object.entries(value?.seats?.[paxIndex] || {}).map(([key, s]) => ({ key, code: s.code }));
  const expand = (kind) =>
    Object.entries(value?.[kind]?.[paxIndex] || {}).flatMap(([key, byCode]) =>
      Object.values(byCode || {}).flatMap((item) =>
        // A quantity of N is N separate SSR entries — TripJack has no qty field.
        Array.from({ length: item.qty || 0 }, () => ({ key, code: item.code })),
      ),
    );

  const sellable = reviewData
    ? new Set(segmentsOf(reviewData).filter((s) => s.baggageSellable).map((s) => s.id))
    : null;
  const bags = expand('baggage').filter((b) => !sellable || sellable.has(String(b.key)));

  return {
    ...(seats.length && { ssrSeatInfos: seats }),
    ...(expand('meals').length && { ssrMealInfos: expand('meals') }),
    ...(bags.length && { ssrBaggageInfos: bags }),
  };
};

/** Per-kind add-on totals across all passengers, for the fare summary. */
export const addOnBreakdown = (value) => {
  const seat = Object.values(value?.seats || {}).reduce(
    (n, bySeg) => n + Object.values(bySeg || {}).reduce((m, s) => m + (s.amount || 0), 0), 0);
  const sumSsr = (kind) =>
    Object.values(value?.[kind] || {}).reduce((n, bySeg) =>
      n + Object.values(bySeg || {}).reduce((m, byCode) =>
        m + Object.values(byCode || {}).reduce((k, i) => k + (i.amount || 0) * (i.qty || 0), 0), 0), 0);
  return { Seat: seat, Meal: sumSsr('meals'), Baggage: sumSsr('baggage') };
};

/** Grand total of every add-on across all passengers. */
export const addOnTotal = (value) => {
  const seats = Object.values(value?.seats || {}).reduce(
    (n, bySeg) => n + Object.values(bySeg || {}).reduce((m, s) => m + (s.amount || 0), 0), 0);
  const ssr = ['meals', 'baggage'].reduce((total, kind) =>
    total + Object.values(value?.[kind] || {}).reduce((n, bySeg) =>
      n + Object.values(bySeg || {}).reduce((m, byCode) =>
        m + Object.values(byCode || {}).reduce((k, i) => k + (i.amount || 0) * (i.qty || 0), 0), 0), 0), 0);
  return seats + ssr;
};
