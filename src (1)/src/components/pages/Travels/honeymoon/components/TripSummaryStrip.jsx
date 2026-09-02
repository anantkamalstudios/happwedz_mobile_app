import { Plane, Clock } from 'lucide-react';
import { airlineLogo } from '../../../../../utils/airlineLogo';

const WEEKDAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

const clock12 = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  const h = d.getHours();
  const suffix = h >= 12 ? 'PM' : 'AM';
  const hour = h % 12 || 12;
  return `${hour}:${String(d.getMinutes()).padStart(2, '0')} ${suffix}`;
};

/** "Fri, 28 Aug'26" */
const shortDate = (value) => {
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) return '';
  return `${WEEKDAYS[d.getDay()]}, ${d.getDate()} ${MONTHS[d.getMonth()]}'${String(d.getFullYear()).slice(2)}`;
};

const durationText = (mins) => `${Math.floor(mins / 60)}h ${String(mins % 60).padStart(2, '0')}m`;

/**
 * Compact itinerary reminder carried above the passenger form, so the traveller
 * can see what they are filling details in for without scrolling back a step.
 */
export default function TripSummaryStrip({ trip, fare, returnTrip, tripType = 'oneway' }) {
  if (!trip?.sI?.length) return null;

  const segs = trip.sI;
  const first = segs[0];
  const last = segs[segs.length - 1];
  const airline = first.fD.aI;
  const stops = segs.length - 1;
  // Airborne time plus every connection — the same total the results card shows.
  const total = segs.reduce((n, s) => n + (s.duration || 0) + (s.cT || 0), 0);
  const flightNumbers = segs.map((s) => `${s.fD.aI.code} - ${s.fD.fN}`).join(', ');

  return (
    <div className="trip-strip">
      <img
        src={airlineLogo(airline.code)}
        alt={airline.name}
        className="trip-strip-logo"
        onError={(e) => { e.target.style.visibility = 'hidden'; }}
      />
      <div className="trip-strip-main">
        <div className="trip-strip-route">
          <strong>
            {first.da.code}, {first.da.city} → {last.aa.code}, {last.aa.city}
          </strong>
          <span className="trip-strip-cabin">{fare?.fd?.ADULT?.cc || 'ECONOMY'}</span>
        </div>
        <div className="trip-strip-meta">
          <span><Plane size={12} /> {airline.name}, {flightNumbers}</span>
          <span><Clock size={12} /> {clock12(first.dt)} → {clock12(last.at)}</span>
          <span>
            {shortDate(first.dt)} | {stops === 0 ? 'Non-stop' : `${stops} stop${stops > 1 ? 's' : ''}`} |{' '}
            {durationText(total)}
          </span>
        </div>
      </div>
      <span className="trip-strip-type">
        {returnTrip || tripType === 'round' ? 'Round Trip' : 'One Way'}
      </span>
    </div>
  );
}
