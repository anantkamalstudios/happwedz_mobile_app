import { useState, useEffect } from 'react';
import { FaPlane } from 'react-icons/fa';
import { getSeatMap } from '../../../../../services/api/flightApi';

export default function SeatSelection({ bookingId, passengers, onBack, onContinue, onRefreshBookingId }) {
  const [seatMapData, setSeatMapData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [selectedSeats, setSelectedSeats] = useState({});
  const [currentPassengerIndex, setCurrentPassengerIndex] = useState(0);

  useEffect(() => {
    fetchSeatMap();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [bookingId]);

  const fetchSeatMap = async () => {
    setLoading(true);
    setError(null);
    try {
      const response = await getSeatMap(bookingId);
      if (response?.status?.success) {
        setSeatMapData(response.tripSeatMap);
      } else {
        const errCode = response?.errors?.[0]?.errCode;
        if (errCode === '1056') {
          // Seat map not available for this flight — auto-skip
          setError('Seat selection is not available for this flight. Proceeding to review...');
          setTimeout(() => onContinue([]), 1500);
        } else if (errCode === '2503') {
          // Review session expired — silently refresh and retry; if refresh fails, skip seat
          await handleSessionExpired();
        } else {
          setError(response?.errors?.[0]?.message || 'Failed to load seat map');
        }
      }
    } catch (err) {
      const errCode = err.response?.data?.errors?.[0]?.errCode;
      if (errCode === '1056') {
        setError('Seat selection is not available for this flight. Proceeding to review...');
        setTimeout(() => onContinue([]), 1500);
      } else if (errCode === '2503') {
        await handleSessionExpired();
      } else {
        setError(err.response?.data?.errors?.[0]?.message || 'Failed to load seat map. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  // When the review session expires (2503), re-do the review to get a fresh bookingId.
  // FlightBookingPage updates the bookingId prop → useEffect re-fires → fetchSeatMap retries.
  // If refresh fails or isn't possible, skip seat selection gracefully.
  const handleSessionExpired = async () => {
    if (typeof onRefreshBookingId === 'function') {
      setLoading(true);
      const refreshed = await onRefreshBookingId();
      if (!refreshed) {
        // Refresh failed — skip seat selection so booking can still proceed
        setLoading(false);
        setError('Could not refresh session. Skipping seat selection...');
        setTimeout(() => onContinue([]), 1500);
      }
      // If refreshed=true, bookingId prop changes → useEffect triggers → fetchSeatMap re-runs automatically
    } else {
      setError('Session expired. Skipping seat selection...');
      setTimeout(() => onContinue([]), 1500);
    }
  };

  const handleSeatClick = (segmentId, seat) => {
    if (seat.isBooked) return;

    const currentPassenger = passengers[currentPassengerIndex];
    const passengerId = `passenger_${currentPassengerIndex}`;

    setSelectedSeats(prev => {
      const newSelection = { ...prev };
      
      // Remove previous seat selection for this passenger in this segment
      if (newSelection[passengerId]?.segmentId === segmentId) {
        delete newSelection[passengerId];
      }
      
      // Check if seat is already selected by another passenger
      const seatAlreadySelected = Object.values(newSelection).some(
        selection => selection.segmentId === segmentId && selection.seatNo === seat.seatNo
      );
      
      if (!seatAlreadySelected) {
        newSelection[passengerId] = {
          segmentId,
          seatNo: seat.seatNo,
          amount: seat.amount,
          passengerName: `${currentPassenger.ti} ${currentPassenger.fN} ${currentPassenger.lN}`,
        };
      }
      
      return newSelection;
    });
  };

  const isSeatSelected = (segmentId, seatNo) => {
    return Object.values(selectedSeats).some(
      selection => selection.segmentId === segmentId && selection.seatNo === seatNo
    );
  };

  const getSeatClass = (seat, segmentId) => {
    if (seat.isBooked) return 'seat-booked';
    if (isSeatSelected(segmentId, seat.seatNo)) return 'seat-selected';
    if (seat.isLegroom) return 'seat-legroom';
    if (seat.amount > 0) return 'seat-paid';
    return 'seat-available';
  };

  const calculateTotalAmount = () => {
    return Object.values(selectedSeats).reduce((sum, seat) => sum + seat.amount, 0);
  };

  const handleContinue = () => {
    const seatSelections = Object.entries(selectedSeats).map(([passengerId, seat]) => ({
      passengerId,
      segmentId: seat.segmentId,
      seatNo: seat.seatNo,
      amount: seat.amount,
    }));
    
    onContinue(seatSelections);
  };

  const renderSeatMap = (segmentId, seatData) => {
    const { sData, sInfo } = seatData;
    const rows = sData.row;
    const columns = sData.column;

    // Create a 2D array for the seat grid
    const seatGrid = Array.from({ length: rows }, () => Array(columns).fill(null));
    
    sInfo.forEach(seat => {
      const rowIndex = seat.seatPosition.row - 1;
      const colIndex = seat.seatPosition.column - 1;
      if (rowIndex >= 0 && rowIndex < rows && colIndex >= 0 && colIndex < columns) {
        seatGrid[rowIndex][colIndex] = seat;
      }
    });

    // Determine aisle position (usually between columns 3 and 4 for most planes)
    const aisleAfterColumn = Math.floor(columns / 2);

    return (
      <div className="seat-map-container">
        <div className="plane-head">
          <img src="/images/honeymoon/plane-head.png" alt="Plane Head" />
        </div>
        
        <div className="seat-grid">
          {/* Column headers */}
          <div className="seat-row seat-header-row">
            <div className="seat-row-number"></div>
            {Array.from({ length: columns }, (_, i) => {
              const letter = String.fromCharCode(65 + i); // A, B, C, D...
              return (
                <div key={i} className="seat-header">
                  {i === aisleAfterColumn && <div className="aisle-space"></div>}
                  <span>{letter}</span>
                </div>
              );
            })}
          </div>

          {/* Seat rows */}
          {seatGrid.map((row, rowIndex) => (
            <div key={rowIndex} className="seat-row">
              <div className="seat-row-number">{rowIndex + 1}</div>
              {row.map((seat, colIndex) => (
                <div key={colIndex} className="seat-cell">
                  {colIndex === aisleAfterColumn && <div className="aisle-space"></div>}
                  {seat ? (
                    <div
                      className={`seat ${getSeatClass(seat, segmentId)}`}
                      onClick={() => handleSeatClick(segmentId, seat)}
                      title={`${seat.seatNo} - ₹${seat.amount}`}
                    >
                      <span className="seat-label">{seat.seatNo}</span>
                    </div>
                  ) : (
                    <div className="seat seat-empty"></div>
                  )}
                </div>
              ))}
            </div>
          ))}
        </div>

        <div className="plane-tail">
          <img src="/images/honeymoon/plane-tail.png" alt="Plane Tail" />
        </div>
      </div>
    );
  };

  if (loading) {
    return (
      <div className="booking-card">
        <div className="text-center py-5">
          <div className="spinner-border text-primary" role="status">
            <span className="visually-hidden">Loading...</span>
          </div>
          <p className="mt-3">Loading seat map...</p>
        </div>
      </div>
    );
  }

  if (error) {
    const isAutoSkipping = error.includes('not available') || error.includes('Proceeding to review');
    
    return (
      <div className="booking-card">
        <div className={`alert ${isAutoSkipping ? 'alert-info' : 'alert-danger'}`}>
          {error}
        </div>
        {!isAutoSkipping && (
          <div className="d-flex gap-2">
            <button className="btn btn-outline-secondary" onClick={onBack}>
              Back
            </button>
            <button className="btn btn-primary" onClick={fetchSeatMap}>
              Retry
            </button>
            <button className="btn btn-secondary" onClick={() => onContinue([])}>
              Skip Seat Selection
            </button>
          </div>
        )}
      </div>
    );
  }

  if (!seatMapData) {
    return (
      <div className="booking-card">
        <div className="alert alert-info">
          Seat selection is not available for this flight. You can proceed to the next step.
        </div>
        <div className="d-flex gap-2">
          <button className="btn btn-outline-secondary" onClick={onBack}>
            Back
          </button>
          <button className="btn btn-primary" onClick={() => onContinue([])}>
            Continue
          </button>
        </div>
      </div>
    );
  }

  const segments = Object.entries(seatMapData.tripSeat || {});

  return (
    <div className="row">
      <div className="col-lg-9">
        <div className="booking-card">
          <h4 className="booking-card-title">
            <FaPlane className="me-2" />
            Select Your Seats
          </h4>

          {/* Passenger selector */}
          <div className="passenger-selector mb-4">
            <h6>Select seat for:</h6>
            <div className="passenger-tabs">
              {passengers.map((passenger, index) => {
                const passengerId = `passenger_${index}`;
                const hasSelectedSeat = selectedSeats[passengerId];
                
                return (
                  <div
                    key={index}
                    className={`passenger-tab ${currentPassengerIndex === index ? 'active' : ''} ${hasSelectedSeat ? 'completed' : ''}`}
                    onClick={() => setCurrentPassengerIndex(index)}
                  >
                    <div className="passenger-tab-name">
                      {passenger.ti} {passenger.fN} {passenger.lN}
                    </div>
                    {hasSelectedSeat && (
                      <div className="passenger-tab-seat">
                        {hasSelectedSeat.seatNo}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Seat legend */}
          <div className="seat-legend mb-4">
            <div className="legend-item">
              <div className="seat seat-available"></div>
              <span>Available</span>
            </div>
            <div className="legend-item">
              <div className="seat seat-paid"></div>
              <span>Paid Seat</span>
            </div>
            <div className="legend-item">
              <div className="seat seat-legroom"></div>
              <span>Extra Legroom</span>
            </div>
            <div className="legend-item">
              <div className="seat seat-selected"></div>
              <span>Selected</span>
            </div>
            <div className="legend-item">
              <div className="seat seat-booked"></div>
              <span>Booked</span>
            </div>
          </div>

          {/* Seat maps for each segment */}
          {segments.map(([segmentId, seatData]) => (
            <div key={segmentId} className="segment-seat-map mb-5">
              <h5 className="segment-title">Flight Segment {segmentId}</h5>
              {renderSeatMap(segmentId, seatData)}
            </div>
          ))}
        </div>
      </div>

      <div className="col-lg-3">
        <div className="booking-card sticky-summary">
          <h5 className="booking-card-title">Seat Selection Summary</h5>

          <div className="selected-seats-list">
            {passengers.map((passenger, index) => {
              const passengerId = `passenger_${index}`;
              const selectedSeat = selectedSeats[passengerId];
              
              return (
                <div key={index} className="selected-seat-item">
                  <div className="passenger-name">
                    {passenger.ti} {passenger.fN} {passenger.lN}
                  </div>
                  {selectedSeat ? (
                    <div className="seat-info">
                      <span className="seat-number">{selectedSeat.seatNo}</span>
                      <span className="seat-price">
                        ₹{Number(selectedSeat.amount).toLocaleString('en-IN')}
                      </span>
                    </div>
                  ) : (
                    <div className="no-seat-selected">No seat selected</div>
                  )}
                </div>
              );
            })}
          </div>

          <div className="seat-total mt-4 pt-3">
            <div className="d-flex justify-content-between align-items-center">
              <span>Total Seat Charges</span>
              <span className="total-amount">
                ₹{Number(calculateTotalAmount()).toLocaleString('en-IN')}
              </span>
            </div>
          </div>

          <div className="seat-info-notice mt-3">
            <small className="text-muted">
              Seat selection is optional. You can skip this step and seats will be assigned automatically.
            </small>
          </div>

          <div className="d-flex gap-2 mt-4">
            <button className="btn btn-outline-secondary flex-grow-1" onClick={onBack}>
              Back
            </button>
            <button className="btn btn-primary flex-grow-1" onClick={handleContinue}>
              Continue
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
