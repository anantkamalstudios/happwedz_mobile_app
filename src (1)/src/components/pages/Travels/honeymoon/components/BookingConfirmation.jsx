import { useState, useRef, useEffect } from 'react';
import {
  FaCheckCircle, FaPrint, FaInfoCircle, FaFilePdf, FaEnvelope,
  FaCommentAlt, FaWhatsapp, FaListUl, FaChevronDown,
} from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';
import FlightSegments from './FlightSegments';
import FareSummary from './FareSummary';
import { shortDob } from './flightFormat';
import { releaseHeldBooking, emailTicket, getBookingDetails } from '../../../../../services/api/flightApi';
import { adaptBookingDetails, isAwaitingPnr, hasPnrs } from './bookingDetailsAdapter';
import { addOnBreakdown } from './FlightAddOn';
import TicketDocument from './TicketDocument';
import PrintTicketModal from './PrintTicketModal';

const PAX_INITIAL = { ADULT: 'A', CHILD: 'C', INFANT: 'I' };

/** "Aug 28, Fri, 08:15" for the print dialog's flight-details expander. */
const stampShort = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  const M = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const W = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  return `${M[d.getMonth()]} ${d.getDate()}, ${W[d.getDay()]}, ${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
};

/** "Aug 27, 2026 5:11 PM" — the portal's created-on stamp. */
const createdStamp = (value) => {
  const d = value ? new Date(value) : new Date();
  if (Number.isNaN(d.getTime())) return '';
  const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const h = d.getHours();
  return `${MONTHS[d.getMonth()]} ${d.getDate()}, ${d.getFullYear()} ${h % 12 || 12}:${String(d.getMinutes()).padStart(2, '0')} ${h >= 12 ? 'PM' : 'AM'}`;
};

/**
 * Static guidance the portal prints under every booking. The final bullet is
 * the operating carrier's conditions of carriage, which only renders when we
 * hold a link for that airline rather than guessing a URL.
 */
const CARRIER_TERMS = {
  QP: 'https://www.akasaair.com/quick-links/conditions-of-carriage',
  '6E': 'https://www.goindigo.in/information/conditions-of-carriage.html',
  AI: 'https://www.airindia.com/in/en/legal/conditions-of-carriage.html',
  SG: 'https://www.spicejet.com/ConditionsOfCarriage.aspx',
  UK: 'https://www.airvistara.com/in/en/legal/conditions-of-carriage',
};

const IMPORTANT_INFO = [
  'You should carry a print-out of your booking and present for check-in.',
  'Date & Time is calculated based on the local time of city/destination.',
  'Use the Reference Number for all Correspondence with us.',
  'Use the Airline PNR for all Correspondence directly with the Airline',
  'For departure terminal please check with airline first.',
  'Please CheckIn atleast 2 hours prior to the departure for domestic flight and 3 hours prior to the departure of international flight.',
  'For rescheduling/cancellation within 4 hours of departure time contact the airline directly',
];

export default function BookingConfirmation({
  bookingData,
  trip,
  returnTrip,
  travellerInfo = [],
  fare,
  returnFare,
  searchParams,
  addOns,
  markup = 0,
  gstInfo,
  agentNote,
  onProceedToPay,
}) {
  const navigate = useNavigate();
  const [releasing, setReleasing] = useState(false);
  const [released, setReleased] = useState(false);
  const [actionError, setActionError] = useState('');
  const [menuOpen, setMenuOpen] = useState(false);
  const [printOpen, setPrintOpen] = useState(false);
  // Defaults match the dialog's own, so "Download as PDF" can skip it entirely.
  const [printOpts, setPrintOpts] = useState({
    showPrice: true,
    hideMarkup: false,
    agentDetails: true,
    gst: true,
    passportInfo: true,
    agentNotes: false,
    showRefundable: true,
    showContact: true,
  });
  const [emailing, setEmailing] = useState(false);
  // Travellers refreshed by the poll below; falls back to what the booking call
  // returned until the first successful re-fetch.
  const [livePax, setLivePax] = useState(null);
  const [pnrWait, setPnrWait] = useState('idle'); // idle | waiting | gave-up
  const menuRef = useRef(null);

  useEffect(() => {
    if (!menuOpen) return undefined;
    const close = (e) => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setMenuOpen(false);
    };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, [menuOpen]);

  const onHold = bookingData.on_hold === true;
  const bookingRef =
    bookingData.order_id || bookingData.booking_id || bookingData.bookingId || '—';

  // Per-traveller PNRs come back keyed by route ("BOM-BLR": "Y8CGHW"), which is
  // the same label the seat and meal columns use.
  //
  // `travellers` is what the book and hold endpoints now send. The two raw
  // shapes below are the same data as persisted: the paid path stores the
  // booking-details response directly, the hold path nests it under `details`.
  const paxInfos =
    livePax ||
    bookingData?.travellers ||
    bookingData?.raw_order?.itemInfos?.AIR?.travellerInfos ||
    bookingData?.raw_order?.details?.itemInfos?.AIR?.travellerInfos ||
    [];
  /**
   * A held or freshly booked itinerary sits at order.status PENDING until the
   * airline issues a PNR — the portal waits on this same screen for it. The BFF
   * passes TripJack's booking-details straight through, so the browser can read
   * pnrDetails directly without waiting on any server-side mapping.
   *
   * The shared rate limiter allows 30 requests a minute, so this stays well
   * inside it at one call per 9s and stops the moment a PNR lands.
   */
  useEffect(() => {
    if (!bookingRef || bookingRef === '—') return undefined;
    if (hasPnrs(paxInfos)) return undefined;

    let cancelled = false;
    let timer = null;
    const startedAt = Date.now();
    const INTERVAL = 9000;
    const GIVE_UP_AFTER = 3 * 60 * 1000;

    setPnrWait('waiting');

    const tick = async () => {
      if (cancelled) return;
      try {
        const details = await getBookingDetails(bookingRef);
        if (cancelled) return;
        const adapted = adaptBookingDetails(details);
        if (adapted?.paxInfos?.length) setLivePax(adapted.paxInfos);
        if (!isAwaitingPnr(details)) {
          setPnrWait('idle');
          return; // PNR issued — stop
        }
      } catch {
        // A blip must not end the wait; the elapsed check below still bounds it.
      }
      if (cancelled) return;
      if (Date.now() - startedAt > GIVE_UP_AFTER) {
        setPnrWait('gave-up');
        return;
      }
      timer = setTimeout(tick, INTERVAL);
    };

    timer = setTimeout(tick, INTERVAL);
    return () => {
      cancelled = true;
      if (timer) clearTimeout(timer);
    };
    // Deliberately keyed on the booking alone. The stop condition reads the
    // freshly fetched payload, not the captured paxInfos, so re-running on each
    // update would only restart the give-up clock.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bookingRef]);

  const infoFor = (i) =>
    paxInfos.find(
      (p) =>
        String(p.fN || '').toUpperCase() === String(travellerInfo[i]?.fN || '').toUpperCase() &&
        String(p.lN || '').toUpperCase() === String(travellerInfo[i]?.lN || '').toUpperCase(),
    ) || paxInfos[i] || {};

  const segRoute = {};
  for (const leg of [trip, returnTrip]) {
    for (const s of leg?.sI || []) segRoute[s.id] = `${s.da.code}-${s.aa.code}`;
  }

  /** Seat / meal / baggage this traveller picked, grouped by leg. */
  const prefsFor = (i) => {
    const byRoute = {};
    const push = (segId, text) => {
      const route = segRoute[segId] || segId;
      if (!text) return;
      (byRoute[route] = byRoute[route] || []).push(text);
    };
    for (const [segId, seat] of Object.entries(addOns?.seats?.[i] || {})) {
      if (seat?.code) push(segId, `Seat - ${seat.code}`);
    }
    for (const kind of ['meals', 'baggage']) {
      for (const [segId, byCode] of Object.entries(addOns?.[kind]?.[i] || {})) {
        const names = Object.values(byCode || {})
          .filter((x) => x?.qty)
          .map((x) => (x.qty > 1 ? `${x.desc || x.code} × ${x.qty}` : x.desc || x.code));
        if (names.length) push(segId, names.join(', '));
      }
    }
    return Object.entries(byRoute);
  };

  const handleUnhold = async () => {
    setActionError('');
    setReleasing(true);
    try {
      await releaseHeldBooking(bookingRef);
      setReleased(true);
    } catch (e) {
      setActionError(e?.response?.data?.message || 'Could not release this hold. Please contact support.');
    } finally {
      setReleasing(false);
    }
  };

  /** Distinct airline PNRs, for the print dialog's picker. */
  const pnrList = (() => {
    const seen = new Map();
    for (const p of paxInfos) {
      for (const [route, code] of Object.entries(p.pnrDetails || {})) {
        if (!seen.has(code)) seen.set(code, { code, route });
      }
    }
    return Array.from(seen.values());
  })();

  const printSegments = [trip, returnTrip].filter(Boolean).flatMap((leg) =>
    (leg.sI || []).map((s) => ({
      id: s.id,
      airline: s.fD.aI.name,
      airlineCode: s.fD.aI.code,
      flightNo: s.fD.fN,
      from: s.da.code,
      to: s.aa.code,
      depart: stampShort(s.dt),
      arrive: stampShort(s.at),
    })),
  );

  /**
   * Printing is the browser's own dialog against the print-only ticket, which
   * is also how "Download as PDF" works — the dialog's Save as PDF target. The
   * portal does the same thing behind its print route.
   */
  const runPrint = (opts) => {
    if (opts) setPrintOpts(opts);
    setPrintOpen(false);
    setMenuOpen(false);
    // Let the ticket re-render with the new options before the dialog opens.
    setTimeout(() => window.print(), 60);
  };

  const handleEmailTicket = async () => {
    setActionError('');
    setEmailing(true);
    try {
      const res = await emailTicket(bookingRef);
      setActionError(res?.status ? '' : res?.message || 'Could not send the ticket.');
      if (res?.status) setMenuOpen(false);
    } catch (e) {
      setActionError(e?.response?.data?.message || 'Could not send the ticket. Please try again.');
    } finally {
      setEmailing(false);
    }
  };

  const carrier = trip?.sI?.[0]?.fD?.aI;
  const carrierLink = CARRIER_TERMS[carrier?.code];

  return (
    <div className="confirm-page">
      {/* Status band — the portal's .abt-section, full width above everything. */}
      <div className="confirm-topbar">
        <div className="confirm-topbar-left">
          <FaCheckCircle className={`confirm-status-icon${onHold ? ' is-hold' : ''}`} size={38} />
          <div>
            <div className="confirm-status">
              Booking <span>{released ? 'Released' : onHold ? 'On Hold' : 'Confirmed'}</span>
            </div>
            <div className="confirm-created">{createdStamp(bookingData.created_at)}</div>
            <p className="confirm-ref">
              <span className="confirm-ref-label">Booking ID</span> {bookingRef}
              {onHold && !released && (
                <span className="confirm-hold-note">
                  <FaInfoCircle size={10} /> Price might change as per airline rules
                </span>
              )}
            </p>
            {onHold && !released && !bookingData.deadline && (
              <p className="confirm-warning">
                We didn&apos;t receive any hold time limit. Kindly check with operations team.
              </p>
            )}
            {onHold && !released && bookingData.deadline && (
              <p className="confirm-deadline">Pay before {createdStamp(bookingData.deadline)} to confirm.</p>
            )}
            {actionError && <p className="confirm-warning">{actionError}</p>}
          </div>
        </div>

        <div className="confirm-topbar-actions">
          {onHold && !released && (
            <>
              <button type="button" className="confirm-ghost-btn" onClick={handleUnhold} disabled={releasing}>
                {releasing ? 'Releasing…' : 'UnHold'}
              </button>
              <button
                type="button"
                className="itin-btn itin-btn-next"
                onClick={onProceedToPay}
                disabled={releasing || !onProceedToPay}
              >
                » PROCEED TO PAY
              </button>
            </>
          )}

          <div className="confirm-more" ref={menuRef}>
            <button
              type="button"
              className="confirm-ghost-btn"
              onClick={() => setMenuOpen((v) => !v)}
              aria-expanded={menuOpen}
              aria-haspopup="menu"
            >
              More Options <FaChevronDown size={10} />
            </button>

            {menuOpen && (
              <div className="confirm-menu" role="menu">
                <button type="button" role="menuitem" onClick={() => runPrint(null)}>
                  <FaFilePdf size={12} /> Download as PDF
                </button>
                <button type="button" role="menuitem" onClick={() => { setMenuOpen(false); setPrintOpen(true); }}>
                  <FaPrint size={12} /> Print Tickets
                </button>
                <button type="button" role="menuitem" onClick={handleEmailTicket} disabled={emailing}>
                  <FaEnvelope size={12} /> {emailing ? 'Sending…' : 'Email Ticket'}
                </button>
                <button type="button" role="menuitem" disabled title="Needs an SMS provider (MSG91 / Twilio) with DLT-registered templates">
                  <FaCommentAlt size={12} /> SMS Ticket
                </button>
                <button type="button" role="menuitem" disabled title="Needs the WhatsApp Business API with approved templates">
                  <FaWhatsapp size={12} /> WhatsApp Me
                </button>
                <button
                  type="button"
                  role="menuitem"
                  onClick={() => navigate('/user-dashboard/booking/travel/flights')}
                >
                  <FaListUl size={12} /> Go to My Bookings
                </button>
              </div>
            )}
          </div>
        </div>
      </div>

      <div className="confirm-body">
        <div className="booking-card">
          <FlightSegments trip={trip} fare={fare} variant="confirmation" />
          {returnTrip && (
            <FlightSegments trip={returnTrip} fare={returnFare} variant="confirmation" className="mt-3" />
          )}
        </div>

        <div className="booking-card">
          <h4 className="rv-heading">
            Passenger Details <span>({travellerInfo.length})</span>
          </h4>

          <div className="rv-table confirm-table">
            <div className="rv-thead">
              <div>Sr.</div>
              <div>Print</div>
              <div>Name, DOB &amp; Passport &amp; FF</div>
              <div>PNR, Ticket No. &amp; Status</div>
              <div>Meal, Baggage, Seat &amp; Other Preference</div>
            </div>

            {travellerInfo.map((t, i) => {
              const info = infoFor(i);
              const pnrs = Object.entries(info.pnrDetails || {});
              const tickets = info.ticketNumberDetails || {};
              const prefs = prefsFor(i);
              return (
                <div className="rv-trow" key={i}>
                  <div className="rv-td-sr">{i + 1}</div>
                  <div className="rv-td-print">
                    <button type="button" onClick={() => window.print()} aria-label="Print this ticket">
                      <FaPrint size={12} />
                    </button>
                  </div>
                  <div className="rv-td-name">
                    <span className="rv-paxname">
                      {t.ti} {t.fN} {t.lN} ({PAX_INITIAL[t.pt] || 'A'})
                    </span>
                    {t.dob ? <span className="rv-paxdob">{shortDob(t.dob)},</span> : null}
                    {t.pNum ? <span className="rv-paxdob">{t.pNum}</span> : null}
                  </div>
                  <div className="rv-td-pnr">
                    {pnrs.length ? (
                      pnrs.map(([route, code]) => (
                        <div key={route}>
                          <b>{route}</b>:<span className="confirm-pnr"> {code} </span>
                          {tickets[route] ? <span className="confirm-ticket">{tickets[route]}</span> : null}
                        </div>
                      ))
                    ) : pnrWait === 'gave-up' ? (
                      <span className="rv-none">
                        Not issued yet — contact support with the booking ID.
                      </span>
                    ) : (
                      <span className="pnr-waiting">
                        <span className="pnr-spinner" aria-hidden="true" />
                        Awaiting airline PNR…
                      </span>
                    )}
                  </div>
                  <div className="rv-td-ssr">
                    {prefs.length ? (
                      prefs.map(([route, items]) => (
                        <div key={route}>
                          <b>{route}</b>: <span className="rv-muted">{items.join(', ')},</span>
                        </div>
                      ))
                    ) : (
                      'NA'
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* The portal drops the fare summary into the main column here rather
            than the right rail it uses on the earlier steps. */}
        {fare && (
          <div className="confirm-fare">
            <FareSummary
              fare={fare}
              returnFare={returnFare}
              searchParams={searchParams}
              markup={markup}
              extras={Object.entries(addOnBreakdown(addOns)).map(([label, amount]) => ({ label, amount }))}
            />
          </div>
        )}

        <div className="booking-card">
          <h5 className="confirm-info-title">IMPORTANT INFORMATION</h5>
          <ul className="confirm-info-list">
            {IMPORTANT_INFO.map((line) => <li key={line}>{line}</li>)}
            {carrierLink && (
              <li>
                Please read the Conditions of Carriage as directed by {carrier.name}:{' '}
                <a href={carrierLink} target="_blank" rel="noreferrer">{carrierLink}</a>
              </li>
            )}
          </ul>
        </div>

        {printOpen && (
          <PrintTicketModal
            pnrs={pnrList}
            segments={printSegments}
            onClose={() => setPrintOpen(false)}
            onSubmit={runPrint}
          />
        )}

        {/* Hidden on screen; @media print swaps the page for this. */}
        <TicketDocument
          bookingData={bookingData}
          trip={trip}
          returnTrip={returnTrip}
          fare={fare}
          returnFare={returnFare}
          travellerInfo={travellerInfo}
          paxInfos={paxInfos}
          addOns={addOns}
          searchParams={searchParams}
          markup={markup}
          gstInfo={gstInfo}
          agentNote={agentNote}
          carrierLink={carrierLink}
          opts={printOpts}
        />

        <div className="confirm-footer">
          <button type="button" className="confirm-ghost-btn" onClick={() => navigate('/user-dashboard/booking/travel/flights')}>
            Go to My Bookings
          </button>
          <button type="button" className="confirm-ghost-btn" onClick={() => navigate('/honeymoon')}>
            Book Another Flight
          </button>
        </div>
      </div>
    </div>
  );
}
