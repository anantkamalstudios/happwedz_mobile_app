import { formatDuration, shortDob } from './flightFormat';

/**
 * The printable ticket, laid out like the portal's print view: agency header,
 * PNR block, then black-barred Flight Detail / Passenger Details / Fare Details
 * / Important Information sections.
 *
 * It renders into the page but is hidden on screen — `@media print` swaps the
 * booking page out for this. That is what the portal does too: its "Download as
 * PDF" is the browser's own print dialog saving to PDF, not a server render.
 *
 * Every `opts` flag maps to a checkbox in the Print Ticket dialog.
 */

const inr = (n) =>
  `₹${Number(n || 0).toLocaleString('en-IN', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/** "Fri, 28 Aug '26, 08:15" */
const printStamp = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${WEEKDAYS[d.getDay()]}, ${d.getDate()} ${MONTHS[d.getMonth()]} '${String(d.getFullYear()).slice(2)}, ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

const bookingStamp = (value) => {
  const d = value ? new Date(value) : new Date();
  if (Number.isNaN(d.getTime())) return '';
  const h = d.getHours();
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()} ${h % 12 || 12}:${String(d.getMinutes()).padStart(2, '0')} ${h >= 12 ? 'PM' : 'AM'}`;
};

const PAX_INITIAL = { ADULT: 'A', CHILD: 'C', INFANT: 'I' };

/** Agency block printed top-right. */
const AGENCY = {
  name: 'Happy Wedz',
  email: 'support@happywedz.com',
  phone: '7770005377',
  address:
    'Happy Wedz Head Office, In premises of Nahata Lawns & Banquets, Wadgaon Budruk, Pune, Maharashtra 411041 India',
};

const DANGEROUS = [
  'Lighters', 'Flammable Liquids', 'Toxic', 'Bleach', 'Explosives',
  'Infectious Substances', 'Pepper Spray', 'RadioActive Materials',
  'Flammable Gas', 'Corrosive',
];

const HAND_ONLY = ['Power Banks', 'Lithium Batteries'];

const IMPORTANT = [
  'You should carry a print-out of your booking and present for check-in.',
  'Date & Time is calculated based on the local time of city/destination.',
  'Use the Reference Number for all Correspondence with us.',
  'Use the Airline PNR for all Correspondence directly with the Airline',
  'For departure terminal please check with airline first.',
  'Please CheckIn atleast 2 hours prior to the departure for domestic flight and 3 hours prior to the departure of international flight.',
  'For rescheduling/cancellation within 4 hours of departure time contact the airline directly',
];

export default function TicketDocument({
  bookingData,
  trip,
  returnTrip,
  fare,
  returnFare,
  travellerInfo = [],
  paxInfos = [],
  addOns,
  searchParams = {},
  gstInfo,
  agentNote,
  markup = 0,
  carrierLink,
  opts = {},
}) {
  const {
    showPrice = true,
    hideMarkup = false,
    agentDetails = true,
    gst = true,
    passportInfo = true,
    agentNotes = false,
    showRefundable = true,
    showContact = true,
    selectedPnrs = null,
  } = opts;

  const legs = [
    { trip, fare },
    ...(returnTrip ? [{ trip: returnTrip, fare: returnFare }] : []),
  ].filter((l) => l.trip?.sI?.length);

  const pax = {
    ADULT: Number(searchParams.adults || travellerInfo.filter((t) => t.pt === 'ADULT').length || 1),
    CHILD: Number(searchParams.children || travellerInfo.filter((t) => t.pt === 'CHILD').length || 0),
    INFANT: Number(searchParams.infants || travellerInfo.filter((t) => t.pt === 'INFANT').length || 0),
  };

  /** Sum one fare component across every passenger on every leg. */
  const sum = (key) =>
    legs.reduce((total, l) =>
      total + Object.entries(pax).reduce((n, [type, count]) => {
        const v = l.fare?.fd?.[type]?.fC?.[key];
        return n + (v ? v * count : 0);
      }, 0), 0);

  /** Tax components, printed as "OC195 AT311 UDF207 …" then their total. */
  const taxParts = (() => {
    const totals = {};
    for (const l of legs) {
      for (const [type, count] of Object.entries(pax)) {
        if (!count) continue;
        for (const [code, value] of Object.entries(l.fare?.fd?.[type]?.afC?.TAF || {})) {
          if (code === 'MF' || code === 'MFT') continue; // shown on their own lines
          totals[code] = (totals[code] || 0) + Number(value || 0) * count;
        }
      }
    }
    return totals;
  })();

  const taxTotal = Object.values(taxParts).reduce((n, v) => n + v, 0);
  const mgmtFee = (() => {
    let n = 0;
    for (const l of legs) {
      for (const [type, count] of Object.entries(pax)) {
        n += Number(l.fare?.fd?.[type]?.afC?.TAF?.MF || 0) * count;
      }
    }
    return n;
  })();
  const mgmtGst = (() => {
    let n = 0;
    for (const l of legs) {
      for (const [type, count] of Object.entries(pax)) {
        n += Number(l.fare?.fd?.[type]?.afC?.TAF?.MFT || 0) * count;
      }
    }
    return n;
  })();

  const ssrTotal = (() => {
    const seat = Object.values(addOns?.seats || {}).reduce(
      (n, bySeg) => n + Object.values(bySeg || {}).reduce((m, s) => m + (s.amount || 0), 0), 0);
    const other = ['meals', 'baggage'].reduce((n, kind) =>
      n + Object.values(addOns?.[kind] || {}).reduce((m, bySeg) =>
        m + Object.values(bySeg || {}).reduce((k, byCode) =>
          k + Object.values(byCode || {}).reduce((j, i) => j + (i.amount || 0) * (i.qty || 0), 0), 0), 0), 0);
    return seat + other;
  })();

  const basePrice = sum('BF');

  // TripJack's TF is the authority and is not always exactly BF + TAF: on some
  // fares it comes back a rupee per passenger lower (MAA-DMK in the
  // certification set does this, ₹5 across five travellers). Adding up the
  // component lines printed above would put the ticket out of step with what
  // was actually charged, so the total is taken from TF and the components are
  // display only.
  const grandTotal = sum('TF') + ssrTotal + (hideMarkup ? 0 : markup);

  const segRoute = {};
  for (const l of legs) for (const s of l.trip.sI) segRoute[s.id] = `${s.da.code}-${s.aa.code}`;

  const infoFor = (i) =>
    paxInfos.find(
      (p) =>
        String(p.fN || '').toUpperCase() === String(travellerInfo[i]?.fN || '').toUpperCase() &&
        String(p.lN || '').toUpperCase() === String(travellerInfo[i]?.lN || '').toUpperCase(),
    ) || paxInfos[i] || {};

  /** All distinct PNRs on the booking, for the header block. */
  const allPnrs = (() => {
    const seen = new Map();
    for (const p of paxInfos) {
      for (const [route, code] of Object.entries(p.pnrDetails || {})) {
        if (!seen.has(code)) seen.set(code, route);
      }
    }
    return Array.from(seen.entries()).map(([code, route]) => ({ code, route }));
  })();

  const printedPnrs = selectedPnrs?.length
    ? allPnrs.filter((p) => selectedPnrs.includes(p.code))
    : allPnrs;

  /** "10 kgs Roasted Cashews | 6F" per leg. */
  const prefsFor = (i) => {
    const byRoute = {};
    const push = (segId, text) => {
      const route = segRoute[segId] || segId;
      if (text) (byRoute[route] = byRoute[route] || []).push(text);
    };
    for (const kind of ['baggage', 'meals']) {
      for (const [segId, byCode] of Object.entries(addOns?.[kind]?.[i] || {})) {
        const names = Object.values(byCode || {})
          .filter((x) => x?.qty)
          .map((x) => (x.qty > 1 ? `${x.desc || x.code} × ${x.qty}` : x.desc || x.code));
        if (names.length) push(segId, names.join(', '));
      }
    }
    for (const [segId, seat] of Object.entries(addOns?.seats?.[i] || {})) {
      if (seat?.code) push(segId, seat.code);
    }
    return byRoute;
  };

  return (
    <div className="ticket-doc" id="ticket-doc">
      {/* Agency header */}
      <div className="tk-head">
        <div />
        {agentDetails && (
          <div className="tk-agency">
            <strong>{AGENCY.name}</strong>
            <div>Email: {AGENCY.email}</div>
            <div>Phone: {AGENCY.phone}</div>
            <div>Address: {AGENCY.address}</div>
          </div>
        )}
      </div>

      {/* Booking meta + airline PNRs */}
      <div className="tk-meta">
        <div className="tk-meta-left">
          <div>Booking Time: {bookingStamp(bookingData?.created_at)}</div>
          <div>Booking ID: {bookingData?.order_id || bookingData?.booking_id || '—'}</div>
          <div>
            Booking Status: <strong>{bookingData?.on_hold ? 'On Hold' : 'Confirmed'}</strong>
          </div>
        </div>
        <div className="tk-meta-right">
          {printedPnrs.length ? printedPnrs.map((p) => (
            <div className="tk-pnr-row" key={p.code}>
              <span className="tk-pnr-air">{trip?.sI?.[0]?.fD?.aI?.name}</span>
              <span className="tk-pnr-code">
                {p.code}
                <small>Airline PNR</small>
              </span>
            </div>
          )) : <div className="tk-pnr-row"><span className="tk-pnr-code">Pending<small>Airline PNR</small></span></div>}
        </div>
      </div>

      {/* Flight Detail */}
      <div className="tk-bar">
        Flight Detail
        <span>*Please verify flight timings &amp; terminal info with the airlines</span>
      </div>
      <table className="tk-table">
        <thead>
          <tr>
            <th>Flight</th><th>Fare Type</th><th>Class</th>
            {showRefundable && <th>Type</th>}
            <th>Departing</th><th>Arriving</th><th>Duration</th>
          </tr>
        </thead>
        <tbody>
          {legs.flatMap((l) =>
            l.trip.sI.flatMap((s, i) => {
              const rows = [(
                <tr key={s.id}>
                  <td><strong>{s.fD.aI.code} - {s.fD.fN}</strong><div>{s.fD.aI.name}</div></td>
                  <td>{l.fare?.fareIdentifier || 'NA'}</td>
                  <td>{(l.fare?.fd?.ADULT?.cc || 'ECONOMY').charAt(0) + (l.fare?.fd?.ADULT?.cc || 'ECONOMY').slice(1).toLowerCase()}</td>
                  {showRefundable && <td>{l.fare?.fd?.ADULT?.rT === 1 ? 'Refundable' : 'Non-Refundable'}</td>}
                  <td>
                    {printStamp(s.dt)}
                    <div>{s.da.city}{s.da.terminal ? `, ${s.da.terminal}` : ''}</div>
                    <div>{s.da.name}</div>
                  </td>
                  <td>
                    {printStamp(s.at)}
                    <div>{s.aa.city}{s.aa.terminal ? `, ${s.aa.terminal}` : ''}</div>
                    <div>{s.aa.name}</div>
                  </td>
                  <td>{formatDuration(s.duration || 0)}</td>
                </tr>
              )];
              if (i < l.trip.sI.length - 1 && s.cT) {
                rows.push(
                  <tr className="tk-layover" key={`${s.id}-lay`}>
                    <td colSpan={showRefundable ? 7 : 6}>Layover Time - {formatDuration(s.cT)}</td>
                  </tr>,
                );
              }
              return rows;
            }),
          )}
        </tbody>
      </table>

      {/* Passenger Details */}
      <div className="tk-bar">Passenger Details</div>
      <table className="tk-table">
        <thead>
          <tr>
            <th>Sr.</th>
            <th>Name &amp; FF</th>
            <th>Sector</th>
            <th>PNR &amp; Ticket No.</th>
            <th>Baggage<small>Check-in | Cabin</small></th>
            <th>Meal, Seat &amp; Other Preference</th>
            {passportInfo && <th>Document Id</th>}
          </tr>
        </thead>
        <tbody>
          {travellerInfo.map((t, i) => {
            const info = infoFor(i);
            const routes = Object.keys(info.pnrDetails || {});
            const prefs = prefsFor(i);
            const legFare = legs[0]?.fare?.fd?.[t.pt];
            return (
              <tr key={i}>
                <td>{i + 1}</td>
                <td>
                  {t.ti} {t.fN} {t.lN} ( {PAX_INITIAL[t.pt] || 'A'} )
                  {t.dob && <div>{shortDob(t.dob)},</div>}
                  {t.ffNumber && <div>FF: {t.ffNumber}</div>}
                </td>
                <td>{(routes.length ? routes : Object.values(segRoute)).map((r) => <div key={r}>{r}</div>)}</td>
                <td>
                  {routes.length
                    ? routes.map((r) => (
                        <div key={r}>
                          {info.pnrDetails[r]}
                          {info.ticketNumberDetails?.[r] ? ` / ${info.ticketNumberDetails[r]}` : ''}
                        </div>
                      ))
                    : 'Pending'}
                </td>
                <td>
                  {(routes.length ? routes : Object.values(segRoute)).map((r) => (
                    <div key={r}>{legFare?.bI?.iB || 'NA'} | {legFare?.bI?.cB || 'NA'}</div>
                  ))}
                </td>
                <td>
                  {Object.keys(prefs).length
                    ? Object.entries(prefs).map(([r, items]) => <div key={r}>{items.join(' | ')}</div>)
                    : 'NA'}
                </td>
                {passportInfo && <td>{t.pNum || ''}</td>}
              </tr>
            );
          })}
        </tbody>
      </table>

      {/* Fare Details */}
      {showPrice && (
        <>
          <div className="tk-bar">Fare Details</div>
          <table className="tk-table tk-fare">
            <tbody>
              <tr><td>Base Price</td><td>{inr(basePrice)}</td></tr>
              <tr>
                <td>Airline Taxes and Fees</td>
                <td>
                  {Object.keys(taxParts).length ? (
                    <span className="tk-taxcodes">
                      ({Object.entries(taxParts).map(([c, v]) => `${c}${Math.round(v)}`).join(' ')}){' '}
                    </span>
                  ) : null}
                  {inr(taxTotal)}
                </td>
              </tr>
              <tr><td>Management Fee</td><td>{inr(mgmtFee)}</td></tr>
              <tr><td>Meal/ Seat/Baggage/ Misc Charges</td><td>{inr(ssrTotal)}</td></tr>
              {!hideMarkup && markup > 0 && (
                <tr><td>Service Charge</td><td>{inr(markup)}</td></tr>
              )}
              {gst && <tr><td>Management Fee GST</td><td>{inr(mgmtGst)}</td></tr>}
              <tr className="tk-total"><td>Total Price</td><td>{inr(grandTotal)}</td></tr>
            </tbody>
          </table>
        </>
      )}

      {showContact && (
        <>
          <div className="tk-bar">Contact Details</div>
          <div className="tk-contact">
            <div>Email: {bookingData?.contact_email || bookingData?.contact?.email || '—'}</div>
            <div>Mobile: {bookingData?.contact_phone || bookingData?.contact?.phone || '—'}</div>
          </div>
        </>
      )}

      {gst && gstInfo && (
        <>
          <div className="tk-bar">GST Details</div>
          <div className="tk-contact">
            <div>{gstInfo.companyName} — {gstInfo.gstNumber}</div>
            {gstInfo.address && <div>{gstInfo.address}</div>}
          </div>
        </>
      )}

      {agentNotes && agentNote && (
        <>
          <div className="tk-bar">Agent Notes</div>
          <div className="tk-contact">{agentNote}</div>
        </>
      )}

      {/* Important Information */}
      <div className="tk-bar">Important Information</div>
      <ol className="tk-info">
        {IMPORTANT.map((line) => <li key={line}>{line}</li>)}
        {carrierLink && (
          <li>
            Please read the Conditions of Carriage as directed by {trip?.sI?.[0]?.fD?.aI?.name}:{' '}
            <a href={carrierLink}>{carrierLink}</a>
          </li>
        )}
      </ol>

      {/* Dangerous goods */}
      <div className="tk-danger">
        <div>
          <strong className="tk-x">✕</strong>
          <span className="tk-danger-title">
            The items are Dangerous Goods and are not permitted to be carried as Hand/Check-in Baggage
          </span>
          <p>{DANGEROUS.join(' · ')}</p>
        </div>
        <div>
          <strong className="tk-tick">✓</strong>
          <span className="tk-danger-title">Items allowed only in Hand Baggage</span>
          <p>{HAND_ONLY.join(' · ')}</p>
        </div>
      </div>
    </div>
  );
}
