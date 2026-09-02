import { FaPlane, FaSuitcase } from 'react-icons/fa';
import { formatDuration, stamp, longDate, journeyMinutes, baggageLine } from './flightFormat';
import { airlineLogo } from '../../../../../utils/airlineLogo';

/**
 * The journey strip and its segment rows, exactly as the portal draws them.
 *
 * Both the itinerary step and the review step render this identically — their
 * markup in the reference HTML is the same `.apt-firstpr` header followed by
 * col-sm-3 / col-sm-7 / col-sm-2 rows — so it lives here rather than being
 * written twice and drifting apart.
 */

export function FlightSegment({ segment, isLast, fare, variant }) {
  const airline = segment.fD.aI;
  const cabin = fare?.fd?.ADULT?.cc;
  const refundable = fare?.fd?.ADULT?.rT === 1 ? 'Refundable' : 'Non-Refundable';

  return (
    <div className="itin-seg">
      <div className="itin-seg-row">
        <div className="itin-seg-airline">
          <img
            src={airlineLogo(airline.code)}
            alt={airline.name}
            onError={(e) => { e.target.style.visibility = 'hidden'; }}
          />
          <div>
            <div className="itin-airline-name">{airline.name}</div>
            <div className="itin-flightno">
              {airline.code}-{segment.fD.fN}
              {segment.fD.eT && (
                <span className="itin-aircraft"><FaPlane size={9} />-{segment.fD.eT}</span>
              )}
            </div>
          </div>
        </div>

        <div className="itin-seg-points">
          <div className="itin-seg-point">
            <div className="itin-stamp">{stamp(segment.dt)}</div>
            <div>{segment.da.city}, {segment.da.country}</div>
            <div className="itin-airport" title={segment.da.name}>{segment.da.name}</div>
            {segment.da.terminal && <div className="itin-airport">{segment.da.terminal}</div>}
          </div>

          <div className="itin-seg-mid">
            <span className="itin-nonstop">Non-Stop</span>
            <span className="itin-arrow" />
          </div>

          <div className="itin-seg-point">
            <div className="itin-stamp">{stamp(segment.at)}</div>
            <div>{segment.aa.city}, {segment.aa.country}</div>
            <div className="itin-airport" title={segment.aa.name}>{segment.aa.name}</div>
            {segment.aa.terminal && <div className="itin-airport">{segment.aa.terminal}</div>}
          </div>
        </div>

        <div className="itin-seg-dur">
          <div className="itin-dur">{formatDuration(segment.duration)}</div>
          <div className="itin-cabin">
            {cabin ? `${cabin.charAt(0)}${cabin.slice(1).toLowerCase()},` : ''}{refundable}
          </div>
        </div>
      </div>

      {fare?.fareIdentifier && (
        <div className="itin-fare-badge">{fare.fareIdentifier}</div>
      )}
      {baggageLine(fare) && (
        variant === 'confirmation' ? (
          <div className="itin-bagblock">
            <p>Baggage Information</p>
            <span>
              Adult - <span className="itin-bag-muted">
                Check-in : {fare?.fd?.ADULT?.bI?.iB || 'NA'}, Cabin : {fare?.fd?.ADULT?.bI?.cB || 'NA'}
              </span>
            </span>
          </div>
        ) : (
          <div className="itin-bagline">
            <FaSuitcase size={12} /> : {baggageLine(fare)}
          </div>
        )
      )}

      {!isLast && (
        <div className="itin-layover">
          <span>
            Require to change Plane
            {segment.cT ? <b>Layover Time - {formatDuration(segment.cT)}</b> : null}
          </span>
        </div>
      )}
    </div>
  );
}

/** One leg: the grey route strip followed by every segment on it. */
export default function FlightSegments({ trip, fare, className = '', variant }) {
  if (!trip?.sI?.length) return null;
  const segs = trip.sI;

  return (
    <div className={`flight-itinerary-section ${className}`.trim()}>
      <div className="itin-strip">
        <span>
          <strong>{segs[0].da.city}</strong> ⟶ <strong>{segs[segs.length - 1].aa.city}</strong>
          <small> on {longDate(segs[0].dt)}</small>
        </span>
        {variant !== 'confirmation' && (
          <span className="itin-strip-dur">🕐 {formatDuration(journeyMinutes(trip))}</span>
        )}
      </div>
      {segs.map((segment, i) => (
        <FlightSegment
          key={segment.id ?? i}
          segment={segment}
          isLast={i === segs.length - 1}
          fare={fare}
          variant={variant}
        />
      ))}
    </div>
  );
}
