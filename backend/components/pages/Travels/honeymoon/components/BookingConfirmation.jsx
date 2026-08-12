import { FaCheckCircle, FaPlane, FaDownload, FaList, FaClock } from 'react-icons/fa';
import { useNavigate } from 'react-router-dom';

export default function BookingConfirmation({ bookingData, trip, returnTrip, travellerInfo }) {
  const navigate = useNavigate();
  const onHold = bookingData.on_hold === true;

  const formatTime = (dateStr) => {
    return new Date(dateStr).toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', hour12: false });
  };

  const formatDate = (dateStr) => {
    return new Date(dateStr).toLocaleDateString('en-US', { day: 'numeric', month: 'short', year: 'numeric' });
  };

  const formatDeadline = (v) => {
    if (!v) return null;
    const d = new Date(v);
    return Number.isNaN(d.getTime()) ? null : d.toLocaleString('en-US', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  };

  const totalAmount = bookingData.amount_paid || bookingData.paymentInfos?.[0]?.amount || 0;
  // Booking ID = TripJack order reference (TJS…). PNR = airline check-in reference (shown separately).
  const bookingRef = bookingData.order_id || bookingData.booking_id || bookingData.bookingId || '—';
  const pnr = bookingData.pnr || null;
  const deadline = formatDeadline(bookingData.deadline);

  return (
    <div className="booking-confirmation-container">
      <div className="row justify-content-center">
        <div className="col-lg-8">
          <div className="booking-card text-center">
            <div className="confirmation-icon mb-4">
              {onHold
                ? <FaClock size={80} style={{ color: '#b9750a' }} />
                : <FaCheckCircle size={80} className="text-success" />}
            </div>

            <h2 className="confirmation-title">{onHold ? 'Fare Held!' : 'Booking Confirmed!'}</h2>
            <p className="confirmation-subtitle">
              {onHold
                ? `Your seat is blocked${deadline ? ` until ${deadline}` : ''}. Pay before the deadline to confirm your ticket.`
                : 'Your flight has been successfully booked'}
            </p>

            <div className="booking-id-section my-4">
              <div className="booking-id-label">Booking ID</div>
              <div className="booking-id-value">{bookingRef}</div>
              {pnr && (
                <div className="booking-pnr mt-2">
                  <span className="booking-id-label">PNR</span>{' '}
                  <span className="booking-pnr-value">{pnr}</span>
                </div>
              )}
            </div>
            
            <div className="confirmation-details-grid mt-4">
              <div className="confirmation-detail-card">
                <h6>Flight Details</h6>
                <div className="flight-summary-mini">
                  <div className="d-flex align-items-center gap-2 mb-2">
                    <FaPlane />
                    <span>{trip.sI[0].fD.aI.name} {trip.sI[0].fD.fN}</span>
                  </div>
                  <div className="route-summary">
                    {trip.sI[0].da.code} → {trip.sI[trip.sI.length - 1].aa.code}
                  </div>
                  <div className="date-summary">
                    {formatDate(trip.sI[0].dt)} at {formatTime(trip.sI[0].dt)}
                  </div>
                </div>
                
                {returnTrip && (
                  <div className="flight-summary-mini mt-3">
                    <div className="d-flex align-items-center gap-2 mb-2">
                      <FaPlane />
                      <span>{returnTrip.sI[0].fD.aI.name} {returnTrip.sI[0].fD.fN}</span>
                    </div>
                    <div className="route-summary">
                      {returnTrip.sI[0].da.code} → {returnTrip.sI[returnTrip.sI.length - 1].aa.code}
                    </div>
                    <div className="date-summary">
                      {formatDate(returnTrip.sI[0].dt)} at {formatTime(returnTrip.sI[0].dt)}
                    </div>
                  </div>
                )}
              </div>
              
              <div className="confirmation-detail-card">
                <h6>Passengers</h6>
                {travellerInfo.map((traveller, index) => (
                  <div key={index} className="passenger-name-item">
                    {traveller.ti} {traveller.fN} {traveller.lN}
                  </div>
                ))}
              </div>
              
              <div className="confirmation-detail-card">
                <h6>Amount Paid</h6>
                <div className="amount-paid">
                  ₹{Number(totalAmount).toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                </div>
              </div>
            </div>
            
            <div className="confirmation-notice mt-4 p-3">
              <p className="mb-0">
                <strong>Booking confirmation has been sent to your email and mobile number.</strong>
              </p>
              <p className="mb-0 mt-2 text-muted">
                Please check your email for detailed itinerary and e-ticket.
              </p>
            </div>
            
            <div className="confirmation-actions mt-4">
              <button 
                className="btn btn-primary btn-lg me-3"
                onClick={() => alert('Download ticket feature coming soon')}
              >
                <FaDownload className="me-2" />
                Download Ticket
              </button>
              <button 
                className="btn btn-outline-primary btn-lg"
                onClick={() => navigate('/user-dashboard/my-bookings')}
              >
                <FaList className="me-2" />
                Go to My Bookings
              </button>
            </div>
            
            <div className="mt-4">
              <button 
                className="btn btn-link"
                onClick={() => navigate('/honeymoon')}
              >
                Book Another Flight
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
