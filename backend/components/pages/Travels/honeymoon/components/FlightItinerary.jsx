import { FaPlane, FaClock, FaSuitcase, FaCheckCircle, FaTimesCircle } from 'react-icons/fa';

export default function FlightItinerary({ trip, returnTrip, fare, returnFare, searchParams, onContinue }) {
  const formatTime = (dateStr) => {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-US', { weekday: 'short', day: 'numeric', month: 'short', year: 'numeric' });
  };

  const formatDuration = (minutes) => {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return `${h}h ${m}m`;
  };

  const renderFlightSegment = (segment, isLast) => {
    const airline = segment.fD.aI;
    const duration = segment.duration;
    
    return (
      <div key={segment.id} className="flight-segment-detail">
        <div className="d-flex align-items-start gap-3">
          <img
            src={`https://logos.skyscnr.com/images/airlines/favicon/${airline.code}.png`}
            alt={airline.name}
            className="airline-logo-md"
            onError={(e) => {
              e.target.onerror = null;
              e.target.src = `https://airlines.airhex.com/airlines-logo/${airline.code.toLowerCase()}.png`;
            }}
          />
          <div className="flex-grow-1">
            <div className="d-flex justify-content-between align-items-start mb-2">
              <div>
                <div className="airline-name-lg">{airline.name}</div>
                <div className="flight-number-lg">{segment.fD.fN}</div>
              </div>
              <div className="text-end">
                <div className="duration-badge">
                  <FaClock size={12} className="me-1" />
                  {formatDuration(duration)}
                </div>
              </div>
            </div>
            
            <div className="flight-route-detail">
              <div className="route-point">
                <div className="route-time">{formatTime(segment.dt)}</div>
                <div className="route-location">
                  <strong>{segment.da.code}</strong> - {segment.da.city}
                </div>
                <div className="route-date">{formatDate(segment.dt)}</div>
                {segment.da.terminal && <div className="route-terminal">Terminal {segment.da.terminal}</div>}
              </div>
              
              <div className="route-connector">
                <div className="route-line"></div>
                <FaPlane className="route-icon" />
              </div>
              
              <div className="route-point">
                <div className="route-time">{formatTime(segment.at)}</div>
                <div className="route-location">
                  <strong>{segment.aa.code}</strong> - {segment.aa.city}
                </div>
                <div className="route-date">{formatDate(segment.at)}</div>
                {segment.aa.terminal && <div className="route-terminal">Terminal {segment.aa.terminal}</div>}
              </div>
            </div>
            
            {segment.fD.eT && (
              <div className="aircraft-info mt-2">
                <small>Aircraft: {segment.fD.eT}</small>
              </div>
            )}
          </div>
        </div>
        
        {!isLast && (
          <div className="layover-notice">
            <FaClock size={12} className="me-1" />
            Layover at {segment.aa.city}
          </div>
        )}
      </div>
    );
  };

  const renderFareSummary = (tripFare, isReturn = false) => {
    const adults = searchParams.adults || 1;
    const children = searchParams.children || 0;
    const infants = searchParams.infants || 0;
    
    const adultFare = tripFare.fd.ADULT;
    const baseFare = adultFare.fC.BF * adults;
    const taxes = adultFare.fC.TAF * adults;
    const total = adultFare.fC.TF * adults;
    
    return (
      <div className="fare-summary-section">
        <h6 className="fare-summary-title">{isReturn ? 'Return Flight' : 'Onward Flight'} Fare</h6>
        <div className="fare-row">
          <span>Base Fare × {adults} Adult{adults > 1 ? 's' : ''}</span>
          <span>₹{Number(baseFare).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
        </div>
        <div className="fare-row">
          <span>Taxes & Fees</span>
          <span>₹{Number(taxes).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
        </div>
        <div className="fare-row fare-total">
          <span>Subtotal</span>
          <span>₹{Number(total).toLocaleString('en-IN', { minimumFractionDigits: 2 })}</span>
        </div>
        
        <div className="fare-details-grid mt-3">
          <div className="fare-detail-item">
            <FaSuitcase className="me-1" />
            <small>Baggage: {adultFare.bI?.iB || '15 Kg'}</small>
          </div>
          <div className="fare-detail-item">
            <FaSuitcase className="me-1" />
            <small>Cabin: {adultFare.bI?.cB || '7 Kg'}</small>
          </div>
          <div className="fare-detail-item">
            {adultFare.rT === 1 ? (
              <><FaCheckCircle className="text-success me-1" /><small>Refundable</small></>
            ) : (
              <><FaTimesCircle className="text-danger me-1" /><small>Non-Refundable</small></>
            )}
          </div>
          <div className="fare-detail-item">
            <small className="fare-type-badge">{tripFare.fareIdentifier}</small>
          </div>
        </div>
      </div>
    );
  };

  const calculateTotalAmount = () => {
    const adults = searchParams.adults || 1;
    const onwardTotal = fare.fd.ADULT.fC.TF * adults;
    const returnTotal = returnFare ? returnFare.fd.ADULT.fC.TF * adults : 0;
    return onwardTotal + returnTotal;
  };

  return (
    <div className="row">
      <div className="col-lg-8">
        <div className="booking-card">
          <h4 className="booking-card-title">Flight Itinerary</h4>
          
          <div className="flight-itinerary-section">
            <div className="section-header">
              <h5>Onward Journey</h5>
              <span className="journey-route">{searchParams.from} → {searchParams.to}</span>
            </div>
            {trip.sI.map((segment, idx) => renderFlightSegment(segment, idx === trip.sI.length - 1))}
          </div>
          
          {returnTrip && (
            <div className="flight-itinerary-section mt-4">
              <div className="section-header">
                <h5>Return Journey</h5>
                <span className="journey-route">{searchParams.to} → {searchParams.from}</span>
              </div>
              {returnTrip.sI.map((segment, idx) => renderFlightSegment(segment, idx === returnTrip.sI.length - 1))}
            </div>
          )}
        </div>
      </div>
      
      <div className="col-lg-4">
        <div className="booking-card sticky-summary">
          <h5 className="booking-card-title">Fare Summary</h5>
          
          {renderFareSummary(fare, false)}
          {returnFare && renderFareSummary(returnFare, true)}
          
          <div className="fare-grand-total mt-4 pt-3">
            <div className="d-flex justify-content-between align-items-center">
              <span className="grand-total-label">Total Amount</span>
              <span className="grand-total-amount">
                ₹{Number(calculateTotalAmount()).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
              </span>
            </div>
          </div>
          
          <button className="btn btn-primary w-100 mt-3 btn-lg" onClick={onContinue}>
            Continue to Passenger Details
          </button>
        </div>
      </div>
    </div>
  );
}
